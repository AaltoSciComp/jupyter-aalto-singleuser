#!/bin/sh
set -eux

if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $(basename $0) DIFF [SOFTWARE]"
    echo
    echo "  Updates the software installation at SOFTWARE with the provided diff DIFF"
    echo "  SOFTWARE defaults to '/opt/software'"
    exit 1
fi

diff_file=$1
software=${2:-/opt/software}

temp_tar=$(mktemp -p /tmp patched.tar.XXXXXX)
temp_dir=$(mktemp -d -p /tmp software-new.XXXXXX)
/usr/local/bin/tar-patch "$diff_file" "$software" "$temp_tar"
tar xf "$temp_tar" -C "$temp_dir"
chmod --reference="$software" "$temp_dir"
chown -R --reference="$software" "$temp_dir"
chmod -R g+rwX "$temp_dir"
find "$temp_dir" -type d -exec chmod +6000 {} \;

# Notes about rsync flags:
#   * --update: ignores existing files with the same checksum -> doesn't touch
#     existing files, prevents image size inflation
#   * -go: set user+group based on source files instead of root:root
#   * -c: perform checksum comparison instead of file size+timestamp because
#     timestamps might not be accurate and it's better to spend extra time when
#     compiling the image than to generate an unnecessarily large image
rsync --delete -crhlpgo --stats "$temp_dir"/ "$software"
rm -r "$temp_dir" "$temp_tar" "$diff_file"
