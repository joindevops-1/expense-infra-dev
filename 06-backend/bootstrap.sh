#!/bin/bash
component=$1
dnf install ansible -y
pip3.9 install ansible botocore boto3
ansible-pull -i localhost, -U https://github.com/joindevops-1/expense-ansible-roles-tf.git -e component=$component -e login_password=ExpenseApp1 main.yaml