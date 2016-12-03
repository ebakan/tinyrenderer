defmodule Tinyrenderer.Image do
  # Functions for reading, manipulating, and writing images
  alias __MODULE__
  alias Tinyrenderer.Math

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
      pixel_data: Enum.map(0..height-1, fn(_y) -> Enum.map(0..width-1, fn(_x) -> color end) end),
      width: width,
      height: height
    }
  end

  # Write to a BMP
  def write(image, filename) do
    Bump.write(filename: filename, pixel_data: image.pixel_data)
  end

  # Read data from a BMP
  def read(filename) do
    pixel_data = Bump.pixel_data(filename)
    %Image{
      pixel_data: pixel_data,
      width: pixel_data |> Enum.at(0) |> length,
      height: pixel_data |> length
    }
  end

  # Set a pixel to a color
  def set(image, x, y, %{r: r, g: g, b: b}), do: set(image, x, y, [b, g, r])
  def set(image, x, y, color) do
    %{image |
      pixel_data: image.pixel_data |> List.update_at(y, fn(row) -> row |> List.replace_at(x, color) end)
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

  def draw_triangle(image, vertices, color) do
    vertices = vertices |> Enum.map(&scale_vertex(&1, image))
    x_coords = vertices |> Enum.map(&Map.get(&1, :x))
    y_coords = vertices |> Enum.map(&Map.get(&1, :y))
    x_min= max(0, x_coords |> Enum.min)
    x_max= min(image.width, x_coords |> Enum.max)
    y_min= max(0, y_coords |> Enum.min)
    y_max= min(image.height, y_coords |> Enum.max)
    [v0, v1, v2] = vertices
    pixels = Enum.map(x_min..x_max, fn(x) ->
      Enum.map(y_min..y_max, fn(y) ->
        %{x: x, y: y}
      end)
    end) |> List.flatten
    pixels
    |> Enum.reject(&(barycentric_coords(&1, vertices) |> Map.values |> Enum.any?(fn(v) -> v < 0 end)))
    |> Enum.reduce(image, &set(&2, &1.x, &1.y, color))
  end

  defp barycentric_coords(p, [v0, v1, v2]) do
    u = Math.cross(%{x: v2.x - v0.x, y: v1.x - v0.x, z: v0.x - p.x},
                   %{x: v2.y - v0.y, y: v1.y - v0.y, z: v0.y - p.y})
    if abs(u.z) < 1 do
      %{x: -1, y: 1, z: 1} # triangle is degenerate
    else
      %{x: 1 - (u.x + u.y) / u.z, y: u.y / u.z, z: u.x / u.z}
    end
  end

  # Render a model with a color literal or function
  def render_model(image, model, color) when not is_function(color) do
    render_model(image, model, fn() -> color end)
  end

  def render_model(image, model, color_fn) do
    model.faces
    |> Enum.reduce(image, fn(face, img) ->
      vertices = face
      |> Enum.map(&Map.get(&1, :vertex))
      |> Enum.map(&Enum.at(model.vertices, &1))
      draw_triangle(img, vertices, color_fn.())
    #draw_wireframe(img, vertices, color_fn.())
    end)
  end

  # Scale a vertex from [[-1..1], [-1..1]] to [[0..width], [0..height]]
  defp scale_vertex(vertex, image) do
    %{vertex |
      x: round((vertex.x + 1) * image.width / 2),
      y: round((vertex.y + 1) * image.height / 2),
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
