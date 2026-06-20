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

    # When True the diff runs without -q and its stdout is kept on the
    # TestResult, so consumers (the watcher's live board) can show what differs.
    # Default False: the CSV/MD evaluator only needs the pass/fail status.
    has Bool $.capture-output = False;

    method transform(Supply $in --> Supply) {
        supply {
            # throttle runs the callable on a worker thread, at most
            # $!concurrency at a time, emitting a Promise (kept with the
            # callable's return value) as each finishes.
            whenever $in.throttle: $!concurrency, -> $solution {
                my $diff-cmd = $!capture-output
                    ?? Proc::Async.new('diff', '-', $solution.test-suite.expected-file)
                    !! Proc::Async.new('diff', '-q', '-', $solution.test-suite.expected-file);
                my @commands = (
                    Proc::Async.new('cat', $solution.test-suite.input-file),
                    Proc::Async.new($solution.path),
                    $diff-cmd,
                );
                my $pipeline = Tubular::CodeGolf::Utils::PipeTimeout.new(:10hup, :2kill, :@commands);

                # throttle's callable is synchronous: it holds the concurrency
                # slot until it returns. Our pipeline is async, so block this
                # worker thread on a react that runs it to completion.
                my $status;
                my $output = '';
                react {
                    # drain diff stdout (and keep it when capturing)
                    whenever @commands[*-1].stdout { $output ~= $_ }
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
                my $diff = $!capture-output ?? $output !! Str;
                Tubular::CodeGolf::Entity::TestResult.new(:$solution, :$status, :$diff);
            } -> $done {
                whenever $done -> $result { $result.emit }
            }
        }
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Runner::SolutionExecutor if $short_name
}
