# John Robinson 2017
# Dockerfile
# ** IMPORTANT ** must build with nvidia-docker

FROM nvidia/cuda:7.5-devel
COPY setup_container.sh /root/setup_container.sh
RUN chmod u+x /root/setup_container.sh
RUN /root/setup_container.sh 

CMD /bin/bash

