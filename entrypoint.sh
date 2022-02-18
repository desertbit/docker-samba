#!/bin/bash
set -e

CONFIG_FILE="/etc/samba/runtime.conf"
HOSTNAME=`hostname`
PASSWD="false"

# Global options.
set -e
cat >"$CONFIG_FILE" <<EOF
[global]
netbios name = $HOSTNAME
server string = $HOSTNAME

EOF

# Parse options.
while getopts ":u:p:s:h" opt; do
case $opt in
    h)
        echo "Options:"
        echo "  -u user                         add a user"
        echo "  -s name@user1:ro[,userN:rw]     add a share"
        echo "  -p user:password                set user password"
        exit 1
        ;;
    u)
        echo -n "Add user "
        IFS=: read user <<<"$OPTARG"
        echo "'$user' "
        addgroup -S "$user"
        adduser -s /sbin/nologin -H -D -G "$user" "$user"
        ;;
    p)
        echo -n "Setting password for user "
        IFS=: read user password <<<"$OPTARG"
        echo "'$user'"
        echo "$password" |tee - |smbpasswd -s -a "$user"
        PASSWD="true"
        ;;
    s)
        echo -n "Add share "
        IFS=@ read sharename users <<<"$OPTARG"
        sharepath="/data/$sharename"
        mkdir -p "$sharepath"
        chown smbuser:smbuser "$sharepath"
        echo -n "'$sharename' "
        echo "[$sharename]" >>"$CONFIG_FILE"
        echo -n "path '$sharepath' "
        echo "path = \"$sharepath\"" >>"$CONFIG_FILE"
        echo "read only = no" >>"$CONFIG_FILE"
        echo "writable = yes" >>"$CONFIG_FILE"
        if [[ -z "$users" ]] ; then
            echo "no user defined"
            exit 1
        else
            echo -n "for users: "
            users=$(echo "$users" |tr "," " ")
            vusers=""
            rusers=""
            wusers=""
            for user in $users; do
                IFS=: read user rw <<<"$user"
                vusers="$vusers $user"
                rusers="$rusers $user"
                if [[ "$rw" == "rw" ]]; then
                    wusers="$wusers $user"
                elif [[ "$rw" != "ro" ]]; then
                    echo "invalid read/write flag"
                    exit 1
                fi
            done
            echo -n "$vusers"
            echo "valid users = $vusers" >>"$CONFIG_FILE"
            echo "read list = $rusers" >>"$CONFIG_FILE"
            echo "write list = $wusers" >>"$CONFIG_FILE"
        fi
        echo
        ;;
    \?)
        echo "Invalid option: -$OPTARG"
        exit 1
        ;;
    :)
        echo "Option -$OPTARG requires an argument."
        exit 1
        ;;
esac
done

if [[ $PASSWD == "true" ]] ; then
    echo "Stopping, because password was set. This must not be a runtime argument!"
    exit 1
fi

# Run samba.
exec ionice -c 3 smbd --foreground --no-process-group --debug-stdout --configfile=/etc/samba/smb.conf
