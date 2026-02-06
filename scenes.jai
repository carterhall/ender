//default_scene :: cube_only;
//default_scene :: f22_only;
default_scene :: space_1;
//default_scene :: big_scene;

sunlight_intensity := 160.0;
sunlight_direction :: #run normalize(Vector3.{ 1.5, 1.3, 1 });

sky_color := #run Vector3.{100.0/256, 107.0/256, 120.0/256} * 1.1;

cube_only :: () {
  {
    using floor_object := make_or_get_object("Floor");
    if !initialized(mesh)  mesh = load_mesh_from_stl_file("assets/floor_big.stl");
    transform.position = .{ 0, 0, -1000 };
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
    material = PLA;
  }
}

space_1 :: () {
  sky_color = .{0.06, 0.05, 0.07};

  camera.position = .{ -10, -5, 1000 };

  {
    using make_or_get_object("planet2");
    if !initialized(mesh)  mesh = load_mesh_from_stl_file("assets/sphere2.stl", scale=6_000.0);
    transform.position = .{ 0, 0, -5_500.0 };
    transform.rotation = .{};
    velocity = .{};
    //angular_momentum = .{0, 1300, 0};
    color = .{ 0.2, 0.45, 0.7 };
    material = PLA;
    enable_movement_physics = false;
    enable_collision_physics = false;
  }

  {
    using make_or_get_object("diamond");
    if !initialized(mesh)  mesh = load_mesh_from_stl_file("assets/diamond1.stl", scale=6.0);
    transform.position = .{ 4, -4, 1000 };
    transform.rotation = .{};
    velocity = .{1, 0, 0};
    //angular_momentum = .{100, 0, 0};
    angular_momentum = .{0, 0, 0};
    color = .{ 0.7, 0.7, 0.7 };
    material = PLA;
  }

  {
    using make_or_get_object("test cube");
    if !initialized(mesh)  mesh = make_test_cube(side_length=1.0);
    transform.position = .{ 4, 4, 1000 };
    transform.rotation = .{};
    velocity = .{};
    //angular_momentum = .{100, 0, 0};
    angular_momentum = .{0, 0, 0};
    color = .{ 0.7, 0.1, 0.1 };
    material = PLA;
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
    material = PLA;
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
    material = PLA;
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
    material = PLA;
  }

  {
    using hammer := make_or_get_object("hammer");
    if !initialized(mesh)  mesh = load_mesh_from_stl_file("assets/hammer.stl", scale=0.45);
    transform.position = .{ 4, 0, 4 };
    transform.rotation = .{};
    velocity = .{};
    angular_momentum = .{0, 1300, 0};
    color = .{ 0.2, 0.2, 0.6 };
    material = PLA;
  }

  {
    using test_cube := make_or_get_object("test cube");
    if !initialized(mesh)  mesh = make_test_cube(side_length=1.0);
    transform.position = .{ 4, 4, 4 };
    transform.rotation = .{};
    velocity = .{};
    angular_momentum = .{-10, 330, 10};
    color = .{ 0.1, 0.1, 0.1 };
    material = PLA;
  }
}

