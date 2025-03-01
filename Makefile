# TODO: Makefile must be crossplatform

CC=g++
CFLAGS=-Wall -Wpedantic -Werror -g
SDL2_MIXER_CFLAGS=$(shell pkg-config --cflags --libs SDL2_mixer)
BINARY=./src/bin/boopbeep
SRC=./src/boopbeep.cpp

$(BINARY): $(SRC)
	$(CC) $(SRC) $(SDL2_MIXER_CFLAGS) -o $(BINARY)

clean: 
	rm $(BINARY)
