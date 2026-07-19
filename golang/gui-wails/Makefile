BINARY := gui-wails
TAGS := production,webkit2_41

.PHONY: build run clean

build:
	go build -tags $(TAGS) -o $(BINARY) .

run: build
	./$(BINARY)

clean:
	rm -f $(BINARY)
