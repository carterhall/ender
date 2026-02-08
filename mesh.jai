// Most of this file is implementation details - loading the STL, calculating the 
// inertia tensor.
// Just a little bit of public stuff at the top.

Vertex :: struct {
  position: Vector3;
  normal: Vector3;
}

Mesh :: struct {   
  // This is a simple triangle mesh. Vertices must form independent triangles.
  vertices: [..] Vertex;

  // Physics properties
  inertia_tensor: Matrix3;
  center_of_mass: Vector3;
  volume: float;

  // Rendering
  shader_program: GLuint;
  vertex_buffer_object, vertex_array_object: GLuint;
}

initialized :: (mesh: Mesh) -> bool {
  return mesh.vertices.count != 0;
}

// This function seems like the right API, but I don't love how it's basically just 
// orchestrating these other functions
load_mesh_from_stl_file :: (file_path: string, scale := 1.0) -> Mesh {
  stl_model := load_stl_model(file_path); 

  mesh := stl_model_to_mesh(stl_model, scale=scale);

  inertia_tensor, center_of_mass, volume := mass_properties_of_triangle_mesh(mesh);

  mesh.inertia_tensor = inertia_tensor;
  mesh.center_of_mass = center_of_mass;
  mesh.volume = volume;
  for * mesh.vertices  it.position -= center_of_mass; 

  print("Mesh % has center of mass %, inertia tensor %, volume %\n", file_path, center_of_mass, inertia_tensor, volume);

  return mesh;
}

make_test_canonical_tetrahedron :: () -> Mesh {
  mesh: Mesh;
  // TODO
  return mesh;
}

//make_test_cube :: (side_length := 1.0, center_of_mass := Vector3.{1, 2, 3}) -> Mesh {
make_test_cube :: (side_length := 1.0, center_of_mass := Vector3.{0, 0, 0}) -> Mesh {
  mesh: Mesh;

  normals: [..] Vector3;
  for axis: 0..2 {
    v: Vector3;
    v.component[axis] = -1;
    array_add(*normals, v);
    array_add(*normals, -v);
  }

  for normal: normals {
    for i_vert: 0..5 {
      _i_vert := ifx i_vert < 3 then i_vert else i_vert - 1;
      position := normal;

      local_x := cos(TAU/8 + _i_vert*TAU/4) / cos(TAU/8);
      local_y := sin(TAU/8 + _i_vert*TAU/4) / cos(TAU/8);

      set_local_x := false;
      for 0..2 {
        if !set_local_x && position.component[it] == 0.0 {
          position.component[it] = local_x;
          set_local_x = true;
        } else if set_local_x && position.component[it] == 0.0 {
          position.component[it] = local_y;
        }
      }

      position = 0.5*side_length*position;
      array_add(*mesh.vertices, Vertex.{ position=position+center_of_mass, normal=normal });
    }
  }

  inertia_tensor, _center_of_mass, volume := mass_properties_of_triangle_mesh(mesh);

  // This is the explicit formula for the inertia tensor of a cube, useful for sanity
  // checking our rotation code without involving our inertia tensor calculation.
  //inertia_tensor = volume * side_length/6.0 * Matrix3_Identity;
  print("Explicit cube inertia tensor:\n  %\n", volume * side_length/6.0 * Matrix3_Identity);

  // from   inertia_tensor = Matrix3_Identity*trace(C) - C,
  // C must be 1/12 * Matrix3_Identity.

  mesh.inertia_tensor = inertia_tensor;
  mesh.center_of_mass = center_of_mass;
  mesh.volume = volume;
  for * mesh.vertices  it.position -= _center_of_mass; 

  print("Test cube has center of mass %, volume %, inertia tensor:\n  %\n\n", _center_of_mass, volume, inertia_tensor);

  return mesh;
}


//#scope_file

stl_model_to_mesh :: (model: STL_Model, scale := 1.0) -> Mesh {
  mesh: Mesh;
  array_resize(*mesh.vertices, 3*model.facets.count);

  for i: 0..mesh.vertices.count-1 {
    mesh.vertices[i].position = (*model.facets[i/3].v1 + (i%3)).* * scale;
    mesh.vertices[i].normal = model.facets[i/3].normal;
  }

  return mesh;
}

// These structs map directly to the STL file itself.
STL_Facet :: struct {
  normal: Vector3;
  v1: Vector3;
  v2: Vector3;
  v3: Vector3;
  attribute_byte_count: u16 = 0; // always zero apparently
} #no_padding;
#run assert(size_of(STL_Facet) == 50, "STL facet must be size 50");

STL_Model :: struct {
  facets: [..] STL_Facet;
}

load_stl_model :: (file_path: string) -> STL_Model {
  result: STL_Model;
  bytes := read_entire_file(file_path);
  if bytes.count < 84 {
    print("Warning: STL file was too small, not returning any model data\n");
    return result;
  }
  if bytes[0] == #char "s" && bytes[1] == #char "o" {  // lazy detection of the ASCII version of STL
    print("Warning: ASCII STL file detected (not binary), not returning any model data\n");
    return result;
  }

  num_facets := (cast(*u32) (bytes.data + 80)).*;
  print("Loading STL file with % facets\n", num_facets);
  array_resize(*result.facets, num_facets);
  memcpy(result.facets.data, bytes.data + 84, bytes.count - 84);

  #if false {
    print("STL facets:\n");
    for 0..result.facets.count-1 {
      print("STL_Facet: %\n", result.facets[it]);
    }
  }
  return result;
}


// Note: used this as a reference alongside Jon's paper. This was necessary to 
// get the right signs on the volumes of the tetrahedra.
// http://chenlab.ece.cornell.edu/Publication/Cha/icip01_Cha.pdf
// EFFICIENT FEATURE EXTRACTION FOR 2D/3D OBJECTS IN MESH REPRESENTATION

make_A_matrix :: (tetrahedron: Tetrahedron) -> Matrix3 {
  A := make_matrix_from_columns(
    tetrahedron.v2 - tetrahedron.v1,
    tetrahedron.v3 - tetrahedron.v1,
    tetrahedron.v4 - tetrahedron.v1,
    Matrix3
  );
  return A;
}

/*
  Note that when Jon writes "covariance" of a tetrahedron or shape, he means the second
  moment of the mass distribution of the body.
 */
covariance_of_tetrahedron :: (tetrahedron: Tetrahedron) -> Matrix3 {
  C_canonical := 1.0/120*Matrix3_Identity + 1.0/120*Matrix3_One; // 1/60 diag, 1/120 otherwise

  A := make_A_matrix(tetrahedron);

  C_prime := determinant(A) * A * C_canonical * transpose(A);

  // would need this extra step if v1, our arbitrary reference point, weren't {0,0,0}
  // C_double_prime := Translate(C_prime, tetrahedron.v1)
  return C_prime;
}

// Note: this only works for constant density!
// Returns inertia tensor, center of mass.
mass_properties_of_triangle_mesh :: (mesh: Mesh) -> Matrix3, Vector3, float {
  total_covariance := Matrix3.{};
  total_center_of_mass := Vector3.{};
  total_volume := 0.0;

  // V2: we need the normals, so we can't squash the information as much...
  assert(mesh.vertices.count % 3 == 0, "Mesh must be a triangle mesh, with vertices divisible by 3.");
  num_triangles := mesh.vertices.count / 3;
  for i: 0..num_triangles-1 {
    tetrahedron: Tetrahedron;
    tetrahedron.v1 = Vector3.{}; // leave v1, the arbitrary reference point, as 0
    tetrahedron.v2 = mesh.vertices[3*i].position;
    tetrahedron.v3 = mesh.vertices[3*i+1].position;
    tetrahedron.v4 = mesh.vertices[3*i+2].position;

    normal := mesh.vertices[3*i].normal;

    tetrahedron_center_of_mass := (tetrahedron.v2 + tetrahedron.v3 + tetrahedron.v4)/4;

    //sign_change := sign(volume(tetrahedron)) * sign(dot_product(tetrahedron.v2, normal));
    //tetrahedron_volume := sign_change * volume(tetrahedron);
    
    A := make_A_matrix(tetrahedron);
    sign_change := sign(determinant(A)) * sign(dot_product(tetrahedron.v2, normal));
    tetrahedron_volume := sign_change * determinant(A) / 6.0;

    //print("Tetrahedron %, CoM %, volume %\n", i, tetrahedron_center_of_mass, tetrahedron_volume);

    total_volume += tetrahedron_volume;
    total_center_of_mass += tetrahedron_center_of_mass * tetrahedron_volume;

    tetrahedron_covariance := sign_change * covariance_of_tetrahedron(tetrahedron);
    //tetrahedron_covariance := covariance_of_tetrahedron(tetrahedron);
    total_covariance += tetrahedron_covariance;
  }

  if total_volume != 0.0 {
    total_center_of_mass /= total_volume;
  }



  /*

  TRANSLATION PART:

  """
  At this point, the covariance of C_total is still computed around our arbitrary reference point. 
  We want to move it to the center of mass, since that is where a physics simulator is most likely to want it:

    C'_total = Translate(C_total, w0 − x_cm_total)
  """

  w0, the arbitrary reference point, was chosen to be 0, the origin.

  So we are looking at Translate(C_total, -x_cm_total).

  What is the definition of Translate?
  
    C' = Translate(C,Δx) = C + m*(Δx*x_cm^T +x_cm*Δx^T +Δx*Δx^T)

  We're factoring out density, so m => V in the above equation.

  x_cm is "the center of mass of the points used to construct C", which is 0 here, right?

  So the first two terms drop out, and only the third remains?

  So for this purpose it simplifies to 

    C' = Translate(C,Δx) = C + V*Δx*Δx^T

  Which is actually what Claude had told us! It's the parallel axis theorem.
  */

  //print("Total:\n  CoM %\n  volume %\n  cov %\n\n", total_center_of_mass, total_volume, total_covariance);
  {
    // Translate the total covariance matrix, per equations (8) in the paper
    //translation := -total_center_of_mass;
    //total_covariance += total_volume * outer_product(translation, translation);

    // There is no reason behind this whatsoever, I just flipped some signs to see
    // if it worked
    translation := total_center_of_mass;
    total_covariance -= total_volume * outer_product(translation, translation);

  }
  //print("after translate,\n  cov %\n\n", total_covariance);

  //total_covariance *= -1;


  trace_of_covariance := total_covariance._11 + total_covariance._22 + total_covariance._33;
  inertia_tensor_without_density := Matrix3_Identity*trace_of_covariance - total_covariance;

  // @Note Material properties were factored out - still need to multiply the result by material density.

  return inertia_tensor_without_density, total_center_of_mass, total_volume;
}

Tetrahedron :: struct {
  v1, v2, v3, v4: Vector3;
}

// need a couple matrix helper definitions here...
Matrix3_One :: Matrix3.{_11=1, _12=1, _13=1, _21=1, _22=1, _23=1, _31=1, _32=1, _33=1};

determinant :: (m: Matrix3) -> float {
  positive := m._11*m._22*m._33 + m._12*m._23*m._31 + m._13*m._21*m._32;
  negative := m._13*m._22*m._31 + m._12*m._21*m._33 + m._11*m._23*m._32;
  return positive - negative;
}

outer_product :: (v: Vector3, w: Vector3) -> Matrix3 {
  return Matrix3.{
    _11=v.x*w.x, _12=v.x*w.y, _13=v.x*w.z,
    _21=v.y*w.x, _22=v.y*w.y, _23=v.y*w.z,
    _31=v.z*w.x, _32=v.z*w.y, _33=v.z*w.z,
  };
}

sign :: (x: float) -> float {
  return ifx x < 0.0 then -1.0 else 1.0;
}

volume :: (tetrahedron: Tetrahedron) -> float {
  m := make_matrix_from_columns(
    tetrahedron.v1 - tetrahedron.v2,
    tetrahedron.v1 - tetrahedron.v3,
    tetrahedron.v1 - tetrahedron.v4,
    Matrix3
  );
  return determinant(m) / 6.0;
}

#import "Basic";
#import "File";
#import "Math";
#import "GL";
