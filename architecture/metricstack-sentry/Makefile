include .env

sentry/install:
	@echo "Cloing sentry/self-hosted repository..."
	@git clone https://github.com/getsentry/self-hosted.git sentry --depth 1

	@echo "Copying sentry example configuration file..."
	@cp sentry/sentry/sentry.conf.example.py sentry/sentry/sentry.conf.py

	@echo "Enabling profiling features in Sentry configuration..."
	@echo 'SENTRY_FEATURES["organizations:profiling-view"] = True' >> sentry/sentry/sentry.conf.py

	@echo "Running Sentry setup..."
	@cd sentry && env SKIP_USER_CREATION=1 REPORT_SELF_HOSTED_ISSUES=0 ./install.sh

	@echo "Creating Sentry user..."
	@cd sentry && docker compose run --rm web createuser \
		--email $(SENTRY_EMAIL) \
		--password $(SENTRY_PASSWORD) \
		--superuser \
		--staff

	@echo "Starting Sentry services..."
	@cd sentry && docker compose up -d
	@echo "Sentry is now running. Access it at http://localhost:9000"

sentry/reset:
	cd sentry && docker compose down --volumes --remove-orphans --timeout 0
	rm -rf sentry
	docker volume ls -q | grep sentry | xargs -r docker volume rm
