# white-point-ctm: see white-point-ctm.c. Needs gcc, wayland-client, wayland-scanner
# and hyprland-protocols (all on an Omarchy system that has built Hyprland).
XML := $(shell pkg-config --variable=pkgdatadir hyprland-protocols)/protocols/hyprland-ctm-control-v1.xml
CFLAGS ?= -O2 -Wall -Wextra

white-point-ctm: white-point-ctm.c hyprland-ctm-control-v1-client-protocol.h hyprland-ctm-control-v1-protocol.c
	$(CC) $(CFLAGS) -o $@ white-point-ctm.c hyprland-ctm-control-v1-protocol.c $(shell pkg-config --cflags --libs wayland-client)

# The shipped XML has a <description> with no summary, which wayland-scanner
# refuses; give it one in a local copy.
hyprland-ctm-control-v1.xml: $(XML)
	sed 's/<description>/<description summary="see text">/' $< > $@

hyprland-ctm-control-v1-client-protocol.h: hyprland-ctm-control-v1.xml
	wayland-scanner client-header $< $@

hyprland-ctm-control-v1-protocol.c: hyprland-ctm-control-v1.xml
	wayland-scanner private-code $< $@

clean:
	rm -f white-point-ctm hyprland-ctm-control-v1.xml hyprland-ctm-control-v1-client-protocol.h hyprland-ctm-control-v1-protocol.c
