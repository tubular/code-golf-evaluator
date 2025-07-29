use Tubular::CodeGolf::Runner::Unit;

class Tubular::CodeGolf::Runner::EntityTransformer does Tubular::CodeGolf::Runner::Unit {
    has $!entity is built;

    method transform(Supply $in --> Supply) {
        return $in.map: { $!entity.new($_) };
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Runner::EntityTransformer if $short_name
}
