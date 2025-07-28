use Tubular::CodeGolf::Conf;
use Tubular::CodeGolf::Entity::DirListMessage;
use Tubular::CodeGolf::Entity::Listable;
use Tubular::CodeGolf::Entity::Task;

class Tubular::CodeGolf::Entity::TestSuite does Tubular::CodeGolf::Entity::Listable {
    has Tubular::CodeGolf::Entity::Task $.task;
    has Str $.test;

    has Tubular::CodeGolf::Conf $!config .= new;

    multi method new(Tubular::CodeGolf::Entity::DirListMessage $msg) {
        my $task = $msg.data;
        my $test = $msg.path.basename.split('.').first;

        samewith(:$task, :$test);
    }

    method input-file {
        self.task.fq-folder.add($!config.get('TESTS_PATH')).add(self.test ~ '.in');
    }

    method expected-file {
        self.task.fq-folder.add($!config.get('TESTS_PATH')).add(self.test ~ '.ex');
    }

    method get-solutions-path {
        return self.task.fq-folder.add($!config.get('SOLUTIONS_PATH'));
    }

    method dir-test returns Code {
        &{
            with self.get-solutions-path.add($_) {
                .f && !.basename.starts-with('.')
            }
        }
    }

    method dir-path returns Supply {
        supply {
            self.get-solutions-path.emit;
        }
    }

    method data {
        return self;
    }
}
