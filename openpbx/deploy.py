import os
import sys
import re
import datetime

user="freeswitch"
group="daemon"

current_time = datetime.datetime.now()
current_time=current_time.strftime("%Y-%m-%d_%H:%M:%S")
def get_skip_args_and_dest():
    skip_args = []
    # Iterate through command-line arguments
    for arg in sys.argv[1:]:
        if arg.startswith("--skip="):
            skip_value = arg[len("--skip="):]
            skip_args.append(skip_value)
        else:
            arg.startswith("--dest=")
            dest=arg[len("--dest="):]
    return skip_args, dest



skip_args, dest=get_skip_args_and_dest()
dest=dest.rstrip("/")
print()
print("skip_args----------------------------------->\n",skip_args)
print()
print("dest_path----------------------------------->\n",dest)

def collect_sub_files_and_dirs(directory):
    sub_files = []
    sub_dirs = []

    for root, dirs, files in os.walk(directory):
        for file in files:
            sub_files.append(os.path.join(root, file))
        for subdir in dirs:
            sub_dirs.append(os.path.join(root, subdir))
    return sub_files, sub_dirs

pwd = os.getcwd()

sub_files, sub_dirs = collect_sub_files_and_dirs(pwd)

print()
print("sub_dirs----------------------------------->\n",sub_dirs)

skip_mkdir=[]
skip_args_path=[]
for i in skip_args:
    find_command = f"find  {pwd} -name {i} -printf '%P\'"
    output = os.popen(find_command).read()
    skip_args_path.append(pwd+"/"+output)
print()
print("skip_args_path----------------------------------->\n",skip_args_path)
skip_dir=[]
skip_files=[]

for item in skip_args_path:
    if os.path.isdir(item):
        skip_dir.append(item)
    elif os.path.isfile(item):
        skip_files.append(item)


print()
print("skip_dir----------------------------------->\n",skip_dir)
print()
print("skip_files----------------------------------->\n",skip_files)


final_src_dirs=[]

# Iterate through sub_dirs
for dir_path in sub_dirs:
    for i in skip_dir:
        if dir_path != i:
            final_src_dirs.append(dir_path)

    
print()
print("final_src_dirs----------------------------------->\n",final_src_dirs)

source_to_copy=[]
for i in final_src_dirs:
    files_and_dirs = os.listdir(i)
    if files_and_dirs:  
        for item in files_and_dirs:
            source_to_copy.append(item)
mkdir_list=[]
source_to_copy_with_base_path=[]
for i in source_to_copy:
    find_command = f"find  {pwd} -name {i} -printf '%P\'"
    output = os.popen(find_command).read()
    mkdir_list.append(output)
    source_to_copy_with_base_path.append(pwd+"/"+output)

print()
print("mkdir_list----------------------------------->\n",mkdir_list)


print()
print("source_to_copy_with_base_path----------------------------------->\n",source_to_copy_with_base_path)

final_source_dir_to_copy=[]
for i in source_to_copy_with_base_path:
    for j in skip_dir:
        if i != j:
            final_source_dir_to_copy.append(i)

print()
print("final_source_dir_to_copy----------------------------------->\n",final_source_dir_to_copy)

final_source_to_copy=[]
for i in final_source_dir_to_copy:
    for j in skip_files:
        if i != j:
            final_source_to_copy.append(i)

print()
print("final_source_to_copy----------------------------------->\n",final_source_to_copy)
FINAL_SRC=[]
dir_to_verify_at_host=[]
for i in final_source_to_copy:
    FINAL_SRC.append(re.sub(pwd, "", i))
    directory_name = os.path.dirname(i)
    result_dir = re.sub(pwd, "", directory_name)
    dir_to_verify_at_host.append(result_dir)

files_in_pwd = os.listdir(pwd)
for file in files_in_pwd:
    file_path = os.path.join(pwd, file)
    if os.path.isfile(file_path):
        FINAL_SRC.append("/"+file)

print()
print("FINAL_SRC----------------------------------->\n",FINAL_SRC)
print()
print("dir_to_verify_at_host----------------------------------->\n",dir_to_verify_at_host)


mkdir_file = '''
#!/bin/bash
'''
for sub_dir in dir_to_verify_at_host:
    mkdir_file += f'''
# Check if {sub_dir} exists
if [ ! -d "{dest}{sub_dir}" ]; then
    mkdir -p "{dest}{sub_dir}"
else
    echo "{sub_dir} already exists"
fi
'''

file_name = '/opt/ansible_scripts/mkdir.sh'
with open(file_name, 'w') as f:
    f.write(mkdir_file)


script_yml='''
---
'''

script_yml+=f'''
- name: script execute
  hosts: dist
  become: yes
  tasks:
    - name: Make a backup copy of the folder
      command: cp -r {dest} {dest}{current_time}.bkp
    - name: check for directory exist
      synchronize:
        src: mkdir.sh
        dest: /opt/
    - name: permit script
      command: chmod +x /opt/mkdir.sh
    - name: execute script
      command: /usr/bin/bash /opt/mkdir.sh
'''

for i in FINAL_SRC:
    script_yml+=f'''
    - name: synchronize dir {i}
      synchronize:
        src: {pwd}{i}
        dest: {dest}{i}
        recursive: yes
'''
    
script_yml+=f'''
    - name: change ownership to {user}
      command: chown -R {user}:{group} {dest}
'''

file_name = '/opt/ansible_scripts/script.yml'
with open(file_name, 'w') as f:
    f.write(script_yml)


#ansible execution
ansible_execution="ansible-playbook -v -i /opt/ansible_scripts/hosts.ini /opt/ansible_scripts/script.yml"
os.system(ansible_execution)



