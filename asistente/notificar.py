#!/usr/bin/python
#-*-coding:utf-8-*-

import os
import gobject
import pynotify
import subprocess

def actualizar(n,action):
    print "INICIAR ACTUALIZACION"
    os.system("gksu asistente-actualizacion")
    os.system("gksu asistente-actualizacion-fin")
    n.close()
    loop.quit()

def ignorar(n,action):
    print "El usuario ha ignorado la notificación."
    n.close()
    loop.quit()

def no_mostrar(n,action):
    check_cb_conf=open(os.environ['HOME']+"/.config/asistente.conf","w")
    check_cb_conf.write("MOSTRAR=0")
    check_cb_conf.close()
    n.close()
    loop.quit()

"""
def quitar_cb(n,action):
    print "INICIAR ACTUALIZACION"
    subprocess.Popen(["gksu","limpiarkernels"])
    n.close()
    loop.quit()

def reboot_cb(n,action):
    print "REINICIAR"
    subprocess.Popen(["gksu","reboot"])
    n.close()
    loop.quit()
"""

if __name__=='__main__':

    try:
        check_cb_conf=open(os.environ['HOME']+"/.config/asistente.conf","r")
        mostrar=check_cb_conf.readline()
        check_cb_conf.close()
    except:
        mostrar=""

    try:
        check_cb_conf=open("/usr/share/asistente-actualizacion/paso.conf","r")
        paso=check_cb_conf.readline()
        check_cb_conf.close()
    except:
        paso=""

    print paso

    if mostrar.find("0") is -1:

        if paso.find("1") > 0:

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

            subprocess.Popen(["gksu","asistente-actualizacion-chaokernels"])
            check_cb_conf=open(os.environ['HOME']+"/.config/asistente.conf","w")
            check_cb_conf.write("MOSTRAR=0")
            check_cb_conf.close()
            pynotify.init("Asistente para la Actualización de Canaima 2.1")
            loop=gobject.MainLoop()
            n=pynotify.Notification("Bienvenido a Canaima GNU/Linux 3.0","Ya puede usar su sistema.")
            n.set_timeout(pynotify.EXPIRES_NEVER)
            n.show()
            loop.run()

