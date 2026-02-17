test :: () {
  cube := make_test_cube();
  cube2 := make_test_cube(2);
  cube3 := make_test_cube(3);
}

#run test();

#import "Basic";
#load "../mesh.jai";
