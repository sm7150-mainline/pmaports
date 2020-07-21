#!/bin/sh

log() {
	echo "$@" | logger -t "postmarketOS:modem-setup"
}

# Current modem routing
#
#  1 - Digital PCM
#  0 - I2S master
#  0 - Primary mode (short sync)
#  2 - 512kHz clock (512kHz / 16bit = 32k samples/s)
#  0 - 16bit linear format
#  1 - 16k sample/s
#  1 - 1 slot
#  1 - map to first slot (the only slot)
#
QDAI_CONFIG="1,0,0,2,0,1,1,1"
QCFG_RISIGNALTYPE_CONFIG="physical"
QMBNCFG_CONFIG="1"
QCFG_IMS_CONFIG="1"

if [ -z "$1" ]
then
	DEV="/dev/EG25.AT"
else
	DEV="$1"
fi

# When running this script from udev the modem might not be fully initialized
# yet, so give it some time to initialize
#
# We'll try to query for the firmware version for 15 seconds after which we'll
# consider the initialization failed

log "Waiting for the modem to initialize"
INITIALIZED=false
for second in $(seq 1 15)
do
        if echo "AT+QDAI?" | atinout - $DEV - | grep -q OK
        then
                INITIALIZED=true
                break
        fi

        log "Waited for $second seconds..."

        sleep 1
done

if $INITIALIZED
then
        log "Modem initialized"
else
        log "Modem failed to initialize"
        exit 1
fi

# Read current config
QDAI_ACTUAL_CONFIG=$(echo "AT+QDAI?" | atinout - $DEV -)
QCFG_RISIGNALTYPE_ACTUAL_CONFIG=$(echo 'AT+QCFG="risignaltype"' | atinout - $DEV -)
QMBNCFG_ACTUAL_CONFIG=$(echo 'AT+QMBNCFG="AutoSel"' | atinout - $DEV -)
QCFG_IMS_ACTUAL_CONFIG=$(echo 'AT+QCFG="ims"' | atinout - $DEV -)

if echo $QDAI_ACTUAL_CONFIG | grep -q $QDAI_CONFIG && \
	echo $QCFG_RISIGNALTYPE_ACTUAL_CONFIG | grep -q $QCFG_RISIGNALTYPE_CONFIG && \
	echo $QMBNCFG_ACTUAL_CONFIG | grep -q $QMBNCFG_CONFIG && \
	echo $QCFG_IMS_ACTUAL_CONFIG | grep -q $QCFG_IMS_CONFIG
then
	log "Modem already configured"
	exit 0
fi

# Modem not configured, we need to send it the digital interface configuration,
# then reboot it

# Configure audio
RET=$(echo "AT+QDAI=$QDAI_CONFIG" | atinout - $DEV -)

if ! echo $RET | grep -q OK
then
	log "Failed to configure audio: $RET"
	exit 1
fi

# Configure ring device
RET=$(echo "AT+QCFG=\"risignaltype\",\"$QCFG_RISIGNALTYPE_CONFIG\"" | atinout - $DEV -)

if ! echo $RET | grep -q OK
then
	log "Failed to configure modem ring wakeup: $RET"
	exit 1
fi

# Configure VoLTE auto selecting profile
RET=$(echo "AT+QMBNCFG=\"AutoSel\",$QMBNCFG_CONFIG" | atinout - $DEV -)

if ! echo $RET | grep -q OK
then
	log "Failed to enable VoLTE profile auto selecting: $RET"
	exit 1
fi

# Enable VoLTE
RET=$(echo "AT+QCFG=\"ims\",$QCFG_IMS_CONFIG" | atinout - $DEV -)

if ! echo $RET | grep -q OK
then
	log "Failed to enable VoLTE: $RET"
	exit 1
fi

# Reset module
# 1 Set the mode to full functionality (vs 4: no RF, and 1: min functionality)
# 1 Reset the modem before changing mode (only available with 1 above)
#
RET=$(echo "AT+CFUN=1,1" | atinout - $DEV -)

if ! echo $RET | grep -q OK
then
	log "Failed to reset the module: $RET"
	exit 1
fi
