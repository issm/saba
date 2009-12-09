package Saba::DSI::YAML;
use strict;
use warnings;
use utf8;

use Saba::ClassBase qw/:base :debug/;
use DBI;
use YAML qw/LoadFile DumpFile/;
use File::Basename;
use File::Path qw/make_path/;

my $_conf;


sub new {
  my ($self, $class, %param) = ({}, shift, @_);
  bless $self, $class;
  $self->{"_$_"} = $param{$_}  for keys %param;
  $self->init(@_);
  $self;
}

#  デストラクタ
sub DESTROY {
}


sub init {
  my $self = shift;
  $_conf  = $self->{_conf};
  $self;
}



#
#  YAMLファイルをロードする
#
#  $hashref = load( name => $name, [ force_array => $flag ] );  # $name: hoge_fuga_piyo -> hoge/fuga/piyo
#  $hashref = load( file => $file, [ force_array => $flag ] );
#
sub load {
  my ($self, $param) = self_param @_;
  my $name        = $param->{name};
  my $file        = $param->{file};
  my $force_array = $param->{force_array}  ||  0;

  return undef
    unless defined $name || defined $file;

  my $data = {};

  my $yamldir = sprintf '%s/yaml', $_conf->{PATH}{DATA};
  my $yamlfile;
  if (defined $name) { $yamlfile = sprintf '%s/%s.yml', $yamldir, name2path( $name ); }
  else               { $yamlfile = -f $file  ?  $file  :  sprintf '%s/%s', $yamldir, $file; }

  if (-f $yamlfile) {
    $data = LoadFile($yamlfile)  or  warn $!;  # ファイルが空 or 記述が不正 or 読み込みエラー
  }
  else {
    warn sprintf '[%s] YAML file does not exist: %s.', __PACKAGE__, $yamlfile;
  }

  (ref $data ne 'ARRAY'  &&  $param->{force_array})  ?  [ $data ]  :  $data;
}



#
#  データをYAMLファイルとして保存する
#
#  @param    data    data
#  @param   ?name    scalar
#  @param   ?mkdir   scalar  flg
#  @param   ?backup  scalar  flg  # TODO
#  @param   ?append  scalar  flg  # TODO
#
#  @return
#
sub save {
  my ( $self, $param ) = self_param( @_ );
  defined $param->{data}  ||  return;
  my $file = sprintf('%s/yaml/%s.yml',
                     $_conf->{PATH}->{DATA},
                     name2path( $param->{name} || $self->{name} ),
                    );

  my $dir  = dirname $file;

  # フラグ mkdir が真のとき，存在しないディレクトリがあれば作成する
  if( $param->{mkdir} ) {
    my $mkdir = make_path $dir, { mode => 0755, error => \my $error };
    if( @$error ) {
      for my $diag ( @$error ) {
        my ($file, $message) = %$diag;
        my $warn = sprintf '%s: %s', $file, $message;
        warn $warn;
      }
    }
  }
  DumpFile($file, $param->{data})  or  warn $!;
  1;
}





1;
__END__
