package Plack::App::CPAN::Changes;

use base qw(Plack::Component::Tags::HTML);
use strict;
use warnings;

use Plack::Util::Accessor qw(changes generator title);
use Tags::HTML::CPAN::Changes;

our $VERSION = 0.01;

sub _css {
	my ($self, $env) = @_;

	$self->{'_tags_changes'}->process_css;

	return;
}

sub _prepare_app {
	my $self = shift;

	# Defaults which rewrite defaults in module which I am inheriting.
	if (! defined $self->generator) {
		$self->generator(__PACKAGE__.'; Version: '.$VERSION);
	}

	if (! defined $self->title) {
		$self->title('Changes');
	}

	# Inherite defaults.
	$self->SUPER::_prepare_app;

	# Defaults from this module.
	my %p = (
		'css' => $self->css,
		'tags' => $self->tags,
	);
	$self->{'_tags_changes'} = Tags::HTML::CPAN::Changes->new(%p);
	if (defined $self->changes) {
		$self->{'_tags_changes'}->init($self->changes);
	}

	return;
}

sub _tags_middle {
	my ($self, $env) = @_;

	$self->{'_tags_changes'}->process;

	return;
}

1;

__END__
