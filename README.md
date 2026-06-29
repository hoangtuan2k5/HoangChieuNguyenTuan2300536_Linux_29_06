<div align="center">

# Bài tập Linux ngày 29/06

**Lời giải Đề của Tuấn**

| Họ và tên | Mã sinh viên |
| --- | --- |
| Hoàng Chiêu Nguyễn Tuấn | 2300536 |

</div>

## Cấu trúc thư mục

```text
.
├── README.md
├── scripts/
│   └── de_tuan.sh
└── tests/
    └── run_tests.sh
```

## Câu 1 (1 điểm)

Kiểm tra xem hệ thống có cài đặt **NFS** hay không. Nếu chưa được cài đặt thì dùng lệnh `rpm` để cài.

```bash
if ! dpkg -s nfs-kernel-server >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y nfs-kernel-server
fi
```

## Câu 2 (1 điểm)

Kiểm tra xem hệ thống có cài đặt **PORTMAP** hay không. Nếu chưa được cài đặt thì dùng lệnh `rpm` để cài.

```bash
if ! dpkg -s rpcbind >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y rpcbind
fi
```

## Câu 3 (1 điểm)

Export thư mục `/usr/share` chỉ cho phép máy có địa chỉ `192.168.xx.yy` mount vào mount point `/mnt/share` để sử dụng.

```bash
sudo mkdir -p /mnt/share
grep -q "^/usr/share " /etc/exports || echo "/usr/share 192.168.1.100(ro,sync,no_subtree_check)" | sudo tee -a /etc/exports
```

## Câu 4 (1 điểm)

Export thư mục `/soft` với quyền **RW** và chỉ cho phép các máy trong mạng `192.168.xx.0/24` mount vào mount point `/mnt/soft`.

```bash
sudo mkdir -p /soft
grep -q "^/soft " /etc/exports || echo "/soft 192.168.1.0/24(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports

sudo systemctl start rpcbind || sudo service rpcbind start
sudo systemctl start nfs-server || sudo service nfs-server start
sudo exportfs -ra
sudo exportfs -v
```

## Câu 5 (1 điểm)

Dùng lệnh `rpcinfo` để kiểm tra dịch vụ **NFS** có đang hoạt động trong hệ thống hay không.

```bash
rpcinfo -p localhost | grep -E "nfs|100003"
```

## Câu 6 (1 điểm)

Dùng lệnh `rpcinfo` để kiểm tra dịch vụ **PORTMAP** có đang hoạt động trong hệ thống hay không.

```bash
rpcinfo -p localhost | grep -E "portmapper|100000"
```

## Câu 7 (1 điểm)

Kiểm tra và xử lý các sự cố thống kê lỗi trên **NFS Server**.

```bash
sudo systemctl status nfs-server --no-pager || true
sudo journalctl -u nfs-server -n 30 --no-pager || true
sudo nfsstat -s || true
```

## Câu 8 (1 điểm)

Liệt kê các filesystem của hệ thống đã được mount.

```bash
findmnt
```

## Câu 9 (1 điểm)

Xem các export directory.

```bash
sudo exportfs -v
showmount -e localhost || true
```

## Câu 10 (1 điểm)

Theo dõi và thống kê sử dụng tài nguyên hệ thống của User.

```bash
ps -eo user,pid,%cpu,%mem,comm --sort=user | head -50
top -b -n 1 | head -30
```
