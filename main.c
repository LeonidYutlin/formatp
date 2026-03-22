#include <stdio.h>

extern void formatp(long a);

int main(void) {
  // printf("As a printf function i can do a lot:\n"
  //        "\tchar - %c\n"
  //        "\tstring - %s\n"
  //        "\tdecimals - %d\n",
  //        'A', 
  //        "Wello Horld!", 
  //        123);
  formatp(6789088921878713);
  return 0;
}
