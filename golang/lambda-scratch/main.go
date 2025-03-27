package main

import (
	"io"
	"net/http"
	"os"
	"strings"
)

type LambdaRuntime struct {
	ApiUrl string
}

func NewLambdaRuntime() *LambdaRuntime {
	apiUrl := os.Getenv("AWS_LAMBDA_RUNTIME_API")

	if apiUrl == "" {
		panic("AWS_LAMBDA_RUNTIME_API environment variable is not set")
	}

	return &LambdaRuntime{ApiUrl: apiUrl}
}

func (l *LambdaRuntime) getNextInvocationUrl() string {
	return "http://" + l.ApiUrl + "/2018-06-01/runtime/invocation/next"
}
func (l *LambdaRuntime) getResponseUrl(requestID string) string {
	return "http://" + l.ApiUrl + "/2018-06-01/runtime/invocation/" + requestID + "/response"
}

func (l *LambdaRuntime) GetNextInvocation() (string, []byte) {
	url := l.getNextInvocationUrl()
	resp, err := http.Get(url)
	if err != nil {
		panic(err)
	}
	defer panicIfError(resp.Body.Close())

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		panic(err)
	}

	requestID := resp.Header.Get("Lambda-Runtime-Aws-Request-Id")

	return requestID, body
}

func (l *LambdaRuntime) SendResponse(requestID string, body io.Reader) {
	url := l.getResponseUrl(requestID)
	resp, err := http.Post(url, "application/json", body)
	if err != nil {
		panic(err)
	}
	defer panicIfError(resp.Body.Close())
}

type LambdaHandler func(requestID string, body []byte) io.Reader

// accept a callable to invoke on each request
func (l *LambdaRuntime) Run(fn LambdaHandler) {
	for {
		requestID, body := l.GetNextInvocation()
		response := fn(requestID, body)
		l.SendResponse(requestID, response)
	}
}

func panicIfError(err error) {
	if err != nil {
		panic(err)
	}
}

func main() {

	println("Hello, World!")

	handler := func(requestID string, body []byte) io.Reader {
		println("Received request: " + requestID)
		println("Body: " + string(body))
		return strings.NewReader(string(body))
	}

	lambdaRuntime := NewLambdaRuntime()
	lambdaRuntime.Run(handler)
}
