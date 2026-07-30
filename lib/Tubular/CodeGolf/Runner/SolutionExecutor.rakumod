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

use Tubular::CodeGolf::Entity::TestResult;
use Tubular::CodeGolf::Runner::Unit;
use Tubular::CodeGolf::Utils::PipeTimeout;

class Tubular::CodeGolf::Runner::SolutionExecutor does Tubular::CodeGolf::Runner::Unit {
    # Cap how many solution pipelines run at once. Without this, every
    # (test × solution) pair is launched concurrently; at scale that saturates
    # the thread pool so badly that even the PipeTimeout timers can't fire, and
    # the whole run deadlocks. Defaults to the CPU count, capped at 16 so a
    # very-high-core host stays clear of the thread-pool ceiling. Override with
    # SOLUTION_CONCURRENCY.
    has Int $.concurrency = (%*ENV<SOLUTION_CONCURRENCY> // ($*KERNEL.cpu-cores min 16)).Int;

    method transform(Supply $in --> Supply) {
        supply {
            # throttle runs the callable on a worker thread, at most
            # $!concurrency at a time, emitting a Promise (kept with the
            # callable's return value) as each finishes.
            whenever $in.throttle: $!concurrency, -> $solution {
                my @commands = (
                    Proc::Async.new('cat', $solution.test-suite.input-file),
                    Proc::Async.new($solution.path),
                    Proc::Async.new('diff', '-q', '-', $solution.test-suite.expected-file),
                );
                my $pipeline = Tubular::CodeGolf::Utils::PipeTimeout.new(:10hup, :2kill, :@commands);

                # throttle's callable is synchronous: it holds the concurrency
                # slot until it returns. Our pipeline is async, so block this
                # worker thread on a react that runs it to completion.
                my $status;
                react {
                    # suppress diff stdout
                    whenever @commands[*-1].stdout {}
                    whenever $pipeline.start {
                        given $_ {
                            when .exitcode != 0        { $status = 'wrong' }
                            when .signal == SIGHUP.Int { $status = 'timeout' }
                            when .signal > 0           { $status = 'error' }
                            default                    { $status = 'success' }
                        }
                        done;
                    }
                }
                Tubular::CodeGolf::Entity::TestResult.new(:$solution, :$status);
            } -> $done {
                whenever $done -> $result { $result.emit }
            }
        }
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Runner::SolutionExecutor if $short_name
}
