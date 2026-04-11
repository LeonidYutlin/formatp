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

- ## Usage

### Prerequisites 
- Linking with `libc` - for `memset` and `strlen`

### Synopsis [^1]
Defined in header `formatp.h`
```c
void formatp(const char* format, ...); //(1)
void fformatp(FILE* stream, const char* format, ...); //(2)
```
Converts given args to character string equivalent, 
dictated by conversion specifiers inside `format` and writes the result to:

1. output stream `stdout`
2. output stream `stream`

**Parameters**

`stream` - output file stream to write to

`format` - pointer to a null-terminated char string, whose contents dictate 
how to interpret the data

`...`    - arguments specifying the data to print


`format` string's content is printed as-is, until a conversion specifier (`'%'`) is reached. 
Depending on the conversion specifier, the next argument (or arguments) 
will be interpreted and converted to string differently

Full list of available conversion specifiers is listed down below:

| Specificator | Mnemonic         | Expects      | Output |
|--------------|------------------|--------------|--------|
| `%c`           | **C**haracter    | `char`       | single 8-bit character |
| `%s`           | **S**tring       | `char*`      | if the pointer isn't `NULL`, prints characters until `'\0'` is reached, otherwise prints `"(null)"`. This specification forces a buffer flush before processing |
| `%d\%ld`       | **D**ecimal      | `int\long`   | 32\64-bit signed decimal |
| `%u\%lu`       | **U**nsigned     | `uint\ulong` | 32\64-bit unsigned decimal |
| `%b\%lb`       | **B**inary       | `int\long`   | 32\64-bit unsigned binary |
| `%q\%lq`       | **Q**uaternary   | `int\long`   | 32\64-bit unsigned quaternary |
| `%o\%lo`       | **O**ctal        | `int\long`   | 32\64-bit unsigned octal |
| `%x\%lx`       | he**X**adecimal  | `int\long`   | 32\64-bit unsigned hexadecimal in lowercase |
| `%X\%lX`       | he**X**adecimal  | `int\long`   | 32\64-bit unsigned hexadecimal in uppercase |
| `%B`           | **B**oolean      | `long`       | `"false"` if the argument is 0, `"true"` otherwise |
| `%%`           | -                | -          | the percent character itself, `'%'` |

**Return value**

None

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
```

### Notes
- `formatp` cannot check types of the arguments provided to it, 
so you may need to explicitly cast some arguments to the desired type
```c
formatp("Long: %ld\n", -4); //here -4 is 32-bit signed int, and formatp expects a 64-bit one
//instead, type:
formatp("Long: %ld\n", -4l); //this is correct
```
- If the number of arguments needed by conversion specifications are greater than 
the number of arguments provided, the behavior is undefined. 
If the argument amount is more than the amount needed, the excess arguments 
are evaluated but never accessed/printed
```c
formatp("Hello %s! Have an int %d!", "World"); //undefined behavior
formatp("I only need one argument: %c", 'a', 123, 'r'); //123 and 'r' are ignored
```
- If the format string contains an unknown conversion specification, 
`formatp` uses itself to report an error to `stderr`
```c
formatp("Apples start with the letter %A"); //causes an error to stderr
```
```
blabla
```
- You can add compiler-specific attributes to the prototype of `formatp` function, 
but that would also disable `formatp`-exclusive specifications
```c
//for example, using gcc attributes
#define FORMATP_ATTRIBUTE __attribute__ ((format (printf, 2, 3)))
#include "formatp.h"
```
- `formatp.h` includes `<stdio.h>` (disableable by `#define FORMATP_NO_STDIO`), 
which is used for `fileno` in macros

### Implementation details

- The output is buffered to issue less write syscalls
- `formatp` uses an internal jump table to reduce comparisons per `'%'` processed
- The assembly bindings are PIE-compliant

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
