data:extend({
  {
    type = "bool-setting",
    name = "research-required",
    setting_type = "startup",
    default_value = true,
    order = "a[a]"
  },
  {
    type = "int-setting",
    name = "minimum-energy-retain-accumulator",
    setting_type = "runtime-global",
    default_value = 10,
    minimum_value = 0,
    maximum_value = 100,
    order = "a[b]"
  },
  {
    type = "int-setting",
    name = "energy-stack-jumps",
    setting_type = "runtime-global",
    default_value = 10,
    minimum_value = 0,
    maximum_value = 100,
    order = "a[c]"
  },
  {
    type = "string-setting",
    name = "accumulator-blacklist",
    setting_type = "runtime-global",
    default_value = "",
    allow_blank = true,
    order = "b[a]"
  },
  {
    type = "bool-setting",
    name = "accumulator-blacklist-as-whitelist",
    setting_type = "runtime-global",
    default_value = false,
    order = "b[b]"
  },
  {
    type = "bool-setting",
    name = "description-show-bar",
    setting_type = "runtime-global",
    default_value = true,
    order = "c[a]"
  },
  {
    type = "string-setting",
    name = "description-bar-filled-color",
    setting_type = "runtime-global",
    default_value = "cyan",
    allow_blank = false,
    order = "c[b]"
  },
  {
    type = "string-setting",
    name = "description-bar-empty-color",
    setting_type = "runtime-global",
    default_value = "gray",
    allow_blank = false,
    order = "c[c]"
  },
  {
    type = "string-setting",
    name = "description-bar-decorator-color",
    setting_type = "runtime-global",
    default_value = "white",
    allow_blank = false,
    order = "c[d]"
  },
  {
    type = "int-setting",
    name = "description-bar-length",
    setting_type = "runtime-global",
    default_value = 10,
    minimum_value = 1,
    maximum_value = 100,
    order = "c[e]"
  },
  {
    type = "bool-setting",
    name = "description-show-percentage",
    setting_type = "runtime-global",
    default_value = true,
    order = "d[a]"
  },
  {
    type = "string-setting",
    name = "description-percentage-color",
    setting_type = "runtime-global",
    default_value = "cyan",
    allow_blank = false,
    order = "d[b]"
  },
  {
    type = "string-setting",
    name = "description-string",
    setting_type = "runtime-global",
    default_value = "<=>",
    allow_blank = false,
    order = "d[c]"
  },
  {
    type = "bool-setting",
    name = "retain-on-player-mined",
    setting_type = "runtime-global",
    default_value = true,
    order = "e[a]"
  },
  {
    type = "bool-setting",
    name = "retain-on-robot-mined",
    setting_type = "runtime-global",
    default_value = true,
    order = "e[b]"
  },
  {
    type = "bool-setting",
    name = "debug",
    setting_type = "runtime-global",
    default_value = false,
    order = "f"
  }
})
