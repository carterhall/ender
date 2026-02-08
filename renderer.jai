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


render_one_frame :: (dt: float) {
  glDepthMask(GL_TRUE);
  glEnable(GL_DEPTH_TEST);
  Simp.clear_render_target(sunlight_intensity/100 * sky_color.x, sunlight_intensity/100*sky_color.y, sunlight_intensity/100*sky_color.z, 1.0);
  glClear(GL_DEPTH_BUFFER_BIT);

  for object: objects {
    render_object(object, camera);
  }

  Simp.set_shader_for_color();
  Simp.draw_text(font_regular, 30, 30, "Some Text!", .{1,1,1,0.5});
  Simp.draw_text(font_regular, 60, 60, "Some Text!", .{0,0,0,1});

  Simp.swap_buffers(window);
}

render_object :: (using object: Object, camera: Camera) {
  mesh_shader_program := mesh.shader_program;

  glBindVertexArray(mesh.vertex_array_object);
  glBindBuffer(GL_ARRAY_BUFFER, mesh.vertex_buffer_object);
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

  glUniform1i(glGetUniformLocation(mesh_shader_program, "use_checkerboard"), xx ifx name == "Floor" then 1 else 0);

  glDrawArrays(GL_TRIANGLES, 0, cast(u32) mesh.vertices.count);
}

draw_sphere :: (position: Vector3, radius: float, color: Vector4) {

}

initialize_renderer :: () {
  mesh_shader_program := compile_and_link_shader_program(VERTEX_SHADER_SOURCE, FRAGMENT_SHADER_SOURCE);

  for * object: objects {
    object.mesh.shader_program = mesh_shader_program;
    using object;
    glGenBuffers(1, *mesh.vertex_buffer_object);
    glBindBuffer(GL_ARRAY_BUFFER, mesh.vertex_buffer_object);
    defer glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBufferData(GL_ARRAY_BUFFER, mesh.vertices.count*size_of(Vertex), mesh.vertices.data, GL_STATIC_DRAW);

    glGenVertexArrays(1, *mesh.vertex_array_object);
    glBindVertexArray(mesh.vertex_array_object);
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
  out vec3 position_in_modelspace_for_checkerboard;

  uniform mat4 model_rotation;  // model space -> world space
  uniform mat4 model_translation;  // model space -> world space
  uniform mat4 view_projection_matrix;  // world space -> canonical view volume

  void main() {
    // gl_Position is *the* required output of a vertex shader
    mat4 model_matrix = model_translation * model_rotation;
    gl_Position = view_projection_matrix * model_matrix * vec4(position, 1);

    normal_for_color = (model_rotation * vec4(normal, 1)).xyz;
    normal_for_color = normal_for_color / length(normal_for_color);

    position_in_modelspace_for_checkerboard = position;
  }
END

FRAGMENT_SHADER_SOURCE :: #string END
  #version 330 core

  // Is this output position automatically used for color? TODO
  layout(location=0) out vec4 color; 

  in vec3 position_in_modelspace_for_checkerboard;
  uniform bool use_checkerboard;

  uniform vec4 object_base_color;

  uniform float sunlight_intensity;
  uniform vec3 sunlight_direction;

  in vec3 normal_for_color;

  void main() {
    // Look at coords within the model to apply a checkerboard "texture"
    color = object_base_color;
    if (use_checkerboard) {
      vec3 modelspace_pos = position_in_modelspace_for_checkerboard;
      int x_floored = int(floor(1 * modelspace_pos.x));
      int y_floored = int(floor(1 * modelspace_pos.y));
      if (x_floored % 2 == 0 ^^ y_floored % 2 == 0) {
        color = object_base_color * 0.95;
      }
    }

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

#import "GL";
