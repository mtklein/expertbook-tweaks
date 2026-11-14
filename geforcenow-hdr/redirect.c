#define _GNU_SOURCE
#include <dlfcn.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static const char *names[][2] = {
    {"/run/host/os-release", "os-release"},
    {"/run/host/etc/os-release", "os-release"},
    {"/etc/os-release", "os-release"},
    {"/usr/lib/os-release", "os-release"},
    {"/sys/class/dmi/id/product_name", "product_name"},
    {"/sys/class/dmi/id/sys_vendor", "sys_vendor"},
    {"/sys/class/dmi/id/board_vendor", "board_vendor"},
    {"/sys/class/dmi/id/board_name", "board_name"},
    {"/sys/devices/virtual/dmi/id/product_name", "product_name"},
    {"/sys/devices/virtual/dmi/id/sys_vendor", "sys_vendor"},
    {"/sys/devices/virtual/dmi/id/board_vendor", "board_vendor"},
    {"/sys/devices/virtual/dmi/id/board_name", "board_name"},
};

static const char *redirect(const char *path, char *buffer, size_t size) {
    const char *dir = getenv("GFN_FAKE_DIR");
    if (!dir || !path) return path;
    for (size_t i = 0; i < sizeof names / sizeof names[0]; i++) {
        if (strcmp(path, names[i][0])) continue;
        snprintf(buffer, size, "%s/%s", dir, names[i][1]);
        int (*real_access)(const char *, int) = dlsym(RTLD_NEXT, "access");
        return real_access(buffer, R_OK) == 0 ? buffer : path;
    }
    return path;
}

#define OPENER(name)                                                     \
    int name(const char *path, int flags, ...) {                         \
        char buffer[4096];                                               \
        int (*real)(const char *, int, ...) = dlsym(RTLD_NEXT, #name);   \
        va_list args;                                                    \
        va_start(args, flags);                                           \
        int mode = va_arg(args, int);                                    \
        va_end(args);                                                    \
        return real(redirect(path, buffer, sizeof buffer), flags, mode); \
    }

#define OPENER_AT(name)                                                      \
    int name(int dir, const char *path, int flags, ...) {                    \
        char buffer[4096];                                                   \
        int (*real)(int, const char *, int, ...) = dlsym(RTLD_NEXT, #name);  \
        va_list args;                                                        \
        va_start(args, flags);                                               \
        int mode = va_arg(args, int);                                        \
        va_end(args);                                                        \
        return real(dir, redirect(path, buffer, sizeof buffer), flags, mode); \
    }

#define FOPENER(name)                                                 \
    FILE *name(const char *path, const char *mode) {                  \
        char buffer[4096];                                            \
        FILE *(*real)(const char *, const char *) = dlsym(RTLD_NEXT, #name); \
        return real(redirect(path, buffer, sizeof buffer), mode);     \
    }

OPENER(open)
OPENER(open64)
OPENER_AT(openat)
OPENER_AT(openat64)
FOPENER(fopen)
FOPENER(fopen64)
