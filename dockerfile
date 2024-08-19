# Use a lightweight Linux base image
FROM alpine:latest

# Install necessary packages
RUN apk add --no-cache openssh-server bash cronie

# Configure SSH
RUN ssh-keygen -A
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
RUN sed -i 's/#Port 22/Port 443/' /etc/ssh/sshd_config
RUN sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Create a user for SSH access
RUN adduser -D tunnel_user
RUN mkdir -p /home/tunnel_user/.ssh

# Copy the public key into the container
COPY id_rsa.pub /home/tunnel_user/.ssh/authorized_keys

# Set correct permissions
RUN chown -R tunnel_user:tunnel_user /home/tunnel_user/.ssh
RUN chmod 700 /home/tunnel_user/.ssh
RUN chmod 600 /home/tunnel_user/.ssh/authorized_keys

# Create a script for system updates and reboot
RUN echo '#!/bin/sh' > /usr/local/bin/update-and-reboot.sh
RUN echo 'apk update && apk upgrade --available' >> /usr/local/bin/update-and-reboot.sh
RUN echo 'echo "System updated. Rebooting now."' >> /usr/local/bin/update-and-reboot.sh
RUN echo 'reboot' >> /usr/local/bin/update-and-reboot.sh
RUN chmod +x /usr/local/bin/update-and-reboot.sh

# Add cron job for updates at 3 AM
RUN echo '0 3 * * * /usr/local/bin/update-and-reboot.sh' > /etc/crontabs/root

# Expose the SSH port
EXPOSE 443

# Start cron and SSH
CMD crond -f & /usr/sbin/sshd -D
