-- 获取物品的edible组件
local function GetItemEdible(item)
    return item.components.edible;
end

-- 判断物品是否可食用
local function IsEdible(item)
    return GetItemEdible(item) ~= nil
end

-- 获取鸟笼中的鸟
local function GetBird(inst)
    return (inst.components.occupiable and inst.components.occupiable:GetOccupant()) or nil
end

-- 判断鸟是否为变异鸟
local function IsMutantBird(inst)
    local bird = GetBird(inst)
    if bird == nil then
        return false
    end
    return bird:HasTag("bird_mutant")
end

-- 判断物品是否为种子类型
local function IsSeeds(item)
    if string.match(item.prefab, "_seeds") then
        return 1
    end
    if string.match(item.prefab, "seeds") then
        return 2
    end
end

-- 日志输出函数（目前被注释掉了）
local function Logging(str)
    --TheNet:Announce(str)
end

-- 定义不同生物的特殊状态映射表
local lootStateMap =
{
    rabbit = "stunned",
    bee = "catchbreath",
    mole = "stunned"
}
-- 判断食物是否为肉类
local function IsMeat(item)
    if (IsEdible(item) == false) then
        return false
    end
    local edible = GetItemEdible(item)
    return edible.foodtype == GLOBAL.FOODTYPE.MEAT
end

-- 判断鸟笼是否应该接受某个物品（用于交易系统）
local function ShouldAcceptItemMod(inst, item)
    if IsMeat(item) then
        return true
    elseif IsSeeds(item) then
        return true
    else
        local seed_name = string.lower(item.prefab .. "_seeds")
        if GLOBAL.Prefabs[seed_name] ~= nil then
            return true
        end
        return false
    end
end

-- 生成战利品的函数
local function SpwanLoot(inst, item, num)
    --Logging("start SpwanLoot")
    local inum = 0
    if num == nil then
        inum = 1
    else
        inum = num
    end

    if inum < 1 then
        return
    end
    Logging("SpwanLoot:" .. item .. "X" .. inum)
    local gotoState = lootStateMap[item]
    if gotoState ~= nil then
        Logging("SpwanLoot:" .. item .. "->" .. gotoState)
    end
    for i = 1, inum do
        local loot = inst.components.lootdropper:SpawnLootPrefab(item)
        if gotoState ~= nil then
            loot.sg:GoToState(gotoState)
            local ivtItem = loot.components.inventoryitem
            if ivtItem and ivtItem.canbepickedup == false then
                ivtItem.canbepickedup = true
            end
        end
    end
end

-- 消化食物并产生相应产物的主逻辑函数
local function DigestFoodMod(inst, food)
    if IsMeat(food) then
        --如果食物是肉类:
        --生成蛋类。
        if IsMutantBird(inst) then
            SpwanLoot(inst, "rottenegg")
        else
            SpwanLoot(inst, "bird_egg")
        end
    else
        if IsMutantBird(inst) then
            SpwanLoot(inst, "spoiled_food")
        else
            local seed_name = string.lower(food.prefab .. "_seeds")
            if GLOBAL.Prefabs[seed_name] ~= nil then
                SpwanLoot(inst, seed_name)
            elseif IsSeeds(food) == 1 then
                SpwanLoot(inst, "seeds")
            else
                --否则...
                --有1/3概率生成粪便。
                if math.random() < 0.33 then
                    SpwanLoot(inst, "guano")
                end
            end
        end
    end
    --Refill bird stomach.
    local bird = GetBird(inst)
    if bird and bird:IsValid() and bird.components.perishable then
        bird.components.perishable:SetPercent(1)
    end
end

-- 播放动画状态的辅助函数
local function PushStateAnim(inst, anim, loop)
    inst.AnimState:PushAnimation(anim .. inst.CAGE_STATE, loop)
end

-- 当鸟笼获得物品时的处理逻辑
local function OnGetItemMod(inst, giver, item)
    -- 如果鸟在睡觉则唤醒它
    if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end

    -- 如果接受该物品，则播放动画并处理消化逻辑
    if ShouldAcceptItemMod(inst, item) then
        inst.AnimState:PlayAnimation("peck")
        inst.AnimState:PushAnimation("peck")
        inst.AnimState:PushAnimation("peck")
        inst.AnimState:PushAnimation("hop")
        PushStateAnim(inst, "idle", true)

        -- 延迟执行消化食物的逻辑
        inst:DoTaskInTime(60 * GLOBAL.FRAMES, DigestFoodMod, item)
    end
end

-- 鸟笼预设初始化后的注入函数
function birdcagePrefabPostInit(inst)
    if inst and inst.components.trader then
        inst.components.trader.onaccept = OnGetItemMod
        inst.components.trader:SetAcceptTest(ShouldAcceptItemMod)
    end
end

-- 添加预制件后初始化钩子
AddPrefabPostInit("birdcage", birdcagePrefabPostInit)
