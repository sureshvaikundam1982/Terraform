#!/bin/bash

azcopy sync \
"/Users/sureshvaikuntam/Downloads/mywebsite" \
"https://whizstorage121982.blob.core.windows.net/learncontainer" \
--recursive=true
