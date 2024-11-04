# A Neovim plugin Mk II

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/jackokring/doris.nvim/lint-test.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

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
  dev = {
    path = "~/projects/doris.nvim",
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

- [ ] Novaride `lua/doris/novaride.lua` global namespace anti-clobber
- [ ] More pure help functions in `lua/doris/module.lua` with pass through
- [x] Pass through of plenary selected modules using short names
- [x] Output window 80\*24 with keyboard capture callback
  - [x] "Ghost" character to "use" cursor visibility (normal mode)
  - [ ] Tested
- [ ] Network client server for multiplayer
  - [ ] Tested
  - [ ] Three player
- [ ] Documentation of new additions
- [ ] A mini-game to play using nerd font glyphs
- [ ] A `.js` file to pass joypad from a browser to a TCP socket for home row keys
- [ ] Investigate `.py` control of `nvim --embed` for features
  - [ ] For local AI players maybe or just use network layer
- [ ] ...

### Plugin structure

So `plugin/doris.lua` loads the plugin referencing `lua/doris.lua` and any
modules in `lua/doris` keeping all the detail out of the base plugin file.

```text
.
├── lua
│   ├── doris
│   │   └── module.lua (pure lua)
│   │   └── novaride.lua (pure lua global context protection)
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
