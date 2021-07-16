JULIA_CMDSTAN_HOME="$HOME/cmdstan-2.27.0/"
OLDWD=`pwd`
cd ~
wget https://github.com/stan-dev/cmdstan/releases/download/v2.27.0/cmdstan-2.27.0.tar.gz
tar -xzpf cmdstan-2.27.0.tar.gz
make -C $JULIA_CMDSTAN_HOME build
cd $OLDWD