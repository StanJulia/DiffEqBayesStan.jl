JULIA_CMDSTAN_HOME="$HOME/cmdstan-2.28.2/"
OLDWD=`pwd`
cd ~
wget https://github.com/stan-dev/cmdstan/releases/download/v2.28.2/cmdstan-2.28.2.tar.gz
tar -xzpf cmdstan-2.28.2.tar.gz
make -C $JULIA_CMDSTAN_HOME build
cd $OLDWD