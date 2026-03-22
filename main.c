#include <stdio.h>
#include <string.h>

extern void formatp(long a);

//Example of a function that will be called 
//from assembly to clear the buffer
void clear_buffer(void* buf, size_t count) {
  memset(buf, 0, count);
}

int main(void) {
  // printf("As a printf function i can do a lot:\n"
  //        "\tchar - %c\n"
  //        "\tstring - %s\n"
  //        "\tdecimals - %d\n",
  //        'A', 
  //        "Wello Horld!", 
  //        123);
  formatp(8);
  formatp(234);
  formatp(4444444444444444444); 
  //BUG: you can overflow the buffer with big numbers
  formatp(11);
  return 0;
}
