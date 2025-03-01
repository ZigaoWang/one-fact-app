# One Fact Backend Deployment Guide

This guide explains how to deploy the One Fact backend to Fly.io.

## Prerequisites

1. Install the Fly.io CLI:
   ```
   brew install flyctl
   ```

2. Log in to Fly.io:
   ```
   fly auth login
   ```

## Deployment Steps

1. **Set up environment variables as secrets**

   We'll use Fly.io's secrets to store our environment variables securely. Use the provided script:

   ```
   ./setup_fly_secrets.sh
   ```

   This script will read your `.env` file and set all variables as secrets in Fly.io.

2. **Deploy the application**

   To deploy the application to Fly.io:

   ```
   fly deploy
   ```

   This command will build the Docker image and deploy it to Fly.io.

3. **Check the deployment status**

   ```
   fly status
   ```

4. **View application logs**

   ```
   fly logs
   ```

## Updating the Deployment

To update your deployment after making changes:

1. Commit your changes to version control
2. Run `fly deploy` again

## Troubleshooting

- If you encounter issues with your secrets, you can check the current secrets with:
  ```
  fly secrets list
  ```

- To update a specific secret:
  ```
  fly secrets set KEY=VALUE
  ```

- To see the application logs for debugging:
  ```
  fly logs
  ```

## iOS App Configuration

After deployment, you'll need to update the API base URL in your iOS app:

1. Get your Fly.io app URL:
   ```
   fly status
   ```

2. Update the `baseURL` in the iOS app's `ChatService.swift` to use your deployed API endpoint:
   ```swift
   init(baseURL: String = "https://your-app-name.fly.dev/api/v1/chat") {
       self.baseURL = baseURL
   }
   ```

## Additional Resources

- [Fly.io Documentation](https://fly.io/docs/)
- [Go on Fly.io](https://fly.io/docs/languages-and-frameworks/golang/)
