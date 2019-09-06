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
        self.body += body
        self.body_encoding = encoding

    def __close__(self, request):
        request.send_response(self.status_code)
        if self.content_type:
            request.send_header('Content-type', self.content_type)
        for key, value in self.headers.items():
            request.send_header(key, value)
        request.end_headers()
        request.wfile.write(self.body.encode(self.body_encoding))
