package Saba::HTTP;
use strict;
use warnings;
use utf8;

use Saba::ClassBase qw/:base :debug/;


my $_conf   = {};
my $_header = [];


sub new {
  my ($self, $class, %param) = ({}, shift, @_);
  bless $self, $class;
  $self->{"_$_"} = $param{$_}  for keys %param;
  $self->init(@_);
  $self;
}


sub init {
  my ($self) = @_;
  $_conf   = Saba::Config->new->get;
  $self->add_header(content_type
                    => ($_conf->{CONTENT_TYPE_DEFAULT}
                       || 'text/plain; charset=utf-8')
                    );
}


# add_header($key1 => $value1, $key2 => $value2, ...);
sub add_header {
  my ($self, @param) = @_;

  my $re_key = qr/^(?: (\w+)[-_](\w+) | ([A-Z]?\w+)([A-Z]\w+) )$/x;

  while (@param) {
    my ($key, $value) = (shift @param, shift @param);
    last  unless $key && $value;

    # content_type, content-type, ContentType, contentType
    # => Content-Type
    $key = ucfirst $key;
    $key =~ s{
               $re_key
             }{
               sprintf '%s-%s', ucfirst($1||$3), ucfirst($2||$4);
             }gex;

    # 同じ $key があれば上書き，そうでなければ追加
    my $i_key = -1;
    for my $h (@$_header) {
      next  if $h->[0] ne $key;
      ++$i_key;
      last  if $h->[0] eq $key;
    }
    # $key が存在しない
    if ($i_key < 0) {
      push @$_header, [$key, $value];
    }
    # $key が存在する
    else {
      $_header->[$i_key][1] = $value;
    }
  }
}

# remove_header($key1, $key2, ...);
sub remove_header {
  my ($self, @keys) = @_;
  my $re_key = qr/^(?: (\w+)[-_](\w+) | ([A-Z]?\w+)([A-Z]\w+) )$/x;

  for my $key (@keys) {
    # content_type, content-type, ContentType, contentType
    # => Content-Type
    $key = ucfirst $key;
    $key =~ s{
               $re_key
            }{
              sprintf '%s-%s', ucfirst($1||$3), ucfirst($2||$4);
            }gex;

    $_header = [
                grep {$_->[0] ne $key;} @$_header
               ];
  }
}

sub header {
  my ($self) = @_;
  join("\n",
       map {
         sprintf '%s: %s', @$_;
       } @$_header
      );
}


# redirect($to);
sub redirect {
  my ($self, $to) = @_;
  return undef  unless defined $to;
  $self->status(301, {location => $to});
  1;
}



# status($code, \%opts);
sub status {
    my ($self, $code, $opts) = @_;
    $code = sprintf '%03d', $code;

    $self->add_header(
        status => $code,
        %{$opts || {}},
    );

    # v viewフォーマット
    return +{
        name => '_status_' . $code,
    };
}


# cookie($name);
# cookie($name, $value);
sub cookie {
    my ($self, $name, $value) = @_;
    my $req = $self->{_req};
    #
    # setter
    #
    if (defined $value) {
        $value = en $value;

        my %param_cookie = (
            -name    => $name,
            -value   => $value,
            -domain  => $_conf->{COOKIE}{DOMAIN},
            -path    => $_conf->{COOKIE}{PATH},
            -secure  => $_conf->{COOKIE}{SECURE},
        );
        $param_cookie{-expires} = $_conf->{COOKIE}{EXPIRES}
            if $_conf->{COOKIE}{EXPIRES} ne '';

        my $cookie = $req->cookie(%param_cookie);
        $self->add_header(
            set_cookie => $cookie->as_string,
        );
        return $cookie;
    }
    #
    # getter
    #
    else {
        return de $req->cookie($name);
    }
}
# remove_cookie($name);
sub remove_cookie {
    my ($self, $name) = @_;
    my $req = $self->{_req};
    my $cookie = $req->cookie(
        -name    => $name,
        -value   => '',
        -expires => -1,
        -domain  => $_conf->{COOKIE}{DOMAIN},
        -path    => $_conf->{COOKIE}{PATH},
        -secure  => $_conf->{COOKIE}{SECURE},
    );
    $self->add_header(
        set_cookie => $cookie->as_string,
    );
    $cookie;
}
