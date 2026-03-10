# Fargo

A Neovim plugin that integrates with [fff.nvim](https://github.com/dmtrKovalenko/fff.nvim)
to provide a toggle dropdown for managing workspace crates visibility.

## Features

- Toggle dropdown window showing workspace crates from `Cargo.toml`
- Toggle visibility of individual crates
- Open crates in fff file manager
- Customizable keybindings and window appearance

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
  dependencies = { 'dmtrKovalenko/fff.nvim' },
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

## License

This project is licensed under the terms of the MIT license.
