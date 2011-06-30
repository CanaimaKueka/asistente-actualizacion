# Makefile

SHELL := sh -e

SCRIPTS = "debian/preinst install" "debian/postinst configure" "debian/prerm remove" "debian/postrm remove"

all: test build

test:

	@echo -n "\n===== Comprobando posibles errores de sintaxis en los scripts de mantenedor =====\n\n"

	@for SCRIPT in $(SCRIPTS); \
	do \
		echo -n "$${SCRIPT}\n"; \
		bash -n $${SCRIPT}; \
	done

	@echo -n "\n=================================================================================\nHECHO!\n\n"

build:

	@echo "Nada para compilar!"

install:

	mkdir -p $(DESTDIR)/usr/share/asistente-actualizacion/
	cp -rf asistente/* $(DESTDIR)/usr/share/asistente-actualizacion/
	cp gui/actualizador $(DESTDIR)/usr/bin/
	chmod +x $(DESTDIR)/usr/bin/actualizador

uninstall:

	rm -rf $(DESTDIR)/usr/share/asistente-actualizacion/
	rm $(DESTDIR)/usr/bin/actualizador

clean:

distclean:

reinstall: uninstall install
