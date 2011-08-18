#!/bin/bash

echo "Iniciando actualización" | tee -a ${LOG}

VARIABLES="/usr/share/asistente-actualizacion/conf/variables.conf"

# Cargando variables internas
. ${VARIABLES}

# Cargando paso actual del asistente
. ${PASO_FILE}

# Cargando funciones
. ${FUNCIONES}

# Organiza los paquetes
cat ${ORIGINAL} > ${TOTAL}
cat ${LOCAL} >> ${TOTAL}
TOTAL_FINAL=$( cat ${TOTAL} | sort -u )
TOTAL_NUM=$( echo ${TOTAL_FINAL} | wc -w )
DESCARGA_OFFSET="0"

# Iniciamos ventana de progreso
xterm -e "tail -f ${LOG}" &
aa-ventana &

echo "" | tee -a ${VENTANA_1} ${LOG}
echo "" | tee -a ${VENTANA_2} ${LOG}
echo "0" | tee -a ${VENTANA_3} ${LOG}
echo "" | tee -a ${VENTANA_4} ${LOG}

# Si estamos en una canaimita, desinstalamos el control parental que ralentiza el proceso
if [ $( dpkg-query -W -f='${Package}\t${Status}\n' canaima-control-parental | grep -c "install ok installed" ) == 1 ]; then
	aptitude purge --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" canaima-control-parental
fi

# Si estamos en una canaimita, desactivamos el filtrado de hosts que ralentiza el proceso
if [ -e "/etc/hosts.canaima-control-parental.backup" ]; then
	cp /etc/hosts.canaima-control-parental.backup /etc/hosts
fi

# Iteramos por los pasos
while [ ${PASO} -lt 60 ]; do

# Verificar si existe un gestor de paquetes trabajando
[ $( ps -A | grep -cw update-manager ) == 1 ] || [ $( ps -A | grep -cw apt-get ) == 1 ] || [ $( ps -A | grep -cw aptitude ) == 1 ] && ERROR_APT

# Obteniendo dirección IP
echo "Obteniendo dirección IP (dhclient)" | tee -a ${VENTANA_4} ${LOG}
/etc/init.d/networking restart | tee -a ${LOG}
dhclient | tee -a ${LOG}

# Hacemos wget de google.com para comprobar que tenemos salida a internet
echo "Comprobando conexión a internet" | tee -a ${VENTANA_4} ${LOG}
wget --timeout=10 http://www.google.com -O /tmp/index.google | tee -a ${LOG}
[ ! -s /tmp/index.google ] && ERROR_INTERNET
[ -e /tmp/index.google ] && rm /tmp/index.google

echo "Arreglando posibles paquetes rotos" | tee -a ${VENTANA_4} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
DEBIAN_FRONTEND=noninteractive apt-get --allow-unauthenticated -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" -y --force-yes -f install | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive dpkg --configure -a | tee -a ${LOG}

echo "== PASO ${PASO} ============================================" | tee -a ${LOG}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}

. ${PASO_FILE}

echo "$[${PASO}+${DESCARGA_OFFSET}]" | tee -a ${VENTANA_3} ${LOG}

case ${PASO} in

1)
	echo "Inicializando el asistente" | tee -a ${VENTANA_1} ${LOG}
	echo "Ejecutando procesos iniciales" | tee -a ${VENTANA_2} ${LOG}
	echo "Bienvenido" | tee -a ${VENTANA_4} ${LOG}

	# Ventana de bienvenida
	zenity --title="Asistente de Actualización a Canaima 3.0" --text="Este asistente se encargará de hacer los cambios necesarios para actualizar el sistema a la versión 3.0 de Canaima.\n\nAsegúrese que:\n\n* Dispone de una conexión a internet.\n\n* Su PC está conectada a una fuente de energía estable.\n\n* Tiene al menos 6GB de espacio libre en disco.\n\n* No está ejecutando un gestor o instalador de paquetes.\n\n* No tiene ningún documento importante abierto.\n\n* Dispone de al menos 2 horas libres de su tiempo.\n\nSi por alguna razón el proceso se detiene, puede reanudarlo desde el punto en que se interrumpió haciendo click en Aplicaciones > Herramientas del Sistema > Actualizador a Canaima 3.0.\n\n¿Desea continuar con la actualización?" --question --width=600
	ESTADO=$?
	[ ${ESTADO} == 1 ] && ERROR_CRITICO

	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

2)
	echo "Actualizando repositorios para Canaima 3.0" | tee -a ${VENTANA_2} ${LOG}
	echo "" | tee -a ${VENTANA_4} ${LOG}

	# Aseguramos que tenemos los repositorios correctos
	cp ${SOURCES_CANAIMA_3} ${SOURCES}
	# Estableciendo prioridades superiores para paquetes provenientes de Debian
	cp ${PREFERENCES_CANAIMA_3} ${PREFERENCES}

	# Actualizamos la lista de paquetes
	aptitude update | tee -a ${LOG}
        ESTADO=$?

	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

3)
	echo "Se descargarán una serie de paquetes necesarios (1,5GB aprox.)" | tee -a ${VENTANA_2} ${LOG}
	echo "" | tee -a ${VENTANA_4} ${LOG}
	DESCARGA_OFFSET="58"

	# Predescarga de todos los paquetes requeridos para la instalación
	for PAQUETE in ${TOTAL_FINAL}; do
		CONTAR=$[${CONTAR}+1]
		echo "Descargando: ${PAQUETE}" | tee -a ${VENTANA_4} ${LOG}
		cd ${CACHE}
		aptitude download ${PAQUETE} | tee -a ${LOG}
		echo "scale=6;${CONTAR}/${TOTAL_NUM}*${DESCARGA_OFFSET}+${PASO}" | bc | tee -a ${VENTANA_3} ${LOG}
	done
        ESTADO=$?

	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

4)
	echo "Introduciendo paquetes en caché (tardará un poco) ..." | tee -a ${VENTANA_4} ${LOG}
	cp /usr/share/asistente-actualizacion/cache/*.deb /var/cache/apt/archives/
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

5)
	# ------- ACTUALIZANDO CANAIMA 2.1 ------------------------------------------------------------------#
	#==================================================================================================#

	echo "Actualizando Canaima 2.1" | tee -a ${VENTANA_1} ${LOG}
	echo "Actualizando lista de paquetes" | tee -a ${VENTANA_2} ${LOG}
	echo "" | tee -a ${VENTANA_4} ${LOG}

	# Aseguramos que tenemos los repositorios correctos
	cp ${SOURCES_CANAIMA_2} ${SOURCES}
	# Estableciendo prioridades superiores para paquetes provenientes de Debian
	cp ${PREFERENCES_CANAIMA_2} ${PREFERENCES}

	# Actualizamos la lista de paquetes
	aptitude update | tee -a ${LOG}
        ESTADO=$?

	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

6)
	# Actualizamos Canaima 2.1
	echo "Descargando último software disponible para Canaima 2.1" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" full-upgrade | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

7)
	# Instalamos otro proveedor de gnome-www-browser
	echo "Instalando otro proveedor de gnome-www-browser" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" galeon | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

8)
	# Removemos la configuración vieja del GRUB
	echo "Eliminando configuración anterior del GRUB" | tee -a ${VENTANA_2} ${LOG}
	rm /etc/default/grub
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

9)
	# Limpiando Canaima 2.1 de aplicaciones no utilizadas en 3.0
	echo "Limpiando Canaima 2.1 de aplicaciones no utilizadas en 3.0" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude purge --assume-yes ~nopenoffice ~nfirefox ~nthunderbird ~ncanaima-instalador-vivo ~ncanaima-particionador | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

10) 
	# ------- ACTUALIZANDO COMPONENTES DE INSTALACIÓN DE LA BASE (DEBIAN SQUEEZE) ---------------------#
	#==================================================================================================#

	echo "Actualizando componentes de la base (Debian Squeeze)" | tee -a ${VENTANA_1} ${LOG}
	echo "Estableciendo repositorios para el sistema base" | tee -a ${VENTANA_2} ${LOG}

	# Aseguramos que tenemos los repositorios correctos
	cp ${SOURCES_DEBIAN} ${SOURCES}
	# Estableciendo prioridades superiores para paquetes provenientes de Debian
	cp ${PREFERENCES_DEBIAN} ${PREFERENCES}

	# Actualizamos la lista de paquetes
	aptitude update | tee -a ${LOG}
        ESTADO=$?

	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

11) 
	# Actualizando componentes fundamentales de instalación
	echo "Actualizando componentes fundamentales de instalación" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" aptitude apt dpkg debian-keyring locales --without-recommends | tee -a ${LOG} 
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

12)
	# Estableciendo repositorios sólo para el sistema base
	echo "Estableciendo repositorios para el sistema base" | tee -a ${VENTANA_2} ${LOG}

	# Aseguramos que tenemos los repositorios correctos
	cp ${SOURCES_DEBIAN} ${SOURCES}
	# Estableciendo prioridades superiores para paquetes provenientes de Debian
	cp ${PREFERENCES_DEBIAN} ${PREFERENCES}

	# Actualizamos la lista de paquetes
	aptitude update | tee -a ${LOG}
        ESTADO=$?

	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;


13)
	# Instalando nuevo Kernel y librerías Perl
	echo "Instalando nuevo Núcleo y librerías Perl" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" linux-image-2.6.32-5-$(uname -r | awk -F - '{print $3}') perl libperl5.10 | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

14)
	# Estableciendo repositorios sólo para el sistema base
	echo "Estableciendo repositorios para el sistema base" | tee -a ${VENTANA_2} ${LOG}

	# Aseguramos que tenemos los repositorios correctos
	cp ${SOURCES_DEBIAN} ${SOURCES}
	# Estableciendo prioridades superiores para paquetes provenientes de Debian
	cp ${PREFERENCES_DEBIAN} ${PREFERENCES}

	# Actualizamos la lista de paquetes
	aptitude update | tee -a ${LOG}
        ESTADO=$?

	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

15)
	# Actualizando gestor de dispositivos UDEV
	echo "Actualizando gestor de dispositivos udev" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" udev | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

16)
	# Estableciendo repositorios sólo para el sistema base
	echo "Estableciendo repositorios para el sistema base" | tee -a ${VENTANA_2} ${LOG}

	# Aseguramos que tenemos los repositorios correctos
	cp ${SOURCES_DEBIAN} ${SOURCES}
	# Estableciendo prioridades superiores para paquetes provenientes de Debian
	cp ${PREFERENCES_DEBIAN} ${PREFERENCES}

	# Actualizamos la lista de paquetes
	aptitude update | tee -a ${LOG}
        ESTADO=$?

	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

17)
	# Actualizando gconf2
	echo "Actualizando gconf2" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" install gconf2=2.28.1-6 libgconf2-4=2.28.1-6 gconf2-common=2.28.1-6 | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

18)
	# Estableciendo repositorios para el sistema base
	echo "Estableciendo repositorios para el sistema base" | tee -a ${VENTANA_2} ${LOG}

	# Aseguramos que tenemos los repositorios correctos
	cp ${SOURCES_DEBIAN} ${SOURCES}
	# Estableciendo prioridades superiores para paquetes provenientes de Debian
	cp ${PREFERENCES_DEBIAN} ${PREFERENCES}

	# Actualizamos la lista de paquetes
	aptitude update | tee -a ${LOG}
        ESTADO=$?

	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;


19)
	# Copia del caché
	echo "Regenerando el caché de paquetes" | tee -a ${VENTANA_2} ${LOG}
	cp /usr/share/asistente-actualizacion/cache/*.deb /var/cache/apt/archives/
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

20)
	# Actualización parcial de la base
	echo "Primera fase de actualización de todas las aplicaciones" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive apt-get --allow-unauthenticated -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" -y --force-yes upgrade | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

21)
	# Estableciendo repositorios para el sistema base
	echo "Estableciendo repositorios para el sistema base" | tee -a ${VENTANA_2} ${LOG}

	# Aseguramos que tenemos los repositorios correctos
	cp ${SOURCES_DEBIAN} ${SOURCES}
	# Estableciendo prioridades superiores para paquetes provenientes de Debian
	cp ${PREFERENCES_DEBIAN} ${PREFERENCES}

	# Actualizamos la lista de paquetes
	aptitude update | tee -a ${LOG}
        ESTADO=$?

	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

22)
	# Actualización total de la base
	echo "Segunda fase de actualización de todas las aplicaciones" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive apt-get --allow-unauthenticated -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" -y --force-yes dist-upgrade | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

23)
	# Estableciendo repositorios para el sistema base
	echo "Estableciendo repositorios para el sistema base" | tee -a ${VENTANA_2} ${LOG}

	# Aseguramos que tenemos los repositorios correctos
	cp ${SOURCES_DEBIAN} ${SOURCES}
	# Estableciendo prioridades superiores para paquetes provenientes de Debian
	cp ${PREFERENCES_DEBIAN} ${PREFERENCES}

	# Actualizamos la lista de paquetes
	aptitude update | tee -a ${LOG}
        ESTADO=$?

	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

24)
	# Actualización completa de la base
	echo "Tercera fase de actualización de todas las aplicaciones" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" full-upgrade | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

25)
	# ------- ACTUALIZANDO COMPONENTES DE CANAIMA 3.0 -------------------------------------------------#
	#==================================================================================================#

	# Estableciendo repositorios para Canaima 3.0
	echo "Actualizando a Canaima 3.0" | tee -a ${VENTANA_1} ${LOG}
	echo "Estableciendo repositorios para Canaima 3.0" | tee -a ${VENTANA_2} ${LOG}

	# Aseguramos que tenemos los repositorios correctos
	cp ${SOURCES_CANAIMA_3} ${SOURCES}
	# Estableciendo prioridades superiores para paquetes provenientes de Debian
	cp ${PREFERENCES_CANAIMA_3} ${PREFERENCES}

	# Actualizamos la lista de paquetes	
	aptitude update | tee -a ${LOG}
        ESTADO=$?

	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

26) 
	# Instalando llaves del repositorio Canaima
	echo "Instalando llaves del repositorio de Canaima 3.0" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" canaima-llaves | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

27) 
	# Removiendo paquetes innecesarios
	echo "Removiendo paquetes innecesarios" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude purge --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" epiphany-browser epiphany-browser-data libgraphviz4 libslab0 gtkhtml3.14 busybox-syslogd dsyslog inetutils-syslogd rsyslog socklog-run sysklogd syslog-ng libfam0c102 | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

28) 
	# Removemos configuraciones obsoletas
	echo "Removiendo configuraciones obsoletas" | tee -a ${VENTANA_2} ${LOG}
	rm -rf /etc/skel/.purple/ 
	rm /etc/canaima_version 
	rm /usr/share/applications/openoffice.org-*
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

29) 
	# Instalando escritorio de Canaima 3.0
	echo "Instalando escritorio de Canaima 3.0" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" canaima-escritorio-gnome | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

30) 
	# Removiendo Navegador web de transición
	echo "Removiendo proveedor de gnome-www-browser galeon" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude purge --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" galeon | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

31) 
	# Actualización final a Canaima 3.0
	echo "Sincronizando aplicaciones con el Repositorio de Canaima 3.0" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" full-upgrade | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

32)
	# Removiendo paquetes innecesarios
	echo "Removiendo paquetes innecesarios" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude purge --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" gstreamer0.10-gnomevfs splashy canaima-accesibilidad | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

33)
	# Actualizando a GDM3
	echo "Actualizando el gestor de escritorios (gdm -> gdm3)" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" gdm3 | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

34)
	# Determina el Disco Duro al cual instalar y actualizar el burg
	PARTS=$( /sbin/fdisk -l | awk '/^\/dev\// {if ($2 == "*") {if ($6 == "83") { print $1 };}}' | sed 's/+//g' )
	DISCO=${PARTS:0:8}
	RESULT=$( echo ${DISCO} | sed -e 's/\//\\\//g' )
	echo "[BASH:aa-principal.sh] Se determinó que el dispositivo en donde se instalará BURG es ${RESULT}" | tee -a ${LOG}
	sed -i "s/\/dev\/xxx/${RESULT}/g" ${DEBCONF_SEL}
	debconf-set-selections ${DEBCONF_SEL}

	# Actualizando a BURG
	echo "Actualizando el gestor de arranque (grub -> burg)" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" burg | tee -a ${LOG}
	burg-install --force ${DISCO}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

35)
	# Instalando Base de Canaima
	echo "Fase final de la actualizacion" | tee -a ${VENTANA_2} ${LOG}
	echo "Verificando la instalación de canaima-base" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" canaima-base | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude reinstall --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" canaima-base | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

36)
	# Reinstalando Estilo Visual
	echo "Verificando la instalación de canaima-estilo-visual" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" canaima-estilo-visual | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude reinstall --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" canaima-estilo-visual | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

37)
	# Reinstalando Escritorio
	echo "Verificando la instalación de canaima-escritorio-gnome" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" canaima-escritorio-gnome | tee -a ${LOG}
	DEBIAN_FRONTEND=noninteractive aptitude reinstall --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -o DPkg::Options::="--force-overwrite" canaima-escritorio-gnome | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

38)
	# Actualizando entradas del BURG
	echo "Actualizando sistemas operativos en el gestor de arranque" | tee -a ${VENTANA_2} ${LOG}
	update-burg | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

39)
	# Estableciendo GDM3 como Manejador de Pantalla por defecto
	echo "Estableciendo gdm3 como gestor de escritorios por defecto" | tee -a ${VENTANA_2} ${LOG}
	echo "/usr/sbin/gdm3" > /etc/X11/default-display-manager
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

40)
	# Reconfigurando el Estilo Visual
	echo "Verificando la instalación de canaima-estilo-visual" | tee -a ${VENTANA_2} ${LOG}
	DEBIAN_FRONTEND=noninteractive dpkg-reconfigure canaima-estilo-visual | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

41)
	# Actualizando entradas del BURG
	echo "Actualizando sistemas operativos en el gestor de arranque" | tee -a ${VENTANA_2} ${LOG}
	update-burg | tee -a ${LOG}
        ESTADO=$?
	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

42) 
	echo "Aplicando configuraciones por defecto para Canaima 3.0" | tee -a ${VENTANA_2} ${LOG}

	# Para cada usuario en /home/ ...
	for HOME_U in /home/*?; do
		# Obteniendo sólo el nombre del usuario
		USUARIO=$( basename ${HOME_U} )
		# Y en caso de que el usuario sea un usuario activo (existente en /etc/shadow) ...
		if [ $( grep -c "${USUARIO}:.*:.*:.*:.*:.*:::" /etc/shadow ) == 1 ] \
		&& [ $( grep -c "${USUARIO}:.*:.*:.*:.*:.*:/bin/.*sh" /etc/passwd ) == 1 ] \
		&& [ -d ${HOME_U} ] \
		&& [ -d ${HOME_U}/.gconf ]; then
			rm -rf ${HOME_U}/.gconf
		fi
	done
        ESTADO=$?

	[ ${ESTADO} == 0 ] && echo "PASO=$[${PASO}+1]" > ${PASO_FILE}
	[ ${ESTADO} != 0 ] && ERROR_INESPERADO
;;

43) 
	echo "Finalizando" | tee -a ${VENTANA_2} ${LOG}
	echo "Reiniciando automáticamente en 20 segundos" | tee -a ${VENTANA_4} ${LOG}
	echo "PASO=70" > ${PASO_FILE}
	sleep 20
	reboot
	exit 0
;;

esac
done
