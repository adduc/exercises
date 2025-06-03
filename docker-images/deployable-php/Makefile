IMAGE := local/deployable-php:latest

build:
	docker build -t $(IMAGE) .

run:
	docker run --rm -it -p 2222:22 -v $$HOME/.ssh:/home/user/.ssh $(IMAGE)
