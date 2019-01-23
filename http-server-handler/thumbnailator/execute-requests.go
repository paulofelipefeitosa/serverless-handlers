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

	if err != nil {
		log.Fatal(err)
	}
	functionURL := fmt.Sprintf("http://%s%s", serverAddress, endpoint)

	upServerCmd := exec.Command("java", "-jar", "target/thumbnailator-server-maven-0.0.1-SNAPSHOT.jar")
	upServerCmd.Env = os.Environ()
	
	serverSTDOUT, err := upServerCmd.StdoutPipe()
	if err != nil {
		log.Fatal(err)
	}

	// Start Http Server
	startHTTPServerTS := time.Now().UTC().UnixNano()
	if err := upServerCmd.Start(); err != nil {
		log.Fatal(err)
	}
	millis2Nano := int64(1000000)
	HTTPServerReadyTS, err := getHTTPServerReadyTS(functionURL, serverSTDOUT)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Max tries reached")
		fmt.Fprintln(os.Stderr, err)
		killHTTPServer(upServerCmd.Process)
	}
	HTTPServerReadyTS *= millis2Nano

	// Ignore T6 line that the HTTP Handler writes
	fmt.Fprintln(os.Stderr, fmt.Sprintf("Ignoring: %d", ignoreEndServiceTs(serverSTDOUT)))

	// Apply requests
	roundTrip, serviceTime := getRoundTripAndServiceTime(nRequests, functionURL, serverSTDOUT)

	// Write results
	fmt.Printf("%s,%s,%d\n", "RuntimeReadyTime", executionID, HTTPServerReadyTS - startHTTPServerTS)
	for i := 0; i < len(roundTrip); i++ {
		fmt.Printf("%s,%d,%d\n", "RoundTripTime", i, roundTrip[i])
		fmt.Printf("%s,%d,%d\n", "ServiceTime", i, serviceTime[i])
	}

	fmt.Fprintln(os.Stderr, fmt.Sprintf("End of execution: %s", executionID))

	killHTTPServer(upServerCmd.Process)
}

func getRoundTripAndServiceTime(nRequests int64, functionURL string, serverSTDOUT io.ReadCloser) ([]int64, []int64) {
	var roundTrip, serviceTime []int64
	var startServiceTS, endServiceTS int64
	millis2Nano := int64(1000000)
	for i := int64(0); i < nRequests; i++ {
		response, err, sendRequestTS, receiveResponseTS := sendRequest2(functionURL)
		if response.StatusCode == http.StatusOK {
			fmt.Fscanf(serverSTDOUT, "T5: %d", &startServiceTS)
			fmt.Fscanf(serverSTDOUT, "T6: %d", &endServiceTS)
			
			roundTrip = append(roundTrip, receiveResponseTS - sendRequestTS)
			serviceTime = append(serviceTime, (endServiceTS - startServiceTS) * millis2Nano)
		} else {
			fmt.Fprint(os.Stderr, err)
		}
	}
	return roundTrip, serviceTime
}

func getHTTPServerReadyTS(functionURL string, serverSTDOUT io.ReadCloser) (int64, error) {
	maxFailsToStart := int64(20000)
	var failCount, HTTPServerReadyTS int64
	for {
		resp, err := http.Get(functionURL)
		if err == nil && resp.StatusCode == http.StatusOK {
			io.Copy(ioutil.Discard, resp.Body)
			resp.Body.Close()
			fmt.Fscanf(serverSTDOUT, "T4: %d", &HTTPServerReadyTS)
			return HTTPServerReadyTS, nil
		} else {
			time.Sleep(20 * time.Millisecond)
			failCount += 1
		}
		if failCount == maxFailsToStart {
			return int64(1)<<62, err
		}
	}
}

func sendRequest2(URL string) (*http.Response, error, int64, int64) {
	sendRequestTS := time.Now()
	response, err := http.Get(URL)
	receiveResponseTS := time.Now()
	if err == nil && response.Body != nil {
		defer response.Body.Close()
		_,_ = ioutil.ReadAll(response.Body)
	}
	return response, err, sendRequestTS.UTC().UnixNano(), receiveResponseTS.UTC().UnixNano()
}

func ignoreEndServiceTs(serverSTDOUT io.Reader) int64 {
	var endServiceTS int64
	fmt.Fscanf(serverSTDOUT, "T6: %d", &endServiceTS)
	return endServiceTS
}

func killHTTPServer(serverProcess *os.Process) {
	// Kill Http Server Process
	if err := serverProcess.Kill(); err != nil {
		log.Fatal("failed to kill process: ", err)
	}
}