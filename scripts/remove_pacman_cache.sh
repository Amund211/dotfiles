#!/bin/sh

sudo find /var/cache/pacman/ -type f -mtime +30 -delete
