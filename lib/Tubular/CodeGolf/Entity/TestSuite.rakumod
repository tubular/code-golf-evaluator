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

class Tubular::CodeGolf::Entity::TestSuite does Tubular::CodeGolf::Entity::Listable {
    has Str $.test;
    has Str $.dirname;

    has Tubular::CodeGolf::Conf $!config .= new;

    multi method new(IO::Path $input-file) {
        my $dirname = $input-file.dirname;
        my $test = $input-file.basename.split('.').first;

        samewith(:$dirname, :$test);
    }

    method input-file {
        $!dirname.IO.add($!test ~ '.in');
    }

    method expected-file {
        $!dirname.IO.add($!test ~ '.ex');
    }
}
