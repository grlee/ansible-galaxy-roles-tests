#!/bin/bash
git submodule init && git submodule update
vagrant pristine -f
ansible-playbook vagrant.yml
ansible-playbook site.yml
