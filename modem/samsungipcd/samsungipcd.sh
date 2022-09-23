#!/sbin/openrc-run

description="AT modem emulation using libsamsung-ipc"
depends="ppp"

command="samsungipcd"
command_args="/dev/ptywc /dev/ptywd"
supervisor="supervise-daemon"
