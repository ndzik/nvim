local utils = require("utils")

utils.map('n', '<leader>dd', '<cmd>call vimspector#Launch()<cr>')
utils.map('n', '<leader>de', '<cmd>call vimspector#Reset()<cr>')

utils.map('n', '<leader>db', '<cmd>call vimspector#ToggleBreakpoint()<cr>')

utils.map('n', '<leader>dl', '<cmd>call vimspector#StepInto()<cr>')
utils.map('n', '<leader>dj', '<cmd>call vimspector#StepOver()<cr>')
utils.map('n', '<leader>dk', '<cmd>call vimspector#StepOut()<cr>')
utils.map('n', '<leader>dr', '<cmd>call vimspector#Restart()<cr>')
utils.map('n', '<leader>dc', '<cmd>call vimspector#Continue()<cr>')
utils.map('n', '<leader>drc', '<cmd>call vimspector#RunToCursor()<cr>')
