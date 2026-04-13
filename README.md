# formatp

`formatp` is an implementation of a `printf`-like function in Assembly for UNIX-like systems

## Installation

While being in the root directory of the project

To compile
```shell
make
```

To compile and run
```shell
make run
```

## Usage

### Prerequisites 
- Linking with `libc` - for `memset` and `strlen`

## Synopsis [^1]
Defined in header `formatp.h`
```c
/* (1) */ size_t formatp(const char* format, ...);
/* (2) */ size_t fformatp(FILE* stream, const char* format, ...);
```
Converts given args to character string equivalent, 
dictated by conversion specifiers inside `format` and writes the result to:

1. output stream `stdout`
2. output stream `stream`

### Parameters

`stream` - output file stream to write to

`format` - pointer to a null-terminated char string, whose contents dictate 
how to interpret the data

`...`    - arguments specifying the data to print


`format` string's contents are printed as-is, until a conversion specifier (`'%'`) is reached. 
Depending on the conversion specifier, the next argument (or arguments) 
will be interpreted and converted to string differently

The full list of available conversion specifiers is listed below:

| Specificator | Mnemonic         | Expects      | Output |
|--------------|------------------|--------------|--------|
| `%c`           | **C**haracter    | `char`       | single 8-bit character |
| `%s`           | **S**tring       | `char*`      | if the pointer isn't `NULL`, prints characters until `'\0'` is reached, otherwise prints `"(null)"`. This specification forces a buffer flush before processing |
| `%z`           | si**Z**ed string       | `size_t`, then `char*`      | if the pointer isn't `NULL`, prints characters until `'\0'` is reached or `n` amount of characters (specified by `size_t` arg) are printed, otherwise prints `"(null)"` if `n` is big enough, otherwise does nothing. This specification forces a buffer flush before processing |
| `%d\%ld`       | **D**ecimal      | `int\long`   | 32\64-bit signed decimal |
| `%u\%lu`       | **U**nsigned     | `uint\ulong` | 32\64-bit unsigned decimal |
| `%b\%lb`       | **B**inary       | `int\long`   | 32\64-bit unsigned binary |
| `%q\%lq`       | **Q**uaternary   | `int\long`   | 32\64-bit unsigned quaternary |
| `%o\%lo`       | **O**ctal        | `int\long`   | 32\64-bit unsigned octal |
| `%x\%lx`       | he**X**adecimal  | `int\long`   | 32\64-bit unsigned hexadecimal in lowercase |
| `%X\%lX`       | he**X**adecimal  | `int\long`   | 32\64-bit unsigned hexadecimal in uppercase |
| `%r\%lr` followed by a number 1-36     | **R**adix        | `int\long`   | 32\64-bit unsigned n-base number in lowercase |
| `%R\%lR` followed by a number 1-36     | **R**adix        | `int\long`   | 32\64-bit unsigned n-base number in uppercase |
| `%B`           | **B**oolean      | `long`       | `"false"` if the argument is 0, `"true"` otherwise |
| `%n`           | **N**umber of bytes | `size_t*`      | produces no output, instead writes the number of bytes written so far (including those that are buffered at the moment) to a pointer. If the pointer is `NULL`, does nothing  |
| `%%`           | -                | -          | the percent character itself, `'%'` |

### Return value

Number of characters that were printed. If an error occurs, 0 is returned

[^1]: mostly inspired by [cpp reference](https://en.cppreference.com/w/c/io/fprintf)

### Example

```c
#include "formatp.h"

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
    formatp("%s with 3 characters is just %z\n", "Funeral", 3, "Funeral");
    formatp("%s with 3 characters is just %z\n", NULL, 3, NULL);

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
```
Output:
```
-4 is
1111111111111111111111111111111111111111111111111111111111111100
Hi I am a % string
Characters! A p D
I know that Q has ASCII code 81!
Decimal: 79
Binary:  1001111
Octal:   117
Hexa:    4f (or 4F)
Quat:    1033
Boolean true: true
Boolean false: false
Hello is a string that isn't (null)
Funeral with 3 characters is just Fun
(null) with 3 characters is just
ABCDEFtrue
n1 = 3
n2 = 6
n3 = 10
base 2 - 100011
base 3 - 1022
base 4 - 203
base 5 - 120
base 6 - 55
base 7 - 50
base 8 - 43
base 9 - 38
base 10 - 35
base 11 - 32
base 12 - 2b
base 13 - 29
...
base 27 - 18
base 36 - z (or Z)
```

### Notes
- `formatp` cannot check the types of the arguments provided to it, 
so you may need to explicitly cast some arguments to the desired type
```c
formatp("Long: %ld\n", -4); // here -4 is 32-bit signed int, and formatp expects a 64-bit one
// instead, type:
formatp("Long: %ld\n", -4l); // this is correct
```
- If the number of arguments needed by conversion specifications is greater than 
the number of arguments provided, the behavior is undefined. 
If the argument amount is more than the amount needed, the excess arguments 
are evaluated, but never accessed/printed
```c
formatp("Hello %s! Have an int %d!", "World"); // undefined behavior
formatp("I only need one argument: %c", 'a', 123, 'r'); // 123 and 'r' are ignored
```
- If the format string contains an unknown conversion specification, 
`formatp` uses itself to report an error to `stderr`
```c
formatp("Apples start with the letter %Apples"); // causes an error to stderr
```
```
 [ERROR]: Unknown conversion type character: 'A' in format ..."e letter %Apples"...
```
- You can add compiler-specific attributes to the prototype of `formatp` function, 
but that would also disable `formatp`-exclusive specifications
```c
// for example, using gcc attributes
#define FORMATP_ATTRIBUTE __attribute__ ((format (printf, 2, 3)))
#include "formatp.h"
```
- `formatp.h` includes `<stdio.h>` (disableable by `#define FORMATP_NO_STDIO`), 
which is used for `fileno` in macros

### Implementation details

- The output is buffered to issue fewer write syscalls
- `formatp` uses an internal jump table to reduce comparisons per `'%'` processed
- The assembly bindings are PIE-compliant
- If you can use an alternative conversion specification for a power of 2 base number (for example instead of `%r8` you can use `%o`), then it is better to use a version that isn't `%r`, since all powers of 2 conversions use bit shifts instead of division, making them faster


`formatp.h` contains macros that wrap the assembly bindings in a more user-friendly way
```c
#define formatp(fmt, ...) \
  fformatp(stdout, fmt __VA_OPT__(,) __VA_ARGS__)
#define fformatp(file, fmt, ...) \
  fformatp_(fileno((file)), fmt __VA_OPT__(,) __VA_ARGS__)
```
In reality, the original assembly function is defined like this
```c
extern void fformatp_(int file_descriptor, const char* format_string, ...);
```
It is not recommended to call the original assembly function, instead use the defined macros
