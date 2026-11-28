local wezterm = require 'wezterm'
local mux = wezterm.mux
local config = wezterm.config_builder()

-- Download from https://github.com/aristocratos/btop4win/releases (latest release),
-- grabbing the "btop4win-LHM-x64.zip" asset (the LHM variant, for LibreHardwareMonitor sensor support),
-- then extract it and point this shared path at the extracted "btop4win" folder.
local btop_dir = [[D:\dev\btop4win-LHM-x64\btop4win]]

-- Set up the startup window with btop4win/LHM in the first tab,
-- the normal dev shell in the second tab, and leave the dev tab focused
wezterm.on('gui-startup', function()
  -- The executable name that is located inside the directory specified by btop_dir.
  local btop_exe = btop_dir .. [[\btop4win.exe]]

  -- Tab 1: Run btop4win/LHM from its install directory
  -- Explicit args here intentionally bypass config.default_prog,
  local btop_tab, btop_pane, window = mux.spawn_window {
    cwd = btop_dir,
    args = {
      'pwsh.exe',
      '-NoLogo',
      '-NoExit',
      '-Command',
      string.format([[sudo "%s"]], btop_exe),
    },
  }

  btop_tab:set_title('btop4win-LHM')

  -- Request maximization before running the dev-shell startup commands
  window:gui_window():maximize()

  -- Tab 2: Open the normal dev shell
  -- Explicit args here intentionally bypass config.default_prog,
  local dev_tab, dev_pane = window:spawn_tab {
    cwd = [[E:]],

    -- Currently commenting out args (which will then use config.default_prog's args)
    -- because WezTerm has a bug where it ignores `cwd` when `spawn_tab` specifies both `cwd` and `args`
    -- (https://github.com/wezterm/wezterm/issues/8150) and we need/want cwd to be respected
    -- args = {
    --   "pwsh.exe",
    --   "-NoLogo",
    -- },
  }

  -- Use cls to clear the pane before running fastfetch and ls
  dev_pane:send_text("cls; fastfetch; ls\r")

  -- Leave the normal dev tab focused
  dev_tab:activate()
end)

wezterm.on('format-tab-title', function(tab)
  local title = tab.tab_title

  if not title or title == '' then
    local pane = tab.active_pane
    local cwd = pane.current_working_dir
    -- Fall back to the pane title if the working directory is unavailable
    title = (cwd and cwd.file_path) or pane.title
  end

  return string.format('%d: %s', tab.tab_index + 1, title)
end)

-- ======================= !!! WINDOWS ONLY SETTINGS !!! =======================
-- config.default_prog = { "powershell.exe", "-NoExit", "-Command", "ls" }
-- config.default_prog = { "pwsh.exe", "-NoLogo" }

-- Default shell for panes/tabs/windows that don't specify their own program.
-- Load the normal PowerShell profile, run the custom `ls`, then stay interactive.
config.default_prog = {
  'pwsh.exe',
  '-NoLogo',
  '-NoExit',
  '-Command',
  'ls',
}

-- -- Initial/fallback working directory.
-- -- However, subsequent panes/tabs/windows will generally inherit the active
-- -- pane's working directory when WezTerm can determine it.
-- config.default_cwd = [[D:\dev]]
-- ^^^^^^^^^^^^^^^^^^^^^^^ !!! WINDOWS ONLY SETTINGS !!! ^^^^^^^^^^^^^^^^^^^^^^^

config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true

-- ============?NO LONGER NEEDED NOW THAT USING THE 'NIGHTLY' BUILD?============
-- Necessary ***SOLELY*** to fix bug where closing a non-rightmost tab
-- with `Ctrl+Shift+W` did not immediately update the tab-bar UI.
-- (https://github.com/wezterm/wezterm/issues/5003)
-- config.switch_to_last_active_tab_when_closing_tab = true
-- ^^^^^^^^^^^^?NO LONGER NEEDED NOW THAT USING THE 'NIGHTLY' BUILD?^^^^^^^^^^^^


-- config.background = {
--   -- Layer 1: Black terminal background at 100% width, height, and opacity
--   {
--     source = { Color = '#000000' },
--     width = '100%',
--     height = '100%',
--   },
--   -- Layer 2: NASA Moon with its original transparent background at 10% brightness
--   {
--     source = {
--       File = 'C:/Users/Nico/Downloads/moon.7106.tif',
--     },
--     width = 'Contain',
--     height = 'Contain',
--     horizontal_align = 'Center',
--     vertical_align = 'Middle',
--     repeat_x = 'NoRepeat',
--     repeat_y = 'NoRepeat',
--     -- opacity = .5,
--     hsb = {
--       hue = 1.0,
--       saturation = 1.0,
--       brightness = 0.1,
--     },
--   },
-- }

-- config.font = wezterm.font {
--   family = 'MonoLisa',
--   harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' },
-- }
-- Use MonoLisa for text and prioritize Nerd Font Symbols for characters
-- MonoLisa lacks. WezTerm's automatic fallbacks otherwise try JetBrains
-- Mono before Nerd Font Symbols, potentially mixing symbol designs with
-- different sizes and vertical alignment.
--
-- Example: this Starship configuration added a moon before the prompt caret:
--   [character]
--   format = "\uE38D$symbol "
--
-- The moon appeared lower than the caret. Font inspection confirmed that
-- the moon came from Symbols Nerd Font Mono, while the caret (❯, U+276F,
-- not the ASCII > character) came from JetBrains Mono: the selected
-- MonoLisa font did not supply it, so WezTerm used its automatic fallback.
--
-- Putting Nerd Font Symbols first makes it supply both characters,
-- resolving that visual mismatch without any font scaling.
config.font = wezterm.font_with_fallback {
  {
    family = 'MonoLisa',
    harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' },
  },
  {
    family = 'Symbols Nerd Font Mono',
  },
}
config.font_size = 15

-- Allow square-like symbols to extend beyond their character cell even
-- when the next cell contains text. The default, 'WhenFollowedBySpace',
-- allows this only when the next cell is a space.
--
-- Example: in Starship, the moon stayed small when touching the caret:
--   [character]
--   format = "\uE38D$symbol "
--
-- Adding a space let it render at its intended size:
--   [character]
--   format = "\uE38D $symbol "
--
-- 'Always' permits that larger rendering in either case, keeping sizing
-- independent of the following character. Icons can overlap adjacent
-- text, so add a space when visual separation is desired.
config.allow_square_glyphs_to_overflow_width = 'Always'

config.default_cursor_style = 'BlinkingBlock'

-- Key bindings
config.keys = {
  -- Ctrl+C: Copy if text is selected, otherwise send Ctrl+C to terminal
  {
    key = 'c',
    mods = 'CTRL',
    action = wezterm.action_callback(function(window, pane)
      local selection = window:get_selection_text_for_pane(pane)
      if selection and selection ~= "" then
        window:copy_to_clipboard(selection)
      else
        window:perform_action(wezterm.action.SendKey { key = 'c', mods = 'CTRL' }, pane)
      end
    end),
  },
  -- Ctrl+Shift+9: Open the tab navigator
  {
    key = 'phys:9',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ShowTabNavigator,
  },
  -- CTRL+Shift+Q: Quit/Terminate the WezTerm application, killing all tabs
  { 
    key = 'q',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.QuitApplication
  },
}

return config