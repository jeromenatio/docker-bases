# DOCKER BASES

Boilerplate files and scripts to install a docker based web server.\
It includes the following containers / services :

- reverse proxy and ssl certification `nginx proxy manager` on port `81`
- container manager `portainer` on port `9000`
- databases client `adminer` on port `8080`
- shells client `sshwifty` on port `8182`
- online code editor `vscode` on port `8443`

All services come with a `graphical user interface` so no code needed after installation et configuration. \
The script is for a debian based linux distribution that uses apt as package manager like `debian` `ubuntu` `etc...` \
For each following steps please replace `/path/to/file/install.sh` with the path of the output file on your system.

## INSTALLATION

##### Download install.sh
```bash
sudo wget -q https://raw.githubusercontent.com/jeromenatio/docker-bases/main/install.sh \
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
sudo wget -q https://raw.githubusercontent.com/jeromenatio/docker-bases/main/install.sh -O /path/to/file/install.sh \
&& sudo chmod +x /path/to/file/install.sh \
&& sudo /path/to/file/install.sh
```

## CONFIGURATION
This section wil be updated soon