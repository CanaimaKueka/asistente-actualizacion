# -*- coding: utf-8 -*-

import pygtk
pygtk.require("2.0")
import gtk, gtk.glade
import os
from multiprocessing import Process
 
class Gui(gtk.Window):
    def __init__(self):
        gtk.Window.__init__(self)
        self.glade = gtk.glade.XML("dialogo1.glade")
        self.glade.signal_autoconnect(self)
        self.dialogo=self.glade.get_widget("window1")
        self.trabajando=self.glade.get_widget("trabajando")
        self.trabajando.set_text("Hola1")
        
        self.dialogo.show_all()
        self.__create_trayicon()
        self.showed = True
        p = Process(target=self.actualizar)
        p.start()

    def actualizar(self,dialogo):
        self.trabajando=self.glade.get_widget("trabajando")
        self.trabajando.set_text("Hola")



    def load_image(self, path, pixbuf=False):
        img_path = os.path.realpath(os.path.join(os.path.dirname(__file__),
            path))
        pix = gtk.gdk.pixbuf_new_from_file(img_path)
        if pixbuf: return pix
        avatar = gtk.Image()
        avatar.set_from_pixbuf(pix)
        del pix
        return avatar
 
    def __create_trayicon(self):
        if gtk.check_version(2, 10, 0) is not None:
            log.debug("Disabled Tray Icon. It needs PyGTK >= 2.10.0")
            return
        self.tray = gtk.StatusIcon()
        self.tray.set_from_pixbuf(self.load_image('turpial-tray.png', True))
        self.tray.set_tooltip('Asistente Actualización')
        self.tray.connect("activate", self.__on_trayicon_click)

    def __on_trayicon_click(self, widget):
        if self.showed:
            self.showed = False
            self.dialogo.hide()
        else:
            self.showed = True
            self.dialogo.show()
         

    def on_window1_delete_event(self, widget, event):
        gtk.main_quit()
 
    def on_button1_clicked(self, widget):
        gtk.main_quit()
 
if __name__ == "__main__":
    try:
        a = Gui()
        gtk.main()
    except KeyboardInterrupt:
        pass
