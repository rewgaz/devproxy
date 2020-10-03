.DEFAULT_GOAL := default
.PHONY: default install uninstall

default:
	@echo "Usage:"
	@echo "  make install"
	@echo "  make uninstall"

install:
	@echo "Install..."
	mkdir -p /etc/devproxy/config
	cp -r src /usr/local/src/devproxy
	chmod +x /usr/local/src/devproxy/devproxy
	ln -sf /usr/local/src/devproxy/devproxy /usr/local/bin/devproxy
	@echo "...complete!"

uninstall:
	@echo "Uninstall..."
	rm -Rf /usr/local/src/devproxy
	rm -f /usr/local/bin/devproxy
	@echo "...complete!"
