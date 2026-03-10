-- ~~/lua/fargo/init.lua --

local interface = require('fargo.interface')
local statemgmt = require('fargo.statemgmt')
local utilities = require('fargo.utilities')

local M = {}

function M.setup(opts)
  statemgmt.set_config(opts)
  local config = statemgmt.get_config()

  if config.keybinding then
    vim.keymap.set('n', config.keybinding, function()
      M.toggle()
    end, { desc = 'Toggle Fargo workspace crates' })
  end
end

function M.toggle()
  local state = statemgmt.get_state()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    interface.close()
  else
    interface.create_window()
  end
end

function M.get_visible_crates()
  local state = statemgmt.get_state()
  local visible = {}
  for _, crate in ipairs(state.crates) do
    if crate.visible then
      table.insert(visible, crate)
    end
  end
  return visible
end

return M
