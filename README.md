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
- The output is not immediate, but instead buffered to reduce number of write syscalls
- If the format string contains unknown `%` specificator, `formatp` uses itself to report
an error to `stderr`, in a form of a following message:
> [ERROR]: Unrecognized escape sequence: '%...' in "%..."
- Multiple specificators, all of them listed below:
| Specificator | Mnemonic         | Expects    | Output |
|--------------|------------------|------------|--------|
| %c           | **C**haracter    | char       | single 8-bit character |
| %s           | **S**tring       | char*      | "(null)" if the provided string is NULL, otherwise the string itself, not including the '\0' character |
| %d\%ld       | **D**ecimal      | int\long   | 32\64-bit signed decimal |
| %u\%lu       | **U**nsigned     | uint\ulong | 32\64-bit unsigned decimal |
| %d\%ld       | **D**ecimal      | int\long   | 32\64-bit unsigned binary |
| %d\%ld       | **D**ecimal      | int\long   | 32\64-bit unsigned octal |
| %d\%ld       | **D**ecimal      | int\long   | 32\64-bit signed decimal |
| %x\%lx       | he**X**adecimal  | int\long   | 32\64-bit unsigned hexadecimal |

## Usage

To use `formatp` in your code, you need to declare an external function in your C code.
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
