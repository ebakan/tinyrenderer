alias Tinyrenderer.Image
alias Tinyrenderer.OBJ.Model

size = 1000

Image.new(height: size, width: size)
|> Image.render_model(Model.read!("obj/african_head.obj"),
                      light_dir: %{x: 0, y: 0, z: -1},
                      texture: Image.read("obj/african_head_diffuse.bmp"),
                      eye: %{x: 1, y: 1, z: 3.0},
                      center: %{x: 0, y: 0, z: 0})
|> Image.write("output.bmp")
