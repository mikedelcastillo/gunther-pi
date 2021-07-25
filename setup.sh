clear && echo "Checking permissions"
is_user_root () { [ "${EUID:-$(id -u)}" -eq 0 ]; }
if is_user_root; then
    echo "Running as root"
else
    echo "You must run this script as root"
    exit 1
fi

clear && echo "Updating system"
apt-get update  -y --fix-missing
apt-get upgrade -y
apt-get autoremove -y

clear && echo "Install linux dependencies"
apt-get install -y git --fix-missing

clear && echo "Install node"
curl -L https://raw.githubusercontent.com/tj/n/master/bin/n -o n
bash n lts
rm n

clear && echo "Install node dependencies"
npm install -g pm2
npm install

clear && echo "Setting up RPI camera"
raspi-config nonint do_camera 0 # Enable the RPI camera
RULE_FILE="/etc/udev/rules.d/100-camera.rules"
rm -rf $RULE_FILE
touch $RULE_FILE
tee -a $RULE_FILE > /dev/null <<EOT
KERNEL=="video*", SUBSYSTEMS=="video4linux", ATTR{name}=="camera0", SYMLINK+="octocam0"
KERNEL=="video*", SUBSYSTEMS=="video4linux", ATTR{name}=="GENERAL WEBCAM: GENERAL WEBCAM", ATTR{index}=="0", SYMLINK+="octocam1"
KERNEL=="video*", SUBSYSTEMS=="video4linux", ATTR{name}=="GENERAL WEBCAM: GENERAL WEBCAM", ATTR{index}=="0", SYMLINK+="octocam2"
EOT

clear && echo "Setting up mjpeg-streamer"
apt-get install -y cmake libjpeg8-dev gcc g++
rm -rf mjpg-streamer
git clone https://github.com/jacksonliam/mjpg-streamer.git
cd ./mjpg-streamer/mjpg-streamer-experimental/
make
make install
cd ../../

clear && echo "Install octoprint"
apt-get install -y python3 python3-pip --fix-missing
pip3 install octoprint

clear && echo "Setting up pm2"
pm2 del all

SLEEP_RETRY=300
pm2 start "npm run camera-1 && sleep $SLEEP_RETRY" --name "camera-1"
pm2 start "npm run camera-2 && sleep $SLEEP_RETRY" --name "camera-2"
pm2 start "npm run camera-3 && sleep $SLEEP_RETRY" --name "camera-3"

for i in `seq 0 2`;
do 
    let "PORT=5000+$i"
    CMD="npm run mjpg-streamer -- -i 'input_uvc.so -d /dev/octocam$i -r 1920x1080 -q 24' -o 'output_http.so -w ./www -p $PORT'"
    pm2 start "$CMD" --name "camera-$i"
done 

for i in `seq 0 2`;
do 
    let "PORT=8000+$i"
    CMD="octoprint serve --port $PORT --basedir ~/.octoprint-$i --iknowwhatimdoing"
    pm2 start "$CMD" --name "octoprint-$i"
done 

pm2 startup
pm2 save
pm2 status