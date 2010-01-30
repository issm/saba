#!/bin/sh
export SABA_EXEC_ROOT=<?=$ROOTDIR;?>
echo \$SABA_EXEC_ROOT: $SABA_EXEC_ROOT
echo Entering $SABA_EXEC_ROOT
cd $SABA_EXEC_ROOT
prove t/*.t t/*/*.t

echo
