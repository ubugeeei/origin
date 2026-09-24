# Terminal appearance

`orca-ubugeeei.json` contains the Orca custom theme, typography, and pane
layout matching the Ghostty configuration: soft teal accents, JetBrains Mono,
14-point text, and 18x14 padding. The custom theme keeps `#282c34` as its base
while `terminalColorOverrides` pins the rendered background to Ghostty's
`#181818`. It also records the Orca app and editor fonts (Geist and Nova).
Merge its `theme` into `terminalCustomThemes` and its `settings` into the local
Orca profile while Orca is closed; editing the profile while running would be
overwritten by the application's in-memory settings.

The shared Starship prompt shows the current physical path and Git branch on
the first line, with `( ◠ ‿ ◠)و` on the second line. Colors belong to the terminal configuration: injecting
OSC color changes into the prompt breaks ush's line-editor cursor accounting.
Ghostty requires a configuration reload; Orca loads its local profile at startup.
