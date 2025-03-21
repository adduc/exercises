include .env

# Try to accomodate double-quotes in the .env file
BACKUP_DIR := $(patsubst "%",%,$(BACKUP_DIR))
TARGET_DIR := $(patsubst "%",%,$(TARGET_DIR))
IMG_NAME := $(patsubst "%",%,$(IMG_NAME))
LUKS_KEYFILE := $(patsubst "%",%,$(LUKS_KEYFILE))

# if TARGET_DIR does not begin with a /, prepend $(CUR_DIR)
ifeq ($(TARGET_DIR),$(filter $(TARGET_DIR),$(subst /,,$(TARGET_DIR))))
	TARGET_DIR_ABS := $(CURDIR)/$(TARGET_DIR)
else
	TARGET_DIR_ABS := $(TARGET_DIR)
endif

# remove backup_dir from curdir to avoid rsync issues (in case it is a
# subdir of the target_dir)
TARGET_DIR_PREPPED := $(subst $(BACKUP_DIR)/,,$(CURDIR))

.PHONY: backup

help: ## Show this help message
	@grep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

dryrun: ## Perform a dry run of the backup
	@echo "Performing a dry run of the backup..."
	sudo rsync -rPtal --delete --delete-excluded --dry-run \
		--include-from=rsync.exclude \
		--exclude="$(TARGET_DIR_PREPPED)/**" \
		"$(BACKUP_DIR)/" "$(TARGET_DIR)/"

backup: ## Back up files from BACKUP_DIR to TARGET_DIR
	@echo "Backing up files from $(BACKUP_DIR) to $(TARGET_DIR)..."
	sudo rsync -rPtal --delete --delete-excluded \
		--include-from=rsync.exclude \
		--exclude="$(TARGET_DIR_PREPPED)/**" \
		"$(BACKUP_DIR)" "$(TARGET_DIR)/"

reset: ## Remove squashfs image
	@echo "Cleaning up..."
	rm -rf "$(IMG_NAME)"

create-squashfs-image: ## Create a SquashFS disk image from TARGET_DIR
	@echo "Creating SquashFS image..."
	sudo mksquashfs "$(TARGET_DIR)" "$(IMG_NAME)" -noappend

	@echo "Setting permissions on the SquashFS image..."
	sudo chown $(USER):$(GROUP) "$(IMG_NAME)"

	@echo "Expanding SquashFS image to allow for LUKS encryption..."
	truncate -s +16M "$(IMG_NAME)"

create-encrypted-image: ## Create a LUKS encrypted image from the SquashFS image
	@echo "Creating LUKS encrypted volume..."
	sudo cryptsetup reencrypt --encrypt --type luks2 \
		--batch-mode \
		--resilience none \
		--disable-locks \
		--reduce-device-size 16M \
		--key-file $(LUKS_KEYFILE) \
		--key-slot 0 \
		--force-offline-reencrypt \
		"$(IMG_NAME)"

	@echo "Shrinking LUKS volume..."
	truncate -s -8M "$(IMG_NAME)"

burn-disc: ## Burn the disk image to a disc
	@echo "Burning the disk image to disc..."
	growisofs -dvd-compat -Z /dev/sr0="$(IMG_NAME)"

generate-luks-keyfile: ## Generate a LUKS keyfile if it doesn't exist
	if [ -f $(LUKS_KEYFILE) ]; then \
		echo "LUKS key already exists. Skipping generation."; \
		exit 1; \
	fi

	@echo "Generating LUKS keyfile..."
	openssl genrsa -out $(LUKS_KEYFILE) 4096