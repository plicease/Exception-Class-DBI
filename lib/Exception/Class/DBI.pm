package Exception::Class::DBI;

# $Id: DBI.pm,v 1.6 2002/08/23 20:11:01 david Exp $

use 5.00500;
use strict;
use Exception::Class;
use vars qw($VERSION);
$VERSION = '0.02';

use Exception::Class ( 'Exception::Class::DBI' =>
                       { description => 'DBI exception',
                         fields => [qw(err errstr state retval)]
                       },
                       'Exception::Class::DBI::Unknown' =>
                       { isa => 'Exception::Class::DBI',
                         description => 'DBI unknown exception'
                       },
                       'Exception::Class::DBI::H' =>
                       { isa => 'Exception::Class::DBI',
                         description => 'DBI handle exception',
                         fields => [qw(warn active kids active_kids compat_mode
                                       inactive_destroy trace_level
                                       fetch_hash_key_name chop_blanks
                                       long_read_len long_trunc_ok taint)]
                       },
                        'Exception::Class::DBI::DRH' =>
                        { isa => 'Exception::Class::DBI::H',
                          description => 'DBI driver handle exception',
                        },
                        'Exception::Class::DBI::DBH' =>
                        { isa => 'Exception::Class::DBI::H',
                          description => 'DBI database handle exception',
                          fields => [qw(auto_commit db_name statement
                                        row_cache_size)]
                        },
                        'Exception::Class::DBI::STH' =>
                        { isa => 'Exception::Class::DBI::H',
                          description => 'DBI statment handle exception',
                          fields => [qw(num_of_fields num_of_params field_names
                                        type precision scale nullable
                                        cursor_name param_values statement
                                        rows_in_cache)]
                        }
                      );

sub handler {
    sub {
        my ($err, $dbh, $retval) = @_;
        if (ref $dbh) {
            # Assemble arguments for a handle exception.
            my @params = ( error               => $err,
                            errstr              => $dbh->errstr,
                            err                 => $dbh->err,
                            state               => $dbh->state,
                            retval              => $retval,
                            warn                => $dbh->{Warn},
                            active              => $dbh->{Active},
                            kids                => $dbh->{Kids},
                            active_kids         => $dbh->{ActiveKids},
                            compat_mode         => $dbh->{CompatMode},
                            inactive_destroy    => $dbh->{InactiveDestroy},
                            trace_level         => $dbh->{TraceLevel},
                            fetch_hash_key_name => $dbh->{FetchHashKeyName},
                            chop_blanks         => $dbh->{ChopBlanks},
                            long_read_len       => $dbh->{LongReadLen},
                            long_trunc_ok       => $dbh->{LongTruncOk},
                            taint               => $dbh->{Taint},
                         );
            if (UNIVERSAL::isa($dbh, 'DBI::dr')) {
                # Just throw a driver exception. It has no extra attributes.
                die Exception::Class::DBI::DRH->new(@params);
            } elsif (UNIVERSAL::isa($dbh, 'DBI::db')) {
                # Throw a database handle exception.
                die Exception::Class::DBI::DBH->new
                  ( @params,
                    auto_commit    => $dbh->{AutoCommit},
                    db_name        => $dbh->{Name},
                    statement      => $dbh->{Statement},
                    row_cache_size => $dbh->{RowCacheSize}
                  );
            } elsif (UNIVERSAL::isa($dbh, 'DBI::st')) {
                # Throw a statement handle exception.
                die Exception::Class::DBI::STH->new
                  ( @params,
                    num_of_fields => $dbh->{NUM_OF_FIELDS},
                    num_of_params => $dbh->{NUM_OF_PARAMS},
                    field_names   => $dbh->{NAME},
                    type          => $dbh->{TYPE},
                    precision     => $dbh->{PRECISION},
                    scale         => $dbh->{SCALE},
                    nullable      => $dbh->{NULLABLE},
                    cursor_name   => $dbh->{CursorName},
                    param_values  => $dbh->{ParamValues},
                    statement     => $dbh->{Statement},
                    rows_in_cache => $dbh->{RowsInCache}
                  );
            } else {
                # Unknown exception. This shouldn't happen.
                die Exception::Class::DBI::Unknown->new(@params);
            }
        } else {
            # Set up for a base class exception.
            my $exc = 'Exception::Class::DBI';
            # Make it an unknown exception if $dbh isn't a DBI class
            # name. Probably shouldn't happen.
            $exc .= '::Unknown' unless $dbh and UNIVERSAL::isa($dbh, 'DBI');
            if ($DBI::lasth) {
                # There was a handle. Get the errors. This may be superfluous,
                # since the handle ought to be in $dbh.
                die $exc->new( error  => $err,
                               errstr => $DBI::errstr,
                               err    => $DBI::err,
                               state  => $DBI::state,
                               retval => $retval
                             );
            } else {
                # No handle, no errors.
                die $exc->new( error  => $err,
                               retval => $retval
                             );
            }
        }
    };
}

1;
__END__

=head1 NAME

Exception::Class::DBI - DBI Exception objects

=head1 SYNOPSIS

  use DBI;
  use Exception::Class::DBI;

  my $dbh = DBI->connect( $data_source, $username, $auth,
                          { PrintError => 0,
                            RaiseError => 0,
                            HandleError => Exception::Class::DBI->handler
                          });

  eval { $dbh->do($sql) };

  if (my $ex = $@) {
      print STDERR "DBI Exception:\n";
      print STDERR "  Exception Type: ", ref $ex, "\n";
      print STDERR "  Error: ", $ex->error, "\n";
      print STDERR "  Err: ", $ex->err, "\n";
      print STDERR "  Errstr: " $ex->errstr, "\n";
      print STDERR "  State: ", $ex->state, "\n";
      my $ret = $ex->retval;
      $ret = 'undef' unless defined $ret;
      print STDERR "  Return Value: $ret\n";
  }

=head1 DESCRIPTION

This module offers a set of DBI-specific exception classes. They inherit from
Exception::Class::Base, the base class for all exception objects created by
the Exception::Class module from the CPAN. Exception::Class::DBI itself offers
a single class method, C<handler()>, that returns a code reference appropriate
for passing the DBI C<HandleError> attribute.

The exception classes created by Exception::Class::DBI are designed to be
thrown in certain DBI contexts; the code reference returned by C<handler()>
and passed to the DBI C<HandleError> attribute determines the context,
assembles the necessary metadata, and throws the apopropriate exception.

Each of the Exception::Class::DBI classes offers a set of object accessor
methods in addition to those provided by Exception::Class::Base. These can be
used to output detailed output in the event of an exception.

=head1 INTERFACE

Exception::Class::DBI inherits from Exception::Class::Base, and thus its
entire interface. Refer to the Exception::Class documentation for details.

=head2 Class Method

=over 4

=item C<handler>

  my $dbh = DBI->connect( $data_source, $username, $auth,
                          { PrintError => 0,
                            RaiseError => 0,
                            HandleError => Exception::Class::DBI->handler
                          });

This method returns a code reference appropriate for passing to the DBI
C<HandleError> attribute. When DBI encounters an error, it checks its
C<PrintError>, C<RaiseError>, and C<HandleError> attributes to decide what to
do about it. When C<HandleError> has been set to a code reference, DBI
executes it, passing it the error string that would be printed for
C<PrintError>, the DBI handle object that was executing the method call that
triggered the error, and the return value of that method call (usually
C<undef>). Using these arguments, the code reference provided by C<handler()>
determines what type of exception to throw. Exception::Class::DBI contains the
subclasses detailed below, each relevant to the DBI handle that triggered the
error.

=back

=head1 CLASSES

Exception::Class::DBI creates a number of exception classes, each one specific
to a particular DBI error context. Most of the object methods described below
correspond to like-named attributes in the DBI itself. Thus the documentation
below summarizes the DBI attribute documentation, so you should refer to
L<DBI|DBI> itself for more in-depth information.

=head2 Exception::Class::DBI

All of the Exception::Class::DBI classes documented below inherit from
Exception::Class::DBI. It offers the several object methods in addition to
those it inherits from I<its> parent, Exception::Class::Base. These methods
correspond to the L<DBI dynamic attributes|DBI/"DBI Dynamic Attributes">, as
well as to the values passed to the C<handler()> exception handler via the DBI
C<HandleError> attribute. Exceptions of this base class are only thrown when
there is no DBI handle object executing, e.g. in the DBI C<connect()>
method. B<Note:> This functionality is not yet implemented in DBI -- see the
discusion that starts here:
L<http://archive.develooper.com/dbi-dev@perl.org/msg01438.html>.

=over 4

=item C<error>

  my $error = $ex->error;

Exception::Class::DBI actually inherits this method from
Exception::Class::Base. It contains the error string that DBI prints when its
C<PrintError> attribute is enabled, or C<die>s with when its <RaiseError>
attribute is enabled.

=item C<err>

  my $err = $ex->err;

Corresponds to the C<$DBI::err> dynamic attribute. Returns the native database
engine error code from the last driver method called.

=item C<errstr>

  my $errstr = $ex->errstr;

Corresponds to the C<$DBI::errstr> dynamic attribute. Returns the native
database engine error message from the last driver method called.

=item C<state>

  my $state = $ex->state;

Corresponds to the C<$DBI::state> dynamic attribute. Returns an error code in
the standard SQLSTATE five character format.

=item C<retval>

  my $retval = $ex->retval;

The first value being returned by the DBI method that failed (typically
C<undef>).

=back

=head2 Exception::Class::DBI::H

This class inherits from L<Exception::Class::DBI|"Exception::Class::DBI">, and
is the base class for all DBI handle exceptions (see below). It will not be
thrown directly. Its methods correspond to the L<DBI attributes common to all
handles|DBI/"ATTRIBUTES COMMON TO ALL HANDLES">.

=over 4

=item C<warn>

  my $warn = $ex->warn;

Boolean value indicating whether DBI warnings have been enabled. Corresponds
to the DBI C<Warn> attribute.

=item C<active>

  my $active = $ex->active;

Boolean value indicating whether the DBI handle that encountered the error is
active. Corresponds to the DBI C<Active> attribute.

=item C<kids>

  my $kids = $ex->kids;

For a driver handle, Kids is the number of currently existing database handles
that were created from that driver handle. For a database handle, Kids is the
number of currently existing statement handles that were created from that
database handle. Corresponds to the DBI C<Kids> attribute.

=item C<active_kids>

  my $active_kids = $ex->active_kids;

Like C<kids>, but only counting those that are C<active> (as
above). Corresponds to the DBI C<ActiveKids> attribute.

=item C<compat_mode>

  my $compat_mode = $ex->compat_mode;

Boolean value indicating whether an emulation layer (such as Oraperl) enables
compatible behavior in the underlying driver (e.g., DBD::Oracle) for this
handle. Corresponds to the DBI C<CompatMode> attribute.

=item C<inactive_destroy>

  my $inactive_destroy = $ex->inactive_destroy;

Boolean value indicating whether the DBI has disabled the database engine
related effect of C<DESTROY>ing a handle. Corresponds to the DBI
C<InactiveDestroy> attribute.

=item C<trace_level>

  my $trace_level = $ex->trace_level;

Returns the DBI trace level set on the handle that encountered the
error. Corresponds to the DBI C<TraceLevel> attribute.

=item C<fetch_hash_key_name>

  my $fetch_hash_key_name = $ex->fetch_hash_key_name;

Returns the attribute name the DBI C<fetchrow_hashref()> method should use to
get the field names for the hash keys. Corresponds to the DBI
C<FetchHashKeyName> attribute.

=item C<chop_blanks>

  my $chop_blanks = $ex->chop_blanks;

Boolean value indicating whether DBI trims trailing space characters from
fixed width character (CHAR) fields. Corresponds to the DBI C<ChopBlanks>
attribute.

=item C<long_read_len>

  my $long_read_len = $ex->long_read_len;

Returns the maximum length of long fields ("blob", "memo", etc.) which the DBI
driver will read from the database automatically when it fetches each row of
data. Corresponds to the DBI C<LongReadLen> attribute.

=item C<long_trunc_ok>

  my $long_trunc_ok = $ex->long_trunc_ok;

Boolean value indicating whether the DBI will truncate values it retrieves from
long fields that are longer than the value returned by
C<long_read_len()>. Corresponds to the DBI C<LongTruncOk> attribute.

=item C<taint>

  my $taint = $ex->taint;

Boolean value indicating whether data fetched from the database is considered
tainted. Corresponds to the DBI C<Taint> attribute.

=back

=head2 Exception::Class::DBI::DRH

DBI driver handle exceptions objects. This class inherits from
L<Exception::Class::DBI::H|"Exception::Class::DBI::H">, and offers no extra
methods of its own.

=head2 Exception::Class::DBI::DBH

DBI database handle exceptions objects. This class inherits from
L<Exception::Class::DBI::H|"Exception::Class::DBI::H"> Its methods correspond
to the L<DBI database handle attributes|DBI/"Database Handle Attributes">.

=over 4

=item C<auto_commit>

  my $auto_commit = $ex->auto_commit;

Returns true if the database handle C<AutoCommit> attribute is
enabled. meaning that database changes cannot be rolled back. Corresponds to
the DBI database handle C<AutoCommit> attribute.

=item C<db_name>

  my $db_name = $ex->db_name;

Returns the "name" of the database. Corresponds to the DBI database handle
C<Name> attribute.

=item C<statement>

  my $statement = $ex->statement;

Returns the statement string passed to the most recent call to the DBI
C<prepare()> method in this database handle. If it was the C<prepare()> method
that encountered the error and triggered the exception, the statement string
will be the statement passed to C<prepare()>. Corresponds to the DBI database
handle C<Statement> attribute.

=item C<row_cache_size>

  my $row_cache_size = $ex->row_cache_size;

Returns the hint to the database driver indicating the size of the local row
cache that the application would like the driver to use for future C<SELECT>
statements. Corresponds to the DBI database handle C<RowCacheSize> attribute.

=back

=head2 Exception::Class::DBI::STH

DBI statement handle exceptions objects. This class inherits from
L<Exception::Class::DBI::H|"Exception::Class::DBI::H"> Its methods correspond
to the L<DBI statement handle attributes|DBI/"Statement Handle Attributes">.

=over 4

=item C<num_of_fields>

  my $num_of_fields = $ex->num_of_fields;

Returns the number of fields (columns) the prepared statement will
return. Corresponds to the DBI statement handle C<NUM_OF_FIELDS> attribute.

=item C<num_of_params>

  my $num_of_params = $ex->num_of_params;

Returns the number of parameters (placeholders) in the prepared
statement. Corresponds to the DBI statement handle C<NUM_OF_PARAMS> attribute.

=item C<field_names>

  my $field_names = $ex->field_names;

Returns a reference to an array of field names for each column. Corresponds to
the DBI statement handle C<NAME> attribute.

=item C<type>

  my $type = $ex->type;

Returns a reference to an array of integer values for each column. The value
indicates the data type of the corresponding column. Corresponds to the DBI
statement handle C<TYPE> attribute.

=item C<precision>

  my $precision = $ex->precision;

Returns a reference to an array of integer values for each column. For
non-numeric columns, the value generally refers to either the maximum length
or the defined length of the column. For numeric columns, the value refers to
the maximum number of significant digits used by the data type (without
considering a sign character or decimal point). Corresponds to the DBI
statement handle C<PRECISION> attribute.

=item C<scale>

  my $scale = $ex->scale;

Returns a reference to an array of integer values for each column. Corresponds
to the DBI statement handle C<SCALE> attribute.

=item C<nullable>

  my $nullable = $ex->nullable;

Returns a reference to an array indicating the possibility of each column
returning a null. Possible values are 0 (or an empty string) = no, 1 = yes, 2
= unknown. Corresponds to the DBI statement handle C<NULLABLE> attribute.

=item C<cursor_name>

  my $cursor_name = $ex->cursor_name;

Returns the name of the cursor associated with the statement handle, if
available. Corresponds to the DBI statement handle C<CursorName> attribute.

=item C<param_values>

  my $param_values = $ex->param_values;

Returns a reference to a hash containing the values currently bound to
placeholders. Corresponds to the DBI statement handle C<ParamValues>
attribute.

=item C<statement>

  my $statement = $ex->statement;

Returns the statement string passed to the DBI C<prepare()>
method. Corresponds to the DBI statement handle C<Statement> attribute.

=item C<rows_in_cache>

  my $rows_in_cache = $ex->rows_in_cache;

the number of unfetched rows in the cache if the driver supports a local row
cache for C<SELECT> statements. Corresponds to the DBI statement handle
C<RowsInCache> attribute.

=back

=head2 Exception::Class::DBI::Unknown

Exceptions of this class are thrown when the context for a DBI error cannot be
determined. Inherits from L<Exception::Class::DBI|"Exception::Class::DBI">,
but implements no methods of its own.

=head1 NOTE

B<Note:> Not I<all> of the attributes offered by the DBI are exploited by
these exception classes. For example, the C<PrintError> and C<RaiseError>
attributes seemed redundant. But if folks think it makes sense to include the
missing attributes for the sake of completeness, let me know. Enough interest
will motivate me to get them in.

=item TO DO

I need to figure out a non-database specific way of testing STH exceptions.
DBD::ExampleP works well for DRH and DBH exceptions, but not so well for
STH exceptions.

=head1 BUGS

Report all bugs via the CPAN Request Tracker at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Exception-Class-DBI>.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

You should really only be using this module in conjunction with Tim Bunce's
L<DBI|DBI>, so it pays to be familiar with its documentation.

See the documentation for Dave Rolsky's L<Exception::Class|Exception::Class>
module for details on the methods this module's classes inherit from
Exception::Class::Base. There's lots more information in these exception
objects, so use them!

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
