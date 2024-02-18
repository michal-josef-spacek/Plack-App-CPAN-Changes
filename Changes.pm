package Plack::App::CPAN::Changes;

use base qw(Plack::Component::Tags::HTML);
use strict;
use warnings;

use Plack::Util::Accessor qw(generator message_cb redirect_change_password
	redirect_error title);
use Plack::Request;
use Plack::Response;
use Plack::Session;
use Tags::HTML::ChangePassword;
use Tags::HTML::Container;

our $VERSION = 0.01;

sub _css {
	my ($self, $env) = @_;

	$self->{'_tags_change_password'}->process_css;
	$self->{'_tags_container'}->process_css;

	return;
}

sub _message {
	my ($self, $env, $message_type, $message) = @_;

	if (defined $self->message_cb) {
		$self->message_cb->($env, $message_type, $message);
	}

	return;
}

sub _prepare_app {
	my $self = shift;

	# Defaults which rewrite defaults in module which I am inheriting.
	if (! defined $self->generator) {
		$self->generator(__PACKAGE__.'; Version: '.$VERSION);
	}

	if (! defined $self->title) {
		$self->title('Change password page');
	}

	# Inherite defaults.
	$self->SUPER::_prepare_app;

	# Defaults from this module.
	my %p = (
		'css' => $self->css,
		'tags' => $self->tags,
	);
	$self->{'_tags_change_password'} = Tags::HTML::ChangePassword->new(%p);
	$self->{'_tags_change_password'}->prepare({
		'info' => 'blue',
		'error' => 'red',
	});
	$self->{'_tags_container'} = Tags::HTML::Container->new(%p);

	return;
}

sub _process_actions {
	my ($self, $env) = @_;

	if (defined $self->change_password_cb && $env->{'REQUEST_METHOD'} eq 'POST') {
		my $req = Plack::Request->new($env);
		my $body_params_hr = $req->body_parameters;
		my ($status, $messages_ar) = $self->_password_change_check($env, $body_params_hr);
		my $res = Plack::Response->new;
		if ($status) {
			if ($self->change_password_cb->($env, $body_params_hr->{'old_password'},
				$body_params_hr->{'password1'})) {

				$self->_message($env, 'info',
					"Password was changed.");
				$res->redirect($self->redirect_change_password);
			} else {
				$res->redirect($self->redirect_error);
			}
		} else {
			$res->redirect($self->redirect_error);
		}
		$self->psgi_app($res->finalize);
		return;
	}

	my $messages_ar = [];
	if (exists $env->{'psgix.session'}) {
		my $session = Plack::Session->new($env);
		$messages_ar = $session->get('messages');
		$session->set('messages', []);
		$self->{'_tags_change_password'}->init($messages_ar);
	}

	return;
}

sub _password_change_check {
	my ($self, $env, $body_parameters_hr) = @_;

	if (! exists $body_parameters_hr->{'change_password'}
		|| $body_parameters_hr->{'change_password'} ne 'change_password') {

		$self->_message($env, 'error', 'There is no change password POST.');
		return 0;
	}
	if (! defined $body_parameters_hr->{'old_password'} || ! $body_parameters_hr->{'old_password'}) {
		$self->_message($env, 'error', "Parameter 'old_password' doesn't defined.");
		return 0;
	}
	if (! defined $body_parameters_hr->{'password1'} || ! $body_parameters_hr->{'password1'}) {
		$self->_message($env, 'error', "Parameter 'password1' doesn't defined.");
		return 0;
	}
	if (! defined $body_parameters_hr->{'password2'} || ! $body_parameters_hr->{'password2'}) {
		$self->_message($env, 'error', "Parameter 'password2' doesn't defined.");
		return 0;
	}
	if ($body_parameters_hr->{'password1'} ne $body_parameters_hr->{'password2'}) {
		$self->_message($env, 'error', 'Passwords are not same.');
		return 0;
	}

	return 1;
}

sub _tags_middle {
	my ($self, $env) = @_;

	$self->{'_tags_container'}->process(
		sub {
			$self->{'_tags_change_password'}->process;
		},
	);

	return;
}

1;

__END__
