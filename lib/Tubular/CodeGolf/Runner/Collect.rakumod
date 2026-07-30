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

use Tubular::CodeGolf::Runner::Unit;

#| Buffers the whole (finite) input stream and, on completion (LAST), applies a
#| fold to the collected list and emits each element it returns. Where Filter
#| decides per item, Collect decides over the entire set — so it can sort, pick
#| the max, take a top-N, dedupe, etc. Only meaningful on streams that end.
class Tubular::CodeGolf::Runner::Collect does Tubular::CodeGolf::Runner::Unit {
    has &.fold is built;

    method transform(Supply $in --> Supply) {
        supply {
            my @all;
            whenever $in {
                @all.push: $_;
                LAST { .emit for &!fold(@all); }
            }
        }
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Runner::Collect if $short_name
}
