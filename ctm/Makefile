XML := $(shell pkg-config --variable=pkgdatadir hyprland-protocols)/protocols/hyprland-ctm-control-v1.xml
CFLAGS ?= -O2 -Wall -Wextra

BIN := ../home/.local/bin/white-point-ctm

$(BIN): white-point-ctm.c hyprland-ctm-control-v1-client-protocol.h hyprland-ctm-control-v1-protocol.c
	$(CC) $(CFLAGS) -o $@ white-point-ctm.c hyprland-ctm-control-v1-protocol.c $(shell pkg-config --cflags --libs wayland-client)

hyprland-ctm-control-v1.xml: $(XML)
	sed 's/<description>/<description summary="see text">/' $< > $@

hyprland-ctm-control-v1-client-protocol.h: hyprland-ctm-control-v1.xml
	wayland-scanner client-header $< $@

hyprland-ctm-control-v1-protocol.c: hyprland-ctm-control-v1.xml
	wayland-scanner private-code $< $@

clean:
	rm -f $(BIN) hyprland-ctm-control-v1.xml hyprland-ctm-control-v1-client-protocol.h hyprland-ctm-control-v1-protocol.c
