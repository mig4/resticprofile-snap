#!/bin/bash
# Run this in a VM where the built snap is available in /mnt/src/, e.g.:
#     multipass launch --name test-01
#     multipass mount $PWD test-01:/mnt/src
#     multipass exec test-01 -- bash /mnt/src/test.sh

set -euo pipefail

sudo snap install --classic restic
sudo snap install --classic --dangerous /mnt/src/resticprofile_0.14.0_amd64.snap
mkdir -p ~/.config/resticprofile
cp /mnt/src/test-profiles.yaml ~/.config/resticprofile/profiles.yaml
resticprofile random-key > ~/.config/resticprofile/repo.secrets-test.key
resticprofile random-key > ~/.config/resticprofile/repo.config-test.key

sudo install -d -o ${USER} -g $(id -gn) -m 775 /srv/restic
restic --repo /srv/restic/restic-test --password-file ~/.config/resticprofile/repo.config-test.key init
restic --repo /srv/restic/restic-test-secrets --password-file ~/.config/resticprofile/repo.secrets-test.key init

resticprofile --config ~/.config/resticprofile/profiles.yaml --name config-test backup
resticprofile --config ~/.config/resticprofile/profiles.yaml --name config-test snapshots

resticprofile --config ~/.config/resticprofile/profiles.yaml --name secrets-test backup
resticprofile --config ~/.config/resticprofile/profiles.yaml --name secrets-test snapshots

resticprofile --config ~/.config/resticprofile/profiles.yaml --name config-test schedule
resticprofile --config ~/.config/resticprofile/profiles.yaml --name config-test status
test -e ~/.config/systemd/user/resticprofile-backup@profile-config-test.timer
test -e ~/.config/systemd/user/resticprofile-backup@profile-config-test.service
systemctl --user status resticprofile-backup@profile-config-test.service
