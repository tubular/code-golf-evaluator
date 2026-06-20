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

    # When True, capture the solution's output and keep a diff on the TestResult
    # so consumers (the watcher's live board) can show what differs. Default
    # False: the CSV/MD evaluator only needs the pass/fail status.
    has Bool $.capture-output = False;

    method transform(Supply $in --> Supply) {
        supply {
            # throttle runs the callable on a worker thread, at most
            # $!concurrency at a time, emitting a Promise (kept with the
            # callable's return value) as each finishes.
            whenever $in.throttle: $!concurrency, -> $solution {
                $!capture-output
                    ?? self!evaluate-capturing($solution)
                    !! self!evaluate-quick($solution);
            } -> $done {
                whenever $done -> $result { $result.emit }
            }
        }
    }

    # Pass/fail only (the evaluator). Streams cat | solution | diff -q and reads
    # the verdict straight off diff's exit status — fast, and never buffers the
    # output. This is the long-proven path and stays exactly as it was.
    method !evaluate-quick($solution) {
        my @commands = (
            Proc::Async.new('cat', $solution.test-suite.input-file),
            Proc::Async.new($solution.path),
            Proc::Async.new('diff', '-q', '-', $solution.test-suite.expected-file),
        );
        my $pipeline = Tubular::CodeGolf::Utils::PipeTimeout.new(:10hup, :2kill, :@commands);

        # throttle's callable is synchronous: block this worker thread on a react
        # that runs the pipeline to completion.
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
        Tubular::CodeGolf::Entity::TestResult.new(:$solution, :$status, :diff(Str));
    }

    # Pass/fail plus a diff (the watcher). Runs cat | solution, captures the
    # solution's output, and compares it to the expected file in-process. We
    # deliberately don't pipe into `diff`: feeding diff a live pipe without -q is
    # unreliable across platforms (BSD diff on macOS can close the pipe early and
    # report a bogus exit status), and doing the compare ourselves is both
    # deterministic and gives us the text to show.
    method !evaluate-capturing($solution) {
        my @commands = (
            Proc::Async.new('cat', $solution.test-suite.input-file),
            Proc::Async.new($solution.path),
        );
        my $pipeline = Tubular::CodeGolf::Utils::PipeTimeout.new(:10hup, :2kill, :@commands);

        # No eager `done`: let the react end once the stdout supply hits EOF and
        # the pipeline supply completes, so the whole output is captured.
        my $status;
        my $output = '';
        react {
            whenever @commands[*-1].stdout { $output ~= $_ }
            whenever $pipeline.start {
                given $_ {
                    when .signal == SIGHUP.Int { $status = 'timeout' }
                    when .signal > 0           { $status = 'error' }
                }
            }
        }

        my $diff = Str;
        without $status {
            my $expected = $solution.test-suite.expected-file.slurp;
            if $output eq $expected {
                $status = 'success';
            } else {
                $status = 'wrong';
                $diff   = self!diff-text($output, $expected);
            }
        }
        Tubular::CodeGolf::Entity::TestResult.new(:$solution, :$status, :$diff);
    }

    # A minimal got/expected line diff for the live board.
    method !diff-text(Str $got, Str $expected) {
        my @g = $got.lines;
        my @e = $expected.lines;
        my @out;
        for ^(@g.elems max @e.elems) -> $i {
            my $g = @g[$i] // '';
            my $e = @e[$i] // '';
            next if $g eq $e;
            @out.push: "- $g";
            @out.push: "+ $e";
        }
        @out.join("\n");
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Runner::SolutionExecutor if $short_name
}
