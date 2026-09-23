# Terminal appearance

`orca-ubugeeei.json` contains the Orca custom theme and typography matching
the Ghostty configuration: `#282c34`, soft teal accents, JetBrains Mono, and
14-point text. Merge its `theme` into `terminalCustomThemes` and its `settings`
into the local Orca profile while Orca is closed; editing the profile while
running would be overwritten by the application's in-memory settings.

The shared Starship prompt shows the current physical path and Git branch on
the first line, with `( ◠ ‿ ◠)و` on the second line. Colors belong to the terminal configuration: injecting
OSC color changes into the prompt breaks ush's line-editor cursor accounting.
Ghostty requires a configuration reload; Orca loads its local profile at startup.
