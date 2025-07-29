use Tubular::CodeGolf::Conf;
use Tubular::CodeGolf::Entity::Listable;

class Tubular::CodeGolf::Entity::TestSuite does Tubular::CodeGolf::Entity::Listable {
    has Str $.test;
    has Str $.dirname;

    has Tubular::CodeGolf::Conf $!config .= new;

    multi method new(IO::Path $input-file) {
        my $dirname = $input-file.dirname;
        my $test = $input-file.basename.split('.').first;

        samewith(:$dirname, :$test);
    }

    method input-file {
        $!dirname.IO.add($!test ~ '.in');
    }

    method expected-file {
        $!dirname.IO.add($!test ~ '.ex');
    }
}
