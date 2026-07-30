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

class Tubular::CodeGolf::Utils::PipeTimeout {
    has Proc::Async @!commands is built;
    has Int $!hup is built;
    has Int $!kill is built;

    submethod TWEAK() {
        for @!commands Z @!commands[1..*] -> ($prev, $next) {
            $next.bind-stdin: $prev.stdout;
        }
    }

    method start(-->Supply) {
        .start for @!commands.head(*-1);

        supply {
            whenever @!commands[*-1].start {
                .emit;
                done;
            }

            whenever Promise.in($!hup) {
                .kill for @!commands;
                whenever Promise.in($!kill) {
                    .kill(SIGKILL) for @!commands;
                }
            }
        }
    }
}
