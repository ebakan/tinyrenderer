defmodule Tinyrenderer.Shader.GouradShader do
  alias Tinyrenderer.{Vector, Matrix}

  defstruct [:transform,
             :texture,
             :color,
             :light_dir,
             triangle: Matrix.new(4, 3),
             intensity: %{},
             uv: Matrix.new(3)]

  def vertex(shader, %{vertex: vertex, texture: texture, normal: normal}, i) do
    %{shader |
      uv: shader.uv |> Matrix.set_col(i, texture |> Vector.uvw_to_xyz),
      intensity: shader.intensity |> Map.put(Enum.at([:x, :y, :z], i), max(0, Vector.dot(normal, shader.light_dir))),
      triangle: shader.triangle |> Matrix.set_col(i, shader.transform
                                                  |> Matrix.mul(vertex)
                                                  |> List.flatten)}
  end

  def fragment(shader, b_coords) do
    texture = shader.texture
    color =
      if texture do
        texture_coords = shader.uv
                         |> Matrix.mul([[b_coords.x], [b_coords.y], [b_coords.z]])
                         |> Matrix.to_vector
        texture.pixel_data[round(texture_coords.y * texture.height)][round(texture_coords.x * texture.width)]
      else
        shader.color || [255, 255, 255]
      end
    intensity = shader.intensity |> Vector.dot(b_coords)
    {:ok, shader, color |> Enum.map(&(round(&1 * intensity)))}
  end
end

