/home/amund/.config/i3/config
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
        status_command i3blocks
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
# reload the configuration file
bindsym $mod+Shift+c reload
# restart i3 inplace (preserves your layout/session, can be used to upgrade i3)
bindsym $mod+Shift+r restart
# exit i3 (logs you out of your X session)
bindsym $mod+Shift+e exec  --no-startup-id "~/.scripts/prompt.sh 'Are you sure you want to exit i3?' 'i3-msg exit'"
# "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -b 'Yes, exit i3' 'i3-msg exit'"


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




# Huge meme ahead

# nullmode to disable input
mode "null" {
        bindsym $mod+Shift+Pause mode "default"
	
	bindsym 0 nop
	bindsym $mod+0 nop
	bindsym $mod+Shift+0 nop
	bindsym Alt_L+Control+0 nop
	bindsym 1 nop
	bindsym $mod+1 nop
	bindsym $mod+Shift+1 nop
	bindsym Alt_L+Control+1 nop
	bindsym 2 nop
	bindsym $mod+2 nop
	bindsym $mod+Shift+2 nop
	bindsym Alt_L+Control+2 nop
	bindsym 3 nop
	bindsym $mod+3 nop
	bindsym $mod+Shift+3 nop
	bindsym Alt_L+Control+3 nop
	bindsym 4 nop
	bindsym $mod+4 nop
	bindsym $mod+Shift+4 nop
	bindsym Alt_L+Control+4 nop
	bindsym 5 nop
	bindsym $mod+5 nop
	bindsym $mod+Shift+5 nop
	bindsym Alt_L+Control+5 nop
	bindsym 6 nop
	bindsym $mod+6 nop
	bindsym $mod+Shift+6 nop
	bindsym Alt_L+Control+6 nop
	bindsym 7 nop
	bindsym $mod+7 nop
	bindsym $mod+Shift+7 nop
	bindsym Alt_L+Control+7 nop
	bindsym 8 nop
	bindsym $mod+8 nop
	bindsym $mod+Shift+8 nop
	bindsym Alt_L+Control+8 nop
	bindsym 9 nop
	bindsym $mod+9 nop
	bindsym $mod+Shift+9 nop
	bindsym Alt_L+Control+9 nop
	bindsym a nop
	bindsym $mod+a nop
	bindsym $mod+Shift+a nop
	bindsym Alt_L+Control+a nop
	bindsym A nop
	bindsym $mod+A nop
	bindsym $mod+Shift+A nop
	bindsym Alt_L+Control+A nop
	bindsym ae nop
	bindsym $mod+ae nop
	bindsym $mod+Shift+ae nop
	bindsym Alt_L+Control+ae nop
	bindsym AE nop
	bindsym $mod+AE nop
	bindsym $mod+Shift+AE nop
	bindsym Alt_L+Control+AE nop
	bindsym Alt_L nop
	bindsym $mod+Alt_L nop
	bindsym $mod+Shift+Alt_L nop
	bindsym Alt_L+Control+Alt_L nop
	bindsym ampersand nop
	bindsym $mod+ampersand nop
	bindsym $mod+Shift+ampersand nop
	bindsym Alt_L+Control+ampersand nop
	bindsym apostrophe nop
	bindsym $mod+apostrophe nop
	bindsym $mod+Shift+apostrophe nop
	bindsym Alt_L+Control+apostrophe nop
	bindsym aring nop
	bindsym $mod+aring nop
	bindsym $mod+Shift+aring nop
	bindsym Alt_L+Control+aring nop
	bindsym Aring nop
	bindsym $mod+Aring nop
	bindsym $mod+Shift+Aring nop
	bindsym Alt_L+Control+Aring nop
	bindsym asterisk nop
	bindsym $mod+asterisk nop
	bindsym $mod+Shift+asterisk nop
	bindsym Alt_L+Control+asterisk nop
	bindsym at nop
	bindsym $mod+at nop
	bindsym $mod+Shift+at nop
	bindsym Alt_L+Control+at nop
	bindsym b nop
	bindsym $mod+b nop
	bindsym $mod+Shift+b nop
	bindsym Alt_L+Control+b nop
	bindsym B nop
	bindsym $mod+B nop
	bindsym $mod+Shift+B nop
	bindsym Alt_L+Control+B nop
	bindsym backslash nop
	bindsym $mod+backslash nop
	bindsym $mod+Shift+backslash nop
	bindsym Alt_L+Control+backslash nop
	bindsym BackSpace nop
	bindsym $mod+BackSpace nop
	bindsym $mod+Shift+BackSpace nop
	bindsym Alt_L+Control+BackSpace nop
	bindsym bar nop
	bindsym $mod+bar nop
	bindsym $mod+Shift+bar nop
	bindsym Alt_L+Control+bar nop
	bindsym braceleft nop
	bindsym $mod+braceleft nop
	bindsym $mod+Shift+braceleft nop
	bindsym Alt_L+Control+braceleft nop
	bindsym braceright nop
	bindsym $mod+braceright nop
	bindsym $mod+Shift+braceright nop
	bindsym Alt_L+Control+braceright nop
	bindsym bracketleft nop
	bindsym $mod+bracketleft nop
	bindsym $mod+Shift+bracketleft nop
	bindsym Alt_L+Control+bracketleft nop
	bindsym bracketright nop
	bindsym $mod+bracketright nop
	bindsym $mod+Shift+bracketright nop
	bindsym Alt_L+Control+bracketright nop
	bindsym Break nop
	bindsym $mod+Break nop
	bindsym $mod+Shift+Break nop
	bindsym Alt_L+Control+Break nop
	bindsym brokenbar nop
	bindsym $mod+brokenbar nop
	bindsym $mod+Shift+brokenbar nop
	bindsym Alt_L+Control+brokenbar nop
	bindsym c nop
	bindsym $mod+c nop
	bindsym $mod+Shift+c nop
	bindsym Alt_L+Control+c nop
	bindsym C nop
	bindsym $mod+C nop
	bindsym $mod+Shift+C nop
	bindsym Alt_L+Control+C nop
	bindsym colon nop
	bindsym $mod+colon nop
	bindsym $mod+Shift+colon nop
	bindsym Alt_L+Control+colon nop
	bindsym comma nop
	bindsym $mod+comma nop
	bindsym $mod+Shift+comma nop
	bindsym Alt_L+Control+comma nop
	bindsym Control_L nop
	bindsym $mod+Control_L nop
	bindsym $mod+Shift+Control_L nop
	bindsym Alt_L+Control+Control_L nop
	bindsym Control_R nop
	bindsym $mod+Control_R nop
	bindsym $mod+Shift+Control_R nop
	bindsym Alt_L+Control+Control_R nop
	bindsym copyright nop
	bindsym $mod+copyright nop
	bindsym $mod+Shift+copyright nop
	bindsym Alt_L+Control+copyright nop
	bindsym currency nop
	bindsym $mod+currency nop
	bindsym $mod+Shift+currency nop
	bindsym Alt_L+Control+currency nop
	bindsym d nop
	bindsym $mod+d nop
	bindsym $mod+Shift+d nop
	bindsym Alt_L+Control+d nop
	bindsym D nop
	bindsym $mod+D nop
	bindsym $mod+Shift+D nop
	bindsym Alt_L+Control+D nop
	bindsym dead_acute nop
	bindsym $mod+dead_acute nop
	bindsym $mod+Shift+dead_acute nop
	bindsym Alt_L+Control+dead_acute nop
	bindsym dead_cedilla nop
	bindsym $mod+dead_cedilla nop
	bindsym $mod+Shift+dead_cedilla nop
	bindsym Alt_L+Control+dead_cedilla nop
	bindsym dead_circumflex nop
	bindsym $mod+dead_circumflex nop
	bindsym $mod+Shift+dead_circumflex nop
	bindsym Alt_L+Control+dead_circumflex nop
	bindsym dead_diaeresis nop
	bindsym $mod+dead_diaeresis nop
	bindsym $mod+Shift+dead_diaeresis nop
	bindsym Alt_L+Control+dead_diaeresis nop
	bindsym dead_doubleacute nop
	bindsym $mod+dead_doubleacute nop
	bindsym $mod+Shift+dead_doubleacute nop
	bindsym Alt_L+Control+dead_doubleacute nop
	bindsym dead_grave nop
	bindsym $mod+dead_grave nop
	bindsym $mod+Shift+dead_grave nop
	bindsym Alt_L+Control+dead_grave nop
	bindsym dead_hook nop
	bindsym $mod+dead_hook nop
	bindsym $mod+Shift+dead_hook nop
	bindsym Alt_L+Control+dead_hook nop
	bindsym dead_tilde nop
	bindsym $mod+dead_tilde nop
	bindsym $mod+Shift+dead_tilde nop
	bindsym Alt_L+Control+dead_tilde nop
	bindsym Delete nop
	bindsym $mod+Delete nop
	bindsym $mod+Shift+Delete nop
	bindsym Alt_L+Control+Delete nop
	bindsym dollar nop
	bindsym $mod+dollar nop
	bindsym $mod+Shift+dollar nop
	bindsym Alt_L+Control+dollar nop
	bindsym Down nop
	bindsym $mod+Down nop
	bindsym $mod+Shift+Down nop
	bindsym Alt_L+Control+Down nop
	bindsym downarrow nop
	bindsym $mod+downarrow nop
	bindsym $mod+Shift+downarrow nop
	bindsym Alt_L+Control+downarrow nop
	bindsym dstroke nop
	bindsym $mod+dstroke nop
	bindsym $mod+Shift+dstroke nop
	bindsym Alt_L+Control+dstroke nop
	bindsym e nop
	bindsym $mod+e nop
	bindsym $mod+Shift+e nop
	bindsym Alt_L+Control+e nop
	bindsym E nop
	bindsym $mod+E nop
	bindsym $mod+Shift+E nop
	bindsym Alt_L+Control+E nop
	bindsym ellipsis nop
	bindsym $mod+ellipsis nop
	bindsym $mod+Shift+ellipsis nop
	bindsym Alt_L+Control+ellipsis nop
	bindsym End nop
	bindsym $mod+End nop
	bindsym $mod+Shift+End nop
	bindsym Alt_L+Control+End nop
	bindsym endash nop
	bindsym $mod+endash nop
	bindsym $mod+Shift+endash nop
	bindsym Alt_L+Control+endash nop
	bindsym eng nop
	bindsym $mod+eng nop
	bindsym $mod+Shift+eng nop
	bindsym Alt_L+Control+eng nop
	bindsym equal nop
	bindsym $mod+equal nop
	bindsym $mod+Shift+equal nop
	bindsym Alt_L+Control+equal nop
	bindsym Escape nop
	bindsym $mod+Escape nop
	bindsym $mod+Shift+Escape nop
	bindsym Alt_L+Control+Escape nop
	bindsym eth nop
	bindsym $mod+eth nop
	bindsym $mod+Shift+eth nop
	bindsym Alt_L+Control+eth nop
	bindsym EuroSign nop
	bindsym $mod+EuroSign nop
	bindsym $mod+Shift+EuroSign nop
	bindsym Alt_L+Control+EuroSign nop
	bindsym exclam nop
	bindsym $mod+exclam nop
	bindsym $mod+Shift+exclam nop
	bindsym Alt_L+Control+exclam nop
	bindsym exclamdown nop
	bindsym $mod+exclamdown nop
	bindsym $mod+Shift+exclamdown nop
	bindsym Alt_L+Control+exclamdown nop
	bindsym f nop
	bindsym $mod+f nop
	bindsym $mod+Shift+f nop
	bindsym Alt_L+Control+f nop
	bindsym F nop
	bindsym $mod+F nop
	bindsym $mod+Shift+F nop
	bindsym Alt_L+Control+F nop
	bindsym F1 nop
	bindsym $mod+F1 nop
	bindsym $mod+Shift+F1 nop
	bindsym Alt_L+Control+F1 nop
	bindsym F10 nop
	bindsym $mod+F10 nop
	bindsym $mod+Shift+F10 nop
	bindsym Alt_L+Control+F10 nop
	bindsym F11 nop
	bindsym $mod+F11 nop
	bindsym $mod+Shift+F11 nop
	bindsym Alt_L+Control+F11 nop
	bindsym F12 nop
	bindsym $mod+F12 nop
	bindsym $mod+Shift+F12 nop
	bindsym Alt_L+Control+F12 nop
	bindsym F2 nop
	bindsym $mod+F2 nop
	bindsym $mod+Shift+F2 nop
	bindsym Alt_L+Control+F2 nop
	bindsym F3 nop
	bindsym $mod+F3 nop
	bindsym $mod+Shift+F3 nop
	bindsym Alt_L+Control+F3 nop
	bindsym F4 nop
	bindsym $mod+F4 nop
	bindsym $mod+Shift+F4 nop
	bindsym Alt_L+Control+F4 nop
	bindsym F5 nop
	bindsym $mod+F5 nop
	bindsym $mod+Shift+F5 nop
	bindsym Alt_L+Control+F5 nop
	bindsym F6 nop
	bindsym $mod+F6 nop
	bindsym $mod+Shift+F6 nop
	bindsym Alt_L+Control+F6 nop
	bindsym F7 nop
	bindsym $mod+F7 nop
	bindsym $mod+Shift+F7 nop
	bindsym Alt_L+Control+F7 nop
	bindsym F8 nop
	bindsym $mod+F8 nop
	bindsym $mod+Shift+F8 nop
	bindsym Alt_L+Control+F8 nop
	bindsym F9 nop
	bindsym $mod+F9 nop
	bindsym $mod+Shift+F9 nop
	bindsym Alt_L+Control+F9 nop
	bindsym g nop
	bindsym $mod+g nop
	bindsym $mod+Shift+g nop
	bindsym Alt_L+Control+g nop
	bindsym G nop
	bindsym $mod+G nop
	bindsym $mod+Shift+G nop
	bindsym Alt_L+Control+G nop
	bindsym greater nop
	bindsym $mod+greater nop
	bindsym $mod+Shift+greater nop
	bindsym Alt_L+Control+greater nop
	bindsym Greek_pi nop
	bindsym $mod+Greek_pi nop
	bindsym $mod+Shift+Greek_pi nop
	bindsym Alt_L+Control+Greek_pi nop
	bindsym guillemotleft nop
	bindsym $mod+guillemotleft nop
	bindsym $mod+Shift+guillemotleft nop
	bindsym Alt_L+Control+guillemotleft nop
	bindsym guillemotright nop
	bindsym $mod+guillemotright nop
	bindsym $mod+Shift+guillemotright nop
	bindsym Alt_L+Control+guillemotright nop
	bindsym h nop
	bindsym $mod+h nop
	bindsym $mod+Shift+h nop
	bindsym Alt_L+Control+h nop
	bindsym H nop
	bindsym $mod+H nop
	bindsym $mod+Shift+H nop
	bindsym Alt_L+Control+H nop
	bindsym Home nop
	bindsym $mod+Home nop
	bindsym $mod+Shift+Home nop
	bindsym Alt_L+Control+Home nop
	bindsym hstroke nop
	bindsym $mod+hstroke nop
	bindsym $mod+Shift+hstroke nop
	bindsym Alt_L+Control+hstroke nop
	bindsym i nop
	bindsym $mod+i nop
	bindsym $mod+Shift+i nop
	bindsym Alt_L+Control+i nop
	bindsym I nop
	bindsym $mod+I nop
	bindsym $mod+Shift+I nop
	bindsym Alt_L+Control+I nop
	bindsym Insert nop
	bindsym $mod+Insert nop
	bindsym $mod+Shift+Insert nop
	bindsym Alt_L+Control+Insert nop
	bindsym ISO_Level3_Shift nop
	bindsym $mod+ISO_Level3_Shift nop
	bindsym $mod+Shift+ISO_Level3_Shift nop
	bindsym Alt_L+Control+ISO_Level3_Shift nop
	bindsym j nop
	bindsym $mod+j nop
	bindsym $mod+Shift+j nop
	bindsym Alt_L+Control+j nop
	bindsym J nop
	bindsym $mod+J nop
	bindsym $mod+Shift+J nop
	bindsym Alt_L+Control+J nop
	bindsym k nop
	bindsym $mod+k nop
	bindsym $mod+Shift+k nop
	bindsym Alt_L+Control+k nop
	bindsym K nop
	bindsym $mod+K nop
	bindsym $mod+Shift+K nop
	bindsym Alt_L+Control+K nop
	bindsym kra nop
	bindsym $mod+kra nop
	bindsym $mod+Shift+kra nop
	bindsym Alt_L+Control+kra nop
	bindsym l nop
	bindsym $mod+l nop
	bindsym $mod+Shift+l nop
	bindsym Alt_L+Control+l nop
	bindsym L nop
	bindsym $mod+L nop
	bindsym $mod+Shift+L nop
	bindsym Alt_L+Control+L nop
	bindsym Left nop
	bindsym $mod+Left nop
	bindsym $mod+Shift+Left nop
	bindsym Alt_L+Control+Left nop
	bindsym leftarrow nop
	bindsym $mod+leftarrow nop
	bindsym $mod+Shift+leftarrow nop
	bindsym Alt_L+Control+leftarrow nop
	bindsym leftdoublequotemark nop
	bindsym $mod+leftdoublequotemark nop
	bindsym $mod+Shift+leftdoublequotemark nop
	bindsym Alt_L+Control+leftdoublequotemark nop
	bindsym less nop
	bindsym $mod+less nop
	bindsym $mod+Shift+less nop
	bindsym Alt_L+Control+less nop
	bindsym lstroke nop
	bindsym $mod+lstroke nop
	bindsym $mod+Shift+lstroke nop
	bindsym Alt_L+Control+lstroke nop
	bindsym m nop
	bindsym $mod+m nop
	bindsym $mod+Shift+m nop
	bindsym Alt_L+Control+m nop
	bindsym M nop
	bindsym $mod+M nop
	bindsym $mod+Shift+M nop
	bindsym Alt_L+Control+M nop
	bindsym Menu nop
	bindsym $mod+Menu nop
	bindsym $mod+Shift+Menu nop
	bindsym Alt_L+Control+Menu nop
	bindsym minus nop
	bindsym $mod+minus nop
	bindsym $mod+Shift+minus nop
	bindsym Alt_L+Control+minus nop
	bindsym mu nop
	bindsym $mod+mu nop
	bindsym $mod+Shift+mu nop
	bindsym Alt_L+Control+mu nop
	bindsym n nop
	bindsym $mod+n nop
	bindsym $mod+Shift+n nop
	bindsym Alt_L+Control+n nop
	bindsym N nop
	bindsym $mod+N nop
	bindsym $mod+Shift+N nop
	bindsym Alt_L+Control+N nop
	bindsym Next nop
	bindsym $mod+Next nop
	bindsym $mod+Shift+Next nop
	bindsym Alt_L+Control+Next nop
	bindsym numbersign nop
	bindsym $mod+numbersign nop
	bindsym $mod+Shift+numbersign nop
	bindsym Alt_L+Control+numbersign nop
	bindsym Num_Lock nop
	bindsym $mod+Num_Lock nop
	bindsym $mod+Shift+Num_Lock nop
	bindsym Alt_L+Control+Num_Lock nop
	bindsym o nop
	bindsym $mod+o nop
	bindsym $mod+Shift+o nop
	bindsym Alt_L+Control+o nop
	bindsym O nop
	bindsym $mod+O nop
	bindsym $mod+Shift+O nop
	bindsym Alt_L+Control+O nop
	bindsym oe nop
	bindsym $mod+oe nop
	bindsym $mod+Shift+oe nop
	bindsym Alt_L+Control+oe nop
	bindsym onehalf nop
	bindsym $mod+onehalf nop
	bindsym $mod+Shift+onehalf nop
	bindsym Alt_L+Control+onehalf nop
	bindsym ordfeminine nop
	bindsym $mod+ordfeminine nop
	bindsym $mod+Shift+ordfeminine nop
	bindsym Alt_L+Control+ordfeminine nop
	bindsym oslash nop
	bindsym $mod+oslash nop
	bindsym $mod+Shift+oslash nop
	bindsym Alt_L+Control+oslash nop
	bindsym Oslash nop
	bindsym $mod+Oslash nop
	bindsym $mod+Shift+Oslash nop
	bindsym Alt_L+Control+Oslash nop
	bindsym p nop
	bindsym $mod+p nop
	bindsym $mod+Shift+p nop
	bindsym Alt_L+Control+p nop
	bindsym P nop
	bindsym $mod+P nop
	bindsym $mod+Shift+P nop
	bindsym Alt_L+Control+P nop
	bindsym parenleft nop
	bindsym $mod+parenleft nop
	bindsym $mod+Shift+parenleft nop
	bindsym Alt_L+Control+parenleft nop
	bindsym parenright nop
	bindsym $mod+parenright nop
	bindsym $mod+Shift+parenright nop
	bindsym Alt_L+Control+parenright nop
	bindsym Pause nop
	bindsym $mod+Pause nop
	bindsym $mod+Shift+Pause nop
	bindsym Alt_L+Control+Pause nop
	bindsym percent nop
	bindsym $mod+percent nop
	bindsym $mod+Shift+percent nop
	bindsym Alt_L+Control+percent nop
	bindsym period nop
	bindsym $mod+period nop
	bindsym $mod+Shift+period nop
	bindsym Alt_L+Control+period nop
	bindsym plus nop
	bindsym $mod+plus nop
	bindsym $mod+Shift+plus nop
	bindsym Alt_L+Control+plus nop
	bindsym plusminus nop
	bindsym $mod+plusminus nop
	bindsym $mod+Shift+plusminus nop
	bindsym Alt_L+Control+plusminus nop
	bindsym Print nop
	bindsym $mod+Print nop
	bindsym $mod+Shift+Print nop
	bindsym Alt_L+Control+Print nop
	bindsym Prior nop
	bindsym $mod+Prior nop
	bindsym $mod+Shift+Prior nop
	bindsym Alt_L+Control+Prior nop
	bindsym q nop
	bindsym $mod+q nop
	bindsym $mod+Shift+q nop
	bindsym Alt_L+Control+q nop
	bindsym Q nop
	bindsym $mod+Q nop
	bindsym $mod+Shift+Q nop
	bindsym Alt_L+Control+Q nop
	bindsym question nop
	bindsym $mod+question nop
	bindsym $mod+Shift+question nop
	bindsym Alt_L+Control+question nop
	bindsym quotedbl nop
	bindsym $mod+quotedbl nop
	bindsym $mod+Shift+quotedbl nop
	bindsym Alt_L+Control+quotedbl nop
	bindsym r nop
	bindsym $mod+r nop
	bindsym $mod+Shift+r nop
	bindsym Alt_L+Control+r nop
	bindsym R nop
	bindsym $mod+R nop
	bindsym $mod+Shift+R nop
	bindsym Alt_L+Control+R nop
	bindsym registered nop
	bindsym $mod+registered nop
	bindsym $mod+Shift+registered nop
	bindsym Alt_L+Control+registered nop
	bindsym Return nop
	bindsym $mod+Return nop
	bindsym $mod+Shift+Return nop
	bindsym Alt_L+Control+Return nop
	bindsym Right nop
	bindsym $mod+Right nop
	bindsym $mod+Shift+Right nop
	bindsym Alt_L+Control+Right nop
	bindsym rightarrow nop
	bindsym $mod+rightarrow nop
	bindsym $mod+Shift+rightarrow nop
	bindsym Alt_L+Control+rightarrow nop
	bindsym rightdoublequotemark nop
	bindsym $mod+rightdoublequotemark nop
	bindsym $mod+Shift+rightdoublequotemark nop
	bindsym Alt_L+Control+rightdoublequotemark nop
	bindsym s nop
	bindsym $mod+s nop
	bindsym $mod+Shift+s nop
	bindsym Alt_L+Control+s nop
	bindsym S nop
	bindsym $mod+S nop
	bindsym $mod+Shift+S nop
	bindsym Alt_L+Control+S nop
	bindsym Scroll_Lock nop
	bindsym $mod+Scroll_Lock nop
	bindsym $mod+Shift+Scroll_Lock nop
	bindsym Alt_L+Control+Scroll_Lock nop
	bindsym section nop
	bindsym $mod+section nop
	bindsym $mod+Shift+section nop
	bindsym Alt_L+Control+section nop
	bindsym semicolon nop
	bindsym $mod+semicolon nop
	bindsym $mod+Shift+semicolon nop
	bindsym Alt_L+Control+semicolon nop
	bindsym Shift_L nop
	bindsym $mod+Shift_L nop
	bindsym $mod+Shift+Shift_L nop
	bindsym Alt_L+Control+Shift_L nop
	bindsym Shift_R nop
	bindsym $mod+Shift_R nop
	bindsym $mod+Shift+Shift_R nop
	bindsym Alt_L+Control+Shift_R nop
	bindsym slash nop
	bindsym $mod+slash nop
	bindsym $mod+Shift+slash nop
	bindsym Alt_L+Control+slash nop
	bindsym space nop
	bindsym $mod+space nop
	bindsym $mod+Shift+space nop
	bindsym Alt_L+Control+space nop
	bindsym ssharp nop
	bindsym $mod+ssharp nop
	bindsym $mod+Shift+ssharp nop
	bindsym Alt_L+Control+ssharp nop
	bindsym sterling nop
	bindsym $mod+sterling nop
	bindsym $mod+Shift+sterling nop
	bindsym Alt_L+Control+sterling nop
	bindsym Super_L nop
	bindsym $mod+Super_L nop
	bindsym $mod+Shift+Super_L nop
	bindsym Alt_L+Control+Super_L nop
	bindsym t nop
	bindsym $mod+t nop
	bindsym $mod+Shift+t nop
	bindsym Alt_L+Control+t nop
	bindsym T nop
	bindsym $mod+T nop
	bindsym $mod+Shift+T nop
	bindsym Alt_L+Control+T nop
	bindsym Tab nop
	bindsym $mod+Tab nop
	bindsym $mod+Shift+Tab nop
	bindsym Alt_L+Control+Tab nop
	bindsym thorn nop
	bindsym $mod+thorn nop
	bindsym $mod+Shift+thorn nop
	bindsym Alt_L+Control+thorn nop
	bindsym u nop
	bindsym $mod+u nop
	bindsym $mod+Shift+u nop
	bindsym Alt_L+Control+u nop
	bindsym U nop
	bindsym $mod+U nop
	bindsym $mod+Shift+U nop
	bindsym Alt_L+Control+U nop
	bindsym underscore nop
	bindsym $mod+underscore nop
	bindsym $mod+Shift+underscore nop
	bindsym Alt_L+Control+underscore nop
	bindsym Up nop
	bindsym $mod+Up nop
	bindsym $mod+Shift+Up nop
	bindsym Alt_L+Control+Up nop
	bindsym v nop
	bindsym $mod+v nop
	bindsym $mod+Shift+v nop
	bindsym Alt_L+Control+v nop
	bindsym V nop
	bindsym $mod+V nop
	bindsym $mod+Shift+V nop
	bindsym Alt_L+Control+V nop
	bindsym w nop
	bindsym $mod+w nop
	bindsym $mod+Shift+w nop
	bindsym Alt_L+Control+w nop
	bindsym W nop
	bindsym $mod+W nop
	bindsym $mod+Shift+W nop
	bindsym Alt_L+Control+W nop
	bindsym x nop
	bindsym $mod+x nop
	bindsym $mod+Shift+x nop
	bindsym Alt_L+Control+x nop
	bindsym X nop
	bindsym $mod+X nop
	bindsym $mod+Shift+X nop
	bindsym Alt_L+Control+X nop
	bindsym XF86Display nop
	bindsym $mod+XF86Display nop
	bindsym $mod+Shift+XF86Display nop
	bindsym Alt_L+Control+XF86Display nop
	bindsym XF86Sleep nop
	bindsym $mod+XF86Sleep nop
	bindsym $mod+Shift+XF86Sleep nop
	bindsym Alt_L+Control+XF86Sleep nop
	bindsym y nop
	bindsym $mod+y nop
	bindsym $mod+Shift+y nop
	bindsym Alt_L+Control+y nop
	bindsym Y nop
	bindsym $mod+Y nop
	bindsym $mod+Shift+Y nop
	bindsym Alt_L+Control+Y nop
	bindsym yen nop
	bindsym $mod+yen nop
	bindsym $mod+Shift+yen nop
	bindsym Alt_L+Control+yen nop
	bindsym z nop
	bindsym $mod+z nop
	bindsym $mod+Shift+z nop
	bindsym Alt_L+Control+z nop
	bindsym Z nop
	bindsym $mod+Z nop
	bindsym $mod+Shift+Z nop
	bindsym Alt_L+Control+Z nop
	bindsym button1 nop
	bindsym $mod+button1 nop
	bindsym $mod+Shift+button1 nop
	bindsym Alt_L+Control+button1 nop
	bindsym button2 nop
	bindsym $mod+button2 nop
	bindsym $mod+Shift+button2 nop
	bindsym Alt_L+Control+button2 nop
	bindsym button3 nop
	bindsym $mod+button3 nop
	bindsym $mod+Shift+button3 nop
	bindsym Alt_L+Control+button3 nop

}

bindsym $mod+Shift+Pause mode "null"
