{
rm -rf /tmp/*

rm -rf /home/$NB_USER/.cache/yarn

/opt/conda/bin/mamba clean --all --yes --force-pkgs-dirs
/opt/software/bin/mamba clean --all --yes --force-pkgs-dirs
mountpoint -q /opt/conda/pkgs/cache/ || rm -rf /opt/conda/pkgs/cache/
mountpoint -q /opt/software/pkgs/cache/ || rm -rf /opt/software/pkgs/cache/
mountpoint -q /root/.cache/pip/ || rm -rf /root/.cache/pip/*
mountpoint -q /home/$NB_USER/.cache/pip/ || rm -rf /home/$NB_USER/.cache/pip/*

npm cache clean --force
rm -rf /home/$NB_USER/.npm/_logs

apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

fix-permissions /opt/conda /home/$NB_USER
[ -d /opt/software ] && fix-permissions /opt/software

} 2>&1 | sed -e 's/^/clean-layer:    /'
