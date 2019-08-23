from enum import Enum

class RequestType(Enum):
    GET = 1
    POST = 2
    DELETE = 3
    PUT = 4
    HEAD = 5

class Request(object):

    def __init__(self, request, type):
        self.type = type
        self.content_type = request.headers.get_content_type()
        self.headers = {}
        for key, value in request.headers.items():
            self.headers[key] = value

        if type == RequestType.POST or type == RequestType.PUT:
            body_encoding = request.headers.get_content_charset()
            if not body_encoding:
                body_encoding = "UTF-8"
            content_length = int(self.headers['Content-Length'])
            self.body = request.rfile.read(content_length).decode(body_encoding)

    def get_request_type(self):
        return self.type

    def get_header(self, key):
        value = None
        if key in self.headers:
            value = self.headers[key]
        return value

    def get_content_type(self):
        return self.content_type

    def get_body(self):
        return self.body


class Response(object):

    def __init__(self):
        self.status_code = 200
        self.content_type = ""
        self.headers = {}
        self.body = ""
        self.body_encoding = "UTF-8"

    def add_header(self, key, value):
        self.headers[key] = value

    def set_status_code(self, code):
        self.status_code = code

    def set_content_type(self, content_type):
        self.content_type = content_type

    def set_body(self, body, encoding="UTF-8"):
        self.body = body
        self.body_encoding = encoding

    def __close__(self, request):
        request.send_response(self.status_code)
        if self.content_type:
            request.send_header('Content-type', self.content_type)
        for key, value in self.headers.items():
            request.send_header(key, value)
        request.end_headers()
        request.wfile.write(self.body.encode(self.body_encoding))
