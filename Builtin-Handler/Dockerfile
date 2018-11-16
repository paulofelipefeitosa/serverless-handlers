FROM openjdk:10

RUN apt install curl \
    && curl -sL https://github.com/openfaas/faas/releases/download/0.9.6/fwatchdog > /usr/bin/fwatchdog \
    && chmod +x /usr/bin/fwatchdog

WORKDIR /root/

COPY src/Handler.java .
RUN javac Handler.java

ENV fprocess="java Handler"

HEALTHCHECK --interval=1s CMD [ -e /tmp/.lock ] || exit 1

CMD date "+Container-startup-time: %s%N" > timestamps.ts && fwatchdog
