#!/usr/bin/perl -w

# $Id: dbi.t,v 1.2 2002/08/23 00:55:45 david Exp $

use strict;
use Test::More (tests => 14);
BEGIN { use_ok('Exception::Class::DBI') }
use DBI;

eval {
    DBI->connect('dbi:Bogus', '', '',
                 { PrintError => 0,
                   RaiseError => 0,
                   HandleError => Exception::Class::DBI->handler
                 });
};

ok( my $err = $@, "Catch exception" );
SKIP: {
    # Remove this skip when DBI->connect uses exceptions.
    skip 'HandleError not logic not yet used by DBI->connect', 6
      unless ref $@;
    isa_ok( $err, 'Exception::Class::DBI' );
    like( $err->error, qr{Can't connect\(dbi:Bogus   HASH\([^\)]+\)\), no database driver specified and DBI_DSN env var not set},
          "Check error" );
    ok( ! defined $err->err, "Check err" );
    ok( ! defined $err->errstr, "Check errstr" );
    ok( ! defined $err->state, "Check state" );
    ok( ! defined $err->retval, "Check retval" );

    # Try to trigger a usage exception.
    eval {
        DBI->connect('', '', {}, # uh-oh, referenced password.
                 { PrintError => 0,
                   RaiseError => 0,
                   HandleError => Exception::Class::DBI->handler
                 });
    };
    ok( $err = $@, "Catch usage exception" );
    isa_ok( $err, 'Exception::Class::DBI' );
    is( $err->error, 'Usage: $class->connect([$dsn [,$user [,$passwd ' .
        '[,\%attr]]]])', "Check usage error" );

  TODO: {
        # Remove this TODO when DBI->install_driver uses exceptions.
        local $TODO = "DBI->install_driver doesn't use HandleError Yet";
        # Try to trigger a install driver error.
        eval {
            DBI->connect('dbi:dummy:foo', '', '', # dummy driver.
                         { PrintError => 0,
                           RaiseError => 0,
                           HandleError => Exception::Class::DBI->handler
                         });
        };
        ok( $err = $@, "Catch usage exception" );
        isa_ok( $err, 'Exception::Class::DBI' );
      SKIP: {
            # Remove this SKIP when DBI->install_driver uses exceptions.
            skip 'HandleError not logic not yet used by DBI->install_driver', 1
              unless ref $err;
            # Can take out "ref $err" when the TODO is completed.
            is( $err->error, 'panic: $class->install_driver(dummy) failed',
                "Check driver error" );
        }
    }
}