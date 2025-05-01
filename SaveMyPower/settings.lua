data:extend({
  {
    type = "int-setting",
    name = "minimum-energy-to-retain-accumulator",
    setting_type = "runtime-global",
    default_value = 1,
    minimum_value = 0,
    maximum_value = 10,
    order = "a[a]"
  },
  -- {
  --   type = "int-setting",
  --   name = "minimum-energy-to-retain-battery",
  --   setting_type = "runtime-global",
  --   default_value = 3,
  --   minimum_value = 0,
  --   maximum_value = 10,
  --   order = "a[a]"
  -- },
  {
    type = "string-setting",
    name = "accumulator-blacklist",
    setting_type = "startup",
    default_value = "",
    allow_blank = true,
    order = "b[a]"
  },
  {
    type = "bool-setting",
    name = "accumulator-blacklist-as-whitelist",
    setting_type = "startup",
    default_value = false,
    order = "b[b]"
  },
  -- {
  --   type = "string-setting",
  --   name = "battery-blacklist",
  --   setting_type = "startup",
  --   default_value = "",
  --   allow_blank = true,
  --   order = "c[a]"
  -- },
  -- {
  --   type = "bool-setting",
  --   name = "battery-blacklist-as-whitelist",
  --   setting_type = "startup",
  --   default_value = true,
  --   order = "c[b]"
  -- },
  {
    type = "bool-setting",
    name = "retain-on-player-mined",
    setting_type = "runtime-global",
    default_value = true,
    order = "d[a]"
  },
  {
    type = "bool-setting",
    name = "retain-on-robot-mined",
    setting_type = "runtime-global",
    default_value = true,
    order = "d[b]"
  },
  {
    type = "bool-setting",
    name = "debug-show-item-info",
    setting_type = "runtime-global",
    default_value = false,
    order = "f"
  }
})
