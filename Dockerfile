FROM openjdk:8-jdk

ENV ANDROID_HOME /opt/android-sdk-linux
ENV ANDROID_SDK_TOOLS_VERSION 4333796
RUN cd /opt \
    && wget -q https://dl.google.com/android/repository/sdk-tools-linux-$ANDROID_SDK_TOOLS_VERSION.zip -O android-sdk-tools.zip \
    && unzip -q android-sdk-tools.zip -d ${ANDROID_HOME} \
    && rm android-sdk-tools.zip
# RUN echo "deb http://deb.debian.org/debian stretch main contrib non-free" > /etc/apt/sources.list && \
#     echo "deb http://security.debian.org/debian-security stretch/updates main contrib non-free" >> /etc/apt/sources.list && \
#     echo "deb http://deb.debian.org/debian stretch-updates main contrib non-free" >> /etc/apt/sources.list
RUN apt-get update \
    && apt-get install -y software-properties-common git --no-install-recommends \
    && apt-get install -y --allow-unauthenticated --no-install-recommends lib32stdc++6 libstdc++6 libglu1-mesa locales \
    && apt-get install -y qemu-kvm libvirt-clients libvirt-daemon-system \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US "en_US.UTF-8" \
    && dpkg-reconfigure locales

ENV PATH ${PATH}:${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools
RUN yes | sdkmanager --licenses
RUN sdkmanager tools
RUN sdkmanager platform-tools
RUN sdkmanager emulator
RUN echo "Adding ekko user and group" \
    && useradd --system --uid 1000 --shell /bin/bash --create-home ekko \
    && chown --recursive ekko:ekko /home/ekko \
    && chown --recursive ekko:ekko ${ANDROID_HOME}
RUN adduser ekko libvirt && adduser ekko libvirt-qemu

ENV HOME /home/ekko
USER ekko
WORKDIR /home/ekko

ENV ANDROID_PLATFORM_VERSION 27
ENV ANDROID_BUILD_TOOLS_VERSION 27.0.3
RUN yes | sdkmanager \
    "platforms;android-$ANDROID_PLATFORM_VERSION" \
    "build-tools;$ANDROID_BUILD_TOOLS_VERSION"

ENV LANG en_US.UTF-8
ENV FLUTTER_HOME ${HOME}/sdks/flutter

RUN curl -O https://storage.googleapis.com/flutter_infra/releases/beta/linux/flutter_linux_v0.5.1-beta.tar.xz
RUN mkdir -p ${HOME}/sdks && \
    tar xf flutter_linux_v0.5.1-beta.tar.xz -C ${HOME}/sdks && \
    rm flutter_linux_v0.5.1-beta.tar.xz
# RUN git clone -b beta https://github.com/flutter/flutter.git ${FLUTTER_HOME}
ENV PATH ${PATH}:${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin
RUN flutter doctor

RUN sdkmanager "platform-tools" "platforms;android-27" "emulator"
RUN sdkmanager "system-images;android-27;default;x86"
RUN echo no | avdmanager create avd -n FlutterEmulator -k "system-images;android-27;default;x86" -d "Nexus 5"
# RUN echo no | avdmanager create avd -n emuTest -k "system-images;android-27;default;x86"
# RUN emulator -avd FlutterEmulator -no-window -no-audio

CMD emulator -avd FlutterEmulator -no-window -no-audio -no-boot-anim
