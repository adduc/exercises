run: reset
	docker compose up -d
	docker compose exec server systemctl enable \
		/etc/systemd/user/OneShot.service \
		/etc/systemd/user/OnFailure.service \
		/etc/systemd/user/Timer.timer

	docker compose exec server systemctl enable --now Timer.timer

	@# docker compose exec server systemctl start OneShot.service
	@# journalctl _SYSTEMD_INVOCATION_ID=d70d82686aba484e9f2aa45142283414

reset:
	docker compose down -t 0

shell:
	docker compose exec server bash

journalctl:
	docker compose exec server journalctl

error-logs:
	docker compose exec server cat /tmp/a
