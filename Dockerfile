# Use the official Nginx image from the Docker Hub
FROM nginx:latest

# Install nano text editor
RUN apt-get update && apt-get install -y nano && \
  echo 'alias ll="ls -l"' >> ~/.bashrc

# Copy the Nginx configuration file
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf

# Expose the ports for Nginx
EXPOSE 80 443
