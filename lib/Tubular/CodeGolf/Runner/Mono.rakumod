use Tubular::CodeGolf::Runner::Producer;

class Tubular::CodeGolf::Runner::Mono does Tubular::CodeGolf::Runner::Producer {
    has $!value is built;

    method transform(--> Supply) {
        return Supply.from-list($!value);
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Runner::Mono if $short_name
}
