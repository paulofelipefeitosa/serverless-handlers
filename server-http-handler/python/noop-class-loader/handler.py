from utils.http_entities import Response
import sys, configparser

class Handler:

	def __init__(self):
		self.config = self.read_config()

	def read_config(self):
		try:
			app_config_path = sys.argv[-1]
			config = configparser.ConfigParser()
			config.read(app_config_path)
			section = config['DEFAULT']
			fn = "base_filepath"
			classes = "classes"
			return [section[fn], section[classes]]
		finally:
			f.close()

	def handle(self, request):
		base_filepath = self.config[0]
		classes = self.config[1]
		for i in range(1, classes + 1):
			import (base_filepath + str(i))
		return Response()