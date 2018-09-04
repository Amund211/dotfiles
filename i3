# ~/.config/i3/config

###############################################################
#			  General
###############################################################
# Keyboard-settings
set $mod Mod4

floating_modifier $mod

# Executable programs
set $screenlocker i3lock -e -c 112233

set $terminal --no-startup-id urxvt

set $browser firefox

# Font for window titles. Will also be used by the bar unless a different font
# is used in the bar {} block below.
font pango:monospace 8

# This font is widely installed, provides lots of unicode glyphs, right-to-left
# text rendering and scalability on retina/hidpi displays (thanks to pango).
#font pango:DejaVu Sans Mono 8

# Before i3 v4.8, we used to recommend this one as the default:
# font -misc-fixed-medium-r-normal--13-120-75-75-C-70-iso10646-1
# The font above is very space-efficient, that is, it looks good, sharp and
# clear in small sizes. However, its unicode glyph coverage is limited, the old
# X core fonts rendering does not support right-to-left and this being a bitmap
# font, it doesn’t scale on retina/hidpi displays.

# Use Mouse+$mod to drag floating windows to their wanted position
###############################################################
#			 Starting scripts
###############################################################
# Start i3bar to display a workspace bar (plus the system information i3blocks
# finds out, if available)
bar {
        status_command i3blocks -c ~/.dotfiles/i3blocks
}

# Setting bg-color
exec --no-startup-id "xsetroot -solid \"#113322\""

# Set bg
# exec_always --no-startup-id "feh --bg-scale ~/path/to/file"

# Networkmanager applet, no-agent because no notif manager
exec --no-startup-id "nm-applet --no-agent"

# Remapping caps to super/escape
exec --no-startup-id "~/.scripts/capsescape.sh"

# Setting keydelay
exec --no-startup-id "xset r rate 300 35"

# Selecting default screenlayout
exec --no-startup-id "~/.screenlayout/default"


###############################################################
#		       Window properties
###############################################################

# Properties for the dropdown terminal
for_window [instance="dropdownTerminal"] floating enable
for_window [instance="dropdownTerminal"] resize set 625 400
for_window [instance="dropdownTerminal"] move scratchpad
for_window [instance="dropdownTerminal"] border pixel 5

exec $terminal -name dropdownTerminal

# Properties for python window
for_window [instance="dropdownPython"] floating enable
for_window [instance="dropdownPython"] resize set 625 400
for_window [instance="dropdownPython"] move scratchpad
for_window [instance="dropdownPython"] border pixel 2

exec $terminal -name dropdownPython -e python
###############################################################
#			Special bindings
###############################################################
# Hotkey fuckery
bindsym Control+F7 exec --no-startup-id "xdotool mousedown 3"

# Blank the screen (brightness 0)
bindsym XF86Display exec --no-startup-id "light -S 0"



# start a terminal
bindsym $mod+Return exec $terminal

# Update all of i3blocks
bindsym $mod+Insert exec --no-startup-id "~/.scripts/updateBlocks.sh"

# Screenlocking
bindsym $mod+Shift+Delete exec --no-startup-id "$screenlocker"

# toggle tiling / floating
bindsym $mod+Shift+space floating toggle

# change focus between tiling / floating windows
bindsym $mod+space focus mode_toggle

bindsym XF86MonBrightnessUp exec --no-startup-id "~/.scripts/brightness.sh 1" 
bindsym XF86MonBrightnessDown exec --no-startup-id "~/.scripts/brightness.sh -1"

# Audio keys
bindsym XF86AudioRaiseVolume exec --no-startup-id "pactl set-sink-volume @DEFAULT_SINK@ +10% && pactl set-sink-mute @DEFAULT_SINK@ 0 && pkill i3blocks -RTMIN+10"
bindsym XF86AudioLowerVolume exec --no-startup-id "pactl set-sink-volume @DEFAULT_SINK@ -10% && pkill i3blocks -RTMIN+10"
bindsym XF86AudioMute exec --no-startup-id "pactl set-sink-mute @DEFAULT_SINK@ toggle && pkill i3blocks -RTMIN+10"


###############################################################
#			Letter key bindings
###############################################################

# Utility bindings ############################################
# Power-options
bindsym $mod+Shift+p exec --no-startup-id "~/.scripts/poweroptions.sh '$screenlocker'"
# Screen-options
bindsym $mod+o exec --no-startup-id "~/.scripts/screensel.sh"
# reload the configuration file
bindsym $mod+Shift+c reload
# restart i3 inplace (preserves your layout/session, can be used to upgrade i3)
bindsym $mod+Shift+r restart
# exit i3 (logs you out of your X session)
bindsym $mod+Shift+e exec  --no-startup-id "~/.scripts/prompt.sh 'Are you sure you want to exit i3?' 'i3-msg exit'"
# "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -b 'Yes, exit i3' 'i3-msg exit'"
# Restart NetworkManager
bindsym $mod+Pause exec --no-startup-id "sudo systemctl restart NetworkManager"


# Application bindings ########################################
# start dmenu (a program launcher)
bindsym $mod+d exec --no-startup-id dmenu_run
# There also is the (new) i3-dmenu-desktop which only displays applications
# shipping a .desktop file. It is a wrapper around dmenu, so you need that
# installed.
# bindsym $mod+d exec --no-startup-id i3-dmenu-desktop

# Show/hide dropdown terminal
bindsym $mod+t [instance="dropdownTerminal"] scratchpad show; [instance="dropdownTerminal"] move position center

# Show/hide dropdown python
bindsym $mod+p [instance="dropdownPython"] scratchpad show; [instance="dropdownPython"] move position center

# Run browser
bindsym $mod+g exec $browser

# Window bindings #############################################
# change focus
bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

# move focused window
bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right

# kill focused window
# bindsym $mod+q [con_id="__focused__" instance="^(?!dropdownTerminal|dropdownPython).*$"] kill
bindsym $mod+Shift+q kill
bindsym $mod+q kill

# Resizing outside of resize mode
bindsym $mod+Shift+y resize shrink width 10 px or 10 ppt
bindsym $mod+Shift+u resize grow height 10 px or 10 ppt
bindsym $mod+Shift+i resize shrink height 10 px or 10 ppt
bindsym $mod+Shift+o resize grow width 10 px or 10 ppt
# resize window (you can also use the mouse for that)
mode "resize" {
        # These bindings trigger as soon as you enter the resize mode

        # Pressing left will shrink the window’s width.
        # Pressing right will grow the window’s width.
        # Pressing up will shrink the window’s height.
        # Pressing down will grow the window’s height.
        bindsym h resize shrink width 10 px or 10 ppt
        bindsym j resize grow height 10 px or 10 ppt
        bindsym k resize shrink height 10 px or 10 ppt
        bindsym l resize grow width 10 px or 10 ppt

        # back to normal: Enter or Escape or $mod+r
        bindsym Return mode "default"
        bindsym Escape mode "default"
        bindsym $mod+r mode "default"
}
bindsym $mod+r mode "resize"

# split in horizontal orientation
bindsym $mod+b split h

# split in vertical orientation
bindsym $mod+v split v

# enter fullscreen mode for the focused container
bindsym $mod+f fullscreen toggle

# change container layout (stacked, tabbed, toggle split)
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

# focus the parent container
bindsym $mod+a focus parent

# focus the child container
#bindsym $mod+d focus child


###############################################################
#			Workspace bindings
###############################################################
# Define names for default workspaces for which we configure key bindings later on.
# We use variables to avoid repeating the names in multiple places.
set $ws1 "1"
set $ws2 "2"
set $ws3 "3"
set $ws4 "4"
set $ws5 "5"
set $ws6 "6"
set $ws7 "7"
set $ws8 "8"
set $ws9 "9"
set $ws10 "10"

# switch to workspace
bindsym $mod+1 workspace $ws1
bindsym $mod+2 workspace $ws2
bindsym $mod+3 workspace $ws3
bindsym $mod+4 workspace $ws4
bindsym $mod+5 workspace $ws5
bindsym $mod+6 workspace $ws6
bindsym $mod+7 workspace $ws7
bindsym $mod+8 workspace $ws8
bindsym $mod+9 workspace $ws9
bindsym $mod+0 workspace $ws10

# move focused container to workspace
bindsym $mod+Shift+1 move container to workspace $ws1
bindsym $mod+Shift+2 move container to workspace $ws2
bindsym $mod+Shift+3 move container to workspace $ws3
bindsym $mod+Shift+4 move container to workspace $ws4
bindsym $mod+Shift+5 move container to workspace $ws5
bindsym $mod+Shift+6 move container to workspace $ws6
bindsym $mod+Shift+7 move container to workspace $ws7
bindsym $mod+Shift+8 move container to workspace $ws8
bindsym $mod+Shift+9 move container to workspace $ws9
bindsym $mod+Shift+0 move container to workspace $ws10

# Tabbing workspaces
bindsym $mod+Tab workspace back_and_forth
# Prev/ next workspace
bindsym $mod+n workspace prev
bindsym $mod+m workspace next

# Send to
bindsym $mod+Shift+n move container to workspace prev

bindsym $mod+Shift+m move container to workspace next

