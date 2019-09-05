FROM phusion/baseimage:latest
LABEL maintainer="exie@pivotal.io"

CMD ["/sbin/my_init"]
ARG UID=501

RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    git curl wget gnupg \
    gnupg-agent \
    software-properties-common \
    unzip \
 && apt-get -qy autoremove \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    asciidoc \
    autoconf \
    automake \
    bash-completion \
    build-essential \
    bison \
    cmake \
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
    pinentry-curses \
    pkg-config \
    unixodbc-dev \
    xclip \
 && apt-get -qy autoremove \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
 && add-apt-repository ppa:neovim-ppa/stable \
 && add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
 && apt-get update && apt-get install -y --no-install-recommends \
    docker-ce docker-ce-cli containerd.io \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    neovim python3 python2.7 python-dev python3-dev python-pip python3-pip \
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
 && pip install --upgrade --no-cache-dir awscli \
 && pip install --upgrade --no-cache-dir yamllint

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

RUN git clone https://github.com/asdf-vm/asdf.git /home/pivotal/.asdf --branch v0.7.3

RUN add-apt-repository ppa:aacebedo/fasd \
&&  apt-get update && apt-get install -y --no-install-recommends \
    sudo tree jq fasd silversearcher-ag \
 && apt-get -qy autoremove \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 2000 pivotal \
 && useradd -ms /bin/bash -u $UID -g pivotal pivotal \
 && echo 'pivotal:pivotal' | chpasswd && adduser pivotal sudo \
 && chown -R pivotal:pivotal /home/pivotal

USER pivotal
WORKDIR /home/pivotal
ENV HOME /home/pivotal

COPY tool-versions $HOME/.tool-versions

RUN bash -c ". $HOME/.asdf/asdf.sh \
 && asdf plugin-add adr-tools \
 && asdf plugin-add cf \
 && asdf plugin-add dep \
 && asdf plugin-add eksctl \
 && asdf plugin-add golang \
 && asdf plugin-add helm \
 && asdf plugin-add istioctl \
 && asdf plugin-add kubectl \
 && asdf plugin-add nodejs \
 && bash /home/pivotal/.asdf/plugins/nodejs/bin/import-release-team-keyring \
 && asdf plugin-add packer \
 && asdf plugin-add protoc \
 && asdf plugin-add ruby \
 && asdf plugin-add shellcheck \
 && asdf plugin-add sqlite \
 && asdf plugin-add terraform \
 && asdf plugin-add yarn \
 && cd $HOME && asdf install \
 && rm -rf /tmp/*"

ENV GOPATH=$HOME/go

RUN mkdir -pv $GOPATH/src \
 && mkdir -pv $HOME/workspace \
 && mkdir -pv $HOME/.cf

RUN bash -c ". $HOME/.asdf/asdf.sh \
 && go get -u github.com/direnv/direnv \
 && go get -u github.com/git-duet/git-duet/... \
 && go get -u github.com/cf-container-networking/bosh-target \
 && go get -u github.com/dbellotti/cf-target \
 && go get -u github.com/fatih/hclfmt \
 && go get -u github.com/onsi/ginkgo/ginkgo \
 && go get -u github.com/onsi/gomega \
 && go get -u github.com/maxbrunsfeld/counterfeiter \
 && go get -u github.com/kkallday/deployment-extractor \
 && go get -u github.com/sourcegraph/go-langserver"

RUN mkdir -pv $HOME/setup \
 && cd $HOME/setup \
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
 && cp $NETWORKING_WORKSPACE/ssh_config $HOME/.ssh/config

RUN git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt --depth=1

ENV SSH_AUTH_SOCK=/tmp/.ssh-auth-sock
LABEL com.ensody.ssh-agent-inject=

COPY shared.bash $NETWORKING_WORKSPACE/shared.bash
COPY cf.config.json $HOME/.cf/config.json
