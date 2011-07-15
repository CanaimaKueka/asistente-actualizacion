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
	mkdir -p $(DESTDIR)/usr/bin/
	mkdir -p $(DESTDIR)/etc/xdg/autostart/

	cp -rf gui log conf listas imagenes $(DESTDIR)/usr/share/asistente-actualizacion/
	cp -rf scripts/aa-fin.sh $(DESTDIR)/usr/bin/aa-fin
	cp -rf scripts/aa-inicio.sh $(DESTDIR)/usr/bin/aa-inicio
	cp -rf scripts/aa-kernel.sh $(DESTDIR)/usr/bin/aa-kernel
	cp -rf scripts/aa-principal.sh $(DESTDIR)/usr/bin/aa-principal
	cp -rf scripts/aa-ventana.sh $(DESTDIR)/usr/bin/aa-ventana
	cp -rf desktop/asistente-actualizacion.desktop $(DESTDIR)/etc/xdg/autostart/

uninstall:

	rm -rf $(DESTDIR)/usr/share/asistente-actualizacion/
	rm $(DESTDIR)/usr/bin/aa-fin
	rm $(DESTDIR)/usr/bin/aa-inicio
	rm $(DESTDIR)/usr/bin/aa-kernel
	rm $(DESTDIR)/usr/bin/aa-principal

clean:

distclean:

reinstall: uninstall install
