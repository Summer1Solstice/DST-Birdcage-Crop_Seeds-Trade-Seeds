local invalid_foods =
{
    "bird_egg",
    "bird_egg_cooked",
    "rottenegg",
    -- "monstermeat",
    -- "cookedmonstermeat",
    -- "monstermeat_dried",
}

-- 获取鸟笼中的鸟
local function GetBird(inst)
    return (inst.components.occupiable and inst.components.occupiable:GetOccupant()) or nil
end

-- 只用于点击和空闲动画的状态推动动画函数
local function PushStateAnim(inst, anim, loop)
    inst.AnimState:PushAnimation(anim..inst.CAGE_STATE, loop)
end

-- 判断鸟笼是否应该接受某个物品（用于交易系统）
local function ShouldAcceptItemMod(inst, item)
    -- 构造种子名称，基于物品prefab加"_seeds"后缀
    local seed_name = string.lower(item.prefab .. "_seeds")

    -- 判断是否可以接受该物品：物品必须是可食用的，并且满足以下条件之一：
    -- 1. 存在对应名称的种子预制件
    -- 2. 物品本身就是种子
    -- 3. 物品名称包含"_seeds"后缀
    -- 4. 物品是肉类食物
    local can_accept = item.components.edible
        and (GLOBAL.Prefabs[seed_name]
            or item.prefab == "seeds"
            or string.match(item.prefab, "_seeds")
            or item.components.edible.foodtype ==  GLOBAL.FOODTYPE.MEAT)

    -- 如果物品在无效食物列表中，则不能接受
    if table.contains(invalid_foods, item.prefab) then
        can_accept = false
    end

    return can_accept
end

-- 消化食物并产生相应产物的主逻辑函数
local function DigestFoodMod(inst, food)
    -- 判断食物类型是否为肉类
    if food.components.edible.foodtype == GLOBAL.FOODTYPE.MEAT then
        -- 如果食物是肉类：
        -- 检查鸟是否是变异鸟，如果是则生成腐烂蛋，否则生成普通鸟蛋
        if inst.components.occupiable and inst.components.occupiable:GetOccupant() and inst.components.occupiable:GetOccupant():HasTag("bird_mutant") then
            inst.components.lootdropper:SpawnLootPrefab("rottenegg")
        else
            inst.components.lootdropper:SpawnLootPrefab("bird_egg")
        end
    else
        -- 如果食物不是肉类：
        -- 检查鸟是否是变异鸟，如果是则生成变质食物，否则根据食物类型生成相应产物
        if inst.components.occupiable and inst.components.occupiable:GetOccupant() and inst.components.occupiable:GetOccupant():HasTag("bird_mutant") then
            inst.components.lootdropper:SpawnLootPrefab("spoiled_food")
        else
            -- 构造种子名称
            local seed_name = string.lower(food.prefab .. "_seeds")
            -- 如果存在对应名称的种子预制件，则生成该种子
            if GLOBAL.Prefabs[seed_name] ~= nil then
                inst.components.lootdropper:SpawnLootPrefab(seed_name)
            -- 如果食物本身已经是种子，则生成普通种子
            elseif string.match(food.prefab, "_seeds") then
                inst.components.lootdropper:SpawnLootPrefab("seeds")
            else
                -- 其他情况：
                -- 33%概率生成鸟粪
                if math.random() < 0.33 then
                    local loot = inst.components.lootdropper:SpawnLootPrefab("guano")
                    loot.Transform:SetScale(.33, .33, .33)
                end
            end
        end
    end

    -- 重新填充鸟的胃部（恢复腐烂进度为100%）
    local bird = GetBird(inst)
    if bird and bird:IsValid() and bird.components.perishable then
        bird.components.perishable:SetPercent(1)
    end
end

-- 当鸟笼获得物品时的处理逻辑
local function OnGetItemMod(inst, giver, item)
    -- 如果鸟笼正在睡眠，则唤醒它
    if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end

    -- 检查物品是否可食用，并且满足以下条件之一：
    -- 1. 是肉类食物
    -- 2. 是普通种子
    -- 3. 名称包含"_seeds"后缀
    -- 4. 存在对应名称的种子预制件
    if item.components.edible ~= nil and
        (   item.components.edible.foodtype == GLOBAL.FOODTYPE.MEAT
            or item.prefab == "seeds"
            or string.match(item.prefab, "_seeds")
            or GLOBAL.Prefabs[string.lower(item.prefab .. "_seeds")] ~= nil
        ) then
        -- 如果物品可食用...
        -- 播放动画序列（啄食、啄食、啄食、跳跃、空闲）
        inst.AnimState:PlayAnimation("peck")
        inst.AnimState:PushAnimation("peck")
        inst.AnimState:PushAnimation("peck")
        inst.AnimState:PushAnimation("hop")
        PushStateAnim(inst, "idle", true)
        -- 在60帧后执行消化食物的逻辑
        inst:DoTaskInTime(60 * GLOBAL.FRAMES, DigestFoodMod, item)
    end
end

-- 鸟笼预设初始化后的注入函数
function birdcagePrefabPostInit(inst)
    -- 如果实例存在并且具有交易组件，则设置自定义的接受物品逻辑
    if inst and inst.components.trader then
        inst.components.trader.onaccept = OnGetItemMod
        inst.components.trader:SetAcceptTest(ShouldAcceptItemMod)
    end
end

-- 添加预制件后初始化钩子
AddPrefabPostInit("birdcage", birdcagePrefabPostInit)