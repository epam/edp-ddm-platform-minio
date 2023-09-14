#!/usr/bin/env bash

USER=${minio_root_user}
GROUP=${minio_root_user}
HOME="/home/${minio_root_user}"

# Detect package management system.
APT_GET=$(which apt-get 2>/dev/null)

echo 'nameserver 8.8.8.8' | tee /etc/resolv.conf >/dev/null

apt update >/dev/null
apt install -y unzip libtool libltdl-dev sharutils curl software-properties-common xfsprogs >/dev/null

user_ubuntu() {
# UBUNTU user setup
  if ! getent group ${GROUP} >/dev/null
  then
    addgroup --system ${GROUP} >/dev/null
  fi

  if ! getent passwd ${USER} >/dev/null
  then
    adduser \
    --system \
    --disabled-login \
    --ingroup ${GROUP} \
    --home ${HOME} \
    --no-create-home \
    --shell /bin/false \
    ${USER}  >/dev/null
  fi
}

if [[ ! -z ${APT_GET} ]]; then
  logger "Setting up user ${USER} for Debian/Ubuntu"
  user_ubuntu
else
    logger "${USER} user not created due to OS detection failure"
    exit 1;
fi

logger "User setup complete"

# Minio SetUp

MINIO_URL="${minio_url}"
curl --silent --output /usr/local/bin/minio ${MINIO_URL}
chmod 0755 /usr/local/bin/minio
chown minio:minio /usr/local/bin/minio
setcap 'cap_net_bind_service=+ep' /usr/local/bin/minio

MINIO_VOLUME_FS=$(blkid -o value -s TYPE ${minio_volume_path})
if [[ ${MINIO_VOLUME_FS} == '' ]] ; then
  logger "Formatting the volume ${minio_volume_path}."
  mkfs.xfs ${minio_volume_path}
fi

if [[ -d ${minio_local_mount_path} ]] ; then
  logger "The mount point directory ${minio_local_mount_path} already exist"
else
  logger "Creating mount point directory ${minio_local_mount_path}"
  mkdir -p ${minio_local_mount_path}
fi

# check if exist in fstab and then mount if not already mounted
MINIO_VOLUME_FS_TAB=$(cat /etc/fstab | grep "${minio_volume_path}")
if [[ ${MINIO_VOLUME_FS_TAB} == '' ]] ; then
  logger "Adding ${minio_volume_path} to /etc/fstab"
  echo "${minio_volume_path} ${minio_local_mount_path} xfs defaults 0 0" | tee -a /etc/fstab >/dev/null
else
  logger "Device ${minio_volume_path} is present in /etc/fstab"
fi

if mount | grep ${minio_volume_path} ; then
  logger "Mounting point ${minio_volume_path} is already mounted"
else
  logger "Mounting ${minio_local_mount_path}"
  mount ${minio_local_mount_path} || logger "Mounting volume ${minio_volume_path} to point ${minio_local_mount_path} has been failed"
fi

if [[ $(ls -ld ${minio_local_mount_path} | awk '{print $3}') == ${USER} ]] ; then
  logger "Chown operation is not needed"
else
  logger "Chown ${minio_local_mount_path}"
  chown ${USER}:${GROUP} -R ${minio_local_mount_path}
fi

if [[ -d ${minio_local_mount_path}/storage ]] ; then
  logger "The mount point directory ${minio_local_mount_path}/storage already exist"
else
  logger "Creating mount point directory ${minio_local_mount_path}/storage"
  mkdir -p ${minio_local_mount_path}/storage
  chown -R ${USER}:${GROUP} /usr/local/share/minio
fi

mkdir /etc/minio
chown -R ${USER}:${GROUP} /etc/minio

cat << EOF > /etc/default/minio
MINIO_ROOT_USER=${minio_root_user}
MINIO_VOLUMES="${minio_local_mount_path}/storage"
MINIO_OPTS="-C /etc/minio --address :9000 --console-address :9001"
MINIO_ROOT_PASSWORD="${minio_root_password}"
EOF

chown ${USER}:${GROUP} /etc/default/minio

cat << EOF > /lib/systemd/system/minio.service
[Unit]
Description=MinIO
Documentation=https://docs.min.io
Wants=network-online.target
After=network-online.target
AssertFileIsExecutable=/usr/local/bin/minio

[Service]
WorkingDirectory=/usr/local/

User=minio
Group=minio

EnvironmentFile=/etc/default/minio
ExecStartPre=/bin/bash -c "if [ -z \"${minio_local_mount_path}/\" ]; then echo \"Variable MINIO_VOLUMES not set in /etc/default/minio\"; exit 1; fi"

ExecStart=/usr/local/bin/minio server \$MINIO_OPTS \$MINIO_VOLUMES

# Let systemd restart this service always
Restart=always

# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=65536

# Specifies the maximum number of threads this process can create
TasksMax=infinity

# Disable timeout logic and wait until process is stopped
TimeoutStopSec=infinity
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable minio
systemctl restart minio

curl --silent --output /usr/local/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc
chmod 0755 /usr/local/bin/mc

mc config host add platform-minio http://127.0.0.1:9000 ${minio_root_user} ${minio_root_password}
mc mb --ignore-existing platform-minio/${bucket_name}
