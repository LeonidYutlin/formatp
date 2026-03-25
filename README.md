# formatp

formatp is an implementation of a `printf`-like function in Assembly for UNIX-like systems (with Windows version due)

## Installation

Whilst being in the root directory of the project

To compile, run
```shell
make
```

To both compile and run the program, run
```shell
make run
```

## Capabilities
- Formatted output to any valid file descriptor
- The output is not immediate, but instead buffered in order to issue less write syscalls
- `formatp` uses an internal jump table to reduce the number of comparisons per percent processed
- If the format string contains an unknown `%` specificator, `formatp` uses itself to report
an error to `stderr`, in a form of the following message:
>     [ERROR]: Unrecognized escape sequence: '%...' in "%..."
- Multiple specificators, all of them listed below:

| Specificator | Mnemonic         | Expects      | Output |
|--------------|------------------|--------------|--------|
| %c           | **C**haracter    | `char`       | single 8-bit character |
| %s           | **S**tring       | `char*`      | "(null)" if the provided pointer is NULL, otherwise the string itself, not including the '\0' character |
| %d\%ld       | **D**ecimal      | `int\long`   | 32\64-bit signed decimal |
| %u\%lu       | **U**nsigned     | `uint\ulong` | 32\64-bit unsigned decimal |
| %b\%lb       | **B**inary       | `int\long`   | 32\64-bit unsigned binary |
| %o\%lo       | **O**ctal        | `int\long`   | 32\64-bit unsigned octal |
| %x\%lx       | he**X**adecimal  | `int\long`   | 32\64-bit unsigned hexadecimal in lowercase |
| %X\%lX       | he**X**adecimal  | `int\long`   | 32\64-bit unsigned hexadecimal in uppercase |
| %B           | **B**oolean      | `long`       | "false" if bool == 0, "true" otherwise |
| %%           | -                | -          | percent character itself '%' |

### Notes
- `formatp` cannot check types of the arguments provided to it, so you may need to explicitly cast some arguments to their type.
For example instead of `fformatp_(1, "Long: %ld", -4)` you should type `fformatp_(1, "Long: %ld", -4l)` to tell C that you explicitly want a 64-bit integer here.
- `formatp` is not protected from the number of arguments needed by `%` specificators exceeding the number of arguments provided to the function
- You can add compiler-specific attributes to the prototype of `formatp` function, but that would also disable `formatp` exclusive specificators
```c
//for example, using gcc
extern void fformatp_(int fd, const char* fmt, ...)  __attribute__ ((format (printf, 2, 3)));
```

## Usage

To use `formatp` in your code, you need to declare an external function prototype in your C code.
`formatp` also references an external function `void clear_buffer(char* buf)` in its implementation, so you need to have such function implemented somewhere in your codebase

```c
extern void fformatp_(int file_descriptor, const char* format_string, ...);

void clear_buffer(char* buf) {...}

int main(void) {
    fformatp_(1, "Hello, %s!", "World");
    return 0;
}
```

### Additional Macros

You can also add some macros to ease the use of `formatp`
```c
#define formatp(fmt, ...) \
  fformatp(stdout, fmt __VA_OPT__(,) __VA_ARGS__)
#define fformatp(file, fmt, ...) \
  fformatp_(fileno((file)), fmt __VA_OPT__(,) __VA_ARGS__)
```
