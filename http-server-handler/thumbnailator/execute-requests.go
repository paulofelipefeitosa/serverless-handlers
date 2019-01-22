package main

import(
	"os"
	"os/exec"
	"log"
	"strings"
	"time"
	"net/http"
	"strconv"
	"fmt"
	"io"
	"io/ioutil"
)

func main() {
	protocol := "http://"
	serverAddress := os.Args[1]
	endpoint := os.Args[2]
	
	var builder strings.Builder
	builder.WriteString(protocol)
	builder.WriteString(serverAddress)
	builder.WriteString(endpoint)
	
	functionUrl := builder.String()

	nRequests, err := strconv.ParseInt(os.Args[3], 10, 64)
	if err != nil {
		log.Fatal(err)
		os.Exit(-1)
	}
	executionId := os.Args[4]

	httpServerCmdParts := strings.Split("java -jar target/thumbnailator-server-maven-0.0.1-SNAPSHOT.jar", " ")
	upServerCmd := exec.Command(httpServerCmdParts[0], httpServerCmdParts[1:]...)
	upServerCmd.Env = getEnvs()
	serverOutputStream, err := upServerCmd.StdoutPipe()
	if err != nil {
    	log.Fatal(err)
    	os.Exit(-1)
	}

	t1 := time.Now().UTC().UnixNano()
	if err := upServerCmd.Start(); err != nil {
    	log.Fatal(err)
    	os.Exit(-1)
	}
	t4 := getT4(functionUrl, serverOutputStream)

	roundTrip, serviceTime := getRoundTripAndServiceTime(nRequests, functionUrl, serverOutputStream)

	fmt.Println("%s,%s,%d", "RuntimeReadyTime", executionId, t4 - t1)
	for i := 1; i <= len(roundTrip); i++ {
    	fmt.Println("%s,%d,%d", "RoundTripTime", i, roundTrip[i])
    	fmt.Println("%s,%d,%d", "ServiceTime", i, serviceTime[i])
	}
}

func getRoundTripAndServiceTime(nRequests int64, functionUrl string, serverStdout io.ReadCloser) ([]int64, []int64) {
	var roundTrip []int64
	var serviceTime []int64
	for i := int64(0); i < nRequests; i++ {
		response, err, t2, t3 := getResponseFrom(functionUrl)
		if response.StatusCode == 200 {
			var t5 int64
			var t6 int64
			fmt.Fscanf(serverStdout, "T5: %d", &t5)
			fmt.Fscanf(serverStdout, "T6: %d", &t6)
			roundTrip = append(roundTrip, t3 - t2)
			serviceTime = append(serviceTime, t6 - t5)
		} else {
			log.Fatal(err)
		}
	}
	return roundTrip, serviceTime
}

func getT4(functionUrl string, serverStdout io.ReadCloser) int64 {
	var t4 int64
	for {
		response, _, _, _ := getResponseFrom(functionUrl)
		if response.StatusCode == 200 {
			fmt.Fscanf(serverStdout, "T4: %d", &t4)
			return t4
		}
	}
}

func getResponseFrom(url string) (*http.Response, error, int64, int64) {
	t2 := time.Now()
	response, err := http.Get(url)
	t3 := time.Now()
	if response.Body != nil {
		response.Body.Close()
		_,_ = ioutil.ReadAll(response.Body)
	}
	return response, err, t2.UTC().UnixNano(), t3.UTC().UnixNano()
}

func getEnvs() []string {
	var envs = os.Environ()
	envs = append(envs, "scale=0.1")
	envs = append(envs, "image_url=https://i.imgur.com/BhlDUOR.jpg")
	return envs
}