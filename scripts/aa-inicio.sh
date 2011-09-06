#!/bin/bash

VARIABLES="/usr/share/asistente-actualizacion/conf/variables.conf"
. ${VARIABLES}

FLAG_270_1G=0
FLAG_M2400=0
FLAG_D2100=0
FLAG_270=0
FLAG_450=0
FLAG_455=0
FLAG_PC=0
CONTROL_PARENTAL=0

DMI_TYPES="bios-vendor system-manufacturer system-product-name system-version baseboard-manufacturer baseboard-product-name chassis-manufacturer chassis-type processor-manufacturer processor-version processor-frequency baseboard-asset-tag" 

DMI_TYPES_270="AmericanMegatrendsInc. MagII IntelpoweredclassmatePC Notebook Intel Intel(R)Atom(TM)CPUN270@1.60GHz 1600MHz 0"

DMI_TYPES_450="Phoenix IntelCorporation IntelpoweredclassmatePC MPPV IntelCorporation IntelpoweredclassmatePC Intel Other Intel C1 1600MHz PTLNanjing"

DMI_TYPES_455="Phoenix IntelCorporation IntelpoweredclassmatePC BPPV IntelCorporation IntelpoweredclassmatePC Intel Notebook Intel C1 1600MHz PTLNanjing"

DMI_TYPES_270_1G="AmericanMegatrendsInc. JPSaCouto IntelpoweredclassmatePC Gen1.5L IntelpoweredclassmatePC BLANK Notebook Intel Intel(R)Atom(TM)CPUN270@1.60GHz 1600MHz 0"

DMI_TYPES_M2400="AmericanMegatrendsInc. PEGATRONCORPORATION T14AF 1.0 PEGATRONCORPORATION T14AF PEGATRONCORPORATION Notebook Intel Intel(R)Core(TM)2DuoCPUT6500@2.10GHz 2100MHz ATN12345678901234567"

DMI_TYPES_D2100="Phoenix CLEVOCO. M540R NotApplicable CLEVO M540R CLEVO Other Intel CPUVersion 2100MHz"

for DMI_LOCAL in ${DMI_TYPES}; do
	DMI_TYPES_LOCAL="${DMI_TYPES_LOCAL} $( dmidecode --string ${DMI_LOCAL} | sed 's/ //g' )"
done

[ "$( echo ${DMI_TYPES_LOCAL} )" == "$( echo ${DMI_TYPES_270} )" ] && FLAG_270=1
[ "$( echo ${DMI_TYPES_LOCAL} )" == "$( echo ${DMI_TYPES_450} )" ] && FLAG_450=1
[ "$( echo ${DMI_TYPES_LOCAL} )" == "$( echo ${DMI_TYPES_455} )" ] && FLAG_455=1
[ "$( echo ${DMI_TYPES_LOCAL} )" == "$( echo ${DMI_TYPES_270_1G} )" ] && FLAG_270_1G=1
[ "$( echo ${DMI_TYPES_LOCAL} )" == "$( echo ${DMI_TYPES_D2100} )" ] && FLAG_D2100=1
[ "$( echo ${DMI_TYPES_LOCAL} )" == "$( echo ${DMI_TYPES_M2400} )" ] && FLAG_M2400=1

[ $FLAG_270 == 1 ] && [ $FLAG_450 == 0 ] && [ $FLAG_455 == 0 ] && [ $FLAG_270_1G == 0 ] && [ $FLAG_D2100 == 0 ] && [ $FLAG_M2400 == 0 ] && echo "Canaimita 270"

[ $FLAG_270 == 0 ] && [ $FLAG_450 == 1 ] && [ $FLAG_455 == 0 ] && [ $FLAG_270_1G == 0 ] && [ $FLAG_D2100 == 0 ] && [ $FLAG_M2400 == 0 ] && echo "Canaimita 450"

[ $FLAG_270 == 0 ] && [ $FLAG_450 == 0 ] && [ $FLAG_455 == 1 ] && [ $FLAG_270_1G == 0 ] && [ $FLAG_D2100 == 0 ] && [ $FLAG_M2400 == 0 ] && echo "Canaimita 455"

[ $FLAG_270 == 0 ] && [ $FLAG_450 == 0 ] && [ $FLAG_455 == 0 ] && [ $FLAG_270_1G == 1 ] && [ $FLAG_D2100 == 0 ] && [ $FLAG_M2400 == 0 ] && echo "Canaimita 270 (1er Grado)"

[ $FLAG_270 == 0 ] && [ $FLAG_450 == 0 ] && [ $FLAG_455 == 0 ] && [ $FLAG_270_1G == 0 ] && [ $FLAG_D2100 == 1 ] && [ $FLAG_M2400 == 0 ] && echo "Canaimita D2100"

[ $FLAG_270 == 0 ] && [ $FLAG_450 == 0 ] && [ $FLAG_455 == 0 ] && [ $FLAG_270_1G == 0 ] && [ $FLAG_D2100 == 0 ] && [ $FLAG_M2400 == 1 ] && echo "Canaimita M2400"

[ $FLAG_270 == 0 ] && [ $FLAG_450 == 0 ] && [ $FLAG_455 == 0 ] && [ $FLAG_270_1G == 0 ] && [ $FLAG_D2100 == 0 ] && [ $FLAG_M2400 == 0 ] && FLAG_PC=1 && echo "PC"

echo "[BASH:aa-inicio.sh] ejecutando aa-notificar.py, localizado en "$( pwd ) | tee -a ${LOG}
[ ${FLAG_PC} == 1 ] && python /usr/share/asistente-actualizacion/gui/aa-notificar.py
