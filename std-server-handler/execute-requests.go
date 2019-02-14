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
	handlerType := os.Args[4]

	if err != nil {
		log.Fatal(err)
	}

	for i := int64(0); i < nRequests; i++ {
		if handlerType != "persistent" || i == 0 {
			upServerCmd := commandSetup(jarPath)
			
			stderrPipe, stdinPipe, stdoutPipe, err := getPipes(upServerCmd)
			if err != nil {
				log.Fatal(err)
			}

			startHandlerTS, err := startService(upServerCmd)
			if err != nil {
				log.Fatal(err)
			}
		}

		// escrever no stdin
		var startHandlerServiceTS, endHandlerServiceTS int64
		fmt.Fscanf(stderrPipe, "T5: %d", &startHandlerServiceTS)
		fmt.Fscanf(stderrPipe, "T6: %d", &endHandlerServiceTS)
		endHandlerTS := time.Now().UTC().UnixNano()
		
		startHandlerServiceTS *= 1e6
		endHandlerServiceTS *= 1e6

		if handlerType != "persistent" {
			closePipes(stderrPipe, stdinPipe, stdoutPipe)
			upServerCmd.Process.Wait()
		} else if i == (nRequests - 1) {
			closePipes(stderrPipe, stdinPipe, stdoutPipe)
			if err := upServerCmd.Process.Kill(); err != nil {
				log.Fatal(err)
			}
			upServerCmd.Process.Wait()
		}

		fmt.Printf("%s,%s,%d,%d\n", "RuntimeReadyTime", executionID, i, startHandlerServiceTS - startHandlerTS)
		fmt.Printf("%s,%s,%d,%d\n", "ServiceTime", executionID, i, endHandlerServiceTS - startHandlerServiceTS)
		fmt.Printf("%s,%s,%d,%d\n", "RoundTripTime", executionID, i, endHandlerTS - startHandlerTS)

		time.Sleep(5 * time.Millisecond)
	}

}

func commandSetup(string jarPath) (Cmd) {
	cmd := exec.Command("java", "-jar", jarPath)
	cmd.Env := os.Environ()
	return cmd
}

func startService(serviceCmd Cmd) (int64, error) {
	startServiceTS := time.Now().UTC().UnixNano()
	return startServiceTS, serviceCmd.Start()
}

func closePipes(stderr io.ReadCloser, stdin io.WriteCloser, stdout io.ReadCloser) {
	io.Copy(ioutil.Discard, stdoutPipe)
	io.Copy(ioutil.Discard, stderrPipe)
	stderrPipe.Close()
	stdinPipe.Close()
	stdoutPipe.Close()
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
