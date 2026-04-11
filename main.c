#include <limits.h>
#include <stdbool.h>
#include "formatp.h"

void runTests();

int main(void) {
    formatp("%ld is\n"
            "%lb\n", 
            -4l, -4l);
    formatp("Hi I %cm a %% string\n", 'a');
    formatp("Characters! %c %c %c\n", 'A', 'p', 'D');
    formatp("I know that %c has ASCII code %d!\n", 'Q', 'Q');

    formatp("Decimal: %d\n"
            "Binary:  %b\n"
            "Octal:   %o\n"
            "Hexa:    %x (or %X)\n"
            "Quat:    %q\n",
            79, 79, 79, 79, 79, 79);

    formatp("Boolean true: %B\n", 10);
    formatp("Boolean false: %B\n", 1 - 1);
    formatp("%s is a string that isn't %s\n", "Hello", NULL);

    size_t n1 = 0;
    size_t n2 = 0;
    size_t n3 = 0;
    formatp("ABC%nDEF%n%B%n\n", &n1, &n2, true, &n3);
    formatp("n1 = %lu\n"
            "n2 = %lu\n"
            "n3 = %lu\n", 
            n1, n2, n3);

    formatp("base 2 - %r2\n"
            "base 3 - %r3\n"
            "base 4 - %r4\n"
            "base 5 - %r5\n"
            "base 6 - %r6\n"
            "base 7 - %r7\n"
            "base 8 - %r8\n"
            "base 9 - %r9\n"
            "base 10 - %r10\n"
            "base 11 - %r11\n"
            "base 12 - %r12\n"
            "base 13 - %r13\n"
            "...\n"
            "base 27 - %r27\n"
            "base 36 - %r36 (or %lR36)\n",
            35, 35, 35, 35, 35, 
            35, 35, 35, 35, 35, 
            35, 35, 35, 35, 35);

    return 0;
}

void runTests() {
  formatp("base 2 - %lr2\n"
          "base 3 - %lr3\n"
          "base 4 - %r4\n"
          "base 5 - %r5\n"
          "base 6 - %r6\n"
          "base 7 - %r7\n"
          "base 8 - %r8\n"
          "base 9 - %r9\n"
          "base 10 - %r10\n"
          "base 11 - %r11\n"
          "base 12 - %r12\n"
          "base 13 - %r13\n"
          "...\n"
          "base 27 - %r27\n"
          "base 36 - %r36 %lR36\n",
          35, 35, 35, 35, 35, 
          35, 35, 35, 35, 35, 
          35, 35, 35, 35, 35);

  size_t n1 = 0;
  size_t n2 = 0;
  size_t n3 = 0;
  formatp("ABC%nDEF%n%B%n\n", &n1, &n2, true, &n3);
  formatp("n1 = %lu\n"
          "n2 = %lu\n"
          "n3 = %lu\n", 
          n1, n2, n3);

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
