dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
if [[ $(HubstaffCLI status | jq -r '.tracking') == 'false' ]]; then
    HubstaffCLI resume 
else 
    HubstaffCLI stop
fi

