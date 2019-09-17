from utils.http_entities import Response
import sys

class Handler:

	def __init__(self):
		self.config = self.read_config()

	def read_config(self):
		try:
			app_config_path = sys.argv[-1]
			f = open(app_config_path, 'r')
			fn_ptt = "base_filename="
			n_classes = "classes="
			for line in f:
				fn_ptt_arr = line.split(fn_ptt)
				n_classes_arr = line.split(n_classes)
				if len(fn_ptt_arr) > 1:
					filename = fn_ptt_arr[1]
				if len(n_classes_arr) > 1:
					classes = n_classes_arr[1]
			return (filename, classes)
		finally:
			f.close()

	def handle(self, request):
		return Response()