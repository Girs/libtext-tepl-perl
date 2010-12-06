package Text::Tepl;
use strict;
use warnings;
use Carp qw(croak);
use base qw(Exporter);

# $Id$
use version; our $VERSION = '0.006';

our @EXPORT_OK = qw(call compose);

sub call {
    my($eperl, @arg) = @_;
    my $pkg = caller;
    my $perl = "package $pkg;" . compose($eperl);
    local $@ = undef;       ## no critic qw(LocalVar)
    my $code = eval $perl; ## no critic qw(StringyEval)
    croak $@ if $@;
    return $code->(@arg);
}

sub compose {
    my($eperl) = @_;
    my $_TEPL = '$_TEPL';   ## no critic qw(Interpolation)
    my $perl = qq{my $_TEPL = q{};\n};
    my $ws = qr{[\r\n\t\x20]}msx;
    my %unesc = (
        'amp' => q{&}, 'lt' => q{<}, 'gt' => q{>},
        'quot' => q{"}, '#39' => q{'},
    );
    while ($eperl =~ m{\G
        (.*?)
        (?:\<\?p(?:er)?l (\:[a-zA-Z0-9_:]*)? $ws+ (.*?) $ws* \?\>
        |  \{\?p(?:er)?l (\:[a-zA-Z0-9_:]*)? $ws+ (.*?) $ws* \?\}
        ) (?:\n|\r\n?)?
    }gcmosx) {
        my $text = $1 || q{};
        my $modifier = $2 || $4 || q{};
        my $code = $3 || $5 || q{};
        if ($5) {
            $code =~ s{\&(amp|lt|gt|quot|\#39);}{ $unesc{$1} }egmosx;
        }
        if ($text ne q{}) {
            $text =~ s/(['\\])/\\$1/gmosx;
            $perl .= qq{$_TEPL .= '$text';\n};
        }
        if (! $modifier) {
            $perl .= qq{$code\n};
        }
        else {
            my @modifiers = grep { $_ } split /:/msx, $modifier;
            if (! @modifiers) {
                push @modifiers, q{*};
            }
            $perl .= qq{$_TEPL .= filter([}
                . (join q{,}, map { qq{'$_'} } @modifiers)
                . qq{], $code);\n};
        }
    }
    if (pos $eperl) {
        $eperl = substr $eperl, pos $eperl;
    }
    if ($eperl ne q{}) {
        $eperl =~ s/(['\\])/\\$1/gmosx;
        $perl .= qq{$_TEPL .= '$eperl';\n};
    }
    return "sub{\n" . $perl . "$_TEPL;\n". "}\n";
}

1;

__END__

=head1 NAME

Text::Tepl - A kind of embeded perl.

=head1 VERSION

0.006

=head1 SYNOPSIS

    use Text::Tepl;
    my $eperl_document = <<'EOS';
    <?perl my($name, @list) = @_; ?>
    ---
    name: "<?perl: $name ?>"
    modifier:
    <?pl for my $item (@list) { ?>
      - "<?pl: $item ?>"
    <?pl } ?>
    EOS
    sub filter {
        my($modifier_name_list, @arg) = @_;
        my $s = join q{}, @arg;
        $s =~ s{"}{\\"}g;
        return $s;
    }
    my @arguments = ('Tepl -- An embeded perl runner', 'call', 'composite');
    # step by step:
    #   - compose perl script from eperl document.
    my $perl_script = Text::Tepl::compose($eperl_document);
    #   - compile perl script.
    my $code = eval $perl_script; ## no critic qw(StringyEval)
    #   - run it.
    print $code->(@arguments);
    # same above steps
    print Text::Tepl::call($eperl_document, @arguments);

=head1 DESCRIPTION

Text::Tepl is a light-weight implementation of the embeded perl (eperl).

=head1 MARKUP

Text::Tepl recognizes embeded perl statements in the processing
instructions named pl or perl. 

    <?pl
        my($self, $list) = @_;
        my $title = $self->{title};
        my $prevlink = $self->{prevlink};
        my $nextlink = $self->{nextlink};
    ?>

If a name of processing instruction contains colon symbols,
it becomes perl expression. In this case, colon separated
names become the chains of modifiers.

    <?pl:foo:bar:xml $thing ?>

Above examle is converted to:

    $_TEPL .= filter(['foo', 'bar', 'xml'], $thing);

where variable C<$_TEPL> is the container for result text.

In the default, the anonymous filter C<filter(['*'], @arg)> is used.

    <?pl: $thing ?>

produces

    $_TEPL .= filter(['*'], $thing);

For speceial cases such as embeded perl code in attributes,
Tepl recognizes blases notations. In blases notation, you
can write escaped special characters for XML: &gt;, &lt;,
&quot;, &amp;, &#39;.

    <a href="{?pl:uri $self-&gt;permlink ?}">

produces codes as below.

    $_TEPL .= q{<a href="};
    $_TEPL .= filter(['uri'], $self->permalink);
    $_TEPL .= q{">};

But we shall write it without escaped characters.

    <?pl for my $link ($self->permalink) { ?>
    <a href="{?pl:uri $link ?}">
    <?pl } ?>

=head1 SUBROUTINES

=over

=item C<< __PACKAGE__::filter(\@modifier_name_list, @args); >>

To run composed perl scripts, you must write filter
functions in stringy-eval package.

=item C<< $text = Text::Tepl::call($eperl_script, @args); >>

Tepl::call is a short cut for running an eperl script.
It composes a code reference from the eperl script
in the caller's package name space, and it runs
it with optional arguments.

At the running eperl codes, them require the filter
functions in the caller's package name space
for C<< <?pl: ?> >> sections.

=item C<< $perl_script = Text::Tepl::compose($eperl_script); >>

Text::Tepl::compose converts from a given eperl script
to a perl script as a string scalar. The converted
perl script contains single anonymous subroutine
definition. If you execute it, for example.

  $perl_script = Text::Tepl::compose($eperl_script);
  $code = eval $perl_script; ## no critic qw(StringyEval)
  $text = $code->(@args);

At the running codes, them require the filter
functions.

=back

=head1 DEPENDENCIES

None.

=head1 SEE ALSO

L<http://www.kuwata-lab.com/erubis/>

=head1 AUTHOR

MIZUTANI Tociyuki  C<< <tociyuki@gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, MIZUTANI Tociyuki C<< <tociyuki@gmail.com> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
