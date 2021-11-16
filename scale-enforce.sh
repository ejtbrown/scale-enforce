#!/bin/bash

# The desired scale is the only argument
desired_scale="${1}"

# Use dbus-monitor to watch for changes
dbus-monitor --session --profile "path='/org/gnome/Mutter/DisplayConfig',type='signal',member='MonitorsChanged'" | while read -r line
do
  if grep -q MonitorsChanged <<< ${line}; then
    # Get overall state
    disp=$(gdbus call --session --dest org.gnome.Mutter.DisplayConfig --object-path /org/gnome/Mutter/DisplayConfig --method org.gnome.Mutter.DisplayConfig.GetCurrentState)
    serial=$(awk '{print $2}' <<< ${disp} | tr -d ',')
    disp_name=$(grep -Po "(?<=\[\(\(').*?(?=')" <<< ${disp})

    # Parse out the current mode
    current=$(grep -Po "\('[0-9x@\.]+', [0-9]+, [0-9]+, [0-9\.]+, [0-9\.]+, \[[0-9, \.]+\], \{'is-current':.*?\)" <<< ${disp})
    current_scale=$(grep -Po "(?<='legacy-ui-scaling-factor': \<)[0-9\.]+(?=\>)" <<< ${disp})
    resolution="$(awk '{print $1}' <<< ${current} | grep -Po "(?<=\(')[0-9x@\.]+(?=')")"
    scale_list=$(grep -Po '(?<=\[).*(?=\])' <<< ${current} | tr -d ',')

    # Figure out which of the supported scales is closest to the desired
    closest=999
    for sc in ${scale_list}; do
      diff=$(bc <<< "${sc}-${desired_scale}")
      if [[ "${diff}" == "0" ]]; then
        scale=${sc}
        break
      fi

      if [[ "$(bc <<< "${diff}<${closest}")" == "1" ]]; then
        scale=${sc}
        closest=${diff}
      fi
    done

    if [[ "$(bc <<< "${scale}-${current_scale}")" == "0" ]]; then
      echo "Scale is correctly set"
    else
      echo "Using mode ID ${resolution} scale ${scale} for display ${disp_name}"

      # Set the scale with the current resolution
      gdbus call --session --dest org.gnome.Mutter.DisplayConfig \
        --object-path /org/gnome/Mutter/DisplayConfig \
        --method org.gnome.Mutter.DisplayConfig.ApplyMonitorsConfig \
        ${serial} 1 "[(0, 0, ${scale}, 0, true, [('${disp_name}', '${resolution}', [] )] )]" "[]"
    fi
  fi
done

