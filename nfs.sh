

## Install NFS server

sudo apt-get update
sudo apt-get install nfs-common nfs-kernel-server -y

## Create and configure directory to share

sudo mkdir -p /data/nfs
sudo chown nobody:nogroup /data/nfs
sudo chmod 2770 /data/nfs

## Configure exports !CHANGE IP!

echo -e "/data/nfs\t37.187.77.198/24(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
sudo exportfs -av

## Restart services

sudo systemctl restart nfs-kernel-server
sudo systemctl status nfs-kernel-server

## Show export details !CHANGE IP!

/sbin/showmount -e 37.187.77.198

## Mount share on client

sudo apt update
sudo apt install nfs-common -y

# Install NFS provisioner 

helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner

## !CHANGE IP!

helm install nfs-subdir-external-provisioner \
nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
--set nfs.server=37.187.77.198 \
--set nfs.path=/data/nfs \
--set storageClass.onDelete=true

#Check Pods and storage Class

kubectl get pod
kubectl get sc

mkdir -p /mnt/nfs_share
mount 127.0.0.1:/srv/nfs_share /mnt/nfs_share


## Automate mount in /etc/fstab


echo "127.0.0.1:/srv/nfs_share /mnt/nfs_share nfs defaults 0 0" | tee -a /etc/fstab


## Add Helm repo for nfs-subdir-external-provisioner
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner

##Install NFS Provisionner
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
kubectl create namespace nfs-storage
helm upgrade --install -n nfs-storage --create-namespace nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=37.187.77.198 \
    --set nfs.path=/data/nfs \
    --set storageClass.name=nfs \
    --set storageClass.archiveOnDelete=false


## Create a PV on the exported NFS share


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
      path: /data/nfs
      server: 37.187.77.198
EOF


## Create the NFS PVC


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

## Create the NFS location profile for Veeam Kasten


echo | kubectl apply -f - << EOF
kind: Profile
apiVersion: config.kio.kasten.io/v1alpha1
metadata:
  name: nfs
  namespace: kasten-io
spec:
  locationSpec:
    type: FileStore
    fileStore:
      claimName: nfs-pvc
      path: /
    credential:
      secretType: ""
      secret:
        apiVersion: ""
        kind: ""
        name: ""
        namespace: ""
  type: Location
EOF



créer un pod qui monte le pvc NFS et voir si je peux écrire et naviguer dedans qui va rester pending en container created.

--> 




