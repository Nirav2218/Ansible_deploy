
#!/bin/bash

# Check if /tmp2 exists
if [ ! -d "/opt/openpbx/tmp2" ]; then
    mkdir -p "/opt/openpbx/tmp2"
else
    echo "/tmp2 already exists"
fi

# Check if /tmp1 exists
if [ ! -d "/opt/openpbx/tmp1" ]; then
    mkdir -p "/opt/openpbx/tmp1"
else
    echo "/tmp1 already exists"
fi
