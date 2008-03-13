# $Id: /mirror/coderepos/lang/perl/Acme-Shukugawa-Atom/trunk/lib/Acme/Shukugawa/Atom.pm 43770 2008-03-13T01:45:34.634120Z daisuke  $

package Acme::Shukugawa::Atom;
use strict;
use warnings;
use utf8;
use Encode qw(decode_utf8);
use Text::MeCab;

our $VERSION = '0.00002';

sub translate
{
    my $self   = shift;
    my $string = decode_utf8(shift);

    $self->preprocess(\$string);
    $self->runthrough(\$string);
    $self->postprocess(\$string);

    return $string;
}

# Special case handling -- this could be optimized further
# put it in a sharefile later
my (@SPECIAL, $EXCEPTION);
BEGIN
{
    @SPECIAL = (
        '銀座' => 'ザギン',
        '別に' => 'ジリサワゴネタ',
        '予約した' => 'バミった',
        '[2２][4４]時|[0０]時' => 'テッペン',
        '巨乳|胸(?:の|が)(大きい|でかい|デカイ)' => 'パイオツカイデー',
        '女性|女の人|お姉さん|おねーさん' => 'チャンネー',
        'お?(?:ばあ|婆)さん' => 'チャンバー',
        '(?:おおきい|大きい)(?:のか?|か)?' => 'カイデー',
    );
    $EXCEPTION = decode_utf8(join("|",
        map { $SPECIAL[$_ * 2 + 1] } (0..$#SPECIAL/2) ));
}

sub preprocess
{
    my ($self, $strref) = @_;

    for(0..$#SPECIAL/2) {
        my $pattern = $SPECIAL[$_ * 2];
        my $replace = $SPECIAL[$_ * 2 + 1];
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

    foreach my $text (split(/($EXCEPTION)/, $$strref)) {
        if ($text =~ /$EXCEPTION/) {
            $ret .= $text;
            next;
        }

        foreach (my $node = $mecab->parse($text); $node; $node = $node->next) {
            my $surface = decode_utf8($node->surface);
            next unless $surface;
            if ($surface =~ /^\p{InHiragana}+$/) {
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
    }
    $$strref = $ret;
}

sub postprocess {}

# シースールール
# 寿司→シースー
# ン、が最後だったらひっくり返さない
my $small    = decode_utf8("[ャュョッー]");
my $syllable = decode_utf8("(?:.$small?)");
my $nbar     = decode_utf8("^ンー");
sub apply_shisu_rule
{
    my ($self, $yomi) = @_;
    return $yomi if $yomi =~ s/^($syllable)($syllable)$/$2ー$1ー/;
    return;
}

# ワイハールール
# ハワイ→ワイハー
sub apply_waiha_rule
{
    my ($self, $yomi) = @_;

    if ($yomi =~ s/^(${syllable}[$nbar]?)([^$nbar].)$/$2$1/) {
        $yomi =~ s/([^ー])$/$1ー/;
        return $yomi;
    }
    return;
}

sub atomize
{
    my ($self, $yomi) = @_;
    $yomi =~ s/ー+/ー/g;

    # Length
    my $length = length($yomi);
    $length -= ($yomi =~ /$small/g);
    if ($length == 2) {
        return $self->apply_shisu_rule($yomi);
    }

    if ($length == 3) {
        return $self->apply_waiha_rule($yomi);
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

  http://svn.coderepos.org/share/lang/perl/Acme-Shukugawa-Atom/trunk

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
