#!/bin/sh

set -e

if [[ $# -eq 0 ]] ; then
    echo 'Usage: $0 ocaml_version'
    exit 1
fi

# Required as the access to /tmp is forbidden
export TMPDIR=$(getconf DARWIN_USER_TEMP_DIR)

echo "Installing vanilla homebrew"
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

/usr/libexec/path_helper
export homebrew=$(brew --prefix)

# Git included in Apple Developer Tools is version 2.37.1
# Brew has version 2.38.1
brew install git

# echo "Install Lock-free Homebrew (maybe needed for parallel support)"
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/patricoferris/install/disable-locking/install.sh)"

# echo "Install Opam 2.0 and 2.1"
echo "Install Opam 2.1"
# git clone -b 2.0 https://github.com/ocaml/opam ./opam
# cd ./opam && make cold && mkdir -p $homebrew/bin && cp ./opam $homebrew/bin/opam-2.0 && chmod a+x $homebrew/bin/opam-2.0 && cd ../ && rm -rf ./opam
git clone -b 2.1 https://github.com/ocaml/opam ./opam
cd ./opam && make CONFIGURE_ARGS=--with-0install-solver cold && mkdir -p $homebrew/bin && cp ./opam $homebrew/bin/opam-2.1 && chmod a+x $homebrew/bin/opam-2.1 && cd ../ && rm -rf ./opam

echo "Default link 2.1 to opam"
ln $homebrew/bin/opam-2.1 $homebrew/bin/opam

echo "Check opam"
opam --version

echo "Updating the .obuilder_profile.sh to pre-init OCaml"

echo 'export HOMEBREW_DISABLE_LOCKING=1' > ~/.obuilder_profile.sh
echo 'export HOMEBREW_NO_AUTO_UPDATE=1' >> ~/.obuilder_profile.sh
echo 'export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin' >> ~/.obuilder_profile.sh
echo 'export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$PATH' >> ~/.obuilder_profile.sh # /opt is used for homebrew on macOS/arm64
echo 'export PATH=/Volumes/'$1':/opt/homebrew/sbin:$PATH' >> ~/.obuilder_profile.sh # Add system compiler to path

# Opam requires GNU Patch
brew install gpatch
for i in $homebrew/Cellar/*/*/bin; do echo 'export PATH="'$i':$PATH' >> ~/.obuilder_profile.sh ; done

echo "Setting up opam"

# Important to source the system compiler path for opam to init correctly
# otherwise we'll pick up the host's non-system compiler!
source ./.obuilder_profile.sh

git clone https://github.com/ocaml/opam-repository.git

opam init -k git -a ./opam-repository -c $1 -y
#opam install -y opam-depext

echo "Updating .obuilder_profile.sh"
echo 'export OPAMYES=1' >> ./.obuilder_profile.sh
echo 'export OPAMCONFIRMLEVEL=unsafe-yes' >> ./.obuilder_profile.sh
echo 'export OPAMERRLOGLEN=0' >> ./.obuilder_profile.sh
echo 'export OPAMPRECISETRACKING=1' >> ./.obuilder_profile.sh

# Stop fseventsd monitoring these volumes
for dir in $homebrew/.fseventsd ~/.fseventsd ~/.opam/download-cache/.fseventsd ~/Library/Caches/Homebrew/.fseventsd ; do
  echo "Remove $dir"
  sudo rm -r $dir
  sudo mkdir $dir
  sudo touch $dir/no_log
  sudo chown -R mac1000:admin $dir
done

echo "link local to $homebrew"
ln -s $homebrew local

