#!/bin/bash

function ERROR_CRITICO {
        pkill xterm
        pkill aa-ventana
        pkill python
        pkill aa-principal
	exit 1
}

function ERROR_APT {
	zenity --text="¡Existe un gestor de paquetes trabajando!\n\nReinicia tu computador o ejecuta manualmente el actualizador desde el menú Aplicaciones > Herramientas del Sistema > Actualizador a Canaima 3.0, cuando el gestor de paquetes termine de ejecutarse." --title="ERROR" --error --width=600
	ERROR_CRITICO
}
function ERROR_INTERNET {
	zenity --text="¡Ooops! Parece que no tienes conexión a internet.\n\nReinicia tu computador o ejecuta manualmente el actualizador desde el menú Aplicaciones > Herramientas del Sistema > Actualizador a Canaima 3.0, cuando compruebes que tienes conexión a internet." --title="ERROR" --error --width=600
	[ -e /tmp/index.google ] && rm /tmp/index.google
	ERROR_CRITICO
}

function ERROR_INESPERADO {
        zenity --text="¡Ha ocurrido un error inesperado!\n\nReinicia tu computador o reanuda manualmente el actualizador desde el menú Aplicaciones > Herramientas del Sistema > Actualizador a Canaima 3.0.\n\nSi el problema persiste, por favor envía el archivo '/usr/share/asistente-actualizacion/log/principal.log' a la dirección de correo electrónico 'desarrolladores@canaima.softwarelibre.gob.ve' junto con una explicación de lo sucedido para que podamos ayudarte." --title="ERROR" --error --width=600
	ERROR_CRITICO
}
