defmodule Tinyrenderer.Image do
  def new(height: height, width: width) do
    new(height: height, width: width, color: [0, 0, 0])
  end
  def new(height: height, width: width, color: %{r: r, g: g, b: b}) do
    new(height: height, width: width, color: [b, g, r])
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

  def set(pixel_data, x, y, %{r: r, g: g, b: b}), do: set(pixel_data, x, y, [b, g, r])
  def set(pixel_data, x, y, color) do
    pixel_data |> List.update_at(y, fn(row) -> row |> List.replace_at(x, color) end)
  end

  def line(pixel_data, x0, y0, x1, y1) do
    line(pixel_data, x0, y0, x1, y1, [255, 255, 255])
  end
  def line(pixel_data, x0, y0, x1, y1, %{r: r, g: g, b: b}) do
    line(pixel_data, x0, y0, x1, y1, [b, g, r])
  end
  def line(pixel_data, x0, y0, x1, y1, color) when x0 - x1 == 0 and  y0 - y1 == 0 do
    set(pixel_data, x0, y0, color)
  end
  def line(pixel_data, x0, y0, x1, y1, color) when abs(x0 - x1) < abs(y0 - y1) do
    line_steep(pixel_data, x0, y0, x1, y1, color)
  end
  def line(pixel_data, x0, y0, x1, y1, color) do
    Enum.reduce(x0..x1, pixel_data, fn(x, data) ->
      t = (x - x0) / (x1 - x0)
      y = y0 * (1 - t) + y1 * t
      set(data, x, round(y), color)
    end)
  end

  defp line_steep(pixel_data, x0, y0, x1, y1, color) do
    Enum.reduce(y0..y1, pixel_data, fn(y, data) ->
      t = (y - y0) / (y1 - y0)
      x = x0 * (1 - t) + x1 * t
      set(data, round(x), y, color)
    end)
  end
end
