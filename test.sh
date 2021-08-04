rm -rf mjpeg_stream_webcam
git clone https://github.com/meska/mjpeg_stream_webcam.git
cd mjpeg_stream_webcam
virtualenv -p python3.7 .env
source .env/bin/activate
python3 -m pip install -r requirements.txt

tccutil reset Camera && python3 mjpegsw.py --camera 0 --port 5000 --ipaddress 0.0.0.0

