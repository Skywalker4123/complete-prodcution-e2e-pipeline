# Sample application for e2e DevOps Pipeline Github Actions
## This is a sample application to demonstrate an end to end DevOps Pipeline

Installation setup

step1: update & upgrade

sudo -i
sudo apt update
sudo apt upgrade -y

Step3: Install Java 

apt update
apt install openjdk-17-jre-headless -y
/usr/bin/java --version
exit 

Step3: Install Jenkins 

sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update

sudo apt-get install jenkins -y

step4: Sonarqube with postgresql, SOnarscanner & Nexus installation are also given for reference

Install Postgresql 15 or newer
sudo apt update
sudo apt upgrade -y
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo tee /etc/apt/trusted.gpg.d/pgdg.asc &>/dev/null
sudo apt update
sudo apt-get -y install postgresql postgresql-contrib
sudo systemctl enable postgresql

Create Database for Sonarqube
sudo passwd postgres
su - postgres
createuser sonar
psql 
ALTER USER sonar WITH ENCRYPTED password 'sonar';
CREATE DATABASE sonarqube OWNER sonar;
grant all privileges on DATABASE sonarqube to sonar;
\q
exit

Install Java 17 can use java-17-jdk also
sudo bash
apt install -y wget apt-transport-https
mkdir -p /etc/apt/keyrings
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc
echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
apt update
apt install temurin-17-jdk
update-alternatives --config java
/usr/bin/java --version
exit 

Increase Limits
sudo vim /etc/security/limits.conf 
Paste the below values at the bottom of the file
sonarqube   -   nofile   65536
sonarqube   -   nproc    4096

sudo vim /etc/sysctl.conf
Paste the below values at the bottom of the file
vm.max_map_count = 262144

Reboot to set the new limits
sudo reboot

Install Sonarqube - add newer version link SonarQube 9.9.3 LTS
cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.4.87374.zip
sudo apt install unzip
sudo unzip sonarqube-9.9.4.873741.zip
sudo mv /opt/sonarqube-9.9.4.87374 /opt/sonarqube
sudo groupadd sonar
sudo useradd -c "user to run SonarQube" -d /opt/sonarqube -g sonar sonar
sudo chown sonar:sonar /opt/sonarqube -R

Update Sonarqube properties with DB credentials
sudo vim /opt/sonarqube/conf/sonar.properties
Find and replace the below values, you might need to add the sonar.jdbc.url
sonar.jdbc.username=sonar
sonar.jdbc.password=sonar
sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube

Create service for Sonarqube unit file
sudo vim /etc/systemd/system/sonar.service
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking

ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop

User=sonar
Group=sonar
Restart=always

LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target

Start Sonarqube and Enable service
sudo systemctl start sonar
sudo systemctl enable sonar
sudo systemctl status sonar
sudo tail -f /opt/sonarqube/logs/sonar.log

Access the Sonarqube UI
http://<IP>:9000

user admin
password admin


sonar-scanner 

sudo wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
unzip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
vi sonar-scanner-5.0.1.3006-linux/conf/sonar-scanner.properties
sonar.host.url=http://sonarqube.9000 uncomment the line starting with sonar.host.url  
chmod +x sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner
sudo ln -s /optsonar-scanner-5.0.1.3006/bin/sonar-scanner /usr/local/bin/sonar-scanner

vi sonar-project.properties
sonar.projectKey=<your_app_name>

sonar.projectName=<your_app_name>

sonar.projectVersion=1.0

sonar.sources=. 

# The value of the property must be the key of the language.

sonar.language=java

sonar.java.binaries=target/classes

sonar.sourceEncoding=UTF-8

sonar-scanner -D sonar.login=squ_d653781275cfb989e2c2cbef75602498280ee27d


Nexus Repository 
Prerequisites
Open JDK 8
Minimum CPU’s: 4
Ubuntu Server with User sudo privileges.
Set User limits
Web Browser
Firewall/Inbound port: 22, 8081

sudo apt-get update
sudo apt install openjdk-8-jre-headless
cd /opt
sudo wget https://download.sonatype.com/nexus/3/nexus-3.64.0-04-unix.tar.gz
tar -zxvf nexus-3.64.0-04-unix.tar.gz
mv nexus-3.64.0-04 nexus
sudo adduser nexus

sudo visudo
nexus ALL=(ALL) NOPASSWD: ALL

sudo chown -R nexus:nexus /opt/nexus
sudo chown -R nexus:nexus /opt/sonatype-work
sudo vi /opt/nexus/bin/nexus.rc
run_as_user="nexus"

sudo vi /etc/systemd/system/nexus.service
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target

sudo systemctl start nexus
sudo systemctl enable nexus
sudo systemctl status nexus
tail -f /opt/sonatype-work/nexus3/log/nexus.log

http://server_IP:8081
user admin
passwd cat /opt/sonatype-work/nexus3/admin.password

Step5: install Nginx for reverse proxy of the jenkins IP 

sudo apt update
sudo apt upgrade
sudo apt install nginx
systemctl status nginx

In order for Nginx to serve this content, it’s necessary to create a server block with the correct directives.
sudo vi /etc/nginx/sites-available/jenkins.dev.dman.cloud

Paste the below (replace your domain)
upstream jenkins{
    server 127.0.0.1:8080;
}

server{
    listen      80;
    server_name jenkins.dev.dman.cloud;

    access_log  /var/log/nginx/jenkins.access.log;
    error_log   /var/log/nginx/jenkins.error.log;

    proxy_buffers 16 64k;
    proxy_buffer_size 128k;

    location / {
        proxy_pass  http://jenkins;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_redirect off;

        proxy_set_header    Host            $host;
        proxy_set_header    X-Real-IP       $remote_addr;
        proxy_set_header    X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto https;
    }

}

Next, let’s enable the file by creating a link from it to the sites-enabled directory, which Nginx reads from during startup:

sudo ln -s /etc/nginx/sites-available/jenkins.dev.dman.cloud /etc/nginx/sites-enabled/

sudo nginx -t
sudo systemctl restart nginx

step6: Configure Jenkins with SSL Using an Nginx Reverse Proxy

Prerequsites
Jenkins installed
An A record with pointing to your server’s public IP address.

sudo apt update
sudo apt upgrade

Installing Certbot
The first step to using Let’s Encrypt to obtain an SSL certificate is to install the Certbot software on your server.

sudo apt install certbot python3-certbot-nginx

Confirming Nginx’s Configuration
Certbot needs to be able to find the correct server block in your Nginx configuration for it to be able to automatically configure SSL. Specifically, it does this by looking for a server_name directive that matches the domain you request a certificate for.

sudo vi /etc/nginx/sites-available/jenkins.dev.dman.cloud

Find the existing server_name line. It should look like this:
...
server_name jenkins.dev.dman.cloud;
...

exit your editor and move on to the next step.

Verifying Certbot Auto-Renewal

Let’s Encrypt’s certificates are only valid for ninety days. This is to encourage users to automate their certificate renewal process. The certbot package we installed takes care of this for us by adding a systemd timer that will run twice a day and automatically renew any certificate that’s within thirty days of expiration

sudo systemctl status certbot.timer

To test the renewal process, you can do a dry run with certbot

sudo certbot renew --dry-run

step7: add jenkinstest node for runnig all task

Create Jenkins User
sudo adduser jenkins

Grant Sudo Rights to Jenkins User
sudo usermod -aG sudo jenkins

Java
apt install openjdk-17-jre-headless -y

Docker
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo docker run hello-world


 mkdir ~/.ssh; cd ~/.ssh/ && ssh-keygen -t rsa -m PEM -C "Jenkins agent key" -f "jenkinsAgent_rsa"


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






