#!/usr/bin/env bash
set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
    echo "Vui long chay script bang quyen root."
    exit 1
fi

CLIENT_IP="${CLIENT_IP:-192.168.xx.yy}"
CLIENT_NET="${CLIENT_NET:-192.168.xx.0/24}"
SERVER_IP="${SERVER_IP:-<ip-may-chu-nfs>}"
NFS_SERVICE="${NFS_SERVICE:-nfs-server}"

title() {
    printf '\n========== %s ==========\n' "$1"
}

start_service() {
    local service_name="$1"

    service "${service_name}" start 2>/dev/null ||
        systemctl start "${service_name}" 2>/dev/null ||
        true
}

if [[ "${CLIENT_IP}" == *xx* || "${CLIENT_NET}" == *xx* ]]; then
    echo "Dat CLIENT_IP va CLIENT_NET truoc khi chay."
    echo "Vi du: sudo CLIENT_IP=192.168.1.10 CLIENT_NET=192.168.1.0/24 SERVER_IP=192.168.1.1 ./scripts/de_tuan.sh"
    exit 1
fi

title "Cau 1: Kiem tra va cai NFS"
if command -v apt-get >/dev/null 2>&1; then
    apt-get install -y nfs-kernel-server
    NFS_SERVICE="nfs-kernel-server"
elif ! rpm -q nfs-utils >/dev/null 2>&1; then
    rpm -ivh "${NFS_RPM:?Dat NFS_RPM=/duong/dan/nfs-utils.rpm}"
fi

title "Cau 2: Kiem tra va cai PORTMAP"
if command -v apt-get >/dev/null 2>&1; then
    apt-get install -y rpcbind
elif ! rpm -q portmap >/dev/null 2>&1 && ! rpm -q rpcbind >/dev/null 2>&1; then
    rpm -ivh "${PORTMAP_RPM:?Dat PORTMAP_RPM=/duong/dan/portmap.rpm}"
fi

title "Cau 3 va 4: Cau hinh export"
mkdir -p /soft
touch /etc/exports
grep -q "^/usr/share " /etc/exports || echo "/usr/share ${CLIENT_IP}(ro,sync,no_subtree_check)" >> /etc/exports
grep -q "^/soft " /etc/exports || echo "/soft ${CLIENT_NET}(rw,sync,no_subtree_check)" >> /etc/exports

start_service rpcbind
start_service "${NFS_SERVICE}"
exportfs -ra
exportfs -v

echo "Lenh mount tren client:"
echo "mkdir -p /mnt/share /mnt/soft"
echo "mount -t nfs ${SERVER_IP}:/usr/share /mnt/share"
echo "mount -t nfs ${SERVER_IP}:/soft /mnt/soft"

title "Cau 5: Kiem tra NFS bang rpcinfo"
rpcinfo -p localhost | grep -E "nfs|100003" || true

title "Cau 6: Kiem tra PORTMAP bang rpcinfo"
rpcinfo -p localhost | grep -E "portmapper|100000" || true

title "Cau 7: Kiem tra loi NFS Server"
systemctl status "${NFS_SERVICE}" --no-pager || true
journalctl -u "${NFS_SERVICE}" -n 30 --no-pager || true
nfsstat -s || true

title "Cau 8: Liet ke filesystem da mount"
findmnt

title "Cau 9: Xem export directory"
exportfs -v
showmount -e localhost || true

title "Cau 10: Thong ke tai nguyen theo user"
ps -eo user,pid,%cpu,%mem,comm --sort=user | head -50
top -b -n 1 | head -30
