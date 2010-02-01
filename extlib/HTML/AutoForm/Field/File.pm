package HTML::AutoForm::Field::File;

use utf8;

our @ISA;
our %defaults;

BEGIN {
    @ISA = qw(HTML::AutoForm::Field::AnyText);
    %Defaults = (
        mime => undef,
    );
    Class::Accessor::Lite->mk_accessors(keys %Defaults);
}

sub new {
    my $klass = shift;
    my $self = $klass->SUPER::new(
        %Defaults,
        @_ == 1 ? %{$_[0]} : @_,
    );
}

sub type { 'file' }

sub _per_field_validate {
    my ($self, $query) = @_;
    my $result = $self->SUPER::_per_field_validate($query); 
    $result and return $result;

    my $value = $query->param($self->name);
    my $r = $self->mime;
    if ($value && $r) {
        my $mime = $query->upload_info($value, 'mime');
        return HTML::AutoForm::Error->INVALID_DATA($self)
        if $mime !~ /$r/;
    }
    return;
}

1;
