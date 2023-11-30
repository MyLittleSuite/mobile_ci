FROM ubuntu:22.04

SHELL ["/bin/bash", "-c"]

## Set timezone to UTC
RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

## Set locale
RUN apt-get update && apt-get -y install locales && \
    locale-gen en_US.UTF-8 || true
ENV LANG=en_US.UTF-8

## Install dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
  build-essential \
  curl \
  file \
  git \
  libcurl4 libcurl4-openssl-dev \
  libyaml-0-2 \
  libgmp-dev \
  libreadline-dev \
  libssl-dev \
  openjdk-17-jdk \
  openjdk-11-jdk \
  openjdk-8-jdk \
  ssh \
  unzip \
  wget \
  zlib1g-dev


## Install Dart
ARG dart=false
ARG dart_sdk=/usr/lib/dart
ARG dart_version=3.2.1
RUN if [ $dart = true ] ; \
  then \
    echo "Installing Dart SDK"; \
    mkdir -p ${dart_sdk} && \
    wget --quiet --output-document=/tmp/dartsdk-linux-x64-release.zip https://storage.googleapis.com/dart-archive/channels/stable/release/${dart_version}/sdk/dartsdk-linux-x64-release.zip && \
    unzip -q /tmp/dartsdk-linux-x64-release.zip -d ${dart_sdk} && \
    rm /tmp/dartsdk-linux-x64-release.zip ; \
  else \
    echo "Skipping Dart SDK installation" ; \
  fi

## Clean dependencies
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

## Install rbenv
ENV RBENV_ROOT "/root/.rbenv"
RUN git clone https://github.com/rbenv/rbenv.git $RBENV_ROOT
ENV PATH "$PATH:$RBENV_ROOT/bin"
ENV PATH "$PATH:$RBENV_ROOT/shims"

## Install jenv
ENV JENV_ROOT "$HOME/.jenv"
RUN git clone https://github.com/jenv/jenv.git $JENV_ROOT
ENV PATH "$PATH:$JENV_ROOT/bin"
RUN mkdir $JENV_ROOT/versions
ENV JDK_ROOT "/usr/lib/jvm/"
RUN jenv add ${JDK_ROOT}/java-8-openjdk-amd64
RUN jenv add ${JDK_ROOT}/java-11-openjdk-amd64
RUN jenv add ${JDK_ROOT}/java-17-openjdk-amd64
RUN echo 'export PATH="$JENV_ROOT/bin:$PATH"' >> ~/.bashrc
RUN echo 'eval "$(jenv init -)"' >> ~/.bashrc

# Install ruby-build (rbenv plugin)
RUN mkdir -p "$RBENV_ROOT"/plugins
RUN git clone https://github.com/rbenv/ruby-build.git "$RBENV_ROOT"/plugins/ruby-build

# Install ruby envs
RUN echo “install: --no-document” > ~/.gemrc
ENV RUBY_CONFIGURE_OPTS=--disable-install-doc
RUN rbenv install 3.1.1

# Setup default ruby env
RUN rbenv global 3.1.1
RUN gem install bundler:2.3.7

## Install Android SDK
ARG android_cmdtools=commandlinetools-linux-10406996_latest.zip
ARG android_home=/opt/android/sdk
ARG android_api=android-34
ARG android_build_tools=34.0.0
RUN mkdir -p ${android_home} && \
    wget --quiet --output-document=/tmp/${android_cmdtools} https://dl.google.com/android/repository/${android_cmdtools} && \
    unzip -q /tmp/${android_cmdtools} -d ${android_home} && \
    rm /tmp/${android_cmdtools}

## Set environment variables
ENV ANDROID_HOME ${android_home}
ENV PATH=${ANDROID_HOME}/emulator:${ANDROID_HOME}/cmdline-tools:${ANDROID_HOME}/cmdline-tools/bin:${ANDROID_HOME}/platform-tools:${PATH}
ENV PATH=${dart_sdk}/dart-sdk/bin:${PATH}
ENV PATH $PATH:~/.pub-cache/bin

## Setup Android SDK
RUN mkdir ~/.android && echo '### User Sources for Android SDK Manager' > ~/.android/repositories.cfg
RUN yes | sdkmanager --sdk_root=$ANDROID_HOME --licenses
RUN sdkmanager --sdk_root=$ANDROID_HOME --install \
  "platform-tools" \
  "build-tools;${android_build_tools}" \
  "platforms;${android_api}"

## Install FVM
RUN if [ $dart = true ] ; \
  then \
    dart pub global activate fvm ; \
  else \
    echo "Skipping FVM installation" ; \
  fi