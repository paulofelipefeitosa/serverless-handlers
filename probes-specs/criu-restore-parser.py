import sys
import re

def eprint(string):
    sys.stderr.write(string)

def print_metric(metric, exec_id, metric_value):
    print ("%s,%s,%s,%d" % (metric, exec_id, "0", metric_value))

def main():
	EXEC_ID = sys.argv[1]

	patterns = [("\(([0-9]+\.[0-9]+)\) Switching to 2 stage$", "ResolveSharedResourcesTime"), 
	("\(([0-9]+\.[0-9]+)\) Switching to 3 stage$", "ForkingTime"), 
	("\(([0-9]+\.[0-9]+)\) Switching to 4 stage$", "RestoreResourcesTime"), 
	("\(([0-9]+\.[0-9]+)\) Writing stats$", "SwitchRestoreContinueTime")]

	timestamps = [0]*len(patterns)

	for line in sys.stdin:
		for i in xrange(len(patterns)):
			(pattern, label) = patterns[i]
			m = re.search(pattern, line)
			if m:
				eprint("Match: " + pattern + " :: " + label + " :: " + line)
				timestamps[i] = float(m.group(1)) * (10**9) # Convert timestamp to nanoseconds

	final_timing = [0] + timestamps
	for i in xrange(len(final_timing) - 1):
		final_timing[i] = final_timing[i + 1] - final_timing[i]

	for i in xrange(len(patterns)):
		print_metric(patterns[i][1], EXEC_ID, final_timing[i])

main()