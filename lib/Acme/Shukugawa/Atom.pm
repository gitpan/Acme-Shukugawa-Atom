# $Id: /mirror/coderepos/lang/perl/Acme-Shukugawa-Atom/trunk/lib/Acme/Shukugawa/Atom.pm 47660 2008-03-13T07:01:48.357924Z daisuke  $

package Acme::Shukugawa::Atom;
use strict;
use warnings;
use utf8;
use Encode qw(decode_utf8);
use Text::MeCab;

our $VERSION = '0.00003';

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
my (@SPECIAL, $EXCEPTION, $RE_SMALL, $RE_SYLLABLE, $RE_NBAR);
BEGIN
{
    $RE_SMALL    = decode_utf8("[ャュョッー]");
    $RE_SYLLABLE = decode_utf8("(?:.$RE_SMALL?)");
    $RE_NBAR     = decode_utf8("^ンー");
    @SPECIAL = (
        '小飼弾|(?i)dankogai|(?i)kogaidan' => 'ガイダンコ',
        '銀座' => 'ザギン',
        '別に' => 'ジリサワゴネタ',
        '予約した' => 'バミった',
        '[2２][4４]時|午前[0０]時' => 'テッペン',
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
            next unless $node->surface;
            my $surface = decode_utf8($node->surface);
            my $feature = decode_utf8($node->feature);
            my ($type, $yomi) = (split(/,/, $feature))[0,8];

            if ($type eq '動詞' && $node->next) {
                # 助動詞を計算に入れる
                my $next_feature = decode_utf8($node->next->feature);
                my ($next_type, $next_yomi) = (split(/,/, $next_feature))[0,8];
                if ($next_type eq '助動詞') {
                    $yomi .= $next_yomi;
                    $node = $node->next;
                }
            }

            if ($type =~ /副詞|助動詞|形容詞|接続詞|助詞/ && $surface =~ /^\p{InHiragana}+$/) {
                $ret .= $surface;
            } elsif ($yomi) {
                $ret .= $self->atomize($yomi) || $surface;
            } else {
                $ret .= $surface;
            }
        }
    }
    $$strref = $ret;
}

sub postprocess {}

# シースールール
# 寿司→シースー
# ン、が最後だったらひっくり返さない
sub apply_shisu_rule
{
    my ($self, $yomi) = @_;
    return $yomi if $yomi =~ s/^($RE_SYLLABLE)($RE_SYLLABLE)$/$2ー$1ー/;
    return;
}

# ワイハールール
# ハワイ→ワイハー
sub apply_waiha_rule
{
    my ($self, $yomi) = @_;

# warn "WAIHA $yomi";
    if ($yomi =~ s/^(${RE_SYLLABLE}[$RE_NBAR]?)([^$RE_NBAR].)$/$2$1/) {
        $yomi =~ s/(^.[^ー].*[^ー])$/$1ー/;
        return $yomi;
    }
    return;
}

# クリビツルール
# びっくり→クリビツ
sub apply_kuribitsu_rule
{
    my ($self, $yomi) = @_;

# warn "KURIBITSU $yomi";
    if ($yomi =~ s/^(..)([^$RE_NBAR]${RE_SYLLABLE}$)/$2$1/) {
        return $yomi;
    }
    return;
}

sub atomize
{
    my ($self, $yomi) = @_;
    $yomi =~ s/ー+/ー/g;

    # Length
    my $word_length = length($yomi);
    my $length = $word_length - ($yomi =~ /$RE_SMALL/g);
    if ($length == 3 && $yomi =~ s/^(${RE_SYLLABLE})ッ/${1}ツ/) {
# warn "Special rule!";
        $length = 4;
    }
    my $done = 0;

# warn "$yomi LENGTH: $length";
    if ($length == 2) {
        my $tmp = $self->apply_shisu_rule($yomi);
        if ($tmp) {
            $yomi = $tmp;
            $done = 1;
        }
    }

    if ($length == 3) {
        my $tmp = $self->apply_waiha_rule($yomi);
        if ($tmp) {
            $yomi = $tmp;
            $done = 1;
        }
    }

    if ($length == 4) { # 4 character words tend to have special xformation
        my $tmp = $self->apply_kuribitsu_rule($yomi);
        if ($tmp) {
            $yomi = $tmp;
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
