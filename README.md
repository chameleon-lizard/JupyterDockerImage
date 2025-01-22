# jupyter-docker-setup

This script simplifies the process of setting up a Docker container for JupyterLab with GPU support, based on PyTorch's Docker images. It automates the creation of `docker-compose.yml` and `Dockerfile` files, allowing you to quickly launch a customized Jupyter environment with your desired system packages and Python modules.

## Prerequisites

Before running the script, ensure you have the following installed and configured:

1. Docker: Install Docker on your system.
2. Docker Compose: Install Docker Compose. Docker Desktop usually includes Docker Compose.
3. NVIDIA Drivers: Make sure you have NVIDIA drivers correctly installed for your GPU. You can verify this by running `nvidia-smi` in your terminal. If it runs without errors, your drivers are likely installed.

## Usage

```
bash <(curl -s https://raw.githubusercontent.com/chameleon-lizard/JupyterDockerImage/refs/heads/main/setup_server.sh)
```

This will create two directories in your home directory: `docker` and `jupyter-docker`. Inside the `jupyter-docker` there will be the `docker-compose.yml` and `Dockerfile` files, which you can manually modify. If you modify the `Dockerfile`, you will need to rebuild the Docker image. You can do this by running `docker-compose up --build` or `docker-compose build` followed by `docker-compose up`.

To start the container, you can just run `docker-compose up -d` inside of this directory. To stop the container, run `docker-compose down`.

Inside `docker` directory there will be all files, which are accessed from the docker container. This can be used to send files inside the container.

To access the jupyter lab instance inside the container, you need to do port forwarding:

```
ssh username@server -L <JUPYTER_PORT>:localhost:<JUPYTER_PORT>
```

By default it will be 8888, but it might not be available, if so, modify it manually inside `docker-compose.yml` and `Dockerfile`.

## Customization

The script generates two main files that you can customize further:

- `docker-compose.yml`: This file defines the Docker Compose setup. You can modify:
    - `container_name`:  Change the container name directly in the `docker-compose.yml` file if you didn't provide one during script execution or want to change it later.
    - `ports`:  Adjust port mappings if you need to use a different port than `8888` on your host machine.
    - `volumes`:  Modify volume mounts to share different directories or datasets between your host machine and the container. The current setup mounts your `$HOME/jupyter-docker` directory to `/my_dir` inside the container and the Hugging Face cache directory.
    - `resources.limits.memory`: Change the memory limit for the container if needed.
    - `devices.device_ids`:  Modify the GPU device ID if you need to use a different GPU.
    - `environment.JUPYTER_TOKEN`: While the token is set via an environment variable, you can manage it differently if required, although using an environment variable is generally recommended.

- `Dockerfile`: This file defines how the Docker image is built. You can customize:
    - Base Image (`FROM`):  Change the base PyTorch Docker image if you need a different PyTorch version, CUDA version, or want to use a different base image altogether.
    - Installed Packages: The script already handles system packages and Python modules based on your input. However, you can add more `RUN apt install` or `RUN pip install` commands in the `Dockerfile` to install additional software or libraries.
    - Working Directory (`WORKDIR`): Change the default working directory inside the container.
    - Jupyter Startup Command (`CMD`): Modify the JupyterLab startup command if you need different JupyterLab extensions or configurations.


