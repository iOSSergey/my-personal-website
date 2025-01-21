# Use the official Nginx image from the Docker Hub
FROM nginx:latest

# Install nano text editor
RUN apt-get update && apt-get install -y nano && \
  echo 'alias ll="ls -l"' >> ~/.bashrc

# Expose the ports for Nginx
EXPOSE 80 443
