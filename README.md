# Regional load balancer accessable over direct link

## onprem

```
# download coredns
version=1.9.3
file=coredns_${version}_linux_amd64.tgz
wget https://github.com/coredns/coredns/releases/download/v${version}/$file
tar zxvf $file

# turn off the default dns resolution
systemctl disable systemd-resolved
systemctl stop systemd-resolved

# chattr -i stops the resolv.conf file from being updated, configure resolution to be from localhost port 53
rm /etc/resolv.conf
cat > /etc/resolv.conf <<EOF
nameserver 127.0.0.1
EOF
chattr +i /etc/resolv.conf
cat /etc/resolv.conf
ls -l /etc/resolv.conf

# coredns will resolve on localhost port 53.  DNS_SERVER_IPS are the custom resolver locations
cat > Corefile <<EOF
.:53 {
    log
    forward .  $(cat DNS_SERVER_IPS)
    prometheus localhost:9253
}
EOF
./coredns
```

maybe
```
cat > /etc/NetworkManager/NetworkManager.conf <<EOF
dns=none
EOF
service network-manager restart
```

ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

```
vi /etc/systemd/resolved.conf
  DNSStubListener=no
vi /etc/resolv.conf
```

 /etc/NetworkManager/dispatcher.d/hook-network-manager


## todo
- onprem /etc/systemd/resolved.conf
