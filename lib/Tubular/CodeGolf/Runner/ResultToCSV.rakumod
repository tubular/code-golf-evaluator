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

class Tubular::CodeGolf::Runner::ResultToCSV does Tubular::CodeGolf::Runner::Unit {
    method transform(Supply $in --> Supply) {
        supply {
            "task,author,version,size,language,test,status".emit;
            whenever $in -> $result {
                (
                    $result.solution.task.name,
                    $result.solution.author,
                    $result.solution.version,
                    $result.solution.size,
                    $result.solution.language,
                    $result.solution.test-suite.test,
                    $result.status,
                ).join(',').emit;
            }
        }
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Runner::ResultToCSV if $short_name
}
