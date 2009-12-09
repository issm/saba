package Saba::ClassBase;
use strict;
use warnings;
use utf8;

use base qw/Exporter/;
use Data::Dumper qw/Dumper/;
use Digest::MD5 qw/md5_hex/;
use Time::HiRes qw/gettimeofday/;
use Encode;


our @EXPORT = qw/self_param
                 name2path
                 generate_random_key
                 read_file
                 en
                 de
                 d
                 D
                /;
our %EXPORT_TAGS =
  ( base  => [qw/self_param
                 name2path
                 generate_random_key
                 read_file
                 en
                 de
                /],
    debug => [qw/d
                 D
                /],
  );



# self_param(@_);
sub self_param {
  return (scalar @_) % 2
    ? (shift, defined @_ ? {@_} : {})
    : ({}, defined @_ ? {@_} : {})
  ;
}


# name2path($name);
sub name2path {
  # v 第1引数がスカラの場合，$self = {}
  # v → OO的メソッドと直接呼び出しのどちらにも対応（のつもり）
  my $self = ref $_[0]  ?  shift  :  {};
  my $path = shift || $self->{name} || '';
  $path =~ s{_}{/}g;
  $path =~ s{^/}{_};
  $path =~ s{//}{/_}g;
  $path;
}


#
sub d { Dumper @_; }
sub D { Data::Dumper->Dump(@_); }


# generate_random_key($n);
sub generate_random_key {
  my $n = shift  ||  1;

  my $ret = '';
  my $hash_n = join('',
                    map {
                      md5_hex sprintf('%s%s', gettimeofday);
                    } 1 .. $n,
                   );

  my @map = qw/ 0 1 2 3 4 5 6 7 8 9 _ -
                a b c d e f g h i j k l m n o p q r s t u v w x y z
                A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
              /;
  my @c = split '', $hash_n;

  while (@c) {
    my @a = (shift @c, shift @c, shift @c, shift @c);
    my $sum = 0;
    for (@a) {
      $sum  +=  eval(sprintf '0x%s', ($_||'00'))  ||  0;
    }
    $ret .= $map[$sum];
  }
  $ret;
}


# read($path);
sub read_file {
  my ($path) = @_;
  return undef  unless -f $path;

  local $/;
  my $buff;
  open my $fh, '<', $path  or  (warn $! && return undef);
  $buff = <$fh>;
  close $fh;

  $buff;
}


#
sub en {
  encode('utf-8', shift || '');
}

#
sub de {
  my $t = shift || '';
  decode('utf-8', $t);
}
