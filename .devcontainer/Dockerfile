FROM debian:bullseye

# disable interactive ui
ENV DEBIAN_FRONTEND=noninteractive

# install dependencies from package manager
RUN apt update && apt install -y \
    sudo \
    git \
    curl wget

# install nodejs, npm & yarn
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && apt-get install -y nodejs
RUN npm install -g yarn

# create 'dev' user, add it to sudo group and set password
RUN mkdir /home/dev
RUN useradd dev && chown -R dev /home/dev
RUN adduser dev sudo
RUN echo "dev:dev"|chpasswd 
