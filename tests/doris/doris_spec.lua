local plugin = require("doris")

describe("setup", function()
  it("works with default", function()
    assert(plugin.doris() == plugin.config.doris, "Default doris")
  end)

  it("works with custom", function()
    plugin.setup({ doris = { test = "ok" } })
    assert(plugin.doris().test == "ok", "Custom doris")
  end)
end)
