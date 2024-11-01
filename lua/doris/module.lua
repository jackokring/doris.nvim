-- pure module with no install specifics
-- look up for 'key' in list of tables `plist'

---@class DorisPureModule
local M = {}

---switch statement
---@param is any
---@return SwitchStatement
M.switch = function(is)
  ---@class SwitchStatement
  ---@field Value any
  ---@field Functions { [any]: fun(is: any): nil }
  local Table = {
    Value = is,
    Functions = {}, -- dictionary as any value
  }

  ---each case
  ---@param testElement any
  ---@param callback fun(is: any): nil
  ---@return SwitchStatement
  Table.case = function(testElement, callback)
    assert(not Table.Functions[testElement], "Duplicate case in switch")
    Table.Functions[testElement] = callback
    return Table
  end

  ---remove case
  ---@param testElement any
  ---@return SwitchStatement
  Table.uncase = function(testElement)
    -- can remove it many times
    Table.Functions[testElement] = nil
    return Table
  end

  ---use newer switch value
  ---@param testElement any
  ---@return SwitchStatement
  Table.reswitch = function(testElement)
    Table.Value = testElement
    return Table
  end

  ---default case
  ---@param callback fun(is: any): nil
  Table.default = function(callback)
    local Case = Table.Functions[Table.Value]
    if Case then
      -- allowing duplicate function usage
      Case(Table.Value)
    else
      callback(Table.Value)
    end
  end

  return Table
end

---modulo statement
---@param over integer
---@return ModuloStatement
M.modulo = function(over)
  ---@class ModuloStatement
  ---@field Value integer
  ---@field Functions (fun(mod: integer): nil)[]
  ---@field Modulos integer[]
  ---@field Random integer
  local Table = {
    Value = over,
    Functions = {}, -- dictionary as any value
    Modulos = {},
    Random = math.random(over),
  }

  ---each case
  ---@param divElement integer
  ---@param callback fun(mod: integer): nil
  ---@return ModuloStatement
  Table.case = function(divElement, callback)
    Table.Functions[#Table.Functions + 1] = callback
    Table.Modulos[#Table.Modulos + 1] = divElement
    return Table
  end

  ---remove case
  ---@param indexElement integer
  ---@return ModuloStatement
  Table.uncase = function(indexElement)
    table.remove(Table.Functions, indexElement)
    table.remove(Table.Modulos, indexElement)
    return Table
  end

  ---run
  Table.run = function()
    for k, v in ipairs(Table.Functions) do
      v(Table.Random % Table.Modulos[k])
    end
    Table.Random = math.random(Table.Value)
  end

  return Table
end

return M
