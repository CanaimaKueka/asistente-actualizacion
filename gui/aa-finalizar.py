#!/usr/bin/python
#-*-coding:utf-8-*-

importos
importgobject
importpynotify
importsubprocess

deffoo_cb(n,action):
print"INICIARACTUALIZACION"
subprocess.Popen(["gksu","asistente-actualizacion"])
n.close()
loop.quit()

defreboot_cb(n,action):
print"REINICIAR"
subprocess.Popen(["gksu","reboot"])
n.close()
loop.quit()


defdefault_cb(n,action):
print"NOPASANADA"
n.close()
loop.quit()

defdefault_cb2(n,action):
check_cb_conf=open(os.environ['HOME']+"/.config/asistente.conf","w")
check_cb_conf.write("MOSTRAR=0")
check_cb_conf.close()
n.close()
loop.quit()

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
        pynotify.init("Asistente para la Actualización de Canaima 2.1")
        loop=gobject.MainLoop()
        n=pynotify.Notification("Fin de la Actualización","Debe reiniciar para finalizar la actualización")
        n.set_timeout(pynotify.EXPIRES_NEVER)
        n.add_action("reiniciar", "Reiniciar", reiniciar)
        n.show()
        loop.run()
