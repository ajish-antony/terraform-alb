#!/bin/bash

echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
echo "LANG=en_US.utf-8" >> /etc/environment
echo "LC_ALL=en_US.utf-8" >> /etc/environment
service sshd restart

echo "password123" | passwd root --stdin
sed  -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
service sshd restart


yum install httpd  php php-mysqlnd.x86_64 -y
service httpd restart
chkconfig httpd on

sudo mkdir -p /root/.aws
cat <<EOF > /root/.aws/config
[default]
output = json
region = us-east-1
EOF

echo "Health Check" > /var/www/html/check.php

wget https://raw.githubusercontent.com/ajish-antony/sample-website/main/index.php -P /var/www/html/ 2>/dev/null

end=`aws rds describe-db-instances --filters "Name=engine,Values=mysql" --query "*[].[Endpoint.Address]" | grep "[a-z]" | sed 's/[" ]//g'`
sed -i "s/localhost/$end/g" /var/www/html/index.php



