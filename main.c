#include <stdio.h>

//TODO: %s and %B shouldnt always cause a buffer flush
//TODO: windows version
//TODO: do not call strlen instead use already known info abt the length of the buffer

#define formatp(fmt, ...) fformatp(1, fmt __VA_OPT__(,) __VA_ARGS__)

extern void fformatp(int fd, const char* fmt, ...)  /*__attribute__ ((format (printf, 2, 3)))*/;

//Example of a function that will be called 
//from assembly to clear the buffer
void clear_buffer(char* buf) {
  if (!buf) return;
  while (*buf)
    *buf++ = '\0';
}

int main(void) {
  
  fformatp(2, "Hi i am formatted in stderr %B\n", true); 
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
          "\tdecimals - %d\n",
          'A', 
          "Wello Horld", 
          123);
  printf("As a printf function i can do a lot:\n"
         "\tchar - %c\n"
         "\tstring - %s\n"
         "\tdecimals - %d\n",
         'A', 
         "Wello Horld", 
         123);
  return 0;
}
