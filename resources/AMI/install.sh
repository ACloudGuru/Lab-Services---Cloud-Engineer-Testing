#!/usr/bin/env bash

if ! grep -q 'cloud_user' /etc/passwd
then
  useradd -m -U -s /bin/bash cloud_user
fi
cloud_user_tmp_pass=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c24; echo)
echo "cloud_user:${cloud_user_tmp_pass}" | chpasswd
root_tmp_pass=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c24; echo)
echo "root:${root_tmp_pass}" | chpasswd
chage -I -1 -m 0 -M 99999 -E -1 cloud_user
chage -I -1 -m 0 -M 99999 -E -1 root


if grep -q '^PermitRootLogin' /etc/ssh/sshd_config
then
  sed -i 's/^PermitRootLogin.*$/PermitRootLogin without-password/' /etc/ssh/sshd_config
else
  echo 'PermitRootLogin without-password' >> /etc/ssh/sshd_config
fi
if grep -q '^PasswordAuthentication' /etc/ssh/sshd_config
then
  sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config
else
  echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
fi
if grep -q '^ChallengeResponseAuthentication' /etc/ssh/sshd_config
then
  sed -i 's/^ChallengeResponseAuthentication.*$/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
else
  echo 'ChallengeResponseAuthentication yes' >> /etc/ssh/sshd_config
fi
if grep -q '^Defaults targetpw' /etc/sudoers
then
  sed -i 's/^Defaults targetpw.*$//' /etc/sudoers
fi
mkdir -p /etc/cloud/cloud.cfg.d
cat <<EOD> /etc/cloud/cloud.cfg.d/99_LinuxAcademy.cfg
users:
- default
disable_root: 1
ssh_pwauth: 1
ssh_deletekeys: 1
system_info:
  default_user:
    name: cloud_user
    lock_passwd: false
    gecos: Cloud User
    groups: [wheel]
    sudo: ["ALL=(ALL) ALL"]
    shell: /bin/bash
  paths:
    cloud_dir: /var/lib/cloud
    templates_dir: /etc/cloud/templates
  ssh_svcname: sshd
  # vim:syntax=yaml
EOD

if [ -f /etc/sysconfig/network ];
then
  sed -i 's/^HOSTNAME.*$//' /etc/sysconfig/network
fi
if [ "$(command -v systemctl)" ];
then
  systemctl disable sethostname.service
elif [ "$(command -v /etc/init.d/sethostname)" ];
then
  chmod -x /etc/init.d/sethostname
else
  service sethostname disable
  update-rc.d sethostname disable
fi

if [ "$(command -v yum)" ];
then
  # Install Software
  yum groupinstall 'Development Tools' -y
  yum install gcc-c++ make fontconfig bzip2 libpng-devel ruby ruby-devel nginx htop iftop-y
  usermod -aG wheel cloud_user
  yum-complete-transaction -y
  yum upgrade -y
  yum autoremove -y
  yum history new
  rm -rf /var/cache/yum
fi
if grep -q '^wheel' /etc/group
then
  sed -i 's/groups:.*$/groups: [wheel]/' /etc/cloud/cloud.cfg.d/99_LinuxAcademy.cfg
elif grep -q '^sudo' /etc/group; then
  sed -i 's/groups:.*$/groups: [sudo]/' /etc/cloud/cloud.cfg.d/99_LinuxAcademy.cfg
elif grep -q '^admin' /etc/group; then
  sed -i 's/groups:.*$/groups: [admin]/' /etc/cloud/cloud.cfg.d/99_LinuxAcademy.cfg
elif ! grep -q 'cloud_user    ALL=(ALL)       ALL' /etc/sudoers; then
  echo 'cloud_user    ALL=(ALL)       ALL' >> /etc/sudoers
fi
rm -rf /etc/udev/rules.d/70-persistent-net.rules
rm -rf /var/lib/cloud/
rm -rf /var/log/{wtmp,lastlog,secure,auth.log,btmp,websh.log,cloud-*}
rm -rf /var/spool/mail/*
rm -rf /tmp/*
rm -rf /root/.vnc
rm -rf /etc/ssh/ssh_known_hosts
rm -rf /home/cloud_user/{.ssh,.cache}/
rm -f /etc/ssh/authorized_keys
touch /var/log/{wtmp,lastlog,secure,auth.log,btmp}
rm -rf /home/cloud_user/.vnc/*.{pid,log}
echo '' > /root/.bash_history
echo '' > /home/cloud_user/.bash_history
chown cloud_user:cloud_user /home/cloud_user/.bash_history
unset root_tmp_pass
unset cloud_user_tmp_pass
rm -rf /root/script.sh
wall 'cleanup finished!'
