use Tubular::CodeGolf::Conf;
use Tubular::CodeGolf::Runner;

proto MAIN(|) is export {*}

multi MAIN('evaluate') {
    my Tubular::CodeGolf::Conf $config .= new;
    my Tubular::CodeGolf::Runner $runner .= new(:$config);

    $runner.run();
}

multi MAIN('compile') { "ok".say }
