use Tubular::CodeGolf::Conf;

grammar TaskFolderParser {
    token TOP { <number> '-' <name> }
    token number { \d+ }
    token name { \w+ }
}

class Tubular::CodeGolf::Entity::Task {
    has Str $.number;
    has Str $.name;

    has Tubular::CodeGolf::Conf $!config .= new;

    multi method new(Str $task-name) {
        my $match = TaskFolderParser.parse($task-name);

        my %h = $match.hash.map: { $_.key => ~$_.value };
        return samewith(|%h);
    }

    method folder {
        return ($!number, $!name).join('-');
    }
}
