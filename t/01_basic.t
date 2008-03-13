use Test::Base;
use utf8;

plan tests => 1 + 1 * blocks;

use_ok("Acme::Shukugawa::Atom");


sub translate {
    Acme::Shukugawa::Atom->translate(shift);
}

filters {
    input => 'translate',
};

run_is;

__DATA__

===
--- input:    六本木の胸の大きいお姉さんがいる店を予約した
--- expected: ギロッポンのパイオツカイデーチャンネーがルーイーセーミーをバミった

===
--- input:    ハワイ
--- expected: ワイハー

===
--- input:    寿司
--- expected: シースー

===
--- input:    銀座で午前0時に寿司行こう
--- expected: ザギンでテッペンにシースーコウイー

===
--- input:    狼
--- expected: カミオー

===
--- SKIP
# mecabの辞書にない？
--- input:    鋏
--- expected: サミハー

===
--- input:    おばあさんの口はどうして大きいの？
--- expected: チャンバーのチークーはどうしてカイデー？

===
--- input:    別にdankogaiはエヌジーというわけではない
--- expected: ジリサワゴネタガイダンコはジーエヌというケーワーではない

===
--- input:    びっくり
--- expected: クリビツ
