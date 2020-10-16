FROM r-base:3.6.3

ENV SHINY_SERVER_GITHUB_URL=https://github.com/rstudio/shiny-server.git 
ENV SHINY_SERVER_CONF_DIR=/etc/shiny-server
ENV SHINY_SERVER_APP_DIR=/srv/shiny-server
ENV SHINY_SERVER_LOG_DIR=/var/log/shiny-server
ENV SHINY_SERVER_LIB_DIR=/var/lib/shiny-server

WORKDIR /tmp

RUN apt-get update --fix-missing && \
    apt-get install -y python3 git cmake libcurl4-openssl-dev libssl-dev && \
    apt-get autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* 

RUN git clone ${SHINY_SERVER_GITHUB_URL} /tmp && \
    mkdir -p /tmp/install-node && \
    ( cd /tmp/install-node && ../external/node/install-node.sh ) && \
    PATH=/tmp/bin:$PATH && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local . && \
    make && \
    mkdir build && \
    ./bin/npm install && \
    ./bin/npm audit fix && \
    ./bin/node ./ext/node/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js rebuild && \
    make install && \
    ln -s /usr/local/shiny-server/bin/shiny-server /usr/bin/shiny-server && \
    mkdir -p ${SHINY_SERVER_CONF_DIR} && \
    cp -v config/default.config ${SHINY_SERVER_CONF_DIR}/shiny-server.conf && \
    sed -i 's/3838;/3838 0.0.0.0;/' ${SHINY_SERVER_CONF_DIR}/shiny-server.conf && \
    rm -rf /tmp/* && \
    Rscript -e "install.packages('shiny')" 

RUN useradd -r -d ${SHINY_SERVER_APP_DIR} -m shiny && \
    mkdir -p ${SHINY_SERVER_LOG_DIR} ${SHINY_SERVER_LIB_DIR} && \
    chown shiny ${SHINY_SERVER_LOG_DIR} ${SHINY_SERVER_LIB_DIR}

WORKDIR $SHINY_SERVER_APP_DIR

USER shiny

RUN mkdir ${SHINY_SERVER_LIB_DIR}/library && \
    echo "R_LIBS=${SHINY_SERVER_LIB_DIR}/library" > .Renviron

EXPOSE 3838

ENTRYPOINT ["shiny-server"]
