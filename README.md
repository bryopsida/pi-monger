# PI Monger

## What is this?

A collection of ansible roles and playbooks with a focus on being used with ansible-pull to actively maintain Raspberry PIs.
Actively maintain means the plays are idempotent and intended to be run on a cron to prevent drift.

## Pre-Requisites (tested)

- RPI4
- Ubuntu Server 22.04 and 24.04
- Ansible installed
- Initial ansible-pull run as root
- Network connectivity to github to pull this repo, or network connectivity to a clone of this repo

## TODOs

- [ ] Add test pipeline where pull runs on main, and then tries to run the pull on incoming branch, use multipass
- [ ] Add instructions to run initial ansible-pull
- [ ] Add instructions on how to add ansible-pull to sdcard cloud-init to run ansible-pull on first boot
- [ ] Implement update system role
- [ ] Implement auto pull role that sets up recurring ansible-pulls to the same play on a cron
- [ ] Implement nodejs role for installing and maintaining a node.js lts version
