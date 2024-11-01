-- pure module with no install specifics
-- look up for 'key' in list of tables `plist'

---@class DorisPureModule
local M = {}

---switch statement
---@param element any
---@return SwitchStatement
M.switch = function(element)
  ---@class SwitchStatement
  ---@field Value any
  ---@field Functions { [any]: fun(is: any): nil }
  local Table = {
    Value = element,
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

return M
