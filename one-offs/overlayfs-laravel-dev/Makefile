DIRNAME := $(shell basename $(PWD))
WORKDIR := $(DIRNAME).workdir
UPPER := $(DIRNAME).upper
LOWER := $(DIRNAME).lower
MERGED := $(DIRNAME).merged

.ONESHELL:

# check for fuse-overlayfs
ifeq (, $(shell which fuse-overlayfs))
$(error "fuse-overlayfs is not installed. Please install it to use this Makefile.")
endif

# check for lower dir
ifeq (, $(shell test -d $(LOWER) && echo 1))
$(error "Lower directory $(LOWER) does not exist. Please create it to use this Makefile.")
endif

# check for upper dir
ifeq (, $(shell test -d $(UPPER) && echo 1))
$(error "Upper directory $(UPPER) does not exist. Please create it to use this Makefile.")
endif


help: ## Show this help message
	@grep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

mount: unmount ## Mount the overlay filesystem
	@set -o pipefail -o errexit -o nounset

	rm -rf $(WORKDIR)
	mkdir -p $(WORKDIR) $(LOWER) $(MERGED)

	fuse-overlayfs -o lowerdir=$(LOWER),upperdir=$(UPPER),workdir=$(WORKDIR) $(MERGED)
	echo "$(MERGED) mounted successfully."

unmount: ## Unmount the overlay filesystem
	@set -o pipefail -o errexit -o nounset

	echo "Checking if $(MERGED) is mounted..."

	if mountpoint -q $(MERGED); then
		echo "$(MERGED) is mounted, unmounting..."
		fusermount -z -u $(MERGED)
	else
		echo "$(MERGED) is not mounted"
	fi

