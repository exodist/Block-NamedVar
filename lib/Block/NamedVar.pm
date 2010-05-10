package Block::NamedVar;
use strict;
use warnings;

our $VERSION = "0.002";

use base 'Devel::Declare::Parser';

__PACKAGE__->register( 'named_var' );
__PACKAGE__->add_accessor( $_ ) for qw/dec var/;

our @DEFAULTS = qw/nmap ngrep/;

sub type { 'const' }

sub ngrep {
    local $_;
    my $code = shift;
    grep { $code->() } @_;
}

sub nmap {
    local $_;
    my $code = shift;
    map { $code->() } @_;
}

sub import {
    my $class = shift;
    my $caller = caller;

    my @args = @_;
    @args = @DEFAULTS unless @args;

    my @export = grep { m/^n(grep|map)$/ } @args;
    for ( @export ) {
        no strict 'refs';
        *{ $caller . '::' . $_ } = \&$_;
    }

    $class->enhance( $caller, $_ ) for @args;
}

sub rewrite {
    my $self = shift;

    if ( @{ $self->parts } > 2 ) {
        ( undef, my @bad ) = @{ $self->parts };
        $self->bail(
            "Syntax error near: " . join( ' and ',
                map { $self->format_part($_)} @bad
            )
        );
    }

    my ($first, $second) = @{ $self->parts };
    my ( $dec, $var ) = ("");
    if ( @{ $self->parts } > 1 ) {
        $self->bail(
            "Syntax error near: " . $self->format_part($first)
        ) unless grep { $first->[0] eq $_ } qw/my our/;
        $dec = $first;
        $var = $second;
    }
    else {
        $var = $first;
        $dec = ['my'] if ref $self->parts->[0];
    }

    $var = $self->format_var( $var );
    $self->dec( $dec );
    $self->var( $var );

    $self->new_parts([]);
}

sub format_var {
    my $self = shift;
    my ( $var ) = @_;
    if ( ref $var ) {
        $var = $var->[0];
    }
    return $var if $var =~ m/^\$\w[\w\d_]*$/;
    return "\$$var" if $var =~ m/^\w[\w\d_]*$/;
    $self->bail( "Syntax error, '$var' is not a valid block variable name" );
}

sub inject {
    my $self = shift;
    my $dec = $self->dec ? $self->dec->[0] : '';
    my $var = $self->var;
    return ( "$dec $var = \$_" );
}

sub _scope_end {
    my $class = shift;
    my ( $id ) = @_;
    my $self = Devel::Declare::Parser::_unstash( $id );

    my $linestr = $self->line;
    $self->offset( $self->_linestr_offset_from_dd() );
    substr($linestr, $self->offset, 0) = ', ';
    $self->end_hook( \$linestr );
    $self->line($linestr);
}

sub _open {
    my $self = shift;
    my $start = $self->prefix;
    return $start . $self->name . " ";
}

1;

__END__

=head1 NAME

Block::NamedVar - Replacements for map, grep with named block variables.

=head1 DESCRIPTION

Gives you nmap and ngrep which are new keywords that let you do a map or grep.
The difference is you can name the block variable instead of relying on $_. You
can also turn custom map/grep like functions into keywords that act like nmap
and ngrep.

=head1 SYNOPSIS

    #!/usr/bin/perl
    use strict;
    use warnings;

    use Block::NamedVar qw/nmap ngrep/;

    my @stuff = qw/a 1 b 2 c 3/
    my ( @list, $count );

    # grep with lexical $x.
    @list = ngrep my $x { $x =~ m/^[a-zA-Z]$/ } @stuff;

    # map with lexical $x
    @list = nmap my $x { "updated_$x" } @stuff;

    # grep with package variable $v
    $count = ngrep our $v { $v =~ m/^[a-zA-Z]$/ } @stuff;

    # grep with closure over existing $y
    my $y;
    $count = ngrep $y { $y =~ m/^[a-zA-Z]$/ } @stuff;

    # Shortcut for lexical variable
    # must be bareword.
    $count = ngrep thing { $thing =~ m/^[a-zA-Z]$/ } @stuff;

=head1 EXPORTED FUNCTIONS

=over 4

=item @out = nmap var { $var ... } @list

=item @out = nmap $var { $var ... } @list

=item @out = nmap my $var { $var ... } @list

=item @out = nmap our $var { $var ... } @list

Works just like map except you specify a variable instead of using $_.

=item @out = ngrep var { $var ... } @list

=item @out = ngrep $var { $var ... } @list

=item @out = ngrep my $var { $var ... } @list

=item @out = ngrep our $var { $var ... } @list

Works just like grep except you specify a variable instead of using $_.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Block-NamedVar is free software; Standard perl licence.

Block-NamedVar is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.
