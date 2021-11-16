# scale-enforce
### Overview
This is a script that watches for changes in display resolution, and sets the 
DPI scaling when they happen.

One's first question might very be, _why on earth would such a thing be
necessary?_ The answer is that VMware Workstation Pro (at least as of version
16.2) does not maintain display scale when it does guest resolution changes in
accordance with the `Autofit Guest` option (which changes guest display
resolution the maximum that will fit in the window) or when toggling in or out
of full screen mode. Instead, it sets it to 1 (aka 100% scale). If this happens
to be the right value, it's fine. But if it's not, it's a monumental annoyance
having to manually set the scale every time the guest window size changes.

The proper solution for this problem without a doubt lays in the realm of the
open-vm-tools guest package. Until that fix happens, scale-enforce can bludgeon
the symptoms by waiting for those resolution changes, and setting the scale back
to the desired value when they happen.

### Compatibility
This was written against Ubuntu 21.10 guests running on VMware Workstation 
16.2, which in turn was running on Ubuntu 21.10. It seems reasonably likely
that any distribution that uses Wayland, Mutter, and dbus should also work,
but your mileage may vary.

### Installation
1: Clone this repo: `git clone https://github.com/ejtbrown/scale-enforce.git`

2: Ensure that the systemd user directory for your user exists:
`mkdir -p "${HOME}/.local/share/systemd/user"`

3: Copy the unit file into the systemd user directory:
`cp "scale-enforce/scale-enforce.service" "${HOME}/.local/share/systemd/user/"`

4: Edit the unit file to set the desired scale:
`vi "${HOME}/.local/share/systemd/user/scale-enforce.service"` ; look for the
line that begins with `ExecStart` - the number on the end of that line is the
desired scale. 2 is 200%, 3 is 300%, etc. Fractional values can be set if the
display and the X server support it.

5: Copy the script to /usr/bin: 
`sudo cp scale-enforce/scale-enforce.sh /usr/bin/`

6: Do a daemon-reload to make systemd pick up the new unit file:
`systemctl --user daemon-reload`

7: Start and enable the service:
`systemctl --user enable --now scale-enforce.service`
