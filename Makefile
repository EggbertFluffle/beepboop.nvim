# TODO: Makefile must be crossplatform

CC=g++
CFLAGS=-Wall -Wextra -Wpedantic -Werror -g
SDL3_MIXER_CFLAGS=$(shell pkg-config --cflags --libs sdl3-mixer)
SDL3_CFLAGS=$(shell pkg-config --cflags --libs sdl3)
# BINARY=/home/eggbert/.local/share/nvim/beepboop/bin/boopbeep
BINARY=./src/bin/boopbeep
SRC=./src/boopbeep.cpp

$(BINARY): $(SRC)
	$(CC) $(SRC) $(SDL3_CFLAGS) $(SDL3_MIXER_CFLAGS) -o $(BINARY)

clean: 
	rm $(BINARY)
