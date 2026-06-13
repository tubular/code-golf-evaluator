use Tubular::CodeGolf::Runner::Unit;
use Tubular::CodeGolf::Utils::CrossSupply;

class Tubular::CodeGolf::Runner::Flow::CrossProduct does Tubular::CodeGolf::Runner::Unit {
    has @!chains is built;

    method new(*@chains) {
        self.bless(:@chains);
    }

    method transform(Supply $input --> Supply) {
        # Cross *per incoming item*, not globally. Each item (a competition task
        # dir) is fed through every chain on its own, so a task's tests are only
        # crossed with that same task's solutions. Crossing the merged streams
        # instead would pair every task's tests with every other task's
        # solutions.
        supply {
            whenever $input -> $item {
                my $one      = Supply.from-list($item);
                my @supplies = @!chains.map: { .transform($one) };
                whenever [X] @supplies -> $tuple {
                    emit $tuple;
                }
            }
        }
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Runner::Flow::CrossProduct if $short_name
}