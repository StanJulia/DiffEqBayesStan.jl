JULIA_CMDSTAN_HOME="$HOME/cmdstan-2.34.1/"
OLDWD=`pwd`
cd ~
wget https://github.com/stan-dev/cmdstan/releases/download/v2.34.1/cmdstan-2.34.1.tar.gz
tar -xzpf cmdstan-2.34.1.tar.gz
make -C $JULIA_CMDSTAN_HOME build
cd $OLDWD