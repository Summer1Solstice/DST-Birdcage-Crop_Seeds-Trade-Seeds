-- 嚎弹炮可装填蜂刺
AddPrefabPostInit("stinger", function(inst) -- 给蜂刺添加tag
    inst:AddTag("blowpipeammo")
    inst:AddTag("reloaditem_ammo") -- Action string.
end)
-- 攻击距离修改
-- 修改嚎弹炮攻击距离的全局变量
local houndstooth_blowpipe_key = { "HOUNDSTOOTH_BLOWPIPE_ATTACK_DIST", "HOUNDSTOOTH_BLOWPIPE_ATTACK_DIST_MAX" }
local add_number = 0
if add_number ~= 0 then
    for _, tuning_name in pairs(houndstooth_blowpipe_key) do
        GLOBAL.TUNING[tuning_name] = GLOBAL.TUNING[tuning_name] + add_number
    end
end
