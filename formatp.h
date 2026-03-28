#ifndef FORMATP_H
#define FORMATP_H

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

#endif
