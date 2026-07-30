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
use Tubular::CodeGolf::Entity::Solution 'Solution';
use Tubular::CodeGolf::Entity::SolutionPath 'SolutionPath';
use Tubular::CodeGolf::Entity::TaskPath 'TaskPath';
use Tubular::CodeGolf::Runner::DirList 'DirList';
use Tubular::CodeGolf::Runner::EntityTransformer 'EntityTransformer';
use Tubular::CodeGolf::Runner::Filter 'Filter';
use Tubular::CodeGolf::Runner::Mono 'Mono';
use Tubular::CodeGolf::Runner::ResultToCSV 'ResultToCSV';
use Tubular::CodeGolf::Runner::ResultToMD 'ResultToMD';
use Tubular::CodeGolf::Runner::SolutionExecutor 'SolutionExecutor';
use Tubular::CodeGolf::Runner::Flow::Chain 'Chain';
use Tubular::CodeGolf::Runner::Flow::CrossProduct 'CrossProduct';

class Tubular::CodeGolf::Evaluator {
    has Tubular::CodeGolf::Conf $!config is built;

    method run(Str :$task, Str :$format = 'csv') {
        my $tests-chain = Chain.new(
            EntityTransformer.new(:entity(TaskPath)),
            DirList.new,
        );
        my $solutions-chain = Chain.new(
            EntityTransformer.new(:entity(SolutionPath)),
            DirList.new,
        );
        # Define data pipeline
        my @pipeline = (
            Mono.new(:value($!config.get('CODEGOLF_PATH'))),
            DirList.new,
        );
        # Scope to a single competition folder when a task is given.
        @pipeline.push: Filter.new(:pred(-> $p { $p.basename eq $task })) if $task;
        @pipeline.append:
            CrossProduct.new(
                $tests-chain, $solutions-chain
            ),
            EntityTransformer.new(:entity(Solution)),
            SolutionExecutor.new;
        @pipeline.push: $format eq 'md' ?? ResultToMD.new !! ResultToCSV.new;

        my $result = Chain.new(|@pipeline);

        my $sup = $result.start;

        react {
            whenever $sup -> $test {
                $test.say;
            }
        }
    }
}
