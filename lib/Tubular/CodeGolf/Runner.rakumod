use Tubular::CodeGolf::Conf;
use Tubular::CodeGolf::Entity::Solution;
use Tubular::CodeGolf::Entity::Task;
use Tubular::CodeGolf::Entity::TestSuite;
use Tubular::CodeGolf::Runner::DirList;
use Tubular::CodeGolf::Runner::EntityTransformer;
use Tubular::CodeGolf::Runner::ResultToCSV;
use Tubular::CodeGolf::Runner::SolutionExecutor;

class Tubular::CodeGolf::Runner {
    has Tubular::CodeGolf::Conf $!config is built;

    method run() {
        my @transformers =
            Tubular::CodeGolf::Runner::DirList.new,
            Tubular::CodeGolf::Runner::EntityTransformer.new(:entity(Tubular::CodeGolf::Entity::Task)),
            Tubular::CodeGolf::Runner::DirList.new,
            Tubular::CodeGolf::Runner::EntityTransformer.new(:entity(Tubular::CodeGolf::Entity::TestSuite)),
            Tubular::CodeGolf::Runner::DirList.new,
            Tubular::CodeGolf::Runner::EntityTransformer.new(:entity(Tubular::CodeGolf::Entity::Solution)),
            Tubular::CodeGolf::Runner::SolutionExecutor.new,
            Tubular::CodeGolf::Runner::ResultToCSV.new;

        my $sup = supply { $!config.get('CODEGOLF_PATH').emit };

        for @transformers {
            $sup = .transform($sup);
        }

        react {
            whenever $sup -> $test {
                $test.say;
            }
        }
    }
}
