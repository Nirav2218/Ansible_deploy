#! /bin/bash

echo"--------------------------------------$(date)"
current_date=$(date -I)

# remove slash after dir name when we use tab
if [[ $1 == */ ]]; then
  # Remove trailing slash
  new_1="${1%/}"
fi

# remove the given dir from $2 
if [ $# > 1 ]; then

# with skip flag
src_file=()
file=()
file_path=()

rm_dir=()
src_dir=()
dir=()
dir_path=()

# for loop in given arguments
for ((i=1; i<=$#; i++)); do
    case "${!i}" in
        --skip=*) 
            # Add skip values to the rm_dir array
              rm_dir+=( "${!i#*=}" ) 
            ;;
        --dest=*) 
            # Add skip values to the rm_dir array
              dest_pat=( "${!i#*=}" ) 
            ;;
        *)

            # Add source directories to the src_dir array
                if [ -f "${!i#*=}" ] ;
                then
                  src_file+=( "${!i#*=}" )
                fi
                src_dir+=( "${!i#*=}" )

            ;;
    esac
done
# echo "src_dir---- ${src_dir[@]}"
# echo "rm_dir---- ${rm_dir[@]}"

# check if  file is skipped or not
for i in ${src_file[@]};
do
  if ! [[ "${rm_dir[*]}" =~ $i || "${rm_dir[*]}" =~ $(pwd)/$i ]]; then
    file+=("$i")
  fi
done

# check if source directory is null then not consider the * to copy
for j in ${src_dir[@]};
do
if [ -d $j ]; 
then
  cd $j 
  if [ ! -z "$(ls -A))" ]; then
  for i in *;
  do
  # check if the sub dir skipped or not
    if ! [[ "${rm_dir[*]}" =~ $i || "${rm_dir[*]}" =~ $(pwd)/$i ]]; then
      if [ -d "$i" ] ;
      then
        dir+=("$i")    
      else
        file+=("$i")
      fi
    fi
  done
  fi
  cd -
fi
done

# find the absolute path for copy for files
for VAR in ${file[@]};
do
  file_path+=( $(find "$(pwd)" -type f -name "$VAR") )
done

# find the absolute path for copy for dir
for VAR in ${dir[@]};
do
  dir_path+=( $(find "$(pwd)" -type d -name "$VAR") )
done
fi

# prepare ansible-playbook file
SUB=/

case $new_1 in

# case : where we give absolute path of the file or folder
*"$SUB"*)

# add files parent dir to src_dir
  for VAR in ${file[@]};
do
  src_dir+=( "$(dirname $VAR)" )
done


# when we want to copy multiple dir or file with path
if [ $# > 1 ] ;
then
  for j in ${src_dir[@]};
  do
    cat <<EOF >/opt/ansible_scripts/mkdir.sh
  if [ ! -d $j ];
then
  mkdir -p $j
else
  echo "The '$j' directory is present there."
fi
EOF
  done
    
  else
  single_dir=${new_1%/*}
  cat <<EOF >/opt/ansible_scripts/mkdir.sh
  if [ ! -d $single_dir ];
then
  mkdir -p $single_dir
else
  echo "The '$single_dir' directory is present there."
fi
EOF
fi

# creating playbook file

# copy mkdir.sh and execute on remote server
  cat <<EOF >/opt/ansible_scripts/script.yml
---
- name: script execute
  hosts: dist
  become: yes
  tasks:
    - name: Make a backup copy of the folder
      command: cp -r /var/www/html/openpbx /var/www/html/openpbx_$current_date.bkp
    - name: check for directory exist
      synchronize:
        src: mkdir.sh
        dest: /opt/
    - name: permit script
      command: chmod +x /opt/mkdir.sh
    - name: execute script
      command: /usr/bin/bash /opt/mkdir.sh
EOF

# if multiple arguments
if [ $# > 1 ];
then
  for i in ${dir_path[@]};
  do
  cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: synchronize dir $i
      synchronize:
        src: $i
        dest: $i
        recursive: yes
EOF
  done
        cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: change ownership to freeswitch
      command: chown -R freeswitch:daemon /var/www/html/openpbx
EOF
  for i in ${file_path[@]};
  do
  cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: synchronize file $i
      synchronize:
        src: $i
        dest: $i
        recursive: yes
EOF
  done
        cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: change ownership to freeswitch
      command: chown -R freeswitch:daemon /var/www/html/openpbx
EOF
# if there is only one argument
  else
  cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: synchronize dir $new_1
      synchronize:
        src: $new_1
        dest: $new_1
        recursive: yes
EOF
fi
        cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: change ownership to freeswitch
      command: chown -R freeswitch:daemon /var/www/html/openpbx
EOF
  ;;
*)   

# prepare script.yml if cmd execute from pwd of src or files
  cat <<EOF >/opt/ansible_scripts/mkdir.sh
if [ ! -d $(pwd) ];
then
  mkdir -p $(pwd)
else
  echo "The '$(pwd)' directory is present there."
fi

EOF
if [ $# > 1 ] ;
then
  for val in ${src_dir[@]};
  do
  cat <<EOF >>/opt/ansible_scripts/mkdir.sh
  if [ ! -d .$val ]; then
    mkdir -p $val
  else
    echo "The '$val' directory is already present."
  fi
EOF
  done
  else
  single_dir=${new_1%/*}
  if [ -d single_dir ] ;
  then
      cat <<EOF >/opt/ansible_scripts/mkdir.sh
  if [ ! -d $single_dir ];
then
  mkdir -p $single_dir
else
  echo "The '$single_dir' directory is present there."
fi
EOF
  fi
fi

  # creating playbook file

# copy and execute mkdir.sh on remote server
  cat <<EOF >/opt/ansible_scripts/script.yml
---
- name: script execute
  hosts: dist
  become: yes
  tasks:
    - name: Make a backup copy of the folder
      command: cp -r /var/www/html/openpbx /var/www/html/openpbx_$current_date.bkp
    - name: check for directory exist
      synchronize:
        src: mkdir.sh
        dest: /opt/
    - name: permit script
      command: chmod +x /opt/mkdir.sh
    - name: execute script
      command: /usr/bin/bash /opt/mkdir.sh
EOF

# when we have to copy multiple things or have multi args

# directories
if [ $# -gt 1 ]; then
  for i in ${dir_path[@]}; do
    cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: synchronize $i
      synchronize:
        src: $i
        dest: $i
        recursive: yes
EOF
  done
        cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: change ownership to freeswitch
      command: chown -R freeswitch:daemon /var/www/html/openpbx
EOF

# files
  for i in ${file_path[@]}; do
    cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: synchronize $i
      synchronize:
        src: $i
        dest: $i
        recursive: yes
EOF
  done
      cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: change ownership to freeswitch
      command: chown -R freeswitch:daemon /var/www/html/openpbx
EOF
else
# only one args at pwd
  cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: synchronize $new_1
      synchronize:
        src: $(pwd)/$new_1
        dest: $(pwd)/
        recursive: yes
EOF
        cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: change ownership to freeswitch
      command: chown -R freeswitch:daemon /var/www/html/openpbx
EOF
fi
  ;;
esac

chmod 777 script.yml
ansible-playbook -v -i /opt/ansible_scripts/hosts.ini /opt/ansible_scripts/script.yml