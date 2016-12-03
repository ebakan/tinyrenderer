alias Tinyrenderer.Image
alias Tinyrenderer.OBJ.Model

width = 200
height = 200

white = %{r: 255, g: 255, b: 255}
#red = %{r: 255, g: 0, b: 0}

light_dir = %{x: 0, y: 0, z: -1}

Image.new(height: height, width: width)
|> Image.render_model(Model.read!("obj/african_head.obj"), white, light_dir)
|> Image.write("output.bmp")
