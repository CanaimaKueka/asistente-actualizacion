#!/bin/bash

VARIABLES="/usr/share/asistente-actualizacion/conf/variables.conf"
. ${VARIABLES}

echo "[BASH:aa-fin.sh] ejecutando aa-finalizar.py, localizado en "$( pwd ) >> ${LOG}
python /usr/share/asistente-actualizacion/gui/aa-finalizar.py
