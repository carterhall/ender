load_application_fonts :: () {
  reset_path();

  //font_size = 0.6 * csv_display_info.cell_height;
  font_size = 28;
  font_regular = Simp.get_font_at_size("../assets/fonts", "Lilex-Regular.ttf", xx font_size);
  font_bold    = Simp.get_font_at_size("../assets/fonts", "Lilex-Bold.ttf", xx font_size);
}

draw_horizontal_line :: (x0: float, x1: float, y: float, color := Vector4.{1,1,1,1}, thickness := 1.0) {
  v0 := Vector2.{x0, y-0.5*thickness};
  v1 := Vector2.{x0, y+0.5*thickness};
  v2 := Vector2.{x1, y+0.5*thickness};
  v3 := Vector2.{x1, y-0.5*thickness};
  //Simp.set_shader_for_color(true);
  Simp.immediate_quad(v0, v1, v2, v3, color);
}

draw_vertical_line :: (x: float, y0: float, y1: float, color := Vector4.{1,1,1,1}, thickness := 1.0) {
  v0 := Vector2.{x-0.5*thickness, y0};
  v1 := Vector2.{x+0.5*thickness, y0};
  v2 := Vector2.{x+0.5*thickness, y1};
  v3 := Vector2.{x-0.5*thickness, y1};
  //Simp.set_shader_for_color(true);
  Simp.immediate_quad(v0, v1, v2, v3, color);
}

fill_rect :: (r: Rect, color: Vector4) {
  v0 := Vector2.{r.x, r.y};
  v1 := Vector2.{r.x, r.y + r.h};
  v2 := Vector2.{r.x + r.w, r.y + r.h};
  v3 := Vector2.{r.x + r.w, r.y};
  //Simp.set_shader_for_color(true);
  Simp.immediate_quad(v0, v1, v2, v3, color);
}

draw_rect :: (r: Rect, color: Vector4) {
  draw_horizontal_line(r.x, r.x + r.w, r.y, color);
  draw_horizontal_line(r.x, r.x + r.w, r.y + r.h, color);
  draw_vertical_line(r.x, r.y, r.y + r.h, color);
  draw_vertical_line(r.x + r.w, r.y, r.y + r.h, color);
}


font_regular: *Simp.Dynamic_Font;
font_bold:    *Simp.Dynamic_Font;
font_size: s64;

#import "GetRect";

#scope_file
//Simp :: #import "Simp";
#import "System";

