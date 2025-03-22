LAMBDA_NAME := golang_lambda

.NOTPARALLEL:
.PHONY: build archive upload wait deploy clean

build:
	# Build the Go binary for AWS Lambda (must be named "bootstrap")
	# @see https://docs.aws.amazon.com/lambda/latest/dg/golang-handler.html
	go build -o build/bootstrap main.go

run:
	go run main.go

archive:
	cd build && zip -r $(LAMBDA_NAME).zip bootstrap

upload:
	aws lambda update-function-code \
		--function-name $(LAMBDA_NAME) \
		--zip-file fileb://build/$(LAMBDA_NAME).zip

wait:
	aws lambda wait function-updated --function-name $(LAMBDA_NAME)

deploy: build archive upload wait

clean:
	rm -f build

invoke:
	aws lambda invoke --function-name $(LAMBDA_NAME) --payload '{}' /dev/stderr > /dev/null

logs:
	aws logs tail /aws/lambda/$(LAMBDA_NAME)