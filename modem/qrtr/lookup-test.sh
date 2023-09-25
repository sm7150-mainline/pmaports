#!/bin/sh -e
# Automated test for qrtr-lookup
# Ensures that a DSP is running and exposes at least 1 service

qrtr-lookup | tee /tmp/qrtr-lookup.log

if [ $(wc -l /tmp/qrtr-lookup.log | cut -d' ' -f1) -gt 1 ]; then
	echo "At least one QMI service is running"
	exit 0
fi

echo "FAIL: No QMI service is running"
exit 1
