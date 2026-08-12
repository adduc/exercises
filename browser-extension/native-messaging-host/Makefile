HOST_NAME := com.adduc.example
ROOT_DIR  := $(abspath .)
SCRIPT    := $(ROOT_DIR)/native-host/native-host.sh
BUILD_DIR := $(ROOT_DIR)/build

LIBREWOLF_DIR := $(HOME)/.librewolf/native-messaging-hosts

# Renders the checked-in templates with this machine's absolute script path
# (native-messaging manifests can't use relative paths or env vars) and,
# for Chrome, the extension ID.
build:
	chmod +x $(SCRIPT)
	mkdir -p $(BUILD_DIR)
	sed -e 's#__NATIVE_HOST_PATH__#$(SCRIPT)#' \
	    -e 's#__EXTENSION_ID__#$(EXTENSION_ID)#' \
	    $(HOST_NAME).json > $(BUILD_DIR)/$(HOST_NAME).chrome.json
	sed -e 's#__NATIVE_HOST_PATH__#$(SCRIPT)#' \
	    $(HOST_NAME).firefox.json > $(BUILD_DIR)/$(HOST_NAME).firefox.json

install-librewolf: build
	mkdir -p $(LIBREWOLF_DIR)
	ln -sf $(BUILD_DIR)/$(HOST_NAME).firefox.json $(LIBREWOLF_DIR)/$(HOST_NAME).json

clean:
	rm -f $(CHROME_DIR)/$(HOST_NAME).json $(FIREFOX_DIR)/$(HOST_NAME).json
	rm -rf $(BUILD_DIR)

