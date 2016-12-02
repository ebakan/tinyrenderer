alias Tinyrenderer.Image
alias Tinyrenderer.OBJ.Model

width = 1000
height = 1000

white = %{r: 255, g: 255, b: 255}
#red = %{r: 255, g: 0, b: 0}
#
#jjjjjjjjjjj
#|> Image.line(130, 200, 800, 400, white)
#|> Image.line(200, 130, 400, 800, red)
#|> Image.line(800, 400, 130, 200, red)
#|> Image.write("tinyrenderer.bmp")

model = Model.read("obj/african_head.obj")
model.faces
|> Enum.reduce(Image.new(height: height, width: width), fn(face, image) ->
  face
  |> Enum.map(&Map.get(&1, :vertex))
  |> Enum.map(&Enum.at(model.vertices, &1))
  |> (fn([head|tail]) -> [head | tail] ++ [head] end).()
  |> Enum.chunk(2, 1)
  |> Enum.reduce(image, fn([v0, v1], img) ->
    img
    |> Image.line(
      round((v0.x + 1) * width / 2),
      round((v0.y + 1) * height / 2),
      round((v1.x + 1) * width / 2),
      round((v1.y + 1) * height / 2),
      white
    )
  end)
end)
|> Image.write("tinyrenderer.bmp")
