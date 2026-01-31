local cooking = require "cooking"
local recipes = cooking.recipes.cookpot
--蒸树枝配方修复
recipes.beefalofeed.test = function(cooker, names, tags) return names.twigs and names.twigs >= 4 end
