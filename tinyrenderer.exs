alias Tinyrenderer.Image
alias Tinyrenderer.OBJ.Model

width = 1000
height = 1000

white = %{r: 255, g: 255, b: 255}
#red = %{r: 255, g: 0, b: 0}

Image.new(height: height, width: width)
|> Image.render_model(Model.read!("obj/african_head.obj"), white)
|> Image.write("tinyrenderer.bmp")
