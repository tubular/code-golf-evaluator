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

use Tubular::CodeGolf::Conf;
use Tubular::CodeGolf::Entity::Listable;

class Tubular::CodeGolf::Entity::TaskPath does Tubular::CodeGolf::Entity::Listable {
    has IO::Path $.path is built is required;
    has Tubular::CodeGolf::Conf $!config = Tubular::CodeGolf::Conf.new;

    multi method new(IO::Path $path) {
        samewith(:$path);
    }

    method dir-path returns Supply {
        supply {
            $!path.add($!config.get('TESTS_PATH')).emit;
        }
    }

    method dir-test returns Code {
        &{ /'.in' $/ }
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Entity::TaskPath if $short_name
}
