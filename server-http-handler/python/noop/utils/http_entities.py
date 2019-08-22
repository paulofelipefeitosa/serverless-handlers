from enum import Enum

class RequestType(Enum):
	GET = 1
	POST = 2
	DELETE = 3
	PUT = 4

class Request(object):

	def __init__(self, request, type):
		self.request = request
		self.type = type

	def get_header(self, key):
		return self.request.headers

class Response(object):

	def __init__(self, request):
		self.request = request

	def add_header(self, key, value):
		self.request.send_header(key, value)