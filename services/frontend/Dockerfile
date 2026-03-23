# Simple static file server
FROM nginx:alpine

# Copy static HTML files from public directory (relative to build context)
COPY public /usr/share/nginx/html

# Copy nginx configuration
COPY services/frontend/nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 3000

# Start nginx
CMD ["nginx", "-g", "daemon off;"]