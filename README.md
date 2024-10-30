# A Neovim plugin Mk II

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/jackokring/doris.nvim/lint-test.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

A template for possible Neovim plugins. It is extended somewhat by me from
`ellisonleao/nvim-plugin-template` to include the basic features of a plugin
and possibly some useful additions, definitions and functions.

## Using it

Via `lazy.nvim`:

```lua
return {
  "jackokring/doris.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
}
```

Configuration for development requires using a local redirect similar to
the changes below.

```lua
return {
  "jackokring/doris.nvim",
  -- **local build**
  name = "doris.nvim",
  dev = {
    path = "~/projects",
    patterns = { "jackokring" },
    fallback = true,
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
}
```

Via `gh`:

```bash
gh repo create my-plugin -p jackokring/doris.nvim
```

Via Github web page:

Click on `Use this template` if this repository is a template.

![Button .png file](https://docs.github.com/assets/cb-36544/images/help/repository/use-this-template-button.png)

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

[X] Pass through of plenary selected modules using short names
[ ] Output window 80\*24 with keyboard capture callback
[ ] Documentation of new additions
[ ] A mini-game to play using nerd font glyphs
[ ] A `.js` file to pass joypad from a browser to a TCP socket for home row keys
[ ] Investigate `.py` control of `nvim --embed` for features
[ ] ...

### Plugin structure

So `plugin/doris.lua` loads the plugin referencing `lua/doris.lua` and any
modules in `lua/doris` keeping all the detail out of the base plugin file.

```text
.
├── lua
│   ├── doris
│   │   └── module.lua (pure lua)
│   └── doris.lua (nvim lua)
├── Makefile (for tests and build)
├── plugin
│   └── doris.lua (nvim new commands loaded)
├── README.md (auto-generation of doc/doris.txt from it)
├── tests
│   ├── minimal_init.lua (test base configuration)
│   └── doris
│       └── doris_spec.lua (tests of doris using plenary)
```
