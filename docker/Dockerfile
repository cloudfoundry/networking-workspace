FROM phusion/baseimage:latest
LABEL maintainer="exie@pivotal.io"

CMD ["/sbin/my_init"]
ARG UID=501

RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl wget gnupg \
    gnupg-agent \
    software-properties-common \
    unzip \
 && apt-get -qy autoremove \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN apt-add-repository ppa:git-core/ppa \
 && apt-get update && apt-get install -y --no-install-recommends \
    asciidoc \
    autoconf \
    automake \
    bash-completion \
    build-essential \
    bison \
    cmake \
    git \
    libcurl3 \
    libcurl4-openssl-dev \
    libevent-dev \
    libffi-dev \
    libncurses-dev \
    libreadline-dev \
    libssl1.0.0 \
    libssl-dev \
    libtool \
    libxml2 \
    libxml2-dev \
    libxslt-dev \
    libyaml-dev \
    openssl \
    openvpn \
    pinentry-curses \
    pkg-config \
    unixodbc-dev \
    xclip \
 && apt-get -qy autoremove \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
 && add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
 && apt-get update && apt-get install -y --no-install-recommends \
    docker-ce docker-ce-cli containerd.io \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python2.7 python-dev python3-dev python-pip python3-pip \
    python-setuptools python3-setuptools \
 && apt-get -qy autoremove \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && pip install --upgrade --no-cache-dir pip \
 && pip3 install --upgrade --no-cache-dir pip \
 && hash -r pip \
 && hash -r pip3 \
 && pip install --upgrade --no-cache-dir neovim \
 && pip3 install --upgrade --no-cache-dir neovim \
 && pip install --upgrade --no-cache-dir awscli yamllint lxml requests

RUN git clone --depth 1 https://github.com/universal-ctags/ctags.git /tmp/ctags \
 && cd /tmp/ctags \
 && ./autogen.sh \
 && ./configure \
 && make \
 && make install \
 && rm -rf /tmp/ctags

RUN git clone --depth 1 https://github.com/lastpass/lastpass-cli.git /tmp/lastpass-cli \
 && cd /tmp/lastpass-cli \
 && make \
 && make install \
 && rm -rf /tmp/lastpass-cli

RUN git clone --depth 1 https://github.com/tmux/tmux.git /tmp/tmux \
 && cd /tmp/tmux \
 && ./autogen.sh \
 && ./configure \
 && make \
 && make install \
 && rm -rf /tmp/tmux

RUN git clone https://github.com/asdf-vm/asdf.git /home/pivotal/.asdf --branch v0.7.8

RUN add-apt-repository -y ppa:aacebedo/fasd \
 && apt-get update && apt-get install -y --no-install-recommends \
    sudo tree jq fasd silversearcher-ag \
 && apt-get -qy autoremove \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
 && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
 && apt-get update && apt-get install -y google-cloud-sdk \
 && apt-get -qy autoremove \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN add-apt-repository -y ppa:dwmw2/openconnect \
 && apt-get update && apt-get install -y openconnect \
 && apt-get -qy autoremove \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY pks-linux-amd64-1.7.0-build.417 /usr/local/bin/pks
COPY smith_linux_amd64.tar.gz /tmp/smith.tar.gz

RUN wget -O /usr/local/bin/bosh https://github.com/cloudfoundry/bosh-cli/releases/download/v6.3.0/bosh-cli-6.3.0-linux-amd64 \
 && wget -O /usr/local/bin/bbl https://github.com/cloudfoundry/bosh-bootloader/releases/download/v8.4.0/bbl-v8.4.0_linux_x86-64 \
 && wget -O /usr/local/bin/om https://github.com/pivotal-cf/om/releases/download/5.0.0/om-linux-5.0.0 \
 && wget -O /usr/local/bin/pivnet https://github.com/pivotal-cf/pivnet-cli/releases/download/v1.0.4/pivnet-linux-amd64-1.0.4 \
 && wget -O /tmp/credhub.tgz https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/2.7.0/credhub-linux-2.7.0.tgz \
 && wget -O /tmp/codeserver.deb https://github.com/cdr/code-server/releases/download/v3.4.1/code-server_3.4.1_amd64.deb \
 && wget -O /tmp/kubebuilder.tar.gz https://github.com/kubernetes-sigs/kubebuilder/releases/download/v2.3.1/kubebuilder_2.3.1_linux_amd64.tar.gz \
 && tar -xzf /tmp/credhub.tgz -C /tmp && mv /tmp/credhub /usr/local/bin/credhub \
 && dpkg -i /tmp/codeserver.deb \
 && tar -xzf /tmp/kubebuilder.tar.gz -C /tmp && mv /tmp/kubebuilder*/bin/kubebuilder /usr/local/bin/kubebuilder \
 && tar -xzf /tmp/smith.tar.gz -C /tmp && mv /tmp/smith /usr/local/bin/smith \
 && chmod +x /usr/local/bin/pks /usr/local/bin/bosh /usr/local/bin/bbl /usr/local/bin/om /usr/local/bin/pivnet \
 && chmod +x /usr/local/bin/credhub /usr/local/bin/kubebuilder /usr/local/bin/smith \
 && rm -rf /tmp/*

# Enable the SSH server on the container
RUN rm -f /etc/service/sshd/down
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

RUN groupadd -g 2000 pivotal \
 && useradd -ms /bin/bash -u $UID -g pivotal pivotal \
 && echo 'pivotal:pivotal' | chpasswd \
 && usermod -aG sudo pivotal \
 && usermod -aG docker pivotal \
 && chown -R pivotal:pivotal /home/pivotal \
 && chmod 1777 /tmp

USER pivotal
WORKDIR /home/pivotal
ENV HOME /home/pivotal

RUN mkdir -pv $HOME/setup

COPY asdf-install.sh $HOME/setup/asdf-install.sh

RUN bash $HOME/setup/asdf-install.sh

ENV GOPATH=$HOME/go

RUN mkdir -pv $HOME/go \
 && mkdir -pv $HOME/workspace \
 && mkdir -pv $HOME/.cf

RUN bash -c ". $HOME/.asdf/asdf.sh \
 && export GO111MODULE=on \
 && go get github.com/direnv/direnv \
 && go get github.com/git-duet/git-duet/... \
 && go get github.com/cf-container-networking/bosh-target \
 && go get github.com/dbellotti/cf-target \
 && go get github.com/fatih/hclfmt \
 && go get github.com/onsi/ginkgo/ginkgo \
 && go get github.com/onsi/gomega \
 && go get github.com/maxbrunsfeld/counterfeiter/v6 \
 && go get github.com/kkallday/deployment-extractor \
 && go get sigs.k8s.io/kind@v0.7.0"

RUN cd $HOME/setup \
 && git clone https://github.com/cloudfoundry/networking-workspace \
 && cd networking-workspace \
 && ln -sf $(pwd)/git-authors $HOME/.git-authors \
 && ln -sf $(pwd)/shared.bash $HOME/.profile \
 && ln -sf $(pwd)/gitconfig $HOME/.gitconfig \
 && ln -sf $(pwd)/inputrc $HOME/.inputrc \
 && ln -sf $(pwd)/flyrc $HOME/.flyrc \
 && ln -sf $(pwd)/global-gitignore $HOME/.global-gitignore \
 && ln -sf $(pwd)/git-prompt-colors.sh $HOME/.git-prompt-colors.sh \
 && ln -sfn $(pwd)/scripts $HOME/scripts

RUN cd $HOME/setup \
 && git clone --single-branch --branch feature/push \
    https://github.com/sirmax/pan-globalprotect-okta/

ENV NETWORKING_WORKSPACE /home/pivotal/setup/networking-workspace

RUN mkdir -pv $HOME/.config \
 && git clone https://github.com/luan/nvim $HOME/.config/nvim \
 && mkdir -p $HOME/.config/nvim/user \
 && ln -sf "$NETWORKING_WORKSPACE/nvim_config/after.vim" "$HOME/.config/nvim/user/after.vim" \
 && mkdir -p ${HOME}/.vim/UltiSnips \
 && ln -sf $NETWORKING_WORKSPACE/go.snippets ${HOME}/.vim/UltiSnips

RUN git clone https://github.com/luan/tmuxfiles $HOME/setup/tmuxfiles \
 && yes | $HOME/setup/tmuxfiles/install

RUN mkdir -pv $HOME/.ssh \
 && chmod 0700 $HOME/.ssh \
 && cp $NETWORKING_WORKSPACE/ssh_config $HOME/.ssh/config \
 && ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

RUN git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt --depth=1 \
 && wget -O $HOME/scripts/diff-highlight \
   https://raw.githubusercontent.com/git/git/d5cb9cbd64165153a318e1049f8bf14b09a16b11/contrib/diff-highlight/diff-highlight \
 && chmod +x $HOME/scripts/diff-highlight

ENV SSH_AUTH_SOCK=/tmp/.ssh-auth-sock
LABEL com.ensody.ssh-agent-inject=

COPY shared.bash $NETWORKING_WORKSPACE/shared.bash
COPY cf.config.json $HOME/.cf/config.json
COPY pivotal.conf $HOME/setup/pan-globalprotect-okta/pivotal.conf
