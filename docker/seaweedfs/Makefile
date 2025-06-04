init:
	docker compose up -d
	sleep 2 # wait for seaweedfs to start
	docker compose exec server sh -c 'echo "s3.bucket.create -name xxx" | weed shell'

list:
	env AWS_DEFAULT_REGION=xxx AWS_ACCESS_KEY_ID=xxx AWS_SECRET_ACCESS_KEY=xxx \
		aws --endpoint-url http://localhost:8333 s3 ls s3://xxx

upload:
	env AWS_DEFAULT_REGION=xxx AWS_ACCESS_KEY_ID=xxx AWS_SECRET_ACCESS_KEY=xxx \
		aws --endpoint-url http://localhost:8333 s3 cp ./Makefile s3://xxx/Makefile

download:
	env AWS_DEFAULT_REGION=xxx AWS_ACCESS_KEY_ID=xxx AWS_SECRET_ACCESS_KEY=xxx \
		aws --endpoint-url http://localhost:8333 s3 cp s3://xxx/Makefile -

reset:
	docker compose down --volumes --timeout 0
	sudo rm -rf ./data
