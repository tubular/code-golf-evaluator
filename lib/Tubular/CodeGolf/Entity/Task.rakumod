use Tubular::CodeGolf::Conf;
use Tubular::CodeGolf::Entity::DirListMessage;
use Tubular::CodeGolf::Entity::Listable;

grammar TaskFolderParser {
    token TOP { <number> '-' <name> }
    token number { \d+ }
    token name { \w+ }
}

class Tubular::CodeGolf::Entity::Task does Tubular::CodeGolf::Entity::Listable {
    has Str $.number;
    has Str $.name;

    has Tubular::CodeGolf::Conf $!config .= new;

    multi method new(Tubular::CodeGolf::Entity::DirListMessage $msg) {
        my $match = TaskFolderParser.parse($msg.path.basename);

        my %h = $match.hash.map: { $_.key => ~$_.value };
        return samewith(|%h);
    }

    method folder {
        return ($!number, $!name).join('-');
    }

    method fq-folder {
        return $!config.get('CODEGOLF_PATH').IO.add(self.folder);
    }

    method dir-test returns Code {
        &{ /'.in' $/ }
    }

    method dir-path returns Supply {
        supply {
            self.fq-folder.add($!config.get('TESTS_PATH')).emit;
        }
    }

    method data {
        return self;
    }
}
