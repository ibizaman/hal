# Hal

Handle everything I need.

## Install

```bash
# on archlinux
yaourt inotify-tools fswatch

# on ubuntu
apt-get install inotify-tools # install fswatch

mkdir $path
mv hal.conf.template $path/hal.conf

# create a release
MIX_ENV=prod mix compile
MIX_ENV=prod mix release

# copy release 0.0.1 somewhere
mkdir -p $dest
cp apps/network/rel/network/releases/0.0.1/network.tar.gz $dest
cd $dest
tar -xf network.tar.gz

# copy template service (if using systemd):
cp hal.service.template /etc/systemd/system/hal.service
systemctl daemon-reload
systemctl start hal

# check that everything goes well (when you're in the $dest folder)
bin/network ping  # should answer pong
bin/network remote_console  # should open a console in running ap

# troubleshoot
bin/network console

# if everything went fine, make hal start on boot
systemctl enable hal
```
With
* `$path` one of `/etc/hal/hal.conf`, `~/.hal/hal.conf`, `hal.conf`
* `$dest` the folder in which you want to install the release.
  `/opt/hal` for example.
