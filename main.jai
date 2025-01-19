/*

  so it sounds like our program has our vertex data in OBJECT LOCAL SPACE, we send those vertices to the GPU
  then the VERTEX SHADER does the transformations into world space, then camera space(?), then canonical view volume [-1, 1].

  so our game objects need to keep track of their position/rotation, and then I guess we pass those to the vertex shader somehow

  and reiterating: the vertex shader should output vertices in [-1, 1].

  the VERTEX SHADER's output is fed to the PRIMITIVE SETUP AND RASTERIZATION fixed function step (in modern OpenGL at least)
  this does all the occlusion, Z buffer calculations, etc. it outputs pixels

  (a GEOMETRY SHADER or TESSELLATION SHADER can OPTIONALLY process pixels after the vertex shader, before the rasterization step. 
   it receives all 3  vertices of each triangle, rather than just 1 vertex at a time.)

  the RASTERIZATION step's output pixels are fed into the FRAGMENT SHADER, which decides what their colors will be.


*/


/*

  GL quirks and notes

  the VERTEX ARRAY OBJECT is a poorly named concept that seems to describe
  a set of vertex attributes?

  the lecturer gave the example of having a vertex array for your chair object,
  which keeps track of the attributes you need for the chair, and then you
  switch to a different vertex array for the table, etc.

  you need at least one vertex array object.

 */

window: Window_Type;
window_width  := cast(s32) 2560;
window_height := cast(s32) 1600;

camera: Camera;
view_projection_matrix: Matrix4;

sunlight_intensity := 100.0;
sunlight_direction :: #run normalize(Vector3.{ 1.5, 1.3, 1 });
//sunlight_direction :: #run normalize(Vector3.{ 0, 1, 0 });

sky_color :: Vector3.{100.0/256, 107.0/256, 120.0/256};

// light_transform :: Transform.{
//   position=.{
// };

// Don't want to use a general Transform for the camera; it's better to use
// Euler angles to store the current rotation state, and generate the quaternion 
// based on that, rather than updating a quaternion based on current controls.
Camera :: struct {
  // updated directly by controls
  position: Vector3;
  euler_angles: Vector3;

  // not updated directly by controls
  rotation: Quaternion;  

  // various transformations needed for lighting
  view_matrix: Matrix4;
  projection_matrix: Matrix4;
  view_projection_matrix: Matrix4;
}

Transform :: struct {
  position: Vector3;
  rotation: Quaternion;
}

Object :: struct {  // I hate 'Entity'
  name: string;

  transform: Transform;
  velocity: Vector3;
  angular_momentum: Vector3;

  density: float;

  mesh: Mesh;
  color: Vector3;

  enable_movement_physics := true;
  enable_collision_physics := true;

  // GL stuff, should we move this inside the Mesh maybe? Or something else?
  mesh_shader_program: GLuint;
  mesh_vertex_buffer_object, mesh_vertex_array_object: GLuint;
}

Material :: enum {
  PLA :: 0;
}

density_of :: (material: Material) -> float {  // in kg/m^3
  if material == .PLA  return 1240.0;
  return 1000.0;
}

objects: [..] Object;
mesh_shader_program: GLuint;

get_object :: (name: string) -> *Object {
  for * objects {
    if it.name == name {
      return it;
    }
  }
  return null;
}

initialize_scene :: () {
  stl_object := get_object("STL model");
  stl_object.transform.position = .{ 0, 0, 10 };
  stl_object.transform.rotation = .{};
  stl_object.velocity = .{};
  //stl_object.angular_momentum = .{7, 60, 13};
  stl_object.angular_momentum = .{0, 0, 1300};
  stl_object.color = .{ 0.6, 0.2, 0.2 };
  stl_object.density = density_of(.PLA);

  floor_object := get_object("Floor");
  floor_object.color = 0.6 * sky_color;
  floor_object.enable_movement_physics = false;
}

main :: () {
  args := get_command_line_arguments();
  if args.count < 2 {
    log_error("Usage: % <STL filename> <optional model scaling factor>", args[0]);
    return;
  }

  filename := args[1];

  scale := 1.0;
  if args.count > 2  scale = parse_float(*args[2]);

  array_add(*objects, Object.{name="STL model"});
  stl_object := *objects[objects.count-1];
  //stl_object.mesh = load_mesh_from_stl_file(filename, scale=scale);
  stl_object.mesh = make_test_cube(side_length=scale);

  array_add(*objects, Object.{name="Floor"});
  floor_object := *objects[objects.count-1];
  floor_object.mesh = load_mesh_from_stl_file("assets/floor_big.stl");

  initialize_scene();  // After loading some meshes, set their other properties. 

  camera.position = .{ -30, -30, 4 };
  camera.euler_angles = .{ 0, 0, 0.2 };

  #if OS == .WINDOWS {
    Windows :: #import "Windows";
    Windows.SetProcessDPIAware();
    Windows.timeBeginPeriod(1);
  }

  window = create_window(window_width, window_height, "Motive Engine", wanted_msaa=4);
  actual_msaa_level := Simp.prepare_window(window, wanted_msaa=4);
  window_width, window_height = Simp.get_render_dimensions(window);
  Simp.set_render_target(window, .LEFT_HANDED);

  initialize_renderer();

  this_frame_start_time := current_time_monotonic();
  last_frame_start_time := this_frame_start_time;

  should_exit := false;
  while !should_exit {
    using Input;
    inputs := Input.input_button_states;
    if inputs[#char "R"] initialize_scene();   // Reset

    last_frame_start_time = this_frame_start_time;
    this_frame_start_time = current_time_monotonic();
    dt := cast(float) to_float64_seconds(this_frame_start_time - last_frame_start_time);

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
      }
    }

    simulate_physics(dt);
    update_camera(dt);
    render_one_frame(dt);

    sleep_milliseconds(10);
    reset_temporary_storage();
  }
}

simulate_physics :: (dt: float) {
  for *object: objects {
    using object;

    if enable_movement_physics {
      //velocity += Vector3.{0, 0, -9.8*dt};  // Gravity

      {
        // @Temporary
        using Input;
        inputs := Input.input_button_states;
        OBJECT_MOVEMENT_SPEED :: 25.0; // m/s
        if inputs[#char "J"] && !inputs[#char "K"] {
          transform.position.y -= OBJECT_MOVEMENT_SPEED*dt;
        } else if !inputs[#char "J"] && inputs[#char "K"] {
          transform.position.y += OBJECT_MOVEMENT_SPEED*dt;
        }
      }

      transform.position += velocity*dt;

      // Need the rotation matrix, not quaternion, for this operation, at least as I understand it
      R := rotation_matrix(Matrix3, transform.rotation);  
      w := R * inverse(mesh.inertia_tensor * density) * transpose(R) * angular_momentum;

      rotation_change: Quaternion;
      set_from_axis_and_angle(*rotation_change, w, dt*length(w));
      transform.rotation *= rotation_change;
      normalize_or_identity(*transform.rotation);
    }
  }
}

update_camera :: (dt: float) {
  CAMERA_MOVEMENT_SPEED :: 25.0; // m/s
  CAMERA_ROTATION_SPEED :: 180.0 * TAU/360.0; // rad/s

  using Input;
  inputs := Input.input_button_states;

  camera.euler_angles.x = 0;

  if inputs[Key_Code.ARROW_UP] && !inputs[Key_Code.ARROW_DOWN] {
    camera.euler_angles.y -= CAMERA_ROTATION_SPEED*dt;
  } else if !inputs[Key_Code.ARROW_UP] && inputs[Key_Code.ARROW_DOWN] {
    camera.euler_angles.y += CAMERA_ROTATION_SPEED*dt;
  }
  // avoid rolling over vertical
  camera.euler_angles.y = clamp(camera.euler_angles.y, -89*PI/180, 89*PI/180);

  if inputs[Key_Code.ARROW_LEFT] && !inputs[Key_Code.ARROW_RIGHT] {
    camera.euler_angles.z += CAMERA_ROTATION_SPEED*dt;
  } else if !inputs[Key_Code.ARROW_LEFT] && inputs[Key_Code.ARROW_RIGHT] {
    camera.euler_angles.z -= CAMERA_ROTATION_SPEED*dt;
  }

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

  if inputs[#char "Z"] sunlight_intensity -= 100.0*dt;
  if inputs[#char "C"] sunlight_intensity += 100.0*dt;

  camera_movement := dt * CAMERA_MOVEMENT_SPEED * normalize(camera_velocity);
  //rotate(*camera_movement, camera.rotation);
  // Rotate movement by yaw, but not by pitch - it feels more natural to go up the 
  // up global z axis when you press shift, rather than object-local z axis
  rotate(*camera_movement, yaw);  
  camera.position += camera_movement;

  camera_transform_matrix := make_translation_matrix4(camera.position) * rotation_matrix(Matrix4, camera.rotation);
  view_matrix := inverse(camera_transform_matrix);

  // This projection matrix is minuz-z-forward, like the graphics APIs want in the 
  // end. But our world coordinates are... well, what are they?

  // Apparently the sokoban game is x-forward, which implies y-left.

  // There's a note in matrix.jai about swizzling the results of this function
  // to change minus-z-forward to x-forward. I guess that's what we want to do here?

  // using 73 as the vertical FOV (close to csgo)
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
  view_projection_matrix = projection_matrix * view_matrix;
}

render_one_frame :: (dt: float) {
  glDepthMask(GL_TRUE);
  glEnable(GL_DEPTH_TEST);
  Simp.clear_render_target(sunlight_intensity/100 * sky_color.x, sunlight_intensity/100*sky_color.y, sunlight_intensity/100*sky_color.z, 1.0);
  glClear(GL_DEPTH_BUFFER_BIT);

  for object: objects {
    render_object(object, camera);
  }
  //render_mesh(mesh_transform);

  Simp.swap_buffers(window);
}

render_object :: (using object: Object, camera: Camera) {
  glBindVertexArray(mesh_vertex_array_object);
  glBindBuffer(GL_ARRAY_BUFFER, mesh_vertex_buffer_object);
  glUseProgram(mesh_shader_program); 

  model_rotation := rotation_matrix(Matrix4, transform.rotation);
  model_translation := make_translation_matrix4(transform.position);
  model_matrix := model_translation * model_rotation;

  glUniformMatrix4fv(glGetUniformLocation(mesh_shader_program, "model_rotation"), 1, GL_TRUE, *model_rotation.coef[0][0]); 
  glUniformMatrix4fv(glGetUniformLocation(mesh_shader_program, "model_translation"), 1, GL_TRUE, *model_translation.coef[0][0]); 
  glUniformMatrix4fv(glGetUniformLocation(mesh_shader_program, "view_projection_matrix"), 1, GL_TRUE, *view_projection_matrix.coef[0][0]);

  // 3 floats in memory (glUniform3f takes separate args for each float)
  glUniform3fv(glGetUniformLocation(mesh_shader_program, "sunlight_direction"), 1, cast(*float) *sunlight_direction);
  glUniform1f(glGetUniformLocation(mesh_shader_program, "sunlight_intensity"), sunlight_intensity);

  glUniform4fv(glGetUniformLocation(mesh_shader_program, "object_base_color"), 1, cast(*float) *color);

  glDrawArrays(GL_TRIANGLES, 0, cast(u32) mesh.vertices.count);
}

initialize_renderer :: () {
  // should this stay global? do we need to keep track of it at the top level?
  mesh_shader_program = compile_and_link_shader_program(VERTEX_SHADER_SOURCE, FRAGMENT_SHADER_SOURCE);

  for * object: objects {
    object.mesh_shader_program = mesh_shader_program;
    using object;
    glGenBuffers(1, *mesh_vertex_buffer_object);
    glBindBuffer(GL_ARRAY_BUFFER, mesh_vertex_buffer_object);
    defer glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBufferData(GL_ARRAY_BUFFER, mesh.vertices.count*size_of(Vertex), mesh.vertices.data, GL_STATIC_DRAW);

    glGenVertexArrays(1, *mesh_vertex_array_object);
    glBindVertexArray(mesh_vertex_array_object);
    defer glBindVertexArray(0);

    position_attribute_location := glGetAttribLocation(mesh_shader_program, "position");
    glEnableVertexAttribArray(cast(GLuint) position_attribute_location);
    glVertexAttribPointer(cast(GLuint) position_attribute_location, 3, GL_FLOAT, GL_FALSE, size_of(Vertex), xx 0);

    normal_attribute_location   := glGetAttribLocation(mesh_shader_program, "normal");
    glEnableVertexAttribArray(cast(GLuint) normal_attribute_location);
    glVertexAttribPointer(cast(GLuint) normal_attribute_location, 3, GL_FLOAT, GL_FALSE, size_of(Vertex), xx size_of(Vector3));   // offset = one vec3
  }
}

VERTEX_SHADER_SOURCE :: #string END
  #version 330 core

  // The input vertex position (this is a vertex attribute, per-vertex info)
  // This doesn't receive data automatically - we have to attach the VERTEX ATTRIBUTE to a VERTEX BUFFER.
  // The VERTEX BUFFER is where we can write data on the CPU side, to send that data to the GPU.

  layout(location=0) in vec3 position;   
  layout(location=1) in vec3 normal;   

  out vec3 normal_for_color;

  //uniform mat4 model_matrix;  // model space -> world space
  uniform mat4 model_rotation;  // model space -> world space
  uniform mat4 model_translation;  // model space -> world space
  uniform mat4 view_projection_matrix;  // world space -> canonical view volume

  void main() {
    // gl_Position is *the* required output of a vertex shader
    mat4 model_matrix = model_translation * model_rotation;
    gl_Position = view_projection_matrix * model_matrix * vec4(position, 1);

    normal_for_color = (model_rotation * vec4(normal, 1)).xyz;
    normal_for_color = normal_for_color / length(normal_for_color);
  }
END

FRAGMENT_SHADER_SOURCE :: #string END
  #version 330 core

  // Is this output position automatically used for color? TODO
  layout(location=0) out vec4 color; 

  in vec4 position_for_color;
  uniform vec4 object_base_color;

  uniform float sunlight_intensity;
  uniform vec3 sunlight_direction;

  in vec3 normal_for_color;

  void main() {
    //color = position_for_color; // multicolor for debugging

    color = object_base_color;
    color = color * sunlight_intensity/100;
    color = color * (0.4*dot(normal_for_color, sunlight_direction) + 0.6);
  }
END

// GL boilerplate to compile and link our shaders.
compile_and_link_shader_program :: (vertex_shader_source: string, fragment_shader_source: string) -> GLuint {
  assert_shader_compiled_successfully :: (shader: GLuint) {
    shader_compiled_successfully: GLint;
    glGetShaderiv(shader, GL_COMPILE_STATUS, *shader_compiled_successfully);
    if shader_compiled_successfully  return;

    log_length: GLint;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, *log_length);
    message := string.{ data=alloc(log_length,, temp), count=log_length };
    glGetShaderInfoLog(shader, xx log_length, xx *log_length, message.data);
    assert(false, tprint("Shader % compilation failed: %", shader, message));
  }

  assert_program_linked_successfully :: (program: GLuint) {
    program_linked_successfully: GLint;
    glGetProgramiv(program, GL_LINK_STATUS, *program_linked_successfully);
    if program_linked_successfully  return;

    log_length: GLint;
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, *log_length);
    message := string.{ data=alloc(log_length,, temp), count=log_length };
    glGetProgramInfoLog(program, xx log_length, xx *log_length, message.data);
    assert(false, tprint("Shader program % linking failed: %", program, message));
  }

  vertex_shader := glCreateShader(GL_VERTEX_SHADER);
  defer glDeleteShader(vertex_shader);
  length := cast(GLint) vertex_shader_source.count;
  glShaderSource(vertex_shader, 1, *vertex_shader_source.data, *length);
  glCompileShader(vertex_shader);
  assert_shader_compiled_successfully(vertex_shader);

  fragment_shader := glCreateShader(GL_FRAGMENT_SHADER);
  defer glDeleteShader(fragment_shader);
  length  = cast(GLint) fragment_shader_source.count;
  glShaderSource(fragment_shader, 1, *fragment_shader_source.data, *length);
  glCompileShader(fragment_shader);
  assert_shader_compiled_successfully(fragment_shader);

  shader_program := glCreateProgram();
  glAttachShader(shader_program, vertex_shader);
  glAttachShader(shader_program, fragment_shader);
  glLinkProgram(shader_program);
  assert_program_linked_successfully(shader_program);

  return shader_program;
}

#load "mesh.jai";

#import "Basic";
#import "GL";
Input :: #import "Input";
#import "Math";
Simp :: #import "Simp";
#import "String";
#import "Window_Creation";
