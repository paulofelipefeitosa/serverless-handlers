FROM openjdk:10

RUN apt-get update \
	&& apt-get install -y curl maven \
    && curl -sL https://github.com/paulofelipefeitosa/faas/releases/download/v0.1-test/fwatchdog > /usr/bin/fwatchdog \
    && chmod +x /usr/bin/fwatchdog

WORKDIR /root/

RUN git clone https://github.com/paulofelipefeitosa/openfaas-java-handlers.git

RUN cd openfaas-java-handlers/heavy-handler

RUN mvn install

RUN ls && ls target

ENV fprocess="java -jar target/heavy-handler.0.0.1-SNAPSHOT.jar"

HEALTHCHECK --interval=1s CMD [ -e /tmp/.lock ] || exit 1

CMD date "+Container-startup-time: %s%N" > timestamps.ts && fwatchdog
