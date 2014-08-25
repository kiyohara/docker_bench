FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update
RUN apt-get -y install supervisor
RUN apt-get -y install openssh-server
RUN apt-get -y install sudo
RUN apt-get -y install ruby
RUN apt-get -y install ruby-dev
RUN apt-get -y install g++
RUN apt-get -y install make
RUN apt-get -y install libssl-dev
RUN apt-get -y install curl

RUN mkdir -p /usr/local/bench

### supervisor
RUN mkdir -p /var/log/supervisor
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

### sshd
RUN mkdir -p /var/log/sshd
RUN mkdir -p /var/run/sshd

RUN useradd docker
RUN mkdir -p /home/docker/.ssh;
RUN chown docker /home/docker/.ssh
RUN chmod 700 /home/docker/.ssh
ADD ./authorized_keys /home/docker/.ssh/authorized_keys
RUN chown docker /home/docker/.ssh/authorized_keys
RUN chmod 600 /home/docker/.ssh/authorized_keys
RUN chsh -s /bin/bash docker

RUN gpasswd -a docker adm
RUN gpasswd -a docker sudo
RUN mkdir -p /etc/sudoers.d/
ADD sudoers.d/docker /etc/sudoers.d/docker
RUN chmod 400 /etc/sudoers.d/docker

### em-httpd
RUN gem install --no-ri --no-rdoc eventmachine
RUN gem install --no-ri --no-rdoc em-http-server
RUN gem install --no-ri --no-rdoc awesome_print
ADD em-httpd.rb /usr/local/bench/em-httpd.rb

### curl-ping
RUN apt-get -y install curl
ADD curl-ping.sh /usr/local/bench/curl-ping.sh

CMD ["/usr/bin/supervisord"]

