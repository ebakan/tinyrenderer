defmodule Tinyrenderer.Matrix do
  alias __MODULE__

  def new(len), do: new(len, len)
  def new(rows, cols) do
    Enum.map(1..rows, fn(i) ->
      Enum.map(1..cols, fn(j) ->
        if i == j, do: 1, else: 0
      end)
    end)
  end

  def identity(len) do
    Enum.reduce(1..len, new(len), fn(i, matrix) ->
      matrix |> set(i, i, 1)
    end)
  end

  def set(matrix, row, col, val) do
    matrix |> List.update_at(row, &(&1 |> List.replace_at(col, val)))
  end

  def from_vector(%{x: x, y: y, z: z}) do
    [ [x], [y], [z], [1] ]
  end

  def to_vector([[x], [y], [z]]), do: to_vector([x, y, z])
  def to_vector([[x], [y], [z], [c]]), do: to_vector([x, y, z, c])
  def to_vector([x, y, z]), do: %{x: x, y: y, z: z}
  def to_vector([x, y, z, c]), do: %{x: x / c, y: y / c, z: z / c}

  def rows(m), do: length(m)
  def cols(m), do: m |> Enum.at(0) |> length

  def mul(m, v) when is_map(v), do: m |> mul(v |> from_vector)
  def mul(m1, m2) do
    if cols(m1) != rows(m2) do
      raise ArgumentError, message: "Invalid matrix dimensions: #{rows(m1)}x#{cols(m1)} * #{rows(m2)}x#{cols(m2)}"
    end
    m1
    |> Enum.map(fn(m1_row) ->
      0..cols(m2) - 1
      |> Enum.map(fn(i) ->
        m2
        |> Enum.with_index
        |> Enum.map(fn {m2_row, j} ->
          Enum.at(m1_row, j) * Enum.at(m2_row, i)
        end)
        |> Enum.sum
      end)
    end)
  end

  def set_col(matrix, i, vector) when is_map(vector) do
    set_col(matrix, i, vector |> Map.values)
  end
  def set_col(matrix, i, vector) do
    matrix
    |> Enum.with_index
    |> Enum.map(fn{row, j} ->
      row |> List.replace_at(i, vector |> Enum.at(j))
    end)
  end

  def transpose(matrix) do
    matrix
    |> Enum.with_index
    |> Enum.reduce(Matrix.new(cols(matrix), rows(matrix)), fn({row, i}, matrix) ->
      matrix |> set_col(i, row)
    end)
  end
end
