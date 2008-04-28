package CLON;
use strict;
use warnings;

use Catalyst::Runtime '5.70';
use Catalyst qw/ConfigLoader/;

our $VERSION = '0.02';

__PACKAGE__->config(
    'Plugin::ConfigLoader' => { file => 'config' },
);

__PACKAGE__->setup;

1;
