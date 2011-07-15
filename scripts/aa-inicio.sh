#!/bin/bash

VARIABLES="/usr/share/asistente-actualizacion/conf/variables.conf"

echo "[bash:aa-inicio.sh] ejecutando notificar.py, localizado en "$( pwd ) > ${log}
python /usr/share/asistente-actualizacion/gui/aa-notificar.py
