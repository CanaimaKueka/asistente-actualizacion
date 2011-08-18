#!/bin/bash

VARIABLES="/usr/share/asistente-actualizacion/conf/variables.conf"
. ${VARIABLES}

echo "[BASH:aa-ventana.sh] ejecutando aa-ventana.py, localizado en "$( pwd ) | tee -a ${LOG}
python /usr/share/asistente-actualizacion/gui/aa-ventana.py
