# discordbee-linux-imgur-workaround
A workaround for Imgur rate limiting with DiscordBee on Linux, using OpenVPN.

## How does this work?
This script bypasses the rate limit (read: IP ban) imposed by Imgur on unsuspecting DiscordBee users on Linux by tunneling MusicBee through a VPN of your choosing, as long as you have an OpenVPN config for it. When MusicBee is closed, the OpenVPN instance is closed as well.

## Prerequisites
You need:
- [MusicBee](https://www.getmusicbee.com/) installed using wine, preferrably in a non-portable manner.
- The latest version of [DiscordBee](https://github.com/sll552/DiscordBee) set up to use Imgur, instructions for which are not provided here.
- [wine-discord-ipc-bridge](https://github.com/0e4ef622/wine-discord-ipc-bridge) (the .exe) saved somewhere in the same wine prefix that MusicBee uses.
- A VPN of your choosing. I personally use [Windscribe](https://windscribe.com/).
- An OpenVPN config for your VPN, placed somewhere alongside this script. Find (or generate) one on the internet if you don't have one.
- `openvpn`, `iproute` (or `iproute2`), and `iptables`  installed.

## Installation
Download the `musicbee.sh` script from the repository, and place it somewhere convenient but permanent.

Because this script executes certain `ip` commands, it needs to be able to elevate itself to superuser level. This can be accomplished by adding an exception for this specific script:

- Edit the sudoers file using `sudo visudo`.
- Add `ALL     ALL = NOPASSWD: /path/to/musicbee.sh` somewhere in the file, filling in the path as necessary.

After you've added an exception for the script, edit the script and fill in the top few variables accordingly:
- `USERNAME` should be set to your username.
- `WINEPREFIX` is to be set to the wine prefix directory that contains both MusicBee and the Discord IPC bridge.
- `MUSICBEE` should be set to either the MusicBee .exe, or the Start Menu shortcut it creates. You may simply replace `your_username` here, in most cases.
  - Make sure the path is prefix-relative, i.e. it begins with `C:/`
- `IPC_BRIDGE` is the path to the Discord IPC bridge stored in the wine prefix.
- `OPENVPN_CONF` is the path to your OpenVPN configuration file.

Finally, edit your relevant MusicBee desktop files to execute this script instead of the original command. You may also manually invoke the script with `sudo ./musicbee.sh` to test it first.

Try out playing a few tracks you haven't uploaded cover art for before; you'll find that it works seamlessly -- and the VPN is constricted to just MusicBee!

## Anything else?
If you have any idea what those `ip` commands do, please submit a pull request commenting them accordingly. Also, if you wish to create a similar script for Windows that uses Powershell (and probably [this](https://r1ch.net/projects/forcebindip)), that would be much appreciated.

