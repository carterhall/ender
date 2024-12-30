make_A_matrix :: (tetrahedron: Tetrahedron) -> Matrix3 {
  A := make_matrix_from_columns(
    tetrahedron.v2 - tetrahedron.v1,
    tetrahedron.v3 - tetrahedron.v1,
    tetrahedron.v4 - tetrahedron.v1,
    Matrix3
  );
  return A;
}

covariance_of_tetrahedron :: (tetrahedron: Tetrahedron) -> Matrix3 {
  C_canonical :: 1.0/120*Matrix3_Identity + 1.0/120*Matrix3_One; // 1/60 diag, 1/120 otherwise

  A := make_A_matrix(tetrahedron);

  C_prime := determinant(A) * A * C_canonical * transpose(A);

  // would need this extra step if v1, our arbitrary reference point, weren't {0,0,0}
  // C_double_prime := Translate(C_prime, tetrahedron.v1)
  // (Translate being parallel axis theorem like below?)
  return C_prime;
}

// Note: this only works for constant density!
// Returns inertia tensor, center of mass.
mass_properties_of_triangle_mesh :: (mesh: Triangle_Mesh) -> Matrix3 #must, Vector3 #must {
  total_covariance := Matrix3.{};
  total_center_of_mass := Vector3.{};
  total_volume := 0.0;

  for triangle: mesh.triangles {
    tetrahedron: Tetrahedron;   // leave v1, the arbitrary reference point, as 0
    tetrahedron.v2 = triangle.v1;
    tetrahedron.v3 = triangle.v2;
    tetrahedron.v4 = triangle.v3;

    tetrahedron_center_of_mass := (tetrahedron.v2 + tetrahedron.v3 + tetrahedron.v4)/4;

    // @Speed Recomputing A here, could refactor to avoid
    tetrahedron_volume := 1.0/6 * determinant(make_A_matrix(tetrahedron));

    tetrahedron_covariance = covariance_of_tetrahedron(tetrahedron);

    total_covariance += tetrahedron_covariance;
    total_volume += tetrahedron_volume;
    total_center_of_mass += tetrahedron_center_of_mass;
  }

  total_center_of_mass /= total_volume;

  // Translate the total covariance matrix, via the parallel axis theorem
  translation := tetrahedron.v1 - total_center_of_mass;
  total_covariance -= total_volume * outer_product(translation, translation);

  trace_of_covariance := total_covariance._11 + total_covariance._22 + total_covariance._33;
  inertia_tensor_without_density := Matrix3_Identity*trace_of_covariance - total_covariance;

  // @Note Material properties were factored out - still need to multiply the result by material density.

  return inertia_tensor_without_density, total_center_of_mass;    
}

Tetrahedron :: struct {
  v1, v2, v3, v4: Vertex;
#place v1;
  vertices: [4] Vertex;
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

#load "stl_file.jai"; // Mesh, Vertex, etc

#import "Basic";
#import "Math";
