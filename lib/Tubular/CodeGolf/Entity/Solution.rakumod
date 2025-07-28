use Tubular::CodeGolf::Conf;
use Tubular::CodeGolf::Entity::DirListMessage;
use Tubular::CodeGolf::Entity::TestSuite;

grammar SolutionFileName {
    token TOP { <author> '-' <version> '.' <extension> }
    token author { <[a .. z] + [\d] + [_]>+ }
    token version { \d+ }
    token extension { \w+ }
}

class SolutionFileNameActions {
    method TOP ($/) {
        make {
            author  => $<author>.made,
            version => $<version>.made,
        }
    }
    method author($/) { make ~$/ }
    method version($/) { make $/.Int }
}

grammar Shebang {
    rule TOP {
        '#!'
        [ '/usr/bin/env' <option>* ]
        <interpreter>
        <optargs>
    }

    token optargs {
        <option>*
    }

    token option {
        '-' <[-] + [\w]>+
    }

    token interpreter {
        <[/] + [a..z] + [\d]>+
    }
}

class ShebangActions {
    method TOP($/) {
        make {
            language => $<interpreter>.made,
            optargs => $<optargs>.made,
        }
    }

    method interpreter($/) { make $/.Str.IO.basename }
    method optargs($/) { make ~$/ }
}

class Tubular::CodeGolf::Entity::Solution {
    has Tubular::CodeGolf::Entity::TestSuite $.test-suite;
    has IO::Path $.path;
    has Str $.author;
    has Int $.version;
    has Str $.language;
    has Int $.size;

    has Tubular::CodeGolf::Conf $!config .= new;

    multi method new(Tubular::CodeGolf::Entity::DirListMessage $msg) {
        my $test-suite = $msg.data;
        my $path = $msg.path;
        my $filename = $path.basename;

        my $solution-match = SolutionFileName.parse($filename, actions => SolutionFileNameActions);
        unless $solution-match {
            die "Can't parse solution name: $filename, should be in format: `<author>-<number>.<extension>";
        }
        my %solution-info = $solution-match.made;

        my $size = $msg.path.s;
        my $shebang = $msg.path.lines.first;
        my $match-shebang = Shebang.parse($shebang, actions => ShebangActions);
        unless $match-shebang {
            die "Can't parse shebang of {$msg.path.Str}: $shebang";
        }
        my %shebang = $match-shebang.made;
        $size -= $shebang.encode('ascii').bytes + 1 - %shebang<optargs>.encode('ascii').bytes;
        my $language = %shebang<language>;

        samewith(
            :$test-suite,
            :$path,
            :$language,
            :$size,
            |%solution-info,
        );
    }
}
