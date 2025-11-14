debug: ./src/boopbeep.zig
	zig build -Dstrip=false

release: ./src/boopbeep.zig
	zig build -Dstrip=true

install:
	mkdir -p ~/.local/share/nvim/beepboop/bin/
	cp ./zig-out/bin/* ~/.local/share/nvim/beepboop/bin/

uninstall:
	rm -rf ~/.local/share/nvim/beepboop/bin/*

clean:
	rm ./zig-out/bin/*

clean_themes:
	rm -rf ~/.local/share/nvim/beepboop/themes/*
