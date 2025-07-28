use Tubular::CodeGolf::Entity::DirListMessage;
use Tubular::CodeGolf::Entity::Listable;
use Tubular::CodeGolf::Runner::Unit;

class Tubular::CodeGolf::Runner::DirList does Tubular::CodeGolf::Runner::Unit {
    method transform(Supply $in --> Supply) {
        supply {
            whenever $in -> $item {
                when $item ~~ Tubular::CodeGolf::Entity::Listable {
                    my $data = $item.data;
                    my $test = $item.dir-test;
                    whenever $item.dir-path -> $in-path {
                        Tubular::CodeGolf::Entity::DirListMessage.new(:$data, path => $_).emit for $in-path.IO.dir(:$test);
                    }
                }
                default {
                    Tubular::CodeGolf::Entity::DirListMessage.new(:data(), path => $_).emit for $item.IO.dir;
                }
            }
        }
    }
}
