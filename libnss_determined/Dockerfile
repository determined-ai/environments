FROM debian

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
 && rm -rf /var/lib/apt/lists/*

COPY . /tmp/libnss_determined

RUN make -C /tmp/libnss_determined mini install \
  && rm -rf /tmp/libnss_determined \
  && sed -r -i -e 's/^(passwd:.*)/\1 determined/' /etc/nsswitch.conf \
  && sed -r -i -e 's/^(shadow:.*)/\1 determined/' /etc/nsswitch.conf \
  && sed -r -i -e 's/^(group:.*)/\1 determined/' /etc/nsswitch.conf \
  && mkdir -p /run/determined \
  && echo "user:1000:user:1000" > /run/determined/agent_user_group
