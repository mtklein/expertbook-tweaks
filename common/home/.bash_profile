[[ -f ~/.bashrc ]] && . ~/.bashrc

if uwsm check may-start -q; then
  exec uwsm start -e -D Hyprland hyprland.desktop
fi
