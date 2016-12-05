defmodule Tinyrenderer.Vector do
  alias __MODULE__

  def cross(u, v) do
    %{
      x: u.y * v.z - u.z * v.y,
      y: u.z * v.x - u.x * v.z,
      z: u.x * v.y - u.y * v.x
    }
  end

  def add(u, v) do
    %{
      x: u.x + v.x,
      y: u.y + v.y,
      z: u.z + v.z
    }
  end

  def sub(u, v) do
    %{
      x: u.x - v.x,
      y: u.y - v.y,
      z: u.z - v.z
    }
  end

  def dot(u, v) do
    u.x * v.x + u.y * v.y + u.z * v.z
  end

  def mul(u, s) do
    %{
      x: u.x * s,
      y: u.y * s,
      z: u.z * s,
    }
  end

  def norm(u) do
    :math.sqrt(u.x * u.x + u.y * u.y + u.z * u.z)
  end

  def normalize(u) do
    u |> mul(1 / norm(u))
  end

  def round_values(u) do
    u
    |> Enum.map(fn {k,v} ->
      {k, round(v)}
    end)
    |> Map.new
  end

  def uvw_to_xyz(vertex) do
    %{x: vertex.u, y: vertex.v, z: vertex.w}
  end

  def barycentric_coords(p, [v0, v1, v2]) do
    u = Vector.cross(%{x: v2.x - v0.x, y: v1.x - v0.x, z: v0.x - p.x},
                     %{x: v2.y - v0.y, y: v1.y - v0.y, z: v0.y - p.y})
    if abs(u.z) < 1 do
      %{x: -1, y: 1, z: 1} # triangle is degenerate
    else
      %{x: 1 - (u.x + u.y) / u.z, y: u.y / u.z, z: u.x / u.z}
    end
  end
end
