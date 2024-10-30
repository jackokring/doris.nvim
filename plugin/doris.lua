-- plugin loader or initializer
-- turns interface into instance
vim.api.nvim_create_user_command("Doris", require("doris").doris, {})
