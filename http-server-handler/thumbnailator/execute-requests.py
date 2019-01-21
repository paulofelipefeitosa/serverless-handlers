import time, requests, sys

def get_replicas_number(json_response):
	return int(json_response['replicas'])

def ensure_scale_from_zero(protocol, gateway_address, function_name, reconciliation_time, max_tries):
	time.sleep(reconciliation_time)

def function_request(protocol, gateway_address, function_name):
	req_url = protocol + gateway_address + '/function/' + function_name
	response = requests.post(req_url, data={})

	if(int(response.status_code) < 300):
		return (response.headers, response.json())
	else:
		message = 'Request to [' + req_url + '] status response [' + str(response.status_code) + ']'
		raise RuntimeError('Request error: ' + message)

def get_ordered_timestamps(headers, response):
	return [headers['X-Run-Handler-Task-Timestamp'], headers['X-JVM-Startup-Timestamp'], headers['X-Ready-Timestamp']]

def normalize_data(timestamps):
	max_size = 0
	for i in xrange(len(timestamps)):
		timestamps[i] = str(timestamps[i])
		length = len(timestamps[i])
		if(length > max_size):
			max_size = length

	for i in xrange(len(timestamps)):
		timestamps[i] = timestamps[i] + ('0' * (max_size - len(timestamps[i])))

	return timestamps

def main():
	args = sys.argv

	reconciliation_time = 1 # 10s
	max_tries = 1 # 2min30s

	protocol = 'http://'
	gateway_address = args[1]
	total_requests = int(args[2])

	function_name = ''

	csv_file = open(function_name + '-' + str(total_requests) + '-' + str(int(time.time())) + '.csv', 'w')
	csv_file.write('Req_Id,Run_Handler_Task,JVM_Startup,Runtime_Startup\n')

	for req_id in xrange(total_requests):
		print req_id
		try:
			ensure_scale_from_zero(protocol, gateway_address, function_name, reconciliation_time, max_tries)
			(headers, response) = function_request(protocol, gateway_address, function_name)
			timestamps = get_ordered_timestamps(headers, response['timestamps'])
			timestamps = normalize_data(timestamps)
			ts_str = str(req_id) + ',' + ",".join(timestamps) + '\n'
			csv_file.write(ts_str)
			print ts_str
		except Exception as e:
			print repr(e)
			continue

	csv_file.close()

main()