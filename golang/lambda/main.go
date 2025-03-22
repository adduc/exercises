package main

import (
	"github.com/aws/aws-lambda-go/lambda"
)

type Request struct {
}

type Response struct {
	Body       string `json:"body"`
	StatusCode int    `json:"statusCode"`
}

func handler(request Request) (Response, error) {
	println("Hello from handler!")
	return Response{
		Body:       "Hello, World!",
		StatusCode: 200,
	}, nil
}

func main() {
	println("Hello from main!")
	lambda.Start(handler)
}
