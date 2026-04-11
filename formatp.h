#ifndef FORMATP_H
#define FORMATP_H

#include <stddef.h>

#define formatp(fmt, ...) \
  fformatp(stdout, fmt __VA_OPT__(,) __VA_ARGS__)

#ifndef FORMATP_NO_STDIO
#include <stdio.h>
#define fformatp(file, fmt, ...) \
  fformatp_(fileno((file)), fmt __VA_OPT__(,) __VA_ARGS__)
#endif

#ifdef FORMATP_ATTRIBUTE
extern size_t fformatp_(int fd, const char* fmt, ...)  FORMATP_ATTRIBUTE ;
#else
extern size_t fformatp_(int fd, const char* fmt, ...);
#endif

#endif
