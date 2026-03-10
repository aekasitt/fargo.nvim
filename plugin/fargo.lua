-- ~~/plugin/fargo.lua --

if vim.g.loaded_fargo then
	return
end
vim.g.loaded_fargo = true

vim.api.nvim_create_user_command("FargoToggle", function()
	require("fargo").toggle()
end, {})
