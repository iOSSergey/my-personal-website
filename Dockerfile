# Use the official Nginx image from the Docker Hub
FROM nginx:latest

# Install nano text editor
RUN apt-get update && apt-get install -y nano && \
  alias ll='ls -alF'

# Create necessary directories
RUN mkdir -p /usr/share/nginx/html/html-static /app/staticfiles

# Copy custom configuration file from the current directory
COPY nginx.conf /etc/nginx/nginx.conf

# Expose the ports for Nginx
EXPOSE 80 443

# Copy the HTML file into the Nginx html directory
# COPY about-me.html /usr/share/nginx/html/about-me.html

# Copy the profile.jpg file into the Nginx html-static directory
# COPY profile.jpg /usr/share/nginx/html/html-static/profile.jpg