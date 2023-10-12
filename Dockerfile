# Based on https://github.com/dperson/samba
FROM alpine:3.18
MAINTAINER Roland Singer, roland.singer@desertbit.com

# Install dependencies.
RUN apk --no-cache --no-progress upgrade && \
    apk --no-cache --no-progress add \
        bash \
        samba \
        samba-common-tools \
        shadow \
        tini \
        tzdata

# Setup samba.
RUN addgroup -g 2222 -S smbuser && \
    adduser -u 2222 -S -D -H -h /tmp -s /sbin/nologin -G smbuser -g 'Samba User' smbuser && \
    mkdir -p /var/log/samba
COPY smb.conf /etc/samba/smb.conf

RUN mkdir /data && \
    chown smbuser:smbuser /data && \
    mkdir /config && \
    chmod 0700 /config
            
VOLUME [ "/config", "/data" ]

EXPOSE 137/udp 138/udp 139 445

# Currently not possible, because user authentication is required.
#HEALTHCHECK --interval=60s --timeout=15s CMD smbclient -L \\localhost -U % -m SMB3

# Entrypoint.
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]