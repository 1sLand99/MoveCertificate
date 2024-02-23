#!/system/bin/sh
# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in post-fs-data mode
# Android 14 cannot be earlier than Zygote
sdk_version=$(getprop ro.build.version.sdk)
# debug
#sdk_version=34
sdk_version_number=$(expr "$sdk_version" + 0)

# add logcat
LOG_PATH="$MODDIR/install.log"
LOG_TAG="iyue_MoveCertificate"

# Keep only one up-to-date log
echo "[$LOG_TAG] Keep only one up-to-date log" >$LOG_PATH

print_log() {
    echo "[$LOG_TAG] $@" >>$LOG_PATH
}

mount_cert() {
    # "Mount a temporary directory to overwrite the system certificate directory"
    print_log "mount: $1"
    mount -t tmpfs tmpfs "$1"
    print_log "mount status:$?"
    # "Copy all certificates to the system certificate directory"
    print_log "move cert: $1"
    cp -f $MODDIR/certificates/* "$1"
    chown -R system:system "$1"
    chown root:shell "$1"
    chmod -R 644 "$1"
    chmod 755 "$1"
    print_log "move cert status:$?"
}

print_log "start move cert !"
print_log "current sdk version is $sdk_version_number"

# Android version >= 14 execute
if [ "$sdk_version_number" -ge 34 ]; then

    chown -R root:root $MODDIR/certificates/
    chmod -R 644 $MODDIR/certificates
    chmod 755 $MODDIR/certificates

    print_log "Backup system certificates"
    cp -u /system/etc/security/cacerts/* $MODDIR/certificates/
    cp -u /apex/com.android.conscrypt/cacerts/* $MODDIR/certificates/

    print_log "Backup user certificates"
    cp -u /data/misc/user/0/cacerts-added/* $MODDIR/certificates/

    print_log "find system conscrypt directory"
    apex_dir=$(find /apex -type d -name "com.android.conscrypt@*")
    print_log "find conscrypt directory: $apex_dir"
    mount_cert "$apex_dir/cacerts/"
    mount_cert /apex/com.android.conscrypt/cacerts/

fi

# All Android versions perform
cp -u /system/etc/security/cacerts/* $MODDIR/certificates
cp -u /data/misc/user/0/cacerts-added/* $MODDIR/certificates/
chown -R root:root $MODDIR/certificates/
chmod -R 644 $MODDIR/certificates
chmod 755 $MODDIR/certificates
mount -t tmpfs tmpfs /system/etc/security/cacerts/
cp -f $MODDIR/certificates/* /system/etc/security/cacerts/
chown root:root /system/etc/security/cacerts
chown -R root:root /system/etc/security/cacerts/
chmod -R 644 /system/etc/security/cacerts/
chmod 755 /system/etc/security/cacerts
chcon u:object_r:system_file:s0 /system/etc/security/cacerts/*
print_log "exit status:$?"
print_log "certificates installed"
