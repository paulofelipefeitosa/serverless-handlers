package main
import(
	"os"
	"os/exec"
	"log"
	"time"
	"net/http"
	"strconv"
	"fmt"
	"io"
	"io/ioutil"
)

func main() {
	serverAddress := os.Args[1]
	endpoint := os.Args[2]
	nRequests, err := strconv.ParseInt(os.Args[3], 10, 64)
	executionID := os.Args[4]
	jarPath := os.Args[5]
	handlerType := os.Args[6]
	serverLogFile := os.Args[7] 

	if err != nil {
		log.Fatal(err)
	}
	functionURL := fmt.Sprintf("http://%s%s", serverAddress, endpoint)

    var upServerCmd* exec.Cmd
    var serverSTDOUT io.ReadCloser
	if handlerType == "criu" {
		fmt.Fprintln(os.Stderr, "Criu Handler")
		upServerCmd = exec.Command("criu", "restore", "-d", "-vvvv", "-o", "restore.log")
		upServerCmd.Env = os.Environ()
		
		currentDir, _ := os.Getwd()
		upServerCmd.Dir = fmt.Sprintf("%s/%s", currentDir, jarPath)

		fmt.Fprintf(os.Stderr, "Dir [%s]\n", upServerCmd.Dir)

		serverSTDOUT, err = os.Open(serverLogFile)
	} else {
		upServerCmd = exec.Command("java", "-jar", jarPath)
		upServerCmd.Env = os.Environ()
		serverSTDOUT, err = upServerCmd.StdoutPipe()
	}

	if err != nil {
		log.Fatal(err)
	}

	// Start Http Server
	fmt.Fprintln(os.Stderr, "To Run")
	startHTTPServerTS := time.Now().UTC().UnixNano()
	if err := upServerCmd.Start(); err != nil {
		log.Fatal(err)
	}
	fmt.Fprintln(os.Stderr, "Running")
	httpServerReadyTS, httpServerServiceTS, err := getHTTPServerReadyAndServiceTS(functionURL, serverSTDOUT)
	fmt.Fprintf(os.Stderr, "%d :: %d\n", httpServerReadyTS, httpServerServiceTS)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Max tries reached")
		
		// Kill Http server process
		if err := upServerCmd.Process.Kill(); err != nil {
			log.Fatal("failed to kill process: ", err)
		}
		log.Fatal(err)
	}
	fmt.Fprintln(os.Stderr, "Get first")
	millis2Nano := int64(1e6)
	httpServerReadyTS *= millis2Nano
	httpServerServiceTS *= millis2Nano

	// Apply requests
	roundTrip, serviceTime := getRoundTripAndServiceTime(nRequests, functionURL, serverSTDOUT)
    fmt.Fprintln(os.Stderr, "Getting all")
	// Write results
	fmt.Printf("%s,%s,%d,%d\n", "RuntimeReadyTime", executionID, 0, httpServerReadyTS - startHTTPServerTS)
	fmt.Printf("%s,%s,%d,%d\n", "ServiceTime", executionID, 0, httpServerServiceTS - startHTTPServerTS)
	for i := 1; i <= len(roundTrip); i++ {
		fmt.Printf("%s,%s,%d,%d\n", "RoundTripTime", executionID, i, roundTrip[i - 1])
		fmt.Printf("%s,%s,%d,%d\n", "ServiceTime", executionID, i, serviceTime[i - 1])
	}

	fmt.Fprintln(os.Stderr, fmt.Sprintf("End of execution: %s", executionID))

	serverSTDOUT.Close()

	// Kill Http server process
	if err := upServerCmd.Process.Kill(); err != nil {
		log.Fatal("failed to kill process: ", err)
	}
	upServerCmd.Process.Wait()
}

func getRoundTripAndServiceTime(nRequests int64, functionURL string, serverSTDOUT io.ReadCloser) ([]int64, []int64) {
	var roundTrip, serviceTime []int64
	var startServiceTS, endServiceTS int64
	millis2Nano := int64(1e6)
	for i := int64(1); i < nRequests; i++ {
		response, err, sendRequestTS, receiveResponseTS := sendRequest2(functionURL)
		if err == nil && response.StatusCode == http.StatusOK {
		    fmt.Fprintln(os.Stderr, "Try to read")
			fmt.Fscanf(serverSTDOUT, "T4: %d", &startServiceTS)
			fmt.Fprintln(os.Stderr, "read 1")
			fmt.Fscanf(serverSTDOUT, "T6: %d", &endServiceTS)
			fmt.Fprintln(os.Stderr, "read 2")
			
			roundTrip = append(roundTrip, receiveResponseTS - sendRequestTS)
			serviceTime = append(serviceTime, (endServiceTS - startServiceTS) * millis2Nano)
		} else {
			log.Fatal(err)
		}
	}
	return roundTrip, serviceTime
}

func getHTTPServerReadyAndServiceTS(functionURL string, serverSTDOUT io.ReadCloser) (int64, int64, error) {
	maxFailsToStart := int64(20000)
	var failCount, httpServerReadyTS, endServiceTS int64
	for {
		resp, err := http.Get(functionURL)
		if err == nil  {
			if resp.StatusCode == http.StatusOK {
				io.Copy(ioutil.Discard, resp.Body)
				resp.Body.Close()
				fmt.Fprintln(os.Stderr, "Try to read")
				fmt.Fscanf(serverSTDOUT, "T4: %d", &httpServerReadyTS)
				fmt.Fprintln(os.Stderr, "read 1")
				fmt.Fscanf(serverSTDOUT, "T6: %d", &endServiceTS)
				fmt.Fprintln(os.Stderr, "read 2")
				return httpServerReadyTS, endServiceTS, nil
			} else {
				return -1, -1, fmt.Errorf("Server is up, but HTTP response is not OK!\nStatusCode: %d\n", resp.StatusCode)
			}
		} else {
			time.Sleep(5 * time.Millisecond)
			failCount += 1
			if failCount == maxFailsToStart {
				return -1, -1, err
			}
		}
	}
}

func sendRequest2(URL string) (*http.Response, error, int64, int64) {
	sendRequestTS := time.Now()
	response, err := http.Get(URL)
	receiveResponseTS := time.Now()
	if err == nil && response.Body != nil {
		io.Copy(ioutil.Discard, response.Body)
		response.Body.Close()
	}
	return response, err, sendRequestTS.UTC().UnixNano(), receiveResponseTS.UTC().UnixNano()
}
