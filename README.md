# BeepBoop.nvim

`Beepboop.nvim` is a Neovim plugin intended to make it easy to incorporate audio cues into Neovim. This can be for accessibility reasons, or in my case, just for fun! Check out the demo below for a little taste of whats possible:

https://github.com/user-attachments/assets/0c3fa223-4d8c-428e-b561-bcbee5ccce8a

## Quick Start

Below are some configs you can throw right into your editor to get some sounds FAST. Take a look at [Getting Started](https://github.com/EggbertFluffle/beepboop.nvim#getting-started) for information on installation, themes and options.

### vim.pack

```lua
vim.pack.add({ "https://github.com/EggbertFluffle/beepboop.nvim" })

require("beepboop").setup({
    theme = "https://github.com/EggbertFluffle/mingleburb.beepboop"
})
```

### lazy.nvim

```lua
{
    "EggbertFluffle/beepboop.nvim",
    opts = {
        theme = "https://github.com/EggbertFluffle/mingleburb.beepboop"
    }
}
```

> [!Note]
> `:checkhealth beepboop` makes it easy to diagnose problems with your configuration

## Getting Started

### Installation

`Beepboop.nvim` uses a companion binary called [boopbeep](https://github.com/EggbertFluffle/boopbeep). The `get_binary_method` option controls how `beepboop.nvim` will get that binary, and uses `"download"` by default.

* `"download"` (default) - Downloads appropriate binary from [boopbeep's releases](https://github.com/EggbertFluffle/boopbeep/releases)
* `"build"` - Requires zig `0.16.0` to be installed, downloads and builds `boopbeep` from source
* `"none"` - No method is used. User **must** set `binary_path` to point to a `boopbeep` executable

> [!Note]
> Beepboop.nvim should work in most enviornments. WSL has not been tested, and building on MacOS seems to be finicky.

### Themes

Themes can be aquired and crafted in several ways. The easiest is through theme repositories. [typewriter.beepboop](https://github.com/EggbertFluffle/typewriter.beepboop) and [mingleburb.beepboop](https://github.com/EggbertFluffle/mingleburb.beepboop) are both remote theme repositories, and can be installed by simply providing their URL. Local theme repositories can be used the same way by providing their **absolute** path.

```lua
{
    theme = "https://github.com/EggbertFluffle/typewriter.beepboop",
    ...
}
```

Finally, themes can be constructed *in-config*. Read more about making themes at [Making Themes](https://github.com/EggbertFluffle/beepboop.nvim#making-themes).

## Configuration

### Default Configuration

```lua
{
	mute = false, -- Start muted
	binary_path = "", -- Path to boopbeep binary
    volume = 100, -- Starting master volume
    get_binary_method = "download",
    theme_directory = "$DATA/beepboop/themes/", -- Theme download location
    theme = nil,
}
```

### Making Themes

#### Sound Maps

Theme's are comprised of "sound maps", which typically associate an action with some sounds. They can correspond to one or multiple sounds, where triggering a sound map will play one of its sounds at random. Sounds are represented as files relative to a user defined `sounds_directory`.

```lua
{
    theme = {
        sounds_directory = "/home/eggbert/.config/nvim/sounds/"
        sound_maps = {
            { trigger = "boom", sound = "vine_boom.wav" }
        }
    }
}
```

There are three ways to trigger sound maps within `beepboop.nvim`, those being auto commands, keymaps and triggers. Triggers are the easiest to understand; A sound map will assign a trigger to a sound. That sound can be played using the trigger from anywhere, with `require("beepboop").play("TRIGGER")`.

```lua
{
    sounds_maps = {
        { trigger = "runcode", sound = "bell.wav" }
    }
}

vim.keymap.set("n", "<C-Enter>", function() 
    require("beepboop").play("runcode") -- Same trigger name
end)
```

Second, is to use Neovim's [auto commands](https://neovim.io/doc/user/autocmd.html). These are editor events that `beepboop.nvim` can easily attach sound to.

```lua
{
    sound_map = {
        { 
            autocommand = "VimEnter", -- When Neovim starts
            sound = "chestopen.oga" 
        }, 
        { 
            autocommand = "InsertCharPre", -- Insert mode key presses
            sounds = {
                "stone1.oga",
                "stone2.oga",
                "stone3.oga" 
            }
        }
    }
}
```

Keymaps behave just like `vim.keymap.set` but also get the option to be blocking. Blocking indicates that the keypress should not be passed through after the sound effect, and non-blocking (the default) will feed the keys through. Essentially previously made keymaps or common editor commands still work while also playing a sound. 

>[!Note] 
>Non-blocking `beepboop.nvim` keymaps will not override existing keymaps, but new Neovim keymaps **will** override these. To avoid this, just make sure `beepboop.nvim` is configured *after* the rest of your configuration, or at least after conflicting keymaps.

```lua
{
    { 
        keymap = { mode = "n", keychord = "<leader>pv", blocking = false },
        sound = "chestopen.oga" 
    },
    { 
        keymap = { mode = "n", keychord = "<C-Enter>", blocking = true }, 
        sounds = { "stone1.oga", "stone2.oga", "stone3.oga", "stone4.oga" }
    }
}
```

The three methods can be combined to give sounds multiple access points. This can be useful for assignming the same sounds to the backspace key, and all insertion characters like so.

```lua
{
    sound_maps = {
        { 
            autocommand = "InsertCharPre", -- Standard character insert
            keymap = { mode = "i", keychord = "<BS>" }, -- Backspace
            sounds = {
                "stone1.oga",
                "stone2.oga",
                "stone3.oga" 
            }
        }
    }
}
```

#### Theme Default Options

```lua
{
    name = "untitled",
    sound_directory = "$CONFIG/sounds/", -- Only for in-config themes
}
```

#### Theme Repositories

Theme repositories are very easy to make if you already understand how to make themes. A theme repository can by any remotely hosted git repository and typically has the file structure seen below. The `theme.lua` simply returns a table containing the theme definition, but can also include arbitrary Lua code to be run for setup. Check the [Theme List](https://github.com/EggbertFluffle/beepboop.nvim#themes-list) for examples.

```
.
├── sounds
│   ├── sound3.wav
│   ├── sound1.wav
│   └── sound2.wav
└── theme.lua
```

```lua
-- theme.lua

return {
    sound_maps = {
		{
			keymap = { mode = "n", keychord = "j" },
			sounds = { "scroll1.wav", "scroll2.wav", "scroll3.wav" }
		}
    }
}
```
## User Commands
| Command                          | Description                                   |
| -------------------------------- | --------------------------------------------- |
| :Beepboop mute                   | Mutes                                         |
| :Beepboop unmute                 | Unmutes                                       |
| :Beepboop toggleMute             | Toggles mute                                  |
| :Beepboop volume <INTEGER 1-100> | Sets master volume                            |
| :Beepboop theme <THEME URI>      | Switch themes based on remote or local themes |

## Plugin Compatability
Just some notes on using other plugins that are known to or may conflict with beepboop.nvim.

### nvim-autopairs
If using [nvim-autopairs](https://github.com/windwp/nvim-autopairs) this will not allow beepboop.nvim to map sounds to `<BS>` (backspace key) or `<CR>` (enter key) by default. If you don't intend to map these keys to sounds, there's no conflict. If you do though, you need to turn off the maps for autopairs to `<BS>` and or  `<CR>` by including the following in your nvim-autopairs config:

```lua
{
    map_bs = false, -- removes map to <BS>
    map_cr = false  -- removes map to <CR>
}
```

## Themes List

Check out the publicly made themes at the [beepboop.nvim themes list](https://github.com/EggbertFluffle/theme_list.beepboop). If you have a theme you want to include, make an issue over there!

Some "provided" themes for beepboop.nvim are listed below.

| Theme                                                                        | Description          |
| ---------------------------------------------------------------------------- | -------------------- |
| [mingleburb.beepboop](https://github.com/EggbertFluffle/mingleburb.beepboop) | Minecraft noises     |
| [typewriter.beepboop](https://github.com/EggbertFluffle/typewriter.beepboop) | Typewriter clicks    |
| [teehee.beepboop](https://github.com/EggbertFluffle/teehee.beepboop)         | *"What have I done"* |
| [keeb.beepboop](https://github.com/EggbertFluffle/keeb.beepboop)             | Mechanical keyboard  |

## Contribution and Bug Reporting

All contributions are welcome. If you have any question feel free to contact me via any of [these methods](https://eggbert.xyz#contact)
