# Fargo

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/aekasitt/fargo.nvim/blob/master/LICENSE)
[![Top](https://img.shields.io/github/languages/top/aekasitt/fargo.nvim)](https://github.com/aekasitt/fargo.nvim)
[![Languages](https://img.shields.io/github/languages/count/aekasitt/fargo.nvim)](https://github.com/aekasitt/fargo.nvim)
[![Size](https://img.shields.io/github/repo-size/aekasitt/fargo.nvim)](https://github.com/aekasitt/fargo.nvim)
[![Last commit](https://img.shields.io/github/last-commit/aekasitt/fargo.nvim/master)](https://github.com/aekasitt/fargo.nvim)

[![Fargo banner](https://github.com/aekasitt/fargo.nvim/blob/master/static/fargo-banner.svg)](static/fargo-banner.svg)

## Features

- Toggle dropdown window showing workspace crates from `Cargo.toml`
- Toggle visibility of individual crates
- Open crates in fff file manager
- Customizable keybindings and window appearance

## Demonstration

[![Fargo demo](https://github.com/aekasitt/fargo.nvim/blob/master/static/fargo.gif)](static/fargo.gif)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'aekasitt/fargo.nvim',
  config = function()
    require('fargo').setup({
      keybinding = '<leader>fg',
      window = {
        border = 'rounded',
        height = 15,
        width = 60,
      },
      fff_integration = true,
    })
  end,
  dependencies = {
    'dmtrKovalenko/fff.nvim',  -- (optional) for quick access
    'nvim-tree/nvim-web-devicons',  -- (optional) for better icons
  },
}
```

## Configuration

Default configuration:

```lua
require('fargo').setup({
  fff_integration = true,  -- Use fff.nvim to open crates
  keybinding = '<leader>fg',
  window = {
    border = 'rounded',  -- 'none', 'single', 'double', 'rounded', 'solid', 'shadow'
    height = 15,
    width = 60,
  },
})
```

## Usage

### Commands

- `:FargoToggle` - Toggle the workspace crates dropdown

### Default Keybindings

In the dropdown window:
- `<Space>` - Toggle crate visibility
- `<CR>` - Open crate in fff
- `q` or `<Esc>` - Close the dropdown

## Requirements

- Neovim >= 0.8.0
- A Rust workspace with `Cargo.toml` containing workspace members
- (Optional) [fff.nvim](https://github.com/dmtrKovalenko/fff.nvim) for file manager integration
- (Optional) [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) for better icons

## License

This project is licensed under the terms of the MIT license.
