package TEST::Block::NamedVar;
use strict;
use warnings;
use Fennec;

BEGIN {
    use_ok( 'Block::NamedVar' );
}
use Block::NamedVar;

tests ngrep {
    my @list = ngrep my $x { $x =~ m/^[a-zA-Z]$/ } qw/ a 1 b 2 c 3/;
    is_deeply(
        \@list,
        [qw/a b c/],
        "filtered as expected"
    );
}

tests nmap {
    my @list = nmap my $x { "updated_$x" } qw/ a b c /;
    is_deeply(
        \@list,
        [qw/updated_a updated_b updated_c/],
        "mapped as expected"
    );
}

tests edge {
    my @list = ngrep
        my
            $x
                {
                    $x =~ m/^[a-zA-Z]$/
                }
                    qw/ a 1 b 2 c 3/;
    is_deeply(
        \@list,
        [qw/a b c/],
        "filtered as expected staircased"
    );
}

tests 'count and vartypes' {
    my $count = ngrep my $x { $x =~ m/^[a-zA-Z]$/ } qw/ a 1 b 2 c 3/;
    is( $count, 3, "counts properly" );

    my $y;
    $count = ngrep $y { $y =~ m/^[a-zA-Z]$/ } qw/ a 1 b 2 c 3 222/;
    is( $count, 3, "closure block var" );
    is( $y, '222', "Used outer scope var" );

    $count = ngrep our $v { $v =~ m/^[a-zA-Z]$/ } qw/ a 1 b 2 c 3/;
    is( $count, 3, "package block var" );

    $count = ngrep thing { $thing =~ m/^[a-zA-Z]$/ } qw/ a 1 b 2 c 3/;
    is( $count, 3, "shorthand new variable" );
}

1;
