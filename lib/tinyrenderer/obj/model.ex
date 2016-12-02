defmodule Tinyrenderer.OBJ.Model do
  alias __MODULE__

  defstruct vertices: [],
            textures: [],
            normals: [],
            faces: []

  def read(filename) do
    filename
    |> File.stream!
    |> Stream.with_index
    |> Enum.reduce(%Model{}, fn({line, line_num}, model) ->
      case line do
        "#" <> _rest -> model
        "\n" -> model
        # Ignore these for now
        "g" <> _rest -> model
        "s" <> _rest -> model
        _ ->
          [type|args] = line |> String.trim |> String.split
          case type do
            "v" ->
              %{model | vertices: [
                case args |> Enum.map(&parse_float/1) do
                  [x, y, z] -> %{x: x, y: y, z: z, w: 1.0}
                  [x, y, z, w] -> %{x: x, y: y, z: z, w: w}
                  _ -> raise ArgumentError, message: "Invalid vertex on line #{line_num}: #{line}"
                end
              | model.vertices]}
            "vt" ->
              %{model | textures: [
                case args |> Enum.map(&parse_float/1) do
                  [u, v] -> %{u: u, v: v, w: 0}
                  [u, v, w] -> %{u: u, v: v, w: w}
                  _ -> raise ArgumentError, message: "Invalid texture on line #{line_num}: #{line}"
                end
              | model.textures]}
            "vn" ->
              %{model | normals: [
                case args |> Enum.map(&parse_float/1) do
                  [x, y, z] -> %{x: x, y: y, z: z}
                  _ -> raise ArgumentError, message: "Invalid normal on line #{line_num}: #{line}"
                end
              | model.normals]}
            "f" ->
              %{model | faces: [
                args |> Enum.map(fn(arg) ->
                  case arg |> String.split("/") do
                    [v] -> %{vertex: String.to_integer(v)}
                    [v, vt] -> %{vertex: String.to_integer(v) - 1, texture: String.to_integer(vt) - 1}
                    [v, "", vn] -> %{vertex: String.to_integer(v) - 1, normal: String.to_integer(vn) - 1}
                    [v, vt, vn] -> %{vertex: String.to_integer(v) - 1, texture: String.to_integer(vt) - 1, normal: String.to_integer(vn) - 1}
                    _ -> raise ArgumentError, message: "Invalid face on line #{line_num}: #{line}"
                  end
                end)
              | model.faces]}
            any -> raise ArgumentError, message: "Invalid identifier #{any} on line #{line_num}: #{line}"
          end
      end
    end)
    |> reverse
  end

  def write(model, filename) do
    File.open!(filename)
    |> File.write!(
      """
      #{model.vertices |> Enum.map(fn(v) -> "v #{v.x} #{v.y} #{v.z}\n" end)}
      #{model.textures |> Enum.map(fn(vt) -> "vt #{vt.u} #{vt.v} #{vt.w}\n" end)}
      #{model.normals |> Enum.map(fn(vn) -> "vn #{vn.x} #{vn.y} #{vn.z}\n" end)}
      #{model.faces |> Enum.map(fn(vn) ->
        case vn do
          %{vertex: v, texture: vt, normal: vn} -> "f #{v + 1}/#{vt + 1}/#{vn + 1}\n"
          %{vertex: v, normal: vn} -> "f #{v + 1}//#{vn + 1}\n"
          %{vertex: v, texture: vt} -> "f #{v + 1}/#{vt + 1}\n"
          %{vertex: v} -> "f #{v + 1}\n"
          _ -> raise ArgumentError, message: "Invalid face #{vn |> inspect}"
        end
      end)}
      """
    )
  end

  defp reverse(model) do
    %Model{
      vertices: model.vertices |> Enum.reverse,
      textures: model.textures |> Enum.reverse,
      normals: model.normals |> Enum.reverse,
      faces: model.faces |> Enum.reverse
    }
  end

  defp parse_float(str) do
    str |> Float.parse |> elem(0)
  end
end
