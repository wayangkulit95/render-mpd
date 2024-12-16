
# MTSOfficial Dashboard Setup

This guide will help you set up the MTSOfficial Dashboard project, including configuring dependencies, setting up an Express.js application, and enabling Nginx with SSL.

## Prerequisites

Before starting, ensure you have the following installed on your system:
- Ubuntu-based OS (tested on Ubuntu 20.04/22.04)
- User with `sudo` privileges
- Domain name pointing to your server's IP

## Setup Steps

### 1. Clone and Run the Script

1. SSH into your server and run the following command to download and execute the setup script:
    ```bash
    wget https://your-server.com/setup.sh
    chmod +x setup.sh
    ./setup.sh
    ```

2. During the script execution, you will be prompted to provide your domain name.

### 2. What the Script Does

The script will:
- Check for and install `Node.js`, `npm`, `Nginx`, and Certbot.
- Initialize a Node.js project and install necessary dependencies.
- Set up the Express.js application and create a sample `app.js`.
- Configure Nginx as a reverse proxy to route requests to the Node.js application.
- Secure your domain with SSL using Let's Encrypt (Certbot).

### 3. Post-Setup Steps

Once the setup is complete:
1. **Start the application**:
    ```bash
    node app.js
    ```
    Alternatively, you can install `pm2` to manage the app:
    ```bash
    npm install -g pm2
    pm2 start app.js --name mtsofficial-dashboard
    pm2 save
    pm2 startup
    ```

2. **Access the application**:
    - Open your domain in a web browser (e.g., `https://your-domain.com`).

3. **Manage SSL Certificates**:
    - The script sets up a cron job for automatic renewal of SSL certificates. To verify, check the cron jobs with:
      ```bash
      sudo crontab -l
      ```

### 4. Managing the App

- To add or modify channels, log in via `/login`.
- Channel management is available at `/dashboard`.
- Credentials are hardcoded in the example app (`admin` / `password`). Update this in `app.js` for better security.

### 5. Troubleshooting

- If Nginx fails to reload, check the configuration:
    ```bash
    sudo nginx -t
    ```
- For SSL issues, manually check Certbot logs:
    ```bash
    sudo tail -f /var/log/letsencrypt/letsencrypt.log
    ```
### 6. Install the Script
```bash
 bash <(curl -s https://raw.githubusercontent.com/wayangkulit95/render-mpd/main/install.sh)
```

## License

This project is licensed under the MIT License. Feel free to modify and use it for your purposes.

---

**Note**: Replace the placeholder values in `app.js` (e.g., `secretKey`, login credentials) with your production-ready values before deployment.
