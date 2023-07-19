
# Create extra groups in the container.

# Format of NB_CREATE_GROUPS "name:125,othergroup:1465641" of name:gid pairs.
# NB_SUPPLEMENTARY_GROUPS:  comma-separated group list:  name,othergroup

IFS=',' read -ra namesgids <<< "${NB_CREATE_GROUPS}"
for x in "${namesgids[@]}" ; do
    IFS=':' read -ra name_gid <<< "$x"
    groupadd -g "${name_gid[1]}" -o "${name_gid[0]}"
done

if [ -n "${NB_SUPPLEMENTARY_GROUPS}" ] ; then
    usermod  -aG "${NB_SUPPLEMENTARY_GROUPS}" $NB_USER
fi

unset namesgids
unset x
unset name_gid
