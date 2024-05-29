#!/bin/bash
component=$1
dnf install ansible -y
pip3.9 install ansible botocore boto3
ansible-pull -i localhost, -U https://github.com/joindevops-1/expense-ansible-roles-tf.git -e component=$component -e BACKEND_API_URL=backend.app-dev.daws78s.online main.yaml