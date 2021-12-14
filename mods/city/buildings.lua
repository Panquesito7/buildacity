local S = minetest.get_translator("city")

local models_path = minetest.get_modpath("city") .. "/models/"

city.buildings = {}

--[[
    city.register_building registers a new building 
    {
        mesh = "meshname.obj",
        cost = 1,                -- construction cost.
        length = 1,              -- length of the building in blocks.
        level = 1,               -- level (progress) of the building.
        self_sufficient = false, -- if true, the building does not require energy.
    }
]]--
function city.register_building(name, def)
    local level = def.level or 1
    if not city.buildings[level] then
        city.buildings[level] = {}
    end
    table.insert(city.buildings[level], name)

    local node_def = {
        mesh = def.mesh..".obj",
        drawtype = "mesh",
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {
            flammable = 1,
            cost = def.cost,
        },
        node_placement_prediction = "",
    }

    --open the mtl file and load the colors
    --read the Kd lines and place the colors into the tiles.
    --this works with models exported from AssetForge.
    local mtl_file = io.open(models_path..def.mesh..".mtl", "r")
    local tiles = {}
    for line in mtl_file:lines() do
        if line:sub(1,3) == "Kd " then
            local r, g, b = line:sub(4):match("(%S+) (%S+) (%S+)")
            table.insert(tiles, {name="city_white.png", color={
                r=255*r, g=255*g, b=255*b, a=255,
            }})
        end
    end
    node_def.tiles = tiles

    if def.length and def.length > 1 then
        node_def.selection_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.5, -0.5+1*def.length, 0.5, 0.5},
            },
        }
        node_def.collision_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.5, -0.5+1*def.length, 0.5, 0.5},
            },
        }
    end

    if not def.self_sufficient then
        local decayed_node_def = table.copy(node_def)

        --replace full windows with lit windows
        for i,v in ipairs(node_def.tiles) do
            if v == "city_window.png" then
                def.tiles[i] = "city_window_lit.png"
            end
        end

        def.on_timer = function(pos, elapsed)
            minetest.set_node(pos, {name = name.."_decayed", param2 = minetest.get_node(pos).param2})
        end

        minetest.register_node(name.."_decayed", decayed_node_def)
    end

    --setup a node timer that will decay the building
    --after a random amount of time.
    def.on_construct = function(pos, placer, itemstack, pointed_thing)
        minetest.get_node_timer(pos):start(math.random(1, 60))
    end

    minetest.register_node(name, node_def)
end

city.register_building("city:house_long_a", {
    mesh = "city_house_long_a",
    length = 2,
    self_sufficient = true,
})
city.register_building("city:house_a", {mesh = "city_house_a"})
city.register_building("city:house_b", {mesh = "city_house_b"})
city.register_building("city:house_c", {mesh = "city_house_c"})