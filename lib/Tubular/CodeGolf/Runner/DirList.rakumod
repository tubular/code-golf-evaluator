use Tubular::CodeGolf::Entity::Listable;
use Tubular::CodeGolf::Runner::Unit;

class Tubular::CodeGolf::Runner::DirList does Tubular::CodeGolf::Runner::Unit {
    method transform(Supply $in --> Supply) {
        supply {
            whenever $in -> $item {
                when $item ~~ Tubular::CodeGolf::Entity::Listable {
                    my $test = $item.dir-test;
                    whenever $item.dir-path -> $in-path {
                        .emit for $in-path.dir(:$test);
                    }
                }
                default {
                    .emit for $item.IO.dir;
                }
            }
        }
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Runner::DirList if $short_name
}
