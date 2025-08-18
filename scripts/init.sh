#! /usr/bin/bash

/usr/bin/solaar -w hide &

/home/amund/.dotfiles/scripts/git-maintenance.sh &

/home/amund/.dotfiles/scripts/start-slack.sh &

/home/amund/.dotfiles/scripts/break-reminder.sh $((30 * 60)) &

/home/amund/.dotfiles/scripts/pr-review.sh /home/amund/git/ignite/main Amund211 &

sleep 60 && /home/amund/.dotfiles/scripts/pr-review.sh /home/amund/git/ignite/go-packages Amund211 &

disown -a
