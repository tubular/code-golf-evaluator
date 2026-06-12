use Tubular::CodeGolf::Runner::Unit;

class Tubular::CodeGolf::Runner::Filter does Tubular::CodeGolf::Runner::Unit {
    has &!pred is built;

    method transform(Supply $in --> Supply) {
        return $in.grep(&!pred);
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Runner::Filter if $short_name
}
