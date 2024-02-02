#! /bin/bash

cd $1
for VAR in $(ls)
do
    echo $VAR
done

dir_arr=()
for ((i=2; i<=$#; i++)); do
    dir_arr+=("${!i}")
done
for dir in "${dir_arr[@]}"; do
    echo $dir
done


for dir in "${all_dir[@]}"; do
  cat <<EOF >>/opt/ansible_scripts/script.yml
      copy:
        src: $dir
        dest: $dir
EOF
done