FROM amd64/ubuntu:18.04 AS base

EXPOSE 8788/tcp
EXPOSE 9766/tcp

ENV DEBIAN_FRONTEND=noninteractive

#Add ppa:bitcoin/bitcoin repository so we can install libdb4.8 libdb4.8++
RUN apt-get update && \
	apt-get install -y software-properties-common && \
	add-apt-repository ppa:bitcoin/bitcoin

#Install runtime dependencies
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
	bash net-tools libminiupnpc10 \
	libevent-2.1 libevent-pthreads-2.1 \
	libdb4.8 libdb4.8++ \
	libboost-system1.65 libboost-filesystem1.65 libboost-chrono1.65 \
	libboost-program-options1.65 libboost-thread1.65 \
	libzmq5 && \
	apt-get clean

FROM base AS build

#Install build dependencies
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
	bash net-tools build-essential libtool autotools-dev automake git \
	pkg-config libssl-dev libevent-dev bsdmainutils python3 \
	libboost-system1.65-dev libboost-filesystem1.65-dev libboost-chrono1.65-dev \
	libboost-program-options1.65-dev libboost-test1.65-dev libboost-thread1.65-dev \
	libzmq3-dev libminiupnpc-dev libdb4.8-dev libdb4.8++-dev && \
	apt-get clean

#Build Meowcoin from source
COPY . /home/meowcoin/build/Meowcoin/
WORKDIR /home/meowcoin/build/Meowcoin
RUN ./autogen.sh && ./configure --disable-tests --with-gui=no && make

FROM base AS final

#Copy the compiled binaries from the build
COPY --from=build /home/meowcoin/build/Meowcoin/src/meowcoind /usr/local/bin/meowcoind
COPY --from=build /home/meowcoin/build/Meowcoin/src/meowcoin-cli /usr/local/bin/meowcoin-cli

ENTRYPOINT ["meowcoind", "-printtoconsole", "-onlynet=ipv4"]
