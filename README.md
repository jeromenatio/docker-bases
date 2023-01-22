# DOCKER BASES
Boiler files and scripts to install a docker based webserver.\
It includes reverse proxies and ssl certification.\
The script is for a debian based linux (debian, ubuntu ...). \
For each following steps please replace "/path_to_file/install.sh" with the path to output file on your system.

## Download install.sh
```bash
sudo wget -q https://raw.githubusercontent.com/jeromenatio/docker-bases/main/install.sh -O /path_to_file/install.sh
```

## Make it executable
```bash
sudo chmod +x /path_to_file/install.sh
```

## Execute and follow instructions
```bash
sudo /path/tofile/install.sh
```

## Single command
```bash
sudo wget -q https://raw.githubusercontent.com/jeromenatio/docker-bases/main/install.sh -O /path_to_file/install.sh \
&& sudo chmod +x /path_to_file/install.sh \
&& sudo /path_to_file/install.sh
```
