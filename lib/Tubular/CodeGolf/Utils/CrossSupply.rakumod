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

unit module CrossSupply;

#| Recursively builds cross product of supplies
sub cross-product-recursive($prev, @rest) {
    return $prev unless @rest;

    my $head = @rest.first;
    my $result = supply {
        whenever $prev -> @list-element {
            whenever $head -> $element {
                (|@list-element, $element).emit;
            }
        }
    };
    return cross-product-recursive($result, @rest[1..*]);
}

#| Creates cross product of multiple supplies
sub cross-product(**@supplies --> Supply) is export {
    return Supply.from-list(()) unless @supplies;
    return @supplies[0] if @supplies == 1;

    my $initial = supply {
        whenever @supplies.first -> $el {
            ($el,).emit;
        }
    };
    return cross-product-recursive($initial, @supplies[1..*]);
}

#| Multiple supply cross product via X operator
multi sub infix:<X>(Supply $first, *@rest where { .all ~~ Supply } --> Supply) is export {
    cross-product($first, |@rest);
}

