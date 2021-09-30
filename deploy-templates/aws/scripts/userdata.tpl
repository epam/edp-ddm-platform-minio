#!/usr/bin/env bash


USER="minio"
GROUP="minio"
HOME="/home/minio"
# Detect package management system.
APT_GET=$(which apt-get 2>/dev/null)

apt update && apt install -y unzip libtool libltdl-dev sharutils curl software-properties-common certbot

user_ubuntu() {
# UBUNTU user setup
  if ! getent group $${GROUP} >/dev/null
  then
    sudo addgroup --system $${GROUP} >/dev/null
  fi

  if ! getent passwd $${USER} >/dev/null
  then
    sudo adduser \
    --system \
    --disabled-login \
    --ingroup $${GROUP} \
    --home $${HOME} \
    --no-create-home \
    --shell /bin/false \
    $${USER}  >/dev/null
  fi
}

  if [[ ! -z $${APT_GET} ]]; then
  logger "Setting up user $${USER} for Debian/Ubuntu"
  user_ubuntu
  else
    logger "$${USER} user not created due to OS detection failure"
    exit 1;
  fi

logger "User setup complete"

MINIO_URL="${minio_url}"
curl --silent --output /usr/local/bin/minio $${MINIO_URL}
chmod 0755 /usr/local/bin/minio
chown minio:minio /usr/local/bin/minio
sudo setcap 'cap_net_bind_service=+ep' /usr/local/bin/minio


MINIO_VOLUME_FS=`blkid -o value -s TYPE ${minio_volume_path}`
if [[ -z $${MINIO_VOLUME_FS} ]] ; then
        mkfs.xfs ${minio_volume_path}
fi

mkdir -p /usr/local/share/minio/storage
echo "${minio_volume_path} /usr/local/share/minio xfs defaults 0 0" >> /etc/fstab
mount /usr/local/share/minio
chown minio:minio -R /usr/local/share/minio

if [ ! -f "/usr/local/share/minio/certificates/${minio_domain}/public.crt" ] && [ ! -f "/usr/local/share/minio/certificates/${minio_domain}/private.key" ] ; then
  certbot certonly --standalone -d "${minio_domain}" --register-unsafely-without-email --agree-tos
  sleep 30
  chmod -R 755 /etc/letsencrypt/live/ && chmod -R 755 /etc/letsencrypt/archive/
  mkdir -p /usr/local/share/minio/certificates/${minio_domain}
  cp /etc/letsencrypt/live/"${minio_domain}"/fullchain.pem /usr/local/share/minio/certificates/${minio_domain}/public.crt
  cp /etc/letsencrypt/live/"${minio_domain}"/privkey.pem /usr/local/share/minio/certificates/${minio_domain}/private.key
  chown minio:minio /usr/local/share/minio/certificates/${minio_domain}/public.crt
  chown minio:minio /usr/local/share/minio/certificates/${minio_domain}/private.key
fi


mkdir /etc/minio
chown minio:minio /etc/minio


cat << EOF > /etc/default/minio
MINIO_ROOT_USER=${minio_root_user}
MINIO_VOLUMES="/usr/local/share/minio/storage"
MINIO_OPTS="-C /etc/minio --address :443 --console-address :9001 -S /usr/local/share/minio/certificates/${minio_domain}"
MINIO_ROOT_PASSWORD="${minio_root_password}"
MINIO_SERVER_URL=https://${minio_domain}
EOF

chown minio:minio /etc/default/minio

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

mc config host add platform-minio https://${minio_domain} minio ${minio_root_password}
mc mb platform-minio/${bucket_name}
