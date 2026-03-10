-- ~~/lua/fargo/utilities.lua --

local M = {}

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

function M.update_ignore_file(crates)
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
  for _, crate in ipairs(crates) do
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

return M
