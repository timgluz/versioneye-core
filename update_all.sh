#!/bin/bash

cat lib/versioneye/version.rb
cd ansible; ansible-playbook update_projects.yml
