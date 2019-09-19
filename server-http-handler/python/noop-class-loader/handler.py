from utils.http_entities import Response
import sys, configparser, importlib, time

def get_monotonic_clock():
    return int(time.monotonic() * 1e9)

class Handler:

	def __init__(self):
		self.config = self.read_config()

	def read_config(self):
		app_config_path = sys.argv[-1]
		config = configparser.ConfigParser()
		config.read(app_config_path)
		section = config['DEFAULT']
		mp = "module_path"
		cn = "classname"
		classes = "classes"
		return [section[mp], section[classes], section[cn]]

	def handle(self, request):
		start = get_monotonic_clock()
		
		module_path = self.config[0]
		classes = self.config[1]
		classname = self.config[2]

		lc_time = 0
		inst_time = 0
		counter = 0
		
		for i in range(1, int(classes) + 1):
			start_load = get_monotonic_clock()
			new_module = importlib.import_module(module_path + str(i))
			
			end_load = get_monotonic_clock()
			
			getattr(new_module, classname)() # instantiate class
			end_inst = get_monotonic_clock()
			
			lc_time += end_load - start_load
			inst_time += end_inst - end_load
			counter += 1
		
		end = get_monotonic_clock()
		total_time = end - start
		print('LCTime: ' + str(lc_time) + '\n' + 
			'ICTime: ' + str(inst_time) + '\n' +
			'LC: ' + str(counter) + '\n' +
			'TLTime: ' + str(total_time))
		return Response()