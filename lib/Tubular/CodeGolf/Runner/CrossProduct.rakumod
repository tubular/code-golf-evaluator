use Tubular::CodeGolf::Runner::Unit;
use Tubular::CodeGolf::Utils::CrossSupply;

class Tubular::CodeGolf::Runner::CrossProduct does Tubular::CodeGolf::Runner::Unit {
    has @!chains is built;

    method new(*@chains) {
        self.bless(:@chains);
    }

    method transform(Supply $input --> Supply) {
        # Transform input through each chain to get individual supplies
        my @supplies = @!chains.map: { .transform($input) };

        # Create cross product of all supplies using reduce operator
        return [X] @supplies;
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Runner::CrossProduct if $short_name
}
