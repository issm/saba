package Saba::View;
use strict;
use warnings;
use utf8;

use Text::MicroTemplate::Extended;
use Encode;
use Saba::Page;
use Saba::ClassBase qw/:base :debug/;


my $_conf   = {};
my $_query  = {};
my $_var    = {};

my $_http;
my $_page;

sub new {
  my ($self, $class, %param) = ({}, shift, @_);
  bless $self, $class;
  $self->{"_$_"} = $param{$_}  for keys %param;
  $self->init(@_);
  $self;
}


sub init {
  my ($self) = @_;
  $_conf  = $self->{_conf};
  $_query = $self->{_query};
  $_var   = $self->{_var};
  $_http  = $self->{_http};

  $_page  = Saba::Page->new(name => $self->{_name},
                            conf => $_conf,
                           );
  my $css_import = $_page->import_css;
  my $js_import  = $_page->import_js;

  ($_var->{CSS_IMPORT}, $_var->{CSS_IMPORT_IE}) = @$css_import;
  ($_var->{JS_IMPORT}, $_var->{JS_IMPORT_IE})   = @$js_import;

  $self;
}


sub go {
  my ($self) = @_;

  my $viewfile = sprintf('%s/%s.mt',
                         $_conf->{PATH}{TEMPLATE},
                         name2path($self->{_name}),
                        );
  my $http_header = $_http->header;
  my $http_body   = '';

  my $mt =
    Text::MicroTemplate::Extended->new(
      include_path  => $_conf->{PATH}{TEMPLATE},
      template_args => {
                        q    => $_query,
                        conf => $_conf,
                        ENV  => \%ENV,
                        var  => $_var,

                        VIEW_NAME   => $self->{_name},
                        ACTION_NAME => $self->{_action_name},
                       },
      use_cache => 1,
    );
  #
  if (-f $viewfile) {
    #my ($QUERY, $CONF);
    #$_query = eval decode('utf-8', D([$_query], ['QUERY']));
    #$_conf  = eval decode('utf-8', D([$_conf], ['CONF']));

    $http_body = $mt->render(name2path($self->{_name})
                      )->as_string;
  }
  #
  else {
    $http_body = $mt->render('_error')->as_string;
#    $http_body = << "...";
#error: $self->{_name}
#...
  }

  print encode('utf-8', << "...");
$http_header

$http_body
...
}




1;
