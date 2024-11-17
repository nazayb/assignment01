FROM ubuntu:22.04
RUN apt update && \
apt install sudo
COPY benchmark.sh /benchmark.sh
ENTRYPOINT ["bash", "/benchmark.sh"]
