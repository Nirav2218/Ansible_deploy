#! /bin/bash

echo "--------------------------------------$(date)"
current_date=$(date +"%d_%m_%y_%H:%M:%S")
user=freeswitch
group=daemon

cat <<EOF >/opt/ansible_scripts/script.yml
---
- name: script execute
  hosts: dist
  become: yes
  tasks:
    - name: Make a backup copy of the folder
      command: cp -r $dest_path $dest_path_$current_date.bkp
    - name: check for directory exist
      synchronize:
        src: mkdir.sh
        dest: /opt/
    - name: permit script
      command: chmod +x /opt/mkdir.sh
    - name: execute script
      command: /usr/bin/bash /opt/mkdir.sh
EOF

for i in ${dir_path[@]}; do
    cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: synchronize dir $i
      synchronize:
        src: $(pwd)/$i
        dest: $dest_path/$i
        recursive: yes
EOF
done

for i in ${file_path[@]}; do
    cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: synchronize file $i
      synchronize:
        src: $(pwd)/$i
        dest: $dest_path/$i
        recursive: yes
EOF
done
cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: change ownership to freeswitch
      command: chown -R $user:$group $dest_path
EOF

chmod 777 script.yml
ansible-playbook -v -i /opt/ansible_scripts/hosts.ini /opt/ansible_scripts/script.yml
rm -rf /opt/ansible_scripts/mkdir.sh