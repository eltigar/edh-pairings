#!/usr/bin/env bash
set -e  # Exit on any error

# -----------------
# CONFIGURATION
# -----------------

# Set GitHub repository URL
GITHUB_REPO_URL="https://github.com/eltigar/edh-pairings"

# Runner version (update as needed)
RUNNER_VERSION="2.321.0"

# Docker Compose version (optional: pin a specific version if needed)
DOCKER_COMPOSE_VERSION="2.23.3"

# Function to get a GitHub token (user input or environment variable)
get_token() {
  if [ -z "$GITHUB_RUNNER_TOKEN" ]; then
    echo "Please enter your GitHub Actions Runner token (expires in 1 hour):"
    read -r GITHUB_RUNNER_TOKEN
  fi

  if [ -z "$GITHUB_RUNNER_TOKEN" ]; then
    echo "Error: Token is required. Exiting."
    exit 1
  fi
}

# -----------------
# SYSTEM UPDATE AND PREPARATION
# -----------------

echo "Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Install dependencies
echo "Installing required packages..."
sudo apt-get install -y \
    curl \
    tar \
    jq \
    git \
    ca-certificates \
    gnupg \
    lsb-release \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3 \
    python3-pip \
    python3-venv \
    sudo

# -----------------
# DOCKER INSTALLATION
# -----------------

echo "Installing Docker using the official script..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

# Add current user to the Docker group to avoid using sudo for Docker commands
sudo usermod -aG docker "$USER"
echo "Docker installation completed. You may need to log out and log back in for 'docker' group changes to take effect."

# Install Docker Compose (optional, can be omitted if installed via Docker plugin)
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose version

# -----------------
# GITHUB RUNNER SETUP
# -----------------

echo "Setting up GitHub Actions Runner..."

# Create the actions-runner directory
mkdir -p ~/actions-runner
cd ~/actions-runner || exit

# Download the GitHub Actions Runner package
RUNNER_TAR="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
curl -o $RUNNER_TAR -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_TAR}"

# Optional: Verify the hash of the downloaded file
HASH="ba46ba7ce3a4d7236b16fbe44419fb453bc08f866b24f04d549ec89f1722a29e"
echo "${HASH}  ${RUNNER_TAR}" | shasum -a 256 -c

# Extract the runner package
tar xzf $RUNNER_TAR
rm $RUNNER_TAR

# Get the GitHub token
get_token

# Configure the runner
./config.sh --url "$GITHUB_REPO_URL" --token "$GITHUB_RUNNER_TOKEN" --unattended --replace

# Install and start the runner as a service
sudo ./svc.sh install
sudo ./svc.sh start

echo "GitHub Actions Runner setup completed successfully!"

# -----------------
# FINAL INSTRUCTIONS
# -----------------

echo "IMPORTANT: If this is your first time using Docker, log out and back in for Docker group permissions to take effect."
echo "Your GitHub Actions Runner is now live and connected to: $GITHUB_REPO_URL"
