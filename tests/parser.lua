-- Test script to debug the workspace crates parser
local test_cargo_toml = [[
[workspace]
members = [
  "crate1",
  "crate2",
  "crate3",
]

[workspace.dependencies]
serde = "1.0"
]]

print("Testing parser with sample Cargo.toml:")
print(test_cargo_toml)
print("\n--- Parsing ---")

-- Find [workspace] section
local workspace_section = test_cargo_toml:match("%[workspace%](.-)%[")
if not workspace_section then
	workspace_section = test_cargo_toml:match("%[workspace%](.*)")
end

print("Workspace section found:", workspace_section ~= nil)
if workspace_section then
	print("Section content:")
	print(workspace_section)
	print("\n--- Extracting members ---")

	local members_content = workspace_section:match("members%s*=%s*%[(.-)%]")
	print("Members content:", members_content)

	if members_content then
		print("\n--- Found crates ---")
		for crate_name in members_content:gmatch('"([^"]+)"') do
			print("  - " .. crate_name)
		end
	end
end

-- Now test with actual Cargo.toml if it exists
print("\n\n=== Testing with actual Cargo.toml ===")
local cwd = vim.fn.getcwd()
local cargo_toml = cwd .. "/Cargo.toml"
print("Looking for: " .. cargo_toml)
print("File readable:", vim.fn.filereadable(cargo_toml) == 1)

if vim.fn.filereadable(cargo_toml) == 1 then
	local content = table.concat(vim.fn.readfile(cargo_toml), "\n")
	print("\nActual Cargo.toml content:")
	print(content)

	print("\n--- Parsing actual file ---")
	workspace_section = content:match("%[workspace%](.-)%[")
	if not workspace_section then
		workspace_section = content:match("%[workspace%](.*)")
	end

	if workspace_section then
		print("Workspace section found!")
		local members_content = workspace_section:match("members%s*=%s*%[(.-)%]")
		if members_content then
			print("Members found:")
			for crate_name in members_content:gmatch('"([^"]+)"') do
				print("  - " .. crate_name)
			end
		else
			print("No members array found in workspace section")
		end
	else
		print("No [workspace] section found")
	end
else
	print("No Cargo.toml found in current directory")
end
