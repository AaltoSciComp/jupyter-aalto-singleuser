{
rm -rf /tmp/*

rm -rf /home/$NB_USER/.cache/yarn

/opt/conda/bin/mamba clean --all --yes
/opt/software/bin/mamba clean --all --yes
mountpoint -q /opt/conda/pkgs/cache/ || rm -rf /opt/conda/pkgs/cache/
mountpoint -q /opt/software/pkgs/cache/ || rm -rf /opt/software/pkgs/cache/
mountpoint -q /root/.cache/pip/ || rm -rf /root/.cache/pip/*

npm cache clean --force
rm -rf /home/$NB_USER/.npm/_logs

apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

fix-permissions /opt/conda /opt/software /home/$NB_USER

} 2>&1 > /dev/null
