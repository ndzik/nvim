"" I did not find another way to achieve this, yet. Hopefully I will be able
"" clean this up sometime in the future.

command! -nargs=1 WildIgnore :lua require("plugins.telescope.common").set_ignore_pattern(<f-args>)
