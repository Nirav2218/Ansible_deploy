#! /bin/bash

echo "--------------------------------------$(date)"
current_date=$(date -I)

# remove slash after dir name when we use tab
if [[ $1 == */ ]]; then
    # Remove trailing slash
    new_1="${1%/}"
fi

# remove the given dir from $2
if [ $# ] >1; then

    # with skip flag
    src_file=()
    file=()
    file_path=()
    src_dir_add=()
    rm_things_file_path=()
    rm_things=()
    src_dir=()
    dir=()
    dir_path=()

    # for loop in given arguments
    for ((i = 1; i <= $#; i++)); do
        case "${!i}" in
        --skip=*)
            # Add skip values to the rm_things array
            rm_things+=("${!i#*=}")
            ;;
        --dest=*)
            # Add skip values to the rm_things array
            dest_path_=("${!i#*=}")
            ;;
        *)
            # Add source directories to the src_dir array
            if [ -f "${!i#*=}" ]; then
                src_file+=("${!i#*=}")
            else
                src_dir+=("${!i#*=}")
            fi
            ;;
        esac
    done

    # check here dest path is mandatory
    if [ -z $dest_path_ ]; then
        echo "please set destination path using --dest flag --->EXAMPLE: --dest=/var/www/html/folder"
        exit 1
    fi
    dest_path="${dest_path_%/}"

    echo "dest_path.....................$dest_path"
    echo "src_dir......................${src_dir[@]}"
    echo "src_files....................${src_file[@]}"
    echo "rm_things.................... ${rm_things[@]}"

    for i in "${rm_things[@]}"; do
        rm_things_file_path+=( $(find "$(pwd)"  -name "$i" -printf "%P\n") )
    done
    echo "rm_things_file_path-----------${rm_things_file_path[@]}"

    # check if  file is skipped or not
    for i in ${src_file[@]}; do
        if ! [[ "${rm_things_file_path[*]}" =~ $i ]]; then
            file+=("$i")
        fi
    done

    # check if source directory is null then not consider the * to copy
    for j in ${src_dir[@]}; do
        if [ -d $j ]; then
            cd $j
            if [ ! -z "$(ls -A))" ]; then
                for i in *; do
                    z=$(find "$(pwd)"  -name "$i" -printf "%P\n") 
                    # check if the sub dir or file skipped or not
                    if ! [[ "${rm_things_file_path[*]}" =~ $z ]]; then
                        if [ -d "$z" ]; then
                            dir+=("$z")
                        else
                            file+=("$z")
                        fi
                    fi
                done
            fi
            cd -
        fi
    done

    # find the absolute path for copy for files
    for VAR in "${file[@]}"; do
        file_path+=($(find $(pwd) -type f -name "$VAR" -printf "%P\n"))
    done
    echo "files_path---- ${file_path[@]}"

    # find the absolute path for copy for dir
    for VAR in "${dir[@]}"; do
        dir_path+=($(find $(pwd) -type d -name "$VAR" -printf "%P\n"))
    done
    echo "dirs_path---- ${dir_path[@]}"

fi

# prepare ansible-playbook file
# add files parent dir to src_dir
for VAR in ${file_path[@]}; do
    dir_name=$(dirname $VAR)
    if [[ !  ${src_dir[@]}  =~  $dir_name ]]; then
        src_dir+=($dir_name)
    fi
done

for VAR in ${dir_path[@]}; do
    dir_name=$(dirname $VAR)
    if [[ !  ${src_dir[@]}  =~  $dir_name ]]; then
        src_dir+=($dir_name)
    fi
done

echo "src_dir---- ${src_dir[@]}"
echo "dir_path---- ${dir_path[@]}"
echo "file_path---- ${file_path[@]}"
# when we want to copy multiple dir or file with path
if [ $# ] >1; then
    for j in ${src_dir[@]}; do
        cat <<EOF >>/opt/ansible_scripts/mkdir.sh
  if [ ! -d $dest_path/$j ];
then
  mkdir -p $dest_path/$j
else
  echo "The '$j' directory is present there."
fi
EOF
    done

else
    single_dir=${new_1%/*}
    cat <<EOF >/opt/ansible_scripts/mkdir.sh
  if [ ! -d $dest_path/$single_dir ];
then
  mkdir -p $dest_path/$single_dir
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
      command: cp -r $dest_path $dest_path$current_date.bkp
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
if [ $# ] >1; then
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
      command: chown -R freeswitch:daemon $dest_path
EOF
    # if there is only one argument
else
    cat <<EOF >>/opt/ansible_scripts/script.yml
    - name: synchronize dir $new_1
      synchronize:
        src: $(pwd)/$new_1
        dest: $dest_path/$new_1
        recursive: yes
    - name: change ownership to freeswitch
      command: chown -R freeswitch:daemon $dest_path
EOF
fi

chmod 777 script.yml
ansible-playbook -v -i /opt/ansible_scripts/hosts.ini /opt/ansible_scripts/script.yml
rm -rf /opt/ansible_scripts/mkdir.sh
