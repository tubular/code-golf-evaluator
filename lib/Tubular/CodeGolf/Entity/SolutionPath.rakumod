use Tubular::CodeGolf::Conf;
use Tubular::CodeGolf::Entity::Listable;

class Tubular::CodeGolf::Entity::SolutionPath does Tubular::CodeGolf::Entity::Listable {
    has IO::Path $.path is built is required;
    has Tubular::CodeGolf::Conf $!config = Tubular::CodeGolf::Conf.new;

    multi method new(IO::Path $path) {
        samewith(:$path);
    }

    method dir-path returns Supply {
        supply {
            $!path.add($!config.get('SOLUTIONS_PATH')).emit;
        }
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Entity::SolutionPath if $short_name
}
