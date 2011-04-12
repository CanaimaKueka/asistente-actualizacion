#! /bin/sh
### BEGIN INIT INFO
# Provides:          actualizacion
# Required-Start:    $local_fs $remote_fs
# Required-Stop:     $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Actualizacion de Canaima GNU/Linux 3.0
# Description:       Canaima init script for the 3.0 update
### END INIT INFO
#
#
set -e

PATH=/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/sbin/actualizacion

test -x $DAEMON || exit 0

case "$1" in
  start)


  ;;
  stop)

  ;;
  reload)

  ;;
  status)
        status_of_proc -p "$PIDFILE" "$DAEMON" gdm3 && exit 0 || exit $?
  ;;
  restart|force-reload)
        $0 stop
        $0 start
  ;;
  *)
        echo "Usage: $BIN {start|stop|restart|reload|force-reload|status}"
        exit 1
  ;;
esac

exit 0
