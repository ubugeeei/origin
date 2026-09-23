# Terminal appearance

`orca-ubugeeei.json` contains the Orca custom theme and typography matching
the Ghostty configuration: `#282c34`, soft teal accents, JetBrains Mono, and
14-point text. Merge its `theme` into `terminalCustomThemes` and its `settings`
into the local Orca profile while Orca is closed; editing the profile while
running would be overwritten by the application's in-memory settings.

The shared Starship prompt keeps the current path, Git branch, and
`( ◠ ‿ ◠)و` on one line. Its fixed terminal module sets background, foreground,
and cursor colors with OSC 10/11/12, so existing Ghostty and Orca surfaces
receive the colors on the next prompt without restarting active sessions.
