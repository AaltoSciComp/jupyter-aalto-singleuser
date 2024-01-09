if [ "${CREATE_USERDATA:-false}" != "true" ]; then
    return
fi

if ! [ -d /coursedata/users ]; then
    echo "/coursedata/users doesn't exist, exiting"
    return
fi

if [ -d /coursedata/users/$NB_USER ]; then
    echo "/coursedata/users/$NB_USER already exists, exiting"
    return
fi

echo "Creating /coursedata/users/$NB_USER"
# Starting a subshell to set umask for mkdir only
(umask 0027 && mkdir /coursedata/users/$NB_USER) || echo "Failed to create /coursedata/users/$NB_USER"
