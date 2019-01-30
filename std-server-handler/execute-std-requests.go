package main

import(
	"os"
	"os/exec"
	"log"
	"time"
	"strconv"
	"fmt"
	"io"
	"io/ioutil"
)

func main() {
	nRequests, err := strconv.ParseInt(os.Args[1], 10, 64)
	jarPath := os.Args[2]
	executionID := os.Args[3]

	if err != nil {
		log.Fatal(err)
	}

	for i := int64(0); i < nRequests; i++ {
		upServerCmd := exec.Command("java", "-jar", jarPath)
		upServerCmd.Env = os.Environ()
		
		stderrPipe, stdinPipe, stdoutPipe, err := getPipes(upServerCmd)
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

		io.Copy(ioutil.Discard, stdoutPipe)
		stderrPipe.Close()
		stdinPipe.Close()
		stdoutPipe.Close()
		
		upServerCmd.Process.Wait()

		fmt.Printf("%s,%s,%d\n", "RuntimeReadyTime", executionID, startHandlerServiceTS - startHandlerTS)
		fmt.Printf("%s,%s,%d\n", "ServiceTime", executionID, endHandlerServiceTS - startHandlerServiceTS)

		time.Sleep(5 * time.Millisecond)
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
