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
	mkdir -p $(DESTDIR)/etc/skel/Escritorio/
	mkdir -p $(DESTDIR)/etc/skel/.config/autostart/
	mkdir -p $(DESTDIR)/usr/share/applications/
	mkdir -p $(DESTDIR)/etc/xdg/autostart/
	cp -r asistente/principal.py $(DESTDIR)/usr/share/asistente-actualizacion/
	cp -r asistente/asistente-actualizacion.desktop $(DESTDIR)/etc/xdg/autostart/
	cp -r asistente/paso.conf $(DESTDIR)/usr/share/asistente-actualizacion/
	cp -r asistente/gui.glade $(DESTDIR)/usr/share/asistente-actualizacion/
	cp -r asistente/asistente.png $(DESTDIR)/usr/share/asistente-actualizacion/
	cp -r asistente/initasist $(DESTDIR)/usr/share/asistente-actualizacion/
	cp -r asistente/preferences.canaima $(DESTDIR)/usr/share/asistente-actualizacion/
	cp -r asistente/preferences $(DESTDIR)/usr/share/asistente-actualizacion/
	cp -r asistente/sources.list $(DESTDIR)/usr/share/asistente-actualizacion/
	cp -r asistente/sources.list.canaima $(DESTDIR)/usr/share/asistente-actualizacion/
	cp -r asistente/acciones $(DESTDIR)/usr/share/asistente-actualizacion/
	cp -r asistente/selections.conf $(DESTDIR)/usr/share/asistente-actualizacion/
	cp -r asistente/acciones $(DESTDIR)/usr/bin/asistente-actualizacion

uninstall:

	rm -rf $(DESTDIR)/usr/share/asistente-actualizacion/

clean:

distclean:

reinstall: uninstall install
