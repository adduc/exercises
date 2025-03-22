LAMBDA_NAME := bash_lambda

.NOTPARALLEL:
.PHONY: archive upload wait deploy clean

archive:
	zip -r $(LAMBDA_NAME).zip bootstrap

upload:
	aws lambda update-function-code \
		--function-name $(LAMBDA_NAME) \
		--zip-file fileb://$(LAMBDA_NAME).zip

wait:
	aws lambda wait function-updated --function-name $(LAMBDA_NAME)

deploy: archive upload wait

invoke:
	aws lambda invoke --function-name $(LAMBDA_NAME) --payload '{}' /dev/stderr > /dev/null

logs:
	aws logs tail /aws/lambda/$(LAMBDA_NAME)