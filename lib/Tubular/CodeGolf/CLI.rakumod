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
use Tubular::CodeGolf::Evaluator;
use Tubular::CodeGolf::Watcher;

proto MAIN(|) is export {*}

multi MAIN('evaluate') {
    my Tubular::CodeGolf::Conf $config .= new;
    my Tubular::CodeGolf::Evaluator $evaluator .= new(:$config);

    $evaluator.run();
}

#| Render the Markdown release page for a single competition (tag == folder name).
multi MAIN('release', Str $tag) {
    my Tubular::CodeGolf::Conf $config .= new;
    my Tubular::CodeGolf::Evaluator $evaluator .= new(:$config);

    $evaluator.run(:task($tag), :format<md>);
}

#| Live golf board: watch a task's solutions/ and re-test on every save,
#| showing the N smallest solutions as OK/NOT OK + byte size.
#| <task> is a task folder name (002-tictactoe).
multi MAIN('watch', Str $task, Int :c(:$count) = 3) {
    my Tubular::CodeGolf::Conf $config .= new;
    Tubular::CodeGolf::Watcher.new(:$config, :$task, :$count).run;
}

#| watch with no task: default to the latest task folder in the competition root.
multi MAIN('watch', Int :c(:$count) = 3) {
    my Tubular::CodeGolf::Conf $config .= new;
    Tubular::CodeGolf::Watcher.new(:$config, :$count).run;
}

multi MAIN('compile') { "ok".say }
