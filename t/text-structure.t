#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 32;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;
use AmuseWikiFarm::Archive::BookBuilder;

my $schema = AmuseWikiFarm::Schema->connect('amuse');


my $testnotoc =<<'MUSE';
#lang en
#teaser blah
#title helloooo <&!"'title>

Hello

MUSE

my $testnotocwithfinal =<<'MUSE';
#lang en
#title helloooo <&!"'title>
#notes This is a not

Hello

MUSE


my $test_no_intro =<<'MUSE';
#lang en
#title Hullllooooo <&!"'title>

*** subsection

* Part

** Chap 1

** Chap 2

**** Subsection
MUSE

my $testbody =<<'MUSE';
#title hello world <&!"'title>

Hello world!

**** Intro

Introduction

* Part 1

**** subsection before chapter

** Chapter *1*

Chapter body

*** Section *1.1*

Section body

*** Section **1.2**

Section body

** Chapter *2*

Chapter body

**** subsection of chapter 2

*** Section **2.1**

Section body

**** Subsection 2.1.1 & test

Subsection body

**** Subsection 2.1.1

Subsection body 2

** Chapter 3

Section 

**** Subsection 3.0.1 [1]

Subsection

[1] example

Subsection

***** Subsubsection

Subsub section

* Part 2

Part again

*** Section of second part

bdoy

** Chapter of second part

body

**** Subsection of chap 1 of part 2.

* Part 3

body

**** Subsection of part 3

body

** Chapter 1 of part 3

body

**** Subsection of part 3, chap 1

body

** Chapter 2 of part 3

body

body

** Chapter 3 of part 3

body

MUSE

my @tests = (
             {
              body => $testnotoc,
              name => 'notoc',
             },
             {
              body => $testnotocwithfinal,
              name => 'notoc-finalpage',
             },
             {
              body => $test_no_intro,
              name => 'nointro',
             },
             {
              body => $testbody,
              name => 'full',
             }
            );

my $site = create_site($schema, '0textstruct0');
$site->update({ secure_site => 0,
                pdf => 0,
                epub => 0,
                html => 1,
              });

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);


foreach my $muse (@tests) {
    my ($rev) = $site->create_new_text({ title => $muse->{name} }, 'text');
    $rev->edit($muse->{body});
    $rev->commit_version;
    $rev->publish_text;
    my $title = $rev->title->discard_changes;
    $mech->get_ok($title->full_uri);
    $mech->get_ok($title->full_toc_uri);
    # diag Dumper($title->_retrieve_text_structure);
    $title->_parse_text_structure;
    my @old = @{$title->_retrieve_text_structure};
    my @new = @{$title->_parse_text_structure};
    # changes wrt old version
    foreach my $el (@old) {
        delete $el->{padding};
        delete $el->{toc};
        delete $el->{highlevel};
        $el->{title} ||= '';
        $el->{title} =~ s!<.*?>!!g;
        foreach my $name (qw/title index level/) {
            $el->{"part_$name"} = delete $el->{$name};
        }
    }
    foreach my $el (@new) {
        delete $el->{part_size};
        delete $el->{toc_index};
    }
    is_deeply(\@new, \@old);
    diag Dumper($title->_parse_text_structure);
    ok $title->text_size;
    ok $title->pages_estimated;
    diag join(" ", $title->uri, $title->text_size, pages => $title->pages_estimated);
    my $bb = AmuseWikiFarm::Archive::BookBuilder->new({ site => $site->discard_changes });
    my $est = $bb->pages_estimated_for_text($title->uri . ':pre,0,1,2,3,4,5,6,7,8,9,10,post');
    ok $est, "Found estimated pages $est";
    diag Dumper($title->text_html_structure);
}

$mech->get_ok('/latest');
$mech->content_lacks('amw-show-text-type-and-number-of-pages');
$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
is $mech->status, '200';
$mech->get_ok("/user/site");
$mech->form_id("site-edit-form");
$mech->tick(show_type_and_number_of_pages => 'on');
$mech->click("edit_site");
$mech->content_lacks(q{id="error_message"}) or die $mech->content;

$mech->get_ok('/latest');
$mech->content_contains('amw-show-text-type-and-number-of-pages');

