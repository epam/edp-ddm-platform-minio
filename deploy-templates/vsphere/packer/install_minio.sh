#!/usr/bin/env bash

set -e

apt-get update && apt-get install -y unzip libtool libltdl-dev curl sharutils perl-modules-5.26

USER="minio"
GROUP="minio"
HOME="/home/minio"

# Detect package management system.
APT_GET=$(which apt-get 2>/dev/null)

pass_generator() {
for ((n=0;n<1;n++))
do dd if=/dev/urandom count=1 2> /dev/null | uuencode -m - | sed -ne 2p | cut -c-12
done
}

user_ubuntu() {
# UBUNTU user setup
  if ! getent group ${GROUP} >/dev/null
  then
    sudo addgroup --system ${GROUP} >/dev/null
  fi

  if ! getent passwd ${USER} >/dev/null
  then
    sudo adduser \
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

minio_root_password=$(pass_generator)
minio_root_user="minio"
minio_bucket_name="mdtuddm"
minio_volume_path="/dev/sdb"

MINIO_URL="https://dl.min.io/server/minio/release/linux-amd64/minio"
curl --silent --output /usr/local/bin/minio ${MINIO_URL}
chmod 0755 /usr/local/bin/minio
chown ${USER}:${GROUP} /usr/local/bin/minio

MINIO_VOLUME_FS=`blkid -o value -s TYPE ${minio_volume_path} || true`

if [[ -z ${MINIO_VOLUME_FS} ]] ; then
        mkfs.ext4 ${minio_volume_path}
fi

mkdir /usr/local/share/minio
echo "${minio_volume_path} /usr/local/share/minio ext4 defaults 0 0" >> /etc/fstab
mount /usr/local/share/minio
chown ${USER}:${GROUP} /usr/local/share/minio

mkdir /etc/minio
chown ${USER}:${GROUP} /etc/minio

cat << EOF > /etc/default/minio
MINIO_ROOT_USER=${minio_root_user}
MINIO_VOLUMES="/usr/local/share/minio/"
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
ExecStartPre=/bin/bash -c "if [ -z \"/usr/local/share/minio/\" ]; then echo \"Variable MINIO_VOLUMES not set in /etc/default/minio\"; exit 1; fi"

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
systemctl start minio

curl --silent --output /usr/local/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc
chmod 0755 /usr/local/bin/mc

mc config host add platform-minio http://127.0.0.1:9000 minio ${minio_root_password}
mc mb platform-minio/${minio_bucket_name}