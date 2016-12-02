defmodule Tinyrenderer.Image do
  def new(height: height, width: width) do
    new(height: height, width: width, color: [0, 0, 0])
  end
  def new(height: height, width: width, color: %{r: r, g: g, b: b}) do
    new(height: height, width: width, color: [r, g, b])
  end
  def new(height: height, width: width, color: color) do
    Enum.map(0..height-1, fn(_y) -> Enum.map(0..width-1, fn(_x) -> color end) end)
  end

  def write(pixel_data, filename) do
    Bump.write(filename: filename, pixel_data: pixel_data)
  end

  def read(filename) do
    Bump.pixel_data(filename)
  end

  def set(pixel_data, x, y, %{r: r, g: g, b: b}), do: set(pixel_data, x, y, [r,g,b])
  def set(pixel_data, x, y, arr) do
    pixel_data |> List.update_at(y, fn(row) -> row |> List.replace_at(x, arr) end)
  end

  def line(pixel_data, x0, y0, x1, y1) do
    line(pixel_data, x0, y0, x1, y1, [255, 255, 255])
  end
  def line(pixel_data, x0, y0, x1, y1, %{r: r, g: g, b: b}) do
    line(pixel_data, x0, y0, x1, y1, [r, g, b])
  end
  def line(pixel_data, x0, y0, x1, y1, color) do
    iters = 1000
    Enum.reduce(0..iters, pixel_data, fn(i, data) ->
      t = i / iters
      x = x0 * (1 - t) + x1 * t
      y = y0 * (1 - t) + y1 * t
      IO.inspect x
      IO.inspect y
      IO.inspect color
      set(data, round(x), round(y), color)
    end)
  end
end
