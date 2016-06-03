#!/usr/local/bin/perl -w

use strict;
use DBI();
no warnings 'uninitialized'; #avoid issues with null columns

#connection string (host, database, user, pass)
my $dbh = DBI->connect('dbi:mysql:host=localhost;database=test',
   '','', { PrintError => 1, RaiseError => 0 });

#if there is a connection string
if ($dbh) {

     my $database = '';
   
     my $database_sth = $dbh->prepare(<<SQL);
     select schema_name
     from information_schema.schemata
     where schema_name not in("mysql", "information_schema", "performance_schema")
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
               select column_name, data_type, is_nullable, column_default, character_maximum_length, collation_name from information_schema.columns where table_schema=? and table_name=?
SQL

               #get the column names and put them into variables
               if ($column_sth) {
                         $column_sth->execute(@{ $database },@{ $table });
                         $column_sth->bind_columns( \my( $column_name, $data_type, $is_nullable, $column_default, $character_maximum_length, $collation_name ) );

                    #print the results
                    print join(" | ", @{ $database }, @{ $table }, $column_name, $data_type, $is_nullable, $column_default, $character_maximum_length, $collation_name,"\n");

               } #//if column_sth

               print "\n";
          } #//while table
         
     } #//if database_sth
         
} else {

        print "Couldn't connect.\n";

}

$dbh->disconnect;

