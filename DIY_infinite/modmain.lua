-- 无限耐久
local function infiniteMod(inst)
    local self1 = inst.components.finiteuses
    if self1 then
        function self1:Use(num) return true end

        print("infiniteMod: ", inst.prefab)
    end
end
-- 创建一个数组
local infiniteItems = { "greenstaff" }
-- 遍历数组
for i = 1, #infiniteItems do
    AddPrefabPostInit(infiniteItems[i], infiniteMod)
end
