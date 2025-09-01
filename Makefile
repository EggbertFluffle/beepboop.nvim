main: ./src/boopbeep.zig
	zig build

install: main
	zig build -p /home/eggbert/.local/share/nvim/beepboop/

uninstall:
	rm -rf /home/eggbert/.local/share/nvim/beepboop/bin

clean:
	rm ./zig-out/bin/boopbeep

clean_themes:
	rm -rf ~/.local/share/nvim/beepboop/themes/*
