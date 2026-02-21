//default_scene :: cube_only;
//default_scene :: f22_only;
default_scene :: space_1;
//default_scene :: big_scene;

sunlight_intensity := 160.0;
sunlight_direction :: #run normalize(Vector3.{ 1.5, 1.3, 1 });

sky_color := #run Vector3.{100.0/256, 107.0/256, 120.0/256} * 1.1;

cube_only :: () {
  {
    using make_or_get_object("Floor");
    if !mesh_handle  mesh_handle = load_mesh_from_stl_file("../assets/models/floor_big.stl");
    transform.position = .{ 0, 0, -1000 };
    color = 0.8 * sky_color;
    flags &= ~.ENABLE_MOVEMENT_PHYSICS;
  }

  {
    using make_or_get_object("test cube");
    if !mesh_handle  mesh_handle = make_test_cube(side_length=1.0);
    transform.position = .{ 4, 4, 4 };
    transform.rotation = .{};
    velocity = .{};
    //angular_momentum = .{100, 0, 0};
    angular_momentum = .{0, 0, 0};
    color = .{ 0.7, 0.1, 0.1 };
    material_handle = get_material_handle("PLA");
  }
}

space_1 :: () {
  sky_color = .{0.06, 0.05, 0.07};

  camera.position = .{ -10, -5, 0 };

  sphere1_mesh_handle := load_mesh_from_stl_file("../assets/models/sphere1.stl", scale=1.0);
  sphere2_mesh_handle := load_mesh_from_stl_file("../assets/models/sphere2.stl", scale=6000.0);
  diamond_mesh_handle := load_mesh_from_stl_file("../assets/models/diamond1.stl", scale=6.0);

  {
    using make_or_get_object("planet2");
    if !mesh_handle  mesh_handle = sphere2_mesh_handle;
    transform.position = .{ 0, 0, -6_500.0 };
    transform.rotation = .{};
    //velocity = .{0,0,-1};
    //velocity = .{};
    //angular_momentum = .{0, 1300, 0};
    color = .{ 0.2, 0.45, 0.7 };
    material_handle = get_material_handle("PLA");
    flags &= ~.ENABLE_MOVEMENT_PHYSICS;
    flags &= ~.ENABLE_COLLISION_PHYSICS;
  }

  //{
  //  using make_or_get_object("small planet");
  //  if !mesh_handle  mesh_handle = sphere1_mesh_handle;
  //  transform.position = .{ -6, -6, 0 };
  //  transform.rotation = .{};
  //  //velocity = .{0,0,-1};
  //  //velocity = .{};
  //  //angular_momentum = .{0, 1300, 0};
  //  color = .{ 0.2, 0.45, 0.7 };
  //  material_handle = get_material_handle("PLA");
  //}

  {
    using make_or_get_object("diamond");
    if !mesh_handle  mesh_handle = diamond_mesh_handle;
    transform.position = .{ 4, -4, 0 };
    transform.rotation = .{};
    velocity = .{1, 0, 0};
    angular_momentum = .{0, 0, 0};
    color = .{ 0.7, 0.7, 0.7 };
    material_handle = get_material_handle("PLA");
  }

  {
    using make_or_get_object("diamond2");
    if !mesh_handle  mesh_handle = diamond_mesh_handle;
    transform.position = .{ -4, -10, 4 };
    transform.rotation = .{};
    velocity = .{1, 0, 0};
    angular_momentum = .{0, 0, 0};
    color = .{ 0.7, 0.7, 0.7 };
    material_handle = get_material_handle("PLA");
  }

  {
    using make_or_get_object("test cube");
    if !mesh_handle  mesh_handle = make_test_cube(side_length=1.0);
    transform.position = .{ 4, 4, 0 };
    transform.rotation = .{};
    velocity = .{};
    //angular_momentum = .{100, 0, 0};
    angular_momentum = .{0, 0, 0};
    color = .{ 0.7, 0.1, 0.1 };
    material_handle = get_material_handle("PLA");
  }
}

f22_only :: () {
  {
    using floor_object := make_or_get_object("Floor");
    if !mesh_handle  mesh_handle = load_mesh_from_stl_file("../assets/models/floor_big.stl");
    color = 0.8 * sky_color;
    flags &= ~.ENABLE_MOVEMENT_PHYSICS;
  }

  {
    using f22 := make_or_get_object("f22");
    if !mesh_handle  mesh_handle = load_mesh_from_stl_file("../assets/models/F22-raptor.stl", scale=0.008);
    transform.position = .{ 0, 0, 4 };
    transform.rotation = .{};
    velocity = .{};
    //angular_momentum = .{400, 10, -10};
    //angular_momentum = .{0, 400, 0};
    angular_momentum = .{};
    color = .{ 0.4, 0.45, 0.5 };
    material_handle = get_material_handle("PLA");
  }
}

big_scene :: () {
  {
    using floor_object := make_or_get_object("Floor");
    if !mesh_handle  mesh_handle = load_mesh_from_stl_file("../assets/models/floor_big.stl");
    color = 0.8 * sky_color;
    flags &= ~.ENABLE_MOVEMENT_PHYSICS;
  }

  {
    using f22 := make_or_get_object("f22");
    if !mesh_handle  mesh_handle = load_mesh_from_stl_file("../assets/models/F22-raptor.stl", scale=0.008);
    transform.position = .{ 0, 0, 4 };
    transform.rotation = .{};
    velocity = .{};
    //angular_momentum = .{400, 10, -10};
    //angular_momentum = .{0, 400, 0};
    angular_momentum = .{};
    color = .{ 0.4, 0.45, 0.5 };
    material_handle = get_material_handle("PLA");
  }

  {
    using starship := make_or_get_object("starship");
    if !mesh_handle  mesh_handle = load_mesh_from_stl_file("../assets/models/StarshipV1.stl", scale=0.03);
    transform.position = .{ 0, 4, 4 };
    transform.rotation = .{};
    velocity = .{};
    angular_momentum = .{1300, 10, -10};
    //color = .{ 0.9, 0.9, 0.9 };
    color = .{ 0.6, 0.2, 0.2 };
    material_handle = get_material_handle("PLA");
  }

  {
    using hammer := make_or_get_object("hammer");
    if !mesh_handle  mesh_handle = load_mesh_from_stl_file("../assets/models/hammer.stl", scale=0.45);
    transform.position = .{ 4, 0, 4 };
    transform.rotation = .{};
    velocity = .{};
    angular_momentum = .{0, 1300, 0};
    color = .{ 0.2, 0.2, 0.6 };
    material_handle = get_material_handle("PLA");
  }

  {
    using test_cube := make_or_get_object("test cube");
    if !mesh_handle  mesh_handle = make_test_cube(side_length=1.0);
    transform.position = .{ 4, 4, 4 };
    transform.rotation = .{};
    velocity = .{};
    angular_momentum = .{-10, 330, 10};
    color = .{ 0.1, 0.1, 0.1 };
    material_handle = get_material_handle("PLA");
  }
}

