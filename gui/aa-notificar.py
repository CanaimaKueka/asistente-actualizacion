#!/usr/bin/env python
#-*-coding:utf-8-*-

import os
import gobject
import pynotify
import subprocess

LOG="/usr/share/asistente-actualizacion/log/principal.log"
MOSTRAR=os.environ['HOME']+"/.config/asistente-actualizacion/mostrar.conf"
PASO="/usr/share/asistente-actualizacion/conf/paso.conf"

def actualizar(n,action):

    log_file=open(LOG,"a")
    log_file.write('[PYTHON:notificar.py] [EJECUCIÓN] Función "actualizar", ejecuta
            aa-principal y luego aa-fin')
    log_file.close()

    os.system("gksu aa-principal")
    os.system("gksu aa-fin")
    n.close()
    loop.quit()

def ignorar(n,action):

    log_file=open(LOG,"a")
    log_file.write('[PYTHON:notificar.py] [EJECUCIÓN] Función "ignorar", se sale
            de la notificación')
    log_file.close()

    n.close()
    loop.quit()

def no_mostrar(n,action):

    log_file=open(LOG,"a")
    log_file.write('[PYTHON:notificar.py] [EJECUCIÓN] Función "no_mostrar",
            escribe "MOSTRAR=0" en '+MOSTRAR)
    log_file.close()

    check_cb_conf=open(MOSTRAR,"w")
    check_cb_conf.write("MOSTRAR=0")
    check_cb_conf.close()
    n.close()
    loop.quit()

if __name__ == '__main__':

    try:
        check_cb_conf=open(MOSTRAR,"r")
        mostrar=check_cb_conf.readline()
        check_cb_conf.close()
        log_file=open(LOG,"a")
        log_file.write('[PYTHON:notificar.py] La configuración encontrada en
                MOSTRAR es ['+mostrar+']')
        log_file.close()
    except:
        mostrar=""
        log_file=open(LOG,"a")
        log_file.write('[PYTHON:notificar.py] No se encontró MOSTRAR')
        log_file.close()


    try:
        check_cb_conf=open(PASO,"r")
        paso=check_cb_conf.readline()
        check_cb_conf.close()
        log_file=open(LOG,"a")
        log_file.write('[PYTHON:notificar.py] La configuración encontrada en
                PASO es ['+paso+']')
        log_file.close()
    except:
        paso=""
        log_file=open(LOG,"a")
        log_file.write('[PYTHON:notificar.py] No se encontró PASO')
        log_file.close()


    if mostrar.find("0") is -1:

        if paso.find("1") > 0:

            log_file=open(LOG,"a")
            log_file.write('[PYTHON:notificar.py] Iniciada la notificación')
            log_file.close()

            pynotify.init("Asistente para la Actualización de Canaima 2.1")
            loop=gobject.MainLoop()
            n=pynotify.Notification("Nueva actualización disponible", "Ya puede actualizar a Canaima 3.0")
            n.set_urgency(pynotify.URGENCY_CRITICAL)
            n.set_timeout(pynotify.EXPIRES_NEVER)
            n.add_action("actualizar", "Actualizar Ahora", actualizar)
            n.add_action("ignorar", "Ignorar", ignorar)
            n.add_action("no_mostrar", "No volver a mostrar", no_mostrar)
            n.show()
            loop.run()

        if paso.find("70") > 0:

            log_file=open(LOG,"a")
            log_file.write('[PYTHON:notificar.py] Iniciando remoción de kernels
                    obsoletos')
            log_file.close()

            subprocess.Popen(["gksu","aa-kernel"])
            check_cb_conf=open(MOSTRAR,"w")
            check_cb_conf.write("MOSTRAR=0")
            check_cb_conf.close()
            pynotify.init("Asistente para la Actualización de Canaima 2.1")
            loop=gobject.MainLoop()
            n=pynotify.Notification("Bienvenido a Canaima GNU/Linux 3.0","Ya puede usar su sistema.")
            n.set_timeout(pynotify.EXPIRES_NEVER)
            n.show()
            loop.run()

