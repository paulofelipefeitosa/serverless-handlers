from http.server import BaseHTTPRequestHandler, HTTPServer
from utils.http_entities import Request, RequestType
import handler
import time

def get_monotonic_clock():
    return int(time.monotonic() * 1e9)

class RequestHandler(BaseHTTPRequestHandler):

    def handle_request(self, req_type):
        print('T4: %d' % get_monotonic_clock())
        handler.handle(Request(self, req_type))
        print('T6: %d' % get_monotonic_clock())

    def do_GET(self):
        self.handle_request(RequestType.GET)
    def do_POST(self):
        self.handle_request(RequestType.POST)

def run():
    server_address = ('127.0.0.1', 9000)
    httpd = HTTPServer(server_address, RequestHandler)
    try:
        print('EFM: %d' % get_monotonic_clock())
        httpd.serve_forever()
    except KeyboardInterrupt:
        httpd.socket.close()

if __name__ == '__main__':
    print('EIM: %d' % get_monotonic_clock())
    run()