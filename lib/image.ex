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
end
