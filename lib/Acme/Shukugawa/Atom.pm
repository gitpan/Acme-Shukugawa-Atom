# $Id: /mirror/coderepos/lang/perl/Acme-Shukugawa-Atom/trunk/lib/Acme/Shukugawa/Atom.pm 43740 2008-03-12T09:14:16.841440Z daisuke  $

package Acme::Shukugawa::Atom;
use strict;
use warnings;
use utf8;
use Encode qw(decode_utf8);
use Text::MeCab;

our $VERSION = '0.00001';

sub translate
{
    my $self   = shift;
    my $string = decode_utf8(shift);

    $self->preprocess(\$string);
    $self->runthrough(\$string);
    $self->postprocess(\$string);

    return $string;
}

sub preprocess
{
    my ($self, $strref) = @_;

    # Special case handling -- this could be optimized further
    # put it in a sharefile later
    my @special = (
        '別に' => 'ジリサワゴネタ',
        '予約した' => 'バミった',
        '[2２][4４]時|[0０]時' => 'テッペン',
        '巨乳|胸(?:の|が)(大きい|でかい|デカイ)' => 'パイオツカイデー',
        '女性|女の人|お姉さん|おねーさん' => 'チャンネー',
        'お?(?:ばあ|婆)さん' => 'チャンバー',
        '(?:おおきい|大きい)(?:のか?|か)?' => 'カイデー',
    );

    for(0..$#special/2) {
        my $pattern = $special[$_ * 2];
        my $replace = $special[$_ * 2 + 1];
        $$strref =~ s/$pattern/$replace/g;
    }
}

sub runthrough
{
    my ($self, $strref) = @_;

    my $mecab = Text::MeCab->new;

    # First, make it all katakana, except for where the surface is already
    # in hiragana
    my $ret = '';
    foreach (my $node = $mecab->parse($$strref);
        $node; $node = $node->next)
    {
        my $surface = decode_utf8($node->surface);
        next unless $surface;
        if ($surface =~ /^\p{InHiragana}+$/ || $surface =~ /^\p{InKatakana}+$/) {
            $ret .= $surface;
        } else {
            my $feature = decode_utf8($node->feature);

            if (my $yomi = (split(/,/, $feature))[8]) {
                $ret .= $self->atomize($yomi) || $surface;
            } else {
                $ret .= $surface;
            }
        }
    }
    $$strref = $ret;
}

sub postprocess {}

sub atomize
{
    my ($self, $yomi) = @_;
    $yomi =~ s/ー+/ー/g;

    my $length = length($yomi);
    if ($length <= 2) {
        return $yomi if $yomi =~ s/(.)([^ン])/$2ー$1ー/;
        return;
    }

    my $done = 0;
    if ($length == 4) { # 4 character words tend to have special xformation
        if ($yomi =~ s/^(.ー)(..)$/$2$1/) {
            $done = 1;
        }
    }

    if (! $done) {
        $yomi =~ s/(.(?:ー+)?)$//;
        $yomi = $1 . $yomi;
    }

    $yomi =~ s/ッ$/ツ/;
    return $yomi;
}


1;

__END__

=encoding UTF-8

=head1 NAME

Acme::Shukugawa::Atom - ギロッポンにテッペンでバミった

=head1 SYNOPSIS

  use Acme::Shukugawa::Atom;
  my $newstring = Acme::Shukugawa::Atom->translate($string);

=head1 DESCRIPTION

夙川アトム風な文章を作成します。

まだまだ足りない部分がありますので、もしよければt/01_basic.tに希望する変換前と
変換後の結果を書いてテストをアップデートしてお知らせください。変換を
可能にするようにコードを修正してみます。

svnが使える方はこちらからどうぞ：

  http://svn.coderepos.org/share.lang/perl/Acme-Shukugawa-Atom/trunk

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
