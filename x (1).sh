sudo apt update && sudo apt upgrade -y
sudo apt install -y wget unzip git openjdk-17-jdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
cd /workspaces
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:/workspaces/flutter/bin"
echo 'export PATH="$PATH:/workspaces/flutter/bin"' >> ~/.bashrc
mkdir -p android-sdk
cd android-sdk
wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
unzip -q commandlinetools-linux-9477386_latest.zip -d
export ANDROID_SDK_ROOT=/workspaces/android-sdk
export ANDROID_HOME=$ANDROID_SDK_ROOT
export PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"
echo "export ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT" >> ~/.bashrc
echo "export ANDROID_HOME=$ANDROID_SDK_ROOT" >> ~/.bashrc
echo 'export PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"' >> ~/.bashrc
source ~/.bashrc
yes | sdkmanager --licenses >/dev/null 2>&1
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
sdkmanager "platforms;android-33" "build-tools;33.0.2"
flutter precache
flutter doctor -v
cd Susanoo

FILE_ID=1CvhQRdjricf21GVwHKn4JRSoZGh1jmFY && \
wget --load-cookies /tmp/cookies.txt \
"https://docs.google.com/uc?export=download&id=$FILE_ID&confirm=$(wget --quiet \
--save-cookies /tmp/cookies.txt \
--keep-session-cookies \
--no-check-certificate \
"https://docs.google.com/uc?export=download&id=$FILE_ID" -O- \
| sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1/p')" \
-O nama.zip

unzip nama.zip
cd SusanooApps
flutter pub get
flutter build apk --release# ⬆⬆⬆ SELESAI MODIFIKASI
