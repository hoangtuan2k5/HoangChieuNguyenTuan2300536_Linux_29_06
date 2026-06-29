#!/usr/bin/env bash
set -euo pipefail

CLIENT_IP="${CLIENT_IP:-192.168.xx.yy}"
CLIENT_NET="${CLIENT_NET:-192.168.xx.0/24}"
SERVER_IP="${SERVER_IP:-<ip-may-chu-nfs>}"
EXPORTS_FILE="/etc/exports"
NFS_SERVICE="nfs-server"

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

package_installed_deb() {
    local package_name="$1"

    dpkg-query -W -f='${Status}' "${package_name}" 2>/dev/null | grep -q "install ok installed"
}

install_deb_if_missing() {
    local package_name="$1"

    if package_installed_deb "${package_name}"; then
        echo "Goi ${package_name} da duoc cai dat."
        return
    fi

    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y "${package_name}"
}

install_package_if_missing() {
    local rpm_package="$1"
    local deb_package="$2"
    local rpm_file="$3"

    if command -v apt-get >/dev/null 2>&1 && command -v dpkg-query >/dev/null 2>&1; then
        install_deb_if_missing "${deb_package}"
    else
        require_command "rpm"
        install_rpm_if_missing "${rpm_package}" "${rpm_file}"
    fi
}

start_service() {
    local service_name="$1"

    if command -v systemctl >/dev/null 2>&1 && systemctl list-units >/dev/null 2>&1; then
        systemctl enable --now "${service_name}"
    elif command -v service >/dev/null 2>&1; then
        service "${service_name}" start
        if command -v chkconfig >/dev/null 2>&1; then
            chkconfig "${service_name}" on || true
        fi
    else
        echo "Khong tim thay lenh quan ly dich vu de khoi dong ${service_name}."
        exit 1
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
    if command -v apt-get >/dev/null 2>&1 && command -v dpkg-query >/dev/null 2>&1; then
        NFS_SERVICE="nfs-kernel-server"
    fi
    install_package_if_missing "nfs-utils" "nfs-kernel-server" "${NFS_RPM:-}"
}

cau_2() {
    print_title "Cau 2: Kiem tra va cai dat PORTMAP"
    if command -v apt-get >/dev/null 2>&1 && command -v dpkg-query >/dev/null 2>&1; then
        install_deb_if_missing "rpcbind"
    elif rpm -q "portmap" >/dev/null 2>&1; then
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
    start_service "${NFS_SERVICE}"
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
    systemctl status "${NFS_SERVICE}" --no-pager || true
    systemctl status rpcbind --no-pager || true
    journalctl -u "${NFS_SERVICE}" -n 50 --no-pager || true
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
