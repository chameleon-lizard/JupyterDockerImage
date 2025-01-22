#!/bin/bash

set -e # Exit on error

nvidia-smi || { echo "Error: nvidia-smi failed. Make sure NVIDIA drivers are installed."; exit 1; }

mkdir -p $HOME/jupyter-docker
cd $HOME/jupyter-docker

read -p "Enter a name for your jupyter container (optional, leave empty for default): " CONTAINER_NAME
read -p "Enter your device ID for the jupyter container: " DEVICE_ID
read -p "Enter your jupyter token: " JUPYTER_TOKEN
read -p "Enter a list of system packages to install (space-separated, e.g., curl vim): " PACKAGES
read -p "Enter a list of Python modules to install (space-separated, e.g., tensorflow torch): " MODULES

# No quoting for PACKAGES and MODULES here - they will be used unquoted in RUN commands
# PACKAGES_QUOTED=$(printf "%q " $PACKAGES) # No quoting for PACKAGES
# MODULES_QUOTED=$(printf "%q " $MODULES)   # No quoting for MODULES

DEVICE_ID_QUOTED=$(printf "%q" "$DEVICE_ID")
JUPYTER_TOKEN_QUOTED=$(printf "%q" "$JUPYTER_TOKEN")
CONTAINER_NAME_QUOTED=$(printf "%q" "$CONTAINER_NAME")

PIP_INSTALL_CMD="RUN pip install jupyterlab ipywidgets ipykernel"
if [ -n "$MODULES" ]; then # Check unquoted MODULES
  PIP_INSTALL_CMD="$PIP_INSTALL_CMD $MODULES" # Use unquoted MODULES
fi

APT_INSTALL_CMD="RUN apt install -y curl"
if [ -n "$PACKAGES" ]; then # Check unquoted PACKAGES
  APT_INSTALL_CMD="$APT_INSTALL_CMD $PACKAGES" # Use unquoted PACKAGES
fi


cat <<EOF > docker-compose.yml
version: '3.8'
services:
  jupyter:
    build: .
    ports:
      - "8888:8888"
    volumes:
      - $HOME/jupyter-docker:/my_dir  # Changed volume mount for clarity
      - ~/.cache/huggingface:/root/.cache/huggingface
    deploy:
      resources:
        limits:
          memory: 24G
        reservations:
          devices:
            - driver: nvidia
              device_ids: ['$DEVICE_ID_QUOTED'] # Keep quoting for DEVICE_ID
              capabilities: [gpu]
    environment: # Using environment variable for token
      JUPYTER_TOKEN: ${JUPYTER_TOKEN_QUOTED} # Keep quoting for JUPYTER_TOKEN
EOF

if [ -n "$CONTAINER_NAME" ]; then
  echo "    container_name: ${CONTAINER_NAME_QUOTED}" >> docker-compose.yml # Keep quoting for CONTAINER_NAME
fi

cat <<EOF > Dockerfile
FROM pytorch/pytorch:2.2.0-cuda12.1-cudnn8-devel

# Install Jupyter and other necessary packages
$PIP_INSTALL_CMD # Uses unquoted MODULES in PIP_INSTALL_CMD

# Set the working directory
WORKDIR /my_dir

# Remove nvidia repos to enable updating
RUN echo '' > /etc/apt/sources.list.d/cuda-ubuntu2204-x86_64.list

# Update repositories and install a sample application inside the container
RUN apt update && apt upgrade -y # Update and upgrade packages
$APT_INSTALL_CMD # Uses unquoted PACKAGES in APT_INSTALL_CMD

# Expose the Jupyter port
EXPOSE 8888

# Start Jupyter when the container runs (using shell form for CMD)
CMD jupyter lab --allow-root --ip=0.0.0.0 "--NotebookApp.token=$JUPYTER_TOKEN"

EOF

echo 'To run the container, use \`docker-compose up\`.'
echo 'To run the container in background, use \`docker-compose up -d\`, to stop it, use \`docker-compose down\`.'
echo 'To install additional applications or Python packages, see \`Dockerfile\`.'
echo 'To change resources configuration, see \`docker-compose.yml\`.'

