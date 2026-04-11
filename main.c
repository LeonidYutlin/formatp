#include <limits.h>
#include <stdbool.h>
#include "formatp.h"

void runTests();

int main(void) {
  runTests();
  return 0;
}

void runTests() {
  //formatp("%i3\n", 8); // output: 22

  size_t n1 = 0;
  size_t n2 = 0;
  size_t n3 = 0;
  formatp("ABC%nDEF%n%B%n\n", &n1, &n2, true, &n3);
  formatp("n1 = %lu\n"
          "n2 = %lu\n"
          "n3 = %lu\n", 
          n1, n2, n3);

  return;

  formatp("What if i try to use l where im not supposed to? %lB", 1);
  formatp("Hi there is an error in this fmt str %r\n");
  formatp("And here %lE too\n");

  formatp("%ld is %lb\n", -4l, -4l);
  formatp("%ld\nvs\n%d\n", ULONG_MAX, ULONG_MAX);
  formatp("%ld\nvs\n%d\n", LONG_MIN, LONG_MIN);
  formatp("%lu\nvs\n%u\n", LONG_MAX, LONG_MAX);
  formatp("%lb\nvs\n%b\n", LONG_MAX, LONG_MAX);
  formatp("%lo\nvs\n%o\n", LONG_MAX, LONG_MAX);
  formatp("%lx\nvs\n%x\n", LONG_MAX, LONG_MAX);
  formatp("%lu\nvs\n%u\n", LONG_MIN, LONG_MIN);

  fformatp(stderr, "Hi am I being formatted in stderr? %B\n", 1);

  formatp("Hi %% I %cm a %% string\n", 'a');
  formatp("Chars, go! %c %c %c\n", 'A', 'p', 'D');
  formatp("I know that %c has ASCII code %d!\n", 'Q', 'Q');

  formatp("Binary | Signed | Unsigned\n"
          "%b | %d | %u\n"
          "%b | %d | %u\n"
          "%b | %d | %u\n"
          "%b | %d | %u\n",
          125,      125,      125,
          INT_MAX,  INT_MAX,  INT_MAX,
          INT_MIN,  INT_MIN,  INT_MIN,
          UINT_MAX, UINT_MAX, UINT_MAX);
  formatp("%d is %b 2 and %o 8 and %x %X 16 and %q 4\n", 
          79, 79, 79, 79, 79, 79);

  formatp("gwonk is that true: %B\n", 10);
  formatp("gwonk is that true: %B\n", 1 - 1);

  formatp("%s is a string that isn't %s\n", "Hello", NULL);
  formatp("\nAs a printf-like function i can do a lot:\n"
          "\tchar - %c\n"
          "\tstring - %s\n"
          "\tdecimals - %d\n"
          "%d %s %X %d%%%c%b\n",
          'A', 
          "Wello Horld", 
          123,
          -1, "LOVE", 3802, 100, 33, 126);
}
