#!/run/current-system/sw/bin/bash
##! nix-shell -v -i bash -p bashInteractive dwm dmenu xlockmore xautolock xorg.xset xorg.xinput xorg.xsetroot xorg.setxkbmap xorg.xmodmap rxvt_unicode
##! nix-shell -I nixpkgs=https://github.com/dguibert/nixpkgs/archive/pu.tar.gz

cd $HOME
set -o nounset
set -o monitor
#set -o verbose
#set -o xtrace
echo $SHELL
which bash
# workaround to get bash (with readline support (aka bashInteractive))
export SHELL=$(which bash)
unset IN_NIX_SHELL
unset SSL_CERT_FILE

while :; do
  # i hate this bell!!!
  xset b 0 &

  # power saving mode of the screen
  xset dpms 300 300 300 &

  # typematic repeat rate
  xset r rate 255 47 &

  #xset to stop the AVRCP key press repeating at warp speed:
  xset -r 171 -r 173 -r 209
  ## To enable vertical scrolling
  xinput set-prop 'TPPS/2 IBM TrackPoint' "Evdev Wheel Emulation" 1
  xinput set-prop 'TPPS/2 IBM TrackPoint' "Evdev Wheel Emulation Button" 2
  xinput set-prop 'TPPS/2 IBM TrackPoint' "Evdev Wheel Emulation Timeout" 200
  ## To enable horizontal scrolling in addition to vertical scrolling
  xinput set-prop 'TPPS/2 IBM TrackPoint' "Evdev Wheel Emulation Axes" 6 7 4 5

  # http://woozle.org/~neale/src/xss.html
  # launch xlock after timeout
  xset s 500
  xss-lock -- xlock -mode blank &

  xrdb -load ~/.Xdefaults
  # launch rxvt daemon
  urxvtd &
  qtpass &

  conky -c ~/.conkyrc | while read line; do 
      xsetroot -name "$line"
  done &
  # relaunch DWM if the binary changes, otherwise bail
  csum=$(sha1sum $(which dwm))
  new_csum=""
  while true
    do
      if [ "$csum" != "$new_csum"  ]
      then
        csum=$new_csum
        dwm
        pid=$!
      else
        exit 0
      fi
      new_csum=$(sha1sum $(which dwm))
      wait $pid
      sleep 0.5
  done

  [ -e $HOME/.xsession-exit ] && break

  echo "I: restarting xsession (touch $HOME/.xsession-exit to exit)..." >&2
done

rm -f $HOME/.xsession-exit

exit 0
