#! /bin/bash

if [[ $1 == */ ]]; then
  # Remove trailing slash
  new_1="${1%/}"
fi

# remove the given dir from $2
if [ $# > 1 ]

then
  dir=()
  rm_dir=()

  for((i=2;i<=$#;i++));
  do
    rm_dir+=("${!i}")
  done
  cd "$1"
  for i in *;
  do
    if ! [[ "${rm_dir[*]}" =~ $i ]]; then
        dir+=("$i")
      fi
  done
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
  tasks:
    - name: check for directory exist
      synchronize:
        src: mkdir.sh
        dest: /opt/
    - name: permit script
      command: chmod +x /opt/mkdir.sh
    - name: execute script
      command: /usr/bin/bash /opt/mkdir.sh
EOF

if [ $# > 1 ]
then
  for i in "${dir[@]}"
  do
  cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: synchronize dir $i
      synchronize:
        src: $i
        dest: $i
        recursive: yes
EOF
  done
  
  else
  cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: synchronize dir $new_1
      synchronize:
        src: $new_1
        dest: $new_1
        recursive: yes
EOF
fi
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
  tasks:
    - name: check for directory exist
      synchronize:
        src: mkdir.sh
        dest: /opt/
    - name: permit script
      command: chmod +x /opt/mkdir.sh
    - name: execute script
      command: /usr/bin/bash /opt/mkdir.sh
EOF

if [ $# -gt 1 ]; then
  for i in "${dir[@]}"; do
    cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: synchronize $i
      synchronize:
        src: $(pwd)/$i
        dest: $(pwd)/$i
        recursive: yes
EOF
  done
else
  cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: synchronize $new_1
      synchronize:
        src: $(pwd)/$new_1
        dest: $(pwd)/$new_1
        recursive: yes
EOF
fi

  ;;
esac

chmod 777 script.yml
ansible-playbook -v -i /opt/ansible_scripts/hosts.ini /opt/ansible_scripts/script.yml
