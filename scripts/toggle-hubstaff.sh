if [[ $(HubstaffCLI status | jq -r '.tracking') == 'false' ]]; then
    HubstaffCLI resume 
else 
    HubstaffCLI stop
fi

