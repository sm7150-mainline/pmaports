#!/bin/sh -e
# Test single functions of mkinitfs_functions.sh. Add -x for verbosity.

. ./mkinitfs_functions.sh

echo ":: testing parse_file_as_line()"
cat << EOF > _test
# comment
module1

module2
# comment2
module3
EOF

if [ "$(parse_file_as_line _test)" != "module1 module2 module3" ]; then
	echo "ERROR in line $LINENO"
	exit 1
fi


echo ":: all tests passed"
