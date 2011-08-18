#!/bin/bash

VARIABLES="/usr/share/asistente-actualizacion/conf/variables.conf"
. ${VARIABLES}

flag_270=1
flag_450=1
flag_455=1
flag_pc=0
CONTROL_PARENTAL=0

dmitypes=( "bios-vendor" "system-manufacturer" "system-product-name" "system-version" "baseboard-manufacturer" "baseboard-product-name" "chassis-manufacturer" "chassis-type" "processor-manufacturer" "processor-version" "processor-frequency" "baseboard-asset-tag" )

dmitypes_270=( "AmericanMegatrendsInc." "J.P.SaCouto" "IntelpoweredclassmatePC" "MagII" "J.P.SaCouto" "IntelpoweredclassmatePC" "J.P.SaCouto" "Notebook" "Intel" "Intel(R)Atom(TM)CPUN270@1.60GHz" "1600MHz" "0" )

dmitypes_450=( "Phoenix" "IntelCorporation" "IntelpoweredclassmatePC" "MPPV" "IntelCorporation" "IntelpoweredclassmatePC" "Intel" "Other" "Intel" "C1" "1600MHz" "PTLNanjing" )

dmitypes_455=( "Phoenix" "IntelCorporation" "IntelpoweredclassmatePC" "BPPV" "IntelCorporation" "IntelpoweredclassmatePC" "Intel" "Notebook" "Intel" "C1" "1600MHz" "PTLNanjing" )

dmitypesnum=${#dmitypes[@]}
dmitypes_local[${dmitypesnum}]=""

echo $dmitypesnum
for ((i=0;i<$dmitypesnum;i++)); do
	dmitypes_local[${i}]=$( dmidecode --string $( echo ${dmitypes[${i}]} ) | sed -e "s/[ ]*//g" )
done

for ((i=0;i<$dmitypesnum;i++)); do
	[ "${dmitypes_local[${i}]}" != "${dmitypes_270[${i}]}" ] && flag_270=0
	[ "${dmitypes_local[${i}]}" != "${dmitypes_450[${i}]}" ] && flag_450=0
	[ "${dmitypes_local[${i}]}" != "${dmitypes_455[${i}]}" ] && flag_455=0
done

[ $( dpkg-query -W -f='${Package}\t${Status}\n' canaima-control-parental | grep -c "install ok installed" ) == 1 ] && CONTROL_PARENTAL=1

[ $flag_270 == 0 ] && [ $flag_450 == 0 ] && [ $flag_455 == 0 ] && flag_pc=1

echo "[BASH:aa-inicio.sh] ejecutando aa-notificar.py, localizado en "$( pwd ) | tee -a ${LOG}
[ ${flag_pc} == 1 ] && [ ${CONTROL_PARENTAL} == 0 ] && python /usr/share/asistente-actualizacion/gui/aa-notificar.py
