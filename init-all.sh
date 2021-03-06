#!/bin/sh

set -e
cd `dirname $0`

if [ "$1" = "" ]; then
    echo "Usage: $0 [ start | stop | restart | reboot ]"
    echo ""
    echo "reboot is meant for cronjobs @reboot and unconditionally removes pid files before proceeding"
    exit 2
fi

if [ ! -f "lib/AmuseWikiFarm.pm" ]; then
    echo "In the wrong directory!";
    exit 2
fi

home_dir=`pwd`

mkdir -p opt/cache

prepare_app () {
# this looks like a bit of an overkill, but better have the files
# locally, without adding more work to the sysadmin

    ./script/install_js.sh
    # perl dependencies. Probably switch to use carton
    if diff -q Makefile.PL "Makefile.PL~" 2>/dev/null; then
        echo "makefile up to date"
    else
        cpanm --installdeps .
        cp Makefile.PL "Makefile.PL~"
    fi

    ./script/amusewiki-upgrade-db
    ./script/amusewiki-generate-nginx-conf
    ./script/amusewiki-upgrade-lexicon repo/*
    ./script/amusewiki-populate-webfonts
}

# echo `pwd`

start_web () {
    prepare_app
    rm -fv current_version_is_*.txt
    amw_version=`perl -I lib -MAmuseWikiFarm -e 'print $AmuseWikiFarm::VERSION'`
    touch current_version_is_$amw_version.txt
    rm -rfv var/cache/*
	./script/init-fcgi.pl start
}

start_all () {
    start_web
    ./script/jobber.pl start
    sleep 5
}

stop_all () {
    ./script/jobber.pl stop
	./script/init-fcgi.pl stop
}

case $1 in
    reboot)
        rm -fv ./var/*.pid
        start_all
    ;;

    start-app)
        start_web
    ;;

    stop-app)
        ./script/init-fcgi.pl stop
    ;;

    start)
        start_all
	;;
    stop)
        stop_all
	;;
    restart)
        stop_all
        start_all
	;;
    *)
	echo "uh?"
	echo "Usage: $0 [ start | stop | restart ]"
	exit 1
	;;
esac

