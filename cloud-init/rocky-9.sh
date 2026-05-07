#!/bin/bash
# Rocky Linux 9 cloud image template with AI tools setup
# Proxmox VM template ID: 9915 — NOTE: conflicts with Debian 13 (9915)
# Change VMID if using both templates on the same Proxmox host.
# Proxmox VM template ID: 9917

set -e

VMID=9917
IMG="Rocky-9-GenericCloud.latest.x86_64.qcow2"
TEMPLATE_NAME="rocky-9-ai-cloudinit.template"
STORAGE="data-pool"
BRIDGE="vmbr0"

# Cleanup
qm destroy $VMID 2>/dev/null || true
rm -f "$IMG"

# Download
wget https://ftp.lysator.liu.se/pub/rocky/9.4/images/x86_64/Rocky-9-GenericCloud.latest.x86_64.qcow2

# Customize image
virt-customize -a "$IMG" --run-command "echo timezone: Europe/Stockholm >> /etc/cloud/cloud.cfg"
virt-customize -a "$IMG" --install qemu-guest-agent
virt-customize -a "$IMG" --install mtr
virt-customize -a "$IMG" --install traceroute
virt-customize -a "$IMG" --install htop
virt-customize -a "$IMG" --install curl,git
virt-customize -a "$IMG" --update

# Install AI setup script
virt-customize -a "$IMG" --copy-in ../ai-setup.sh:/usr/local/bin/
virt-customize -a "$IMG" --run-command "chmod +x /usr/local/bin/ai-setup.sh && ln -sf /usr/local/bin/ai-setup.sh /usr/local/bin/ai-setup"
virt-customize -a "$IMG" --copy-in ../first-login.sh:/etc/profile.d/
virt-customize -a "$IMG" --run-command "mv /etc/profile.d/first-login.sh /etc/profile.d/99-ai-setup.sh && chmod +r /etc/profile.d/99-ai-setup.sh"

# Create Proxmox VM template
qm create $VMID --name "$TEMPLATE_NAME" --memory 1024 --cores 1 --net0 virtio,bridge=$BRIDGE
qm importdisk $VMID "$IMG" $STORAGE
qm set $VMID --scsihw virtio-scsi-pci --scsi0 ${STORAGE}:vm-${VMID}-disk-0
qm set $VMID --ide0 ${STORAGE}:cloudinit
qm set $VMID --agent enabled=1
qm set $VMID --hotplug=disk,network
qm set $VMID --vga std
qm set $VMID --numa 0
qm set $VMID --onboot 1
qm set $VMID --boot c --bootdisk scsi0
qm set $VMID --cdrom none,media=cdrom
qm template $VMID

echo "Template $VMID ($TEMPLATE_NAME) created."
