#!/usr/bin/env bash
set -euo pipefail

output_dir="/tmp/ami-challenge-output"

desired_software="bzip2\|fontconfig\|gcc-c++\|git\|htop\|iftop\|libpng-devel\|make\|neofetch\|nginx\|rsync\|ruby\|ruby-devel"
if [ ! -d "${output_dir}" ]
then
    mkdir "${output_dir}"
fi

# Verify Installed Software
yum list installed >  "${output_dir}"/installed-packages

# Verify Services
systemctl list-unit-files | grep enabled  | grep 'ssh\|nginx' > "${output_dir}"/enabled-services

# Collect history
cat /root/.bash_history > "${output_dir}"/root-history
cat /home/cloud_user/.bash_history > "${output_dir}"/root-history
