# must specify as 'DBI' or 'YAML
sub dsi_type { 'YAML'; }

sub sample {
  my $self = shift;
  #$_dsi;

  [ {id => 1, name => 'foo'},
    {id => 2, name => 'bar'},
    {id => 3, name => 'baz'},
    {id => 4, name => 'hoge'},
    {id => 5, name => 'fuga'},
  ];
}
