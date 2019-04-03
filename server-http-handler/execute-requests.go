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
	_ "unsafe" // required to use //go:linkname
)

//go:noescape
//go:linkname nanotime runtime.nanotime
func nanotime() int64

func Now() int64 {
	return int64(nanotime())
}

func setupCRIU(jarPath string, serverLogFile string) (*exec.Cmd, io.ReadCloser, error) {
	fmt.Fprintln(os.Stderr, "Criu Handler Type")
	upServerCmd := exec.Command("criu", "restore", "-d", "-v3", "-o", "restore.log")
	upServerCmd.Env = os.Environ()
	
	currentDir, _ := os.Getwd()
	upServerCmd.Dir = fmt.Sprintf("%s/%s", currentDir, jarPath)
	fmt.Fprintf(os.Stderr, "Dir [%s]\n", upServerCmd.Dir)
	
	serverStdout, err := os.Open(serverLogFile)
	return upServerCmd, serverStdout, err
}

func setupDefault(jarPath string) (*exec.Cmd, io.ReadCloser, error) {
	fmt.Fprintln(os.Stderr, "Default Handler Type")
	upServerCmd := exec.Command("java", "-jar", jarPath)
	upServerCmd.Env = os.Environ()
	serverStdout, err := upServerCmd.StdoutPipe()
	return upServerCmd, serverStdout, err
}

func main() {
	serverAddress := os.Args[1]
	endpoint := os.Args[2]
	nRequests, err := strconv.ParseInt(os.Args[3], 10, 64)
	executionID := os.Args[4]
	jarPath := os.Args[5]
	handlerType := os.Args[6]
	trace := os.Args[7]
	optPath := os.Args[8]

	if err != nil {
		log.Fatal(err)
	}
	functionURL := fmt.Sprintf("http://%s%s", serverAddress, endpoint)

    var upServerCmd* exec.Cmd
    var serverStdout io.ReadCloser
	if handlerType == "criu" {
		fmt.Fprintln(os.Stderr, "CRIU")
		upServerCmd, serverStdout, err = setupCRIU(jarPath, optPath)
	} else if trace == "y" {
		fmt.Fprintln(os.Stderr, "TRACE")
		upServerCmd = nil
		serverStdout, err = os.Open(optPath)
	} else {
		fmt.Fprintln(os.Stderr, "DEFAULT")
		upServerCmd, serverStdout, err = setupDefault(jarPath)
	}

	if err != nil {
		log.Fatal(err)
	}

	var startHTTPServerTS int64
	if upServerCmd != nil {
		fmt.Println(os.Stderr, strings.Join(upServerCmd.Args, ", "))
		// Start Http Server
		fmt.Fprintln(os.Stderr, "Start HTTP Server")

		startHTTPServerTS = Now()
		if err := upServerCmd.Start(); err != nil {
			log.Fatal(err)
		}
	}

	fmt.Fprintln(os.Stderr, "Get Ready Time")

	timestamps, err := getHTTPServerReadyAndServiceTS(functionURL, serverStdout)
	fmt.Fprintln(os.Stderr, "Got Ready Time")

	if err != nil {
		fmt.Fprintln(os.Stderr, "Max tries reached")
		
		// Kill Http server process
		if err := upServerCmd.Process.Kill(); err != nil {
			log.Fatal("failed to kill process: ", err)
		}
		log.Fatal(err)
	}

	fmt.Fprintf(os.Stderr, "Values for Ready Time %d, %d\n", timestamps[2], timestamps[3])

	if trace != "y" {
		// Apply requests
		fmt.Fprintln(os.Stderr, "Applying requests")
		roundTrip, serviceTime := getRoundTripAndServiceTime(nRequests, functionURL, serverStdout)

		// Write results
		fmt.Fprintln(os.Stderr, "Writing results")
		fmt.Printf("%s,%s,%d,%d\n", "RuntimeReadyTime", executionID, 0, timestamps[2] - startHTTPServerTS)
		fmt.Printf("%s,%s,%d,%d\n", "ServiceTime", executionID, 0, timestamps[3] - timestamps[2])
		for i := 1; i <= len(roundTrip); i++ {
			fmt.Printf("%s,%s,%d,%d\n", "RoundTripTime", executionID, i, roundTrip[i - 1])
			fmt.Printf("%s,%s,%d,%d\n", "ServiceTime", executionID, i, serviceTime[i - 1])
		}
	} else {
		// Write results
		fmt.Fprintln(os.Stderr, "Writing results")
		fmt.Printf("%s,%s,%d,%d\n", "MainEntry", executionID, 0, timestamps[0])
		fmt.Printf("%s,%s,%d,%d\n", "MainExit", executionID, 0, timestamps[1])
		fmt.Printf("%s,%s,%d,%d\n", "Ready2Serve", executionID, 0, timestamps[2])
	}

	serverStdout.Close()

	if upServerCmd != nil {
		fmt.Fprintln(os.Stderr, fmt.Sprintf("Killing Process: %d\n", upServerCmd.Process.Pid))
		// Kill Http server process
		if err := upServerCmd.Process.Kill(); err != nil {
			log.Fatal("failed to kill process: ", err)
		}
		fmt.Fprintln(os.Stderr, fmt.Sprintf("Waiting...\n"))
		upServerCmd.Process.Wait()
	}

	fmt.Fprintln(os.Stderr, fmt.Sprintf("End of execution: %s\n", executionID))

	os.Exit(0)
}

func getRoundTripAndServiceTime(nRequests int64, functionURL string, serverStdout io.ReadCloser) ([]int64, []int64) {
	var roundTrip, serviceTime []int64
	var startServiceTS, endServiceTS int64
	for i := int64(1); i < nRequests; i++ {
		response, err, sendRequestTS, receiveResponseTS := sendRequest2(functionURL)
		if err == nil && response.StatusCode == http.StatusOK {
			fmt.Fscanf(serverStdout, "T4: %d", &startServiceTS)
			fmt.Fscanf(serverStdout, "T6: %d", &endServiceTS)
			
			roundTrip = append(roundTrip, receiveResponseTS - sendRequestTS)
			serviceTime = append(serviceTime, endServiceTS - startServiceTS)
		} else {
			log.Fatal(err)
		}
	}
	return roundTrip, serviceTime
}

func getHTTPServerReadyAndServiceTS(functionURL string, serverStdout io.ReadCloser) ([4]int64, error) {
	maxFailsToStart := int64(2000)
	var failCount int64
	var timestamps [4]int64
	for {
		resp, err := http.Get(functionURL)
		if err == nil  {
			if resp.StatusCode == http.StatusOK {
				io.Copy(ioutil.Discard, resp.Body)
				resp.Body.Close()
				fmt.Fscanf(serverStdout, "Entered in main: %d", &timestamps[0])
				fmt.Fscanf(serverStdout, "Exit from main: %d", &timestamps[1])
				fmt.Fscanf(serverStdout, "T4: %d", &timestamps[2])
				fmt.Fscanf(serverStdout, "T6: %d", &timestamps[3])
				return timestamps, nil
			} else {
				return timestamps, fmt.Errorf("Server is up, but HTTP response is not OK!\nStatusCode: %d\n", resp.StatusCode)
			}
		} else {
			time.Sleep(5 * time.Millisecond)
			failCount += 1
			if failCount == maxFailsToStart {
				return timestamps, err
			}
		}
	}
}

func sendRequest2(URL string) (*http.Response, error, int64, int64) {
	sendRequestTS := Now()
	response, err := http.Get(URL)
	receiveResponseTS := Now()
	if err == nil && response.Body != nil {
		io.Copy(ioutil.Discard, response.Body)
		response.Body.Close()
	}
	return response, err, sendRequestTS, receiveResponseTS
}
