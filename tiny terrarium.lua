-- tiny terrarium
-- by helado de brownie

function _init()
    -- constants

    acol = {
        block   = 5,
        bug     = 8,
        sand    = 15,
        clay    = 4,
    }

    spdspr = {
        fast    = 9,
        slow    = 10,
        stop    = 11,
    }

    mspr = {
        overwrite   = 12,
        underwrite  = 13,
        erase       = 14,
    }

    cap = 32

    bdata = {
        tiny    = {2,   1,      1},
        small   = {3,   2,      2},
        medium  = {4,   3,      3},
        big     = {5,   4,      4},
        huge    = {6,   5,      5},
        column  = {7,   1,      cap},
        row     = {8,   cap,    1},
    }

    scale = 128 / cap
    cs = cap * scale

    -- state

    grid = new_grid(cap, cap)
    queue = {}
    x, y = flr(cap / 2), flr(cap / 2)

    option = enum(
        'atom',
        'brush',
        'cursor speed',
        'cursor mode',
        'sim. speed',
    nil)

    atom = enum(
        'block',
        'clay',
        'sand',
    nil)

    brush = enum(
        'tiny',
        'small',
        'medium',
        'big',
        'huge',
        'column',
        'row',
    nil)

    cspeed = enum('fast', 'slow')

    cmode = enum(
        'overwrite',
        'underwrite',
        'erase',
    nil)

    sspeed = enum(
        'fast',
        'slow',
        'stop',
    nil)

    simulator = cocreate(simulate)
    bug_rate = 4096
    --bug_rate = 0 / 0
end

function _update60()
    -- simulation

    coresume(simulator)

    -- controls

    if btn(4) then
        if (btnp(2)) option:cycle(-1)
        if (btnp(3)) option:cycle()
        local o = option()
        local t
        if (o == 'atom') t = atom
        if (o == 'brush') t = brush
        if (o == 'cursor speed') t = cspeed
        if (o == 'cursor mode') t = cmode
        if (o == 'sim. speed') t = sspeed
        if (btnp(0)) t:cycle(-1)
        if (btnp(1)) t:cycle( 1)
    else
        local b = btn
        if (cspeed() == 'slow') b = btnp
        if (b(0)) x -= 1
        if (b(1)) x += 1
        if (b(2)) y -= 1
        if (b(3)) y += 1
        local bd = bdata[brush()]
        local sx, sy = bd[2], bd[3]
        x = mid(0, x, cap - sx)
        y = mid(0, y, cap - sy)

        if btn(5) then
            local a = atom()
            local m = cmode()

            for i = 0, sx - 1 do
                for j = 0, sy - 1 do
                    if m == 'erase' then
                        if (grid(x + i, y + j) == a) grid:set(x + i, y + j, nil)
                    elseif grid:is_air(x + i, y + j) or m == 'overwrite' then
                        if(grid(x + i, y + j) ~= 'bug') grid:set(x + i, y + j, a)
                    end
                end
            end
        end
    end
end

function _draw()
    -- background

    cls(12)

    -- grid

    sspr(0, 64, cap, cap, 0, 0, cs, cs)

    if btn(4) then
        -- options

        camera(0, -104)
        rectfill(0, 0, 127, 23, 1)
        spr(0, 7, 0)
        local o = option()
        print(o, 7, 9, 7)
        spr(0, 7, 16, 1, 1, false, true)
        spr(1, 55, 7)
        local a = atom()

        if o == 'atom' then
         print(a, 71, 9, acol[a])
        elseif o == 'brush' then
            pal(7, 0)
            pal(5, acol[a])
            local br = brush()
            spr(bdata[br][1], 71, 7)
            print(br, 80, 9, 15)
            pal()
        elseif o == 'cursor speed' then
            local s = cspeed()
            spr(spdspr[s], 71, 7)
            print(s, 80, 9, 15)
        elseif o == 'cursor mode' then
            local m = cmode()
            spr(mspr[m], 71, 7)
            print(m, 80, 9, 15)
        elseif o == 'sim. speed' then
            local s = sspeed()
            spr(spdspr[s], 71, 7)
            print(s, 80, 9, 15)
        end

        spr(1, 119, 7, 1, 1, true)
    else
        -- cursor

        camera(-x * scale, -y * scale)
        color(7)
        local bd = bdata[brush()]
        local sx, sy = bd[2] * scale, bd[3] * scale
        rect(-1, -1, sx, sy, 0)
    end
    camera()
end

function simulate()
    while true do
        local ss = sspeed()

        if ss ~= 'stop' then
            -- advance atoms

            grid:each(iterate)

            for k, e in pairs(queue) do
                grid:swap(e.x1, e.y1, e.x2, e.y2)
                queue[k] = nil
            end

            -- spawn bugs

            if flr(rnd(bug_rate)) == 0 then
                local rx = flr(rnd(cap))
                local ry = flr(rnd(cap))
                if grid(rx, ry) == 'sand' then
                    grid:set(rx, ry, 'bug')
                    bug_rate /= 2
                end
            end
        end

        yield()

        if ss == 'slow' then
            yield()
            yield()
            yield()
        end
    end
end

function iterate(p, x, y)
    if p ~= "block" and grid:is_air(x, y + 1) then
        order(x, y, x, y + 1)
    elseif p == 'sand' then
        local r = choose{-1, 1}

        if grid:is_air(x + r, y + 1) then
            order(x, y, x + r, y + 1)
        elseif grid:is_air(x - r, y + 1) then
            order(x, y, x - r, y + 1)
        end
    elseif p == 'bug' then
        local r = flr(rnd(32))
        local rx = choose{-1, 0, 1}
        local ry = choose{-1, 0, 1}

        if r == 0 and grid:is_in_bounds(x + rx, y + ry) and
        grid(x + rx, y + ry) ~= "block" then
            order(x, y, x + rx, y + ry)
        end
    end
end

function new_grid(w, h)
    local es = {}
    local m = {}

    function m:__call(x, y)
        return es[xy_to_s(x, y)]
    end

    local r = setmetatable({}, m)

    function r:each(f)
        for k, v in pairs(es) do
            f(v, 0 + sub(k, 1, 3), 0 + sub(k, 4, 6))
        end
    end

    function r:set(x, y, v)
        es[xy_to_s(x, y)] = v
        sset(x, y + 64, acol[v])
    end

    function r:swap(x1, y1, x2, y2)
        local v1 = r(x1, y1)
        local v2 = r(x2, y2)
        r:set(x1, y1, v2)
        r:set(x2, y2, v1)
    end

    function r:is_in_bounds(x, y)
        return mid(0, x, w - 1) == x and mid(0, y, h - 1) == y
    end

    function r:is_air(x, y)
        return r:is_in_bounds(x, y) and r(x, y) == nil
    end

    return r
end

function order(x1, y1, x2, y2)
    add(queue, {
        x1 = x1,
        y1 = y1,
        x2 = x2,
        y2 = y2,
    })
end

function enum(...)
    local t = {...}
    assert(#t > 0)
    local i = 1
    local m = {}

    function m:__call()
        return t[i]
    end

    local r = setmetatable({}, m)

    function r:cycle(n)
        n = n or 1
        i = (i + n - 1) % #t + 1
    end

    return r
end

function xy_to_s(x, y)
    return pad(x) .. pad(y)
end

function pad(s)
    s = '' .. s
    return sub('000', #s + 1, 3) .. s
end

function choose(t)
    return t[flr(rnd() * #t) + 1]
end
