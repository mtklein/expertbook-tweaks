// white-point-ctm: sets Hyprland's colour transform matrix (the white point)
// on every output, to any value, and keeps it there.
//
// ambient-display runs this and writes one line per change to its stdin:
//
//     <red> <green> <blue>      per-channel gains, 0..1 ("1 1 1" is neutral)
//
// It replaces hyprsunset here, which only takes temperatures in 100 K steps
// (a visible jump at the warm end). Same protocol, hyprland-ctm-control-v1;
// the patched Hyprland applies the matrix in linear light (hyprland-patched/06).
// The protocol carries 24.8 fixed point, so a gain has 256 steps: about a
// mired apiece across the range, where 100 K is 3 to 16.
//
// Hyprland resets the matrix to neutral when the client that set it goes
// away, so this stays running; it exits when its stdin closes. Only one
// client may control the matrix: if another already does (hyprsunset), this
// prints "blocked" and exits with status 3.
#include <errno.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <wayland-client.h>
#include "hyprland-ctm-control-v1-client-protocol.h"

struct output {
    struct wl_output *wl;
    uint32_t name;
    struct output *next;
};

static struct wl_display *display;
static struct hyprland_ctm_control_manager_v1 *manager;
static struct output *outputs;
static double gain[3] = {1, 1, 1};
static int have_gain;

static void apply(void) {
    if (!manager || !have_gain) return;
    for (struct output *o = outputs; o; o = o->next)
        hyprland_ctm_control_manager_v1_set_ctm_for_output(manager, o->wl,
            wl_fixed_from_double(gain[0]), 0, 0,
            0, wl_fixed_from_double(gain[1]), 0,
            0, 0, wl_fixed_from_double(gain[2]));
    hyprland_ctm_control_manager_v1_commit(manager);
    wl_display_flush(display);
}

static void blocked(void *data, struct hyprland_ctm_control_manager_v1 *m) {
    (void)data; (void)m;
    fprintf(stderr, "blocked\n");
    exit(3);
}
static const struct hyprland_ctm_control_manager_v1_listener manager_listener = {.blocked = blocked};

static void global(void *data, struct wl_registry *reg, uint32_t name, const char *iface, uint32_t version) {
    (void)data;
    if (!strcmp(iface, wl_output_interface.name)) {
        struct output *o = calloc(1, sizeof *o);
        o->wl = wl_registry_bind(reg, name, &wl_output_interface, 1);
        o->name = name;
        o->next = outputs;
        outputs = o;
        apply();  // a new screen gets the current white point too
    } else if (!strcmp(iface, hyprland_ctm_control_manager_v1_interface.name)) {
        manager = wl_registry_bind(reg, name, &hyprland_ctm_control_manager_v1_interface, version < 2 ? version : 2);
        if (version >= 2) hyprland_ctm_control_manager_v1_add_listener(manager, &manager_listener, NULL);
    }
}

static void global_remove(void *data, struct wl_registry *reg, uint32_t name) {
    (void)data; (void)reg;
    for (struct output **p = &outputs; *p; p = &(*p)->next) {
        if ((*p)->name != name) continue;
        struct output *gone = *p;
        *p = gone->next;
        wl_output_destroy(gone->wl);
        free(gone);
        break;
    }
}
static const struct wl_registry_listener registry_listener = {.global = global, .global_remove = global_remove};

static void line(char *s) {
    double r, g, b;
    if (sscanf(s, "%lf %lf %lf", &r, &g, &b) != 3) return;
    if (r < 0 || g < 0 || b < 0) return;
    gain[0] = r; gain[1] = g; gain[2] = b;
    have_gain = 1;
    apply();
}

int main(void) {
    display = wl_display_connect(NULL);
    if (!display) { fprintf(stderr, "no Wayland display\n"); return 1; }
    struct wl_registry *registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, NULL);
    wl_display_roundtrip(display);
    if (!manager) { fprintf(stderr, "compositor has no hyprland-ctm-control\n"); return 1; }
    wl_display_roundtrip(display);  // hear "blocked" before taking any input

    char buf[256];
    size_t used = 0;
    struct pollfd fds[2] = {{.fd = wl_display_get_fd(display), .events = POLLIN}, {.fd = STDIN_FILENO, .events = POLLIN}};
    for (;;) {
        wl_display_dispatch_pending(display);
        wl_display_flush(display);
        if (poll(fds, 2, -1) < 0) {
            if (errno == EINTR) continue;
            return 1;
        }
        if (fds[0].revents & (POLLERR | POLLHUP)) return 1;  // the compositor went away
        if (fds[0].revents & POLLIN && wl_display_dispatch(display) < 0) return 1;
        if (fds[1].revents & (POLLIN | POLLHUP)) {
            ssize_t n = read(STDIN_FILENO, buf + used, sizeof buf - 1 - used);
            if (n <= 0) return 0;  // stdin closed: ambient-display is gone
            used += (size_t)n;
            buf[used] = 0;
            char *start = buf, *nl;
            while ((nl = strchr(start, '\n'))) {
                *nl = 0;
                line(start);
                start = nl + 1;
            }
            used = strlen(start);
            memmove(buf, start, used);
            if (used >= sizeof buf - 1) used = 0;  // a line too long to be ours
        }
    }
}
