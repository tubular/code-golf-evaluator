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

use Tubular::CodeGolf::Entity::Listable;
use Tubular::CodeGolf::Runner::Unit;

class Tubular::CodeGolf::Runner::DirList does Tubular::CodeGolf::Runner::Unit {
    method transform(Supply $in --> Supply) {
        supply {
            whenever $in -> $item {
                when $item ~~ Tubular::CodeGolf::Entity::Listable {
                    my $test = $item.dir-test;
                    whenever $item.dir-path -> $in-path {
                        .emit for $in-path.dir(:$test);
                    }
                }
                default {
                    .emit for $item.IO.dir;
                }
            }
        }
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Runner::DirList if $short_name
}
