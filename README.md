# my quickshell config
a personal Hyprland desktop config built with [Quickshell](https://quickshell.outfoxxed.me/). status bar, app launcher. each piece is its own module and works independently, so feel free to grab only the parts you need.

i hope it's helpful as a starting point or reference. if you have questions or ide

as, don't hesitate to open an issue - happy to chat.

<img width="1920" height="111" alt="image" src="https://github.com/user-attachments/assets/06d824ae-cf21-4c78-919c-1604f1c0a2dc" />
<br/>
<img width="405" height="146" alt="image" src="https://github.com/user-attachments/assets/40c9b11a-abf2-4e9b-bf85-ec44ea67d69d" />
<br/>
<img width="601" height="495" alt="image" src="https://github.com/user-attachments/assets/40c46613-dc24-461a-9075-33ffea221716" />


https://github.com/user-attachments/assets/55c47c05-34b6-402c-aea7-42a369b86828


## what's included

| Module | What it does |
|--------|-------------|
| **Bar** | clock, workspaces, active window title, volume, brightness, network, battery, system tray, now-playing indicator |
| **App Launcher** | rofi drun-style application launcher |

## prerequisites

these are needed regardless of which modules you use:

- [Quickshell](https://quickshell.outfoxxed.me/) + Qt 6
- [Hyprland](https://hyprland.org/)
- a [Nerd Font](https://www.nerdfonts.com/) (i use Hack Nerd Font - swap it in the QML files if you prefer another)

optional, depending on which modules you use:

- `brightnessctl` - for brightness display and control in the bar and OSD
- `nmcli` - for wifi network info in the bar
- `/sys/class/power_supply/` - for battery info (standard on most laptops)
- `hyprpaper` or `swww` - for the wallpaper manager
- `hyprctl` / Hyprland - for the monitor manager

## installing everything

if you'd like the full setup:

```bash
git clone https://github.com/doannc2212/quickshell-config ~/.config/quickshell
quickshell
```

that's it - quickshell reads from `~/.config/quickshell/` by default.


## acknowledgments

this wouldn't exist without the wonderful work behind [Quickshell](https://quickshell.outfoxxed.me/), [Hyprland](https://hyprland.org/), and the theme creators:

- [doannc2212's quickshell config](https://github.com/doannc2212/quickshell-config) The base of some of the components of my quickshell config.
- [Tokyo Night](https://github.com/enkia/tokyo-night-vscode-theme) by enkia - 4 themes (Night, Storm, Moon, Light)
- [Catppuccin](https://github.com/catppuccin/catppuccin) by the Catppuccin team - 4 themes (Mocha, Macchiato, Frappe, Latte)
- [Beared Theme](https://marketplace.visualstudio.com/items?itemName=BeardedBear.beardedtheme) by BeardedBear - 7 themes
- [MonkeyType](https://monkeytype.com/) - 187 community themes. colors were derived from MonkeyType's theme palette. all credit goes to the original theme creators and the MonkeyType community contributors.

thank you all.
