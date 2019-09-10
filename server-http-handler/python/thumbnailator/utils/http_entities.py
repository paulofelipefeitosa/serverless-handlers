from flask import make_response

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

    def set_body_encoding(self, encoding="UTF-8"):
        self.body_encoding = encoding

    def set_body(self, body):
        self.body += body
        
    def __close__(self):
        resp = make_response(self.body.encode(self.body_encoding), self.status_code)
        
        if self.content_type:
            resp.headers['Content-type'] = self.content_type
        
        for key, value in self.headers.items():
            resp.headers[key] = value

        return resp