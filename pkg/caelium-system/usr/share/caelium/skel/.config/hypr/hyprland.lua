-- Caelium Hyprland entry point.
-- Forked from Omarchy; internal namespace remains "omarchy" so the vendored
-- Lua modules and Quickshell shell keep working.

dofile((os.getenv("OMARCHY_PATH") or "/usr/share/caelium") .. "/default/hypr/bootstrap.lua")

-- Disable Omarchy's preinstalled app/webapp bindings (ChatGPT, Grok, YouTube, etc.).
-- We add back only the apps we want in ~/.config/hypr/bindings.lua.
omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Load Caelium user overrides.
require("hypr.bindings")
