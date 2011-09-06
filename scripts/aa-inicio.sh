#!/bin/bash

VARIABLES="/usr/share/asistente-actualizacion/conf/variables.conf"
. ${VARIABLES}

echo "[BASH:aa-inicio.sh] ejecutando aa-notificar.py, localizado en "$( pwd ) | tee -a ${LOG}
python /usr/share/asistente-actualizacion/gui/aa-notificar.py
