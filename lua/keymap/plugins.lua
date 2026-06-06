local utils = require("utils")

utils.map('n', '<leader>ho', '<cmd>Hoogle<cr>')

-- Pi active-chat socket integration.
utils.map('n', '<leader>pa', '<cmd>PiSinkAsk<cr>', { silent = true })
utils.map('x', '<leader>pa', ':<C-u>PiSinkAskSelection<cr>', { silent = true })
utils.map('n', '<leader>pA', '<cmd>PiSinkAskDiagnostics<cr>', { silent = true })
utils.map('x', '<leader>pA', ':<C-u>PiSinkAskSelectionDiagnostics<cr>', { silent = true })
utils.map('n', '<leader>pp', '<cmd>PiSinkAttach<cr>', { silent = true })
utils.map('n', '<leader>pl', '<cmd>PiSinkList<cr>', { silent = true })
