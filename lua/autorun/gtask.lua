-- https://github.com/Be1zebub/gtask/blob/master/lua/autorun/gtask.lua

--[[
MIT License

Copyright (c) 2021 Aleksandrs Filipovskis & Be1zebub

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

if gtask then return end

local remove, CurTime, isstring, isnumber, isfunction, assert, next = table.remove, CurTime, isstring, isnumber, isfunction, assert, next

local stored, tick_stored, named_tasks = {}, {}, {}

local function CallTask(index, curtime)
    local data = stored[index]

    local diff, repeats = curtime - data.started, data.repeats

    if data.infinite then
        data.func()
        return true
    elseif diff >= data.time then
        if repeats > 0 then
            data.started = curtime
            repeats = repeats - 1
        end

        data.func()

        if repeats < 1 then
            remove(stored, index)
            if data.onfinish then data.onfinish() end
        else
            data.repeats = repeats
        end

        return true
    end

    return false
end

local function CallTickTask(index)
    local data = tick_stored[index]
    if data == nil then return false end

    data.func()

    data.repeats = data.repeats - 1
    if data.repeats <= 0 then
        remove(tick_stored, index)
    end

    return true
end

hook.Add("Think", "gtask.Think", function()
    local ct = CurTime()
    for index = 1, #stored do
        CallTask(index, ct)
    end

    CallTickTask(
        next(tick_stored)
    )
end)

gtask = {}

--- Create a task
---@param time number
---@param func function
---@param repeats number
---@param onfinish function
function gtask.Create(time, func, repeats, onfinish)
    assert(isnumber(time), "<time> should be a number")
    assert(isfunction(func), "<func> must be a function")

    repeats = repeats or 1

    local id = #stored + 1
    stored[id] = {
        started = CurTime(),
        time = time,
        func = func,
        repeats = repeats,
        infinite = repeats == 0,
        onfinish = onfinish
    }
    
    return id
end

--- Create a named task
---@param name string
---@param time number
---@param func function
---@param repeats number
---@param onfinish function
function gtask.CreateNamed(name, time, func, repeats, onfinish)
    gtask.RemoveNamed(name)

    named_tasks[name] = gtask.Create(time, func, repeats, function()
        named_tasks[name] = nil
        if onfinish then onfinish() end
    end)
end

--- Create a tick-task (1 tick = 1 task running)
---@param time number
---@param func function
---@return ticktaskid number
function gtask.CreateTick(time, func, repeats)
    assert(isnumber(time), "<time> should be a number")
    assert(isfunction(func), "<func> must be a function")

    local id = #tick_stored + 1
    tick_stored[id] = {
        func = func,
        repeats = repeats or 1
    }

    return id
end

--- Force call task by index
---@param index number
---@param isticktask boolean
---@return issucess boolean
function gtask.Call(index, tick)
    return (tick and CallTickTask or CallTask)(index, tick and CurTime())
end

--- Remove task by index
---@param index number
---@return removedtask table
function gtask.Remove(index, tick)
    return remove(tick and tick_stored or stored, index)
end

--- Remove named task
---@param name string
---@return removedtask table
function gtask.RemoveNamed(name)
    local index = named_tasks[name]
    if index then
        named_tasks[name] = nil
        return gtask.Remove(index)
    end
end

--- Return all tasks
---@return tasks table
---@return ticktasks table
---@return namedtasks tabke
function gtask.GetTable()
    return stored, tick_stored, named_tasks
end
