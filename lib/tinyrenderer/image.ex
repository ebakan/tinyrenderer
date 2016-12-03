defmodule Tinyrenderer.Image do
  # Functions for manipulating pixel data

  # Create 2D array of pixels, which are represented as [b, g, r]
  def new(height: height, width: width) do
    new(height: height, width: width, color: [0, 0, 0])
  end
  def new(height: height, width: width, color: %{r: r, g: g, b: b}) do
    new(height: height, width: width, color: [b, g, r])
  end
  def new(height: height, width: width, color: color) do
    Enum.map(0..height-1, fn(_y) -> Enum.map(0..width-1, fn(_x) -> color end) end)
  end

  # Write to a BMP
  def write(pixel_data, filename) do
    Bump.write(filename: filename, pixel_data: pixel_data)
  end

  # Read data from a BMP
  def read(filename) do
    Bump.pixel_data(filename)
  end

  def width(pixel_data), do: pixel_data |> Enum.at(0) |> length

  def height(pixel_data), do: pixel_data |> length

  # Set a pixel to a color
  def set(pixel_data, x, y, %{r: r, g: g, b: b}), do: set(pixel_data, x, y, [b, g, r])
  def set(pixel_data, x, y, color) do
    pixel_data |> List.update_at(y, fn(row) -> row |> List.replace_at(x, color) end)
  end

  # Draw a line with a color
  def draw_line(pixel_data, x0, y0, x1, y1) do
    draw_line(pixel_data, x0, y0, x1, y1, [255, 255, 255])
  end
  def draw_line(pixel_data, x0, y0, x1, y1, %{r: r, g: g, b: b}) do
    draw_line(pixel_data, x0, y0, x1, y1, [b, g, r])
  end
  def draw_line(pixel_data, x0, y0, x1, y1, color) when x0 - x1 == 0 and  y0 - y1 == 0 do
    # Optimization when drawing a single pixel
    set(pixel_data, x0, y0, color)
  end
  def draw_line(pixel_data, x0, y0, x1, y1, color) when abs(x0 - x1) < abs(y0 - y1) do
    # If the line is steep, we'll iterate over the Y coordinates and interpolate X
    draw_line(pixel_data, y0, x0, y1, x1, color, steep: true)
  end
  def draw_line(pixel_data, x0, y0, x1, y1, color, opts \\ []) do
    Enum.reduce(x0..x1, pixel_data, fn(x, data) ->
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

  # Render a model with a color literal or function
  def render_model(pixel_data, model, color) when not is_function(color) do
    render_model(pixel_data, model, fn() -> color end)
  end

  def render_model(pixel_data, model, color_fn) do
    width_2 = width(pixel_data) / 2
    height_2 = height(pixel_data) / 2
    model.faces
    |> Enum.reduce(pixel_data, fn(face, image) ->
      face
      |> Enum.map(&Map.get(&1, :vertex))
      |> Enum.map(&Enum.at(model.vertices, &1))
      |> (fn([head|tail]) -> [head | tail] ++ [head] end).()
      |> Enum.chunk(2, 1)
      |> Enum.reduce(image, fn([v0, v1], img) ->
        img
        |> draw_line(
          round((v0.x + 1) * width_2),
          round((v0.y + 1) * height_2),
          round((v1.x + 1) * width_2),
          round((v1.y + 1) * height_2),
          color_fn.()
        )
      end)
    end)
  end
end
