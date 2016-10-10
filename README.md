kivitendo_docker
================

Docker Build for Kivitendo a erp solution for small businesses


# Table of Contents

- [Introduction](#introduction)
- [Changelog](Changelog.md)
- [Contributing](#contributing)
- [Reporting Issues](#reporting-issues)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Creating User and Database at Launch](creating-user-and-database-at-launch)
- [Configuration](#configuration)
    - [Data Store](#data-store)
- [Upgrading](#upgrading)

# Introduction

Dockerfile to build a Kivitendo container image which can be linked to other containers.
Will install Postgres and Apache2 and all the necessary packages for Kivitendo.

# Contributing

If you find this image useful here's how you can help:

- Send a Pull Request with your awesome new features and bug fixes
- Help new users with [Issues](https://github.com/drnoa/kivitendo_docker/issues) they may encounter

# Reporting Issues

Docker is a relatively new project and is active being developed and tested by a thriving community of developers and testers and every release of docker features many enhancements and bugfixes.

Given the nature of the development and release cycle it is very important that you have the latest version of docker installed because any issue that you encounter might have already been fixed with a newer docker release.

For ubuntu users I suggest [installing docker](https://docs.docker.com/installation/ubuntulinux/) using docker's own package repository since the version of docker packaged in the ubuntu repositories are a little dated.

Here is the shortform of the installation of an updated version of docker on ubuntu.

```bash
sudo apt-get purge docker.io
curl -s https://get.docker.io/ubuntu/ | sudo sh
sudo apt-get update
sudo apt-get install lxc-docker
```

# Installation

Pull the latest version of the image from the docker index. This is the recommended method of installation as it is easier to update image in the future. These builds are performed by the **Docker Trusted Build** service.

```bash
docker pull drnoa/kivitendo-docker
```

Alternately you can build the image yourself.

```bash
git clone https://github.com/drnoa/kivitendo_docker.git
cd kivitendo_docker
docker build -t="$USER/kivitendo_docker" .
```

# Quick Start

Run the Kivitendo image

```bash
docker run --name kivitendo_docker -d drnoa/kivitendo_docker
```
Check the ip of your docker container
```bash
docker ps -q | xargs docker inspect | grep IPAddress | cut -d '"' -f 4
```

Got to the administrative interface of kivitendo using the password: admin123 and configure the database. All database users (kivitendo and docker) use docker as password.

Alternately you can fetch the password set for the `postgres` user from the container logs.

```bash
docker logs postgresql
```

In the output you will notice the following lines with the password:

```bash
|------------------------------------------------------------------|
| PostgreSQL User: postgres, Password: xxxxxxxxxxxxxx              |
|                                                                  |
| To remove the PostgreSQL login credentials from the logs, please |
| make a note of password and then delete the file pwfile          |
| from the data store.                                             |
|------------------------------------------------------------------|
```

To test if the postgresql server is working properly, try connecting to the server.

```bash
psql -U postgres -h $(docker inspect --format {{.NetworkSettings.IPAddress}} postgresql)
```

# Configuration

## Data Store

For data persistence a volume should be mounted at `/var/lib/postgresql`.

The updated run command looks like this.

```bash
docker run --name postgresql -d \
  -v /opt/postgresql/data:/var/lib/postgresql drnoa/kivitendo_docker:latest
```

This will make sure that the data stored in the database is not lost when the image is stopped and started again.

## Securing the server

By default 'docker' is assigned as password for the postgres user. 

You can change the password of the postgres user
```bash
psql -U postgres -h $(docker inspect --format {{.NetworkSettings.IPAddress}} postgresql)
\password postgres
```

## Build container from Dockerfile
You can build the container from the Dockerfile in
https://github.com/drnoa/kivitendo_docker

simply clone the git repo localy and then build
```bash
git clone https://github.com/drnoa/kivitendo_docker.git
cd kivitendo_docker
sudo docker build .
```

When you build the container using the Dockerfile you have the possibility to change some parameters
for example the used postgressql version or the database locale (default ist de_DE).
Its also possible to change the postgred passwords.
To change this paramters simply edit the Dockerfile and edit the following values:
```bash
ENV postgresversion 9.3
ENV locale de_CH
ENV postrespassword docker
```


# Upgrading

To upgrade to newer releases, simply follow this 3 step upgrade procedure.

- **Step 1**: Stop the currently running image

```bash
docker stop $USER/kivitendo_docker
```

- **Step 2**: Update the docker image.

```bash
docker pull drnoa/kivitendo_docker:latest
```

- **Step 3**: Start the image

```bash
docker run --name kivitendo_docker -d [OPTIONS] drnoa/kivitendo_docker:latest
```
