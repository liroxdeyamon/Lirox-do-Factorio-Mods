data:extend({
  -- blacklists
  {
    type = "string-setting",
    name = "label-blacklists",
    setting_type = "runtime-global",
    default_value = "DUMMY",
    allow_blank = true,
    order = "a[a]"
  },
  {
    type = "string-setting",
    name = "default-blacklist",
    setting_type = "runtime-global",
    default_value = "",
    allow_blank = true,
    order = "a[b]"
  },
  {
    type = "string-setting",
    name = "entity-blacklist",
    setting_type = "runtime-global",
    default_value = "",
    allow_blank = true,
    order = "a[c]"
  },
  {
    type = "bool-setting",
    name = "entity-blacklist-as-whitelist",
    setting_type = "runtime-global",
    default_value = false,
    order = "a[d]"
  },
  {
    type = "string-setting",
    name = "equipment-blacklist",
    setting_type = "runtime-global",
    default_value = "",
    allow_blank = true,
    order = "a[e]"
  },
  {
    type = "bool-setting",
    name = "equipment-blacklist-as-whitelist",
    setting_type = "runtime-global",
    default_value = false,
    order = "a[g]"
  },
  -- energy
  {
    type = "string-setting",
    name = "label-energy",
    setting_type = "runtime-global",
    default_value = "DUMMY",
    allow_blank = true,
    order = "b[a]"
  },
  {
    type = "int-setting",
    name = "minimum-energy-to-retain",
    setting_type = "runtime-global",
    default_value = 10,
    minimum_value = 0,
    maximum_value = 100,
    order = "b[b]"
  },
  {
    type = "int-setting",
    name = "energy-stacking",
    setting_type = "runtime-global",
    default_value = 10,
    minimum_value = 0,
    maximum_value = 100,
    order = "b[c]"
  },

  -- description
  {
    type = "string-setting",
    name = "label-description",
    setting_type = "runtime-global",
    default_value = "DUMMY",
    allow_blank = true,
    order = "c[a]"
  },
  {
    type = "bool-setting",
    name = "description-show-bar",
    setting_type = "runtime-global",
    default_value = true,
    order = "c[b]"
  },
  {
    type = "color-setting",
    name = "description-bar-filled-color",
    setting_type = "runtime-global",
    default_value = {r = 0, g = 1, b = 1, a = 1},
    allow_blank = false,
    order = "c[c]"
  },
  {
    type = "color-setting",
    name = "description-bar-empty-color",
    setting_type = "runtime-global",
    default_value = {r = 0.5, g = 0.5, b = 0.5, a = 1},
    allow_blank = false,
    order = "c[d]"
  },
  {
    type = "color-setting",
    name = "description-bar-decorator-color",
    setting_type = "runtime-global",
    default_value = {r = 1, g = 1, b = 1, a = 1},
    allow_blank = false,
    order = "c[e]"
  },
  {
    type = "int-setting",
    name = "description-bar-length",
    setting_type = "runtime-global",
    default_value = 10,
    minimum_value = 1,
    maximum_value = 100,
    order = "c[f]"
  },
  {
    type = "bool-setting",
    name = "description-show-percentage",
    setting_type = "runtime-global",
    default_value = true,
    order = "c[g]"
  },
  {
    type = "color-setting",
    name = "description-percentage-color",
    setting_type = "runtime-global",
    default_value = {r = 0, g = 1, b = 0, a = 1},
    allow_blank = false,
    order = "c[h]"
  },
  {
    type = "string-setting",
    name = "description-string",
    setting_type = "runtime-global",
    default_value = "<=>",
    allow_blank = false,
    order = "c[i]"
  },

  -- other
  {
    type = "string-setting",
    name = "label-other",
    setting_type = "runtime-global",
    default_value = "DUMMY",
    allow_blank = true,
    order = "d[a]"
  },
  {
    type = "bool-setting",
    name = "research-required",
    setting_type = "startup",
    default_value = true,
    order = "d[b]"
  },
  {
    type = "bool-setting",
    name = "retain-on-player-mined",
    setting_type = "runtime-global",
    default_value = true,
    order = "d[c]"
  },
  {
    type = "bool-setting",
    name = "retain-on-robot-mined",
    setting_type = "runtime-global",
    default_value = true,
    order = "d[d]"
  },
  {
    type = "bool-setting",
    name = "retain-equipment-energy",
    setting_type = "runtime-global",
    default_value = true,
    order = "d[e]"
  },
  {
    type = "bool-setting",
    name = "debug",
    setting_type = "runtime-global",
    default_value = false,
    order = "f"
  }
})
