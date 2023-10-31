# DOCKER BASES

Boilerplate files and scripts to install a docker based server.\
It will install everything you need to use docker and docker-compose, as well as basic cli tools to auto install some prepared containers.\
By default nginxproxy manager will also be installed and launched for reverse proxy and ssl certification `nginx proxy manager` on port `81`.\

The script is for a debian based linux distribution that uses apt as package manager like `debian` `ubuntu` `etc...` \
For each following steps please replace `/path/to/file/install.sh` with the path of the output file on your system.

## INSTALLATION

##### Download install.sh
```bash
sudo wget -q https://raw.githubusercontent.com/jeromenatio/docker-bases/main/scripts/tninstall.sh \
-O /path/to/file/install.sh
```

##### Make it executable
```bash
sudo chmod +x /path/to/file/install.sh
```

##### Execute and follow instructions
```bash
sudo /path/tofile/install.sh
```

##### All in a single command
```bash
sudo wget -q https://raw.githubusercontent.com/jeromenatio/docker-bases/main/scripts/tninstall.sh -O /path/to/file/install.sh \
&& sudo chmod +x /path/to/file/install.sh \
&& sudo /path/to/file/install.sh
```