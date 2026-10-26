-- HyprGlass: full liquid-glass profile.
-- Restore the stronger optical treatment used by the preferred setup.
if hl.plugin and hl.plugin.hyprglass then
	local hg = hl.plugin.hyprglass

	hg.config({
		default_theme = "dark",
		default_preset = "glass",
		manage_window_blur = true,

		refraction_strength = 0.6,
		chromatic_aberration = 0.5,
		fresnel_strength = 0.6,
		specular_strength = 0.8,
		edge_thickness = 0.06,
		lens_distortion = 0.5,
		blur_iterations = 3,

		dark = {
			brightness = 0.86,
			contrast = 0.96,
			saturation = 0.90,
			vibrancy = 0.15,
			adaptive_dim = 0.25,
		},
		light = {
			brightness = 1.10,
			contrast = 0.98,
			saturation = 0.95,
			vibrancy = 0.12,
			adaptive_boost = 0.25,
		},

		-- Keep Quickshell's layer-shell surfaces under its own renderer. Applying
		-- Hyprglass to all layer-shell surfaces destabilizes the active shell.
		layers = { enabled = false },
	})

end
