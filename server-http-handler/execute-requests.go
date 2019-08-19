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
	"strings"
	_ "unsafe" // For go:linkname
)

//go:noescape
//go:linkname nanotime runtime.nanotime
func nanotime() int64 

// Get monotonic clock time to be compatible with the bpftrace timestamps
func Now() int64 {
	return int64(nanotime())
}

func startCRIUServer(appDir string, serverLogFile string) (*exec.Cmd, io.ReadCloser, error) {
	fmt.Fprintln(os.Stderr, "Criu Handler Type")
	upServerCmd := exec.Command("criu", "restore", "-d", "-v3", "-o", "restore.log")
	upServerCmd.Env = os.Environ()
	
	currentDir, _ := os.Getwd()
	upServerCmd.Dir = fmt.Sprintf("%s/%s", currentDir, appDir)
	fmt.Fprintf(os.Stderr, "Dir [%s]\n", upServerCmd.Dir)
	
	serverStdout, err := os.Open(serverLogFile)
	return upServerCmd, serverStdout, err
}

func startDefaultServer(runtime string, appDir string, args string) (*exec.Cmd, io.ReadCloser, io.ReadCloser, error) {
	fmt.Fprintln(os.Stderr, "Default Handler Type")
	var upServerCmd *exec.Cmd
	if runtime == "java" {
		upServerCmd = exec.Command("java", "-jar", fmt.Sprintf("%s/target/app-0.0.1-SNAPSHOT.jar", appDir), args)
	} else if runtime == "nodejs" {
		upServerCmd = exec.Command("node", fmt.Sprintf("%s/app.js", appDir), args)
	}
	upServerCmd.Env = os.Environ()
	
	serverStdout, err := upServerCmd.StdoutPipe()
	if err != nil {
		log.Fatal(err)
	}
	serverStderr, err := upServerCmd.StderrPipe()
	return upServerCmd, serverStdout, serverStderr, err
}

func checkIfFileExists(filePath string) {
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		fmt.Fprintln(os.Stderr, "File [%s] does not exists", filePath)
		log.Fatal(err)
	}
}

func checkEmpty(key string, value string) {
	if strings.Trim(key, "") == "" {
		fmt.Fprintln(os.Stderr, "%s argument is empty", value)
		os.Exit(1) // bad args
	}
}

func main() {
	serverAddress := os.Args[1]
	endpoint := os.Args[2]
	nRequests, err := strconv.ParseInt(os.Args[3], 10, 64)
	executionID := os.Args[4]
	runtime := os.Args[5]
	appDir := os.Args[6]
	handlerType := os.Args[7]
	
	var optPath string
	var classLoadStats bool
	if len(os.Args) > 8 {
		optPath = os.Args[8] // Synthetic Function JAR File Path or Server Log File
		classLoadStats = (handlerType != "criu") && (optPath != "")
	} else {
		optPath = ""
		classLoadStats = false
	}

	if err != nil {
		fmt.Fprintln(os.Stderr, "Amount of Requests is not an integer, given value %s", os.Args[3])
		log.Fatal(err)
	}
	checkEmpty(serverAddress, "serverAddress")
	checkEmpty(endpoint, "endpoint")
	checkEmpty(executionID, "executionID")
	checkEmpty(handlerType, "handlerType")
	if classLoadStats || (handlerType == "criu") {
		checkIfFileExists(optPath)
	}

	functionURL := fmt.Sprintf("http://%s%s", serverAddress, endpoint)

	var upServerCmd* exec.Cmd
	var serverStdout, serverStderr io.ReadCloser
	if handlerType == "criu" {
		upServerCmd, serverStdout, err = startCRIUServer(appDir, optPath)
	} else {
		upServerCmd, serverStdout, serverStderr, err = startDefaultServer(runtime, appDir, optPath)
	}

	if err != nil {
		log.Fatal(err)
	}

	startHTTPServerNanoTS := Now()
	if err := upServerCmd.Start(); err != nil {
		log.Fatal(err)
	}
	
	reqStatsNS, err := getHTTPServerReadyAndServiceTS(functionURL, serverStdout, classLoadStats)
	fmt.Fprintln(os.Stderr, "Got Ready Time")

	if err != nil {
		fmt.Fprintln(os.Stderr, "Max tries reached")

		if serverStderr != nil {
			fmt.Fprintln(os.Stderr, fmt.Sprint("Application Stderr == \n"))
			if _, err := io.Copy(os.Stderr, serverStderr); err != nil {
				log.Fatal(err)
			}
			fmt.Fprintln(os.Stderr, fmt.Sprint("Application Stderr // \n"))
			serverStderr.Close()
		}
		serverStdout.Close()
		
		// Kill Http server process
		if err := upServerCmd.Process.Kill(); err != nil {
			log.Fatal("failed to kill process: ", err)
		}
		log.Fatal(err)
	}

	fmt.Fprintf(os.Stderr, "Values for Ready Time [%d, %d]\n", reqStatsNS[2], reqStatsNS[3])

	// Apply requests
	fmt.Fprintln(os.Stderr, "Applying requests")
	roundTripTime, serviceTime := getRoundTripAndServiceTime(nRequests, functionURL, serverStdout)

	// Write results
	fmt.Fprintln(os.Stderr, "Writing results")
	fmt.Printf("%s,%s,%d,%d\n", "MainEntry", executionID, 0, reqStatsNS[0])
	fmt.Printf("%s,%s,%d,%d\n", "MainExit", executionID, 0, reqStatsNS[1])
	fmt.Printf("%s,%s,%d,%d\n", "Ready2Serve", executionID, 0, reqStatsNS[2])
	fmt.Printf("%s,%s,%d,%d\n", "RuntimeReadyTime", executionID, 0, reqStatsNS[2] - startHTTPServerNanoTS)
	fmt.Printf("%s,%s,%d,%d\n", "ServiceTime", executionID, 0, reqStatsNS[3] - reqStatsNS[2])
	fmt.Printf("%s,%s,%d,%d\n", "LatencyTime", executionID, 0, reqStatsNS[3] - startHTTPServerNanoTS)
	if classLoadStats {
		fmt.Printf("%s,%s,%d,%d\n", "LoadedClasses", executionID, 0, reqStatsNS[6])
		fmt.Printf("%s,%s,%d,%d\n", "FindingClassesTime", executionID, 0, reqStatsNS[4])
		fmt.Printf("%s,%s,%d,%d\n", "CompilingClassesTime", executionID, 0, reqStatsNS[5])
		fmt.Printf("%s,%s,%d,%d\n", "LoadClassesTotalTime", executionID, 0, reqStatsNS[7])
		fmt.Printf("%s,%s,%d,%d\n", "LoadingClassesOverheadTime", executionID, 0, reqStatsNS[7] - reqStatsNS[4] - reqStatsNS[5])
	}
	for i := 1; i <= len(roundTripTime); i++ {
		fmt.Printf("%s,%s,%d,%d\n", "LatencyTime", executionID, i, roundTripTime[i - 1])
		fmt.Printf("%s,%s,%d,%d\n", "ServiceTime", executionID, i, serviceTime[i - 1])
	}

	if serverStderr != nil {
		serverStderr.Close()
	}
	serverStdout.Close()

	fmt.Fprintln(os.Stderr, fmt.Sprintf("Killing Process: %d\n", upServerCmd.Process.Pid))
	// Kill Http server process
	if err := upServerCmd.Process.Kill(); err != nil {
		log.Fatal("failed to kill process: ", err)
	}
	fmt.Fprintln(os.Stderr, fmt.Sprintf("Waiting...\n"))
	upServerCmd.Process.Wait()

	fmt.Fprintln(os.Stderr, fmt.Sprintf("End of execution: %s\n", executionID))

	os.Exit(0)
}

func getRoundTripAndServiceTime(nRequests int64, functionURL string, serverStdout io.ReadCloser) ([]int64, []int64) {
	var roundTripTime, serviceTime []int64
	for i := int64(1); i < nRequests; i++ {
		response, err, sendRequestNanoTS, receiveResponseNanoTS := sendRequest2(functionURL)
		if err == nil && response.StatusCode == http.StatusOK {
			var startServiceNanoTS, endServiceNanoTS int64
			fmt.Fscanf(serverStdout, "T4: %d", &startServiceNanoTS)
			fmt.Fscanf(serverStdout, "T6: %d", &endServiceNanoTS)
			
			roundTripTime = append(roundTripTime, receiveResponseNanoTS - sendRequestNanoTS)
			serviceTime = append(serviceTime, endServiceNanoTS - startServiceNanoTS)
		} else {
			log.Fatal(err)
		}
	}
	return roundTripTime, serviceTime
}

func getHTTPServerReadyAndServiceTS(functionURL string, serverStdout io.ReadCloser, clStats bool) ([]int64, error) {
	maxFailsToStart := int64(2000)
	var failCount int64
	reqStatsNS := make([]int64, 8)
	for {
		resp, err := http.Get(functionURL)
		if err == nil  {
			if resp.StatusCode == http.StatusOK {
				io.Copy(ioutil.Discard, resp.Body)
				resp.Body.Close()
				fmt.Fscanf(serverStdout, "EIM: %d", &reqStatsNS[0])
				fmt.Fscanf(serverStdout, "EFM: %d", &reqStatsNS[1])
				fmt.Fscanf(serverStdout, "T4: %d", &reqStatsNS[2])
				fmt.Fscanf(serverStdout, "T6: %d", &reqStatsNS[3])
				if clStats {
					fmt.Fscanf(serverStdout, "LCTime: %d", &reqStatsNS[4])
					fmt.Fscanf(serverStdout, "ICTime: %d", &reqStatsNS[5])
					fmt.Fscanf(serverStdout, "LC: %d", &reqStatsNS[6])
					fmt.Fscanf(serverStdout, "TLTime: %d", &reqStatsNS[7])
				}
				return reqStatsNS, nil
			} else {
				return reqStatsNS, fmt.Errorf("Server is up, but HTTP response is not OK!\nStatusCode: %d\n", resp.StatusCode)
			}
		} else {
			time.Sleep(5 * time.Millisecond)
			failCount += 1
			if failCount == maxFailsToStart {
				return reqStatsNS, err
			}
		}
	}
}

func sendRequest2(URL string) (*http.Response, error, int64, int64) {
	sendRequestNanoTS := Now()
	response, err := http.Get(URL)
	receiveResponseNanoTS := Now()
	if err == nil && response.Body != nil {
		io.Copy(ioutil.Discard, response.Body)
		response.Body.Close()
	}
	return response, err, sendRequestNanoTS, receiveResponseNanoTS
}
