defmodule Tinyrenderer.Math do
  def cross(u, v) do
    %{
      x: u.y * v.z - u.z * v.y,
      y: u.z * v.x - u.x * v.z,
      z: u.x * v.y - u.y * v.x
    }
  end
end
