-- ~~/fargo/init.lua --

local M = {}

local config = {
  fff_integration = true,
  keybinding = '<leader>fg',
  window = {
    border = 'rounded',
    height = 15,
    width = 60,
  },
}

local state = {
  buf = nil,
  win = nil,
  crates = {},
}

function M.setup(opts)
  config = vim.tbl_deep_extend('force', config, opts or {})
  if config.keybinding then
    vim.keymap.set('n', config.keybinding, function()
      M.toggle()
    end, { desc = 'Toggle Fargo workspace crates' })
  end
end

function M.get_hidden_crates_from_ignore()
  local cwd = vim.fn.getcwd()
  local ignore_file = cwd .. '/.ignore'
  local hidden = {}

  if vim.fn.filereadable(ignore_file) == 1 then
    local in_fargo_section = false
    for _, line in ipairs(vim.fn.readfile(ignore_file)) do
      if line == '# fargo-nvim: start' then
        in_fargo_section = true
      elseif line == '# fargo-nvim: end' then
        in_fargo_section = false
      elseif in_fargo_section and line ~= '' then
        hidden[line] = true
      end
    end
  end

  return hidden
end

function M.get_workspace_crates()
  local crates = {}
  local cwd = vim.fn.getcwd()

  local cargo_toml = cwd .. '/Cargo.toml'

  if vim.fn.filereadable(cargo_toml) == 1 then
    local content = table.concat(vim.fn.readfile(cargo_toml), '\n')

    -- Find [workspace] section (stop at next TOML section like [package] or [dependencies])
    local workspace_section = content:match('%[workspace%](.-)\n%[%w')
    if not workspace_section then
      -- No other section after [workspace], take until end
      workspace_section = content:match('%[workspace%](.*)')
    end

    if workspace_section then
      -- Extract members array - handles both inline and multiline formats
      -- Inline: members = ["crate1", "crate2"]
      -- Multiline: members = [
      --   "crate1",
      --   "crate2",
      -- ]
      local members_content = workspace_section:match('members%s*=%s*%[(.-)%]')

      if members_content then
        -- Load hidden crates from .ignore file
        local hidden = M.get_hidden_crates_from_ignore()

        -- Extract all quoted strings from the members array (both single and double quotes)
        for crate_name in members_content:gmatch('["\']([^"\']+)["\']') do
          table.insert(crates, {
            name = crate_name,
            path = cwd .. '/' .. crate_name,
            visible = not hidden[crate_name],
          })
        end
      end
    end
  end

  return crates
end

function M.create_window()
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
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end
  state.crates = M.get_workspace_crates()

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

function M.update_ignore_file()
  local cwd = vim.fn.getcwd()
  local ignore_file = cwd .. '/.ignore'

  -- Read existing .ignore file
  local existing_lines = {}
  local fargo_start_marker = '# fargo-nvim: start'
  local fargo_end_marker = '# fargo-nvim: end'
  local in_fargo_section = false

  if vim.fn.filereadable(ignore_file) == 1 then
    for _, line in ipairs(vim.fn.readfile(ignore_file)) do
      if line == fargo_start_marker then
        in_fargo_section = true
      elseif line == fargo_end_marker then
        in_fargo_section = false
      elseif not in_fargo_section then
        table.insert(existing_lines, line)
      end
    end
  end

  -- Build new content with fargo section
  local new_lines = {}
  for _, line in ipairs(existing_lines) do
    table.insert(new_lines, line)
  end

  -- Add fargo-managed hidden crates
  local hidden_crates = {}
  for _, crate in ipairs(state.crates) do
    if not crate.visible then
      table.insert(hidden_crates, crate.name)
    end
  end

  if #hidden_crates > 0 then
    table.insert(new_lines, fargo_start_marker)
    for _, crate_name in ipairs(hidden_crates) do
      table.insert(new_lines, crate_name)
    end
    table.insert(new_lines, fargo_end_marker)
  end

  -- Write back to .ignore file
  vim.fn.writefile(new_lines, ignore_file)
end

function M.toggle_crate()
  local line = vim.api.nvim_win_get_cursor(state.win)[1]
  local crate_idx = line - 5 -- Account for header lines (3 header + 1 separator + 1 blank = 5)

  if crate_idx > 0 and crate_idx <= #state.crates then
    state.crates[crate_idx].visible = not state.crates[crate_idx].visible

    -- Update .ignore file to reflect visibility changes
    M.update_ignore_file()

    M.render_crates()
    vim.api.nvim_win_set_cursor(state.win, { line, 0 })
  end
end

function M.open_in_fff()
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
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
  state.buf = nil
end

function M.toggle()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    M.close()
  else
    M.create_window()
  end
end

function M.get_visible_crates()
  local visible = {}
  for _, crate in ipairs(state.crates) do
    if crate.visible then
      table.insert(visible, crate)
    end
  end
  return visible
end

return M
