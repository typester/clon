#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, '..', 'lib' );

use File::Temp;
use Path::Class qw/file dir/;
use Template;

use Getopt::Long;

GetOptions(
    \my %opt,
    qw/help debug lighttpd=s port=i/,
);
$opt{port} ||= 3000;
$opt{lighttpd} ||= '/usr/sbin/lighttpd';

$ENV{CATALYST_DEBUG} = 1 if $opt{debug};

my $child;
if ( !($child = fork) ) {
    my $fastcgi = file($FindBin::Bin)->parent->subdir('script')->file('clon_fastcgi.pl');
    my $socket  = file($FindBin::Bin)->parent->subdir('tmp')->file('socket');

    system "$fastcgi", '-l', "$socket", '-e';
}
else {

    my $fh  = File::Temp->new;

    my $mime_types = do {
        my $res = "mimetype.assign = (\n";
        my %known_extensions;
        for my $line ( file('/etc/mime.types')->slurp ) {
            $line =~ s/\#.*//;

            if ( my ( $type, $exts )
                = $line =~ /^([a-z0-9\/+-.]+)\s+((?:[a-z0-9.+-]+[ ]?)+)$/ )
            {
                for my $ext ( split / /, $exts ) {
                    next if $known_extensions{$ext};
                    $known_extensions{$ext} = 1;
                    $res .= qq{".$ext" => "$type",\n};
                }
            }
        }
        $res .= ")\n";
        $res;
    };

    my $template = <<'__CONF__';
server.modules = (
    "mod_fastcgi",
)

server.document-root = "[% home.subdir('root') %]"
server.port = [% opt.port %]

[% mime_types %]

$HTTP["url"] =~ "^/(?!js/|css/|images?/|swf/|static/|tmp/|favicon\.ico$|crossdomain\.xml$)" {
    fastcgi.server = (
        "" => (
            (
                "socket" => "[% home.subdir('tmp').file('socket') %]",
                "check-local" => "disable",
            )
        ),
    )
}

__CONF__

    my $tt = Template->new;
    $tt->process(
        \$template,
        {   home       => dir($FindBin::Bin)->parent,
            opt        => \%opt,
            mime_types => $mime_types,
        },
        \my $conf
    );

    print $fh $conf;

    system( $opt{lighttpd}, '-f', $fh->filename, '-D' );
}
