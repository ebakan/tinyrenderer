defmodule Tinyrenderer.Image do
  # Functions for reading, manipulating, and writing images
  alias __MODULE__
  alias Tinyrenderer.{Model, Vector, Matrix, Shader}

  defstruct [:pixel_data, :width, :height]

  # Create 2D array of pixels, which are represented as [b, g, r]
  def new(height: height, width: width) do
    new(height: height, width: width, color: [0, 0, 0])
  end
  def new(height: height, width: width, color: %{r: r, g: g, b: b}) do
    new(height: height, width: width, color: [b, g, r])
  end
  def new(height: height, width: width, color: color) do
    %Image{
      pixel_data:
        Enum.map(0..height-1, fn(_y) ->
          Enum.map(0..width-1, fn(_x) ->
            color end)
        end) |> list_to_map,
      width: width,
      height: height
    }
  end

  # Write to a BMP
  def write(image, filename) do
    Bump.write(filename: filename, pixel_data: image.pixel_data |> map_to_list)
  end

  # Read data from a BMP
  def read(filename) do
    pixel_data = Bump.pixel_data(filename)
    %Image{
      pixel_data: pixel_data |> list_to_map,
      width: pixel_data |> Enum.at(0) |> length,
      height: pixel_data |> length
    }
  end

  defp map_to_list(map) do
    map |> Enum.sort |> Keyword.values |> Enum.map(&(&1 |> Enum.sort |> Keyword.values))
  end

  defp list_to_map(list) do
    list
    |> Enum.with_index
    |> Enum.map(fn {row, i} ->
      {
        i,
        row
        |> Enum.with_index
        |> Enum.map(fn {val, j} ->
          {j, val}
        end)
        |> Map.new
      }
    end)
    |> Map.new
  end

  # Set a pixel to a color
  def set(image, x, y, %{r: r, g: g, b: b}), do: set(image, x, y, [b, g, r])
  def set(image, x, y, color) do
    %{image |
      pixel_data: image.pixel_data |> Map.update!(y, fn(row) -> %{row | x => color} end)
    }
  end

  # Draw a line with a color
  def draw_line(image, x0, y0, x1, y1) do
    draw_line(image, x0, y0, x1, y1, [255, 255, 255])
  end
  def draw_line(image, x0, y0, x1, y1, %{r: r, g: g, b: b}) do
    draw_line(image, x0, y0, x1, y1, [b, g, r])
  end
  def draw_line(image, x0, y0, x1, y1, color) when x0 - x1 == 0 and  y0 - y1 == 0 do
    # Optimization when drawing a single pixel
    set(image, x0, y0, color)
  end
  def draw_line(image, x0, y0, x1, y1, color) when abs(x0 - x1) < abs(y0 - y1) do
    # If the line is steep, we'll iterate over the Y coordinates and interpolate X
    draw_line(image, y0, x0, y1, x1, color, steep: true)
  end
  def draw_line(image, x0, y0, x1, y1, color, opts \\ []) do
    Enum.reduce(x0..x1, image, fn(x, data) ->
      t = (x - x0) / (x1 - x0)
      y = round(y0 * (1 - t) + y1 * t)
      # If it's a steep line, we've swapped X and Y coordinates
      if opts[:steep] do
        set(data, y, x, color)
      else
        set(data, x, y, color)
      end
    end)
  end

  def draw_wireframe(image, vertices, color) do
    vertices
    |> Enum.map(&scale_vertex(&1, image))
    |> (fn([head|tail]) -> [head | tail] ++ [head] end).()
    |> Enum.chunk(2, 1)
    |> Enum.reduce(image, fn([v0, v1], img) ->
      img |> draw_line(v0.x, v0.y, v1.x, v1.y, color)
    end)
  end

  def draw_triangle(image, vertices, zbuffer, shader) do
    x_coords = vertices |> Enum.map(&Map.get(&1, :x))
    y_coords = vertices |> Enum.map(&Map.get(&1, :y))
    x_min = x_coords |> Enum.min |> max(0) |> min(image.width - 1)
    x_max = x_coords |> Enum.max |> min(image.width - 1) |> max(0)
    y_min = y_coords |> Enum.min |> max(0) |> min(image.height - 1)
    y_max = y_coords |> Enum.max |> min(image.height - 1) |> max(0)
    x_size = x_max - x_min + 1
    y_size = y_max - y_min + 1
    [v0, v1, v2] = vertices
    z_vec = %{x: v0.z, y: v1.z, z: v2.z}
    pixels = Enum.map(0..(x_size * y_size), fn(i) ->
      %{x: rem(i, x_size) + x_min, y: div(i, x_size) + y_min}
    end)
    pixels
    |> Enum.map(&({&1, Vector.barycentric_coords(&1, vertices)}))
    |> Enum.reject(&(&1 |> elem(1) |> Map.values |> Enum.any?(fn(v) -> v < 0 end)))
    |> Enum.map(fn {pixel, b_coords} -> {pixel |> Map.merge(%{z: Vector.dot(z_vec, b_coords)}), b_coords} end)
    |> Enum.reduce({zbuffer, shader, image}, fn({pixel, b_coords}, {zbuf, shdr, img}) ->
      zbuf_val = zbuf[pixel.y * image.width + pixel.x]
      if is_nil(zbuf_val) or zbuf_val < pixel.z do
        case shdr |> shdr.__struct__.fragment(b_coords) do
          {:ok, shdr, color} ->
            {
              %{zbuf | pixel.y * image.width + pixel.x => pixel.z},
              shdr,
              img |> set(pixel.x, pixel.y, color)
            }
          {:discard, shdr} -> {zbuf, shdr, img}
        end
      else
        {zbuf, shdr, img}
      end
    end)
  end

  defp look_at(eye, center, up) do
    z = eye |> Vector.sub(center) |> Vector.normalize
    x = up |> Vector.cross(z) |> Vector.normalize
    y = z |> Vector.cross(x) |> Vector.normalize
    ([x: x, y: y, z: z]
    |> Enum.map(fn({key, vec}) ->
      [vec.x, vec.y, vec.z, center[key]]
    end)) ++ [[0, 0, 0, 1]]
  end

  # Render a model with a color literal or function
  def render_model(image, model), do: render_model(image, model, [])
  def render_model(image, model, opts) do
    # Initial config
    # Parameter values
    width = image.width
    height = image.height
    texture = opts[:texture]
    light_dir = opts[:light_dir] || %{x: 0, y: 0, z: -1}
    eye = opts[:eye] || %{x: 0, y: 0, z: 1}
    up = opts[:up] || %{x: 0, y: 1, z: 0}
    center = opts[:center] || %{x: 0, y: 0, z: 0}
    depth = opts[:depth] || 255
    shader_module = opts[:shader] || Shader.GouradShader

    # Projection initialization
    model_view = eye |> look_at(center, up)
    projection = Matrix.identity(4) |> Matrix.set(3, 2, -1 / (eye |> Vector.sub(center) |> Vector.norm))
    viewport = gen_viewport(x: width / 8, y: height / 8, w: width * 3 / 4, h: height * 3 / 4, depth: depth)
    transform = viewport
                |> Matrix.mul(projection)
                |> Matrix.mul(model_view)

    zbuffer = (0..(width * height))
              |> Enum.map(&({&1, nil}))
              |> Map.new

    shader = struct(shader_module,
                    transform: transform,
                    texture: texture,
                    light_dir: light_dir)

    model.faces
    |> Enum.reduce({zbuffer, shader, image}, fn(face, {zbuf, shdr, img}) ->
      {shdr, vertices} = face
                         |> Enum.map(&Model.map_face(model, &1))
                         |> Enum.with_index
                         |> Enum.reduce({shdr, []}, fn ({v, i}, {s, list}) ->
                           {s, new_v} = s |> shdr.__struct__.vertex(v, i)
                           {s, [new_v | list]}
                         end)
      shdr =
        if opts[:color] do
          color = opts[:color]
          color = if is_function(color), do: color.(), else: color
          color = if is_map(color), do: [color.b, color.g, color.r], else: color
          %{shdr | color: color}
        else
          shdr
        end
      draw_triangle(img, vertices |> Enum.reverse, zbuf, shdr)
    end) |> elem(2)
  end

  defp gen_viewport(x: x, y: y, w: w, h: h, depth: depth) do
    Matrix.identity(4)
    |> Matrix.set(0, 3, x + w / 2)
    |> Matrix.set(1, 3, y + h / 2)
    |> Matrix.set(2, 3, depth / 2)
    |> Matrix.set(0, 0, w / 2)
    |> Matrix.set(1, 1, h / 2)
    |> Matrix.set(2, 2, depth / 2)
  end

  # Scale a vertex from [[-1..1], [-1..1]] to [[0..width - 1], [0..height - 1]]
  defp scale_vertex(vertex, image) do
    %{vertex |
      x: round((vertex.x + 1) * (image.width - 1) / 2),
      y: round((vertex.y + 1) * (image.height - 1) / 2),
    }
  end

  def rand_color() do
    %{
      r: :rand.uniform(255),
      g: :rand.uniform(255),
      b: :rand.uniform(255)
    }
  end
end
