alias Tinyrenderer.Image

white = %{r: 255, g: 255, b: 255}
red = %{r: 255, g: 0, b: 0}

Image.new(height: 1000, width: 1000)
|> Image.line(130, 200, 800, 400, white)
|> Image.line(200, 130, 400, 800, red)
|> Image.line(800, 400, 130, 200, red)
|> Image.write("tinyrenderer.bmp")
