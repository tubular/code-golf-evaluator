#
# Copyright 2022-2026 Chartbeat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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