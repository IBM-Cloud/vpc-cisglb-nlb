# Regional load balancer accessable over direct link

## On premises

The default ubuntu DNS resolver can be hard to follow.  Follow the instructions below to disable the default and use [coredns](https://coredns.io/)


```
ssh root@...
...
# download coredns
version=1.9.3
file=coredns_${version}_linux_amd64.tgz
wget https://github.com/coredns/coredns/releases/download/v${version}/$file
tar zxvf $file

# chattr -i stops the resolv.conf file from being updated, configure resolution to be from localhost port 53
rm /etc/resolv.conf
cat > /etc/resolv.conf <<EOF
nameserver 127.0.0.1
EOF
chattr +i /etc/resolv.conf
cat /etc/resolv.conf
ls -l /etc/resolv.conf

# turn off the default dns resolution
systemctl disable systemd-resolved
systemctl stop systemd-resolved


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

Create a second ssh session to the on premises ubuntu instance that is running coredns, copy/paste the suggested output from the terraform output.  A session will look like this:
```
ssh root@...
...
curl $glb/instance


while sleep 1; do curl --connect-timeout 2 $glb/instance; done

```

## Watching failures
Visit the [VPC Instances](https://cloud.ibm.com/vpc-ext/compute/vs) and notice there are instances in each zone based on variable instances.  The instances can be **Stopped** using the menu on the far right.  Click on the menu then click **Stop** on a few and observe the curl in the while loop.  When you stop all of the instances in a zone notice the failure pattern.

Example, stopping both us-south-1-0 and us-south-1-1:

```
root@dnsglb-onprem:~# while sleep 1; do curl --connect-timeout 2 $glb/instance; done
...
dnsglb-us-south-1-0
curl: (7) Failed to connect to backend.widgets.cogs port 80: Connection refused
dnsglb-us-south-2-1
curl: (7) Failed to connect to backend.widgets.cogs port 80: Connection refused
dnsglb-us-south-2-0
dnsglb-us-south-3-1
dnsglb-us-south-3-1
curl: (7) Failed to connect to backend.widgets.cogs port 80: Connection refused
dnsglb-us-south-3-1
dnsglb-us-south-3-1
curl: (7) Failed to connect to backend.widgets.cogs port 80: Connection refused
curl: (7) Failed to connect to backend.widgets.cogs port 80: Connection refused
curl: (7) Failed to connect to backend.widgets.cogs port 80: Connection refused
dnsglb-us-south-3-1
dnsglb-us-south-2-1
curl: (7) Failed to connect to backend.widgets.cogs port 80: Connection refused
curl: (7) Failed to connect to backend.widgets.cogs port 80: Connection refused
dnsglb-us-south-3-1
dnsglb-us-south-3-1
dnsglb-us-south-2-0
dnsglb-us-south-2-1
dnsglb-us-south-2-0
```

Start up the instances to see them start up again.

## Troubleshooting

Notes:

The terraform output shows info sorted into zone and instance





## todo

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
