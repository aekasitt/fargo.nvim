-- ~~/lua/fargo/interface.lua --

local statemgmt = require('fargo.statemgmt')
local utilities = require('fargo.utilities')

local M = {}

function M.create_window()
  local config = statemgmt.get_config()
  local state = statemgmt.get_state()

  local width = config.window.width
  local height = config.window.height

  local ui = vim.api.nvim_list_uis()[1]
  local win_width = ui.width
  local win_height = ui.height

  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)

  state.buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_option(state.buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(state.buf, 'filetype', 'fargo')

  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = config.window.border,
    title = ' Workspace Crates ',
    title_pos = 'center',
    noautocmd = false,
  }

  state.win = vim.api.nvim_open_win(state.buf, true, opts)

  vim.api.nvim_win_set_option(state.win, 'cursorline', true)
  vim.api.nvim_win_set_option(state.win, 'cursorlineopt', 'both')
  vim.api.nvim_win_set_option(
    state.win,
    'winhighlight',
    'Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:Visual,SignColumn:NormalFloat,LineNr:NormalFloat,CursorLineNr:NormalFloat'
  )
  vim.api.nvim_win_set_option(state.win, 'number', false)
  vim.api.nvim_win_set_option(state.win, 'relativenumber', false)
  vim.api.nvim_win_set_option(state.win, 'signcolumn', 'no')

  M.render_crates()
  M.setup_keymaps()

  -- Position cursor on first crate line
  if #state.crates > 0 then
    vim.api.nvim_win_set_cursor(state.win, { 6, 0 })
  end
end

function M.render_crates()
  local config = statemgmt.get_config()
  local state = statemgmt.get_state()

  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end
  state.crates = utilities.get_workspace_crates()

  -- Check if nvim-web-devicons is available
  local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
  local eye_icon = has_devicons and '  ' or '[✓]' -- nf-fa-eye
  local eye_slash_icon = has_devicons and '  ' or '[ ]' -- nf-fa-eye_slash

  local lines = {}
  table.insert(lines, '')
  table.insert(lines, ' Space: toggle visibility  |  Enter: open in fff  |  q/Esc: close')
  table.insert(lines, '')
  table.insert(lines, string.rep('─', config.window.width - 2))
  table.insert(lines, '')
  for i, crate in ipairs(state.crates) do
    local icon = crate.visible and eye_icon or eye_slash_icon
    local line = string.format(' %s %s', icon, crate.name)
    table.insert(lines, line)
  end

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.buf, 'modifiable', false)
end

function M.toggle_crate()
  local state = statemgmt.get_state()
  local line = vim.api.nvim_win_get_cursor(state.win)[1]
  local crate_idx = line - 5 -- Account for header lines (3 header + 1 separator + 1 blank = 5)

  if crate_idx > 0 and crate_idx <= #state.crates then
    state.crates[crate_idx].visible = not state.crates[crate_idx].visible

    -- Update .ignore file to reflect visibility changes
    utilities.update_ignore_file(state.crates)

    M.render_crates()
    vim.api.nvim_win_set_cursor(state.win, { line, 0 })
  end
end

function M.open_in_fff()
  local config = statemgmt.get_config()
  local state = statemgmt.get_state()
  local line = vim.api.nvim_win_get_cursor(state.win)[1]
  local crate_idx = line - 5 -- Account for header lines

  if crate_idx > 0 and crate_idx <= #state.crates then
    local crate = state.crates[crate_idx]
    M.close()

    if config.fff_integration then
      local fff_ok, fff = pcall(require, 'fff')
      if fff_ok and fff.find_files then
        -- Open fff in the crate directory
        vim.cmd('cd ' .. crate.path)
        fff.find_files()
      else
        vim.cmd('edit ' .. crate.path)
      end
    else
      vim.cmd('edit ' .. crate.path)
    end
  end
end

function M.setup_keymaps()
  local state = statemgmt.get_state()
  local opts = { buffer = state.buf, nowait = true, silent = true }

  -- Action keys
  vim.keymap.set('n', '<Space>', M.toggle_crate, opts)
  vim.keymap.set('n', '<CR>', M.open_in_fff, opts)
  vim.keymap.set('n', 'q', M.close, opts)
  vim.keymap.set('n', '<Esc>', M.close, opts)

  -- Restricted movement keys
  local first_crate_line = 6
  local last_crate_line = 5 + #state.crates

  vim.keymap.set('n', 'j', function()
    local line = vim.api.nvim_win_get_cursor(state.win)[1]
    if line < last_crate_line then
      vim.cmd('normal! j')
    end
  end, opts)

  vim.keymap.set('n', 'k', function()
    local line = vim.api.nvim_win_get_cursor(state.win)[1]
    if line > first_crate_line then
      vim.cmd('normal! k')
    end
  end, opts)

  vim.keymap.set('n', '<Down>', function()
    local line = vim.api.nvim_win_get_cursor(state.win)[1]
    if line < last_crate_line then
      vim.cmd('normal! j')
    end
  end, opts)

  vim.keymap.set('n', '<Up>', function()
    local line = vim.api.nvim_win_get_cursor(state.win)[1]
    if line > first_crate_line then
      vim.cmd('normal! k')
    end
  end, opts)

  -- Jump to first/last crate
  vim.keymap.set('n', 'gg', function()
    vim.api.nvim_win_set_cursor(state.win, { first_crate_line, 0 })
  end, opts)

  vim.keymap.set('n', 'G', function()
    vim.api.nvim_win_set_cursor(state.win, { last_crate_line, 0 })
  end, opts)

  -- Restrict cursor movement with autocmd (catches all other movement attempts)
  vim.api.nvim_create_autocmd('CursorMoved', {
    buffer = state.buf,
    callback = function()
      local line = vim.api.nvim_win_get_cursor(state.win)[1]

      if line < first_crate_line then
        vim.api.nvim_win_set_cursor(state.win, { first_crate_line, 0 })
      elseif line > last_crate_line then
        vim.api.nvim_win_set_cursor(state.win, { last_crate_line, 0 })
      end
    end,
  })
end

function M.close()
  local state = statemgmt.get_state()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
  state.buf = nil
end

return M
