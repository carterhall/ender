test_load_stl_model :: () {
  args := get_command_line_arguments();
  if args.count != 2 {
    log_error("Usage: % <STL filename>", args[0]);
    return;
  }

  filename := args[1];
  model := load_stl_model(filename);

  if model.facets.count >= 10 {
    print("First 10 facets:\n");
    for 0..9 {
      print("STL_Facet: %\n", model.facets[it]);
    }
  }
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

  num_facets := << (cast(*u32) (bytes.data + 80));
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

// These structs are our format, designed to be passed to OpenGL.
// This is dead simple at the moment, but we might want to add normals
// or color information or something else. I don't know yet. Depends on how
// far we go with lighting etc.
Vertex :: struct {
  position: Vector3;
  normal: Vector3;
}

Mesh :: struct {   // This is just a list of vertices, they could mean anything.
  vertices: [..] Vertex;
}

Triangle_Mesh :: struct {  // Here we're being explicit about 3 vertices = a triangle.
  Triangle :: struct {
    v1, v2, v3: Vertex;

  #place v1;
    vertices: [3] Vertex = ---;
  }

  triangles: [..] Triangle;  
}

stl_model_to_mesh :: (model: STL_Model, scale := 1.0) -> Mesh {
  mesh: Mesh;
  array_resize(*mesh.vertices, 3*model.facets.count);

  min_coords := model.facets[0].v1;
  max_coords := model.facets[0].v1;
  for i: 0..mesh.vertices.count-1 {
    mesh.vertices[i].position = <<(*model.facets[i/3].v1 + (i%3)) * scale;
    mesh.vertices[i].normal = model.facets[i/3].normal;

    // Keep track of extremes values in each dimension
    min_coords.x = min(mesh.vertices[i].position.x, min_coords.x);
    min_coords.y = min(mesh.vertices[i].position.y, min_coords.y);
    min_coords.z = min(mesh.vertices[i].position.z, min_coords.z);
    max_coords.x = max(mesh.vertices[i].position.x, max_coords.x);
    max_coords.y = max(mesh.vertices[i].position.y, max_coords.y);
    max_coords.z = max(mesh.vertices[i].position.z, max_coords.z);
  }

  #if false {
    for i: 0..mesh.vertices.count-1 {  
      mesh.vertices[i].position.x -= (max_coords.x - min_coords.x) / 2.0;
      mesh.vertices[i].position.y -= (max_coords.y - min_coords.y) / 2.0;
      mesh.vertices[i].position.z -= (max_coords.z - min_coords.z) / 2.0;
    }
  }

  return mesh;
}

#import "Basic";
#import "File";
#import "Math";
