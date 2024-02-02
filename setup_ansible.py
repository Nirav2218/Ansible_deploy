import subprocess
import os

# Install epel-release
epel_release_command = "yum install -y epel-release"
subprocess.run(epel_release_command, shell=True, check=True)

# Install ansible
ansible_install_command = "yum install -y ansible"
subprocess.run(ansible_install_command, shell=True, check=True)

# Directory path
directory_path = "/var/log/sync_files"

# Create the directory and its parent directories if they do not exist
os.makedirs(directory_path, exist_ok=True)

content_to_append = """\
sync_files() {
    today=$(date "+%Y-%m-%d")
    echo "-------------------start = $(date) -------------------" >> /var/log/sync_files/sync_files_${today}.log
    /opt/ansible_scripts/sync_files.sh $@ | tee -a "/var/log/sync_files/sync_files_${today}.log"
}
alias sync_files='sync_files'
"""

bashrc_path = os.path.expanduser("~/.bashrc")

# Append the content to the ~/.bashrc file
with open(bashrc_path, "a") as file:
    file.write(content_to_append)

ansible_scripts_path = '/opt/ansible_scripts'

# Check for the existence of the /opt/ansible_scripts directory
if not os.path.exists(ansible_scripts_path):
    # If the directory does not exist, create it
    os.makedirs(ansible_scripts_path)
    print(f"Created {ansible_scripts_path}")
else:
    print(f"The {ansible_scripts_path} directory is present there.")

hosts_ini_path = '/opt/ansible_scripts/hosts.ini'

# Check for the existence of the /opt/ansible_scripts/hosts.ini file
if not os.path.exists(hosts_ini_path):
    # If the file does not exist, create it
    open(hosts_ini_path, 'a').close()
    print(f"Created {hosts_ini_path}")
else:
    print(f"The {hosts_ini_path} file is present there.")

subprocess.run("source ~/.bashrc", shell=True)

