FROM ubuntu:trusty
MAINTAINER Chad Schmutzer <schmutze@amazon.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -q update && \
  apt-get -y -q dist-upgrade && \
  apt-get -y -q install rsyslog python-setuptools python-pip curl

RUN curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -o awslogs-agent-setup.py

RUN sed -i "s/#\$ModLoad imudp/\$ModLoad imudp/" /etc/rsyslog.conf && \
  sed -i "s/#\$UDPServerRun 514/\$UDPServerRun 514/" /etc/rsyslog.conf && \
  sed -i "s/#\$ModLoad imtcp/\$ModLoad imtcp/" /etc/rsyslog.conf && \
  sed -i "s/#\$InputTCPServerRun 514/\$InputTCPServerRun 514/" /etc/rsyslog.conf

RUN sed -i "s/authpriv.none/authpriv.none,local6.none,local7.none/" /etc/rsyslog.d/50-default.conf

RUN echo "if \$syslogfacility-text == 'local6' and \$programname == 'httpd' then /var/log/httpd-access.log" >> /etc/rsyslog.d/httpd.conf && \
	echo "if \$syslogfacility-text == 'local6' and \$programname == 'httpd' then ~" >> /etc/rsyslog.d/httpd.conf && \
	echo "if \$syslogfacility-text == 'local7' and \$programname == 'httpd' then /var/log/httpd-error.log" >> /etc/rsyslog.d/httpd.conf && \
	echo "if \$syslogfacility-text == 'local7' and \$programname == 'httpd' then ~" >> /etc/rsyslog.d/httpd.conf

COPY awslogs.conf awslogs.conf
RUN python ./awslogs-agent-setup.py -n -r us-east-1 -c /awslogs.conf

RUN pip install supervisor
COPY supervisord.conf /usr/local/etc/supervisord.conf

EXPOSE 514/tcp 514/udp
CMD ["/usr/local/bin/supervisord"]
