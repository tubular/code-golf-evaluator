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

class Tubular::CodeGolf::Conf {
    my $path = '/app/code-golf/competition';
    has %!config =
            CODEGOLF_PATH => $path,
            SOLUTIONS_PATH => 'solutions',
            TESTS_PATH => 'tests';

    my Tubular::CodeGolf::Conf $singleton;

    method new() {
        $singleton //= self.bless;
    }

    submethod TWEAK() {
        %!config{$_} = %*ENV{$_} for %!config.keys.grep:{ %*ENV{$_}:exists };
    }

    method get(Str $key) {
        die "$key config parameter not found" unless %!config{$key}:exists;
        %!config{$key}
    }
}
