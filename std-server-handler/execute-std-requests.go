package main

import(
	"os"
	"os/exec"
	"log"
	"time"
	"strconv"
	"fmt"
	"io"
)

func main() {
	nRequests, err := strconv.ParseInt(os.Args[1], 10, 64)
	jarPath := os.Args[2]

	if err != nil {
		log.Fatal(err)
	}

	for i := int64(0); i < nRequests; i++ {
		upServerCmd := exec.Command("java", "-jar", jarPath)
		upServerCmd.Env = os.Environ()
		
		stderrPipe, _, _, err := getPipes(upServerCmd)
		if err != nil {
			log.Fatal(err)
		}

		startHandlerTS := time.Now().UTC().UnixNano()
		if err := upServerCmd.Start(); err != nil {
			log.Fatal(err)
		}
		// escrever no stdin
		var startHandlerServiceTS, endHandlerServiceTS int64
		fmt.Fscanf(stderrPipe, "T5: %d", &startHandlerServiceTS)
		fmt.Fscanf(stderrPipe, "T6: %d", &endHandlerServiceTS)
		startHandlerServiceTS *= 1e6
		endHandlerServiceTS *= 1e6
		
		fmt.Printf("%s,%d,%d\n", "RuntimeReadyTime", i, startHandlerServiceTS - startHandlerTS)
		fmt.Printf("%s,%d,%d\n", "ServiceTime", i, endHandlerServiceTS - startHandlerServiceTS)
	}

}

func getPipes(command* exec.Cmd) (io.ReadCloser, io.WriteCloser, io.ReadCloser, error) {
	stderrPipe, err := command.StderrPipe()
	if err != nil {
		return stderrPipe, nil, nil, err 
	}
	stdinPipe, err := command.StdinPipe()
	if err != nil {
		return stderrPipe, stdinPipe, nil, err 
	}
	stdoutPipe, err := command.StdoutPipe()
	if err != nil {
		return stderrPipe, stdinPipe, stdoutPipe, err 
	}
	return stderrPipe, stdinPipe, stdoutPipe, nil
}