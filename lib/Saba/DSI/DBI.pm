package Saba::DSI::DBI;
use strict;
use warnings;
use utf8;

use Saba::ClassBase qw/:base :debug/;
use DBI;
use YAML qw/LoadFile DumpFile/;
use Encode;

my $_conf;
my $_cache;
my $_pre;

my $_sth;
my $_dbh;



sub new {
  my ($self, $class, %param) = ({}, shift, @_);
  bless $self, $class;
  $self->{"_$_"} = $param{$_}  for keys %param;
  $self->init(@_);
  $self;
}


sub init {
  my $self = shift;
  $_conf  = $self->{_conf};
  $_cache = {};
  $_pre   = $_conf->{DB}{TABLE_PREFIX}  ||  '';
  $self->connect;
  $self;
}


#
#  DBに接続する
#
sub connect {
  my $self = shift;
  my $db_type = lc ($_conf->{DB}{TYPE} || 'mysql');

  if($_dbh  &&  $_sth) {
    warn sprintf 'Already connected to %s', $db_type;
    return;
  }

  # MySQL
  if($db_type eq 'mysql') {
    $_dbh =
      DBI->connect(sprintf('DBI:mysql:%s:%s',
                           $_conf->{DB}{NAME},
                           $_conf->{DB}{HOST},
                          ),
                   $_conf->{DB}{USER},
                   $_conf->{DB}{PASSWD},
                   { AutoCommit => 1 },
                  )
        or  (warn "Could not connect to database: " . DBI->errstr
             && return);
    $self->prepare;
    #warn 'Connected to mysql.'  if $Sabae::DEBUG;
  }
  # PostgreSQL
  elsif( $db_type eq 'pgsql' ) {
  }
  # SQLite
  elsif( $db_type eq 'sqlite' ) {
  }
}

#
#  DBから切断する
#
sub disconnect {
  my $self = shift;
  $_sth->finish;
  $_dbh->disconnect;
}

#  ステートメントハンドルを準備する
sub prepare {
  shift;
  $_sth = $_dbh->prepare( shift || '' );
}



#
#  ステートメントを実行する
#
sub execute {
  my $self = shift;
  $_sth->execute( defined @_ ? @_ : undef );
}





#
#  SQLを実行する
#
#  @param    sql       scalar
#  @param   ?bind      arrayref, arrayref of arrayref
#  @param   ?ref_type  scalar
#  @param   ?key       scalar
#  @param   ?warn      scalar
#
#  sql      => $sql,
#  bind     => $arrayref, # $arrayref == [ $val1, $val2, ... ] or [ [ $val11, $val12, ... ], [ $val21, $val22, ... ], ... ]
#  ref_type => $reftype,  # $reftype == 'hash' or 'array'
#  key      => $key,  # $reftype == 'hash' 時に指定するカラム
#
#  q( sql => $sql, bind => [ $b1, $b2, ... ] );
#  q( $sql, [ $b1, $b2, ... ] );
#
#  q( sql => { name => $name, key => $key, limit => $limit }, bind => [ $b1, $b2, ... ] );
#  q( { name => $name, key => $key, limit => $limit }, [ $b1, $b2, ... ] );
#  q( [ $name, $key, $limit ], [ $b1, $b2, ... ] );
#
sub q     { shift->query(@_); }
sub query {
  my $self = shift;
  push @_, undef  if scalar @_ % 2;
  my $param  = @_ ? { @_ } : {};
  my ( $sql, $bind, $ref_type, $key, $is_warn_sql );

  # $param->{sql} が定義されている場合，名前付き引数指定とみなす
  if( defined $param->{sql} ) {
    $sql         = $param->{sql};
    $bind        = $param->{bind};
    $ref_type    = $param->{ref_type}  ||  'array';
    $key         = $param->{key};
    $is_warn_sql = defined $param->{warn}  ?  $param->{warn}  :  $self->{WARN_SQL};
  }
  # $param->{sql} が定義されていない場合，名前なし引数指定とみなす
  else {
    ( $sql, $bind, $ref_type, $key ) = @_;
    $ref_type    ||= 'array';
    $is_warn_sql ||= 0;
    if( ! $key  &&  ref $ref_type eq 'HASH' ) {
      $key = (keys %$ref_type)[0]  ||  undef;
    }
    if( ref $ref_type eq 'HASH' )     { $ref_type = 'hash'; }
    elsif( ref $ref_type eq 'ARRAY' ) { $ref_type = 'array'; }
  }

  # $sql が hashref or arrayref の場合，load_sql メソッドを呼ぶ
  if( ref $sql eq 'HASH' ) {
    $sql = $self->load_sql( name => $sql->{name}, key => $sql->{key}, limit => $sql->{limit} );
  }
  elsif( ref $sql eq 'ARRAY' ) {
    $sql = $self->load_sql( name => $sql->[0], key => $sql->[1], limit => $sql->[2] );
  }
  elsif (ref $sql eq '') {
    # また，$sql が文字列かつ '<name>::<key>[<limit>]' な書式の場合も load_sql メソッドを呼ぶ
    my ($name, $key, $limit) =
      $sql =~ /(\w+) :: (\w+) (?:\[ (\d+ (?:, \d+)?) \])?/x;
    if ($name  &&  $key) {
      $sql = $self->load_sql(name  => $name,
                             key   => $key,
                             limit => $limit,
                            );
    }
    else {
      $sql = '1';
    }
  }

  # パラメータのチェック
  return {}  if $ref_type eq 'hash'  &&  ! $key;  # ref_type をハッシュに指定したにも関わらず，key の指定がない場合

  # [未実装] データベースハンドルが有効でない（== 接続が確立できていない）場合
  if( 0 ) {
    $self->connect;
  }

  # 出力指定がある場合，SQLを警告出力
  warn $sql  if $is_warn_sql;


  my $db_type = $_conf->{DB}{TYPE};
  #--------------------------------------------------------------------------------
  #
  # MySQL
  #
  #--------------------------------------------------------------------------------
  if( $db_type eq 'mysql' ) {
    $self->prepare( $sql );
    #
    # INSERT, REPLACE, UPDATE, DELETE, CREATE TABLE, DROP TABLE
    #
    if( $sql =~ m{^\s*( INSERT | REPLACE | UPDATE | DELETE | CREATE \s TABLE | DROP \s TABLE )\s}ix ) {
      my $rows_affected = 0;
      # バインド値が指定されている
      if( defined $bind ) {
        foreach my $b ( @$bind ) {
          # $bind == [ $arrayref1, $arrayref2, ... ]
          if( ref $b eq 'ARRAY' ) {
            $rows_affected += $_sth->execute( @$b )  ||  0;
            next;
          }
          # $bind == $arrayref
          else {
            $rows_affected += $_sth->execute( @$bind )  ||  0;
            last;
          }
        }
      }
      # バインド値が指定されていない
      else {
        $rows_affected = $_sth->execute();
      }
      return $rows_affected;
    }
    #
    # SELECT, SHOW, DESCRIBE  # 今のところ scalar を要素に持つ arrayref のみ bind を許可
    #
    elsif( $sql =~ m{^\s*( SELECT | SHOW | DESCRIBE )\s}ix ) {
      defined $bind  ?  $self->execute( @$bind )  :  $self->execute;
      #$self->execute( defined $bind->[0]  ?  @$bind  :  undef );
      my $ref_fetch = $ref_type eq 'hash'
        ?  ( $_sth->fetchall_hashref( $key )  ||  {} )
        :  ( $_sth->fetchall_arrayref()  ||  [] );
      my $RET;
      #my $decoded = decode('utf-8', Data::Dumper->Dump([$ref_fetch], ['RET']));
      my $decoded = decode('utf-8', D([$ref_fetch], ['RET']));
      return eval $decoded;
      #return $ref_fetch;
    }
    #
    # CREATE TABLE, DROP TABLE, CREATE DATABASE
    #
    elsif( $sql =~ m{^\s*( CREATE \s TABLE | DROP \s TABLE | CREATE \s DATABASE )\s}ix ) {
      $_sth->execute();
      return;
    }
  }
  #--------------------------------------------------------------------------------
  #
  # PostgreSQL
  #
  #--------------------------------------------------------------------------------
  elsif( $db_type eq 'pgsql' ) {
  }
  #--------------------------------------------------------------------------------
  #
  # SQLite
  #
  #--------------------------------------------------------------------------------
  elsif( $db_type eq 'sqlite' ) {
  }

  return;
}



# load_sql( name => $name, key => $key );
# load_sql( name => $name, key => $key, limit => [ $start, $offset ] );
# load_sql( name => $name, key => $key, limit => $offset );
sub load_sql {
  my ($self, $param) = self_param @_;
  my $name  = $param->{name};
  my $key   = $param->{key};
  my $limit = $param->{limit};

  unless (exists $_cache->{$name}) {
    my $data = {};
    my $yamlfile = sprintf('%s/sql/%s.yml',
                           $_conf->{PATH}{DATA},
                           name2path $name,
                          );
    if (-f $yamlfile) {
      if ($data = LoadFile($yamlfile)) {
        $_cache->{$name} = $data;
      }
      else {
        warn $!;
        return undef;
      }
    }
    else {
      warn sprintf '[%s] YAML file does not exist: %s.', __PACKAGE__, $yamlfile;
      return undef;
    }
  }
  my $sql;
  ($sql = $_cache->{$name}->{$key}  ||  '')
    =~ s/%(?:PRE)?%/$_pre/g;  # %PRE% または %% を $_pre の値に置き換える

  my $LIMIT = '';
  # limit => [ $start, $offset ],
  if (defined $limit
      &&  ref $limit eq 'ARRAY'
      &&  scalar @$limit >= 2) {
    $LIMIT = sprintf 'LIMIT %d, %d', @$limit;
  }
  # limiit => $offset
  elsif (defined $limit
         &&  ref $limit eq '') {
    $LIMIT = sprintf 'LIMIT %s', $limit;
  }
  else {
  }
  $sql =~ s{%LIMIT%}{$LIMIT};
  $sql;
}



1;
__END__
