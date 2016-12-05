defmodule Tinyrenderer.Shader.GouradShader do
  alias Tinyrenderer.{Vector, Matrix}

  defstruct [:transform, :texture, :color, :light_dir, intensity: %{}, uv: %{}]

  def vertex(shader, %{vertex: vertex, texture: texture, normal: normal}, i) do
    { %{shader |
        uv: shader.uv |> Map.put(i, texture |> Vector.uvw_to_xyz),
        intensity: shader.intensity
                    |> Map.put(Enum.at([:x, :y, :z], i),
                               normal
                               |> Vector.dot(shader.light_dir)
                               |> max(0))},
      shader.transform
      |> Matrix.mul(vertex)
      |> Matrix.to_vector
      |> Vector.round_values }
  end

  def fragment(shader, b_coords) do
    texture = shader.texture
    color =
      if texture do
        texture_coords = Vector.inv_barycentric_coords(b_coords, 0..2 |> Enum.map(&(shader.uv[&1])))
        texture.pixel_data[round(texture_coords.y * texture.height)][round(texture_coords.x * texture.width)]
      else
        shader.color || [255, 255, 255]
      end
      intensity = shader.intensity |> Vector.dot(b_coords)
    {:ok, shader, color |> Enum.map(&(round(&1 * intensity)))}
  end
end

