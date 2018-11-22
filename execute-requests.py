import time, requests, sys

def get_replicas_number(json_response):
	return int(json_response['replicas'])

def ensure_scale_from_zero(protocol, gateway_address, function_name, reconciliation_time, max_tries):
	count = 0
	while True:
		req_url = protocol + gateway_address + '/system/function/' + function_name
		info_req = requests.get(req_url)
		
		if(int(info_req.status_code) < 300):
			n_replicas = get_replicas_number(info_req.json())
			
			if(n_replicas == 0):
				break
			elif(count > max_tries):
				message = 'Too much tries, please ensure the zero scale funcionality in OpenFaaS [gateway configuration, faas-idler configuration and function deployment configuration]'
				raise RuntimeError(message)
			else:
				count += 1
		else:
			message = 'Request to [' + req_url + '] status response [' + str(info_req.status_code) + ']'
			raise RuntimeError('Request error: ' + message)
		
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
	return [headers['X-Scale-Start-Time'], headers['X-Scale-Post-Send-Time'], headers['X-Scale-Post-Response-Time'], 
		response['Container-startup-time'], headers['X-Start-Time'], headers['X-Watchdog-Startup-Time'], 
		headers['X-Prepare-Fork-Time'], headers['X-Fork-Startup-Time'], response['JVMStartTime'], response['ReadyTime'], 
		response['ReadyToProcessTime'], headers['X-Fork-End-Time'], headers['X-Wait-Time'], headers['X-Duration-Seconds']]

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

	reconciliation_time = 10 # 10s
	max_tries = 15 # 2min30s

	protocol = 'http://'
	gateway_address = args[1]
	function_name = args[2]
	total_requests = int(args[3])

	csv_file = open(function_name + '-' + str(total_requests) + '-' + str(int(time.time())) + '.csv', 'w')
	csv_file.write('Req_Id,Arrival_Gateway,Send_Set_Replicas_Swarm,Response_Set_Replicas_Swarm,Container_Running,' +
		'Proxy_Handler_Gateway,Watchdog_Running,Receive_Request_Watchdog,Run_Function_Watchdog,JVM_Startup_Time,' + 
		'Running_Function,Processing_Function,Finish_Function_Watchdog,Wait_Run_Function_Watchdog,Function_Duration_Watchdog\n')

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