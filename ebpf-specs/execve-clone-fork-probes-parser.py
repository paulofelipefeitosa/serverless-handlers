import sys
import re

def get_list(line):
    str_list = line.split("]")[0].split("[")[1].split(", ")
    llist = map(lambda x: int(x), str_list)
    return llist

def eprint(string):
    sys.stderr.write(string + "\n")

def main():
    EXEC_ID = sys.argv[1]
    for line in sys.stdin:
        x = re.search(" execve: ./execute-requests$", line)
        if x:
            llist = get_list(line)
            execve_req_pid = llist[0]
            execve_req_tid = llist[1]
            break

    eprint("execve req PID: " + str(execve_req_pid)) 
    eprint("execve req TID: " + str(execve_req_tid))
    clone_list = []
    execve_list = []
    for line in sys.stdin:
        x = re.search(" clone$", line)
        y = re.search(" execve: .*/java$", line)
        if x:
            llist = get_list(line)
            if llist[0] == execve_req_pid and llist[1] == execve_req_tid:
                clone_list = llist
        elif y:
            execve_list = get_list(line)
            eprint("Found clone list: " + str(clone_list) )
            eprint("Found execve java list: " + str(execve_list))
            break
        else:
            eprint("Ops?? Not clone or execve, please check the file")

    if not (execve_list == []):
        print "CloneEntry," + EXEC_ID + ",0," + str(clone_list[2])
        print "CloneExit," + EXEC_ID + ",0," + str(clone_list[3])
        print "ExecveEntry," + EXEC_ID + ",0," + str(execve_list[2])
        print "ExecveExit," + EXEC_ID + ",0," + str(execve_list[3])
    else:
        eprint("Could not identify execve to java bin")

main()