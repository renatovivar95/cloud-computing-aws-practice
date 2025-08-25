#!/bin/bash

set -e  # Exit on error

source config.sh

# Install Java and Maven (manual install of Maven >= 3.2.5)
ssh -o StrictHostKeyChecking=no -i "$AWS_EC2_SSH_KEYPAR_PATH" ec2-user@$(cat instance.dns) <<'EOF'
  sudo yum update -y
  sudo yum install -y java-11-amazon-corretto.x86_64 wget tar

  MAVEN_VERSION=3.9.6
  wget https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
  tar -xvzf apache-maven-${MAVEN_VERSION}-bin.tar.gz
  sudo mv apache-maven-${MAVEN_VERSION} /opt/maven
  echo 'export PATH=/opt/maven/bin:$PATH' >> ~/.bash_profile
  export PATH=/opt/maven/bin:$PATH
  mvn -version
EOF

# Upload the Server directory
scp -o StrictHostKeyChecking=no -i "$AWS_EC2_SSH_KEYPAR_PATH" -r "$DIR/../Server" ec2-user@$(cat instance.dns):

# Build the Maven project on the EC2 instance
ssh -o StrictHostKeyChecking=no -i "$AWS_EC2_SSH_KEYPAR_PATH" ec2-user@$(cat instance.dns) <<'EOF'
  export PATH=/opt/maven/bin:$PATH
  cd Server
  mvn clean package
EOF

# Set up rc.local and enable its systemd compatibility unit
ssh -o StrictHostKeyChecking=no -i "$AWS_EC2_SSH_KEYPAR_PATH" ec2-user@$(cat instance.dns) <<'EOF'
  # Write the startup command to /etc/rc.local
  sudo tee /etc/rc.local > /dev/null <<'EOL'
#!/bin/bash
cd /home/ec2-user/Server
/usr/bin/java -cp webserver/target/webserver-1.0.0-SNAPSHOT-jar-with-dependencies.jar -Xbootclasspath/a:javassist/target/JavassistWrapper-1.0-jar-with-dependencies.jar -javaagent:webserver/target/webserver-1.0.0-SNAPSHOT-jar-with-dependencies.jar=ICount:pt.ulisboa.tecnico.cnv.capturetheflag,pt.ulisboa.tecnico.cnv.fifteenpuzzle,pt.ulisboa.tecnico.cnv.gameoflife:output pt.ulisboa.tecnico.cnv.webserver.WebServer &
exit 0
EOL

  # Make rc.local executable
  sudo chmod +x /etc/rc.local

  # Create systemd service for rc.local compatibility
  sudo tee /etc/systemd/system/rc-local.service > /dev/null << 'EOL'
[Unit]
Description=/etc/rc.local Compatibility
ConditionPathExists=/etc/rc.local

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
EOL

  # Enable and start the service
  sudo systemctl daemon-reload
  sudo systemctl enable rc-local
  sudo systemctl start rc-local
EOF
