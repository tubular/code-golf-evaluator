use Tubular::CodeGolf::Conf;
use Tubular::CodeGolf::Runner;

proto MAIN(|) is export {*}

multi MAIN('evaluate') {
    my Tubular::CodeGolf::Conf $config .= new;
    my Tubular::CodeGolf::Runner $runner .= new(:$config);

    $runner.run();
}

#| Render the Markdown release page for a single competition (tag == folder name).
multi MAIN('release', Str $tag) {
    my Tubular::CodeGolf::Conf $config .= new;
    my Tubular::CodeGolf::Runner $runner .= new(:$config);

    $runner.run(:task($tag), :format<md>);
}

multi MAIN('compile') { "ok".say }
