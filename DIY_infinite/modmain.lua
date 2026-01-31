-- 无限耐久模块函数，用于使物品获得无限使用的特性
local function infiniteMod(inst)
    local self1 = inst.components.finiteuses --耐久组件（有限使用次数）
    local self2 = inst.components.fueled     --燃料组件（需要燃料的物品）
    local self = inst.components.armor       --护甲组件（装备的耐久度）
    local self3 = inst.components.perishable --腐烂组件（会腐败的物品）

    -- 如果物品会腐烂，则将其剩余腐烂时间重置为最大腐烂时间
    if self3 then self3.perishremainingtime = self3.perishtime end --重置腐烂时间

    -- 处理有限使用次数的物品组件
    if self1 then
        -- 重写Use方法，使其总是返回true，表示使用成功但不消耗耐久
        function self1:Use(num) return true end

        -- 重写SetConsumption方法，将各种行为的消耗量设为0
        function self1:SetConsumption(action, uses) self1[action] = 0 end

        -- 如果总使用次数小于5次，则将其设置为10次（防止一次性物品也被修改）
        if self1.total < 5 then self1.total = 10 end
        -- 将当前使用次数恢复到最大值
        self1:SetUses(self1.total)
    end

    -- 处理需要燃料的物品组件
    if self2 then
        -- 将燃料量初始化为最大值
        self2:InitializeFuelLevel(self2.maxfuel)
        -- 重写StartConsuming方法，使其不开始消耗燃料
        function self2:StartConsuming() return true end

        -- 重写DoDelta方法，阻止燃料的增减
        function self2:DoDelta(amount, doer) return true end
    end

    -- 处理护甲组件
    if self then
        -- 重写SetCondition方法，使装备变为不可摧毁状态
        function self:SetCondition(amount) self:InitIndestructible(self.absorb_percent) end

        -- 将装备的当前耐久度设置为最大值
        self.condition = self.maxcondition
    end

    -- 处理腐烂组件
    if self3 then
        -- 停止腐烂过程
        self3:StopPerishing()
        -- 将本地腐烂倍数设为0，进一步防止腐烂
        self3.localPerishMultiplyer = 0
    end

    -- 如果物品是武器组件，将其攻击磨损设为0
    if inst.components.weapon then inst.components.weapon.attackwear = 0 end

    -- 特殊处理带有"zidingyifire"标签的自定义火源物品
    if inst:HasTag("zidingyifire") and inst.components.fueled then
        -- 将燃料消耗速率设为0
        inst.components.fueled.rate = 0
        -- 设置添加燃料的回调函数
        inst.components.fueled:SetTakeFuelFn(function(inst)
            -- 确保燃烧状态为false
            inst.components.burnable.burning = false
            -- 播放添加燃料的音效
            inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
            -- 重新点燃物品
            inst.components.burnable:Ignite(nil, nil, doer)
            -- 设置燃烧特效等级
            inst.components.burnable:SetFXLevel(5, 1)
            -- 将燃料百分比重置为100%
            inst.components.fueled:SetPercent(1)
        end)
        -- 设置燃料阶段变化的回调函数
        inst.components.fueled:SetSectionCallback(function()
            -- 如果正在燃烧，则保持燃料为100%
            if inst.components.burnable.burning then
                inst.components.fueled:SetPercent(1)
            end
        end)
    end

    -- 如果物品没有"hide_percentage"标签，则添加该标签（用于隐藏耐久百分比显示）
    if not inst:HasTag("hide_percentage") then inst:AddTag("hide_percentage") end
end

-- 定义需要应用无限耐久效果的物品列表
-- 不要添加"bedroll_straw"、"reviver"
local infiniteItems = { "greenstaff", "saltlick_improved" }

-- 遍历物品列表，为每个物品添加无限耐久的后初始化处理
for i = 1, #infiniteItems do
    AddPrefabPostInit(infiniteItems[i], infiniteMod)
end
