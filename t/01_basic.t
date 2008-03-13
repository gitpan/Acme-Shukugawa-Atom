use strict;
use utf8;
use Test::More (tests => 7);

BEGIN
{
    use_ok("Acme::Shukugawa::Atom");
}

my %data = (
    "六本木の胸の大きいお姉さんがいる店を予約した"
        => "ギロッポンのパイオツカイデーチャンネーがいるセーミーをバミった" ,
    "ハワイ" => "ワイハー",
    "寿司"   => "シースー",
    "銀座" => "ザギン",
    "狼" => "カミオー",
#     "鋏" => "サミハー", <- mecabの辞書にない？
    "おばあさんの口はどうして大きいの？" =>
        "チャンバーのチークーはどうしてカイデー？"
);

while (my($orig, $expected) = each %data) {
    is( Acme::Shukugawa::Atom->translate($orig), $expected );
}