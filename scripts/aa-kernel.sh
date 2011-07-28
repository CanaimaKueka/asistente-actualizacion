#!/bin/bash

VARIABLES="/usr/share/asistente-actualizacion/conf/variables.conf"

# Cargando variables internas
. ${VARIABLES}

# Eliminando kernels anteriores
for KERNEL in $( dpkg-query -W -f='${Package} ${Version}\t${Status}\n' linux-image* linux-headers* linux-source* linux-kbuild* | grep "install ok installed" | awk '{ print $1"_____"$2 }'); do
KERNEL_PAQUETE=$( echo ${KERNEL} | sed 's/_____.*//g' )
KERNEL_VERSION=${KERNEL#${KERNEL_PAQUETE}"_____"}
[ $( echo ${KERNEL_VERSION} | awk -F . '{print $3}' | sed 's/-.*//g' | sed 's/+.*//g' ) -lt 32 ] && PARA_DESINSTALAR=${PARA_DESINSTALAR}" "${KERNEL_PAQUETE}
done

xterm -e "tail -f ${LOG}" &
aa-ventana &

echo "Limpieza Final del Sistema" | tee -a ${VENTANA_1} ${LOG}
echo "Removiendo Kernels Obsoletos ..." | tee -a ${VENTANA_2} ${LOG}
echo "50" | tee -a ${VENTANA_3} ${LOG}
echo "--" | tee -a ${VENTANA_4} ${LOG}

aptitude purge --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" ${PARA_DESINSTALAR} | tee -a ${LOG}

echo "#!/bin/bash" > /usr/bin/limpiar-asistente
echo 'rm -rf /usr/share/asistente-actualizacion/cache/* | tee -a ${LOG}' >> /usr/bin/limpiar-asistente
echo 'aptitude purge --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" asistente-actualizacion | tee -a ${LOG}' >> /usr/bin/limpiar-asistente
echo 'pkill aa-ventana | tee -a ${LOG}' >> /usr/bin/limpiar-asistente
echo 'pkill xterm | tee -a ${LOG}' >> /usr/bin/limpiar-asistente

chmod +x /usr/bin/limpiar-asistente

limpiar-asistente

exit 0

