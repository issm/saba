#!/bin/sh
export SABA_EXEC_ROOT=<?=$ROOTDIR;?>
export PERL5LIB=$SABA_EXEC_ROOT/saba/lib:$SABA_EXEC_ROOT/saba/extlib:$PERL5LIB

echo \$SABA_EXEC_ROOT: $SABA_EXEC_ROOT
echo \$PERL5LIB:       $PERL5LIB

echo Entering $SABA_EXEC_ROOT
cd $SABA_EXEC_ROOT
prove t/*.t t/*/*.t

echo
