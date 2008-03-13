use strict;
use inc::Module::Install;

name('Acme-Shukugawa-Atom');
all_from('lib/Acme/Shukugawa/Atom.pm');
requires('Text::MeCab', '0.20007');
requires('Encode');

use_test_base;

auto_install;
WriteAll;
