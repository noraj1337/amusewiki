#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 'lib';
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use Cwd;
use Getopt::Long;
use File::Temp;

my ($logformat, $help, $ssl_key, $secure_only);
my $nginx_root = '/etc/nginx';
my $default_key = "ssl/amusewiki.key";
my $default_crt = "ssl/amusewiki.crt";

GetOptions ('log-format=s' => \$logformat,
            help => \$help,
            'ssl-key=s' => \$ssl_key,
            'nginx-root=s' => \$nginx_root,
            'secure-only' => \$secure_only,
           ) or die;

if ($ssl_key) {
    unless (-f catfile($nginx_root, 'ssl', $ssl_key)) {
        die catfile($nginx_root, 'ssl', $ssl_key) . " doesn't exist\n";
    }
}



if ($help) {
    print <<"HELP";

Usage: $0 [ options ]

Create the nginx configuration for amusewiki. The output consists of
two files: "amusewiki_include" and "amusewiki". The first must be
installed in the root of the nginx configuration directory, usually
/etc/nginx. This is the include with the common configuration.

The second, "amusewiki", is the virtual host configuration, where
we set the server names and the SSL certificates.

Options:

 --help

 Print this message and exit

 --log-format <combined>

 Set the logging for the amusewiki request. Common value is
 "combined". Not set if not provided.

 --ssl-key

 We assume you'll have two kinds of sites. The ones with a self-signed
 certificate, and the ones with a "good" one, provided by a CA.

 For the self-signed ones, the ssl key and certificate are assumed to
 be the ones generated by script/generate-ssl-certs.pl [--wildcards],
 i.e., /etc/nginx/ssl/amusewiki.key and /etc/nginx/ssl/amusewiki.crt

 The signed certificates are detected if the filename matches the
 canonical of the site, and they ssl-key will be the one passed as
 argument. If you don't provide ssl-key, we don't even try to look
 them up, and use the self-signed ones in any case.

 Example: canonical amusewiki.org has a signed cert in
    /etc/nginx/ssl/amusewiki.org.crt and this one will be used, if you
    pass a value to --ssl-key. Otherwise will try to use amusewiki.crt
    and amusewiki.key.

       $0 --ssl-key server.key

     The config will have ssl/server.key as key and
     ssl/amusewiki.org.crt as key and cert, if amusewiki.org.crt
     exists.

 --nginx-root

 Defaults to /etc/nginx

 --secure-only

 If this option is passed, redirect the http sites to https if there
 is a matching certificate for this site.

HELP
    exit 2;
}
my $amw_home = getcwd;
unless (-f catfile($amw_home, qw/lib AmuseWikiFarm.pm/)) {
    die "This script must be executed from the root of the application\n";
}


my $schema = AmuseWikiFarm::Schema->connect('amuse');

my @sites = $schema->resultset('Site')->search(undef, { order_by => [qw/id/] })->all;

my $output_dir = File::Temp->newdir(CLEANUP => 0,
                                    TMPDIR => 1,
                                    TEMPLATE => 'nginx-amusewiki-XXXXXXXX')
  ->dirname;

print "Files saved in $output_dir\n";



# globals
my $cgit = "### cgit is not installed ###\n";
my $cgit_path = catfile(qw/root git cgit.cgi/);

if (-f $cgit_path) {
    $cgit = <<"EOF";
server {
    listen 127.0.0.1:9015;
    server_name localhost;
    location /git/ {
        root $amw_home/root;
        fastcgi_split_path_info ^/git()(.*);
        fastcgi_param   PATH_INFO       \$fastcgi_path_info;
        fastcgi_param   SCRIPT_FILENAME \$document_root/git/cgit.cgi;

        fastcgi_param  QUERY_STRING       \$query_string;
        fastcgi_param  REQUEST_METHOD     \$request_method;
        fastcgi_param  CONTENT_TYPE       \$content_type;
        fastcgi_param  CONTENT_LENGTH     \$content_length;

        fastcgi_param  SCRIPT_NAME        \$fastcgi_script_name;
        fastcgi_param  REQUEST_URI        \$request_uri;
        fastcgi_param  DOCUMENT_URI       \$document_uri;
        fastcgi_param  DOCUMENT_ROOT      \$document_root;
        fastcgi_param  SERVER_PROTOCOL    \$server_protocol;
        fastcgi_param  HTTPS              \$https if_not_empty;

        fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
        fastcgi_param  SERVER_SOFTWARE    nginx/\$nginx_version;

        fastcgi_param  REMOTE_ADDR        \$remote_addr;
        fastcgi_param  REMOTE_PORT        \$remote_port;
        fastcgi_param  SERVER_ADDR        \$server_addr;
        fastcgi_param  SERVER_PORT        \$server_port;
        fastcgi_param  SERVER_NAME        \$server_name;

        fastcgi_pass    unix:/var/run/fcgiwrap.socket;
    }
}
EOF
}

my $conf_file = catfile($output_dir, 'amusewiki');
open (my $fhc, '>:encoding(UTF-8)', $conf_file) or die "Cannot open $conf_file $!";
print $fhc $cgit;
foreach my $site (@sites) {
    print $fhc insert_server_stanza($site);
}
close $fhc;

my $include_file = catfile($output_dir, 'amusewiki_include');
open (my $fh, '>:encoding(UTF-8)', $include_file) or die $!;
print $fh <<"INCLUDE";
    root $amw_home/root;

    # LEGACY STUFF
    rewrite ^/lib/(.*)\$ /library/\$1 permanent;
    rewrite ^/HTML/(.*)\\.html\$ /library/\$1 permanent;
    rewrite ^/pdfs/a4/(.*)_a4\\.pdf /library/\$1.pdf permanent;
    rewrite ^/pdfs/letter/(.*)_letter\\.pdf /library/\$1.pdf permanent;
    rewrite ^/pdfs/a4_imposed/(.*)_a4_imposed\\.pdf /library/\$1.a4.pdf permanent;
    rewrite ^/pdfs/letter_imposed/(.*)_letter_imposed\\.pdf /library/\$1.lt.pdf permanent;
    rewrite ^/print/(.*)\\.html /library/\$1.html permanent;
    rewrite ^/epub/(.*)\\.epub /library/\$1.epub permanent;
    rewrite ^/topics/(.*)\\.html /category/topic/\$1 permanent;
    rewrite ^/authors/(.*)\\.html /category/author/\$1 permanent;
    # END LEGACY STUFF

    # deny direct access to the cgi file
    location /git/cgit.cgi {
        deny all;
    }
    location /src/ {
        deny all;
    }
    location /themes/ {
        deny all;
    }
    location /private/repo/ {
        internal;
        alias $amw_home/repo/;
    }
    location /private/bbfiles/ {
        internal;
        alias $amw_home/bbfiles/;
    }
    location /private/staging/ {
        internal;
        alias $amw_home/staging/;
    }
    location / {
        try_files \$uri \@proxy;
        expires max;
    }
    location \@proxy {
        fastcgi_param  QUERY_STRING       \$query_string;
        fastcgi_param  REQUEST_METHOD     \$request_method;
        fastcgi_param  CONTENT_TYPE       \$content_type;
        fastcgi_param  CONTENT_LENGTH     \$content_length;

        fastcgi_param  SCRIPT_NAME        '';
        fastcgi_param  PATH_INFO          \$fastcgi_script_name;
        fastcgi_param  REQUEST_URI        \$request_uri;
        fastcgi_param  DOCUMENT_URI       \$document_uri;
        fastcgi_param  DOCUMENT_ROOT      \$document_root;
        fastcgi_param  SERVER_PROTOCOL    \$server_protocol;
        fastcgi_param  HTTPS              \$https if_not_empty;

        fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
        fastcgi_param  SERVER_SOFTWARE    nginx/\$nginx_version;

        fastcgi_param  REMOTE_ADDR        \$remote_addr;
        fastcgi_param  REMOTE_PORT        \$remote_port;
        fastcgi_param  SERVER_ADDR        \$server_addr;
        fastcgi_param  SERVER_PORT        \$server_port;
        fastcgi_param  SERVER_NAME        \$server_name;

        fastcgi_param HTTP_X_SENDFILE_TYPE X-Accel-Redirect;
        fastcgi_param HTTP_X_ACCEL_MAPPING $amw_home=/private;
        fastcgi_pass  unix:$amw_home/var/amw.sock;
    }
INCLUDE

close $fh;

my $conf_target = catfile($nginx_root, qw/sites-enabled amusewiki/);
my $include_target = catfile($nginx_root, 'amusewiki_include');
print <<"HELP";
please execute the following command as root

cat $include_file > $include_target
cat $conf_file > $conf_target
nginx -t && service nginx reload

HELP

sub insert_server_stanza {
    my ($site) = @_;
    my $canonical = $site->canonical;
    my @vhosts = $site->alternate_hostnames;
    my $hosts = join("\n" . (" " x 16),  $canonical, @vhosts);
    my $out = '';
    my $redirect_to_secure;

    $out = <<"DEFAULT";
    listen 80;
    listen 443 ssl;
    ssl_certificate_key $default_key;
    ssl_certificate     $default_crt;
DEFAULT

    if ($ssl_key) {
        my $ca_cert = $canonical . '.crt';
        if (-f catfile($nginx_root, 'ssl', $ca_cert)) {
            $out = '';
            if ($secure_only) {
                $redirect_to_secure = 1;
            }
            else {
                $out .= "    listen 80;\n";
            }
            $out .= "    listen 443 ssl;\n";
            $out .= "    ssl_certificate     ssl/$ca_cert;\n";
            $out .= "    ssl_certificate_key ssl/$ssl_key;\n";
        }
    }
    $out .= "    server_name $hosts;\n";
    if ($logformat) {
        $out .= "    access_log /var/log/nginx/$canonical.log $logformat;\n";
    }
    $out .= "    include amusewiki_include;\n";
    my $stanza = "server {\n$out\n}\n";
    if ($redirect_to_secure) {
        $stanza .= <<"REDIRECT";
server {
    listen 80;
    server_name $hosts;
    return 301 https://$canonical\$request_uri;
}
REDIRECT
    }
    $stanza .= "\n";
    return $stanza;
}
