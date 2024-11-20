# A Neovim plugin Mk II

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/jackokring/doris.nvim/lint-test.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

```text
     _            _                  _
  __| | ___  _ __(_)___   _ ____   _(_)_ __ ___
 / _` |/ _ \| '__| / __| | '_ \ \ / / | '_ ` _ \
| (_| | (_) | |  | \__ \_| | | \ V /| | | | | | |
 \__,_|\___/|_|  |_|___(_)_| |_|\_/ |_|_| |_| |_|
```

A template for possible Neovim plugins. It is extended somewhat by me from
`ellisonleao/nvim-plugin-template` to include the basic features of a plugin
and possibly some useful additions, definitions and functions.

I just though I'd say remapping insert mode `<C-\\>` to `<esc>a` has much
improved my `nvim` experience as it can be used to close the LSP completion
dropdown, and so not interfere with use of the actual cursor keys. By default
the cursor keys move up and down the LSP completions and not up and down the
document. Some purists might say go to normal mode and move about.

The key `<C-\\>` is actually mapped to some other stuff which I've never used
and am not likely to use. I'm still a fan of `o` instead of `i`. I like
"output". `A<cr>` was a thing for a while. I'm sure `hjkl` are right for some,
but I'd be happier if the left and right arrows would flow past the beginning
and end of lines. It's not "normal." I'm looking into `luaSnip` now, as I am
now enthused enough about not being driven to OCD LSP hell.

I know `<C-e>` is supposed to be used for this, but on an ISO keyboard,
the single finger or tiny motion `<C-\\>` is possible.

Oh, and I mapped `<C-s>` to save all buffers keeping the mode, and `<C-z>` to
revert from file, defaulting to a "normal" start. Nice to see formatting
of indents auto magical happens on save. The keys `[s`, `zg` and `z=` replace
much of what `r` does. But on with the show.

There's some nice things about Lua. `..` amongst them. The `_G` extension
to the language is excellent. It's a very post JavaScript, post modern BASIC
(from an age where all acronyms were capital case, CamelCase and snake_case
were dreams, and iGeneric was for discerning connoisseurs in plastic macs.) So I
added `num` and `chr`. Cool.

## Novaride

I've added `doris/novaride` to control the namespace `_G`. It sets up a proxy
to manage override attempts via `__newindex`. It has a function `.ignore(t, ...)`
so that strings of fields to allow an override on can be setup if you
experience an `_G.oh_dear` from somewhere else and would instead like the
suppressed override. As a consequence of it being just a simple extension
of code available online, you can also `.track(t)` any other tables for
protection from overrides. If you supply `nil` as `t`, `_G` will be assumed.
Don't forget to `.restore()` novaride to unnest the protection, and regain a
slight amount of speed from removing the protection "virtualization."

It does `local novaride = require("doris.novaride").setup() ...` and
at the end just before `return M` (or whatever the module is called) a
`novaride.restore()`. Added in `.untrack(t)` which returns a table untracked.

This is a very useful `require()`.

## Module

A few convenience things are placed in the `_G` context for faster coding
and syntax sugar. It includes a pattern compiler, the `range` iterator,
a `switch` statement and various wrappers around `string.format` to name
a few. I think it's quite nice, but that's just me.

It's written in pure lua as anything `nvim` has been kept out of it. This is
why `chr` and `num` are not in this file. Not that they can't be written
in pure lua, it's just `nvim` kid of already has likely optimized versions.

These are the things that, I consider, should have been in Lua as defaults.

## Async

A pass-through into the `_G` namespace of much of the plenary async module
along with some extras. The `plenary.async.control` is `sync`. A general
wrapper around `coroutine`, for more `async`/`await` style coding.

## Object

Various classes placed in the `_G` context. This relies on the plenary OOP
library, and includes some `Nad` monad/comonad functional programming bits.
Overriding `conad()`, `new()` and using `class()` maybe is useful.

I mean there is no identity monad, as tables are not bare types like integers.
It does include a `Term` type though if `nil` terminated lists and things are
not your bag. Kind of a multi-false paradigm, or is that multi-true?

Everyone's class implementation in Lua is kind of strange.

## Bus

A simple bus object `Bus("<name>")` returns a bus instance with `send(...)`,
`listen(fn)` and `remove(fn)`. The bus operates in cycles to prevent multiple
calls to the same listener per cycle. That is to say all bus events are queued
and the queue is played back with sends being uniquely queued for a later cycle.

It's useful if you need it.

## Extras-backup

Just some dot files for `extras-install.sh` to interactively install if you
wish. A nerd font, and some of my config for `nvim` (LazyVim), `rofi`, `nano`
and `neofetch`. It also includes a helper to compile `dwm` (but you need source)
of all the bits in `~` subfolders (`dwm`, `dmenu`, `st` and `slstatus`). I've got
other repositories with my modified versions of these, which `make install` to
`~/bin`.

## Using it

Via `lazy.nvim`:

```lua
return {
  "jackokring/doris.nvim",
  build = "./build.sh"
}
```

Then `require("doris")` for all things except `require("doris.novaride").setup()`
with `.restore()` of the `.setup()` local at the end of a file using Novaride.

This is because Novaride is a utility to check namespace security between its
`.setup()` and `.restore()`.

## Development

Configuration for development requires using a local redirect similar to
the changes below. This then uses the local version based on `dir` as the
location of the repository.

```lua
-- doris plugin loader for nvim
return {
  "jackokring/doris.nvim",
  -- **local build**
  dev = true,
  dir = "~/projects/doris.nvim",
  fallback = true,
  -- **build command**
  build = "./build.sh",
  -- **setup options**
  opts = {},
  -- **lazy load info**
  -- lazy = true,
  -- **on event**
  -- event = { "BufEnter", "BufEnter *.lua" },
  -- **on command use**
  -- cmd = { "cmd" },
  -- **on filetype**
  -- ft = { "lua" },
  -- **on keys**
  -- keys = {
  --    -- key tables
  --    {
  --      "<leader>ft",
  --      -- "<cmd>Neotree toggle<cr>",
  --      -- desc = "NeoTree",
  --      -- mode = "n",
  --      -- ft = "lua"
  --    },
  --  },
}
```

### `:Lazy reload doris.nvim` to bring it upto date by a reload

## Features and structure

- 100% Lua
- Github actions for:
  - running tests using [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
    and [busted](https://olivinelabs.com/busted/)
  - check for formatting errors (Stylua)
  - vimdocs auto-generation from README.md file
  - luarocks release (LUAROCKS_API_KEY secret configuration required)
    this is done by registration with luarocks, getting a LUAROCKS_API_KEY
    then adding it to the security settings option for secrets.

### Features To Do

- [x] Novaride `lua/doris/novaride.lua` global namespace anti-clobber
- [x] More pure help functions in `lua/doris/module.lua` with pass through
- [x] Pass through of plenary selected modules using short names
- [x] Simple Bus module for attachment of functions to signals
- [x] Output window 80\*24 with keyboard capture callback
  - [ ] Cursor keys still need redirect
  - [x] "Ghost" character to "use" cursor visibility (normal mode)
  - [ ] Tested
- [ ] Audio format:
  - `len vol freq filt vol.drift freq.drift filt.drift [mod ...]`
- [ ] Network client server for multiplayer
  - [ ] Tested
  - [ ] Three player
- [ ] Documentation of new additions
- [ ] A mini-game to play using nerd font glyphs
- [ ] A `.js` file to pass joypad from a browser to a TCP socket for home row keys
- [ ] Investigate `.py` control of `nvim --embed` for features
  - [ ] For local AI players maybe or just use network layer
- [ ] Added in a template for adding in C native `.so` production
- [ ] ...

### Plugin structure

So `plugin/doris.lua` loads commands. Main reference is `lua/doris.lua` with
modules in `lua/doris` keeping all the detail out of the base plugin file.

```text
.
├── lua
│   ├── doris
│   │   ├── bus.lua (pure lua a simple function call bus)
│   │   ├── module.lua (pure lua programming aid for terse input)
│   │   ├── novaride.lua (pure lua global context protection)
│   │   └── object.lua (pure plenary lua OOP and functionals)
│   └── doris.lua (nvim lua main module)
├── c
│   ├── audio.c
│   ├── doris.c
│   └── doris.h
├── build.sh (shell script to compile C shared doris.so)
├── freeze.sh (shell script to freeze venv and extras)
├── require.sh (shell script to make python venv from git pull)
├── extras-install.sh (shell script to offer option to install .config files)
├── extras-backup (.config files)
│   └── ...
├── yes-no.sh (shell script to get a yes or no)
├── xdg.sh (shell script to include for XDG directories)
├── Makefile (for tests and build)
├── plugin
│   └── doris.lua (nvim new commands loaded)
├── README.md (auto-generation of doc/doris.txt from it)
├── tests
│   ├── minimal_init.lua (test base configuration)
│   └── doris
│       └── doris_spec.lua (tests of doris using plenary)
```
