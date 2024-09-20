# A Neovim plugin

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/jackokring/doris.nvim/lint-test.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

A template for possible Neovim plugins. It is extended somewhat by me from
`ellisonleao/nvim-plugin-template` to include the basic features of a plugin
and possibly some useful additions, definitions and functions.

## Using it

Via `gh`:

```bash
gh repo create my-plugin -p jackokring/doris.nvim
```

Via Github web page:

Click on `Use this template`

![](https://docs.github.com/assets/cb-36544/images/help/repository/use-this-template-button.png)

## Features and structure

- 100% Lua
- Github actions for:
  - running tests using [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) and [busted](https://olivinelabs.com/busted/)
  - check for formatting errors (Stylua)
  - vimdocs autogeneration from README.md file
  - luarocks release (LUAROCKS_API_KEY secret configuration required)
  this is done by registration with luarocks, getting a LUAROCKS_API_KEY
  then adding it to the security settings option for secrets.

### Plugin structure

So `plugin/doris.lua` loads the plugin referencing `lua/doris.lua` and any
modules in `lua/doris` keeping all the detail out of the base plugin file.

```
.
├── lua
│   ├── doris
│   │   └── module.lua
│   └── doris.lua
├── Makefile
├── plugin
│   └── doris.lua
├── README.md
├── tests
│   ├── minimal_init.lua
│   └── doris
│       └── doris_spec.lua
```
