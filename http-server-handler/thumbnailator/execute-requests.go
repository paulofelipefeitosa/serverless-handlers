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
	httpServerReadyTS, err := getHTTPServerReadyTS(functionURL, serverSTDOUT)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Max tries reached")
		fmt.Fprintln(os.Stderr, err)
		
		// Kill Http server process
		if err := upServerCmd.Process.Kill(); err != nil {
			log.Fatal("failed to kill process: ", err)
		}
	}
	millis2Nano := int64(1e6)
	httpServerReadyTS *= millis2Nano

	// Ignore T6 line that the HTTP Handler writes
	fmt.Fprintln(os.Stderr, fmt.Sprintf("Ignoring: %d", ignoreEndServiceTs(serverSTDOUT)))

	// Apply requests
	roundTrip, serviceTime := getRoundTripAndServiceTime(nRequests, functionURL, serverSTDOUT)

	// Write results
	fmt.Printf("%s,%s,%d\n", "RuntimeReadyTime", executionID, httpServerReadyTS - startHTTPServerTS)
	for i := 0; i < len(roundTrip); i++ {
		fmt.Printf("%s,%d,%d\n", "RoundTripTime", i, roundTrip[i])
		fmt.Printf("%s,%d,%d\n", "ServiceTime", i, serviceTime[i])
	}

	fmt.Fprintln(os.Stderr, fmt.Sprintf("End of execution: %s", executionID))

	// Kill Http server process
	if err := upServerCmd.Process.Kill(); err != nil {
		log.Fatal("failed to kill process: ", err)
	}
}

func getRoundTripAndServiceTime(nRequests int64, functionURL string, serverSTDOUT io.ReadCloser) ([]int64, []int64) {
	var roundTrip, serviceTime []int64
	var startServiceTS, endServiceTS int64
	millis2Nano := int64(1e6)
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
	var failCount, httpServerReadyTS int64
	for {
		resp, err := http.Get(functionURL)
		if err == nil  {
			if resp.StatusCode == http.StatusOK {
				io.Copy(ioutil.Discard, resp.Body)
				resp.Body.Close()
				fmt.Fscanf(serverSTDOUT, "T4: %d", &httpServerReadyTS)
				return httpServerReadyTS, nil
			} else {
				return -1, fmt.Errorf("Server is up, but HTTP response is not OK!\nStatusCode: %d\n", resp.StatusCode)
			}
		} else {
			time.Sleep(5 * time.Millisecond)
			failCount += 1
			if failCount == maxFailsToStart {
				return -1, err
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

func ignoreEndServiceTs(serverSTDOUT io.Reader) int64 {
	var endServiceTS int64
	fmt.Fscanf(serverSTDOUT, "T6: %d", &endServiceTS)
	return endServiceTS
}
