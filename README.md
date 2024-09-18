# kasten-nfs

In the procedure below we assume that boths NFS server and NFS client are running on the same server.

## Install NFS server

```console
apt update
apt install nfs-kernel-server
```

## Create and configure directory to share

```console
mkdir -p /srv/nfs_share
chown nobody:nogroup /srv/nfs_share
chmod 755 /srv/nfs_share
```

## Configure exports

```console
echo "/srv/nfs_share    127.0.0.1/24(rw,sync,no_subtree_check)" | tee -a /etc/exports
```

## Apply modification and restart service

```console
exportfs -a
systemctl restart nfs-kernel-server
```

## Mount share on client

```console
apt install nfs-common
mkdir -p /mnt/nfs_share
mount 127.0.0.1:/srv/nfs_share /mnt/nfs_share
```

## Automate mount in /etc/fstab

```console
echo "127.0.0.1:/srv/nfs_share /mnt/nfs_share nfs defaults 0 0" | tee -a /etc/fstab
```

## Create a PV on the exported NFS share

```console
echo | kubectl apply -f - << EOF
apiVersion: v1
kind: PersistentVolume
metadata:
   name: nfs-pv
spec:
   capacity:
      storage: 10Gi
   volumeMode: Filesystem
   accessModes:
      - ReadWriteMany
   persistentVolumeReclaimPolicy: Retain
   storageClassName: nfs
   mountOptions:
      - hard
      - nfsvers=4.1
   nfs:
      path: /mnt/nfs_share
      server: 127.0.0.1
EOF
```

## Create the NFS PVC

```console
echo | kubectl apply -f - << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
   name: nfs-pvc
   namespace: kasten-io
spec:
   storageClassName: nfs
   accessModes:
      - ReadWriteMany
   resources:
      requests:
         storage: 10Gi
EOF
```
## Create the NFS location profile for Veeam Kasten

```console
echo | kubectl apply -f - << EOF
kind: Profile
apiVersion: config.kio.kasten.io/v1alpha1
metadata:
  name: nfs-share
  namespace: kasten-io
spec:
  locationSpec:
    type: FileStore
    fileStore:
      claimName: nfs-pvc
      path: /srv/nfs_share
    credential:
      secretType: ""
      secret:
        apiVersion: ""
        kind: ""
        name: ""
        namespace: ""
  type: Location
EOF
```

