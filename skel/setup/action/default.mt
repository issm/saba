# $_conf  : config hash
# $_query : query hash
# $_mm    : metamodel object

sub BEFORE {
  my $self = shift;

  '';
}


sub GET {
  my $self = shift;

  my $sample = $_mm->get_model('sample');
  my $samplelist = $sample->sample;

  $self->set_var(
    hello      => 'Hello, world!',
    samplelist => $samplelist,
  );

  '';
}


sub POST {
  my $self = shift;

  '';
}


sub AFTER {
  my $self = shift;

  '';
}
