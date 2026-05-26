local utils = require("utils")

require("diffview").setup({})

utils.map("n", "<leader>ö", "<cmd>DiffviewOpen<CR>")
