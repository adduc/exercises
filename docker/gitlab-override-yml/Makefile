reset:
	docker compose kill
	docker compose rm -f
	sudo rm -rf config data logs

up:
	@echo "Starting GitLab and waiting for it to be fully up..."
	@echo "This may take a few minutes, please be patient."
	docker compose up -d --wait
	@echo "GitLab can now be reached at http://gitlab.127.0.0.1.nip.io"