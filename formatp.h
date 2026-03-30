#ifndef FORMATP_H
#define FORMATP_H

#include <string.h>

#define formatp(fmt, ...) \
  fformatp(stdout, fmt __VA_OPT__(,) __VA_ARGS__)

#ifndef FORMATP_NO_STDIO
#include <stdio.h>
#define fformatp(file, fmt, ...) \
  fformatp_(fileno((file)), fmt __VA_OPT__(,) __VA_ARGS__)
#endif

extern void fformatp_(int fd, const char* fmt, ...)  /*__attribute__ ((format (printf, 2, 3)))*/;

#endif
