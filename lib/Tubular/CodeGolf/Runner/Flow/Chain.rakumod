use Tubular::CodeGolf::Runner::Producer;
use Tubular::CodeGolf::Runner::Unit;

class Tubular::CodeGolf::Runner::Flow::Chain does Tubular::CodeGolf::Runner::Unit {
    has @!chain is built;

    method new(*@chain) {
        self.bless(:@chain);
    }

    method transform(Supply $input --> Supply) {
        my $current = $input;

        for @!chain -> $step {
            $current = $step.transform($current);
        }

        return $current;
    }

    method start(--> Supply) {
        die "Chain cannot be empty" unless @!chain;

        my $first = @!chain[0];
        my @rest = @!chain[1..*];

        # If first step is a Producer, it generates the initial Supply
        if $first ~~ Tubular::CodeGolf::Runner::Producer {
            my $initial = $first.transform();

            # Apply remaining transformers
            my $current = $initial;
            for @rest -> $step {
                $current = $step.transform($current);
            }

            return $current;
        }
        # Otherwise, we need an input Supply (shouldn't happen in start())
        else {
            die "First step in chain must be a Producer when using .start()";
        }
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Runner::Flow::Chain if $short_name
}