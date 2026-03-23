#include <stdio.h>

//TODO: %s and %B shouldnt always cause a buffer flush
//TODO: windows version
//TODO: ensure calling conventions are enforced
//TODO: maybe to convert into binary, octal or hexa you shouldnt use divs (triads, and quads instead)
//TODO: negative numbers in %d but always positive with %u
//TODO: symbolic branch names
//TODO: MACROS for 'b', 8, 4, three lines together, fd of stderr (see chat)
//TODO: commentary for some registers that we are using
//TODO: factor out repeating code
//TODO: create a README
//TODO: maybe another way of preventing rcx corruption when calling clear_buffer
//TODO: %ld, %lu

#define formatp(fmt, ...) \
  fformatp(stdout, fmt __VA_OPT__(,) __VA_ARGS__)
#define fformatp(file, fmt, ...) \
  fformatp_(fileno((file)), fmt __VA_OPT__(,) __VA_ARGS__)

extern void fformatp_(int fd, const char* fmt, ...)  /*__attribute__ ((format (printf, 2, 3)))*/;

//Example of a function that will be called 
//from assembly to clear the buffer
void clear_buffer(char* buf) {
  if (!buf) return;
  while (*buf)
    *buf++ = '\0';
}

int main(void) { 
  fformatp(stderr, "i i am formatted in stderr %B\n", 1);
  formatp("Hi %% I %cm a %% string\n", 'a');
  formatp("Chars, go! %c %c %c\n", 'A', 'p', 'D');
  formatp("Boy oh boy what if i try to cause an error%Q\n");
  formatp("I know that %c has ASCII code %d!\n", 'Q', 'Q');
  formatp("-1 is %d\n", -1);
  formatp("%d is %b 2 and %o 8 and %x %X 16\n", 
          79, 79, 79, 79, 79);

  formatp("gwonk is that true: %B\n", 10);
  formatp("gonk  is that twue: %B\n", 1 - 1);

  formatp("%s is a string that isnt %s, wow\n", "Hello", NULL);

  formatp("\nAs a better printf function i can do a lot:\n"
          "\tchar - %c\n"
          "\tstring - %s\n"
          "\tdecimals - %d\n"
          "%d %s %X %d%%%c%b\n",
          'A', 
          "Wello Horld", 
          123,
          -1, "LOVE", 3802, 100, 33, 126);
  printf("As a printf function i can do a lot:\n"
         "\tchar - %c\n"
         "\tstring - %s\n"
         "\tdecimals - %d\n",
         'A', 
         "Wello Horld", 
         123);
  return 0;
}
