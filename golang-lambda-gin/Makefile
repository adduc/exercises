include terraform.tfvars

.NOTPARALLEL:
.PHONY: build archive deploy pipeline execute clean

build:
	go build -o build/bootstrap main.go

archive:
	zip -j build/lambda.zip build/bootstrap

deploy:
	aws lambda update-function-code \
		--function-name $(lambda_name) \
		--zip-file fileb://build/lambda.zip

pipeline: build archive deploy
	aws lambda wait function-updated \
		--function-name $(lambda_name)

execute:
	aws lambda invoke --function-name $(lambda_name) --payload "{}" /dev/stdout

clean:
	rm -rf build