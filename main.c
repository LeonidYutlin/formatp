#include <stdio.h>
#include <string.h>

extern void formatp(const char* fmt, ...);

//Example of a function that will be called 
//from assembly to clear the buffer
void clear_buffer(char* buf) {
  if (!buf) return;
  while (*buf)
    *buf++ = '\0';
}

int main(void) {
  // printf("As a printf function i can do a lot:\n"
  //        "\tchar - %c\n"
  //        "\tstring - %s\n"
  //        "\tdecimals - %d\n",
  //        'A', 
  //        "Wello Horld!", 
  //        123);
  formatp("Hi %% I %c m %% atring\n", 'W');
  formatp("Qwerty %% %c %c %c", 'A', 'p', 'D');
  formatp("Hello blabla %% %A", 'A', 'p', 'D');
  return 0;
}
