#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTTP::Headers::ActionPack');
}

my $pack = HTTP::Headers::ActionPack->new;
isa_ok($pack, 'HTTP::Headers::ActionPack');

my $media_type = $pack->create( 'Content-Type' => 'application/xml;charset=UTF-8' );
isa_ok($media_type, 'HTTP::Headers::ActionPack::MediaType');

is($media_type->to_string, 'application/xml; charset="UTF-8"', '... got the right string');

my $links = $pack->create( 'Link' => '</test/tree/1_2>; tag="child", </test/tree/1_1>; tag="child", </test/tree>; rel="up"');
isa_ok($links, 'HTTP::Headers::ActionPack::LinkList');

is($links->to_string, '</test/tree/1_2>; tag="child", </test/tree/1_1>; tag="child", </test/tree>; rel="up"', '... got the right string');

done_testing;