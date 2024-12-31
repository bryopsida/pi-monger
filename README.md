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
- [x] Add instructions for providing secrets/vaults to plays with cloud-init
- [x] Add instructions to run initial ansible-pull
- [x] Add instructions on how to add ansible-pull to sdcard cloud-init to run ansible-pull on first boot
- [x] Implement update system role
- [x] Implement auto pull role that sets up recurring ansible-pulls to the same play on a cron
- [x] Implement nodejs role for installing and maintaining a node.js lts version
- [x] Implement role that uses complianceascode security content and oscap to harden system
- [x] Implement java role for installing and maintaining a java install
- [x] Implement node-red role that installs node-red and takes patches on cron
- [x] Implement monitoring role that reports system information to an external syste
- [ ] Implement falco role
  - [x] Falco service install
  - [ ] Can manage falco rules
- [ ] Implement pi-hole role
- [ ] Implement adguard home role
- [ ] Investigate and implement FDE if possible
- [ ] Implement Clevis role
- [ ] Implement k3s role
- [ ] Implement envoy role that installs reverse proxy
  - [ ] Add ability to manage/define virtual hosts and SNI routing.
- [x] Implement cloudflared role
- [x] Implement firewalld role
- [ ] Implement role to manage static hostnames /etc/hosts
- [ ] Implement role to manage static ip addresses via netplan
- [x] Disable cloud-init and shred user-data after first pull
- [ ] Add watch subscription to trigger runs on change instead of cron/polled updates

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
  - scp -o StrictHostKeyChecking=no -r -i /root/.ssh/ansible ansible@<servername with ansible files>:/home/ansible/ansible-files /root
  - ansible-pull -U https://github.com/bryopsida/pi-monger.git -i /root/ansible-files/inventory/localhost.ini --vault-password-file /root/ansible-files/vault-password plays/nodejs.yaml
```

If you are using a private repo you likely will prefer to keep the inventory and vault files in source with the playbooks, the above approach can be used to fetch the vault key file as well

### Complete example

#### Assumptions

1) You know how to setup a SSH server
1) A cloud provider secret manager is not available
1) The ssh username is named ansible
1) You are familiar with using Rasperry PI Imager
1) You are familiar with mounting sdcards in your operating system
1) You are familiar with linux file permissions and set appropriate permissions on your ansible files to restrict access to the owner:group.
1) Some familiarity with [cloud-init](https://cloudinit.readthedocs.io/en/latest/#)

#### Setup a SSH server

In order to handle sensitive values we cannot check into source, ansible vaults will need to be used. For that reason we need a ssh server we can use scp to fetch the values managed outside of source.
The details of setting up a SSH server is out of scope for this repo, depending on your network setup you may be able to use your router/gateway.

##### Recommeneded Configuration

1) Use pubkey ssh authentication
1) Create dedicated non admin limited scope account to hold the ansible values

#### SSH Server File Setup

1) Login to your ssh server for holding the inventory files
1) Create the `ansible-files` folder under the ssh users home folder
1) Create a `vault-password` file underneath `ansible-files` folder, this should match the password you use for vaulting any sensitive values
1) Create a `inventory` folder underneath the `ansible-files` folder
1) Create a `localhost.ini` file under the `ansible-files/inventory` file with the following contents
1) Ensure you have a copy of the ssh private key and public key for the ssh user

``` ini
[all]
localhost ansible_connection=local

[all:vars]
auto_pull_inventory=/root/ansible-files/inventory/localhost.ini
auto_pull_secure_copy_enabled=true
auto_pull_secure_copy_host=<hostname of your ssh server with ansible-files>
```

The resulting folder structure should look like this

``` shell
tree ansible-files    
ansible-files
├── inventory
│   └── localhost.ini
└── vault-password

2 directories, 2 files
```

#### Flash a Ubuntu Server 22.04 Image

Use [Raspberry PI Imager](https://www.raspberrypi.com/software/) to create a Ubuntu Server 22.04 image.

#### Modify `user-data` to run ansible-pull

After the image hs been created using Raspberry PI Imager.

1) Remount the image.
1) Open the `user-data` file with your editor of choice.
1) Update `user-data` to look like this with your values replaced

``` yaml
#cloud-config
hostname: <your desired hostname>
manage_etc_hosts: true
packages:
  - avahi-daemon
  - ansible
apt:
  conf: |
    Acquire {
      Check-Date "false";
    };

users:
  - name: <your desired username>
    groups: users,adm,dialout,audio,netdev,video,plugdev,cdrom,games,input,gpio,spi,i2c,render,sudo
    shell: /bin/bash
    lock_passwd: false
    passwd: <passwd hash>
    ssh_authorized_keys:
      - <ssh pub key>
    sudo: ALL=(ALL) NOPASSWD:ALL

write_files:
  - content: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      <redacted>
      -----END OPENSSH PRIVATE KEY-----
    path: /root/.ssh/ansible
    permissions: '0400'
    owner: 'root:root'
  - content: |
      ssh-ed25519 redacted username@host
    path: /root/.ssh/ansible.pub
    permissions: '0444'
    owner: 'root:root'

timezone: <your timezone>
runcmd:
  - localectl set-x11-keymap "us" pc105
  - setupcon -k --force || true
  - scp -o StrictHostKeyChecking=no -r -i /root/.ssh/ansible ansible@your.ansible.server.name:/home/ansible/ansible-files /root
  - ansible-pull -U https://github.com/bryopsida/pi-monger.git -i /root/ansible-files/inventory/localhost.ini --vault-password-file /root/ansible-files/vault-password plays/nodejs.yaml
```
