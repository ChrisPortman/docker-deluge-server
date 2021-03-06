#A deluge server bundled with some post processing and XBMC integration
FROM ubuntu:14.04
MAINTAINER Chris Portman <chris@portman.net.au>

#Install apt packages
#Just need to find a package for File::Unpack
ADD sources.list /etc/apt/sources.list
ADD deluge.list /etc/apt/sources.list.d/deluge.list
RUN apt-get update && apt-get install -y --force-yes build-essential lzma-dev libmagic-dev git deluged deluge-web deluge-console libcompress-raw-lzma-perl libconfig-auto-perl libemail-sender-perl libemail-sender-transport-smtps-perl libemail-mime-perl liblog-any-adapter-dispatch-perl liblog-any-adapter-perl liblog-any-perl libmime-lite-perl libjson-perl libjson-xs-perl libwww-mechanize-perl make libdancer-perl libdancer-plugin-rest-perl starman unrar

#Install File::Unpack from cpan
#The cpan client is picky and typically works, but will produce a non-zero exit code.
ADD cpan_config.pm /tmp/cpan_config.pm
RUN cpan -j /tmp/cpan_config.pm -f -T -i File::Unpack; echo 'done'

#Clone the required GIT repos
RUN echo 2 && git clone https://github.com/ChrisPortman/downloadManager.git /opt/download_manager
RUN echo 4 && git clone https://github.com/ChrisPortman/TorrentManager.git /opt/torrent_manager

#Configure the post processing scripts
RUN cp /opt/download_manager/etc/downloads.conf.sample /opt/download_manager/etc/downloads.conf
RUN ln -s /opt/download_manager/etc/downloads.conf /etc/downloadManager.conf

#Add the deluge config
ADD deluge_config.tar.gz /etc/deluge/
ADD configure.pl /tmp/configure.pl
ADD environment.conf /tmp/environment.conf

#Configure the TorrentManager web application
ADD production.yml /opt/torrent_manager/environments/production.yml

#Apply all the settings from the environment.conf
RUN perl /tmp/configure.pl

#Publish the network port
EXPOSE 80
EXPOSE 8112
EXPOSE 58846

#Define the Entrypoint
ENTRYPOINT plackup -D -E production -s Starman --workers=10 -p 80 /opt/torrent_manager/bin/app.pl; /usr/bin/deluged -d -c /etc/deluge

