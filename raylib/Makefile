# Builds the game for desktop and for the web from the same sources.
# Run it inside `nix develop`, which provides gcc, raylib, emcc and RAYLIB_SRC.
#
#   make          desktop build -> build/desktop/$(NAME)
#   make run      build and run it (from the project root, so assets/ is found)
#   make web      web build     -> build/web/  (index.html .js .wasm .data: copy this folder anywhere)
#   make serve    web build, served on http://localhost:8000
#   make clean
#
# Every src/*.c is compiled; everything in assets/ ships with the game.

# NAME comes from flake.nix (the dev shell exports it); "game" outside of it
NAME       ?= game
PREFIX     ?= /usr/local
ASSETS_DIR ?= assets

SRC    := $(wildcard src/*.c)
ASSETS := $(shell find assets -type f 2>/dev/null)

.PHONY: all run web serve install clean
all: build/desktop/$(NAME)

# ---- desktop: links raylib from the system (pkg-config) ---------------------------------
CFLAGS      ?= -O2 -g
DESKTOP_OBJ := $(SRC:src/%.c=build/desktop-obj/%.o)

build/desktop/$(NAME): $(DESKTOP_OBJ)
	@mkdir -p $(@D)
	$(CC) $^ $(shell pkg-config --libs raylib) -lm $(LDLIBS) -o $@

build/desktop-obj/%.o: src/%.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -std=gnu11 -Wall -Wextra -MMD -MP $(shell pkg-config --cflags raylib) \
		-DASSETS_DIR='"$(ASSETS_DIR)"' -c $< -o $@

run: build/desktop/$(NAME)
	./build/desktop/$(NAME)

install: build/desktop/$(NAME)
	install -Dm755 build/desktop/$(NAME) $(PREFIX)/bin/$(NAME)
	mkdir -p $(PREFIX)/share/$(NAME)
	cp -r assets $(PREFIX)/share/$(NAME)/

# ---- web: raylib compiled from its sources (RAYLIB_SRC) with emcc ------------------------
RAYLIB_MODULES := rcore rshapes rtextures rtext rmodels raudio
WEB_OBJ := $(SRC:src/%.c=build/web-obj/%.o) $(RAYLIB_MODULES:%=build/web-obj/raylib/%.o)
# -ffile-prefix-map: keep the raylib source path (a Nix store path) out of the output
WEB_CFLAGS := -O3 -flto -std=gnu11 -Wall -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES2 \
	-I$(RAYLIB_SRC)/src -ffile-prefix-map=$(RAYLIB_SRC)=raylib -MMD -MP
# A fixed heap instead of ALLOW_MEMORY_GROWTH: raylib warns growth can break audio buffers.
WEB_LDFLAGS := -O3 -flto -sUSE_GLFW=3 -sINITIAL_MEMORY=134217728 \
	--shell-file web/shell.html --preload-file assets

ifneq ($(filter web serve,$(MAKECMDGOALS)),)
ifeq ($(RAYLIB_SRC),)
$(error RAYLIB_SRC is not set: run this inside nix develop)
endif
endif

web: build/web/index.html

build/web/index.html: $(WEB_OBJ) web/shell.html $(ASSETS)
	@mkdir -p $(@D)
	emcc $(WEB_OBJ) $(WEB_LDFLAGS) -o $@

build/web-obj/%.o: src/%.c
	@mkdir -p $(@D)
	emcc $(WEB_CFLAGS) -c $< -o $@

build/web-obj/raylib/%.o: $(RAYLIB_SRC)/src/%.c
	@mkdir -p $(@D)
	emcc $(WEB_CFLAGS) -w -c $< -o $@

serve: web
	python3 -m http.server 8000 -d build/web

clean:
	rm -rf build

-include $(DESKTOP_OBJ:.o=.d) $(WEB_OBJ:.o=.d)
