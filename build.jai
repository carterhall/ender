// This is a very simple build program that configures a module directory (./modules) and 
// a binary output directory (./bin). 
//
// It was adapted from some examples in how_to and the built-in Jai modules.
//
// For more information, see jai/how_to/400_workspaces.jai.

#run build();

build :: () {
  w := compiler_create_workspace();
  options := get_build_options();
  options.output_executable_name = "ender";

  // Append "modules" to the existing import paths. This allows you to put third-party
  // modules into the "modules" folder without using the -import_dir compiler argument.
  new_import_path: [..] string;
  new_import_path.allocator = temp;
  for options.import_path  array_add(*new_import_path, it);
  array_add(*new_import_path, "modules");
  options.import_path = new_import_path;

  options.output_path = "bin";

  set_build_options(options, w);

  // Make sure you have finished setting build options. After you call add_build_file, 
  // compilation will begin immediately.
  add_build_file("main.jai", w); 

  // Prints values of all available build options. This is probably the easiest way to
  // look for an option whose name you can't remember.
  #if false {
    fmt := *context.print_style.default_format_struct;
    fmt.use_newlines_if_long_form = true;
    fmt.indentation_width = 2;
    print("Workspace: %\nOptions: %\n", w, options); 
  }

  // Don't generate an executable for this file (the build program.)
  set_build_options_dc(.{do_output=false}); 
}

#import "Compiler";
#import "Basic";
