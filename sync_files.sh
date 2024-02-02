#! /bin/bash
current_date=$(date -I)
if [[ $1 == */ ]]; then
  # Remove trailing slash
  new_1="${1%/}"

fi

# prepare ansible-playbook file
SUB=/

case $new_1 in
*"$SUB"*)
  # prepare script for checking if directror exist or not ?
  dir=${new_1%/*}

  cat <<EOF >/opt/ansible_scripts/mkdir.sh
if [ ! -d $dir ]
then
  mkdir -p $dir
else
  echo "The '$dir' directory is present there."
fi
EOF

  # creating playbook file
  cat <<EOF >/opt/ansible_scripts/script.yml
---
- name: script execute
  hosts: dist
  become: yes
  tasks:
    - name: Make a backup copy of the folder
      command: cp -r /var/www/html/openpbx /var/www/html/openpbx_$current_date.bkp
    - name: check for directory exist
      copy:
        src: mkdir.sh
        dest: /opt/
    - name: permit script
      command: chmod +x /opt/mkdir.sh
    - name: execute script
      command: /usr/bin/bash /opt/mkdir.sh
    - name: copy script
      copy:
        src: $new_1
        dest: $new_1
    - name: change ownership to freeswitch
      command: chown -R freeswitch:daemon /var/www/html/openpbx
EOF
  ;;
*)

  # prepare script for checking if directror exist or not ?
  cat <<EOF >/opt/ansible_scripts/mkdir.sh
if [ ! -d $(pwd) ]
then
  mkdir -p $(pwd)
else
  echo "The '$(pwd)' directory is present there."
fi
EOF

  # creating playbook file
  cat <<EOF >/opt/ansible_scripts/script.yml
---
- name: script execute
  hosts: dist
  become: yes
  tasks:
    - name: Make a backup copy of the folder
      command: cp -r /var/www/html/openpbx /var/www/html/openpbx_$current_date.bkp
    - name: check for directory exist
      copy:
        src: mkdir.sh
        dest: /opt/
    - name: permit script
      command: chmod +x /opt/mkdir.sh
    - name: execute script
      command: /usr/bin/bash /opt/mkdir.sh
    - name: copy files or directories
      copy:
        src: $(pwd)/$new_1
        dest: $(pwd)/
    - name: change ownership to freeswitch
      command: chown -R freeswitch:daemon /var/www/html/openpbx
EOF
  ;;
esac

chmod 777 script.yml
ansible-playbook -i /opt/ansible_scripts/hosts.ini /opt/ansible_scripts/script.yml
