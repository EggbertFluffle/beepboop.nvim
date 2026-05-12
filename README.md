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

>[!Note]
> `:checkhealth beepboop` makes it easy to diagnose problems with your configuration

## Getting Started

### Installation

`Beepboop.nvim` uses a companion binary called [boopbeep](https://github.com/EggbertFluffle/boopbeep). The `get_binary_method` option controls how `beepboop.nvim` will get that binary, and uses `"download"` by default.

* `"download"` (default) - Downloads appropriate binary from [boopbeep's releases](https://github.com/EggbertFluffle/boopbeep/releases)
* `"build"` - Requires zig `0.16.0` to be installed, downloads and builds `boopbeep` from source
* `"none"` - No method is used. User **must** set `binary_path` to point to a `boopbeep` executable

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
            { trigger_name = "boom", sound = "vine_boom.wav" }
        }
    }
}
```

There are three ways to trigger sound maps within `beepboop.nvim`, those being auto commands, keymaps and trigger names. Trigger names are the easiest to understand; A sound map will assign a "trigger name" to a sound. That sound can be played using the trigger name, from anywhere, with `require("beepboop").play("TRIGGER_NAME")`.

```lua
{
    sounds_maps = {
        { trigger_name = "runcode", sound = "bell.wav" }
    }
}

vim.keymap.set("n", "<C-Enter>", function() 
    require("beepboop").play("runcode") -- Same trigger name
end)
```

Second, is to use Neovim's [https://neovim.io/doc/user/autocmd.html](auto commands). These are editor events that `beepboop.nvim` can easily attach sound to.

```lua
{
    sound_map = {
        { 
            auto_command = "VimEnter", -- When Neovim starts
            sound = "chestopen.oga" 
        }, 
        { 
            auto_command = "InsertCharPre", -- Insert mode key presses
            sounds = {
                "stone1.oga",
                "stone2.oga",
                "stone3.oga" 
            }
        }
    }
}
```

Third, keymaps behave just like `vim.keymap.set` but also get the option to be blocking. Blocking indicates that the keypress should not be passed through after the sound effect, and non-blocking (the default) will feed the keys through. Essentially previously made keymaps or common editor commands still work while also playing a sound. 

>[!Note] 
>Non-blocking `beepboop.nvim` keymaps will not override existing keymaps, but new Neovim keymaps **will** override these. To avoid this, just make sure `beepboop.nvim` is configured *after* the rest of your configuration.

```lua
{
    { 
        key_map = { mode = "n", key_chord = "<leader>pv", blocking = false },
        sound = "chestopen.oga" 
    },
    { 
        key_map = { mode = "n", key_chord = "<C-Enter>", blocking = true }, 
        sounds = { "stone1.oga", "stone2.oga", "stone3.oga", "stone4.oga" }
    }
}
```

The three methods can be combined to give sounds multiple access points. This can be useful for assignming the same sounds to the backspace key, and all insertion characters like so.

```lua
{
    sound_maps = {
        { 
            auto_command = "InsertCharPre", -- Standard character insert
            key_map = { mode = "i", key_chord = "<BS>" }, -- Backspace
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
    max_sounds = 15, -- How many of the same sound can play at once
    cooldown = 0 -- Master cooldown for playing sounds (ms)
}
```

#### Theme Repositories

Theme repositories are very easy to make if you already understand how to make themes. A theme repository can by any remotely hosted git repository and typically has the file structure seen below. The `theme.lua` simply returns a table containing the theme definition, but can also include arbitrary Lua code to be run for setup.

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
    name = "new_theme",
    sound_maps = {
		{
			key_map = { mode = "n", key_chord = "j" },
			sounds = { "scroll1.wav", "scroll2.wav", "scroll3.wav" }
		}
    }
}
```

## Plugin Compatability
Just some notes on using other plugins that are known to or may conflict with beepboop.nvim

### nvim-autopairs
If using [nvim-autopairs](https://github.com/windwp/nvim-autopairs) this will not allow beepboop.nvim to map sounds to `<BS>` (backspace key) or `<CR>` (enter key) by default. If you don't intend to map these keys to sounds, there's no conflict. If you do though, you need to turn off the maps for autopairs to `<BS>` and or  `<CR>` by including the following in your nvim-autopairs config:

```lua
{
    map_bs = false, -- removes map to <BS>
    map_cr = false  -- removes map to <CR>
}
```

## Themes List

If you have a theme you want to include here, go ahead and make an issue!

| Theme                                                                        | Description          |
| ---------------------------------------------------------------------------- | -------------------- |
| [mingleburb.beepboop](https://github.com/EggbertFluffle/mingleburb.beepboop) | Minecraft noises     |
| [typewriter.beepboop](https://github.com/EggbertFluffle/typewriter.beepboop) | Typewriter clicks    |
| [teehee.beepboop](https://github.com/EggbertFluffle/teehee.beepboop)         | *"What have I done"* |
| [keeb.beepboop](https://github.com/EggbertFluffle/keeb.beepboop)             | Mechanical keyboard  |

## Contribution and Bug Reporting

All contributions are welcome, just note that bugs or features for the companion binary should go to [boopbeep's repo](https://github.com/EggbertFluffle/boopbeep). If you have any question feel free to contact me via any of [these methods](https://eggbert.xyz#contact)
