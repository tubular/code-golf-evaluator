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

#| Turns each incoming SolutionPath into a stream of "re-evaluate now" pulses.
#| For every one it sees, it emits the task directory (its .path) once up-front
#| so the first board renders immediately, then re-emits it on every debounced
#| change in the directory it lists (dir-path → the task's solutions/). inotify
#| is non-recursive, so we must watch solutions/ itself, not the task dir.
#| Downstream stages re-list the directory on each pulse, so newly created
#| solutions (cono-03, cono-04, …) are picked up live. Where solutions/ lives is
#| the SolutionPath's business (its dir-path), so this unit needs no config.
class Tubular::CodeGolf::Runner::DirWatch does Tubular::CodeGolf::Runner::Unit {
    # Quiet window (seconds) to collapse the burst of events an editor emits per
    # save into a single pulse.
    has Real $.debounce is built = 0.2;

    method transform(Supply $in --> Supply) {
        supply {
            whenever $in -> $solution-path {
                emit $solution-path.path;
                whenever $solution-path.dir-path -> $watched {
                    whenever IO::Notification.watch-path($watched.Str).stable($!debounce) {
                        emit $solution-path.path;
                    }
                }
            }
        }
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Runner::DirWatch if $short_name
}
