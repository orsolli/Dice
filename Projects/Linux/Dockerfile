FROM ubuntu:18.04
RUN apt update 
RUN apt install -y -qq build-essential \
    libopenal-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libx11-dev \
    libxext-dev \
    libxrender-dev \
    libxft-dev \
    libcurl4-openssl-dev
RUN useradd leadwerks
RUN mkdir -p /home/leadwerks/.steam
USER leadwerks
WORKDIR /home/leadwerks/
#https://www.ultraengine.com/community/topic/19903-ubuntu-2004-and-leadwerks/
