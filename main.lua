--[[
Runebound Frontier (LÖVE2D)
A complete single-file action/turn-based RPG with procedural visuals (no sprites).

Controls
- Title: Enter (new game), L (load)
- World: WASD/Arrows move, E interact, Tab / I menu, M map tab shortcut, J journal tab shortcut
- Menu/Dialog/Battle: Arrows navigate, Enter confirm, Backspace/Esc back
- World quick: F5 save, F9 load

Everything is drawn with primitives and text.
]]

local lg = love.graphics
local lk = love.keyboard
local floor = math.floor
local min, max = math.min, math.max
local abs = math.abs
local sqrt = math.sqrt
local sin, cos = math.sin, math.cos
local random = love.math.random

local GAME = {
    scene = "title", -- title, world, battle, gameover
    titleIndex = 1,
    time = 0,
    fonts = {},
    cam = {x = 0, y = 0},
    msg = nil,
    msgTimer = 0,
    shake = 0,
    seed = 0,
}

local COLORS = {
    text = {0.95, 0.96, 1.0},
    dim = {0.65, 0.68, 0.74},
    panel = {0.08, 0.09, 0.12, 0.92},
    panel2 = {0.12, 0.13, 0.17, 0.95},
    good = {0.35, 0.88, 0.45},
    bad = {0.92, 0.28, 0.28},
    warn = {0.95, 0.76, 0.25},
    mana = {0.26, 0.65, 0.95},
    xp = {0.75, 0.3, 0.95},
    gold = {0.95, 0.85, 0.25},
    shadow = {0, 0, 0, 0.35},
}

local BIOMES = {
    meadow = {name = "Meadow", ground = {0.20, 0.55, 0.20}, detail = {0.12, 0.40, 0.12}, water = {0.16, 0.35, 0.65}},
    forest = {name = "Forest", ground = {0.12, 0.40, 0.16}, detail = {0.07, 0.25, 0.10}, water = {0.10, 0.28, 0.55}},
    ember  = {name = "Ember Wastes", ground = {0.42, 0.23, 0.10}, detail = {0.25, 0.12, 0.05}, water = {0.35, 0.15, 0.10}},
    crystal= {name = "Crystal Fields", ground = {0.18, 0.24, 0.38}, detail = {0.12, 0.16, 0.28}, water = {0.12, 0.20, 0.45}},
    town   = {name = "Hearthhome", ground = {0.34, 0.31, 0.22}, detail = {0.22, 0.20, 0.14}, water = {0.18, 0.32, 0.52}},
}

local ITEMS = {
    potion = {name = "Potion", kind = "consumable", desc = "Restore 70 HP.", value = 20, use = {hp = 70}},
    hi_potion = {name = "Hi-Potion", kind = "consumable", desc = "Restore 160 HP.", value = 65, use = {hp = 160}},
    ether = {name = "Ether", kind = "consumable", desc = "Restore 40 MP.", value = 30, use = {mp = 40}},
    antidote = {name = "Antidote", kind = "consumable", desc = "Cure poison and burn.", value = 18, use = {cure = {"poison", "burn"}}},
    bomb = {name = "Bomb", kind = "consumable", desc = "Deals 80-110 damage in battle.", value = 40, use = {bomb = true}},

    herb = {name = "Herb", kind = "material", desc = "Healing herb. Crafting material.", value = 6},
    ore = {name = "Iron Ore", kind = "material", desc = "Metal ore. Crafting material.", value = 8},
    ember_shard = {name = "Ember Shard", kind = "material", desc = "Warm crystal from emberlands.", value = 12},
    crystal_dust = {name = "Crystal Dust", kind = "material", desc = "Arcane dust from crystal biome.", value = 12},
    fang = {name = "Beast Fang", kind = "material", desc = "Dropped by wild beasts.", value = 10},
    void_core = {name = "Void Core", kind = "quest", desc = "A core pulsing with unstable energy.", value = 0},
    forest_sigil = {name = "Forest Sigil", kind = "quest", desc = "Proof of clearing the Verdant Rift.", value = 0},
    ember_sigil = {name = "Ember Sigil", kind = "quest", desc = "Proof of clearing the Ember Rift.", value = 0},
    crystal_sigil = {name = "Crystal Sigil", kind = "quest", desc = "Proof of clearing the Crystal Rift.", value = 0},
}

local EQUIPMENT = {
    bronze_sword = {name = "Bronze Sword", slot = "weapon", atk = 5, mag = 0, def = 0, spd = 0, value = 35, desc = "Reliable starter blade."},
    ranger_blade = {name = "Ranger Blade", slot = "weapon", atk = 8, mag = 1, def = 0, spd = 1, value = 80, desc = "Balanced weapon."},
    ember_blade = {name = "Ember Blade", slot = "weapon", atk = 12, mag = 3, def = 0, spd = 0, value = 150, desc = "Forged from ember shards."},
    crystal_rod = {name = "Crystal Rod", slot = "weapon", atk = 3, mag = 11, def = 0, spd = 1, value = 160, desc = "Amplifies arcane power."},
    void_edge = {name = "Void Edge", slot = "weapon", atk = 16, mag = 6, def = 0, spd = 2, value = 0, desc = "A blade born in the final rift."},

    leather_armor = {name = "Leather Armor", slot = "armor", atk = 0, mag = 0, def = 4, spd = 1, value = 40, desc = "Light protective gear."},
    chain_mail = {name = "Chain Mail", slot = "armor", atk = 0, mag = 0, def = 8, spd = -1, value = 90, desc = "Solid defense."},
    ember_plate = {name = "Ember Plate", slot = "armor", atk = 1, mag = 0, def = 12, spd = -1, value = 170, desc = "Heat-resistant heavy armor."},
    crystal_cloak = {name = "Crystal Cloak", slot = "armor", atk = 0, mag = 5, def = 7, spd = 2, value = 170, desc = "Runed arcane cloak."},

    copper_ring = {name = "Copper Ring", slot = "charm", atk = 2, mag = 0, def = 1, spd = 0, value = 35, desc = "Simple charm."},
    hunter_charm = {name = "Hunter Charm", slot = "charm", atk = 2, mag = 0, def = 0, spd = 2, value = 75, desc = "Improves speed."},
    sage_charm = {name = "Sage Charm", slot = "charm", atk = 0, mag = 4, def = 0, spd = 0, value = 85, desc = "Boosts spellcraft."},
    guard_emblem = {name = "Guard Emblem", slot = "charm", atk = 0, mag = 0, def = 4, spd = 0, value = 85, desc = "Defensive emblem."},
}

local SKILLS = {
    slash = {name = "Power Slash", cost = 6, kind = "damage", power = 1.55, scale = "atk", target = "enemy", desc = "Heavy physical strike."},
    firebolt = {name = "Firebolt", cost = 8, kind = "magic", power = 1.45, scale = "mag", target = "enemy", element = "fire", burn = 0.35, desc = "Magic fire attack; may burn."},
    heal = {name = "Heal", cost = 8, kind = "heal", power = 1.35, scale = "mag", target = "self", desc = "Restore HP."},
    poison_dart = {name = "Poison Dart", cost = 9, kind = "damage", power = 1.05, scale = "atk", target = "enemy", poison = 0.75, desc = "Weak hit, high poison chance."},
    guardbreak = {name = "Guard Break", cost = 10, kind = "damage", power = 1.15, scale = "atk", target = "enemy", shred = 0.20, desc = "Reduces enemy defense."},
    arc_burst = {name = "Arc Burst", cost = 16, kind = "magic_aoe", power = 1.05, scale = "mag", target = "all_enemies", desc = "Arcane damage to all enemies."},
    meditate = {name = "Meditate", cost = 0, kind = "utility", target = "self", desc = "Restore MP and gain regen."},
    stun_blow = {name = "Stun Blow", cost = 12, kind = "damage", power = 1.20, scale = "atk", target = "enemy", stun = 0.45, desc = "May stun target."},
}

local ENEMIES = {
    slime = {name = "Moss Slime", shape = "blob", hp = 52, mp = 10, atk = 9, def = 4, mag = 4, spd = 7, xp = 16, gold = 9,
        loot = { {"herb", 0.55, 1, 2}, {"potion", 0.18, 1, 1} }, biome = "meadow"},
    wolf = {name = "Grey Wolf", shape = "wolf", hp = 60, mp = 0, atk = 12, def = 5, mag = 0, spd = 12, xp = 18, gold = 10,
        loot = { {"fang", 0.55, 1, 2}, {"herb", 0.25, 1, 1} }, biome = "meadow"},
    bandit = {name = "Road Bandit", shape = "humanoid", hp = 74, mp = 10, atk = 14, def = 7, mag = 4, spd = 10, xp = 24, gold = 16,
        loot = { {"ore", 0.4, 1, 2}, {"ether", 0.12, 1, 1} }, biome = "forest"},
    treant = {name = "Rift Treant", shape = "treant", hp = 240, mp = 40, atk = 18, def = 10, mag = 10, spd = 7, xp = 140, gold = 85,
        loot = { {"forest_sigil", 1.0, 1, 1}, {"hi_potion", 0.65, 1, 2}, {"ranger_blade", 0.15, 1, 1} }, boss = true, biome = "forest"},
    salamander = {name = "Cinder Lizard", shape = "lizard", hp = 88, mp = 14, atk = 16, def = 8, mag = 6, spd = 11, xp = 30, gold = 18,
        loot = { {"ember_shard", 0.65, 1, 2}, {"fang", 0.2, 1, 1} }, biome = "ember"},
    golem = {name = "Ash Golem", shape = "golem", hp = 115, mp = 0, atk = 18, def = 13, mag = 0, spd = 5, xp = 40, gold = 22,
        loot = { {"ore", 0.55, 1, 3}, {"ember_shard", 0.35, 1, 2} }, biome = "ember"},
    magma_beast = {name = "Magma Beast", shape = "beast", hp = 320, mp = 30, atk = 24, def = 14, mag = 14, spd = 8, xp = 220, gold = 130,
        loot = { {"ember_sigil", 1.0, 1, 1}, {"ember_plate", 0.25, 1, 1}, {"ember_blade", 0.20, 1, 1} }, boss = true, biome = "ember"},
    wisp = {name = "Crystal Wisp", shape = "wisp", hp = 82, mp = 24, atk = 10, def = 6, mag = 15, spd = 14, xp = 32, gold = 18,
        loot = { {"crystal_dust", 0.65, 1, 2}, {"ether", 0.25, 1, 1} }, biome = "crystal"},
    shardling = {name = "Shardling", shape = "shard", hp = 95, mp = 8, atk = 17, def = 10, mag = 5, spd = 9, xp = 34, gold = 20,
        loot = { {"crystal_dust", 0.4, 1, 2}, {"ore", 0.3, 1, 2} }, biome = "crystal"},
    crystal_lord = {name = "Crystal Lord", shape = "lord", hp = 360, mp = 70, atk = 20, def = 12, mag = 23, spd = 11, xp = 260, gold = 150,
        loot = { {"crystal_sigil", 1.0, 1, 1}, {"crystal_cloak", 0.25, 1, 1}, {"crystal_rod", 0.25, 1, 1} }, boss = true, biome = "crystal"},
    void_knight = {name = "Void Knight", shape = "knight", hp = 520, mp = 80, atk = 29, def = 16, mag = 24, spd = 14, xp = 500, gold = 420,
        loot = { {"void_core", 1.0, 1, 1}, {"void_edge", 1.0, 1, 1} }, boss = true, biome = "crystal"},
}

local RECIPES = {
    {id = "potion", name = "Brew Potion", out = {potion = 1}, req = {herb = 2}},
    {id = "hi_potion", name = "Brew Hi-Potion", out = {hi_potion = 1}, req = {potion = 2, herb = 2}},
    {id = "ether", name = "Distill Ether", out = {ether = 1}, req = {crystal_dust = 2, herb = 1}},
    {id = "bomb", name = "Forge Bomb", out = {bomb = 1}, req = {ore = 1, ember_shard = 2}},
    {id = "ranger_blade", name = "Forge Ranger Blade", out = {ranger_blade = 1}, req = {ore = 4, fang = 2}},
    {id = "chain_mail", name = "Forge Chain Mail", out = {chain_mail = 1}, req = {ore = 6}},
    {id = "hunter_charm", name = "Craft Hunter Charm", out = {hunter_charm = 1}, req = {fang = 4, ore = 2}},
    {id = "sage_charm", name = "Craft Sage Charm", out = {sage_charm = 1}, req = {crystal_dust = 4, herb = 2}},
}

local function deepcopy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[deepcopy(k)] = deepcopy(v) end
    return out
end

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

local function dist(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return sqrt(dx * dx + dy * dy)
end

local function chance(p)
    return random() < p
end

local function pick(list)
    return list[random(1, #list)]
end

local function serialize(v, indent)
    indent = indent or 0
    local t = type(v)
    if t == "number" or t == "boolean" then
        return tostring(v)
    elseif t == "string" then
        return string.format("%q", v)
    elseif t == "table" then
        local pad = string.rep(" ", indent)
        local pad2 = string.rep(" ", indent + 2)
        local parts = {"{"}
        for k, val in pairs(v) do
            local key
            if type(k) == "string" and k:match("^[_%a][_%w]*$") then
                key = k
            else
                key = "[" .. serialize(k, indent + 2) .. "]"
            end
            table.insert(parts, "\n" .. pad2 .. key .. "=" .. serialize(val, indent + 2) .. ",")
        end
        if #parts > 1 then table.insert(parts, "\n" .. pad) end
        table.insert(parts, "}")
        return table.concat(parts)
    else
        return "nil"
    end
end

local function notify(text)
    GAME.msg = text
    GAME.msgTimer = 2.6
end

local function newPlayer()
    return {
        x = 36 * 24 + 12,
        y = 36 * 24 + 12,
        r = 10,
        speed = 118,
        dirx = 0, diry = 1,

        name = "Warden",
        level = 1,
        xp = 0,
        xpToNext = 65,
        gold = 40,
        hp = 110,
        mp = 30,
        base = {maxhp = 110, maxmp = 30, atk = 12, def = 8, mag = 8, spd = 10},
        bonus = {might = 0, mind = 0, agility = 0},
        statPoints = 0,

        equipment = {weapon = "bronze_sword", armor = "leather_armor", charm = "copper_ring"},
        gearOwned = {bronze_sword = 1, leather_armor = 1, copper_ring = 1},
        items = {
            potion = 5, ether = 2, antidote = 2,
            herb = 0, ore = 0, ember_shard = 0, crystal_dust = 0, fang = 0,
        },
        skills = {"slash", "firebolt", "heal"},
        flags = {metElder = false, wonGame = false},
        statuses = {}, -- overworld temporary buffs
        blessing = nil,
        killCounts = {},
        explored = {},
    }
end

local function calcPlayerStats(p)
    local s = {
        maxhp = p.base.maxhp + p.level * 8 + (p.bonus.might or 0) * 6,
        maxmp = p.base.maxmp + p.level * 3 + (p.bonus.mind or 0) * 5,
        atk = p.base.atk + p.level * 2 + (p.bonus.might or 0) * 2,
        def = p.base.def + p.level + (p.bonus.might or 0),
        mag = p.base.mag + p.level * 2 + (p.bonus.mind or 0) * 2,
        spd = p.base.spd + floor(p.level * 0.7) + (p.bonus.agility or 0) * 2,
    }
    for _, slot in pairs({"weapon", "armor", "charm"}) do
        local eqid = p.equipment[slot]
        local eq = eqid and EQUIPMENT[eqid]
        if eq then
            s.atk = s.atk + (eq.atk or 0)
            s.def = s.def + (eq.def or 0)
            s.mag = s.mag + (eq.mag or 0)
            s.spd = s.spd + (eq.spd or 0)
        end
    end
    if p.blessing and p.blessing.battlesLeft and p.blessing.battlesLeft > 0 then
        s.atk = s.atk + (p.blessing.atk or 0)
        s.mag = s.mag + (p.blessing.mag or 0)
        s.def = s.def + (p.blessing.def or 0)
        s.spd = s.spd + (p.blessing.spd or 0)
    end
    return s
end

local function gainItem(p, id, n)
    n = n or 1
    if ITEMS[id] then
        p.items[id] = (p.items[id] or 0) + n
    elseif EQUIPMENT[id] then
        p.gearOwned[id] = (p.gearOwned[id] or 0) + n
    end
end

local function spendItem(p, id, n)
    n = n or 1
    if ITEMS[id] then
        if (p.items[id] or 0) >= n then p.items[id] = p.items[id] - n return true end
    elseif EQUIPMENT[id] then
        if (p.gearOwned[id] or 0) >= n then p.gearOwned[id] = p.gearOwned[id] - n return true end
    end
    return false
end

local function playerHas(p, id, n)
    n = n or 1
    if ITEMS[id] then return (p.items[id] or 0) >= n end
    if EQUIPMENT[id] then return (p.gearOwned[id] or 0) >= n end
    return false
end

local function hasSkill(p, id)
    for _, s in ipairs(p.skills) do if s == id then return true end end
    return false
end

local function learnSkill(p, id)
    if not hasSkill(p, id) then table.insert(p.skills, id) notify("Learned " .. SKILLS[id].name .. "!") end
end

local function addXP(p, amount)
    p.xp = p.xp + amount
    local ding = false
    while p.xp >= p.xpToNext do
        p.xp = p.xp - p.xpToNext
        p.level = p.level + 1
        p.xpToNext = floor(p.xpToNext * 1.25 + 20)
        p.statPoints = p.statPoints + 2
        local st = calcPlayerStats(p)
        p.hp = st.maxhp
        p.mp = st.maxmp
        ding = true
        if p.level == 2 then learnSkill(p, "poison_dart") end
        if p.level == 3 then learnSkill(p, "guardbreak") end
        if p.level == 4 then learnSkill(p, "stun_blow") end
        if p.level == 5 then learnSkill(p, "meditate") end
        if p.level == 6 then learnSkill(p, "arc_burst") end
    end
    if ding then notify("Level Up! Lv." .. p.level .. " (+2 stat points)") end
end

local function biomeForTile(x, y, w, h)
    local cx, cy = w / 2, h / 2
    local townRect = {x = cx - 5, y = cy - 5, w = 10, h = 10}
    if x >= townRect.x and x < townRect.x + townRect.w and y >= townRect.y and y < townRect.y + townRect.h then
        return "town"
    end
    if x < cx and y < cy then return "meadow" end
    if x >= cx and y < cy then return "forest" end
    if x < cx and y >= cy then return "ember" end
    return "crystal"
end

local function newWorld(seed)
    local world = {
        w = 72,
        h = 72,
        tile = 24,
        seed = seed,
        tiles = {},
        npcs = {},
        objects = {}, -- chests, rifts, shrines
        resources = {},
        mobs = {},
        weather = {kind = "clear", timer = 35},
        dayTime = 0.15,
        defeatedRifts = {forest = false, ember = false, crystal = false, void = false},
        nextBountyId = 1,
    }

    local function noise(a, b, c)
        return love.math.noise((a + seed * 0.13) * c, (b + seed * 0.21) * c)
    end

    for y = 1, world.h do
        world.tiles[y] = {}
        for x = 1, world.w do
            local biome = biomeForTile(x, y, world.w, world.h)
            local n = noise(x, y, 0.09)
            local m = noise(x + 100, y - 40, 0.18)
            local blocked = false
            local water = false
            if biome ~= "town" then
                if biome == "meadow" then
                    blocked = n > 0.83 and m > 0.45
                    water = n < 0.14
                elseif biome == "forest" then
                    blocked = n > 0.74
                    water = n < 0.10 and m < 0.45
                elseif biome == "ember" then
                    blocked = n > 0.80
                    water = n < 0.08 -- lava pools visually treated as water-like hazard (blocked)
                    if water then blocked = true end
                elseif biome == "crystal" then
                    blocked = n > 0.78
                    water = n < 0.09
                end
            end
            local centerDist = dist(x, y, world.w / 2, world.h / 2)
            if centerDist < 8 then blocked = false water = false biome = biomeForTile(x, y, world.w, world.h) end
            world.tiles[y][x] = {biome = biome, blocked = blocked, water = water, decor = m}
        end
    end

    -- Town buildings and NPCs
    local tx, ty = floor(world.w / 2) - 5, floor(world.h / 2) - 5
    world.town = {
        x = tx, y = ty, w = 10, h = 10,
        buildings = {
            {name = "Elder Hall", x = tx + 1, y = ty + 1, w = 3, h = 2, doorx = tx + 2, doory = ty + 3, kind = "elder"},
            {name = "Trader", x = tx + 6, y = ty + 1, w = 3, h = 2, doorx = tx + 7, doory = ty + 3, kind = "merchant"},
            {name = "Forge", x = tx + 1, y = ty + 6, w = 3, h = 2, doorx = tx + 2, doory = ty + 5, kind = "smith"},
            {name = "Sanctum", x = tx + 6, y = ty + 6, w = 3, h = 2, doorx = tx + 7, doory = ty + 5, kind = "healer"},
        }
    }

    local function addNPC(id, name, role, x, y, color)
        table.insert(world.npcs, {id = id, name = name, role = role, x = x * world.tile + 12, y = y * world.tile + 12, r = 9, color = color, dir = 1})
    end

    addNPC("elder", "Elder Rowan", "elder", tx + 2, ty + 4, {0.90, 0.85, 0.45})
    addNPC("merchant", "Mira", "merchant", tx + 7, ty + 4, {0.40, 0.80, 0.95})
    addNPC("smith", "Doran", "smith", tx + 2, ty + 5, {0.90, 0.45, 0.30})
    addNPC("healer", "Sister Vale", "healer", tx + 7, ty + 5, {0.65, 0.95, 0.75})
    addNPC("hunter", "Kest", "hunter", tx + 4, ty + 8, {0.85, 0.70, 0.50})

    -- Rifts (boss gates)
    local riftDefs = {
        {id = "forest", biome = "forest", x = 56, y = 14, boss = "treant", label = "Verdant Rift"},
        {id = "ember", biome = "ember", x = 14, y = 57, boss = "magma_beast", label = "Ember Rift"},
        {id = "crystal", biome = "crystal", x = 59, y = 58, boss = "crystal_lord", label = "Crystal Rift"},
        {id = "void", biome = "crystal", x = 36, y = 11, boss = "void_knight", label = "Void Gate", hidden = true},
    }
    for _, r in ipairs(riftDefs) do
        table.insert(world.objects, {type = "rift", id = r.id, biome = r.biome, x = r.x * world.tile + 12, y = r.y * world.tile + 12, r = 14, boss = r.boss, label = r.label, cleared = false, hidden = r.hidden})
    end

    -- Shrines
    local shrines = {
        {id = "meadow_shrine", x = 16, y = 16, kind = "atk"},
        {id = "forest_shrine", x = 61, y = 20, kind = "mind"},
        {id = "ember_shrine", x = 18, y = 62, kind = "guard"},
        {id = "crystal_shrine", x = 63, y = 62, kind = "speed"},
    }
    for _, s in ipairs(shrines) do
        table.insert(world.objects, {type = "shrine", id = s.id, x = s.x * world.tile + 12, y = s.y * world.tile + 12, r = 12, shrineKind = s.kind, used = false})
    end

    -- Chests
    local chestSpots = {
        {10, 10}, {21, 29}, {63, 10}, {49, 26}, {9, 56}, {25, 63}, {58, 50}, {66, 64}, {34, 18},
    }
    for i, c in ipairs(chestSpots) do
        local lootTable = {
            {"potion", random(1, 2)}, {"ether", random(1, 2)}, {"ore", random(2, 4)}, {"herb", random(2, 4)},
            {"ember_shard", random(1, 3)}, {"crystal_dust", random(1, 3)},
        }
        local loot = pick(lootTable)
        table.insert(world.objects, {type = "chest", id = "chest" .. i, x = c[1] * world.tile + 12, y = c[2] * world.tile + 12, r = 10, opened = false, loot = loot})
    end

    -- Resource nodes
    for y = 4, world.h - 3 do
        for x = 4, world.w - 3 do
            local tile = world.tiles[y][x]
            if tile.biome ~= "town" and not tile.blocked and not tile.water then
                local n = noise(x + 130, y + 230, 0.25)
                if n > 0.86 then
                    local kind = (tile.biome == "meadow" or tile.biome == "forest") and "herb" or ((tile.biome == "ember") and "ember_shard" or "crystal_dust")
                    if chance(0.35) then kind = "ore" end
                    table.insert(world.resources, {x = x * world.tile + 12, y = y * world.tile + 12, r = 8, kind = kind, timer = 0, active = true})
                end
            end
        end
    end

    -- Mobs
    local biomePools = {
        meadow = {"slime", "wolf"},
        forest = {"bandit", "wolf", "slime"},
        ember = {"salamander", "golem"},
        crystal = {"wisp", "shardling"},
    }
    for i = 1, 70 do
        local x, y, tries = 0, 0, 0
        repeat
            x, y = random(2, world.w - 1), random(2, world.h - 1)
            tries = tries + 1
            local t = world.tiles[y][x]
            if tries > 100 then break end
            if t and t.biome ~= "town" and not t.blocked and not t.water and dist(x, y, world.w / 2, world.h / 2) > 11 then break end
        until false
        local biome = world.tiles[y][x].biome
        local pool = biomePools[biome]
        if pool then
            table.insert(world.mobs, {
                id = "mob" .. i,
                enemyId = pick(pool),
                x = x * world.tile + 12,
                y = y * world.tile + 12,
                r = 9,
                vx = 0, vy = 0,
                think = random() * 2,
                roam = {x = x * world.tile + 12, y = y * world.tile + 12},
                respawn = 0,
                alive = true,
            })
        end
    end

    return world
end

local function canWalk(world, px, py, radius)
    local ts = world.tile
    local samples = {
        {px - radius, py - radius}, {px + radius, py - radius}, {px - radius, py + radius}, {px + radius, py + radius},
        {px, py}, {px - radius, py}, {px + radius, py}, {px, py - radius}, {px, py + radius},
    }
    for _, s in ipairs(samples) do
        local tx = floor(s[1] / ts) + 1
        local ty = floor(s[2] / ts) + 1
        if tx < 1 or ty < 1 or tx > world.w or ty > world.h then return false end
        local tile = world.tiles[ty][tx]
        if tile.blocked or tile.water then return false end
    end

    -- Building walls
    for _, b in ipairs(world.town.buildings) do
        local rx, ry = b.x * ts, b.y * ts
        local rw, rh = b.w * ts, b.h * ts
        local doorx = b.doorx * ts
        local doory = b.doory * ts
        local inside = px + radius > rx and px - radius < rx + rw and py + radius > ry and py - radius < ry + rh
        if inside then
            -- allow doorway corridor
            local atDoor = px > doorx and px < doorx + ts and py > doory and py < doory + ts
            if not atDoor then return false end
        end
    end
    return true
end

local function questById(g, id)
    for _, q in ipairs(g.quests) do
        if q.id == id then return q end
    end
end

local function addQuest(g, q)
    if not questById(g, q.id) then
        table.insert(g.quests, q)
        notify("New Quest: " .. q.name)
    end
end

local function completeQuest(g, qid)
    local q = questById(g, qid)
    if not q or q.state == "done" then return end
    q.state = "done"
    local p = g.player
    if q.reward then
        if q.reward.xp then addXP(p, q.reward.xp) end
        if q.reward.gold then p.gold = p.gold + q.reward.gold end
        if q.reward.items then for id, n in pairs(q.reward.items) do gainItem(p, id, n) end end
        if q.reward.gear then for id, n in pairs(q.reward.gear) do gainItem(p, id, n) end end
    end
    notify("Quest Complete: " .. q.name)
end

local function ensureMainQuest(g)
    local p = g.player
    local q = questById(g, "main_rifts")
    if not q then
        addQuest(g, {
            id = "main_rifts",
            name = "Seal the Three Rifts",
            state = "active",
            type = "main",
            progress = {forest = false, ember = false, crystal = false},
            desc = "Defeat the bosses in the Verdant, Ember, and Crystal Rifts.",
            reward = {xp = 200, gold = 200},
        })
        p.flags.metElder = true
    end
end

local function unlockVoidGateIfReady(g)
    local q = questById(g, "main_rifts")
    if not q then return end
    if q.progress.forest and q.progress.ember and q.progress.crystal then
        if q.state ~= "done" then completeQuest(g, "main_rifts") end
        if not questById(g, "final_void") then
            addQuest(g, {
                id = "final_void",
                name = "The Void Gate",
                state = "active",
                type = "main",
                desc = "Elder Rowan revealed the hidden Void Gate. Defeat the Void Knight.",
                reward = {xp = 600, gold = 500},
            })
        end
        for _, o in ipairs(g.world.objects) do
            if o.type == "rift" and o.id == "void" then o.hidden = false end
        end
    end
end

local function createBounty(g)
    if questById(g, "bounty") and questById(g, "bounty").state ~= "done" then return end
    local opts = {
        {enemy = "wolf", count = random(3, 5), xp = 60, gold = 70},
        {enemy = "bandit", count = random(3, 4), xp = 90, gold = 95},
        {enemy = "salamander", count = random(3, 4), xp = 110, gold = 120},
        {enemy = "wisp", count = random(3, 4), xp = 120, gold = 130},
        {enemy = "golem", count = random(2, 3), xp = 130, gold = 140},
    }
    local o = pick(opts)
    addQuest(g, {
        id = "bounty",
        name = "Hunter's Bounty",
        state = "active",
        type = "side",
        enemy = o.enemy,
        count = o.count,
        progress = 0,
        desc = "Hunt " .. o.count .. " " .. ENEMIES[o.enemy].name .. "s for Kest.",
        reward = {xp = o.xp, gold = o.gold, items = {potion = 2}},
    })
end

local function trackKill(g, enemyId)
    local p = g.player
    p.killCounts[enemyId] = (p.killCounts[enemyId] or 0) + 1
    local b = questById(g, "bounty")
    if b and b.state == "active" and b.enemy == enemyId then
        b.progress = min(b.count, (b.progress or 0) + 1)
        if b.progress >= b.count then
            b.state = "ready"
            notify("Bounty ready to turn in")
        end
    end
end

local function makeGame(seed)
    local g = {
        seed = seed,
        world = newWorld(seed),
        player = newPlayer(),
        quests = {},
        menu = {open = false, tab = 1, cursor = 1, sub = nil, targetTab = nil},
        dialog = nil,
        battle = nil,
        particles = {},
        weatherFlash = 0,
        playTime = 0,
    }
    addQuest(g, {
        id = "intro",
        name = "Report to Elder Rowan",
        state = "active",
        type = "main",
        desc = "Speak to Elder Rowan in Hearthhome.",
        reward = {xp = 40, gold = 20, items = {herb = 2}},
    })
    return g
end

local function statColor(kind)
    if kind == "hp" then return COLORS.good end
    if kind == "mp" then return COLORS.mana end
    if kind == "xp" then return COLORS.xp end
    return COLORS.text
end

local function addParticle(g, p)
    table.insert(g.particles, p)
end

local function spawnBurst(g, x, y, kind)
    for i = 1, 10 do
        local a = random() * math.pi * 2
        local sp = random(20, 90)
        local c = kind == "heal" and {0.4, 1, 0.5, 1} or (kind == "mana" and {0.4, 0.7, 1, 1} or {1, 0.85, 0.35, 1})
        addParticle(g, {x = x, y = y, vx = cos(a) * sp, vy = sin(a) * sp, t = 0.4 + random() * 0.4, r = random(2, 4), color = c})
    end
end

local function addFloating(g, x, y, text, color)
    addParticle(g, {x = x, y = y, vy = -30, vx = random(-12, 12), t = 0.9, float = true, text = text, color = color or {1, 1, 1, 1}})
end

local function openDialog(g, title, body, options)
    g.dialog = {title = title, body = body, options = options or {{label = "OK", fn = function() end}}, cursor = 1}
end

local function closeDialog(g)
    g.dialog = nil
end

local function openMenu(g, tab)
    g.menu.open = true
    if tab then g.menu.tab = tab end
    g.menu.cursor = 1
    g.menu.sub = nil
end

local function closeMenu(g)
    g.menu.open = false
    g.menu.sub = nil
end

local function tileAt(world, px, py)
    local tx = floor(px / world.tile) + 1
    local ty = floor(py / world.tile) + 1
    if tx < 1 or ty < 1 or tx > world.w or ty > world.h then return nil end
    return world.tiles[ty][tx], tx, ty
end

local function nearestInteractable(g)
    local p, w = g.player, g.world
    local best, bestd = nil, 36
    local function scan(tbl)
        for _, o in ipairs(tbl) do
            if o.active == nil or o.active == true then
                if not o.hidden then
                    local d = dist(p.x, p.y, o.x, o.y)
                    if d < bestd then bestd = d; best = o end
                end
            end
        end
    end
    scan(w.npcs)
    scan(w.objects)
    scan(w.resources)
    return best
end

local function promptUseShrine(g, shrine)
    if shrine.used then
        notify("Shrine is dormant")
        return
    end
    local blessMap = {
        atk = {name = "Might Blessing", atk = 4, battlesLeft = 4},
        mind = {name = "Sage Blessing", mag = 4, battlesLeft = 4},
        guard = {name = "Guard Blessing", def = 5, battlesLeft = 4},
        speed = {name = "Swift Blessing", spd = 4, battlesLeft = 4},
    }
    local b = deepcopy(blessMap[shrine.shrineKind])
    openDialog(g, "Ancient Shrine", "Receive " .. b.name .. " for the next 4 battles?", {
        {label = "Accept", fn = function()
            g.player.blessing = b
            shrine.used = true
            spawnBurst(g, shrine.x, shrine.y, "mana")
            notify(b.name .. " granted")
            closeDialog(g)
        end},
        {label = "Leave", fn = function() closeDialog(g) end},
    })
end

local function doChest(g, chest)
    if chest.opened then notify("Chest is empty") return end
    chest.opened = true
    gainItem(g.player, chest.loot[1], chest.loot[2])
    notify("Found " .. chest.loot[2] .. "x " .. (ITEMS[chest.loot[1]] and ITEMS[chest.loot[1]].name or EQUIPMENT[chest.loot[1]].name))
    spawnBurst(g, chest.x, chest.y, "gold")
end

local function doGather(g, node)
    if not node.active then notify("Resource depleted") return end
    local amt = random(1, 2)
    node.active = false
    node.timer = 40 + random() * 40
    gainItem(g.player, node.kind, amt)
    notify("Gathered " .. amt .. "x " .. ITEMS[node.kind].name)
    spawnBurst(g, node.x, node.y, node.kind == "ore" and "gold" or "heal")
end

local function saveGame(g)
    if GAME.scene == "battle" then notify("Cannot save in battle") return end
    local data = {
        seed = g.seed,
        world = g.world,
        player = g.player,
        quests = g.quests,
        playTime = g.playTime,
    }
    local chunk = "return " .. serialize(data)
    love.filesystem.write("runebound_save.lua", chunk)
    notify("Game saved")
end

local function normalizeLoadedGame(g)
    g.menu = g.menu or {open = false, tab = 1, cursor = 1}
    g.dialog = nil
    g.battle = nil
    g.particles = {}
    g.weatherFlash = 0
    g.playTime = g.playTime or 0
    g.player.items = g.player.items or {}
    g.player.gearOwned = g.player.gearOwned or {}
    g.player.killCounts = g.player.killCounts or {}
    g.player.bonus = g.player.bonus or {might = 0, mind = 0, agility = 0}
    g.player.statPoints = g.player.statPoints or 0
    local st = calcPlayerStats(g.player)
    g.player.hp = clamp(g.player.hp or st.maxhp, 1, st.maxhp)
    g.player.mp = clamp(g.player.mp or st.maxmp, 0, st.maxmp)
    unlockVoidGateIfReady(g)
end

local function loadSavedGame()
    if not love.filesystem.getInfo("runebound_save.lua") then
        notify("No save file")
        return nil
    end
    local str = love.filesystem.read("runebound_save.lua")
    local fn = loadstring and loadstring(str) or load(str)
    if not fn then notify("Save load failed") return nil end
    local ok, data = pcall(fn)
    if not ok or type(data) ~= "table" then notify("Save corrupted") return nil end
    local g = {
        seed = data.seed,
        world = data.world,
        player = data.player,
        quests = data.quests or {},
        playTime = data.playTime or 0,
    }
    normalizeLoadedGame(g)
    return g
end

local function interactWithNPC(g, npc)
    local p = g.player
    if npc.role == "elder" then
        local intro = questById(g, "intro")
        if intro and intro.state ~= "done" then
            openDialog(g, npc.name,
                "The rifts are worsening. We need a Warden. Seal the three rifts and return to me with proof.",
                {
                    {label = "Accept duty", fn = function()
                        completeQuest(g, "intro")
                        ensureMainQuest(g)
                        closeDialog(g)
                    end},
                    {label = "Later", fn = function() closeDialog(g) end},
                }
            )
            return
        end
        local qMain = questById(g, "main_rifts")
        local qFinal = questById(g, "final_void")
        if qMain and qMain.state ~= "done" then
            local t = qMain.progress
            local body = string.format("Rift seals status:\n- Verdant: %s\n- Ember: %s\n- Crystal: %s", t.forest and "Cleared" or "Open", t.ember and "Cleared" or "Open", t.crystal and "Cleared" or "Open")
            openDialog(g, npc.name, body, {{label = "Understood", fn = function() closeDialog(g) end}})
            return
        end
        if qFinal and qFinal.state == "active" then
            openDialog(g, npc.name, "All three seals resonate. The hidden Void Gate has awakened north of town. End this.", {{label = "I will", fn = function() closeDialog(g) end}})
            return
        end
        if qFinal and qFinal.state == "done" then
            openDialog(g, npc.name, "The valley is stable again. You are now the Warden in full. Continue exploring and taking bounties.", {{label = "Thank you", fn = function() closeDialog(g) end}})
            return
        end
        openDialog(g, npc.name, "Keep gathering supplies. The wilds remain dangerous.", {{label = "OK", fn = function() closeDialog(g) end}})
        return
    elseif npc.role == "merchant" then
        local buyList = {
            {"potion", 20}, {"hi_potion", 65}, {"ether", 30}, {"antidote", 18}, {"bomb", 40},
            {"ranger_blade", 80}, {"chain_mail", 90}, {"hunter_charm", 75}, {"sage_charm", 85}, {"guard_emblem", 85},
        }
        local opts = {}
        for _, e in ipairs(buyList) do
            local id, price = e[1], e[2]
            local nm = ITEMS[id] and ITEMS[id].name or EQUIPMENT[id].name
            table.insert(opts, {label = "Buy " .. nm .. " (" .. price .. "g)", fn = function()
                if p.gold < price then notify("Not enough gold") return end
                p.gold = p.gold - price
                gainItem(p, id, 1)
                notify("Bought " .. nm)
            end})
        end
        table.insert(opts, {label = "Sell materials", fn = function()
            local total = 0
            for id, n in pairs(p.items) do
                if n > 0 and ITEMS[id] and ITEMS[id].kind == "material" then
                    local v = ITEMS[id].value or 1
                    total = total + v * n
                    p.items[id] = 0
                end
            end
            if total > 0 then p.gold = p.gold + total; notify("Sold materials for " .. total .. "g") else notify("No materials to sell") end
        end})
        table.insert(opts, {label = "Leave", fn = function() closeDialog(g) end})
        openDialog(g, npc.name, "Supplies, charms, and field gear.", opts)
        return
    elseif npc.role == "smith" then
        openDialog(g, npc.name, "I can refine ore and shards. Use the Craft tab in your menu while in town.", {
            {label = "Open Crafting", fn = function() closeDialog(g); openMenu(g, 5) end},
            {label = "Leave", fn = function() closeDialog(g) end},
        })
        return
    elseif npc.role == "healer" then
        openDialog(g, npc.name, "The Sanctum restores body and mind.", {
            {label = "Heal (25g)", fn = function()
                if p.gold < 25 then notify("Not enough gold") return end
                local st = calcPlayerStats(p)
                p.gold = p.gold - 25
                p.hp, p.mp = st.maxhp, st.maxmp
                spawnBurst(g, p.x, p.y, "heal")
                notify("Fully restored")
            end},
            {label = "Cleanse shrines", fn = function()
                for _, o in ipairs(g.world.objects) do if o.type == "shrine" then o.used = false end end
                notify("Ancient shrines resonate again")
            end},
            {label = "Leave", fn = function() closeDialog(g) end},
        })
        return
    elseif npc.role == "hunter" then
        local b = questById(g, "bounty")
        if b and b.state == "ready" then
            openDialog(g, npc.name, "Good work. Here is your bounty.", {
                {label = "Turn in", fn = function() completeQuest(g, "bounty"); createBounty(g); closeDialog(g) end},
                {label = "Later", fn = function() closeDialog(g) end},
            })
            return
        end
        if not b or b.state == "done" then createBounty(g) b = questById(g, "bounty") end
        if b then
            openDialog(g, npc.name,
                "Target: " .. ENEMIES[b.enemy].name .. "\nProgress: " .. (b.progress or 0) .. "/" .. b.count .. "\nReward: " .. (b.reward.gold or 0) .. "g + XP",
                {{label = "On it", fn = function() closeDialog(g) end}}
            )
        end
        return
    end
end

local function chooseRandomEncounter(world, biome, playerLv)
    local choices = {}
    for id, e in pairs(ENEMIES) do
        if e.biome == biome and not e.boss then table.insert(choices, id) end
    end
    if #choices == 0 then choices = {"slime"} end
    local count = 1
    if playerLv >= 3 and chance(0.45) then count = 2 end
    if playerLv >= 6 and chance(0.25) then count = 3 end
    local group = {}
    for i = 1, count do table.insert(group, {id = pick(choices), levelMod = random(-1, 2)}) end
    return group
end

local function battleEnemyFromDef(id, levelMod, playerLv)
    local d = ENEMIES[id]
    local lv = max(1, playerLv + (levelMod or 0))
    if d.boss then lv = max(playerLv + 1, playerLv) end
    local scale = 1 + (lv - 1) * 0.10
    local e = {
        id = id,
        name = d.name,
        shape = d.shape,
        maxhp = floor(d.hp * scale),
        hp = floor(d.hp * scale),
        mp = floor((d.mp or 0) * scale),
        maxmp = floor((d.mp or 0) * scale),
        atk = floor(d.atk * scale),
        def = floor(d.def * scale),
        mag = floor(d.mag * scale),
        spd = floor(d.spd * scale),
        xp = floor(d.xp * scale),
        gold = floor(d.gold * scale),
        loot = deepcopy(d.loot),
        boss = d.boss,
        status = {},
        temp = {defMul = 1.0},
        aiCooldown = 0,
        phase = 1,
    }
    return e
end

local function startBattle(g, enemyGroup, biome, opts)
    local p = g.player
    local pst = calcPlayerStats(p)
    local b = {
        biome = biome or "meadow",
        enemies = {},
        state = "command", -- command, skills, items, target, enemyAct, result
        cmdIndex = 1,
        skillIndex = 1,
        itemIndex = 1,
        targetIndex = 1,
        subAction = nil,
        log = {},
        floater = {},
        round = 1,
        queue = {},
        queueIndex = 1,
        canFlee = not (opts and opts.noFlee),
        boss = opts and opts.boss,
        source = opts and opts.source,
        postVictory = opts and opts.postVictory,
        p = {
            name = p.name,
            hp = clamp(p.hp, 1, pst.maxhp),
            mp = clamp(p.mp, 0, pst.maxmp),
            maxhp = pst.maxhp,
            maxmp = pst.maxmp,
            atk = pst.atk,
            def = pst.def,
            mag = pst.mag,
            spd = pst.spd,
            status = {},
            temp = {guard = false, defMul = 1.0},
        },
        anim = {t = 0},
    }
    for _, eg in ipairs(enemyGroup) do table.insert(b.enemies, battleEnemyFromDef(eg.id, eg.levelMod, p.level)) end
    table.insert(b.log, "Battle started")
    g.battle = b
    GAME.scene = "battle"

    -- Blessing consumption on battle start
    if p.blessing and p.blessing.battlesLeft and p.blessing.battlesLeft > 0 then
        p.blessing.battlesLeft = p.blessing.battlesLeft - 1
        if p.blessing.battlesLeft <= 0 then
            notify("Blessing faded")
            p.blessing = nil
        end
    end
end

local function livingEnemies(b)
    local t = {}
    for i, e in ipairs(b.enemies) do if e.hp > 0 then table.insert(t, i) end end
    return t
end

local function isBattleOver(b)
    if b.p.hp <= 0 then return "lose" end
    for _, e in ipairs(b.enemies) do if e.hp > 0 then return nil end end
    return "win"
end

local function addBattleLog(b, text)
    table.insert(b.log, 1, text)
    while #b.log > 8 do table.remove(b.log) end
end

local function statusTickUnit(u, who, b, g, isPlayer)
    local totalStartMsg = nil
    if u.status.poison and u.status.poison > 0 then
        u.status.poison = u.status.poison - 1
        local dmg = floor(max(4, u.maxhp * 0.06))
        u.hp = max(0, u.hp - dmg)
        addBattleLog(b, who .. " takes poison damage")
        addFloating(g, isPlayer and 160 or (460 + random(-20,20)), isPlayer and 245 or (140 + random(-20,20)), "-" .. dmg, {0.6, 1, 0.5, 1})
    end
    if u.status.burn and u.status.burn > 0 then
        u.status.burn = u.status.burn - 1
        local dmg = floor(max(5, u.maxhp * 0.07))
        u.hp = max(0, u.hp - dmg)
        addBattleLog(b, who .. " burns")
        addFloating(g, isPlayer and 160 or (460 + random(-20,20)), isPlayer and 245 or (140 + random(-20,20)), "-" .. dmg, {1, 0.45, 0.2, 1})
    end
    if u.status.regen and u.status.regen > 0 then
        u.status.regen = u.status.regen - 1
        local heal = floor(max(6, u.maxhp * 0.08))
        u.hp = min(u.maxhp, u.hp + heal)
        addBattleLog(b, who .. " regenerates")
        addFloating(g, isPlayer and 160 or (460 + random(-20,20)), isPlayer and 245 or (140 + random(-20,20)), "+" .. heal, {0.5, 1, 0.7, 1})
    end
    if u.status.stun and u.status.stun > 0 then
        -- consumed when actor attempts to act
    end
end

local function basicDamage(att, def, mult, magic)
    local attackStat = magic and att.mag or att.atk
    local defenseStat = max(1, def.def)
    local raw = attackStat * (mult or 1) * (0.9 + random() * 0.22) - defenseStat * 0.65
    if def.temp and def.temp.guard then raw = raw * 0.55 end
    raw = raw / ((def.temp and def.temp.defMul) or 1.0)
    local dmg = max(1, floor(raw))
    if chance(0.08 + (att.spd or 0) * 0.003) then dmg = floor(dmg * 1.5) end
    return dmg
end

local function usePlayerItemInBattle(g, b, itemId, targetIndex)
    local p = g.player
    local it = ITEMS[itemId]
    if not it or it.kind ~= "consumable" then return false end
    if (p.items[itemId] or 0) <= 0 then notify("Out of item") return false end
    p.items[itemId] = p.items[itemId] - 1
    if it.use.hp then
        local n = it.use.hp
        b.p.hp = min(b.p.maxhp, b.p.hp + n)
        addBattleLog(b, "You used " .. it.name)
        addFloating(g, 160, 245, "+" .. n, {0.4, 1, 0.4, 1})
    elseif it.use.mp then
        local n = it.use.mp
        b.p.mp = min(b.p.maxmp, b.p.mp + n)
        addBattleLog(b, "You restored MP")
        addFloating(g, 160, 245, "+" .. n .. " MP", {0.4, 0.75, 1, 1})
    elseif it.use.cure then
        for _, k in ipairs(it.use.cure) do b.p.status[k] = nil end
        addBattleLog(b, "Status cured")
    elseif it.use.bomb then
        local e = b.enemies[targetIndex]
        if e and e.hp > 0 then
            local dmg = random(80, 110)
            e.hp = max(0, e.hp - dmg)
            addBattleLog(b, "Bomb hits " .. e.name)
            addFloating(g, 500, 140 + targetIndex * 70, "-" .. dmg, {1, 0.75, 0.3, 1})
        end
    end
    return true
end

local function playerSkillCast(g, b, skillId, targetIndex)
    local sk = SKILLS[skillId]
    if not sk then return false end
    if b.p.mp < sk.cost then notify("Not enough MP") return false end
    b.p.mp = b.p.mp - sk.cost
    local uname = sk.name

    if sk.kind == "damage" or sk.kind == "magic" then
        local e = b.enemies[targetIndex]
        if not e or e.hp <= 0 then return false end
        local dmg = basicDamage(b.p, e, sk.power, sk.kind == "magic")
        e.hp = max(0, e.hp - dmg)
        addBattleLog(b, "You used " .. uname)
        addFloating(g, 500, 140 + targetIndex * 70, "-" .. dmg, sk.kind == "magic" and {0.55, 0.75, 1, 1} or {1, 0.55, 0.55, 1})
        if sk.poison and chance(sk.poison) then e.status.poison = 3; addBattleLog(b, e.name .. " is poisoned") end
        if sk.burn and chance(sk.burn) then e.status.burn = 3; addBattleLog(b, e.name .. " is burning") end
        if sk.stun and chance(sk.stun) then e.status.stun = 1; addBattleLog(b, e.name .. " is stunned") end
        if sk.shred then e.temp.defMul = (e.temp.defMul or 1) + sk.shred; addBattleLog(b, e.name .. " defense broken") end
    elseif sk.kind == "magic_aoe" then
        addBattleLog(b, "You cast " .. uname)
        for i, e in ipairs(b.enemies) do
            if e.hp > 0 then
                local dmg = basicDamage(b.p, e, sk.power, true)
                e.hp = max(0, e.hp - dmg)
                addFloating(g, 500, 140 + i * 70, "-" .. dmg, {0.65, 0.55, 1, 1})
            end
        end
    elseif sk.kind == "heal" then
        local amt = floor(b.p.mag * sk.power + 16 + random(0, 10))
        b.p.hp = min(b.p.maxhp, b.p.hp + amt)
        addBattleLog(b, "You cast Heal")
        addFloating(g, 160, 245, "+" .. amt, {0.45, 1, 0.55, 1})
    elseif sk.kind == "utility" and skillId == "meditate" then
        local m = 10 + floor(b.p.mag * 0.4)
        b.p.mp = min(b.p.maxmp, b.p.mp + m)
        b.p.status.regen = 2
        addBattleLog(b, "You meditate")
        addFloating(g, 160, 245, "+" .. m .. " MP", {0.4, 0.8, 1, 1})
    end
    return true
end

local function enemyTurn(g, b, idx)
    local e = b.enemies[idx]
    if not e or e.hp <= 0 then return end
    statusTickUnit(e, e.name, b, g, false)
    if e.hp <= 0 then return end
    if e.status.stun and e.status.stun > 0 then
        e.status.stun = e.status.stun - 1
        addBattleLog(b, e.name .. " is stunned")
        return
    end

    local p = b.p
    local id = e.id
    e.temp.guard = false

    local function hit(mult, magic, label, opts)
        local dmg = basicDamage(e, p, mult, magic)
        if opts and opts.fire then p.status.burn = max(p.status.burn or 0, 2) end
        if opts and opts.poison then p.status.poison = max(p.status.poison or 0, 2) end
        if opts and opts.stun and chance(opts.stun) then p.status.stun = 1 end
        p.hp = max(0, p.hp - dmg)
        addBattleLog(b, e.name .. " uses " .. label)
        addFloating(g, 160, 245, "-" .. dmg, magic and {0.75, 0.55, 1, 1} or {1, 0.45, 0.45, 1})
    end

    if e.boss then
        if id == "treant" then
            if e.hp < e.maxhp * 0.45 and e.phase == 1 then
                e.phase = 2
                e.temp.defMul = 0.85
                addBattleLog(b, "Treant enrages and hardens")
            end
            local roll = random()
            if roll < 0.25 then
                e.status.regen = 2
                addBattleLog(b, "Treant roots and regenerates")
            elseif roll < 0.65 then
                hit(1.25, false, "Vine Lash", {poison = true})
            else
                hit(1.10, true, "Spore Burst", {})
            end
        elseif id == "magma_beast" then
            if e.hp < e.maxhp * 0.50 and e.phase == 1 then
                e.phase = 2
                e.atk = floor(e.atk * 1.15)
                addBattleLog(b, "Magma Beast overheats")
            end
            local roll = random()
            if roll < 0.30 then hit(1.0, true, "Cinder Breath", {fire = true})
            elseif roll < 0.75 then hit(1.35, false, "Crushing Swipe", {})
            else
                e.temp.guard = true
                addBattleLog(b, "Magma Beast hardens its shell")
            end
        elseif id == "crystal_lord" then
            if e.hp < e.maxhp * 0.40 and e.phase == 1 then
                e.phase = 2
                e.spd = e.spd + 4
                addBattleLog(b, "Crystal Lord fractures into faster shards")
            end
            local roll = random()
            if roll < 0.35 then hit(1.05, true, "Prism Ray", {})
            elseif roll < 0.60 then hit(0.95, true, "Stasis Pulse", {stun = 0.35})
            else
                e.status.regen = 1
                addBattleLog(b, "Crystal Lord refracts and restores")
            end
        elseif id == "void_knight" then
            if e.hp < e.maxhp * 0.55 and e.phase == 1 then
                e.phase = 2
                e.atk = e.atk + 5
                e.mag = e.mag + 5
                addBattleLog(b, "Void Knight draws power from the gate")
            end
            local roll = random()
            if roll < 0.30 then hit(1.15, true, "Void Lance", {stun = 0.25})
            elseif roll < 0.65 then hit(1.35, false, "Abyss Cleave", {})
            elseif roll < 0.85 then
                e.status.regen = 2
                e.temp.guard = true
                addBattleLog(b, "Void Knight enters dark stance")
            else
                hit(1.05, true, "Entropy Flame", {fire = true})
            end
        end
        return
    end

    -- Normal enemies
    if id == "slime" then
        if chance(0.25) then
            e.status.regen = 1
            addBattleLog(b, e.name .. " jiggles and restores")
        else
            hit(1.0, false, "Body Slam", {})
        end
    elseif id == "wolf" then
        if chance(0.30) then hit(1.1, false, "Rend", {poison = true}) else hit(0.95, false, "Bite", {}) end
    elseif id == "bandit" then
        if chance(0.25) and p.gold > 0 then
            local steal = min(p.gold, random(4, 10))
            p.gold = p.gold - steal
            addBattleLog(b, "Bandit steals " .. steal .. "g")
        else
            hit(1.1, false, "Knife Flurry", {})
        end
    elseif id == "salamander" then
        if chance(0.55) then hit(1.0, true, "Ember Spit", {fire = true}) else hit(1.05, false, "Tail Lash", {}) end
    elseif id == "golem" then
        if chance(0.35) then
            e.temp.guard = true
            addBattleLog(b, e.name .. " braces")
        else
            hit(1.25, false, "Stone Fist", {})
        end
    elseif id == "wisp" then
        if chance(0.6) then hit(1.0, true, "Arc Spark", {}) else hit(0.9, false, "Zap", {}) end
    elseif id == "shardling" then
        if chance(0.3) then hit(0.95, true, "Shard Burst", {stun = 0.25}) else hit(1.1, false, "Crystal Claw", {}) end
    else
        hit(1.0, false, "Strike", {})
    end
end

local function battleVictory(g, b)
    local p = g.player
    p.hp = b.p.hp
    p.mp = b.p.mp
    local totalXP, totalGold = 0, 0
    for _, e in ipairs(b.enemies) do
        totalXP = totalXP + e.xp
        totalGold = totalGold + e.gold
        trackKill(g, e.id)
        for _, l in ipairs(e.loot or {}) do
            local id, prob, mn, mx = l[1], l[2], l[3] or 1, l[4] or (l[3] or 1)
            if chance(prob) then gainItem(p, id, random(mn, mx)) end
        end
    end
    p.gold = p.gold + totalGold
    addXP(p, totalXP)

    if b.postVictory then b.postVictory(g, b) end
    notify("Victory! +" .. totalXP .. " XP, +" .. totalGold .. "g")
    GAME.scene = "world"
    g.battle = nil
end

local function battleDefeat(g, b)
    local p = g.player
    p.hp = floor((calcPlayerStats(p).maxhp) * 0.35)
    p.mp = floor((calcPlayerStats(p).maxmp) * 0.35)
    p.gold = max(0, p.gold - floor(p.gold * 0.15))
    p.x = g.world.town.x * g.world.tile + g.world.tile * 5
    p.y = g.world.town.y * g.world.tile + g.world.tile * 5
    notify("You were defeated and rescued back to town")
    GAME.scene = "world"
    g.battle = nil
end

local function playerAttackBattle(g, b, targetIndex)
    local e = b.enemies[targetIndex]
    if not e or e.hp <= 0 then return false end
    local dmg = basicDamage(b.p, e, 1.0, false)
    e.hp = max(0, e.hp - dmg)
    addBattleLog(b, "You attack " .. e.name)
    addFloating(g, 500, 140 + targetIndex * 70, "-" .. dmg, {1, 0.55, 0.55, 1})
    return true
end

local function battleEnemiesAct(g, b)
    for i, e in ipairs(b.enemies) do
        if e.hp > 0 then
            enemyTurn(g, b, i)
            if b.p.hp <= 0 then break end
        end
    end
    local over = isBattleOver(b)
    if over == "win" then battleVictory(g, b) return end
    if over == "lose" then battleDefeat(g, b) return end
    -- reset temporary flags each round
    b.p.temp.guard = false
    for _, e in ipairs(b.enemies) do e.temp.guard = false end
    b.state = "command"
end

local function useWorldItem(g, itemId)
    local p = g.player
    local it = ITEMS[itemId]
    if not it or it.kind ~= "consumable" then return end
    if (p.items[itemId] or 0) <= 0 then notify("Out of item") return end
    local st = calcPlayerStats(p)
    p.items[itemId] = p.items[itemId] - 1
    if it.use.hp then p.hp = min(st.maxhp, p.hp + it.use.hp); spawnBurst(g, p.x, p.y, "heal") end
    if it.use.mp then p.mp = min(st.maxmp, p.mp + it.use.mp); spawnBurst(g, p.x, p.y, "mana") end
    if it.use.cure then p.statuses = {} end
    if it.use.bomb then notify("Bombs are battle items") p.items[itemId] = p.items[itemId] + 1 return end
    notify("Used " .. it.name)
end

local function equipGear(g, gearId)
    local p = g.player
    if (p.gearOwned[gearId] or 0) <= 0 then return end
    local eq = EQUIPMENT[gearId]
    local slot = eq.slot
    local old = p.equipment[slot]
    p.equipment[slot] = gearId
    p.gearOwned[gearId] = p.gearOwned[gearId] - 1
    if old then p.gearOwned[old] = (p.gearOwned[old] or 0) + 1 end
    notify("Equipped " .. eq.name)
    local st = calcPlayerStats(p)
    p.hp = min(p.hp, st.maxhp)
    p.mp = min(p.mp, st.maxmp)
end

local function craftRecipe(g, recipe)
    local p = g.player
    -- town only
    local t, tx, ty = tileAt(g.world, p.x, p.y)
    if not t or t.biome ~= "town" then notify("Crafting requires town forge") return end
    for id, n in pairs(recipe.req) do
        if not playerHas(p, id, n) then notify("Missing materials") return end
    end
    for id, n in pairs(recipe.req) do spendItem(p, id, n) end
    for id, n in pairs(recipe.out) do gainItem(p, id, n) end
    notify("Crafted: " .. recipe.name)
end

local function triggerRift(g, rift)
    if rift.hidden then notify("It is sealed") return end
    local qMain = questById(g, "main_rifts")
    local qFinal = questById(g, "final_void")

    if rift.id == "void" then
        if not qFinal or qFinal.state ~= "active" then
            notify("The gate is dormant")
            return
        end
        startBattle(g, {{id = "void_knight", levelMod = 2}}, "crystal", {
            boss = true,
            noFlee = true,
            source = {type = "rift", id = "void"},
            postVictory = function(game)
                rift.cleared = true
                game.world.defeatedRifts.void = true
                completeQuest(game, "final_void")
                game.player.flags.wonGame = true
                notify("The valley is saved")
            end,
        })
        return
    end

    if not qMain then
        notify("Speak to Elder Rowan first")
        return
    end

    if not rift.cleared then
        startBattle(g, {{id = rift.boss, levelMod = 1}}, rift.biome, {
            boss = true,
            noFlee = true,
            source = {type = "rift", id = rift.id},
            postVictory = function(game)
                rift.cleared = true
                game.world.defeatedRifts[rift.id] = true
                local qm = questById(game, "main_rifts")
                if qm and qm.progress then qm.progress[rift.id] = true end
                unlockVoidGateIfReady(game)
            end,
        })
    else
        local pack = chooseRandomEncounter(g.world, rift.biome, g.player.level + 1)
        startBattle(g, pack, rift.biome, {boss = false, noFlee = false})
    end
end

local function handleWorldInteract(g)
    local obj = nearestInteractable(g)
    if not obj then notify("Nothing nearby") return end
    if obj.role then
        interactWithNPC(g, obj)
    elseif obj.type == "chest" then
        doChest(g, obj)
    elseif obj.type == "shrine" then
        promptUseShrine(g, obj)
    elseif obj.type == "rift" then
        triggerRift(g, obj)
    elseif obj.kind and obj.active ~= nil then
        doGather(g, obj)
    end
end

local function updateWorld(g, dt)
    g.playTime = g.playTime + dt
    local p, w = g.player, g.world
    local st = calcPlayerStats(p)
    p.hp = clamp(p.hp, 1, st.maxhp)
    p.mp = clamp(p.mp, 0, st.maxmp)

    -- day/night + weather
    w.dayTime = (w.dayTime + dt * 0.005) % 1
    w.weather.timer = w.weather.timer - dt
    if w.weather.timer <= 0 then
        w.weather.timer = 28 + random() * 45
        local rolls = {"clear", "rain", "fog", "wind"}
        w.weather.kind = pick(rolls)
        notify("Weather changed: " .. w.weather.kind)
    end

    -- Movement (disabled if menu/dialog open)
    if not g.menu.open and not g.dialog then
        local mx = (lk.isDown("d") or lk.isDown("right")) and 1 or 0
        local my = (lk.isDown("s") or lk.isDown("down")) and 1 or 0
        mx = mx - ((lk.isDown("a") or lk.isDown("left")) and 1 or 0)
        my = my - ((lk.isDown("w") or lk.isDown("up")) and 1 or 0)
        if mx ~= 0 or my ~= 0 then
            local len = sqrt(mx * mx + my * my)
            mx, my = mx / len, my / len
            p.dirx, p.diry = mx, my
            local speedMul = (w.weather.kind == "wind" and 1.05 or 1.0)
            local nx = p.x + mx * p.speed * speedMul * dt
            local ny = p.y + my * p.speed * speedMul * dt
            if canWalk(w, nx, p.y, p.r) then p.x = nx end
            if canWalk(w, p.x, ny, p.r) then p.y = ny end
        end
    end

    -- Mark explored tiles
    local _, tx, ty = tileAt(w, p.x, p.y)
    if tx and ty then p.explored[ty .. ":" .. tx] = true end

    -- NPC idle animation
    for _, npc in ipairs(w.npcs) do
        npc.dir = ((npc.dir or 1) + dt * 0.8) % (math.pi * 2)
    end

    -- Resource respawns
    for _, r in ipairs(w.resources) do
        if not r.active then
            r.timer = r.timer - dt
            if r.timer <= 0 then r.active = true end
        end
    end

    -- Mobs AI
    for _, m in ipairs(w.mobs) do
        if m.alive then
            local mtile = tileAt(w, m.x, m.y)
            local near = dist(m.x, m.y, p.x, p.y)
            m.think = m.think - dt
            if m.think <= 0 then
                m.think = 0.7 + random() * 1.4
                if near < 140 then
                    local dx, dy = p.x - m.x, p.y - m.y
                    local l = max(1, sqrt(dx * dx + dy * dy))
                    m.vx, m.vy = dx / l, dy / l
                else
                    local a = random() * math.pi * 2
                    m.vx, m.vy = cos(a), sin(a)
                end
            end
            local mv = 45 + (near < 140 and 20 or 0)
            local nx, ny = m.x + m.vx * mv * dt, m.y + m.vy * mv * dt
            if canWalk(w, nx, m.y, m.r) then m.x = nx else m.vx = -m.vx end
            if canWalk(w, m.x, ny, m.r) then m.y = ny else m.vy = -m.vy end

            if near < m.r + p.r + 4 and not g.menu.open and not g.dialog then
                local tile = tileAt(w, m.x, m.y)
                local biome = tile and tile.biome or "meadow"
                local group = chooseRandomEncounter(w, biome, p.level)
                group[1] = {id = m.enemyId, levelMod = 0}
                m.alive = false
                m.respawn = 25 + random() * 20
                startBattle(g, group, biome, {source = {type = "mob", ref = m}})
                return
            end
        else
            m.respawn = m.respawn - dt
            if m.respawn <= 0 then
                m.alive = true
                -- potentially upgrade spawn by biome progression
                local tile, tx2, ty2 = tileAt(w, m.x, m.y)
                if tile then
                    local poolByBiome = {
                        meadow = {"slime", "wolf"},
                        forest = {"bandit", "wolf", "slime"},
                        ember = {"salamander", "golem"},
                        crystal = {"wisp", "shardling"},
                    }
                    m.enemyId = pick(poolByBiome[tile.biome] or {"slime"})
                    if tile.blocked or tile.water then
                        -- push toward center if blocked due to drift
                        m.x, m.y = (tx2 or 10) * w.tile, (ty2 or 10) * w.tile
                    end
                end
            end
        end
    end

    -- Camera
    local sw, sh = lg.getDimensions()
    GAME.cam.x = p.x - sw / 2
    GAME.cam.y = p.y - sh / 2

    -- Particles
    for i = #g.particles, 1, -1 do
        local pt = g.particles[i]
        pt.t = pt.t - dt
        if pt.t <= 0 then
            table.remove(g.particles, i)
        else
            pt.x = pt.x + (pt.vx or 0) * dt
            pt.y = pt.y + (pt.vy or 0) * dt
            if not pt.float then pt.vy = (pt.vy or 0) + 20 * dt end
        end
    end
end

local function updateBattle(g, dt)
    local b = g.battle
    if not b then return end
    b.anim.t = b.anim.t + dt

    -- battle particles are stored in g.particles too
    for i = #g.particles, 1, -1 do
        local pt = g.particles[i]
        pt.t = pt.t - dt
        if pt.t <= 0 then table.remove(g.particles, i)
        else
            pt.x = pt.x + (pt.vx or 0) * dt
            pt.y = pt.y + (pt.vy or 0) * dt
        end
    end

    if b.state == "enemyAct" then
        b.aiTimer = (b.aiTimer or 0) - dt
        if b.aiTimer <= 0 then
            battleEnemiesAct(g, b)
            b.aiTimer = nil
        end
    end

    local over = isBattleOver(b)
    if over == "win" then battleVictory(g, b) end
    if over == "lose" then battleDefeat(g, b) end
end

local function uiListMove(idx, dir, len)
    if len < 1 then return 1 end
    idx = idx + dir
    if idx < 1 then idx = len end
    if idx > len then idx = 1 end
    return idx
end

local function getMenuTabNames()
    return {"Inventory", "Equipment", "Skills", "Stats", "Craft", "Journal", "Map", "System"}
end

local function menuInventoryList(g)
    local out = {}
    for id, n in pairs(g.player.items) do
        if n > 0 and ITEMS[id] then table.insert(out, {id = id, count = n, item = ITEMS[id]}) end
    end
    table.sort(out, function(a, b) return a.item.name < b.item.name end)
    return out
end

local function menuEquipList(g)
    local out = {}
    for id, n in pairs(g.player.gearOwned) do
        if n > 0 and EQUIPMENT[id] then table.insert(out, {id = id, count = n, eq = EQUIPMENT[id]}) end
    end
    table.sort(out, function(a, b) return a.eq.name < b.eq.name end)
    return out
end

local function systemMenuOptions()
    return {"Save Game", "Load Game", "Close Menu", "Quit to Title"}
end

local function battleUsableItems(g)
    local out = {}
    for id, n in pairs(g.player.items) do
        if n > 0 and ITEMS[id] and ITEMS[id].kind == "consumable" then
            table.insert(out, {id = id, count = n, item = ITEMS[id]})
        end
    end
    table.sort(out, function(a, b) return a.item.name < b.item.name end)
    return out
end

local function handleBattleConfirm(g)
    local b = g.battle
    if not b then return end
    if b.state == "command" then
        local options = {"Attack", "Skill", "Item", "Guard", "Flee"}
        local choice = options[b.cmdIndex]
        if choice == "Attack" then
            b.state = "target"; b.subAction = {kind = "attack"}; b.targetIndex = 1
        elseif choice == "Skill" then
            b.state = "skills"; b.skillIndex = 1
        elseif choice == "Item" then
            b.state = "items"; b.itemIndex = 1
        elseif choice == "Guard" then
            b.p.temp.guard = true
            addBattleLog(b, "You guard")
            statusTickUnit(b.p, "You", b, g, true)
            local over = isBattleOver(b)
            if over == "win" then battleVictory(g, b) return end
            if over == "lose" then battleDefeat(g, b) return end
            b.state = "enemyAct"; b.aiTimer = 0.45
        elseif choice == "Flee" then
            if not b.canFlee then notify("Cannot flee") return end
            if chance(0.45 + g.player.level * 0.03) then
                notify("Escaped")
                g.player.hp = b.p.hp
                g.player.mp = b.p.mp
                GAME.scene = "world"
                g.battle = nil
            else
                addBattleLog(b, "Failed to flee")
                b.state = "enemyAct"; b.aiTimer = 0.45
            end
        end
    elseif b.state == "skills" then
        local sid = g.player.skills[b.skillIndex]
        local sk = sid and SKILLS[sid]
        if not sk then return end
        if sk.target == "enemy" then
            b.state = "target"; b.subAction = {kind = "skill", id = sid}; b.targetIndex = 1
        elseif sk.target == "all_enemies" or sk.target == "self" then
            statusTickUnit(b.p, "You", b, g, true)
            if b.p.hp <= 0 then battleDefeat(g, b) return end
            if b.p.status.stun and b.p.status.stun > 0 then
                b.p.status.stun = b.p.status.stun - 1
                addBattleLog(b, "You are stunned")
            else
                if playerSkillCast(g, b, sid, 1) then end
            end
            local over = isBattleOver(b)
            if over == "win" then battleVictory(g, b) return end
            b.state = "enemyAct"; b.aiTimer = 0.45
        end
    elseif b.state == "items" then
        local items = battleUsableItems(g)
        local ent = items[b.itemIndex]
        if not ent then return end
        if ent.id == "bomb" then
            b.state = "target"; b.subAction = {kind = "item", id = ent.id}; b.targetIndex = 1
        else
            statusTickUnit(b.p, "You", b, g, true)
            if b.p.hp <= 0 then battleDefeat(g, b) return end
            if b.p.status.stun and b.p.status.stun > 0 then
                b.p.status.stun = b.p.status.stun - 1
                addBattleLog(b, "You are stunned")
            else
                usePlayerItemInBattle(g, b, ent.id, 1)
            end
            b.state = "enemyAct"; b.aiTimer = 0.45
        end
    elseif b.state == "target" then
        local live = livingEnemies(b)
        if #live == 0 then return end
        local ti = live[((b.targetIndex - 1) % #live) + 1]

        statusTickUnit(b.p, "You", b, g, true)
        if b.p.hp <= 0 then battleDefeat(g, b) return end
        if b.p.status.stun and b.p.status.stun > 0 then
            b.p.status.stun = b.p.status.stun - 1
            addBattleLog(b, "You are stunned")
            b.state = "enemyAct"; b.aiTimer = 0.45
            return
        end

        if b.subAction.kind == "attack" then
            playerAttackBattle(g, b, ti)
        elseif b.subAction.kind == "skill" then
            playerSkillCast(g, b, b.subAction.id, ti)
        elseif b.subAction.kind == "item" then
            usePlayerItemInBattle(g, b, b.subAction.id, ti)
        end
        local over = isBattleOver(b)
        if over == "win" then battleVictory(g, b) return end
        if over == "lose" then battleDefeat(g, b) return end
        b.state = "enemyAct"; b.aiTimer = 0.45
    end
end

local function handleBattleKey(g, key)
    local b = g.battle
    if not b then return end
    if b.state == "enemyAct" then return end

    if key == "escape" or key == "backspace" then
        if b.state == "skills" or b.state == "items" then b.state = "command" return end
        if b.state == "target" then
            if b.subAction and b.subAction.kind == "attack" then b.state = "command" else
                if b.subAction and b.subAction.kind == "skill" then b.state = "skills" else b.state = "items" end
            end
            return
        end
    end

    if key == "return" or key == "kpenter" or key == "space" then handleBattleConfirm(g) return end

    if b.state == "command" then
        if key == "up" then b.cmdIndex = uiListMove(b.cmdIndex, -1, 5) end
        if key == "down" then b.cmdIndex = uiListMove(b.cmdIndex, 1, 5) end
    elseif b.state == "skills" then
        if key == "up" then b.skillIndex = uiListMove(b.skillIndex, -1, #g.player.skills) end
        if key == "down" then b.skillIndex = uiListMove(b.skillIndex, 1, #g.player.skills) end
    elseif b.state == "items" then
        local len = #battleUsableItems(g)
        if key == "up" then b.itemIndex = uiListMove(b.itemIndex, -1, len) end
        if key == "down" then b.itemIndex = uiListMove(b.itemIndex, 1, len) end
    elseif b.state == "target" then
        local live = livingEnemies(b)
        if key == "left" or key == "up" then b.targetIndex = uiListMove(b.targetIndex, -1, max(1, #live)) end
        if key == "right" or key == "down" then b.targetIndex = uiListMove(b.targetIndex, 1, max(1, #live)) end
    end
end

local function handleDialogKey(g, key)
    local d = g.dialog
    if not d then return end
    if key == "up" then d.cursor = uiListMove(d.cursor, -1, #d.options) end
    if key == "down" then d.cursor = uiListMove(d.cursor, 1, #d.options) end
    if key == "return" or key == "kpenter" or key == "space" then
        local opt = d.options[d.cursor]
        if opt and opt.fn then opt.fn() end
    elseif key == "escape" or key == "backspace" then
        closeDialog(g)
    end
end

local function handleMenuKey(g, key)
    local m = g.menu
    if not m.open then return end
    local tabs = getMenuTabNames()
    if key == "escape" or key == "tab" then closeMenu(g) return end
    if key == "left" then m.tab = uiListMove(m.tab, -1, #tabs) m.cursor = 1 return end
    if key == "right" then m.tab = uiListMove(m.tab, 1, #tabs) m.cursor = 1 return end

    -- Tab shortcuts
    if key == "1" then m.tab = 1 m.cursor = 1 return end
    if key == "2" then m.tab = 2 m.cursor = 1 return end
    if key == "3" then m.tab = 3 m.cursor = 1 return end
    if key == "4" then m.tab = 4 m.cursor = 1 return end
    if key == "5" then m.tab = 5 m.cursor = 1 return end
    if key == "6" then m.tab = 6 m.cursor = 1 return end
    if key == "7" then m.tab = 7 m.cursor = 1 return end
    if key == "8" then m.tab = 8 m.cursor = 1 return end

    if m.tab == 1 then
        local list = menuInventoryList(g)
        if key == "up" then m.cursor = uiListMove(m.cursor, -1, #list) end
        if key == "down" then m.cursor = uiListMove(m.cursor, 1, #list) end
        if (key == "return" or key == "kpenter") and list[m.cursor] then
            local ent = list[m.cursor]
            if ent.item.kind == "consumable" then useWorldItem(g, ent.id) else notify("Materials are for crafting") end
        end
    elseif m.tab == 2 then
        local list = menuEquipList(g)
        if key == "up" then m.cursor = uiListMove(m.cursor, -1, #list) end
        if key == "down" then m.cursor = uiListMove(m.cursor, 1, #list) end
        if (key == "return" or key == "kpenter") and list[m.cursor] then equipGear(g, list[m.cursor].id) end
    elseif m.tab == 3 then
        if key == "up" then m.cursor = uiListMove(m.cursor, -1, #g.player.skills) end
        if key == "down" then m.cursor = uiListMove(m.cursor, 1, #g.player.skills) end
    elseif m.tab == 4 then
        if g.player.statPoints > 0 then
            if key == "1" then g.player.bonus.might = (g.player.bonus.might or 0) + 1; g.player.statPoints = g.player.statPoints - 1; notify("Might +1") end
            if key == "2" then g.player.bonus.mind = (g.player.bonus.mind or 0) + 1; g.player.statPoints = g.player.statPoints - 1; notify("Mind +1") end
            if key == "3" then g.player.bonus.agility = (g.player.bonus.agility or 0) + 1; g.player.statPoints = g.player.statPoints - 1; notify("Agility +1") end
            local st = calcPlayerStats(g.player)
            g.player.hp = min(g.player.hp, st.maxhp)
            g.player.mp = min(g.player.mp, st.maxmp)
        end
    elseif m.tab == 5 then
        if key == "up" then m.cursor = uiListMove(m.cursor, -1, #RECIPES) end
        if key == "down" then m.cursor = uiListMove(m.cursor, 1, #RECIPES) end
        if (key == "return" or key == "kpenter") and RECIPES[m.cursor] then craftRecipe(g, RECIPES[m.cursor]) end
    elseif m.tab == 6 then
        if key == "up" then m.cursor = uiListMove(m.cursor, -1, #g.quests) end
        if key == "down" then m.cursor = uiListMove(m.cursor, 1, #g.quests) end
    elseif m.tab == 8 then
        local opts = systemMenuOptions()
        if key == "up" then m.cursor = uiListMove(m.cursor, -1, #opts) end
        if key == "down" then m.cursor = uiListMove(m.cursor, 1, #opts) end
        if key == "return" or key == "kpenter" then
            local s = opts[m.cursor]
            if s == "Save Game" then saveGame(g)
            elseif s == "Load Game" then
                local ng = loadSavedGame()
                if ng then GAME.game = ng; GAME.scene = "world" end
            elseif s == "Close Menu" then closeMenu(g)
            elseif s == "Quit to Title" then GAME.scene = "title"; GAME.game = nil end
            end
        end
    end
end

local function drawPanel(x, y, w, h, alpha)
    lg.setColor(0, 0, 0, alpha or 0.55)
    lg.rectangle("fill", x + 3, y + 3, w, h, 8, 8)
    lg.setColor(COLORS.panel)
    lg.rectangle("fill", x, y, w, h, 8, 8)
    lg.setColor(0.9, 0.95, 1.0, 0.12)
    lg.rectangle("line", x + 0.5, y + 0.5, w - 1, h - 1, 8, 8)
end

local function drawBar(x, y, w, h, frac, col, bg)
    frac = clamp(frac, 0, 1)
    lg.setColor(bg or {0.12, 0.12, 0.12, 0.95})
    lg.rectangle("fill", x, y, w, h, 4, 4)
    lg.setColor(col)
    lg.rectangle("fill", x + 1, y + 1, (w - 2) * frac, h - 2, 4, 4)
    lg.setColor(1, 1, 1, 0.15)
    lg.rectangle("line", x + 0.5, y + 0.5, w - 1, h - 1, 4, 4)
end

local function drawEntityShape(x, y, shape, t, scale, color)
    scale = scale or 1
    lg.setColor(color or 1, 1, 1, 1)
    if shape == "player" then
        lg.circle("fill", x, y - 2, 10 * scale)
        lg.setColor(0.15, 0.18, 0.28)
        lg.rectangle("fill", x - 8 * scale, y + 7 * scale, 16 * scale, 10 * scale, 3, 3)
        lg.setColor(0.95, 0.95, 0.95)
        lg.line(x - 6 * scale, y + 4 * scale, x + 6 * scale, y + 4 * scale)
    elseif shape == "blob" then
        local r = 10 * scale + sin(t * 3) * 1.5
        lg.ellipse("fill", x, y + 2, r * 1.1, r * 0.85)
        lg.setColor(1, 1, 1, 0.4)
        lg.circle("fill", x - 3 * scale, y - 2 * scale, 2.5 * scale)
    elseif shape == "wolf" or shape == "beast" or shape == "lizard" then
        lg.ellipse("fill", x, y, 12 * scale, 8 * scale)
        lg.circle("fill", x + 10 * scale, y - 2 * scale, 5 * scale)
        lg.polygon("fill", x + 12 * scale, y - 8 * scale, x + 8 * scale, y - 5 * scale, x + 15 * scale, y - 4 * scale)
        lg.polygon("fill", x + 5 * scale, y + 6 * scale, x + 9 * scale, y + 6 * scale, x + 7 * scale, y + 12 * scale)
        lg.polygon("fill", x - 5 * scale, y + 6 * scale, x - 1 * scale, y + 6 * scale, x - 3 * scale, y + 12 * scale)
    elseif shape == "humanoid" or shape == "knight" or shape == "lord" then
        lg.circle("fill", x, y - 10 * scale, 6 * scale)
        lg.rectangle("fill", x - 7 * scale, y - 3 * scale, 14 * scale, 16 * scale, 3, 3)
        lg.rectangle("fill", x - 10 * scale, y + 12 * scale, 5 * scale, 10 * scale)
        lg.rectangle("fill", x + 5 * scale, y + 12 * scale, 5 * scale, 10 * scale)
        if shape == "knight" then
            lg.setColor(0.95, 0.2, 0.35)
            lg.line(x + 10 * scale, y - 2 * scale, x + 16 * scale, y - 8 * scale)
        elseif shape == "lord" then
            lg.setColor(0.75, 0.85, 1.0, 0.75)
            lg.circle("line", x, y + 4 * scale, 15 * scale)
        end
    elseif shape == "treant" then
        lg.rectangle("fill", x - 8 * scale, y - 4 * scale, 16 * scale, 20 * scale, 4, 4)
        lg.line(x - 6 * scale, y - 4 * scale, x - 12 * scale, y - 14 * scale)
        lg.line(x + 6 * scale, y - 4 * scale, x + 12 * scale, y - 14 * scale)
        lg.line(x - 4 * scale, y + 16 * scale, x - 10 * scale, y + 24 * scale)
        lg.line(x + 4 * scale, y + 16 * scale, x + 10 * scale, y + 24 * scale)
        lg.setColor(0.45, 0.85, 0.35)
        lg.circle("fill", x - 9 * scale, y - 12 * scale, 6 * scale)
        lg.circle("fill", x + 9 * scale, y - 12 * scale, 6 * scale)
        lg.circle("fill", x, y - 16 * scale, 8 * scale)
    elseif shape == "golem" then
        lg.rectangle("fill", x - 12 * scale, y - 6 * scale, 24 * scale, 18 * scale, 3, 3)
        lg.rectangle("fill", x - 9 * scale, y + 12 * scale, 6 * scale, 12 * scale)
        lg.rectangle("fill", x + 3 * scale, y + 12 * scale, 6 * scale, 12 * scale)
        lg.rectangle("fill", x - 16 * scale, y - 4 * scale, 4 * scale, 12 * scale)
        lg.rectangle("fill", x + 12 * scale, y - 4 * scale, 4 * scale, 12 * scale)
    elseif shape == "wisp" then
        lg.circle("fill", x, y, 9 * scale)
        for i = 1, 4 do
            local a = t * 2 + i * 1.4
            lg.circle("line", x + cos(a) * 10 * scale, y + sin(a) * 10 * scale, 3 * scale)
        end
    elseif shape == "shard" then
        lg.polygon("fill", x, y - 12 * scale, x + 10 * scale, y, x, y + 14 * scale, x - 10 * scale, y)
        lg.setColor(1, 1, 1, 0.25)
        lg.line(x, y - 10 * scale, x, y + 10 * scale)
    else
        lg.circle("fill", x, y, 10 * scale)
    end
end

local function drawWorld(g)
    local p, w = g.player, g.world
    local sw, sh = lg.getDimensions()
    local ts = w.tile
    local camx, camy = floor(GAME.cam.x), floor(GAME.cam.y)
    local startX = max(1, floor(camx / ts))
    local startY = max(1, floor(camy / ts))
    local endX = min(w.w, startX + floor(sw / ts) + 3)
    local endY = min(w.h, startY + floor(sh / ts) + 3)

    local day = 0.5 + 0.5 * sin(w.dayTime * math.pi * 2)
    local nightFactor = 0.45 + day * 0.55

    lg.push()
    lg.translate(-camx, -camy)

    -- Tiles
    for y = startY, endY do
        for x = startX, endX do
            local t = w.tiles[y][x]
            local b = BIOMES[t.biome]
            local gx, gy = (x - 1) * ts, (y - 1) * ts
            local r, gch, bl = b.ground[1], b.ground[2], b.ground[3]
            local n = t.decor
            local mod = (n * 0.08)
            if w.weather.kind == "fog" then mod = mod * 0.5 end
            lg.setColor((r + mod) * nightFactor, (gch + mod) * nightFactor, (bl + mod) * nightFactor)
            lg.rectangle("fill", gx, gy, ts + 1, ts + 1)
            if t.water then
                lg.setColor(b.water[1] * nightFactor, b.water[2] * nightFactor, b.water[3] * nightFactor)
                lg.rectangle("fill", gx + 2, gy + 2, ts - 4, ts - 4, 3, 3)
                lg.setColor(1, 1, 1, 0.08)
                lg.line(gx + 4, gy + 8 + sin(GAME.time * 2 + x) * 2, gx + ts - 4, gy + 8)
            elseif t.blocked then
                if t.biome == "forest" then
                    lg.setColor(0.08 * nightFactor, 0.22 * nightFactor, 0.10 * nightFactor)
                    lg.circle("fill", gx + 12, gy + 12, 10)
                    lg.setColor(0.30 * nightFactor, 0.20 * nightFactor, 0.10 * nightFactor)
                    lg.rectangle("fill", gx + 10, gy + 14, 4, 8)
                elseif t.biome == "ember" then
                    lg.setColor(0.25 * nightFactor, 0.14 * nightFactor, 0.08 * nightFactor)
                    lg.polygon("fill", gx + 4, gy + 20, gx + 10, gy + 6, gx + 18, gy + 18)
                elseif t.biome == "crystal" then
                    lg.setColor(0.55 * nightFactor, 0.70 * nightFactor, 1.0 * nightFactor)
                    lg.polygon("fill", gx + 12, gy + 3, gx + 20, gy + 12, gx + 12, gy + 21, gx + 4, gy + 12)
                else
                    lg.setColor(0.18 * nightFactor, 0.38 * nightFactor, 0.12 * nightFactor)
                    lg.circle("fill", gx + 12, gy + 12, 8)
                end
            else
                lg.setColor((b.detail[1] + 0.02) * nightFactor, (b.detail[2] + 0.02) * nightFactor, (b.detail[3] + 0.02) * nightFactor, 0.35)
                lg.points(gx + 3 + (n * 13) % 16, gy + 4 + (n * 29) % 15)
                lg.points(gx + 16 - (n * 7) % 13, gy + 10 + (n * 11) % 9)
            end
        end
    end

    -- Roads in town
    local tx, ty = w.town.x * ts, w.town.y * ts
    lg.setColor(0.48 * nightFactor, 0.42 * nightFactor, 0.30 * nightFactor)
    lg.rectangle("fill", tx + 4 * ts, ty, ts * 2, ts * 10)
    lg.rectangle("fill", tx, ty + 4 * ts, ts * 10, ts * 2)

    -- Buildings
    for _, b in ipairs(w.town.buildings) do
        local bx, by = b.x * ts, b.y * ts
        lg.setColor(0.14 * nightFactor, 0.12 * nightFactor, 0.10 * nightFactor)
        lg.rectangle("fill", bx, by, b.w * ts, b.h * ts, 4, 4)
        lg.setColor(0.65 * nightFactor, 0.35 * nightFactor, 0.25 * nightFactor)
        lg.polygon("fill", bx - 2, by + 4, bx + b.w * ts / 2, by - 10, bx + b.w * ts + 2, by + 4)
        lg.setColor(0.95, 0.85, 0.45, 0.55 + 0.25 * sin(GAME.time * 2))
        lg.rectangle("fill", b.doorx * ts + 6, b.doory * ts + 6, ts - 12, ts - 8, 2, 2)
    end

    -- Objects
    for _, o in ipairs(w.objects) do
        if not o.hidden then
            if o.type == "chest" then
                lg.setColor(o.opened and {0.35, 0.25, 0.16} or {0.70, 0.45, 0.20})
                lg.rectangle("fill", o.x - 8, o.y - 6, 16, 12, 2, 2)
                lg.setColor(0.95, 0.85, 0.20)
                lg.rectangle("fill", o.x - 8, o.y - 1, 16, 2)
            elseif o.type == "shrine" then
                local c = {atk = {0.95,0.50,0.30}, mind = {0.45,0.65,1.0}, guard = {0.55,0.95,0.55}, speed = {0.90,0.90,0.45}}
                local col = c[o.shrineKind] or {1,1,1}
                lg.setColor(col[1], col[2], col[3], o.used and 0.35 or 0.85)
                lg.circle("fill", o.x, o.y, 8 + sin(GAME.time * 2) * 1.5)
                lg.setColor(1,1,1,o.used and 0.12 or 0.25)
                lg.circle("line", o.x, o.y, 14 + sin(GAME.time * 2.2) * 2)
            elseif o.type == "rift" then
                local pulse = 0.7 + 0.3 * sin(GAME.time * 3)
                local col = o.id == "forest" and {0.35,1,0.45} or (o.id == "ember" and {1,0.35,0.15} or (o.id == "crystal" and {0.55,0.75,1} or {0.85,0.3,1}))
                lg.setColor(col[1], col[2], col[3], o.cleared and 0.35 or pulse)
                lg.circle("line", o.x, o.y, 14)
                lg.circle("line", o.x, o.y, 9)
                lg.line(o.x - 8, o.y, o.x + 8, o.y)
                lg.line(o.x, o.y - 8, o.x, o.y + 8)
            end
        end
    end

    -- Resources
    for _, r in ipairs(w.resources) do
        if r.active then
            if r.kind == "herb" then
                lg.setColor(0.25, 0.85, 0.35)
                lg.line(r.x, r.y + 5, r.x, r.y - 4)
                lg.line(r.x, r.y, r.x - 4, r.y - 2)
                lg.line(r.x, r.y - 1, r.x + 4, r.y - 3)
            elseif r.kind == "ore" then
                lg.setColor(0.65, 0.65, 0.72)
                lg.polygon("fill", r.x - 5, r.y + 4, r.x - 1, r.y - 6, r.x + 5, r.y + 1, r.x + 2, r.y + 6)
            elseif r.kind == "ember_shard" then
                lg.setColor(1.0, 0.45, 0.2)
                lg.polygon("fill", r.x, r.y - 6, r.x + 4, r.y, r.x, r.y + 6, r.x - 4, r.y)
            elseif r.kind == "crystal_dust" then
                lg.setColor(0.55, 0.75, 1.0)
                lg.circle("fill", r.x, r.y, 4)
                lg.circle("fill", r.x + 4, r.y + 1, 2)
                lg.circle("fill", r.x - 3, r.y + 2, 2)
            end
        end
    end

    -- Mobs
    for _, m in ipairs(w.mobs) do
        if m.alive then
            local e = ENEMIES[m.enemyId]
            local col = {0.8, 0.25, 0.25}
            if e.biome == "meadow" then col = {0.45, 0.95, 0.45}
            elseif e.biome == "forest" then col = {0.75, 0.75, 0.35}
            elseif e.biome == "ember" then col = {1.0, 0.45, 0.25}
            elseif e.biome == "crystal" then col = {0.6, 0.8, 1.0}
            end
            drawEntityShape(m.x, m.y, e.shape, GAME.time, 0.7, col)
        end
    end

    -- NPCs
    for _, n in ipairs(w.npcs) do
        drawEntityShape(n.x, n.y, "humanoid", GAME.time + n.dir, 0.7, n.color)
        lg.setColor(1,1,1,0.25)
        lg.circle("line", n.x, n.y + 14, 10)
    end

    -- Player
    drawEntityShape(p.x, p.y, "player", GAME.time, 1.0, {0.85, 0.9, 1.0})

    -- Weather overlay particles (visual only)
    if w.weather.kind == "rain" then
        lg.setColor(0.7, 0.8, 1.0, 0.25)
        for i = 1, 120 do
            local rx = camx + ((i * 73 + floor(GAME.time * 300)) % (sw + 80)) - 40
            local ry = camy + ((i * 127 + floor(GAME.time * 420)) % (sh + 80)) - 40
            lg.line(rx, ry, rx - 4, ry + 10)
        end
    elseif w.weather.kind == "fog" then
        lg.setColor(0.85, 0.90, 0.95, 0.07)
        for i = 1, 7 do
            local y = camy + (i * 80 + sin(GAME.time * 0.3 + i) * 20)
            lg.rectangle("fill", camx - 20, y, sw + 40, 34)
        end
    end

    -- Particles and float text
    for _, pt in ipairs(g.particles) do
        if pt.float and pt.text then
            lg.setColor(pt.color)
            lg.print(pt.text, pt.x - 8, pt.y)
        elseif not pt.float then
            lg.setColor(pt.color)
            lg.circle("fill", pt.x, pt.y, pt.r or 2)
        end
    end

    lg.pop()

    -- UI HUD
    drawPanel(10, 10, 315, 92)
    local stp = calcPlayerStats(p)
    lg.setColor(COLORS.text)
    lg.setFont(GAME.fonts.small)
    lg.print(p.name .. "  Lv." .. p.level, 18, 16)
    lg.setColor(COLORS.dim)
    local tile = tileAt(w, p.x, p.y)
    lg.print((tile and BIOMES[tile.biome].name or "?") .. "  |  Weather: " .. w.weather.kind, 18, 34)
    drawBar(18, 52, 230, 12, p.hp / stp.maxhp, COLORS.good)
    drawBar(18, 68, 230, 12, p.mp / stp.maxmp, COLORS.mana)
    drawBar(18, 84, 230, 8, p.xp / p.xpToNext, COLORS.xp)
    lg.setColor(COLORS.text) lg.print(string.format("HP %d/%d", p.hp, stp.maxhp), 254, 48)
    lg.setColor(COLORS.text) lg.print(string.format("MP %d/%d", p.mp, stp.maxmp), 254, 64)
    lg.setColor(COLORS.gold) lg.print("Gold " .. p.gold, 254, 80)

    -- Quest tracker
    drawPanel(sw - 290, 10, 280, 92)
    lg.setColor(COLORS.text)
    lg.print("Active Quest", sw - 282, 16)
    local active = nil
    for _, q in ipairs(g.quests) do if q.state == "active" or q.state == "ready" then active = q break end end
    lg.setFont(GAME.fonts.tiny)
    if active then
        lg.setColor(active.type == "main" and {1,0.9,0.4} or {0.7,0.9,1.0})
        lg.printf(active.name, sw - 282, 36, 264)
        lg.setColor(COLORS.dim)
        local line = active.desc
        if active.id == "bounty" then line = string.format("%s %d/%d", ENEMIES[active.enemy].name, active.progress or 0, active.count) end
        lg.printf(line, sw - 282, 54, 264)
    else
        lg.setColor(COLORS.dim)
        lg.print("No active quests", sw - 282, 42)
    end
    lg.setFont(GAME.fonts.small)

    -- Interaction hint
    local near = nearestInteractable(g)
    if near and dist(p.x, p.y, near.x, near.y) < 36 then
        local label = near.name or near.label or (near.type == "chest" and "Chest") or (near.kind and ("Gather " .. ITEMS[near.kind].name)) or "Interact"
        drawPanel(sw / 2 - 140, sh - 52, 280, 36)
        lg.setColor(COLORS.text)
        lg.printf("E  Interact: " .. label, sw / 2 - 132, sh - 43, 264, "center")
    end

    if GAME.msg and GAME.msgTimer > 0 then
        drawPanel(sw / 2 - 190, sh - 92, 380, 34)
        lg.setColor(1,1,1, clamp(GAME.msgTimer / 2.6, 0.35, 1))
        lg.printf(GAME.msg, sw / 2 - 180, sh - 84, 360, "center")
    end
end

local function drawBattle(g)
    local b = g.battle
    local sw, sh = lg.getDimensions()

    -- Background by biome
    local bg = BIOMES[b.biome] or BIOMES.meadow
    lg.clear(bg.detail[1] * 0.4, bg.detail[2] * 0.4, bg.detail[3] * 0.45)
    for i = 1, 12 do
        lg.setColor(bg.ground[1] * (0.5 + i * 0.02), bg.ground[2] * (0.5 + i * 0.02), bg.ground[3] * (0.5 + i * 0.02))
        lg.rectangle("fill", 0, i * 40, sw, 36)
    end
    lg.setColor(0, 0, 0, 0.18)
    lg.ellipse("fill", 165, 272, 95, 20)
    lg.ellipse("fill", 540, 170, 180, 34)

    -- Hero and enemies
    drawEntityShape(160, 240 + sin(b.anim.t * 2) * 2, "player", b.anim.t, 1.3, {0.85, 0.95, 1.0})
    for i, e in ipairs(b.enemies) do
        if e.hp > 0 then
            local ex = 470 + ((i - 1) % 2) * 120
            local ey = 130 + floor((i - 1) / 2) * 90
            local col = {1, 0.65, 0.65}
            if e.boss then col = {1.0, 0.35, 0.7} end
            drawEntityShape(ex, ey, e.shape, b.anim.t + i, e.boss and 1.15 or 0.95, col)
            if b.state == "target" then
                local live = livingEnemies(b)
                local li = live[((b.targetIndex - 1) % max(1,#live)) + 1]
                if li == i then
                    lg.setColor(1, 1, 0.3, 0.8)
                    lg.circle("line", ex, ey + 24, 18)
                end
            end
            drawBar(ex - 34, ey + 30, 68, 8, e.hp / e.maxhp, COLORS.bad)
            lg.setColor(COLORS.text)
            lg.setFont(GAME.fonts.tiny)
            lg.printf(e.name, ex - 50, ey + 40, 100, "center")
            if e.status.poison and e.status.poison > 0 then lg.setColor(0.5,1,0.5) lg.print("PSN", ex - 28, ey + 52) end
            if e.status.burn and e.status.burn > 0 then lg.setColor(1,0.5,0.2) lg.print("BRN", ex, ey + 52) end
            if e.status.stun and e.status.stun > 0 then lg.setColor(1,0.9,0.3) lg.print("STN", ex + 22, ey + 52) end
        end
    end
    lg.setFont(GAME.fonts.small)

    -- Floaters/particles (reused)
    for _, pt in ipairs(g.particles) do
        if pt.float and pt.text then
            lg.setColor(pt.color)
            lg.print(pt.text, pt.x, pt.y)
        end
    end

    -- Status panels
    drawPanel(14, 14, 308, 88)
    lg.setColor(COLORS.text) lg.print(g.player.name .. "  Lv." .. g.player.level, 22, 20)
    drawBar(22, 44, 220, 12, b.p.hp / b.p.maxhp, COLORS.good)
    drawBar(22, 60, 220, 12, b.p.mp / b.p.maxmp, COLORS.mana)
    lg.setColor(COLORS.text) lg.print(string.format("HP %d/%d", b.p.hp, b.p.maxhp), 248, 41)
    lg.print(string.format("MP %d/%d", b.p.mp, b.p.maxmp), 248, 57)
    if b.p.status.poison and b.p.status.poison > 0 then lg.setColor(0.5,1,0.5) lg.print("Poison", 22, 76) end
    if b.p.status.burn and b.p.status.burn > 0 then lg.setColor(1,0.5,0.2) lg.print("Burn", 78, 76) end
    if b.p.status.stun and b.p.status.stun > 0 then lg.setColor(1,0.9,0.3) lg.print("Stun", 126, 76) end
    if b.p.status.regen and b.p.status.regen > 0 then lg.setColor(0.5,1,0.9) lg.print("Regen", 170, 76) end

    -- Command and logs
    drawPanel(14, sh - 182, 420, 168)
    drawPanel(442, sh - 182, sw - 456, 168)
    local cy = sh - 174
    lg.setColor(COLORS.text)
    if b.state == "command" then
        lg.print("Choose Action", 22, cy)
        local opts = {"Attack", "Skill", "Item", "Guard", "Flee"}
        for i, s in ipairs(opts) do
            if i == b.cmdIndex then lg.setColor(1, 0.95, 0.45) else lg.setColor(COLORS.text) end
            lg.print((i == b.cmdIndex and "> " or "  ") .. s, 28, cy + 20 + (i - 1) * 24)
        end
    elseif b.state == "skills" then
        lg.print("Skills", 22, cy)
        for i, sid in ipairs(g.player.skills) do
            local sk = SKILLS[sid]
            if i == b.skillIndex then lg.setColor(1, 0.95, 0.45) else lg.setColor(COLORS.text) end
            lg.print((i == b.skillIndex and "> " or "  ") .. sk.name .. " (" .. sk.cost .. " MP)", 28, cy + 20 + (i - 1) * 18)
        end
        local sk = SKILLS[g.player.skills[b.skillIndex]]
        if sk then lg.setColor(COLORS.dim) lg.printf(sk.desc, 220, cy + 20, 200) end
    elseif b.state == "items" then
        local items = battleUsableItems(g)
        lg.print("Items", 22, cy)
        for i, ent in ipairs(items) do
            if i == b.itemIndex then lg.setColor(1,0.95,0.45) else lg.setColor(COLORS.text) end
            lg.print((i == b.itemIndex and "> " or "  ") .. ent.item.name .. " x" .. ent.count, 28, cy + 20 + (i - 1) * 18)
        end
        local ent = items[b.itemIndex]
        if ent then lg.setColor(COLORS.dim) lg.printf(ent.item.desc, 220, cy + 20, 200) end
    elseif b.state == "target" then
        lg.print("Select Target", 22, cy)
        lg.setColor(COLORS.dim)
        lg.printf("Arrow keys to choose enemy. Enter to confirm.", 28, cy + 24, 380)
        if b.subAction and b.subAction.kind == "skill" then
            local sk = SKILLS[b.subAction.id]
            if sk then lg.printf(sk.name .. ": " .. sk.desc, 28, cy + 48, 380) end
        elseif b.subAction and b.subAction.kind == "item" then
            local it = ITEMS[b.subAction.id]
            if it then lg.printf(it.name .. ": " .. it.desc, 28, cy + 48, 380) end
        end
    elseif b.state == "enemyAct" then
        lg.print("Enemies acting...", 22, cy)
        lg.setColor(COLORS.dim)
        lg.printf("Prepare your next turn.", 28, cy + 24, 380)
    end

    lg.setColor(COLORS.text)
    lg.print("Battle Log", 450, cy)
    lg.setFont(GAME.fonts.tiny)
    for i = 1, min(8, #b.log) do
        local line = b.log[i]
        lg.setColor(i == 1 and {1, 0.95, 0.6} or COLORS.dim)
        lg.printf("• " .. line, 450, cy + 20 + (i - 1) * 16, sw - 470)
    end
    lg.setFont(GAME.fonts.small)
end

local function drawMenu(g)
    if not g.menu.open then return end
    local sw, sh = lg.getDimensions()
    local x, y, w, h = 34, 30, sw - 68, sh - 60
    drawPanel(x, y, w, h, 0.72)

    local tabs = getMenuTabNames()
    lg.setColor(COLORS.text)
    lg.setFont(GAME.fonts.small)
    lg.print("Menu", x + 12, y + 10)
    for i, t in ipairs(tabs) do
        local tx = x + 70 + (i - 1) * 90
        if i == g.menu.tab then lg.setColor(1, 0.95, 0.45) else lg.setColor(COLORS.dim) end
        lg.print(t, tx, y + 10)
    end

    local leftX, topY = x + 12, y + 40
    local p = g.player
    local st = calcPlayerStats(p)

    if g.menu.tab == 1 then
        local list = menuInventoryList(g)
        drawPanel(leftX, topY, 330, h - 52)
        drawPanel(leftX + 340, topY, w - 364, h - 52)
        lg.setColor(COLORS.text) lg.print("Inventory", leftX + 10, topY + 8)
        lg.setFont(GAME.fonts.tiny)
        for i, ent in ipairs(list) do
            local yy = topY + 30 + (i - 1) * 17
            if yy > topY + h - 75 then break end
            lg.setColor(i == g.menu.cursor and {1,0.95,0.45} or COLORS.text)
            lg.print((i == g.menu.cursor and "> " or "  ") .. ent.item.name .. " x" .. ent.count, leftX + 8, yy)
        end
        local ent = list[g.menu.cursor]
        if ent then
            lg.setColor(COLORS.text) lg.printf(ent.item.name, leftX + 350, topY + 12, w - 384)
            lg.setColor(COLORS.dim) lg.printf(ent.item.desc, leftX + 350, topY + 32, w - 384)
            lg.setColor(COLORS.gold) lg.print("Sell value: " .. (ent.item.value or 0) .. "g", leftX + 350, topY + 56)
            if ent.item.kind == "consumable" then lg.setColor(0.6,1,0.6) lg.print("Enter: Use", leftX + 350, topY + 76) end
        end
        lg.setFont(GAME.fonts.small)
    elseif g.menu.tab == 2 then
        local list = menuEquipList(g)
        drawPanel(leftX, topY, 360, h - 52)
        drawPanel(leftX + 370, topY, w - 394, h - 52)
        lg.setColor(COLORS.text) lg.print("Equipment Bag", leftX + 10, topY + 8)
        lg.setFont(GAME.fonts.tiny)
        for i, ent in ipairs(list) do
            local yy = topY + 30 + (i - 1) * 17
            if yy > topY + h - 75 then break end
            lg.setColor(i == g.menu.cursor and {1,0.95,0.45} or COLORS.text)
            lg.print((i == g.menu.cursor and "> " or "  ") .. ent.eq.name .. " [" .. ent.eq.slot .. "] x" .. ent.count, leftX + 8, yy)
        end
        local ent = list[g.menu.cursor]
        lg.setColor(COLORS.text)
        lg.print("Equipped", leftX + 380, topY + 8)
        lg.setColor(COLORS.dim)
        lg.print("Weapon: " .. (EQUIPMENT[p.equipment.weapon].name), leftX + 380, topY + 28)
        lg.print("Armor:  " .. (EQUIPMENT[p.equipment.armor].name), leftX + 380, topY + 44)
        lg.print("Charm:  " .. (EQUIPMENT[p.equipment.charm].name), leftX + 380, topY + 60)
        if ent then
            lg.setColor(COLORS.text)
            lg.print(ent.eq.name, leftX + 380, topY + 92)
            lg.setColor(COLORS.dim)
            lg.printf(ent.eq.desc, leftX + 380, topY + 110, w - 420)
            lg.setColor(COLORS.text)
            lg.print(string.format("ATK %+d   DEF %+d   MAG %+d   SPD %+d", ent.eq.atk or 0, ent.eq.def or 0, ent.eq.mag or 0, ent.eq.spd or 0), leftX + 380, topY + 138)
            lg.setColor(0.6,1,0.6) lg.print("Enter: Equip", leftX + 380, topY + 160)
        end
        lg.setFont(GAME.fonts.small)
    elseif g.menu.tab == 3 then
        drawPanel(leftX, topY, 340, h - 52)
        drawPanel(leftX + 350, topY, w - 374, h - 52)
        lg.print("Skills", leftX + 10, topY + 8)
        lg.setFont(GAME.fonts.tiny)
        for i, sid in ipairs(p.skills) do
            local sk = SKILLS[sid]
            local yy = topY + 30 + (i - 1) * 18
            lg.setColor(i == g.menu.cursor and {1,0.95,0.45} or COLORS.text)
            lg.print((i == g.menu.cursor and "> " or "  ") .. sk.name .. " (" .. sk.cost .. " MP)", leftX + 8, yy)
        end
        local sk = SKILLS[p.skills[g.menu.cursor]]
        if sk then
            lg.setColor(COLORS.text) lg.print(sk.name, leftX + 360, topY + 8)
            lg.setColor(COLORS.dim) lg.printf(sk.desc, leftX + 360, topY + 30, w - 398)
            lg.setColor(COLORS.text)
            lg.print("Target: " .. sk.target, leftX + 360, topY + 62)
            lg.print("Type: " .. sk.kind, leftX + 360, topY + 78)
        end
        lg.setFont(GAME.fonts.small)
    elseif g.menu.tab == 4 then
        drawPanel(leftX, topY, w - 24, h - 52)
        lg.print("Stats", leftX + 10, topY + 8)
        lg.setColor(COLORS.dim)
        lg.print("Spend points: 1=Might  2=Mind  3=Agility", leftX + 10, topY + 28)
        lg.setColor(COLORS.text)
        lg.print("Unspent points: " .. p.statPoints, leftX + 10, topY + 48)
        lg.print(string.format("Might: %d   Mind: %d   Agility: %d", p.bonus.might or 0, p.bonus.mind or 0, p.bonus.agility or 0), leftX + 10, topY + 68)
        lg.print(string.format("HP %d/%d  MP %d/%d", p.hp, st.maxhp, p.mp, st.maxmp), leftX + 10, topY + 88)
        lg.print(string.format("ATK %d   DEF %d   MAG %d   SPD %d", st.atk, st.def, st.mag, st.spd), leftX + 10, topY + 108)
        lg.print("Gold: " .. p.gold .. "   XP: " .. p.xp .. "/" .. p.xpToNext, leftX + 10, topY + 128)
        if p.blessing then
            lg.setColor(0.7, 0.95, 1.0)
            lg.print("Blessing: " .. (p.blessing.name or "") .. " (" .. (p.blessing.battlesLeft or 0) .. " battles)", leftX + 10, topY + 150)
        end
    elseif g.menu.tab == 5 then
        drawPanel(leftX, topY, 390, h - 52)
        drawPanel(leftX + 400, topY, w - 424, h - 52)
        lg.print("Crafting (Town only)", leftX + 10, topY + 8)
        lg.setFont(GAME.fonts.tiny)
        for i, r in ipairs(RECIPES) do
            local yy = topY + 30 + (i - 1) * 17
            if yy > topY + h - 75 then break end
            lg.setColor(i == g.menu.cursor and {1,0.95,0.45} or COLORS.text)
            lg.print((i == g.menu.cursor and "> " or "  ") .. r.name, leftX + 8, yy)
        end
        local r = RECIPES[g.menu.cursor]
        if r then
            lg.setColor(COLORS.text)
            lg.print(r.name, leftX + 410, topY + 8)
            lg.setColor(COLORS.dim)
            local reqs = {}
            for id, n in pairs(r.req) do table.insert(reqs, (ITEMS[id] and ITEMS[id].name or EQUIPMENT[id].name) .. " x" .. n .. " (have " .. ((p.items[id] or p.gearOwned[id] or 0)) .. ")") end
            table.sort(reqs)
            lg.print("Requires:", leftX + 410, topY + 30)
            for i, s in ipairs(reqs) do lg.print("- " .. s, leftX + 410, topY + 48 + (i - 1) * 16) end
            local outs = {}
            for id, n in pairs(r.out) do table.insert(outs, (ITEMS[id] and ITEMS[id].name or EQUIPMENT[id].name) .. " x" .. n) end
            lg.print("Produces:", leftX + 410, topY + 100)
            for i, s in ipairs(outs) do lg.print("- " .. s, leftX + 410, topY + 118 + (i - 1) * 16) end
            lg.setColor(0.6,1,0.6) lg.print("Enter: Craft", leftX + 410, topY + 154)
        end
        lg.setFont(GAME.fonts.small)
    elseif g.menu.tab == 6 then
        drawPanel(leftX, topY, 400, h - 52)
        drawPanel(leftX + 410, topY, w - 434, h - 52)
        lg.print("Journal", leftX + 10, topY + 8)
        lg.setFont(GAME.fonts.tiny)
        for i, q in ipairs(g.quests) do
            local yy = topY + 30 + (i - 1) * 18
            if yy > topY + h - 75 then break end
            local col = q.state == "done" and {0.45, 0.95, 0.45} or (q.state == "ready" and {1,0.9,0.45} or (q.type == "main" and {0.95,0.85,0.5} or COLORS.text))
            lg.setColor(i == g.menu.cursor and {1,1,1} or col)
            local mark = q.state == "done" and "[Done] " or (q.state == "ready" and "[Ready] " or "")
            lg.print((i == g.menu.cursor and "> " or "  ") .. mark .. q.name, leftX + 8, yy)
        end
        local q = g.quests[g.menu.cursor]
        if q then
            lg.setColor(COLORS.text)
            lg.print(q.name, leftX + 420, topY + 8)
            lg.setColor(COLORS.dim)
            lg.printf(q.desc or "", leftX + 420, topY + 30, w - 454)
            lg.print("Status: " .. q.state, leftX + 420, topY + 64)
            if q.id == "main_rifts" and q.progress then
                lg.print("Verdant: " .. (q.progress.forest and "Cleared" or "Open"), leftX + 420, topY + 84)
                lg.print("Ember:   " .. (q.progress.ember and "Cleared" or "Open"), leftX + 420, topY + 100)
                lg.print("Crystal: " .. (q.progress.crystal and "Cleared" or "Open"), leftX + 420, topY + 116)
            elseif q.id == "bounty" then
                lg.print("Target: " .. ENEMIES[q.enemy].name, leftX + 420, topY + 84)
                lg.print("Progress: " .. (q.progress or 0) .. "/" .. (q.count or 0), leftX + 420, topY + 100)
            end
        end
        lg.setFont(GAME.fonts.small)
    elseif g.menu.tab == 7 then
        drawPanel(leftX, topY, w - 24, h - 52)
        lg.print("Map", leftX + 10, topY + 8)
        local mapX, mapY, mapW, mapH = leftX + 10, topY + 30, w - 44, h - 90
        lg.setColor(0.03,0.03,0.04) lg.rectangle("fill", mapX, mapY, mapW, mapH)
        local cellW = mapW / g.world.w
        local cellH = mapH / g.world.h
        for yy = 1, g.world.h do
            for xx = 1, g.world.w do
                if g.player.explored[yy .. ":" .. xx] then
                    local t = g.world.tiles[yy][xx]
                    local b = BIOMES[t.biome]
                    local c = t.blocked and b.detail or b.ground
                    lg.setColor(c[1], c[2], c[3])
                    lg.rectangle("fill", mapX + (xx - 1) * cellW, mapY + (yy - 1) * cellH, cellW + 0.2, cellH + 0.2)
                end
            end
        end
        for _, o in ipairs(g.world.objects) do
            if o.type == "rift" and (not o.hidden) then
                lg.setColor(o.cleared and {0.6,0.6,0.6} or {1,0.5,0.2})
                lg.circle("fill", mapX + (o.x / (g.world.w * g.world.tile)) * mapW, mapY + (o.y / (g.world.h * g.world.tile)) * mapH, 3)
            end
        end
        lg.setColor(0.95,0.95,1.0)
        lg.circle("fill", mapX + (g.player.x / (g.world.w * g.world.tile)) * mapW, mapY + (g.player.y / (g.world.h * g.world.tile)) * mapH, 3)
        lg.setColor(COLORS.dim)
        lg.print("White = player, orange = active rifts", leftX + 10, topY + h - 74)
    elseif g.menu.tab == 8 then
        local opts = systemMenuOptions()
        drawPanel(leftX, topY, w - 24, h - 52)
        lg.print("System", leftX + 10, topY + 8)
        for i, s in ipairs(opts) do
            lg.setColor(i == g.menu.cursor and {1,0.95,0.45} or COLORS.text)
            lg.print((i == g.menu.cursor and "> " or "  ") .. s, leftX + 18, topY + 34 + (i - 1) * 22)
        end
        lg.setColor(COLORS.dim)
        lg.print("F5 Save / F9 Load also work in the world.", leftX + 18, topY + 150)
    end
end

local function drawDialog(g)
    if not g.dialog then return end
    local d = g.dialog
    local sw, sh = lg.getDimensions()
    drawPanel(sw * 0.12, sh * 0.58, sw * 0.76, sh * 0.30, 0.78)
    local x, y = sw * 0.12 + 14, sh * 0.58 + 10
    lg.setColor(1, 0.95, 0.45) lg.setFont(GAME.fonts.small)
    lg.print(d.title, x, y)
    lg.setColor(COLORS.text) lg.setFont(GAME.fonts.tiny)
    lg.printf(d.body, x, y + 20, sw * 0.76 - 28)
    for i, o in ipairs(d.options) do
        lg.setColor(i == d.cursor and {1,0.95,0.45} or COLORS.text)
        lg.print((i == d.cursor and "> " or "  ") .. o.label, x, y + 74 + (i - 1) * 18)
    end
    lg.setFont(GAME.fonts.small)
end

local function drawTitle()
    local sw, sh = lg.getDimensions()
    local t = GAME.time
    lg.clear(0.03, 0.035, 0.05)
    for i = 1, 24 do
        local y = (i * 36 + sin(t * 0.3 + i) * 12)
        lg.setColor(0.08 + i * 0.004, 0.10 + i * 0.004, 0.16 + i * 0.004)
        lg.rectangle("fill", 0, y, sw, 30)
    end
    -- decorative shapes
    for i = 1, 50 do
        local x = (i * 117 + t * 10) % (sw + 40) - 20
        local y = (i * 53) % sh
        lg.setColor(0.7, 0.85, 1.0, 0.05)
        lg.circle("line", x, y, 8 + ((i * 7) % 12))
    end

    lg.setFont(GAME.fonts.big)
    lg.setColor(0.95, 0.96, 1.0)
    lg.printf("RUNEBOUND FRONTIER", 0, sh * 0.18, sw, "center")
    lg.setFont(GAME.fonts.small)
    lg.setColor(0.75, 0.80, 0.90)
    lg.printf("Single-file RPG for LÖVE2D • Procedural visuals • Exploration + Boss Rifts + Crafting", 0, sh * 0.29, sw, "center")

    drawEntityShape(sw * 0.25, sh * 0.52, "player", t, 1.5, {0.9, 0.95, 1.0})
    drawEntityShape(sw * 0.5, sh * 0.49, "treant", t, 1.25, {0.55, 0.9, 0.45})
    drawEntityShape(sw * 0.75, sh * 0.50, "knight", t, 1.35, {0.95, 0.35, 0.75})

    local options = {"New Game", "Load Game", "Quit"}
    drawPanel(sw * 0.35, sh * 0.66, sw * 0.30, 110)
    for i, s in ipairs(options) do
        lg.setColor(i == GAME.titleIndex and {1, 0.95, 0.45} or COLORS.text)
        lg.printf((i == GAME.titleIndex and "> " or "  ") .. s, sw * 0.35, sh * 0.69 + (i - 1) * 28, sw * 0.30, "center")
    end
    lg.setColor(COLORS.dim)
    lg.printf("Enter to select • Arrow keys to navigate", 0, sh - 34, sw, "center")
end

local function drawGameOver(g)
    local sw, sh = lg.getDimensions()
    lg.clear(0.02, 0.02, 0.03)
    lg.setFont(GAME.fonts.big)
    lg.setColor(1, 0.35, 0.35)
    lg.printf("YOU FELL", 0, sh * 0.28, sw, "center")
    lg.setFont(GAME.fonts.small)
    lg.setColor(COLORS.text)
    lg.printf("Press Enter to return to title", 0, sh * 0.50, sw, "center")
end

function love.load()
    love.window.setTitle("Runebound Frontier")
    love.window.setMode(1100, 700, {resizable = true, minwidth = 900, minheight = 620})
    GAME.fonts.big = lg.newFont(30)
    GAME.fonts.small = lg.newFont(14)
    GAME.fonts.tiny = lg.newFont(12)
    lg.setFont(GAME.fonts.small)
    love.math.setRandomSeed(os.time())
end

function love.update(dt)
    GAME.time = GAME.time + dt
    if GAME.msgTimer > 0 then GAME.msgTimer = GAME.msgTimer - dt if GAME.msgTimer <= 0 then GAME.msg = nil end end

    local g = GAME.game
    if GAME.scene == "world" and g then
        updateWorld(g, dt)
    elseif GAME.scene == "battle" and g then
        updateBattle(g, dt)
    end
end

function love.draw()
    if GAME.scene == "title" then
        drawTitle()
        return
    end

    local g = GAME.game
    if not g then
        lg.clear(0.03, 0.03, 0.04)
        return
    end

    if GAME.scene == "world" then
        drawWorld(g)
        drawMenu(g)
        drawDialog(g)
        if g.player.flags.wonGame then
            local sw, sh = lg.getDimensions()
            drawPanel(sw - 350, sh - 138, 340, 76)
            lg.setColor(0.7, 1.0, 0.75)
            lg.print("Main story complete", sw - 338, sh - 132)
            lg.setColor(COLORS.dim)
            lg.printf("Continue exploring, crafting, and taking bounties.", sw - 338, sh - 112, 324)
        end
    elseif GAME.scene == "battle" then
        drawBattle(g)
    elseif GAME.scene == "gameover" then
        drawGameOver(g)
    end
end

function love.keypressed(key)
    if GAME.scene == "title" then
        if key == "up" then GAME.titleIndex = uiListMove(GAME.titleIndex, -1, 3) end
        if key == "down" then GAME.titleIndex = uiListMove(GAME.titleIndex, 1, 3) end
        if key == "l" then GAME.titleIndex = 2 end
        if key == "return" or key == "kpenter" then
            if GAME.titleIndex == 1 then
                local seed = random(100000, 999999)
                GAME.game = makeGame(seed)
                GAME.scene = "world"
                notify("Welcome to Hearthhome")
            elseif GAME.titleIndex == 2 then
                local g = loadSavedGame()
                if g then GAME.game = g; GAME.scene = "world" end
            elseif GAME.titleIndex == 3 then
                love.event.quit()
            end
        end
        return
    end

    local g = GAME.game
    if not g then return end

    if GAME.scene == "world" then
        if g.dialog then handleDialogKey(g, key) return end
        if g.menu.open then handleMenuKey(g, key) return end

        if key == "e" then handleWorldInteract(g) return end
        if key == "i" or key == "tab" then openMenu(g, 1) return end
        if key == "j" then openMenu(g, 6) return end
        if key == "m" then openMenu(g, 7) return end
        if key == "f5" then saveGame(g) return end
        if key == "f9" then
            local ng = loadSavedGame()
            if ng then GAME.game = ng; GAME.scene = "world" end
            return
        end
        if key == "escape" then openMenu(g, 8) return end
    elseif GAME.scene == "battle" then
        handleBattleKey(g, key)
    elseif GAME.scene == "gameover" then
        if key == "return" or key == "kpenter" then GAME.scene = "title" GAME.game = nil end
    end
end
