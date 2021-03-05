FROM debian

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        valgrind \
  && rm -rf /var/lib/apt/lists/*

COPY . /tmp/libnss_determined

RUN make -C /tmp/libnss_determined libnss_determined.so.2 install \
  && rm -rf /tmp/libnss_determined \
  && sed -E -i -e 's/^((passwd|shadow|group):.*)/\1 determined/' /etc/nsswitch.conf \
  && mkdir -p /run/determined/etc \
  && echo "user:x:1000:1000::/home/user:/bin/bash" > /run/determined/etc/passwd \
  && echo "user:THEHASH:18459::::::" > /run/determined/etc/shadow \
  && echo "user:x:1000:" > /run/determined/etc/group
