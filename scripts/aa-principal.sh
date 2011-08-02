#!/bin/bash

echo "[BASH:aa-principal.sh] Iniciando actualización" >> ${LOG}

VARIABLES="/usr/share/asistente-actualizacion/conf/variables.conf"

# Cargando variables internas
. ${VARIABLES}

# Cargando paso actual del asistente
. ${PASO_FILE}

# Organiza los paquetes
TOTAL_NICE=$( cat ${TOTAL} | awk 'BEGIN {OFS = "\n"; ORS = " " }; {print $1}' )
LOCAL_NICE=$( cat ${LOCAL} | awk 'BEGIN {OFS = "\n"; ORS = " " }; {print $1}' )
TOTAL_FINAL=${TOTAL_NICE}" "${LOCAL_NICE}
TOTAL_NUM=$( echo $TOTAL_FINAL | wc -w )

# Iniciamos ventana de progreso
xterm -e "tail -f ${LOG}" &
aa-ventana &

# Iteramos por los pasos
while [ ${PASO} -lt 60 ]; do

# Verificar si existe un gestor de paquetes
[ $( ps -A | grep -cw update-manager ) == 1 ] || [ $( ps -A | grep -cw apt-get ) == 1 ] || [ $( ps -A | grep -cw aptitude ) == 1 ] &&  zenity --title="Asistente de Actualización a Canaima 3.0" --text="¡Existe un gestor de paquetes trabajando! No podemos continuar." --error --width=600 && pkill aa-principal && pkill xterm && pkill aa-ventana && exit 1

(wget -q --tries=10 --timeout=5 http://www.google.com -O /tmp/index.google) | zenity --progress --pulsate --width=600 --height=80 --title="Instalación de Aplicaciones Extendidas" --text "Verificando conexión a Internet ..." --auto-close

if [ ! -s /tmp/index.google ];then
       zenity --text="¡Ooops! Parece que no tienes conexión a internet." --title="ERROR" --error --width=600 && pkill aa-principal && pkill xterm && pkill aa-ventana && exit 1
fi


echo "[BASH:aa-principal.sh] PASO ${PASO} ============================================" >> ${LOG}

. ${PASO_FILE}

case ${PASO} in

1)
# Ventana de bienvenida
zenity --title="Asistente de Actualización a Canaima 3.0" --text="Este asistente se encargará de hacer los cambios necesarios para actualizar el sistema a la versión 3.0 de Canaima.\n\nAsegúrese que:\n\n* Dispone de conexión a internet.\n\n* Su PC está conectada a una fuente de energía estable.\n\n* Tiene al menos 6GB de espacio libre en disco.\n\n* No está ejecutando un gestor o instalador de paquetes.\n\n* No tiene ningún documento importante abierto.\n\n* Usted dispone de 2 horas libres de su tiempo.\n\n¿Desea continuar con la actualización?" --question --width=600
[ $? == 1 ] && pkill aa-principal && pkill xterm && pkill aa-ventana && exit 1
echo "Inicializando el Asistente" | tee -a ${VENTANA_1} ${LOG}
echo "Ejecutando procesos iniciales ..." | tee -a ${VENTANA_2} ${LOG}
echo "1" | tee -a ${VENTANA_3} ${LOG}
echo "--" | tee -a ${VENTANA_4} ${LOG}
echo 'PASO=2' > ${PASO_FILE}
;;

2)

echo "Descargando paquetes" | tee -a ${VENTANA_1} ${LOG}
echo "Se descargarán una serie de paquetes necesarios para la actualización del sistema (1.5G aprox.)" | tee -a ${VENTANA_2} ${LOG}

# Aseguramos que tenemos los repositorios correctos
cp ${SOURCES_DEBIAN} ${SOURCES}

# Estableciendo prioridades superiores para paquetes provenientes de Debian
cp ${PREFERENCES_DEBIAN} ${PREFERENCES}

aptitude update | tee -a ${LOG} && sleep 2

# Predescarga de todos los paquetes requeridos para la instalación
for PAQUETE in ${TOTAL_FINAL}; do
CONTAR=$[${CONTAR}+1]
echo "Descargando: ${PAQUETE}" | tee -a ${VENTANA_4} ${LOG}
aptitude download ${PAQUETE} | tee -a ${LOG}
mv *.deb ${CACHE}
echo "scale=6;${CONTAR}/${TOTAL_NUM}*40" | bc | tee -a ${VENTANA_3} ${LOG}
done
cp /usr/share/asistente-actualizacion/cache/*.deb /var/cache/apt/archives/
echo "PASO=3" > ${PASO_FILE}
;;

3)

# ------- PREPARANDO CANAIMA 2.1 ------------------------------------------------------------------#
#==================================================================================================#

# Aseguramos que tenemos los repositorios correctos
cp ${SOURCES_CANAIMA_2} ${SOURCES}

# Estableciendo prioridades superiores para paquetes provenientes de Debian
cp ${PREFERENCES_CANAIMA_2} ${PREFERENCES}

# Actualizamos la lista de paquetes
echo "Ejecutando rutina de actualizacion" | tee -a ${VENTANA_1} ${LOG}
echo "Actualizando lista de paquetes ..." | tee -a ${VENTANA_2} ${LOG}
echo "41" | tee -a ${VENTANA_3} ${LOG}
echo "" | tee -a ${VENTANA_4} ${LOG}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
aptitude update | tee -a ${LOG} && sleep 2
echo "PASO=4" > ${PASO_FILE}
;;

4)
echo "42" | tee -a ${VENTANA_3} ${LOG}
echo "PASO=5" > ${PASO_FILE}
;;

5)
# Actualizamos Canaima 2.1
echo "Descargando último software disponible para Canaima 2.1" | tee -a ${VENTANA_2} ${LOG}
echo "43" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive aptitude --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" full-upgrade | tee -a ${LOG} && sleep 2
echo "PASO=6" > ${PASO_FILE}
;;

6)
# Instalamos otro proveedor de gnome-www-browser
echo "Instacion de otro proveedor de gnome-www-browser" | tee -a ${VENTANA_2} ${LOG}
echo "44" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" galeon | tee -a ${LOG} && sleep 2
echo "PASO=7" > ${PASO_FILE}
;;

7)
# Removemos la configuración vieja del GRUB
echo "Eliminando configuracion anterior del GRUB" | tee -a ${VENTANA_2} ${LOG}
echo "45" | tee -a ${VENTANA_3} ${LOG}
rm /etc/default/grub && sleep 2
echo "PASO=8" > ${PASO_FILE}
;;

8)
# Limpiando Canaima 2.1 de aplicaciones no utilizadas en 3.0
echo "Limpiando Canaima 2.1 de aplicaciones no utilizadas en 3.0" | tee -a ${VENTANA_2} ${LOG}
echo "46" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive apt-get purge --force-yes -y openoffice* firefox* thunderbird* canaima-instalador-vivo canaima-particionador | tee -a ${LOG} && sleep 2
echo "PASO=9" > ${PASO_FILE}
;;

9) 
echo "47" | tee -a ${VENTANA_3} ${LOG}
echo "PASO=10" > ${PASO_FILE}
;;

10) 

# ------- ACTUALIZANDO COMPONENTES DE INSTALACIÓN DE LA BASE (DEBIAN SQUEEZE) ---------------------#
#==================================================================================================#

echo "Actualizando componentes de la instalacion de la base (squeeze)" | tee -a ${VENTANA_2} ${LOG}
echo "48" | tee -a ${VENTANA_3} ${LOG}

# Aseguramos que tenemos los repositorios correctos
cp ${SOURCES_DEBIAN} ${SOURCES}

# Estableciendo prioridades superiores para paquetes provenientes de Debian
cp ${PREFERENCES_DEBIAN} ${PREFERENCES}

echo "PASO=11" > ${PASO_FILE}
;;

11) 
# Actualizamos la lista de paquetes
echo "Actualizamos la lista de paquetes" | tee -a ${VENTANA_2} ${LOG}
echo "49" | tee -a ${VENTANA_3} ${LOG}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
aptitude update | tee -a ${LOG} && sleep 2
echo "PASO=12" > ${PASO_FILE}
;;

12) 
echo "50" | tee -a ${VENTANA_3} ${LOG}
echo "PASO=13" > ${PASO_FILE}
;;

13) 
# Actualizando componentes fundamentales de instalación
echo "Actualizando componentes fundamentales de instalación" | tee -a ${VENTANA_2} ${LOG}
echo "51" | tee -a ${VENTANA_3} ${LOG}
cp "${CACHE}*.deb" ${CACHE_APT}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" aptitude apt dpkg debian-keyring locales --without-recommends | tee -a ${LOG} && sleep 2 
echo "PASO=14" > ${PASO_FILE}
;;

14) 
# Arreglando paquetes en mal estado
echo "Arreglando paquetes en mal estado" | tee -a ${VENTANA_2} ${LOG}
echo "52" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive apt-get --allow-unauthenticated -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -y --force-yes -f install | tee -a ${LOG} && sleep 2
echo "PASO=15" > ${PASO_FILE}
;;

15) 
# Instalando nuevo Kernel y librerías Perl
echo "Instalando nuevo Kernel y librerías Perl" | tee -a ${VENTANA_2} ${LOG}
echo "53" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" linux-image-2.6.32-5-686 perl libperl5.10 | tee -a ${LOG} && sleep 2
echo "PASO=16" > ${PASO_FILE}
;;

16) 
# Estableciendo repositorios sólo para el sistema base
echo "Estableciendo repositorios sólo para el sistema base" | tee -a ${VENTANA_2} ${LOG}
echo "54" | tee -a ${VENTANA_3} ${LOG}
# Aseguramos que tenemos los repositorios correctos
cp ${SOURCES_DEBIAN} ${SOURCES}

# Estableciendo prioridades superiores para paquetes provenientes de Debian
cp ${PREFERENCES_DEBIAN} ${PREFERENCES}

echo "PASO=17" > ${PASO_FILE}
;;

17) 
# Actualizamos la lista de paquetes
echo "Actualizamos la lista de paquetes" | tee -a ${VENTANA_2} ${LOG}
echo "56" | tee -a ${VENTANA_3} ${LOG}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
aptitude update | tee -a ${LOG} && sleep 2
echo "PASO=18" > ${PASO_FILE}
;;

18) 
echo "57" | tee -a ${VENTANA_3} ${LOG}
echo "PASO=19" > ${PASO_FILE}
;;

19) 
# Arreglando paquetes en mal estado
echo "Arreglando paquetes en mal estado" | tee -a ${VENTANA_2} ${LOG}
echo "58" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
cp "${CACHE}*.deb" ${CACHE_APT}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive apt-get --allow-unauthenticated -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -y --force-yes -f install | tee -a ${LOG} && sleep 2
echo "PASO=20" > ${PASO_FILE}
;;

20) 
# Actualizando gestor de dispositivos UDEV
echo "Actualizando gestor de dispositivos UDEV" | tee -a ${VENTANA_2} ${LOG}
echo "59" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
cp "${CACHE}*.deb" ${CACHE_APT}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" udev | tee -a ${LOG} && sleep 2
echo "PASO=21" > ${PASO_FILE}
;;

21) 
# Estableciendo repositorios sólo para el sistema base
echo "Estableciendo repositorios sólo para el sistema base" | tee -a ${VENTANA_2} ${LOG}
echo "60" | tee -a ${VENTANA_3} ${LOG}
# Aseguramos que tenemos los repositorios correctos
cp ${SOURCES_DEBIAN} ${SOURCES}

# Estableciendo prioridades superiores para paquetes provenientes de Debian
cp ${PREFERENCES_DEBIAN} ${PREFERENCES}

echo "PASO=22" > ${PASO_FILE}
;;

22) 
echo "61" | tee -a ${VENTANA_3} ${LOG}
echo "PASO=23" > ${PASO_FILE}
;;

23) 
# Actualizamos la lista de paquetes
echo "Actualizamos la lista de paquetes" | tee -a ${VENTANA_2} ${LOG}
echo "62" | tee -a ${VENTANA_3} ${LOG}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
aptitude update | tee -a ${LOG} && sleep 2
echo "PASO=24" > ${PASO_FILE}
;;

24) 
echo "63" | tee -a ${VENTANA_3} ${LOG}
echo "PASO=25" > ${PASO_FILE}
;;

25) 
# Arreglando paquetes en mal estado
echo "Arreglando paquetes en mal estado" | tee -a ${VENTANA_2} ${LOG}
echo "64" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
cp "${CACHE}*.deb" ${CACHE_APT}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive apt-get --allow-unauthenticated -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -y --force-yes -f install | tee -a ${LOG} && sleep 2
echo "PASO=26" > ${PASO_FILE}
;;

26) 
# Actualizando gconf2
echo "Actualizando gconf2" | tee -a ${VENTANA_2} ${LOG}
echo "65" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive aptitude --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" install gconf2=2.28.1-6 libgconf2-4=2.28.1-6 gconf2-common=2.28.1-6 | tee -a ${LOG} && sleep 2
echo "PASO=27" > ${PASO_FILE}
;;

27) 
# Actualización de componentes adicionales instalados por el usuario (no incluidos en canaima 2.1)
echo "Actualización de componentes adicionales instalados por el usuario" | tee -a ${VENTANA_2} ${LOG}
echo "66" | tee -a ${VENTANA_3} ${LOG}
cp "${CACHE}*.deb" ${CACHE_APT}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
echo "PASO=28" > ${PASO_FILE}
;;

28)
# Actualización parcial de la base
echo "Actualización parcial de la base" | tee -a ${VENTANA_2} ${LOG}
echo "67" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
cp "${CACHE}*.deb" ${CACHE_APT}
DEBIAN_FRONTEND=noninteractive apt-get --allow-unauthenticated -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" --force-yes -y upgrade | tee -a ${LOG} && sleep 2
echo "PASO=29" > ${PASO_FILE}
;;

29) 
# Actualización total de la base
echo "Actualización total de la base" | tee -a ${VENTANA_2} ${LOG}
echo "68" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
cp "${CACHE}*.deb" ${CACHE_APT}
DEBIAN_FRONTEND=noninteractive apt-get --allow-unauthenticated -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" --force-yes -y dist-upgrade | tee -a ${LOG} && sleep 2
echo "PASO=30" > ${PASO_FILE}
;;

30) 
# Actualización completa de la base
echo "Actualización completa de la base" | tee -a ${VENTANA_2} ${LOG}
echo "69" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
cp "${CACHE}*.deb" ${CACHE_APT}
DEBIAN_FRONTEND=noninteractive aptitude --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" full-upgrade | tee -a ${LOG} && sleep 2
echo "PASO=31" > ${PASO_FILE}
;;

31) 
# Estableciendo repositorios sólo para el sistema base
echo "Estableciendo repositorios sólo para el sistema base" | tee -a ${VENTANA_2} ${LOG}
echo "70" | tee -a ${VENTANA_3} ${LOG}
# Aseguramos que tenemos los repositorios correctos
cp ${SOURCES_CANAIMA_3} ${SOURCES}
echo "PASO=32" > ${PASO_FILE}
;;

32) 
# Estableciendo prioridades superiores para paquetes provenientes de Debian
echo "Estableciendo prioridades superiores para paquetes provenientes de Debian" | tee -a ${VENTANA_2} ${LOG}
echo "71" | tee -a ${VENTANA_3} ${LOG}
# Estableciendo prioridades superiores para paquetes provenientes de Debian
cp ${PREFERENCES_CANAIMA_3} ${PREFERENCES}
echo "PASO=33" > ${PASO_FILE}
;;

33) 
# Actualizamos la lista de paquetes
echo "Actualizamos la lista de paquetes" | tee -a ${VENTANA_2} ${LOG}
echo "72" | tee -a ${VENTANA_3} ${LOG}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
aptitude update | tee -a ${LOG} && sleep 2
echo "PASO=34" > ${PASO_FILE}
;;

34) 
echo "73" | tee -a ${VENTANA_3} ${LOG}
echo "PASO=36" > ${PASO_FILE}
;;

36) 
# Arreglando paquetes en mal estado
echo "Arreglando paquetes en mal estado" | tee -a ${VENTANA_2} ${LOG}
echo "74" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive apt-get --allow-unauthenticated -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" -y --force-yes -f install | tee -a ${LOG} && sleep 2
echo "PASO=37" > ${PASO_FILE}
;;

37) 
# Instalando llaves del repositorio Canaima
echo "Instalando llaves del repositorio Canaima" | tee -a ${VENTANA_2} ${LOG}
echo "75" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" canaima-llaves | tee -a ${LOG} && sleep 2
echo "PASO=38" > ${PASO_FILE}
;;

38) 
# Removiendo paquetes innecesarios
echo "Removiendo paquetes innecesarios" | tee -a ${VENTANA_2} ${LOG}
echo "76" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive aptitude purge --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" epiphany-browser epiphany-browser-data libgraphviz4 libslab0 gtkhtml3.14 busybox-syslogd dsyslog inetutils-syslogd rsyslog socklog-run sysklogd syslog-ng libfam0c102 | tee -a ${LOG} && sleep 2
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
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" canaima-escritorio-gnome | tee -a ${LOG} && sleep 2
echo "PASO=41" > ${PASO_FILE}
;;

41) 
# Removiendo Navegador web de transición
echo "Removiendo Navegador web de transición" | tee -a ${VENTANA_2} ${LOG}
echo "79" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive aptitude purge --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" galeon | tee -a ${LOG} && sleep 2
echo "PASO=42" > ${PASO_FILE}
;;

42) 
# Actualización final a Canaima 3.0
echo "Actualización final a Canaima 3.0" | tee -a ${VENTANA_2} ${LOG}
echo "80" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive aptitude --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" full-upgrade | tee -a ${LOG} && sleep 2
echo "PASO=43" > ${PASO_FILE}
;;

43) 
# Removiendo paquetes innecesarios
echo "Removiendo paquetes innecesarios" | tee -a ${VENTANA_2} ${LOG}
echo "81" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive aptitude purge --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" gstreamer0.10-gnomevfs splashy canaima-accesibilidad | tee -a ${LOG} && sleep 2
echo "PASO=44" > ${PASO_FILE}
;;

44) 
# Actualizando a GDM3
echo "Actualizando a GDM3" | tee -a ${VENTANA_2} ${LOG}
echo "82" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" gdm3 | tee -a ${LOG} && sleep 2
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
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" burg | tee -a ${LOG} && sleep 2
burg-install --force ${DISCO}
echo "PASO=47" > ${PASO_FILE}
;;

47) 
# Reinstalando Base de Canaima
echo "Reinstalando Base de Canaima" | tee -a ${VENTANA_2} ${LOG}
echo "84" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" canaima-base | tee -a ${LOG} && sleep 2
DEBIAN_FRONTEND=noninteractive aptitude reinstall --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" canaima-base | tee -a ${LOG} && sleep 2
echo "PASO=48" > ${PASO_FILE}
;;

48) 
# Reinstalando Estilo Visual
echo "Finalizando rutina de actualización" | tee -a ${VENTANA_1} ${LOG}
echo "Reinstalando Estilo Visual" | tee -a ${VENTANA_2} ${LOG}
echo "85" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" canaima-estilo-visual | tee -a ${LOG} && sleep 2
DEBIAN_FRONTEND=noninteractive aptitude reinstall --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" canaima-estilo-visual | tee -a ${LOG} && sleep 2
echo "PASO=49" > ${PASO_FILE}
;;

49) 
# Reinstalando Escritorio
echo "Reinstalando Escritorio" | tee -a ${VENTANA_2} ${LOG}
echo "86" | tee -a ${VENTANA_3} ${LOG}
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" canaima-escritorio-gnome | tee -a ${LOG} && sleep 2
DEBIAN_FRONTEND=noninteractive aptitude reinstall --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" -o DPkg::Options::="--force-confnew" canaima-escritorio-gnome | tee -a ${LOG} && sleep 2
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
debconf-set-selections ${DEBCONF_SEL}
echo "PAQUETES EN CACHÉ: $( ls ${CACHE} | wc -l )" | tee -a ${LOG}
dpkg-reconfigure canaima-estilo-visual | tee -a ${LOG} && sleep 2
echo "PASO=53" > ${PASO_FILE}
;;

53) 
echo "" | tee -a ${VENTANA_2} ${LOG}
echo "95" | tee -a ${VENTANA_3} ${LOG}
update-burg

		# Para cada usuario en /home/ ...
		for usuario in /home/*? ; do

			#Obteniendo sólo el nombre del usuario
			usuario_min=$(basename ${usuario})

			#Y en caso de que el usuario sea un usuario activo (existente en /etc/shadow) ...
			case  $(grep "${usuario_min}:.*:.*:.*:.*:.*:::" /etc/shadow) in

				'')
				#No hace nada si no se encuentra en /etc/shadow
				;;

				*)

					# Elimina configuracion de gconf previo
					rm -rf ${usuario}/.gconf/
				;;
			esac

		done
echo "Reiniciando el sistema en 20 segundos..." | tee -a ${VENTANA_2} ${LOG}
echo "99" | tee -a ${VENTANA_3} ${LOG}
sleep 20
echo 'PASO=70' > ${PASO_FILE}
reboot
exit 0
;;
esac
done
