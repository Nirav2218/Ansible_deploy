#! /bin/bash

# install ansible
yum install -y epel-release
yum install -y ansible

mkdir -p /var/log/sync_files

cat << 'EOF' >> ~/.bashrc
sync_files() {
    today=$(date "+%Y-%m-%d")
    echo "-------------------start = $(date) -------------------" >> /var/log/sync_files/sync_files_${today}.log
    /opt/ansible_scripts/sync_files.sh $@ | tee -a "/var/log/sync_files/sync_files_${today}.log"
}
alias sync_files='sync_files'
EOF

# check for ansible directory
if [ ! -d /opt/ansible_scripts ]; then
    mkdir /opt/ansible_scripts
else
    echo "The /opt/ansible directory is present there."
fi

# check for hosts.ini file directory
if [ ! -f /opt/ansible_scripts/hosts.ini ]; then
    touch /opt/ansible_scripts/hosts.ini
else
    echo "The /opt/ansible/hosts.ini fike is present there."
fi

source ~/.bashrc
