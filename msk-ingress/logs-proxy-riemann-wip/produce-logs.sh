#!/usr/bin/env bash

while true; do sleep 15 ; echo "<133>:{\"description\":\"background\"}"; done &

while true; do sleep 12 ; echo "<133>:{\"description\":\"foreground\"}"; done
