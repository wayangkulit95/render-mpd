#!/bin/bash

# Setup script to install dependencies and set up the environment for the Express channel management application.

# Exit the script if any command fails
set -e

# Step 1: Check if Node.js is installed
echo "Checking if Node.js is installed..."
if ! command -v node &> /dev/null; then
    echo "Node.js is not installed. Installing Node.js..."
    # Install Node.js (for Ubuntu-based systems)
    sudo apt update
    sudo apt install -y nodejs npm
else
    echo "Node.js is already installed."
fi

# Step 2: Set up the project directory
echo "Setting up the project directory..."
mkdir -p mtsofficial-dashboard

cd mtsofficial-dashboard

# Step 3: Initialize the Node.js project
echo "Initializing Node.js project..."
npm init -y

# Step 4: Install required dependencies
echo "Installing dependencies..."
npm install express body-parser ejs http-proxy-middleware express-session

# Step 5: Create the app.js file
echo "Creating the app.js file..."
cat << 'EOF' > app.js
// Import necessary modules
const express = require('express');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');
const { createProxyMiddleware } = require('http-proxy-middleware');
const session = require('express-session');

// Initialize the Express application
const app = express();
const port = 8881;

// Middleware to parse URL-encoded form data
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));  // Serve static files (e.g., CSS)
app.set('view engine', 'ejs');  // Use EJS templates

// Set up session
app.use(session({
  secret: 'yourSecretKey',  // Change this to a real secret key in production
  resave: false,
  saveUninitialized: true
}));

// Path to the channel data storage file
const channelsFilePath = path.join(__dirname, 'channels.json');

// Utility function to read channels from the JSON file
const readChannels = () => {
  try {
    if (!fs.existsSync(channelsFilePath)) {
      return [];
    }
    const data = fs.readFileSync(channelsFilePath, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.error('Error reading channels:', error);
    return [];
  }
};

// Utility function to save channels to the JSON file
const saveChannels = (channels) => {
  try {
    fs.writeFileSync(channelsFilePath, JSON.stringify(channels, null, 2), 'utf8');
  } catch (error) {
    console.error('Error saving channels:', error);
  }
};

// Login route (GET)
app.get('/login', (req, res) => {
  if (req.session.user) {
    return res.redirect('/dashboard');  // If the user is already logged in, redirect to dashboard
  }
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Login</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 0; padding: 0; background: #f4f4f4; }
          .container { max-width: 400px; margin: 100px auto; padding: 20px; background: white; border-radius: 8px; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1); }
          h2 { text-align: center; color: #333; }
          label { display: block; margin: 10px 0 5px; color: #555; }
          input { width: 100%; padding: 10px; margin: 5px 0 15px; border: 1px solid #ccc; border-radius: 4px; }
          button { width: 100%; padding: 10px; background-color: #5cb85c; color: white; border: none; border-radius: 4px; cursor: pointer; }
          button:hover { background-color: #4cae4c; }
        </style>
      </head>
      <body>
        <div class="container">
          <h2>Login</h2>
          <form action="/login" method="POST">
            <label>Username:</label>
            <input type="text" name="username" required>
            <label>Password:</label>
            <input type="password" name="password" required>
            <button type="submit">Login</button>
          </form>
        </div>
      </body>
    </html>
  `);
});

// Handle login (POST)
app.post('/login', (req, res) => {
  const { username, password } = req.body;

  // Basic authentication (replace with real authentication logic)
  if (username === 'admin' && password === 'password') {
    req.session.user = { username };  // Save user info in session
    return res.redirect('/dashboard');  // Redirect to dashboard after successful login
  }

  res.status(401).send('Invalid credentials');  // Send error if credentials are incorrect
});

// Logout route
app.get('/logout', (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      return res.status(500).send('Could not log out');
    }
    res.redirect('/login');  // Redirect to login page after logout
  });
});

// Middleware to protect routes (e.g., channel management) from unauthorized access
const isAuthenticated = (req, res, next) => {
  if (!req.session.user) {
    return res.redirect('/login');  // If not logged in, redirect to login page
  }
  next();  // Proceed to the requested page if authenticated
};

// Protect channel management routes
app.use('/dashboard', isAuthenticated);

// Serve the channel management page
app.get('/dashboard', (req, res) => {
  const channels = readChannels();
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Channel Management</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 0; padding: 0; background: #f4f4f4; }
          .container { max-width: 1000px; margin: 50px auto; padding: 20px; background: white; border-radius: 8px; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1); }
          h2 { text-align: center; color: #333; }
          table { width: 100%; margin-top: 20px; border-collapse: collapse; }
          table, th, td { border: 1px solid #ddd; }
          th, td { padding: 10px; text-align: left; }
          th { background-color: #f2f2f2; }
          .btn { padding: 5px 15px; background-color: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer; }
          .btn:hover { background-color: #0056b3; }
        </style>
      </head>
      <body>
        <div class="container">
          <h2>Channel Management</h2>
          <a href="/add-channel" class="btn">Add Channel</a>
          <table>
            <tr>
              <th>Name</th>
              <th>URL</th>
              <th>Actions</th>
            </tr>
            ${channels.map((channel, index) => `
              <tr>
                <td>${channel.name}</td>
                <td>${channel.url}</td>
                <td>
                  <a href="/edit-channel/${index}" class="btn">Edit</a>
                  <form action="/delete-channel/${index}" method="POST" style="display:inline;">
                    <button type="submit" class="btn">Delete</button>
                  </form>
                </td>
              </tr>
            `).join('')}
          </table>
        </div>
      </body>
    </html>
  `);
});

// Serve the page for adding a new channel
app.get('/add-channel', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Add Channel</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 0; padding: 0; background: #f4f4f4; }
          .container { max-width: 400px; margin: 50px auto; padding: 20px; background: white; border-radius: 8px; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1); }
          h2 { text-align: center; color: #333; }
          label { display: block; margin: 10px 0 5px; color: #555; }
          input { width: 100%; padding: 10px; margin: 5px 0 15px; border: 1px solid #ccc; border-radius: 4px; }
          button { width: 100%; padding: 10px; background-color: #5cb85c; color: white; border: none; border-radius: 4px; cursor: pointer; }
          button:hover { background-color: #4cae4c; }
        </style>
      </head>
      <body>
        <div class="container">
          <h2>Add Channel</h2>
          <form action="/add-channel" method="POST">
            <label>Name:</label>
            <input type="text" name="name" required>
            <label>URL:</label>
            <input type="url" name="url" required>
            <label>License Key:</label>
            <input type="text" name="licenseKey" required>
            <label>User Agent:</label>
            <input type="text" name="userAgent">
            <label>Referrer:</label>
            <input type="text" name="referrer">
            <button type="submit">Add Channel</button>
          </form>
        </div>
      </body>
    </html>
  `);
});

// Handle adding a new channel
app.post('/add-channel', (req, res) => {
  const { name, url, licenseKey, userAgent, referrer } = req.body;

  const channels = readChannels();
  const newChannel = { name, url, licenseKey, userAgent, referrer };
  channels.push(newChannel);

  saveChannels(channels);

  res.redirect('/dashboard');  // Redirect to dashboard after adding the channel
});

// Handle deleting a channel
app.post('/delete-channel/:index', (req, res) => {
  const index = req.params.index;
  const channels = readChannels();

  channels.splice(index, 1);  // Remove the channel at the specified index
  saveChannels(channels);

  res.redirect('/dashboard');  // Redirect to dashboard after deletion
});

// Start the server
app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
EOF

# Step 6: Create the channels.json file (it will hold channel data)
echo "[]" > channels.json

# Step 7: Provide instructions for the user
echo "Setup complete!"
echo "Run the application using the following command:"
echo "  node app.js"
