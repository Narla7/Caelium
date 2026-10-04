-- Caelium keybinding overrides.
-- Loaded after Omarchy's defaults in ~/.config/hypr/hyprland.lua.

-- mod + hjkl for window focus.
hl.unbind("SUPER + H")
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")

o.bind("SUPER + H", "Focus left window", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus down window", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus up window", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus right window", hl.dsp.focus({ direction = "r" }))

-- App launches (re-added because preinstalled bindings are disabled).
o.bind("SUPER + SHIFT + RETURN", "Zen browser", { omarchy = "browser" })
o.bind("SUPER + SHIFT + F", "Files", { omarchy = "nautilus" })
o.bind("SUPER + SHIFT + O", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })
o.bind("SUPER + SHIFT + T", "Toggle theme", "caelium-theme-toggle")

-- Remove an AI/agent binding left over from Omarchy's defaults.
hl.unbind("SUPER + SHIFT + CTRL + A")

-- Note:
--   mod + enter   -> Terminal (already default, launches kitty via omarchy-launch-terminal)
--   mod + space   -> Caelium menu (already default, omarchy.menu)
--   mod + w       -> Close window (already default)
