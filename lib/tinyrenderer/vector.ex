defmodule Tinyrenderer.Vector do
  alias __MODULE__

  def cross(u, v) do
    %{
      x: u.y * v.z - u.z * v.y,
      y: u.z * v.x - u.x * v.z,
      z: u.x * v.y - u.y * v.x
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
end
