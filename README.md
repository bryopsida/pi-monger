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
- [ ] Add instructions to run initial ansible-pull
- [ ] Add instructions on how to add ansible-pull to sdcard cloud-init to run ansible-pull on first boot
- [ ] Implement update system role
- [ ] Implement auto pull role that sets up recurring ansible-pulls to the same play on a cron
- [ ] Implement nodejs role for installing and maintaining a node.js lts version

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

Save the modifications to user-data and umount.
