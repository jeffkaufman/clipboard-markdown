all: bin/html-clipboard

bin/html-clipboard: src/html-clipboard.swift
	swiftc src/html-clipboard.swift -o bin/html-clipboard

clean:
	rm -f bin/html-clipboard

.PHONY: all clean
