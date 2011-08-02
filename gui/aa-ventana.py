#!/usr/bin/env python
# -*- coding: utf-8 -*-

import threading
import gtk
import random
import time
import gtk, gtk.glade
import os
import sys

BASE="/usr/share/asistente-actualizacion/"

gtk.gdk.threads_init()

NUM_THREADS = 5

class PyApp(gtk.Window):
    def __init__(self, threads=None):
        super(PyApp, self).__init__()
       
        self.glade = gtk.glade.XML(BASE+"gui/aa-ventana.glade")
        
        dic = { "destroy" : self.cerrar,
                "cancelar" : self.cerrar,
                "on_cancelar_clicked" : self.cerrar,
                "on_MainWindow_destroy" : self.cerrar }
        
        self.glade.signal_autoconnect(dic)

        self.dialogo=self.glade.get_widget("window1")
        self.trabajando=self.glade.get_widget("trabajando")
        self.trabajando0=self.glade.get_widget("trabajando0")
        self.progreso=self.glade.get_widget("progreso")
        self.trabajando.set_text("Hola1")
        self.trabajando0.set_text("Hola1")
        self.progreso.set_text("Hola1")
        self.dialogo.show_all()

        self.t=ProgressThread(self.trabajando,self.trabajando0,self.progreso)

    def cerrar(self, widget,event=None):
        os.system("pkill xterm")
        os.system("pkill aa-principal")
        os.system("pkill aptitude")
        os.system("pkill apt")
        os.system("pkill apt-get")
        os.system("pkill dpkg")
        os.system("pkill gksu")
        os.system("pkill gnome-terminal")
        os.system("pkill tail")
        self.glade.get_widget("window1").hide()
        gtk.main_quit()

class ProgressThread(threading.Thread):
    def __init__(self,trabajando,trabajando0,progressbar):
        threading.Thread.__init__ (self)

        self.tb = trabajando
        self.tb0 = trabajando0        
        self.pb = progressbar
        
        self.stopthread = threading.Event()

    def run(self):
        while not self.stopthread.isSet():
            gtk.gdk.threads_enter()
            uno=open(BASE+"log/ventana_4.log","r")
            lineasuno=uno.readlines()
            self.pb.set_text(lineasuno[len(lineasuno)-1][:-1])
            uno.close()

            uno=open(BASE+"log/ventana_3.log","r")
            lineasuno=uno.readlines()
            self.pb.set_fraction(float(lineasuno[len(lineasuno)-1])/100)
            uno.close()

            uno=open(BASE+"log/ventana_1.log","r")
            lineasuno=uno.readlines()
            self.tb.set_text(lineasuno[len(lineasuno)-1][:-1])
            uno.close()

            uno=open(BASE+"log/ventana_2.log","r")
            lineasuno=uno.readlines()
            self.tb0.set_text(lineasuno[len(lineasuno)-1][:-1])
            uno.close()

            gtk.gdk.threads_leave()
            
            time.sleep(1)
        
    def stop(self):
        self.stopthread.set()
        
if __name__ == "__main__":
    pyapp = PyApp()
    
    pyapp.t.start()
    
    gtk.gdk.threads_enter()
    gtk.main()
    gtk.gdk.threads_leave()


