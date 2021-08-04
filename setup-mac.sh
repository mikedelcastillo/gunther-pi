brew install ffmpeg
ffserver -f ffserver.cfg
ffmpeg -r 30 -f avfoundation -video_size 1920x1080 -framerate 30 -i "default:none" -c copy http://localhost:8000/webcam.ffm

sudo python3 -m pip install octoprint
curl -L https://raw.githubusercontent.com/tj/n/master/bin/n -o n
sudo bash n lts

sudo npm install -g pm2 nodemon

pm2 unstartup
pm2 del all

for i in `seq 0 2`;
do 
    let "PORT=8000+$i"
    CMD="npm run octoprint -- serve --port $PORT --basedir ./.octoprint-$i --iknowwhatimdoing"
    echo $CMD
    pm2 start "$CMD" --name "octoprint-$i"
done 

pm2 startup
pm2 save
pm2 status

