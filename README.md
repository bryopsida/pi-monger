# PI Monger

## What is this?

A collection of ansible roles and playbooks with a focus on being used with ansible-pull to actively maintain Raspberry PIs.
Actively maintain means the plays are idempotent and intended to be run on a cron to prevent drift.

## Pre-Requisites (tested)

- RPI4
- Ubuntu Server 22.04 or 24.04
  - If Ubuntu 24.04 is used, oscap hardening is not yet supported
- Ansible installed
- Initial ansible-pull run with sudo
- Network connectivity to github to pull this repo, or network connectivity to a clone of this repo

## TODOs

- [ ] Add test pipeline where pull runs on main, and then tries to run the pull on incoming branch, use multipass
- [ ] Add instructions for providing secrets/vaults to plays with cloud-init
- [x] Add instructions to run initial ansible-pull
- [x] Add instructions on how to add ansible-pull to sdcard cloud-init to run ansible-pull on first boot
- [x] Implement update system role
- [x] Implement auto pull role that sets up recurring ansible-pulls to the same play on a cron
- [x] Implement nodejs role for installing and maintaining a node.js lts version
- [x] Implement role that uses complianceascode security content and oscap to harden system
- [x] Implement java role for installing and maintaining a java install
- [ ] Implement node-red role that installs node-red and takes patches on cron
- [ ] Implement monitoring role that reports system information to an external system
- [ ] Implement envoy role that installs reverse proxy
- [ ] Implement traefik role alternative to envoy
- [ ] Implement cloudflared role
- [ ] Implement guacamole role

## Running initial ansible-pull

```sh
sudo ansible-pull -U https://github.com/bryopsida/pi-monger.git -i inventory/localhost.ini plays/<pick your falvor>.yaml
```

If you are cloning your own repo and running it locally, replace the url after -U.

## Cloud-Init

### Example cloud-init.yaml

``` yaml
#cloud-config
packages:
  - ansible

runcmd:
  - ansible-pull -U https://github.com/bryopsida/pi-monger.git -i inventory/localhost.ini plays/nodejs.yaml
```

### How to run cloud-init on first boot

Assuming you are using the Raspberry PI Imager tool, and selecting Ubuntu Server 22.04 or 24.04.
After the flashing of the sd card has finished, remount the sd card.
There should be a user-data file located at the root of the image, if not make one.

Ansible must be added to packages

``` yaml
...
packages:
- avahi-daemon
- ansible # add ansible
...
```

An ansible pull instruction must be added

``` yaml
...
runcmd:
- localectl set-x11-keymap "us" pc105
- setupcon -k --force || true
- ansible-pull -U https://github.com/bryopsida/pi-monger.git -C main -i inventory/localhost.ini plays/nodejs.yaml
...
```

Save the modifications to user-data and umount. You can now insert it into PI and proceed with booting the system.

### Using sensitive values

If you need to provide the play with sensitive values such as access keys, you should do this using a secure copy to pull in vault and inventory values.

For example

``` yaml
#cloud-config
packages:
  - ansible

write_files:
  - content: |
      <ssh private key with read access to server holding vault>
    path: /root/.ssh/ansible
    permissions: '0400'
    owner: 'root:root'
  - content: |
      <ssh public key with read access to server holding vault>
    path: /root/.ssh/ansible.pub
    permissions: '0444'
    owner: 'root:root'

runcmd:
  - scp -i /root/.ssh/ansible ansible@servername:/home/ansible/ansible-files /root/ansible-files
  - ansible-pull -U https://github.com/bryopsida/pi-monger.git -i /root/ansible-files/inventory/localhost.ini --vault-password-file /root/ansible-files/vault-password plays/nodejs.yaml
```

If you are using a private repo you likely will prefer to keep the inventory and vault files in source with the playbooks, the above approach can be used to fetch the vault key file as well
