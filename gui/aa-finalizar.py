#!/usr/bin/env python
#-*-coding:utf-8-*-

import os
import gobject
import pynotify
import subprocess

LOG="/usr/share/asistente-actualizacion/log/principal.log"
MOSTRAR=os.environ['HOME']+"/.config/asistente-actualizacion/mostrar.conf"
PASO="/usr/share/asistente-actualizacion/conf/paso.conf"

def reiniciar(n,action):
    subprocess.Popen(["gksu","reboot"])
    n.close()
    loop.quit()

if __name__=='__main__':

    try:
        check_cb_conf=open(MOSTRAR,"r")
        mostrar=check_cb_conf.readline()
        check_cb_conf.close()
        log_file=open(LOG,"a")
        log_file.write('[PYTHON:aa-finalizar.py] La configuración encontrada en MOSTRAR es ['+mostrar+']')
        log_file.close()
    except:
        mostrar=""
        log_file=open(LOG,"a")
        log_file.write('[PYTHON:aa-finalizar.py] No se encontró MOSTRAR')
        log_file.close()


    try:
        check_cb_conf=open(PASO,"r")
        paso=check_cb_conf.readline()
        check_cb_conf.close()
        log_file=open(LOG,"a")
        log_file.write('[PYTHON:aa-finalizar.py] La configuración encontrada en PASO es ['+paso+']')
        log_file.close()
    except:
        paso=""
        log_file=open(LOG,"a")
        log_file.write('[PYTHON:aa-finalizar.py] No se encontró PASO')
        log_file.close()

    pynotify.init("Asistente de Actualización")
    loop=gobject.MainLoop()
    n=pynotify.Notification("Fin de la Actualización","Reinicie para utilizar Canaima 3.0")
    n.set_timeout(pynotify.EXPIRES_NEVER)
    n.add_action("reiniciar", "Reiniciar", reiniciar)
    n.show()
    loop.run()

