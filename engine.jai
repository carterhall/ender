Handle :: struct ($T: Type) {
  handle: u16;
}

operator ! :: (handle: Handle($T)) -> bool {
  return handle.handle == 0;
}

lookup :: (array: [..] $T, handle: Handle(T)) -> *T {
  if handle.handle >= array.count  return null;
  return *array[handle.handle];
}

Object :: struct {
  name: string; 

  transform: Transform;
  velocity: Vector3; // TODO move these into some physics struct?
  angular_momentum: Vector3;

  model_scale := 1.0;

  mesh_handle: Handle(Mesh);
  material_handle: Handle(Material);
  color: Vector3;  // TODO move this into material?
  opacity := 1.0;

  Flags :: enum_flags u32 {
    ENABLE_MOVEMENT_PHYSICS;
    ENABLE_COLLISION_PHYSICS;
    IS_SKYBOX;
  }
  flags := 
    Flags.ENABLE_MOVEMENT_PHYSICS |
    Flags.ENABLE_COLLISION_PHYSICS;
}

Transform :: struct {
  position: Vector3;
  rotation: Quaternion;
}

Material :: struct {
  name := "default";
  color := Vector4.{ 248.0/256, 34.0/256, 205.0/256, 1.0 }; // pink
  density := 1000.0;  // kg/m^3
  restitution := 0.0;
}

get_material_handle :: (name: string) -> Handle(Material) {
  for * materials {
    if it.name == name {
      return .{ xx it_index };
    }
  }
  return .{ 0 };
}

get_object :: (name: string) -> *Object {
  for * objects {
    if it.name == name {
      return it;
    }
  }
  return null;
}

make_or_get_object :: (name: string) -> *Object {
  object := get_object(name);
  if object  return object;

  array_add(*objects, Object.{name=name});
  return *objects[objects.count - 1];
}

make_object :: (name := "") -> Handle(Object) {
  object_name := name;
  if object_name == "" {
    object_name = sprint("Object %", objects.count);
  }
  array_add(*objects, Object.{name=object_name});
  //return *objects[objects.count - 1];
  return Handle(Object).{ cast(u16) objects.count - 1 };
}

materials: [..] Material;
meshes: [..] Mesh;
objects: [..] Object;

reset_path :: () {
  path := path_strip_filename(get_path_of_running_executable());
  set_working_directory(path);
}


#scope_file
#import "String";
#import "System";
