#!/bin/bash
# Check ncurses compatibility

cc="/usr/bin/cc"  # <-- Устанавливаем компилятор по умолчанию

# What library to link
ldflags()
{
    echo "-L/opt/homebrew/opt/ncurses/lib -lncurses"
}

# Where is ncurses.h?
ccflags()
{
    echo "-I/opt/homebrew/opt/ncurses/include -DCURSES_LOC=\"<ncurses.h>\" -DKBUILD_NO_NLS -Wno-format-security"
}

# Temp file, try to clean up after us
tmp=.lxdialog.tmp
trap "rm -f $tmp ${tmp%.tmp}.d" 0 1 2 3 15

# Check if we can link to ncurses
check() {
    $cc -I/opt/homebrew/opt/ncurses/include -L/opt/homebrew/opt/ncurses/lib -lncurses -x c - -o $tmp 2>/dev/null <<'EOF'
#include <ncurses.h>
int main() { return 0; }
EOF

    if [ $? != 0 ]; then
        echo " *** Unable to find the ncurses libraries or the"       1>&2
        echo " *** required header files."                            1>&2
        echo " *** 'make menuconfig' requires the ncurses libraries." 1>&2
        echo " *** "                                                  1>&2
        echo " *** Install ncurses (ncurses-devel) and try again."    1>&2
        echo " *** "                                                  1>&2
        exit 1
    fi
}

usage() {
    printf "Usage: $0 [-check compiler options|-ccflags|-ldflags compiler options]\n"
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

case "$1" in
    "-check")
        shift
        check "$@"
        ;;
    "-ccflags")
        ccflags
        ;;
    "-ldflags")
        shift
        ldflags "$@"
        ;;
    *)
        usage
        exit 1
        ;;
esac

