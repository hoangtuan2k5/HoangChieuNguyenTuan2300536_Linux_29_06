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
├── assets/
│   ├── code-de-tuan.png
│   └── diagram-de-tuan.png
├── diagrams/
│   └── de_tuan_flow.puml
├── scripts/
│   └── de_tuan.sh
└── tests/
    └── run_tests.sh
```

## Câu 1 (1 điểm)

Kiểm tra xem hệ thống có cài đặt **NFS** hay không. Nếu chưa được cài đặt thì dùng lệnh `rpm` để cài.

```bash
if ! rpm -q nfs-utils >/dev/null 2>&1; then
    rpm -ivh /path/to/nfs-utils.rpm
fi
```

## Câu 2 (1 điểm)

Kiểm tra xem hệ thống có cài đặt **PORTMAP** hay không. Nếu chưa được cài đặt thì dùng lệnh `rpm` để cài.

```bash
if ! rpm -q portmap >/dev/null 2>&1 && ! rpm -q rpcbind >/dev/null 2>&1; then
    rpm -ivh /path/to/portmap.rpm
fi
```

## Câu 3 (1 điểm)

Export thư mục `/usr/share` chỉ cho phép máy có địa chỉ `192.168.xx.yy` mount vào mount point `/mnt/share` để sử dụng.

```bash
mkdir -p /mnt/share
grep -q "^/usr/share " /etc/exports || echo "/usr/share 192.168.xx.yy(ro,sync,no_subtree_check)" >> /etc/exports
```

## Câu 4 (1 điểm)

Export thư mục `/soft` với quyền **RW** và chỉ cho phép các máy trong mạng `192.168.xx.0/24` mount vào mount point `/mnt/soft`.

```bash
mkdir -p /soft
grep -q "^/soft " /etc/exports || echo "/soft 192.168.xx.0/24(rw,sync,no_subtree_check)" >> /etc/exports

service rpcbind start
service nfs-server start
exportfs -ra
exportfs -v
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
systemctl status nfs-server --no-pager
journalctl -u nfs-server -n 30 --no-pager
nfsstat -s
```

## Câu 8 (1 điểm)

Liệt kê các filesystem của hệ thống đã được mount.

```bash
findmnt
```

## Câu 9 (1 điểm)

Xem các export directory.

```bash
exportfs -v
showmount -e localhost
```

## Câu 10 (1 điểm)

Theo dõi và thống kê sử dụng tài nguyên hệ thống của User.

```bash
ps -eo user,pid,%cpu,%mem,comm --sort=user | head -50
top -b -n 1 | head -30
```

## Sơ đồ xử lý

![Sơ đồ xử lý Đề của Tuấn](assets/diagram-de-tuan.png)

## Ảnh chụp mã nguồn

![Ảnh chụp mã nguồn Đề của Tuấn](assets/code-de-tuan.png)
