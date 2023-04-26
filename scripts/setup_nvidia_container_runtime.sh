sudo apt-get install nvidia-container-runtime -y
sudo echo > /etc/docker/daemon.json <<'daemon'
{
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
         }
    },
    "default-runtime": "nvidia"
}
daemon
sudo systemctl restart docker
