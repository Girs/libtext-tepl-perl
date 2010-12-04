use strict;
use warnings;
use Test::Base;
use Text::Tepl;

plan tests => 1 * blocks;

filters {
    input => [qw(tepl_compose chomp)],
    expected => [qw(chomp)],
};

run_is 'input' => 'expected';

sub tepl_compose { return Text::Tepl::compose(@_) }

__END__

=== empty
--- input
--- expected
sub{
my $_TEPL = q{};
$_TEPL;
}

=== plain
--- input
abc
def
--- expected
sub{
my $_TEPL = q{};
$_TEPL .= 'abc
def
';
$_TEPL;
}

=== plain with apos
--- input
ab'c
def
--- expected
sub{
my $_TEPL = q{};
$_TEPL .= 'ab\'c
def
';
$_TEPL;
}

=== <?pl ?> 1
--- input
<?pl for my $a (map { "$_ : $Hoge{$_}" } keys %Hoge) {
     }
?>
--- expected
sub{
my $_TEPL = q{};
for my $a (map { "$_ : $Hoge{$_}" } keys %Hoge) {
     }

$_TEPL;
}

=== <?pl ?> 2
--- input
<?pl for my $a (map { "$_ : $Hoge{$_}" } keys %Hoge) { ?>
<?pl } ?>
--- expected
sub{
my $_TEPL = q{};
for my $a (map { "$_ : $Hoge{$_}" } keys %Hoge) { 
} 
$_TEPL;
}

=== <?pl ?> and newline
--- input
hoge
<?pl for my $a (map { "$_ : $Hoge{$_}" } keys %Hoge) { ?>
fuga
<?pl } ?>
uga
--- expected
sub{
my $_TEPL = q{};
$_TEPL .= 'hoge
';
for my $a (map { "$_ : $Hoge{$_}" } keys %Hoge) { 
$_TEPL .= 'fuga
';
} 
$_TEPL .= 'uga
';
$_TEPL;
}

=== <?pl: ?>
--- input
<?pl: $title ?>
--- expected
sub{
my $_TEPL = q{};
$_TEPL .= filter(['*'], $title );
$_TEPL;
}

=== <?pl:a ?>
--- input
<?pl:a $title ?>
--- expected
sub{
my $_TEPL = q{};
$_TEPL .= filter(['a'], $title );
$_TEPL;
}

=== <?pl:a:b ?>
--- input
<?pl:a:b $title ?>
--- expected
sub{
my $_TEPL = q{};
$_TEPL .= filter(['a','b'], $title );
$_TEPL;
}

=== {?pl: ?}
--- input
{?pl for my $a (map { &quot;$_ : $Hoge{$_}&quot; } keys %Hoge) { ?}
{?pl: $a-&gt;{hoge} . &#39;hoge&#39; ?}
{?pl } ?}
--- expected
sub{
my $_TEPL = q{};
for my $a (map { "$_ : $Hoge{$_}" } keys %Hoge) { 
$_TEPL .= filter(['*'], $a->{hoge} . 'hoge' );
} 
$_TEPL;
}

