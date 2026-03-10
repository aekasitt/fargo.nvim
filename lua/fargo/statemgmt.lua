-- ~~/lua/fargo/statemgmt.lua --

local M = {}

M.config = {
  fff_integration = true,
  keybinding = '<leader>fg',
  window = {
    border = 'rounded',
    height = 15,
    width = 60,
  },
}

M.state = {
  buf = nil,
  win = nil,
  crates = {},
}

function M.get_config()
  return M.config
end

function M.set_config(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

function M.get_state()
  return M.state
end

return M
