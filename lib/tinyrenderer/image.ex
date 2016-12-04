defmodule Tinyrenderer.Image do
  # Functions for reading, manipulating, and writing images
  alias __MODULE__
  alias Tinyrenderer.Vector

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

  def draw_triangle(image, vertices, zbuffer, opts \\ [{:color, [255, 255, 255]}]) do
    vertices = vertices |> Enum.map(&scale_vertex(&1, image))
    x_coords = vertices |> Enum.map(&Map.get(&1, :x))
    y_coords = vertices |> Enum.map(&Map.get(&1, :y))
    x_min= max(0, x_coords |> Enum.min)
    x_max= min(image.width, x_coords |> Enum.max)
    y_min= max(0, y_coords |> Enum.min)
    y_max= min(image.height, y_coords |> Enum.max)
    [v0, v1, v2] = vertices
    z_vec = %{x: v0.z, y: v1.z, z: v2.z}
    pixels = Enum.map(x_min..x_max, fn(x) ->
      Enum.map(y_min..y_max, fn(y) ->
        %{x: x, y: y}
      end)
    end) |> List.flatten
    pixels
    |> Enum.map(&({&1, barycentric_coords(&1, vertices)}))
    |> Enum.reject(&(&1 |> elem(1) |> Map.values |> Enum.any?(fn(v) -> v < 0 end)))
    |> Enum.map(fn {pixel, b_coords} -> {pixel |> Map.merge(%{z: Vector.dot(z_vec, b_coords)}), b_coords} end)
    |> Enum.reduce({zbuffer, image}, fn({pixel, b_coords}, {zbuf, img}) ->
      zbuf_val = zbuf[pixel.y * image.width + pixel.x]
      if is_nil(zbuf_val) or zbuf_val < pixel.z do
        intensity = opts[:intensity] || 1;
        color =
          if opts[:texture] do
            {texture, texture_coords} = opts[:texture]
            texture_b_coords = inv_barycentric_coords(b_coords, texture_coords)
            texture.pixel_data[round(texture_b_coords.y * texture.height)][round(texture_b_coords.x * texture.width)]
          else
            opts[:color]
          end
        {
          %{zbuf | pixel.y * image.width + pixel.x => pixel.z},
          img |> set(pixel.x, pixel.y, color |> Enum.map(&(round(&1 * intensity))))
        }
      else
        {zbuf, img}
      end
    end)
  end

  defp barycentric_coords(p, [v0, v1, v2]) do
    u = Vector.cross(%{x: v2.x - v0.x, y: v1.x - v0.x, z: v0.x - p.x},
                     %{x: v2.y - v0.y, y: v1.y - v0.y, z: v0.y - p.y})
    if abs(u.z) < 1 do
      %{x: -1, y: 1, z: 1} # triangle is degenerate
    else
      %{x: 1 - (u.x + u.y) / u.z, y: u.y / u.z, z: u.x / u.z}
    end
  end

  defp inv_barycentric_coords(b_coord, [v0, v1, v2]) do
    Vector.add(Vector.mul(v0, b_coord.x),
               Vector.add(Vector.mul(v1, b_coord.y),
                          Vector.mul(v2, b_coord.z)))
  end

  # Render a model with a color literal or function
  def render_model(image, model, color, light_dir), do: render_model(image, model, color, light_dir, nil)
  def render_model(image, model, color, light_dir, texture) when not is_function(color) do
    render_model(image, model, fn() -> color end, light_dir, texture)
  end

  def render_model(image, model, color_fn, light_dir, texture) do
    zbuffer = (0..(image.width * image.height))
              |> Enum.map(&({&1, nil}))
              |> Map.new
    model.faces
    |> Enum.reduce({zbuffer, image}, fn(face, {zbuf, img}) ->
      vertices = face
      |> Enum.map(&Map.get(&1, :vertex))
      |> Enum.map(&Enum.at(model.vertices, &1))
      [v0, v1, v2] = vertices
      intensity =  Vector.cross(Vector.sub(v2, v0), Vector.sub(v1, v0))
                   |> Vector.normalize
                   |> Vector.dot(light_dir)
      if intensity > 0 do
        if texture do
          texture_coords = face
          |> Enum.map(&Map.get(&1, :texture))
          |> Enum.map(&Enum.at(model.textures, &1))
          |> Enum.map(&uvw_to_xyz/1)
          draw_triangle(img, vertices, zbuf, intensity: intensity, texture: {texture, texture_coords})
        else
          color =
            case color_fn.() do
              c when is_map(c) -> [c.b, c.g, c.r]
              c -> c
            end
          draw_triangle(img, vertices, zbuf, intensity: intensity, color: color)
        end
      else
        {zbuf, img}
      end
    end) |> elem(1)
  end

  # Scale a vertex from [[-1..1], [-1..1]] to [[0..width - 1], [0..height - 1]]
  defp scale_vertex(vertex, image) do
    %{vertex |
      x: round((vertex.x + 1) * (image.width - 1) / 2),
      y: round((vertex.y + 1) * (image.height - 1) / 2),
    }
  end

  defp uvw_to_xyz(vertex) do
    %{x: vertex.u, y: vertex.v, z: vertex.w}
  end

  def rand_color() do
    %{
      r: :rand.uniform(255),
      g: :rand.uniform(255),
      b: :rand.uniform(255)
    }
  end
end
