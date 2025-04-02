FROM ubuntu:20.04

ARG RUNNER_VERSION="2.321.0"

# Prevents install dependencies from prompting the user and blocking the image creation
ARG DEBIAN_FRONTEND=noninteractive

# Create the user for running the container
RUN useradd -m adminuser

# Update the package lists and install required packages
RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    sudo curl jq build-essential libssl-dev libffi-dev \
    python3 python3-venv python3-dev python3-pip \
    docker.io apt-transport-https gnupg

# Add adminuser to sudoers with full privileges (NOPASSWD)
RUN echo "adminuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Add Kubernetes apt repository and install kubectl

# Download and extract the GitHub Actions runner
RUN cd /home/adminuser && mkdir actions-runner && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz

# Ensure the user has ownership of the files
RUN chown -R adminuser:adminuser /home/adminuser/actions-runner

# Install dependencies for the GitHub Actions runner
RUN /home/adminuser/actions-runner/bin/installdependencies.sh

# Add the user to the "docker" group
RUN usermod -aG docker adminuser

# Add adminuser to sudoers with full privileges (NOPASSWD)
RUN echo "adminuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Ensure the Docker socket is accessible via sudo
RUN echo "adminuser ALL=(ALL) NOPASSWD: /usr/bin/docker" >> /etc/sudoers

# Copy start.sh script into the container
COPY start.sh /home/adminuser/start.sh

# Make the script executable
RUN chmod +x /home/adminuser/start.sh

# Set the user to "adminuser" to run the container
USER adminuser

# Set the entrypoint to the start.sh script
ENTRYPOINT ["/home/adminuser/start.sh"]
