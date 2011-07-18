#!/bin/bash

# Eliminando kernels anteriores
for KERNEL in $( dpkg-query -W -f='${Package} ${Version}\t${Status}\n' linux-image* linux-headers* linux-source* linux-kbuild* | grep "install ok installed" | awk '{ print $1"_____"$2 }'); do
KERNEL_PAQUETE=$( echo ${KERNEL} | sed 's/_____.*//g' )
KERNEL_VERSION=${KERNEL#${KERNEL_PAQUETE}"_____"}
[ $( echo ${KERNEL_VERSION} | awk -F . '{print $3}' | sed 's/-.*//g' | sed 's/+.*//g' ) -lt 32 ] && PARA_DESINSTALAR=${PARA_DESINSTALAR}" "${KERNEL_PAQUETE}
done

( aptitude purge --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" ${PARA_DESINSTALAR} >> /var/log/salida   &&  sleep 2  ) | zenity --title="Asistente de Actualización a Canaima 3.0" --text="Limpieza final del sistema" --progress --pulsate --auto-close --width=600

aptitude purge  --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" asistente-actualizacion2
