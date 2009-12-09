# must specify as 'DBI' or 'YAML
sub dsi_type { 'DBI'; }

sub sample {
  my $self = shift;
  my $sel = $_dsi->q('sample::sample__select[1,2]');
}
