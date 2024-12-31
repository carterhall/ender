main :: () {
  using mesh: Mesh;

  corners := Vector3.[
    Vector3.{ 0, 0, 0 },
    Vector3.{ 1, 0, 0 },
    Vector3.{ 0, 1, 0 },
    Vector3.{ 0, 0, 1 },
  ];

  for i: 0..3 {
    for j: 0..2 {
      array_add(*vertices, Vertex.{ position=corners[(i+j) % 4] });
    }
  }

  inertia, center := mass_properties_of_triangle_mesh(mesh);
  print("Center = %\n", center);
}

#load "../mesh.jai";
#import "Basic";
#import "Math";
