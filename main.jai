window: Window_Type;
window_width  := cast(s32) 2560;
window_height := cast(s32) 1600;

camera: Camera;
//view_projection_matrix: Matrix4;

enable_gravity := false;
paused := false;
enable_mouse_movement := false;

initialize_scene_function := default_scene;

DT_PHYSICS :: 0.001;

// Don't want to use a general Transform for the camera; it's better to use
// Euler angles to store the current rotation state, and generate the quaternion 
// based on that, rather than updating a quaternion based on current controls.
Camera :: struct {
  // updated directly by controls
  position: Vector3;
  euler_angles: Vector3;

  // not updated directly by controls, calculated from the above
  rotation: Quaternion;  

  // various transformations needed for lighting
  view_matrix: Matrix4;
  projection_matrix: Matrix4;
  view_projection_matrix: Matrix4;
}

/*
Object :: struct {  // I hate 'Entity'
  name: string;

  transform: Transform;
  velocity: Vector3;
  angular_momentum: Vector3;

  mesh: Mesh;
  material: Material;
  color: Vector3;

  enable_movement_physics := true;
  enable_collision_physics := true;
}
*/

initialize_materials :: () {
  array_add(*materials, Material.{ name="PLA", density=1240, restitution=0.6 });
}

main :: () {
  //args := get_command_line_arguments();
  //if args.count < 2 {
  //  log_error("Usage: % <STL filename> <optional model scaling factor>", args[0]);
  //  return;
  //}

  // Hell yeah
  //gltf := gltf_parse_file("./path-to-gltf-or-glb-file");

  camera.position = .{ -10, -5, 4 };
  camera.euler_angles = .{ 0, 0, 0.3 };

  reset_path();
  initialize_scene_function();  // Load meshes and set their properties

  #if OS == .WINDOWS {
    Windows :: #import "Windows";
    Windows.SetProcessDPIAware();
    Windows.timeBeginPeriod(1);
  }

  window = create_window(window_width, window_height, "Ender Engine", wanted_msaa=4);
  actual_msaa_level := Simp.prepare_window(window, wanted_msaa=4);
  window_width, window_height = Simp.get_render_dimensions(window);
  Simp.set_render_target(window, .LEFT_HANDED);

  load_application_fonts();

  initialize_renderer();

  initialize_materials();

  print("==================================================\n");
  print("Initialized engine:\n");
  print("- % objects\n", objects.count);
  for objects {
    print("  %: %\n", it_index, it);
  }
  print("- % meshes\n", meshes.count);
  print("- % materials\n", materials.count);
  print("==================================================\n");

  this_frame_start_time := current_time_monotonic();
  last_frame_start_time := this_frame_start_time;

  //physics_time := this_frame_start_time;
  physics_lag := 0.0;

  should_exit := false;
  frame_index := 0;
  while !should_exit {
    last_frame_start_time = this_frame_start_time;
    this_frame_start_time = current_time_monotonic();
    dt := cast(float) to_float64_seconds(this_frame_start_time - last_frame_start_time);
    if !paused  physics_lag += dt;

    using Input;
    inputs := Input.input_button_states;
    Input.update_window_events();

    for Input.get_window_resizes() {
      Simp.update_window(it.window);

      if it.window == window {
        should_reinit := (it.width != window_width) || (it.height != window_height);

        window_width  = it.width;
        window_height = it.height;
      }
    }

    for event: Input.events_this_frame {
      if event.type == .QUIT {
        should_exit = true;
      } else if event.type == .KEYBOARD && event.key_pressed {
        if event.key_code == {
          case #char "R";       initialize_scene_function();
          case #char "G";       enable_gravity ^= true;
          case #char "P";       paused ^= true;
          case #char "M";       enable_mouse_movement ^= true;
          case #char "Q";       should_exit = true;
        }
      }
    }

    if inputs[#char "Z"] sunlight_intensity -= 100.0*dt;
    if inputs[#char "C"] sunlight_intensity += 100.0*dt;

    while (physics_lag > DT_PHYSICS) {
      simulate_physics(DT_PHYSICS);
      physics_lag -= DT_PHYSICS;
    }

    update_camera(dt);
    render_one_frame(dt);
    draw_gui(this_frame_start_time);
    Simp.swap_buffers(window);

    sleep_milliseconds(10);
    reset_temporary_storage();
  }
}

update_camera :: (dt: float) {
  CAMERA_MOVEMENT_SPEED :: 10.0; // m/s
  CAMERA_ROTATION_SPEED :: 180.0 * TAU/360.0; // rad/s

  using Input;
  inputs := Input.input_button_states;

  camera.euler_angles.x = 0;
  if inputs[Key_Code.ARROW_UP]    camera.euler_angles.y -= CAMERA_ROTATION_SPEED*dt;
  if inputs[Key_Code.ARROW_DOWN]  camera.euler_angles.y += CAMERA_ROTATION_SPEED*dt;
  if inputs[Key_Code.ARROW_LEFT]  camera.euler_angles.z += CAMERA_ROTATION_SPEED*dt;
  if inputs[Key_Code.ARROW_RIGHT] camera.euler_angles.z -= CAMERA_ROTATION_SPEED*dt;

  if enable_mouse_movement{
    camera.euler_angles.z -= 0.0035 * Input.mouse_delta_x;
    camera.euler_angles.y += 0.0035 * Input.mouse_delta_y;
  }

  // avoid rolling over vertical
  camera.euler_angles.y = clamp(camera.euler_angles.y, -89*PI/180, 89*PI/180);

  pitch, yaw: Quaternion;
  set_from_axis_and_angle(*pitch, .{0,1,0}, camera.euler_angles.y);
  set_from_axis_and_angle(*yaw,   .{0,0,1}, camera.euler_angles.z);

  camera.rotation = yaw * pitch;
  normalize_or_identity(*camera.rotation);

  camera_velocity: Vector3;
  if inputs[#char "W"] camera_velocity.x += 1.0;
  if inputs[#char "A"] camera_velocity.y += 1.0; // y is left! right handed!
  if inputs[#char "S"] camera_velocity.x -= 1.0;
  if inputs[#char "D"] camera_velocity.y -= 1.0;
  if inputs[Key_Code.SHIFT] camera_velocity.z += 1.0;
  if inputs[Key_Code.CTRL] camera_velocity.z -= 1.0;

  camera_movement := dt * CAMERA_MOVEMENT_SPEED * normalize(camera_velocity);

  // Rotate movement by yaw, but not by pitch - it feels more natural to go up the 
  // up global z axis when you press shift, rather than object-local z axis
  rotate(*camera_movement, yaw);  
  camera.position += camera_movement;

  camera_transform_matrix := make_translation_matrix4(camera.position) * rotation_matrix(Matrix4, camera.rotation);
  view_success, view_matrix := inverse(camera_transform_matrix);

  // This projection matrix is minuz-z-forward, like the graphics APIs want in the 
  // end. But our world coordinates are... well, what are they?

  // Apparently the sokoban game is x-forward, which implies y-left.

  // There's a note in matrix.jai about swizzling the results of this function
  // to change minus-z-forward to x-forward. I guess that's what we want to do here?

  // using 73 as the vertical FOV (close to csgo)
  // Not sure if the other constants are optimal - look back at the impl at some point
  projection_matrix := make_projection_matrix(73.0*PI/180.0, 16.0/9.0, 0.1, 1000.0);

  // We need this correction matrix to 'fix' the axes going into the projection,
  // which is negative-z-forward.
  // After looking at what people like best in other engines, we're using x-forward
  // (y-left, z-up) for world coordinates.
  // So on the way into the projection matrix, we need to map:
  correction: Matrix4;
  correction._12 = -1;  // negative y to x
  correction._23 = 1;   // z to y
  correction._31 = -1;  // negative x to z
  correction._44 = 1;   // (homogeneous coordinates need this)

  projection_matrix = projection_matrix * correction;
  camera.view_projection_matrix = projection_matrix * view_matrix;
}


// I haven't searched *that* hard, but so far, this has been the best resource for overall game physics:
// https://research.ncl.ac.uk/game/mastersdegree/gametechnologies/physicstutorials/
simulate_physics :: (dt: float) {
  for *object: objects {
    using object;
    if !(flags & flags.ENABLE_MOVEMENT_PHYSICS)  continue;

    material := lookup(materials, material_handle);
    mesh := lookup(meshes, mesh_handle);
    //print("Obj: %, transform %\n", name, transform);
    //print("Obj: %, meshvolume %\n", name, mesh.volume);

    density := material.density;
    mass := material.density * mesh.volume;
    //print("Obj: %, material %\n", name, material.*);
    //print("Obj: %, volume %\n", name, mesh.volume);

    R := rotation_matrix(Matrix3, transform.rotation);  
    //world_inverse_inertia_tensor := R * inverse(density * mesh.inertia_tensor) * transpose(R);
    //print("vel %\n", velocity);

    success, inv := inverse(density * mesh.inertia_tensor);
    world_inverse_inertia_tensor := R * inv * transpose(R);

    net_linear_momentum_change := Vector3.{0, 0, 0};
    net_torque := Vector3.{};

    collision_happened := false;
    collision_point := Vector3.{};
    lowest_vertex := R*mesh.vertices[0].position + transform.position;

    /*
    for vertex: mesh.vertices {
      worldspace_pos := R*vertex.position + transform.position;
      if worldspace_pos.z < lowest_vertex.z || it_index == 0 {
        lowest_vertex = worldspace_pos;
      }
    }
    collision_point = lowest_vertex;
    */

    num_collision_vertices := 0;
    for vertex: mesh.vertices {
      worldspace_pos := R*vertex.position + transform.position;
      if worldspace_pos.z < 0.0 {
        collision_happened = true;
        num_collision_vertices += 1;
        collision_point += worldspace_pos;
        if worldspace_pos.z < lowest_vertex.z  lowest_vertex = worldspace_pos;
      }
    }
    if collision_happened  collision_point /= cast(float)num_collision_vertices;

    if collision_happened {
      z := collision_point.z;
      lever_arm := collision_point - transform.position;

      coefficient_of_restitution := 0.5;
      //coefficient_of_restitution := 0.1;
      collision_normal := Vector3.{0,0,1};

      // this will be calculated again later for the *update*
      // but we need it here for the collision response
      w := world_inverse_inertia_tensor * angular_momentum;

      v_rel := velocity + cross_product(w, lever_arm);
      v_n_i := dot_product(v_rel, collision_normal);
      v_n_f := -coefficient_of_restitution * v_n_i;

      impulse_numerator := -(1 + coefficient_of_restitution) * dot_product(v_rel, collision_normal);
      impulse_denominator := 1.0/mass + dot_product(
        world_inverse_inertia_tensor * cross_product(cross_product(lever_arm, collision_normal), lever_arm),
        collision_normal
      );

      // J = m*delta_v = F*delta_t
      impulse := impulse_numerator / impulse_denominator * collision_normal;

      // F = J/delta_t
      net_linear_momentum_change += impulse;

      // delta_L = torque * dt = (r x F) * dt = (r x (J/dt))*dt
      net_torque += cross_product(lever_arm, impulse);

      transform.position.z += abs(lowest_vertex.z) * 1.5;
      //transform.position.z += abs(collision_point.z) * 1.5;
      //transform.position.z += abs(collision_point.z);

      //print("obj %, v_rel %, v_n_i %, v_n_f %, impulse %\n", name, v_rel, v_n_i, v_n_f, impulse);

      //print("obj %, v_rel %, impulse %\n", name, v_rel, impulse);
      //print("                torque %\n", net_torque);
    }

    //angular_momentum += net_angular_momentum_change;
    //angular_momentum += net_torque * dt;
    angular_momentum += net_torque;

    tol := 0.01;
    if enable_gravity && (lowest_vertex.z > 0.0 || abs(velocity.z) > tol) {
      net_linear_momentum_change += mass * .{0, 0, -9.8} * dt;
    } else {
      //print("% defying gravity\n", name);
    }
    //print("obj %, mass %\n", name, mass);
    

    velocity += net_linear_momentum_change / mass;
    //print("obj %: pos %, vel %, ang mom %\n", name, transform.position, velocity, angular_momentum);


    transform.position += velocity*dt;

    // Need the rotation matrix, not quaternion, for this operation, at least as I understand it
    //w := R * inverse(density * mesh.inertia_tensor) * transpose(R) * angular_momentum;
    w := world_inverse_inertia_tensor * angular_momentum;

    rotation_change: Quaternion;
    set_from_axis_and_angle(*rotation_change, w, dt*length(w));
    transform.rotation = rotation_change * transform.rotation;
    normalize_or_identity(*transform.rotation);

    // AFTER all other position updates, do the final collision resolution step
    /*
    should_resolve_position := false;
    lowest_vertex = R*mesh.vertices[0].position + transform.position;
    for vertex: mesh.vertices {
      worldspace_pos := R*vertex.position + transform.position;
      if worldspace_pos.z < 0.0 && worldspace_pos.z < lowest_vertex.z  {
        should_resolve_position = true;
        lowest_vertex = worldspace_pos;
      }
    }
    if should_resolve_position { 
      transform.position.z += abs(lowest_vertex.z);
    }
    */
  }
}

#load "engine.jai";
#load "mesh.jai";
#load "renderer.jai";
#load "gui.jai";
#load "scenes.jai";

#import "Basic";
#import "GL";
Input :: #import "Input";
#import "Math";
Simp :: #import "Simp";
#import "String";
#import "Window_Creation";

//#import "gltf_parser";
