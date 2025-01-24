//default_scene :: cube_only;
default_scene :: f22_only;
//default_scene :: big_scene;

cube_only :: () {
  {
    using floor_object := make_or_get_object("Floor");
    if !initialized(mesh)  mesh = load_mesh_from_stl_file("assets/floor_big.stl");
    color = 0.8 * sky_color;
    enable_movement_physics = false;
  }

  {
    using test_cube := make_or_get_object("test cube");
    if !initialized(mesh)  mesh = make_test_cube(side_length=1.0);
    transform.position = .{ 4, 4, 4 };
    transform.rotation = .{};
    velocity = .{};
    //angular_momentum = .{100, 0, 0};
    angular_momentum = .{0, 0, 0};
    color = .{ 0.7, 0.1, 0.1 };
    density = density_of(.PLA);
  }
}

f22_only :: () {
  {
    using floor_object := make_or_get_object("Floor");
    if !initialized(mesh)  mesh = load_mesh_from_stl_file("assets/floor_big.stl");
    color = 0.8 * sky_color;
    enable_movement_physics = false;
  }

  {
    using f22 := make_or_get_object("f22");
    if !initialized(mesh)  mesh = load_mesh_from_stl_file("assets/F22-raptor.stl", scale=0.008);
    transform.position = .{ 0, 0, 4 };
    transform.rotation = .{};
    velocity = .{};
    //angular_momentum = .{400, 10, -10};
    //angular_momentum = .{0, 400, 0};
    angular_momentum = .{};
    color = .{ 0.4, 0.45, 0.5 };
    density = density_of(.PLA);
  }
}

big_scene :: () {
  {
    using floor_object := make_or_get_object("Floor");
    if !initialized(mesh)  mesh = load_mesh_from_stl_file("assets/floor_big.stl");
    color = 0.8 * sky_color;
    enable_movement_physics = false;
  }

  {
    using f22 := make_or_get_object("f22");
    if !initialized(mesh)  mesh = load_mesh_from_stl_file("assets/F22-raptor.stl", scale=0.008);
    transform.position = .{ 0, 0, 4 };
    transform.rotation = .{};
    velocity = .{};
    //angular_momentum = .{400, 10, -10};
    //angular_momentum = .{0, 400, 0};
    angular_momentum = .{};
    color = .{ 0.4, 0.45, 0.5 };
    density = density_of(.PLA);
  }

  {
    using starship := make_or_get_object("starship");
    if !initialized(mesh)  mesh = load_mesh_from_stl_file("assets/StarshipV1.stl", scale=0.03);
    transform.position = .{ 0, 4, 4 };
    transform.rotation = .{};
    velocity = .{};
    angular_momentum = .{1300, 10, -10};
    //color = .{ 0.9, 0.9, 0.9 };
    color = .{ 0.6, 0.2, 0.2 };
    density = density_of(.PLA);
  }

  {
    using hammer := make_or_get_object("hammer");
    if !initialized(mesh)  mesh = load_mesh_from_stl_file("assets/hammer.stl", scale=0.45);
    transform.position = .{ 4, 0, 4 };
    transform.rotation = .{};
    velocity = .{};
    angular_momentum = .{0, 1300, 0};
    color = .{ 0.2, 0.2, 0.6 };
    density = density_of(.PLA);
  }

  {
    using test_cube := make_or_get_object("test cube");
    if !initialized(mesh)  mesh = make_test_cube(side_length=1.0);
    transform.position = .{ 4, 4, 4 };
    transform.rotation = .{};
    velocity = .{};
    angular_momentum = .{-10, 330, 10};
    color = .{ 0.1, 0.1, 0.1 };
    density = density_of(.PLA);
  }
}

