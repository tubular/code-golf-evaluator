use Tubular::CodeGolf::Runner::Unit;

class Tubular::CodeGolf::Runner::EntityTransformer does Tubular::CodeGolf::Runner::Unit {
    has $!entity is built;

    method transform(Supply $in --> Supply) {
        return $in.map: { $!entity.new($_) };
    }
}
