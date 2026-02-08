load_application_fonts :: () {
  path := path_strip_filename(get_path_of_running_executable());
  set_working_directory(path);

  //font_size = 0.6 * csv_display_info.cell_height;
  font_size = 28;
  font_regular = Simp.get_font_at_size("../assets/fonts", "Lilex-Regular.ttf", xx font_size);
  font_bold    = Simp.get_font_at_size("../assets/fonts", "Lilex-Bold.ttf", xx font_size);
}

font_regular: *Simp.Dynamic_Font;
font_bold:    *Simp.Dynamic_Font;
font_size: s64;


#scope_file
//Simp :: #import "Simp";
#import "System";
