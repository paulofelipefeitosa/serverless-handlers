package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
)

type ExecutionConfig struct {
	EnvVars  []string // Additional environment variables in format "key=value".
	Requests int      // Number of the request that should be applied.
	Request  *Request // The specification of the request that will be sent to the function.
}

type RequestMethod string

const (
	Get     RequestMethod = "GET"
	Post    RequestMethod = "POST"
	Invalid RequestMethod = "Invalid"
)

type Request struct {
	Method       string
	Path         string
	Headers      map[string]string
	BodyFilepath string
}

func (r *Request) GetPath() string {
	return r.Path
}

func (r *Request) GetMethod() (RequestMethod, error) {
	switch r.Method {
	case string(Get):
		return Get, nil
	case string(Post):
		return Post, nil
	default:
		return Invalid, fmt.Errorf("invalid request method (%s)", r.Method)
	}
}

func (r *Request) GetBody() (string, error) {
	f, err := os.Open(r.BodyFilepath)
	if err != nil {
		return "", fmt.Errorf("unable to open file (%s) which contains the request body content due to (%v)", r.BodyFilepath, err)
	}
	c, err := ioutil.ReadAll(f)
	if err != nil {
		return "", fmt.Errorf("unable to read file (%s) which contains the request body content due to (%v)", r.BodyFilepath, err)
	}
	return string(c), nil
}

func (r *Request) GetHeaders() map[string]string {
	return r.Headers
}

func (r *Request) HTTPRequest(hostAddr string) (*http.Request, error) {
	URL := fmt.Sprintf("http://%s%s", hostAddr, r.GetPath())
	body, err := r.GetBody()
	if err != nil {
		return nil, fmt.Errorf("cannot create request due to (%v)", err)
	}
	req, err := http.NewRequest(r.Method, URL, ioutil.NopCloser(strings.NewReader(body)))
	if err != nil {
		return nil, fmt.Errorf("cannot create request due to (%v)", err)
	}
	return req, nil
}
