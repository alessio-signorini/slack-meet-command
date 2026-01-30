# Deployment Guide

Complete step-by-step instructions for deploying the Slack /meet command.

## Prerequisites

- [Fly.io CLI](https://fly.io/docs/hands-on/install-flyctl/) installed
- Google Cloud account with billing enabled
- Slack workspace where you have admin permissions
- Git repository cloned locally

## Step 1: Google Cloud Setup

### 1.1 Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Name: `slack-meet-command`
4. Click "Create"
5. Wait for project creation, then select it

### 1.2 Enable Google Meet REST API

1. Go to [APIs & Services → Library](https://console.cloud.google.com/apis/library)
2. Search for "Google Meet REST API"
3. Click on it → Click "Enable"

### 1.3 Configure OAuth Consent Screen

1. Go to [APIs & Services → OAuth consent screen](https://console.cloud.google.com/apis/credentials/consent)
2. Select "External" (unless you have Google Workspace)
3. Click "Create"
4. Fill in:
   - App name: `Slack Meet Command`
   - User support email: your email
   - Developer contact: your email
5. Click "Save and Continue"
6. Click "Add or Remove Scopes"
7. Add scope: `https://www.googleapis.com/auth/meetings.space.created`
8. Click "Save and Continue"
9. Add test users (your email) if in testing mode
10. Click "Save and Continue" → "Back to Dashboard"

### 1.4 Create OAuth Credentials

1. Go to [APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials)
2. Click "Create Credentials" → "OAuth client ID"
3. Application type: "Web application"
4. Name: `Slack Meet Command`
5. Authorized redirect URIs: `https://YOUR_FLY_APP.fly.dev/auth/google/callback`
   (You'll update this after Fly deployment)
6. Click "Create"
7. **Save the Client ID and Client Secret** - you'll need these later

## Step 2: Slack App Setup

### 2.1 Create Slack App

1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Click "Create New App" → "From scratch"
3. App Name: `Meet`
4. Select your workspace
5. Click "Create App"

### 2.2 Add Slash Command

1. In your app settings, go to "Slash Commands"
2. Click "Create New Command"
3. Fill in:
   - Command: `/meet`
   - Request URL: `https://YOUR_FLY_APP.fly.dev/slack/meet`
     (You'll update this after Fly deployment)
   - Short Description: `Create a Google Meet link`
   - Usage Hint: `[meeting name]`
4. Click "Save"

### 2.3 Get Signing Secret

1. Go to "Basic Information"
2. Under "App Credentials", find "Signing Secret"
3. Click "Show" and **save this value**

### 2.4 Install to Workspace

1. Go to "Install App"
2. Click "Install to Workspace"
3. Authorize the app

## Step 3: Fly.io Deployment

### 3.1 Login to Fly.io

```bash
fly auth login
```

### 3.2 Create the App

```bash
cd /workspaces/slack-meet-command.sonnet
fly launch --no-deploy
```

When prompted:
- App name: choose a unique name (e.g., `slack-meet-yourname`)
- Region: choose closest to you
- Do not set up Postgres or Redis

### 3.3 Create Persistent Volume

```bash
fly volumes create data --size 1 --region YOUR_REGION
```

Replace `YOUR_REGION` with your chosen region (e.g., `sjc`, `iad`, `lhr`).

### 3.4 Set Secrets

```bash
# Generate a session secret
SESSION_SECRET=$(ruby -e "require 'securerandom'; puts SecureRandom.hex(64)")

# Set all secrets
fly secrets set \
  SLACK_SIGNING_SECRET="your_slack_signing_secret" \
  GOOGLE_CLIENT_ID="your_google_client_id" \
  GOOGLE_CLIENT_SECRET="your_google_client_secret" \
  APP_URL="https://YOUR_APP_NAME.fly.dev" \
  SESSION_SECRET="$SESSION_SECRET" \
  DATABASE_URL="sqlite:///data/production.sqlite3"
```

### 3.5 Deploy

```bash
fly deploy
```

### 3.6 Verify Deployment

```bash
# Check app status
fly status

# Check health endpoint
curl https://YOUR_APP_NAME.fly.dev/health
```

Expected response:
```json
{"status":"ok","timestamp":"2026-01-30T12:00:00Z"}
```

## Step 4: Connect Services

### 4.1 Update Slack Request URL

1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Select your app
3. Go to "Slash Commands"
4. Edit `/meet` command
5. Update Request URL to: `https://YOUR_APP_NAME.fly.dev/slack/meet`
6. Save

### 4.2 Update Google OAuth Redirect URI

1. Go to [Google Cloud Console → Credentials](https://console.cloud.google.com/apis/credentials)
2. Click on your OAuth 2.0 Client ID
3. Under "Authorized redirect URIs", update to:
   `https://YOUR_APP_NAME.fly.dev/auth/google/callback`
4. Save

## Step 5: Test the Integration

### 5.1 Test /meet Command

1. Open Slack
2. In any channel, type: `/meet test`
3. You should see: "⏳ Creating meeting..."
4. If not authenticated, you'll see "Connect Google Account" button
5. Click the button, complete Google OAuth
6. Try `/meet test` again
7. You should see a meeting link posted to the channel

### 5.2 Verify Meeting Works

1. Click "Join Meeting" button
2. Google Meet should open in browser
3. Verify the meeting is accessible

## Troubleshooting

### "Invalid signature" error

- Verify `SLACK_SIGNING_SECRET` matches your Slack app
- Check that the secret doesn't have extra whitespace

### "Not authenticated" after OAuth

- Verify `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` are correct
- Check that redirect URI matches exactly (including https)
- Ensure Google Meet REST API is enabled

### App not responding

```bash
# Check logs
fly logs

# Check if app is running
fly status

# Restart if needed
fly apps restart
```

### Database issues

```bash
# SSH into the app
fly ssh console

# Check database file exists
ls -la /data/

# Run migrations manually if needed
bundle exec rake db:migrate
```

## Updating the App

```bash
# Make changes locally
git add .
git commit -m "Your changes"

# Deploy
fly deploy
```

## Scaling

The default configuration runs one always-on machine. To scale:

```bash
# Add more machines
fly scale count 2

# Upgrade machine size
fly scale vm shared-cpu-2x

# Increase memory
fly scale memory 512
```

## Monitoring

```bash
# View logs
fly logs

# View metrics
fly dashboard

# SSH into machine
fly ssh console
```

## Security Best Practices

1. Rotate secrets regularly
2. Use Google Workspace accounts for enhanced security features
3. Monitor logs for suspicious activity
4. Keep dependencies updated: `bundle update`
5. Review OAuth scopes periodically

## Cost Estimation

- Fly.io: ~$5-10/month for basic usage (shared-cpu-1x, 256MB, always-on)
- Google Cloud: Free tier covers most usage
- Slack: Free (slash commands are free)

Total: ~$5-10/month
