use strict;
use utf8;
use Test::More (tests => 4);

BEGIN
{
    use_ok("Acme::Shukugawa::Atom");
}

my %data = (
    "六本木の胸の大きいお姉さんがいる店を予約した"
        => "ギロッポンのパイオツカイデーチャンネーがいるセーミーをバミった" ,
    "狼" => "カミオー",
    "おばあさんの口はどうして大きいの？" =>
        "チャンバーのチークーはどうしてカイデー？"
);

while (my($orig, $expected) = each %data) {
    is( Acme::Shukugawa::Atom->translate($orig), $expected );
}