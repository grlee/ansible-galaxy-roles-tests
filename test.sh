#!/bin/bash
git submodule init && git submodule update
vagrant pristine -f
ansible-playbook vagrant.yml
ansible-playbook site.yml
ansible test_boxes -m shell -a "ansible --version"
