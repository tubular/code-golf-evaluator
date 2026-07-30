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

class Tubular::CodeGolf::Runner::EntityTransformer does Tubular::CodeGolf::Runner::Unit {
    has $!entity is built;
    # When True, items whose construction throws (e.g. a half-written solution
    # with no valid shebang) are dropped instead of killing the stream. The
    # watcher needs this since it re-runs on every save, including mid-edit.
    has Bool $!skip-errors is built = False;

    method transform(Supply $in --> Supply) {
        return $in.map: { $!entity.new($_) } unless $!skip-errors;
        supply {
            whenever $in -> $item {
                my $entity = try { $!entity.new($item) };
                emit $entity if $entity.defined;
            }
        }
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Runner::EntityTransformer if $short_name
}
