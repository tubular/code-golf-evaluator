use Tubular::CodeGolf::Entity::TestResult;
use Tubular::CodeGolf::Runner::Unit;
use Tubular::CodeGolf::Utils::PipeTimeout;

class Tubular::CodeGolf::Runner::SolutionExecutor does Tubular::CodeGolf::Runner::Unit {
    method transform(Supply $in --> Supply) {
        supply {
            whenever $in -> $solution {
                my @commands = (
                    Proc::Async.new('cat', $solution.test-suite.input-file),
                    Proc::Async.new($solution.path),
                    Proc::Async.new('diff', '-q', '-', $solution.test-suite.expected-file),
                );
                my $pipeline = Tubular::CodeGolf::Utils::PipeTimeout.new(:10hup, :2kill, :@commands);

                # supress diff stderr
                whenever @commands[*-1].stdout {}
                whenever $pipeline.start {
                    when .exitcode != 0 {
                        Tubular::CodeGolf::Entity::TestResult.new(:$solution, status => 'wrong').emit;
                    }
                    when .signal == SIGHUP.Int {
                        Tubular::CodeGolf::Entity::TestResult.new(:$solution, status => 'timeout').emit;
                    }
                    when .signal > 0 {
                        Tubular::CodeGolf::Entity::TestResult.new(:$solution, status => 'error').emit;
                    }
                    default {
                        Tubular::CodeGolf::Entity::TestResult.new(:$solution, status => 'success').emit;
                    }
                }
            }
        }
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Runner::SolutionExecutor if $short_name
}
