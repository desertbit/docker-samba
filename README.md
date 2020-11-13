# A secure samba docker image
## Running
```
docker run \
    --rm \
    --name samba \
    --hostname "Samba" \
    -e TZ=Europe/Berlin \
    -p 445:445 \
    desertbit/samba \
        -u foo \
        -u moo \
        -s share@foo:rw,moo:ro
```

## Set Passwords
```
docker exec -it samba smbpasswd -a foo
```

## Systemd Service
```ini
[Unit]
Description=Samba
After=docker.service
Requires=docker.service

[Install]
WantedBy=multi-user.target

[Service]
TimeoutStartSec=0
Restart=always
ExecStartPre=-/usr/bin/docker kill samba
ExecStartPre=-/usr/bin/docker rm samba
ExecStartPre=-/usr/bin/docker pull desertbit/samba
ExecStart=/usr/bin/docker run \
    --name samba \
    --hostname "Samba" \
    -e TZ=Europe/Berlin \
    -p 445:445 \
    --volume /data/samba/config:/config \
    --volume /data/samba/data:/data \
    desertbit/samba \
        -u foo \
        -u moo \
        -s share@foo:rw,moo:ro
ExecStop=/usr/bin/docker kill samba
```

## Thanks to
- https://github.com/deftwork/samba
- https://github.com/dperson/samba
- https://github.com/Stanback/alpine-samba