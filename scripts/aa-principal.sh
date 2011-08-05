#!/bin/bash

echo "[BASH:aa-principal.sh] Iniciando actualización" >> ${LOG}

VARIABLES="/usr/share/asistente-actualizacion/conf/variables.conf"

# Cargando variables internas
. ${VARIABLES}

# Cargando paso actual del asistente
. ${PASO_FILE}

# Organiza los paquetes
cat ${ORIGINAL} > ${TOTAL}
cat ${LOCAL} >> ${TOTAL}
TOTAL_REP=$( cat ${TOTAL} | sort -u )
TOTAL_FINAL=$( echo ${TOTAL_REP} | awk 'BEGIN {OFS = "\n"; ORS = " " }; {print $1}' )
TOTAL_NUM=$( echo $TOTAL_FINAL | wc -w )

# Iniciamos ventana de progreso
xterm -e "tail -f ${LOG}" &
aa-ventana &

# Si estamos en una canaimita, desinstalamos en control parental que ralentiza el proceso
if [ $( dpkg-query -W -f='${Package}\t${Status}\n' canaima-control-parental | grep -c "install ok installed" ) == 1 ]; then
	aptitude purge ${APTITUDE_OPTIONS} canaima-control-parental
fi

# Si estamos en una canaimita, desactivamos el filtrado de hosts que ralentiza el proceso
if [ -e "/etc/hosts.canaima-control-parental.backup" ]; then
	cp /etc/hosts.canaima-control-parental.backup /etc/hosts
fi

# Iteramos por los pasos
while [ ${PASO} -lt 60 ]; do

# Verificar si existe un gestor de paquetes
if [ $( ps -A | grep -cw update-manager ) == 1 ] || [ $( ps -A | grep -cw apt-get ) == 1 ] || [ $( ps -A | grep -cw aptitude ) == 1 ];then
	zenity --text="¡Existe un gestor de paquetes trabajando!\n\nReinicia tu computador o ejecuta manualmente el actualizador desde el menú Aplicaciones > Herramientas del Sistema > Actualizador a Canaima 3.0, cuando el gestor de paquetes termine de ejecutarse." --title="ERROR" --error --width=600
	pkill xterm
	pkill aa-ventana
	pkill python
	pkill aa-principal
	exit 1
fi

echo "Obteniendo dirección IP (dhclient)" | tee -a ${VENTANA_2} ${LOG}
/etc/init.d/networking restart | tee -a ${LOG}
dhclient | tee -a ${LOG}

echo "Comprobando conexión a internet" | tee -a ${VENTANA_2} ${LOG}
wget --timeout=10 http://www.google.com -O /tmp/index.google | tee -a ${LOG}

if [ ! -s /tmp/index.google ];then
	zenity --text="¡Ooops! Parece que no tienes conexión a internet.\n\nReinicia tu computador o ejecuta manualmente el actualizador desde el menú Aplicaciones > Herramientas del Sistema > Actualizador a Canaima 3.0, cuando compruebes que tienes conexión a internet." --title="ERROR" --error --width=600
	pkill xterm
	pkill aa-ventana
	pkill python
	pkill aa-principal
	rm /tmp/index.google
	exit 1
fi

rm /tmp/index.google

echo "Arreglando posibles paquetes rotos" | tee -a ${VENTANA_2} ${LOG}
apt-get ${APT_GET_OPTIONS} -f install | tee -a ${LOG}
dpkg --configure -a | tee -a ${LOG}
debconf-set-selections ${DEBCONF_SEL}

echo "[BASH:aa-principal.sh] PASO ${PASO} ============================================" >> ${LOG}

. ${PASO_FILE}

case ${PASO} in

1)
	# Ventana de bienvenida
	zenity --title="Asistente de Actualización a Canaima 3.0" --text="Este asistente se encargará de hacer los cambios necesarios para actualizar el sistema a la versión 3.0 de Canaima.\n\nAsegúrese que:\n\n* Dispone de una conexión a internet.\n\n* Su PC está conectada a una fuente de energía estable.\n\n* Tiene al menos 6GB de espacio libre en disco.\n\n* No está ejecutando un gestor o instalador de paquetes.\n\n* No tiene ningún documento importante abierto.\n\n* Dispone de al menos 2 horas libres de su tiempo.\n\nSi por alguna razón el proceso se detiene, puede reiniciarlo desde el punto en quese interrumpió haciendo click en Aplicaciones > Herramientas del Sistema > Actualizador a Canaima 3.0.\n\n¿Desea continuar con la actualización?" --question --width=600

	if [ $? == 1 ];then
		pkill xterm
		pkill aa-ventana
		pkill python
		pkill aa-principal
		exit 1
	fi

	echo "Inicializando el Asistente" | tee -a ${VENTANA_1} ${LOG}
	echo "Ejecutando procesos iniciales ..." | tee -a ${VENTANA_2} ${LOG}
	echo "1" | tee -a ${VENTANA_3} ${LOG}
	echo "--" | tee -a ${VENTANA_4} ${LOG}
	echo 'PASO=2' > ${PASO_FILE}
;;

2)
	echo "Descargando Paquetes" | tee -a ${VENTANA_1} ${LOG}
	echo "Se descargarán una serie de paquetes necesarios (1,5GB aprox.)" | tee -a ${VENTANA_2} ${LOG}

	# Aseguramos que tenemos los repositorios correctos
	cp ${SOURCES_CANAIMA_3} ${SOURCES}
	# Estableciendo prioridades superiores para paquetes provenientes de Debian
	cp ${PREFERENCES_CANAIMA_3} ${PREFERENCES}

	# Actualizamos la lista de paquetes
	aptitude update | tee -a ${LOG} && sleep 2

	# Predescarga de todos los paquetes requeridos para la instalación
	for PAQUETE in ${TOTAL_FINAL}; do
		CONTAR=$[${CONTAR}+1]
		echo "Descargando: ${PAQUETE}" | tee -a ${VENTANA_4} ${LOG}
		aptitude download ${PAQUETE} | tee -a ${LOG}
		mv *.deb ${CACHE}
		echo "scale=6;${CONTAR}/${TOTAL_NUM}*40" | bc | tee -a ${VENTANA_3} ${LOG}
	done

	echo "Introduciendo paquetes en caché (tardará un poco) ..." | tee -a ${VENTANA_4} ${LOG}
	cp /usr/share/asistente-actualizacion/cache/*.deb /var/cache/apt/archives/
	echo "PASO=3" > ${PASO_FILE}
;;

3)
	# ------- ACTUALIZANDO CANAIMA 2.1 ------------------------------------------------------------------#
	#==================================================================================================#

	echo "Actualizando Canaima 2.1" | tee -a ${VENTANA_1} ${LOG}
	echo "Actualizando lista de paquetes ..." | tee -a ${VENTANA_2} ${LOG}
	echo "41" | tee -a ${VENTANA_3} ${LOG}
	echo "" | tee -a ${VENTANA_4} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}

	# Aseguramos que tenemos los repositorios correctos
        cp ${SOURCES_CANAIMA_2} ${SOURCES}
        # Estableciendo prioridades superiores para paquetes provenientes de Debian
        cp ${PREFERENCES_CANAIMA_2} ${PREFERENCES}

	# Actualizamos la lista de paquetes
	aptitude update | tee -a ${LOG} && sleep 2

	echo "PASO=4" > ${PASO_FILE}
;;

4)
	# Actualizamos Canaima 2.1
	echo "Descargando último software disponible para Canaima 2.1" | tee -a ${VENTANA_2} ${LOG}
	echo "42" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude ${APTITUDE_OPTIONS} full-upgrade | tee -a ${LOG} && sleep 2
	echo "PASO=5" > ${PASO_FILE}
;;

5)
	# Instalamos otro proveedor de gnome-www-browser
	echo "Instalando otro proveedor de gnome-www-browser" | tee -a ${VENTANA_2} ${LOG}
	echo "43" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install ${APTITUDE_OPTIONS} galeon | tee -a ${LOG} && sleep 2
	echo "PASO=6" > ${PASO_FILE}
;;

6)
	# Removemos la configuración vieja del GRUB
	echo "Eliminando configuración anterior del GRUB" | tee -a ${VENTANA_2} ${LOG}
	echo "44" | tee -a ${VENTANA_3} ${LOG}
	rm /etc/default/grub && sleep 2
	echo "PASO=7" > ${PASO_FILE}
;;

7)
	# Limpiando Canaima 2.1 de aplicaciones no utilizadas en 3.0
	echo "Limpiando Canaima 2.1 de aplicaciones no utilizadas en 3.0" | tee -a ${VENTANA_2} ${LOG}
	echo "45" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive apt-get purge ${APT_GET_OPTIONS} openoffice* firefox* thunderbird* canaima-instalador-vivo canaima-particionador | tee -a ${LOG} && sleep 2
	echo "PASO=8" > ${PASO_FILE}
;;

8) 
	# ------- ACTUALIZANDO COMPONENTES DE INSTALACIÓN DE LA BASE (DEBIAN SQUEEZE) ---------------------#
	#==================================================================================================#

	echo "Actualizando componentes de la instalacion de la base (squeeze)" | tee -a ${VENTANA_2} ${LOG}
	echo "46" | tee -a ${VENTANA_3} ${LOG}
        echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}

	# Aseguramos que tenemos los repositorios correctos
	cp ${SOURCES_DEBIAN} ${SOURCES}
	# Estableciendo prioridades superiores para paquetes provenientes de Debian
	cp ${PREFERENCES_DEBIAN} ${PREFERENCES}

	# Actualizamos la lista de paquetes
	aptitude update | tee -a ${LOG} && sleep 2

	echo "PASO=9" > ${PASO_FILE}
;;

9) 
	# Actualizando componentes fundamentales de instalación
	echo "Actualizando componentes fundamentales de instalación" | tee -a ${VENTANA_2} ${LOG}
	echo "47" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install ${APTITUDE_OPTIONS} aptitude apt dpkg debian-keyring locales --without-recommends | tee -a ${LOG} && sleep 2 
	echo "PASO=10" > ${PASO_FILE}
;;

10)
	# Estableciendo repositorios sólo para el sistema base
	echo "Estableciendo repositorios para el sistema base" | tee -a ${VENTANA_2} ${LOG}
	echo "48" | tee -a ${VENTANA_3} ${LOG}
        echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}

	# Aseguramos que tenemos los repositorios correctos
	cp ${SOURCES_DEBIAN} ${SOURCES}
	# Estableciendo prioridades superiores para paquetes provenientes de Debian
	cp ${PREFERENCES_DEBIAN} ${PREFERENCES}

	# Actualizamos la lista de paquetes
	aptitude update | tee -a ${LOG} && sleep 2

	echo "PASO=11" > ${PASO_FILE}
;;


11)
	# Instalando nuevo Kernel y librerías Perl
	echo "Instalando nuevo Kernel y librerías Perl" | tee -a ${VENTANA_2} ${LOG}
	echo "49" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install ${APTITUDE_OPTIONS} linux-image-2.6.32-5-$(uname -r | awk -F - '{print $3}') perl libperl5.10 | tee -a ${LOG} && sleep 2
	echo "PASO=12" > ${PASO_FILE}
;;

12)
	# Estableciendo repositorios sólo para el sistema base
	echo "Estableciendo repositorios sólo para el sistema base" | tee -a ${VENTANA_2} ${LOG}
	echo "50" | tee -a ${VENTANA_3} ${LOG}
        echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}

	# Aseguramos que tenemos los repositorios correctos
	cp ${SOURCES_DEBIAN} ${SOURCES}
	# Estableciendo prioridades superiores para paquetes provenientes de Debian
	cp ${PREFERENCES_DEBIAN} ${PREFERENCES}

	# Actualizamos la lista de paquetes
	aptitude update | tee -a ${LOG} && sleep 2

	echo "PASO=13" > ${PASO_FILE}
;;

13)
	# Actualizando gestor de dispositivos UDEV
	echo "Actualizando gestor de dispositivos UDEV" | tee -a ${VENTANA_2} ${LOG}
	echo "51" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install ${APTITUDE_OPTIONS} udev | tee -a ${LOG} && sleep 2
	echo "PASO=14" > ${PASO_FILE}
;;

14)
	# Estableciendo repositorios sólo para el sistema base
	echo "Estableciendo repositorios sólo para el sistema base" | tee -a ${VENTANA_2} ${LOG}
	echo "52" | tee -a ${VENTANA_3} ${LOG}
        echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}

	# Aseguramos que tenemos los repositorios correctos
	cp ${SOURCES_DEBIAN} ${SOURCES}
	# Estableciendo prioridades superiores para paquetes provenientes de Debian
	cp ${PREFERENCES_DEBIAN} ${PREFERENCES}

        # Actualizamos la lista de paquetes
	aptitude update | tee -a ${LOG} && sleep 2

	echo "PASO=15" > ${PASO_FILE}
;;

15)
	# Actualizando gconf2
	echo "Actualizando gconf2" | tee -a ${VENTANA_2} ${LOG}
	echo "53" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude ${APTITUDE_OPTIONS} install gconf2=2.28.1-6 libgconf2-4=2.28.1-6 gconf2-common=2.28.1-6 | tee -a ${LOG} && sleep 2
	echo "PASO=16" > ${PASO_FILE}
;;

16)
        # Estableciendo repositorios para el sistema base
        echo "Estableciendo repositorios para el sistema base" | tee -a ${VENTANA_2} ${LOG}
        echo "52" | tee -a ${VENTANA_3} ${LOG}
        echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}

	# Aseguramos que tenemos los repositorios correctos
	cp ${SOURCES_DEBIAN} ${SOURCES}
	# Estableciendo prioridades superiores para paquetes provenientes de Debian
	cp ${PREFERENCES_DEBIAN} ${PREFERENCES}

	# Actualizamos la lista de paquetes
	aptitude update | tee -a ${LOG} && sleep 2

	echo "PASO=17" > ${PASO_FILE}
;;


17)
	# Actualización parcial de la base
	echo "Actualización parcial de la base" | tee -a ${VENTANA_2} ${LOG}
	echo "56" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive apt-get ${APT_GET_OPTIONS} upgrade | tee -a ${LOG} && sleep 2
	echo "PASO=18" > ${PASO_FILE}
;;

18)
        # Estableciendo repositorios para el sistema base
        echo "Estableciendo repositorios para el sistema base" | tee -a ${VENTANA_2} ${LOG}
        echo "52" | tee -a ${VENTANA_3} ${LOG}
        echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}

	# Aseguramos que tenemos los repositorios correctos
	cp ${SOURCES_DEBIAN} ${SOURCES}
	# Estableciendo prioridades superiores para paquetes provenientes de Debian
	cp ${PREFERENCES_DEBIAN} ${PREFERENCES}

	# Actualizamos la lista de paquetes
	aptitude update | tee -a ${LOG} && sleep 2

	echo "PASO=19" > ${PASO_FILE}
;;

19)
	# Actualización total de la base
	echo "Actualización total de la base" | tee -a ${VENTANA_2} ${LOG}
	echo "57" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive apt-get ${APT_GET_OPTIONS} dist-upgrade | tee -a ${LOG} && sleep 2
	echo "PASO=18" > ${PASO_FILE}
;;

16)
        # Estableciendo repositorios para el sistema base
        echo "Estableciendo repositorios para el sistema base" | tee -a ${VENTANA_2} ${LOG}
        echo "52" | tee -a ${VENTANA_3} ${LOG}
        echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}

	# Aseguramos que tenemos los repositorios correctos
	cp ${SOURCES_DEBIAN} ${SOURCES}
	# Estableciendo prioridades superiores para paquetes provenientes de Debian
	cp ${PREFERENCES_DEBIAN} ${PREFERENCES}

	# Actualizamos la lista de paquetes
	aptitude update | tee -a ${LOG} && sleep 2

	echo "PASO=17" > ${PASO_FILE}
;;

18)
	# Actualización completa de la base
	echo "Actualización completa de la base" | tee -a ${VENTANA_2} ${LOG}
	echo "58" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude ${APTITUDE_OPTIONS} full-upgrade | tee -a ${LOG} && sleep 2
	echo "PASO=19" > ${PASO_FILE}
;;

20)
	# Estableciendo repositorios sólo para el sistema base
	echo "Estableciendo repositorios para Canaima 3.0" | tee -a ${VENTANA_2} ${LOG}
	echo "59" | tee -a ${VENTANA_3} ${LOG}
        echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}

	# Aseguramos que tenemos los repositorios correctos
	cp ${SOURCES_CANAIMA_3} ${SOURCES}
	# Estableciendo prioridades superiores para paquetes provenientes de Debian
	cp ${PREFERENCES_CANAIMA_3} ${PREFERENCES}

	# Actualizamos la lista de paquetes	
	aptitude update | tee -a ${LOG} && sleep 2

	echo "PASO=22" > ${PASO_FILE}
;;

37) 
	# Instalando llaves del repositorio Canaima
	echo "Instalando llaves del repositorio Canaima" | tee -a ${VENTANA_2} ${LOG}
	echo "75" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install ${APTITUDE_OPTIONS} canaima-llaves | tee -a ${LOG} && sleep 2
	echo "PASO=38" > ${PASO_FILE}
;;

38) 
	# Removiendo paquetes innecesarios
	echo "Removiendo paquetes innecesarios" | tee -a ${VENTANA_2} ${LOG}
	echo "76" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude purge ${APTITUDE_OPTIONS} epiphany-browser epiphany-browser-data libgraphviz4 libslab0 gtkhtml3.14 busybox-syslogd dsyslog inetutils-syslogd rsyslog socklog-run sysklogd syslog-ng libfam0c102 | tee -a ${LOG} && sleep 2
	echo "PASO=39" > ${PASO_FILE}
;;

39) 
	# Removemos configuraciones obsoletas
	echo "Removemos configuraciones obsoletas" | tee -a ${VENTANA_2} ${LOG}
	echo "77" | tee -a ${VENTANA_3} ${LOG}
	rm -rf /etc/skel/.purple/ 
	rm /etc/canaima_version 
	rm /usr/share/applications/openoffice.org-*
	echo "PASO=40" > ${PASO_FILE}
;;

40) 
	# Instalando escritorio de Canaima 3.0
	echo "Instalando escritorio de Canaima 3.0" | tee -a ${VENTANA_2} ${LOG}
	echo "78" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install ${APTITUDE_OPTIONS} canaima-escritorio-gnome | tee -a ${LOG} && sleep 2
	echo "PASO=41" > ${PASO_FILE}
;;

41) 
	# Removiendo Navegador web de transición
	echo "Removiendo Navegador web de transición" | tee -a ${VENTANA_2} ${LOG}
	echo "79" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude purge ${APTITUDE_OPTIONS} galeon | tee -a ${LOG} && sleep 2
	echo "PASO=42" > ${PASO_FILE}
;;

42) 
	# Actualización final a Canaima 3.0
	echo "Actualización final a Canaima 3.0" | tee -a ${VENTANA_2} ${LOG}
	echo "80" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude ${APTITUDE_OPTIONS} full-upgrade | tee -a ${LOG} && sleep 2
	echo "PASO=43" > ${PASO_FILE}
;;

43) 
	# Removiendo paquetes innecesarios
	echo "Removiendo paquetes innecesarios" | tee -a ${VENTANA_2} ${LOG}
	echo "81" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude purge ${APTITUDE_OPTIONS} gstreamer0.10-gnomevfs splashy canaima-accesibilidad | tee -a ${LOG} && sleep 2
	echo "PASO=44" > ${PASO_FILE}
;;

44) 
	# Actualizando a GDM3
	echo "Actualizando a GDM3" | tee -a ${VENTANA_2} ${LOG}
	echo "82" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install ${APTITUDE_OPTIONS} gdm3 | tee -a ${LOG} && sleep 2
	echo "PASO=46" > ${PASO_FILE}
;;

46)
	# Determina el Disco Duro al cual instalar y actualizar el burg
	PARTS=$( /sbin/fdisk -l | awk '/^\/dev\// {if ($2 == "*") {if ($6 == "83") { print $1 };}}' | sed 's/+//g' )
	DISCO=${PARTS:0:8}
	RESULT=$( echo ${DISCO} | sed -e 's/\//\\\//g' )
	echo "[BASH:aa-principal.sh] Se determinó que el dispositivo en donde se instalará BURG es ${RESULT}" >> ${LOG}
	sed -i "s/\/dev\/xxx/${RESULT}/g" ${DEBCONF_SEL}

	# Actualizando a BURG
	echo "Actualizando a BURG" | tee -a ${VENTANA_2} ${LOG}
	echo "83" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install ${APTITUDE_OPTIONS} burg | tee -a ${LOG} && sleep 2
	burg-install --force ${DISCO}
	echo "PASO=47" > ${PASO_FILE}
;;

47) 
	# Reinstalando Base de Canaima
	echo "Reinstalando Base de Canaima" | tee -a ${VENTANA_2} ${LOG}
	echo "84" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install ${APTITUDE_OPTIONS} canaima-base | tee -a ${LOG} && sleep 2
	DEBIAN_FRONTEND=noninteractive aptitude reinstall ${APTITUDE_OPTIONS} canaima-base | tee -a ${LOG} && sleep 2
	echo "PASO=48" > ${PASO_FILE}
;;

48) 
	# Reinstalando Estilo Visual
	echo "Finalizando rutina de actualización" | tee -a ${VENTANA_1} ${LOG}
	echo "Reinstalando Estilo Visual" | tee -a ${VENTANA_2} ${LOG}
	echo "85" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install ${APTITUDE_OPTIONS} canaima-estilo-visual | tee -a ${LOG} && sleep 2
	DEBIAN_FRONTEND=noninteractive aptitude reinstall ${APTITUDE_OPTIONS} canaima-estilo-visual | tee -a ${LOG} && sleep 2
	echo "PASO=49" > ${PASO_FILE}
;;

49) 
	# Reinstalando Escritorio
	echo "Reinstalando Escritorio" | tee -a ${VENTANA_2} ${LOG}
	echo "86" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install ${APTITUDE_OPTIONS} canaima-escritorio-gnome | tee -a ${LOG} && sleep 2
	DEBIAN_FRONTEND=noninteractive aptitude reinstall ${APTITUDE_OPTIONS} canaima-escritorio-gnome | tee -a ${LOG} && sleep 2
	echo "PASO=50" > ${PASO_FILE}
;;

50) 
	# Actualizando entradas del BURG
	echo "Actualizando entradas del BURG" | tee -a ${VENTANA_2} ${LOG}
	echo "87" | tee -a ${VENTANA_3} ${LOG}
	update-burg | tee -a ${LOG} && sleep 2
	echo "PASO=51" > ${PASO_FILE}
;;

51) 
	# Estableciendo GDM3 como Manejador de Pantalla por defecto
	echo "Estableciendo GDM3 como Manejador de Pantalla por defecto" | tee -a ${VENTANA_2} ${LOG}
	echo "88" | tee -a ${VENTANA_3} ${LOG}
	echo "/usr/sbin/gdm3" > /etc/X11/default-display-manager && sleep 2
	echo "PASO=52" > ${PASO_FILE}
;;

52) 
	# Reconfigurando el Estilo Visual
	echo "Fin de la actualización" | tee -a ${VENTANA_1} ${LOG}
	echo "Reconfigurando el Estilo Visual" | tee -a ${VENTANA_2} ${LOG}
	echo "90" | tee -a ${VENTANA_3} ${LOG}
	echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
	dpkg-reconfigure canaima-estilo-visual | tee -a ${LOG} && sleep 2
	echo "PASO=53" > ${PASO_FILE}
;;

53) 
	echo "" | tee -a ${VENTANA_2} ${LOG}
	echo "95" | tee -a ${VENTANA_3} ${LOG}
	update-burg | tee -a ${LOG} && sleep 2

	# Para cada usuario en /home/ ...
	for usuario in /home/*? ; do

		#Obteniendo sólo el nombre del usuario
		usuario_min=$(basename ${usuario})

		#Y en caso de que el usuario sea un usuario activo (existente en /etc/shadow) ...
                if [ $( grep "${usuario_min}:.*:.*:.*:.*:.*:::" /etc/shadow ) == 1 ] && [ $( grep "${usuario_min}:.*:.*:.*:.*:.*:/bin/.*sh" /etc/passwd  ) == 1 ]; then
			rm -rf ${usuario}/.gconf/
		fi
	done

	echo "¡LISTO!" | tee -a ${VENTANA_2} ${LOG}
	echo "99" | tee -a ${VENTANA_3} ${LOG}
	sleep 20
	echo 'PASO=70' > ${PASO_FILE}
	exit 0
;;

esac
done
