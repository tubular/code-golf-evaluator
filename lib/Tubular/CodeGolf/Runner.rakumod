use Tubular::CodeGolf::Conf;
use Tubular::CodeGolf::Entity::Solution 'Solution';
use Tubular::CodeGolf::Entity::TaskPath 'TaskPath';
use Tubular::CodeGolf::Entity::SolutionPath 'SolutionPath';
use Tubular::CodeGolf::Runner::DirList 'DirList';
use Tubular::CodeGolf::Runner::EntityTransformer 'EntityTransformer';
use Tubular::CodeGolf::Runner::ResultToCSV 'ResultToCSV';
use Tubular::CodeGolf::Runner::SolutionExecutor 'SolutionExecutor';
use Tubular::CodeGolf::Runner::CrossProduct 'CrossProduct';
use Tubular::CodeGolf::Runner::Mono 'Mono';
use Tubular::CodeGolf::Utils::SupplyChain 'SupplyChain';

class Tubular::CodeGolf::Runner {
    has Tubular::CodeGolf::Conf $!config is built;

    method run() {
        my $tests-chain = SupplyChain.new(
            EntityTransformer.new(:entity(TaskPath)),
            DirList.new,
        );
        my $solutions-chain = SupplyChain.new(
            EntityTransformer.new(:entity(SolutionPath)),
            DirList.new,
        );
        # Define data pipeline
        my $result = SupplyChain.new(
            Mono.new(:value($!config.get('CODEGOLF_PATH'))),
            DirList.new,
            CrossProduct.new(
                $tests-chain, $solutions-chain
            ),
            EntityTransformer.new(:entity(Solution)),
            SolutionExecutor.new,
            ResultToCSV.new,
        );

        my $sup = $result.start;

        react {
            whenever $sup -> $test {
                $test.say;
            }
        }
    }
}
