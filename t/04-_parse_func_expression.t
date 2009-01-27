use Test::More 'no_plan';
use strict;
use warnings;

use App::Sequence;

# success pattern
{
    my $func_exp = "backup( c.name, r.age ) : r.content";
    my $func_info = App::Sequence::_parse_func_expression( $func_exp );
    is_deeply( $func_info, { package => 'main', name => 'backup', args => [ 'c.name', 'r.age' ], ret => 'r.content' }, 'success pattern1' );
}

{
    my $func_exp = " backup( c.name, r.age ) ";
    my $func_info = App::Sequence::_parse_func_expression( $func_exp );
    is_deeply( $func_info, { package => 'main', name => 'backup', args => [ 'c.name', 'r.age' ], ret => undef }, 'success pattern2' );
}

{
    my $func_exp = " backup( c.name, r.age ) ";
    my $func_info = App::Sequence::_parse_func_expression( $func_exp );
    is_deeply( $func_info, { package => 'main', name => 'backup', args => [ 'c.name', 'r.age' ], ret => undef }, 'success pattern3' );
}

{
    my $func_exp = " backup() :r.age";
    my $func_info = App::Sequence::_parse_func_expression( $func_exp );
    is_deeply( $func_info, { package => 'main', name => 'backup', args => [], ret => 'r.age' }, 'success pattern4' );
}

{
    my $func_exp = " backup:r.age";
    my $func_info = App::Sequence::_parse_func_expression( $func_exp );
    is_deeply( $func_info, { package => 'main', name => 'backup', args => [], ret => 'r.age' }, 'success pattern5' );
}

{
    my $func_exp = "A::backup( c.name, r.age ) : r.content";
    my $func_info = App::Sequence::_parse_func_expression( $func_exp );
    is_deeply( $func_info, { package => 'A', name => 'backup', args => [ 'c.name', 'r.age' ], ret => 'r.content' }, 'success pattern6' );
}

{
    my $func_exp = "A::B::backup( c.name, r.age ) : r.content";
    my $func_info = App::Sequence::_parse_func_expression( $func_exp );
    is_deeply( $func_info, { package => 'A::B', name => 'backup', args => [ 'c.name', 'r.age' ], ret => 'r.content' }, 'success pattern7' );
}

{
    my $func_exp = " backup( c.name, r.age, ) ";
    my $func_info = App::Sequence::_parse_func_expression( $func_exp );
    is_deeply( $func_info, { package => 'main', name => 'backup', args => [ 'c.name', 'r.age' ], ret => undef }, 'success pattern8' );
}

{
    my $func_exp = "a";
    my $func_info = App::Sequence::_parse_func_expression( $func_exp );
    is_deeply( $func_info, { package => 'main', name => 'a', args => [ ], ret => undef }, 'success pattern9' );
}

{
    my $func_exp = "a\n";
    my $func_info = App::Sequence::_parse_func_expression( $func_exp );
    is_deeply( $func_info, { package => 'main', name => 'a', args => [ ], ret => undef }, 'success pattern10' );
}

{
    my $func_exp = "a : stdout";
    my $func_info = App::Sequence::_parse_func_expression( $func_exp );
    is_deeply( $func_info, { package => 'main', name => 'a', args => [ ], ret => 'stdout' }, 'success pattern11' );
}


### error pattern
{
    my $func_exp = "( c.name, r.age ) : r.content";
    eval{
        my $func_info = App::Sequence::_parse_func_expression( $func_exp );
    };
    like( $@, qr/function name is invalid./, 'err pattern 1' );
}

{
    my $func_exp = "%%%uuiu( c.name, r.age ) : r.content";
    eval{
        my $func_info = App::Sequence::_parse_func_expression( $func_exp );
    };
    like( $@, qr/function name is invalid\. '%%%uuiu\( c\.name, r\.age \) : r\.content'/, 'err pattern 2' );
}

{
    my $func_exp = "aaa%%( c.name, r.age ) : r.content";
    eval{
        my $func_info = App::Sequence::_parse_func_expression( $func_exp );
    };
    like( $@, qr/parse error 'aaa%%\( c\.name, r\.age \) : r\.content'. expression must be like 'func_name\( c\.name, r\.age, \.\. \) : r\.content'/, 'err pattern 3' );
}

{
    my $func_exp = "backup( cc.name, r.age ) : r.content";
    eval{
        my $func_info = App::Sequence::_parse_func_expression( $func_exp );
    };
    like( $@, qr/arg 'cc\.name' is invalid\. arg must be like c\.name or r\.age, etc/, 'err pattern 3' );
}

{
    my $func_exp = "backup : rr.content";
    eval{
        my $func_info = App::Sequence::_parse_func_expression( $func_exp );
    };
    like( $@, qr/ret 'rr\.content' is invalid\. arg must be like r\.age, etc/, 'err pattern 4' );
}

