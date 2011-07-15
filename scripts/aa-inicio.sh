#!/bin/bash

VARIABLES="/usr/share/asistente-actualizacion/conf/variables.conf"

echo "[BASH:aa-inicio.sh] ejecutando notificar.py, localizado en "$( pwd ) > ${LOG}
python /usr/share/asistente-actualizacion/gui/aa-notificar.py
