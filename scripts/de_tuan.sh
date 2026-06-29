#!/usr/bin/env bash
set -euo pipefail

CLIENT_IP="${CLIENT_IP:-192.168.xx.yy}"
CLIENT_NET="${CLIENT_NET:-192.168.xx.0/24}"
SERVER_IP="${SERVER_IP:-<ip-may-chu-nfs>}"
EXPORTS_FILE="/etc/exports"

require_root() {
    if [ "${EUID}" -ne 0 ]; then
        echo "Vui long chay script bang quyen root."
        exit 1
    fi
}

require_command() {
    local command_name="$1"

    if ! command -v "${command_name}" >/dev/null 2>&1; then
        echo "Thieu lenh ${command_name}. Hay cai goi phu hop truoc khi chay."
        exit 1
    fi
}

print_title() {
    printf '\n========== %s ==========\n' "$1"
}

install_rpm_if_missing() {
    local package_name="$1"
    local rpm_file="$2"

    if rpm -q "${package_name}" >/dev/null 2>&1; then
        echo "Goi ${package_name} da duoc cai dat."
        return
    fi

    if [ -z "${rpm_file}" ]; then
        echo "Chua co goi ${package_name}. Dat bien duong dan RPM phu hop roi chay lai."
        exit 1
    fi

    rpm -ivh "${rpm_file}"
}

start_service() {
    local service_name="$1"

    if command -v systemctl >/dev/null 2>&1; then
        systemctl enable --now "${service_name}"
    else
        service "${service_name}" start
        chkconfig "${service_name}" on || true
    fi
}

validate_network_values() {
    if [[ "${CLIENT_IP}" == *xx* || "${CLIENT_NET}" == *xx* ]]; then
        echo "Hay dat CLIENT_IP va CLIENT_NET dung voi mang phong thuc hanh."
        echo "Vi du: CLIENT_IP=192.168.1.10 CLIENT_NET=192.168.1.0/24"
        exit 1
    fi
}

cau_1() {
    print_title "Cau 1: Kiem tra va cai dat NFS"
    require_command "rpm"
    install_rpm_if_missing "nfs-utils" "${NFS_RPM:-}"
}

cau_2() {
    print_title "Cau 2: Kiem tra va cai dat PORTMAP"
    require_command "rpm"
    if rpm -q "portmap" >/dev/null 2>&1; then
        echo "Goi portmap da duoc cai dat."
    elif rpm -q "rpcbind" >/dev/null 2>&1; then
        echo "He thong dang dung rpcbind thay cho portmap."
    else
        install_rpm_if_missing "portmap" "${PORTMAP_RPM:-}"
    fi
}

cau_3_va_4() {
    print_title "Cau 3 va 4: Cau hinh export /usr/share va /soft"
    validate_network_values

    mkdir -p /soft
    cp -a "${EXPORTS_FILE}" "${EXPORTS_FILE}.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
    touch "${EXPORTS_FILE}"

    local share_line="/usr/share ${CLIENT_IP}(ro,sync,no_subtree_check)"
    local soft_line="/soft ${CLIENT_NET}(rw,sync,no_subtree_check)"

    grep -qxF "${share_line}" "${EXPORTS_FILE}" || echo "${share_line}" >> "${EXPORTS_FILE}"
    grep -qxF "${soft_line}" "${EXPORTS_FILE}" || echo "${soft_line}" >> "${EXPORTS_FILE}"

    start_service "rpcbind"
    start_service "nfs-server"
    exportfs -ra
    exportfs -v

    echo "Lenh mount tren may client:"
    echo "mkdir -p /mnt/share /mnt/soft"
    echo "mount -t nfs ${SERVER_IP}:/usr/share /mnt/share"
    echo "mount -t nfs ${SERVER_IP}:/soft /mnt/soft"
}

cau_5() {
    print_title "Cau 5: Kiem tra dich vu NFS bang rpcinfo"
    require_command "rpcinfo"
    rpcinfo -p localhost | grep -E '100003|nfs'
}

cau_6() {
    print_title "Cau 6: Kiem tra PORTMAP bang rpcinfo"
    require_command "rpcinfo"
    rpcinfo -p localhost | grep -E '100000|portmapper'
}

cau_7() {
    print_title "Cau 7: Kiem tra su co va thong ke loi tren NFS Server"
    systemctl status nfs-server --no-pager || true
    systemctl status rpcbind --no-pager || true
    journalctl -u nfs-server -n 50 --no-pager || true
    nfsstat -s || true
    exportfs -v
}

cau_8() {
    print_title "Cau 8: Liet ke filesystem da mount"
    findmnt
}

cau_9() {
    print_title "Cau 9: Xem cac export directory"
    exportfs -v
    showmount -e localhost || true
}

cau_10() {
    print_title "Cau 10: Theo doi tai nguyen he thong cua user"
    ps -eo user,pid,ppid,%cpu,%mem,comm --sort=user | head -50
    top -b -n 1 | head -40
}

main() {
    require_root
    cau_1
    cau_2
    cau_3_va_4
    cau_5
    cau_6
    cau_7
    cau_8
    cau_9
    cau_10
}

main "$@"
