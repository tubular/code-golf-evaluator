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

grammar TaskFolderParser {
    token TOP { <number> '-' <name> }
    token number { \d+ }
    token name { \w+ }
}

class Tubular::CodeGolf::Entity::Task {
    has Str $.number;
    has Str $.name;

    has Tubular::CodeGolf::Conf $!config .= new;

    multi method new(Str $task-name) {
        my $match = TaskFolderParser.parse($task-name);

        my %h = $match.hash.map: { $_.key => ~$_.value };
        return samewith(|%h);
    }

    method folder {
        return ($!number, $!name).join('-');
    }
}
