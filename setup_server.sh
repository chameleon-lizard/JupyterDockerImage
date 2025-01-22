#!/bin/bash


mkdir -p jupyter-docker
cd jupyter-docker
mkdir -p $HOME/docker

read -p "Enter your device ID for the jupyter container" DEVICE_ID
read -p "Enter your jupyter token: " JUPYTER_TOKEN
read -p "Enter a list of packages to install into the container: " PACKAGES
read -p "Enter a list of python modules to install into the container: " MODULES

echo "
version: '3.8'
services:
  jupyter:
    build: .  #  <-- Use the Dockerfile in current directory
    ports:
      - "8888:8888"
    volumes:
      - $HOME/docker:/my_dir # Insert path to your own directory
      - ~/.cache/huggingface:/root/.cache/huggingface
    networks:
      - my_network
    deploy:
      resources:
        limits:
          memory: 24G
        reservations:
          devices:
            - driver: nvidia
              device_ids: ['$DEVICE_ID'] # Modify this if you need more than one GPUs
              capabilities: [gpu]
networks:
  my_network:
    driver: bridge
" > docker-compose.yml

echo "FROM pytorch/pytorch:2.2.0-cuda12.1-cudnn8-devel

# Install Jupyter and other necessary packages
RUN pip install jupyterlab ipywidgets ipykernel $MODULES # To add your own packages, modify this

# Set the working directory
WORKDIR /my_dir

# Remove nvidia repos to enable updating
RUN echo '' > /etc/apt/sources.list.d/cuda-ubuntu2204-x86_64.list

# Update repositories and install a sample application inside the container
RUN apt update
RUN apt install -y curl $PACKAGES # To install your own applications modify this

# Expose the Jupyter port
EXPOSE 8888

# Start Jupyter when the container runs
CMD ["jupyter", "lab", "--allow-root", "--ip=0.0.0.0", "--NotebookApp.token=$JUPYTER_TOKEN"]

" > Dockerfile

echo 'To run the container, use `docker-compose up`.'
echo 'To run the container in background, use `docker-compose up -d`, to stop it, use `docker-compose down`.'
echo 'To install additional applications or Python packages, see `Dockerfile`.'
echo 'To change resources configuration, see `docker-compose.yml`.'

