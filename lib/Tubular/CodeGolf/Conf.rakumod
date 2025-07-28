class Tubular::CodeGolf::Conf {
    my $path = '/app/code-golf/competition';
    has %!config =
            CODEGOLF_PATH => $path,
            SOLUTIONS_PATH => 'solutions',
            TESTS_PATH => 'tests';

    my Tubular::CodeGolf::Conf $singleton;

    method new() {
        $singleton //= self.bless;
    }

    submethod TWEAK() {
        %!config{$_} = %*ENV{$_} for %!config.keys.grep:{ %*ENV{$_}:exists };
    }

    method get(Str $key) {
        die "$key config parameter not found" unless %!config{$key}:exists;
        %!config{$key}
    }
}
