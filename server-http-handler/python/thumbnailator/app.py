import time

def get_monotonic_clock():
    return int(time.monotonic() * 1e9)

print('EIM: %d' % get_monotonic_clock())

from flask import Flask, request
from gevent.pywsgi import WSGIServer
import handler
 
app = Flask(__name__)
 
@app.route("/", methods=["POST", "GET"])
def main_route():
    warm_req = request.headers.get("X-Warm-Request", None) == 'true'
    if not warm_req:
        print('T4: %d' % get_monotonic_clock())
    
    ret = handler.handle(request)
    
    if not warm_req:
        print('T6: %d' % get_monotonic_clock())
    
    return ret.body
 
if __name__ == '__main__':
    http_server = WSGIServer(('', 9000), app)
    print('EFM: %d' % get_monotonic_clock())
    http_server.serve_forever()
