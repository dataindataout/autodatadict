#!/usr/local/bin/perl -w

# Valerie Parham-Thompson 2013-2016 for sharing
# keep it open and free

# todo: efficiency
# todo: don't block on large, busy datasets

use strict;
use DBI();
use Number::Format;
no warnings 'uninitialized'; #avoid issues with null columns

#connection string (host, database, user, pass)
my $dbh = DBI->connect('dbi:mysql:host=localhost;database=test',
 'root','', { PrintError => 1, RaiseError => 0 });

#if there is a connection string
if ($dbh) {

   my $database = '';
   
   my $database_sth = $dbh->prepare(<<SQL);
   select schema_name
   from information_schema.schemata
   where schema_name not in("mysql", "information_schema", "performance_schema", "sys")
   order by schema_name
SQL

   if ($database_sth) {
   $database_sth->execute;
   }

          #for each database (schema) found
          while (my $database = $database_sth->fetchrow_arrayref) {

          my $table = '';
          my $table_sth = $dbh->prepare(<<SQL);
          select table_name
          from information_schema.tables
          where table_schema=?
SQL

          if ($table_sth) {
          $table_sth->execute(@{ $database});
          }   

          #for each table found
          while (my $table = $table_sth->fetchrow_arrayref) {

              my $column_sth = $dbh->prepare(<<SQL);
              select column_name, data_type from information_schema.columns where table_schema=? and table_name=?
SQL

              if ($column_sth) {

                    $column_sth->execute(@{ $database },@{ $table });
                    $column_sth->bind_columns( \my( $column_name, $data_type ) );

                             #for each column
                             while ( $column_sth->fetch ) {

                             print "-----------\n";
                                
                                print join(".", @{ $database }, @{ $table }, $column_name);

                                print "\n";
                                
                                print "Data type: ".$data_type."\n";

                                #this block is in the wrong place
                                my ($count) = $dbh->selectrow_array("select count(*) from @{ $database }.@{ $table }");
                                print "Row count: ";
                                my $count_formatted = new Number::Format;
                                print $count_formatted->format_number($count,2);
                                print "\n";

                                if ($data_type ~~ ["char", "enum", "set", "varchar"]) {

                                    #select distinct($column) from $database.$table -> $distinct_char_values

                                    my $distinct_sth = $dbh->prepare("select distinct($column_name) from @{ $database }.@{ $table }");
                                    $distinct_sth->execute();
                                    if($distinct_sth) {
                                        print "Distinct values:\n";
                                    }
                                    my $ref;
                                    while($ref = $distinct_sth->fetchrow_arrayref) {
                                        print join (", ", @{$ref}), "\n";
                                    }

                                }

                                elsif ($data_type ~~ ["bigint", "decimal", "double", "float", "int", "mediumint", "smallint", "tinyint"]) {

                                    my ($min) = $dbh->selectrow_array("select min($column_name) from @{ $database }.@{ $table }");
                                    my ($max) = $dbh->selectrow_array("select max($column_name) from @{ $database }.@{ $table }");
                                    my ($avg) = $dbh->selectrow_array("select avg($column_name) from @{ $database }.@{ $table }");

                                    print "Min value: ".$min."\n";
                                    print "Max value: ".$max."\n";
                                    print "Avg value: ".$avg."\n";

                                }

                                elsif ($data_type ~~ ["datetime", "timestamp"]) {

                                    my ($min) = $dbh->selectrow_array("select min($column_name) from @{ $database }.@{ $table }");
                                    my ($max) = $dbh->selectrow_array("select max($column_name) from @{ $database }.@{ $table }");

                                    print "Min value: ".$min."\n";
                                    print "Max value: ".$max."\n";

                                }

                                elsif ($data_type ~~ ["binary", "blob", "longblob", "longtext", "mediumblob", "mediumtext", "text", "tinytext", "varbinary"]) {

                                    print "BLOB TYPE\n";
                                    #maybe a truncated sample here?

                                }

                            } #//while column_sth

                   } #//if column_sth

                   print "\n";
          } #//while table

     } #//if database_sth

     } else {

     print "Couldn't connect.\n";

     }

     $dbh->disconnect;

