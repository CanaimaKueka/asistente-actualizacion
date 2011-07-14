#!/usr/bin/env python
# -*- coding: utf-8 -*-

import pynotify, sys

try:
    import pygtk
    import time
    import os
    import subprocess
    import subprocess 
    pygtk.require("2.0")

except:
    pass

try:
    import gtk
    import gtk.glade
    import pango

except:
    sys.exit(1)

def callback_function():
    print "Hola"

BASE="/usr/share/asistente-actualizacion/"

class AsistenteGTK:

    def __init__(self):
        self.pos=0
        self.MAX=2
        self.MIN=0
        self.gladefile = "aa-principal.glade"
        self.glade = gtk.Builder()
        self.glade.add_from_file(self.gladefile)
        self.sig = self.glade.get_object('siguiente')
        self.sig.connect('clicked', self.siguiente)
        self.ant = self.glade.get_object('atras')
        self.ant.connect('clicked', self.anterior)
        self.ayuda = self.glade.get_object('ayuda')
        self.ayuda.connect('clicked', self.dale)

        self.window = self.glade.get_object('window1')       
        self.v = self.glade.get_object('vbox1')       
        self.titulo = self.glade.get_object('label1')       
        self.titulo.modify_font(pango.FontDescription("sans bold 12"))
        if os.path.exists(BASE+"paso"):
            archivo=open(BASE+"paso")
            paso=archivo.readline()
            self.pos=int(paso)
            print "vamos en pos: "+str(self.pos)
        self.mostrar()
            
    def siguiente(self,widget):
        if self.pos<self.MAX:
            self.ant.set_sensitive(True)
            self.pos=self.pos+1
            self.mostrar()
        if self.pos==self.MAX:
            self.sig.set_sensitive(False)

    def anterior(self,widget):
        if self.pos>self.MIN:
            self.sig.set_sensitive(True)
            self.pos=self.pos-1
            self.mostrar()
        if self.pos==self.MIN:
            self.ant.set_sensitive(False)

    def mostrar(self):
        self.contenido = self.glade.get_object('contenido')       
        print  "pos: "+str(self.pos)
        if self.pos == 0:
            self.contenido.set_text("A continuación este asistente se encargará de realizar todos los pasos necesarios para la actualización de su sistema, a la versión de los paquetes que corresponden con Canaima 3.0\n\nHaga clic en siguiente para continuar.")
            self.window.show()

        elif self.pos == 1:
            self.contenido.set_text("Este asistente realizará lo siguiente:\n\n- Paso 1\n- Paso 2 \n- Paso 3 \n- Paso 4\n\nIndicaciones y advertencias aqui, indicaciones y advertencias.\n\nInformacion de como sabra cuando el sistema esta listo.\n\n\nHaga clic en el boton 'Siguiente' para iniciar el proceso, al hacer clic en aceptar no tendrá marcha atrás. ")
            self.window.show()
            subprocess.Popen(["sudo","mkdir","-p",BASE])
            subprocess.Popen(["sudo","touch",BASE+"paso"])

        elif self.pos == 2:
            print "Ocultar la toche ventana!!"
            self.window.hide()

            self.window.hide_all()
            while gtk.events_pending():
                gtk.main_iteration()

            subprocess.Popen(["aa-principal"],shell=True)

        else:
            print 'Desconocido...' 

    def dale(self,widget):
        box2 = gtk.VBox(False, 10)
        box2.set_border_width(10)
        self.v.pack_start(box2, True, True, 0)
        box2.show()

    def contenido(self,widget):
        self.contenido = self.glade.get_object('contenido')       
        self.contenido.set_text("Hola")

"""
    def actualizar(self, widget):
        n = pynotify.Notification("Actualización a Versión 3.0", "Ya se encuentra disponible la versión 3.0 de Canaima GNU/Linux.", "dialog-warning")
        #n = pynotify.Notification("Actualización a Versión 3.0", "Ya se encuentra disponible la versión 3.0 de Canaima GNU/Linux.")
        n.set_urgency(pynotify.URGENCY_NORMAL)
        n.set_timeout(pynotify.EXPIRES_NEVER)
        n.add_action("clicked","Actualizar ahora", callback_function, None)
        n.add_action("clicked","Recordar luego", callback_function, None)
        n.show()

    def exito(self):
	pynotify.init("Actualizacion Canaima")
        n = pynotify.Notification("Actualización a Versión 3.0", "ACTUALIZACIÓN REALIZADA CON EXITO. Ya puede disfrutar de Canaima GNU/Linux 3.0.", "dialog-warning")
        n.set_urgency(pynotify.URGENCY_NORMAL)
        n.set_timeout(pynotify.EXPIRES_NEVER)
        n.show()

    def notificar(self, mensaje):
        print "#############################################"+str(self.pos)+" :: "+mensaje
	pynotify.init("Actualizacion Canaima")
        n = pynotify.Notification("Actualización de Canaima",mensaje, "dialog-warning")
        n.set_urgency(pynotify.URGENCY_NORMAL)
        n.show()

    def callback_function():
        print "Hola"
"""

if __name__ == "__main__":
    Asistente = AsistenteGTK()
    #Asistente.actualizar(Asistente)
    gtk.main()


