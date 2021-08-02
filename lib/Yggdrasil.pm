#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I/home/phil/perl/cpan/NasmX86/lib/ -I/h-I/home/phil/perl/cpan/AsmC/lib/ -I/home/phil/perl/cpan/TreeTerm/lib/
#-------------------------------------------------------------------------------
# Yggdrasil - the world tree.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
# podDocumentation
package Yggdrasil;
our $VERSION = "20210801";
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Nasm::X86 qw(:all);
#use feature qw(say current_sub);

my $develop = -e q(/home/phil/);                                                # Developing

#D1 Parse                                                                       # Parse Unisyn expressions

my $debug = 0;                                                                  # 1 - Trace actions on stack

sub refScalar {Vq(key, 0)}                                                      # The branch used to hold scalar values - dwords at this point
sub refTree   {Vq(key, 1)}                                                      # The branch used to hold trees

sub describe($$;$)                                                              # Describe a world tree or one of its branches
 {my ($byteString, $tree, $result) = @_;                                        # Byte string, tree, optional result variable

  genHash(__PACKAGE__,
    byteString => $byteString,                                                  # Byte string containing the world tree
    tree       => $tree,                                                        # Block multi way tree representing the root or a branch of the world tree
    result     => $result ? $result : Vq(result, 0),                            # This variable will be set to show the result of the last operation
    data       => Vq(data, 0),                                                  # This variable will contain the data retrieved by the last retrieve operation
   );
 }

sub new()                                                                       # Create the world tree and return a description of it.
 {my $b = Nasm::X86::CreateByteString(free => 1);                               # Create a byte string to hold the world tree
  my $t = Nasm::X86::ByteString::CreateBlockMultiWayTree($b);                   # Create a block multi way tree in a byte string

  describe($b, $t)
 }

sub locateOrCreateBranch($$)                                                    # Create or locate a branch of the world tree and return a descriptor for it. Load the descriptor with either the description of an existing sub tree or of a new tree if it is necessary to create the branch.
 {my ($y, $key) = @_;                                                           # Yggdrasil, key to find
  my $data  = Vq(data);                                                         # The data associated with the key
  my $found = Vq(found);                                                        # Whether the key was found or not
  $y->tree->find(key => $key, $data, $found);                                   # Try to find the key provided

  my $b = $y->tree->bs;                                                         # The byte string containing the world tree
  my $d = Nasm::X86::BlockMultiWayTree::DescribeBlockMultiWayTree($b);          # Descriptor for the tree representing the new branch
  my $r = Vq(result,0);                                                         # Result variable

  If ($found, sub
   {$d->bs->bs->copy($b->bs);
    $d->first ->copy($data);
    $r->getConst(0);                                                            # Set result to zero to show that the branch was found
   },
  sub
   {my $t = Nasm::X86::ByteString::CreateBlockMultiWayTree($b);                 # Create the branch
    $y->tree  ->insert(key => $key, data => $t->first);
    $d->bs->bs->copy($b->bs);
    $d->first ->copy($t->first);
    $r->getConst(1);                                                            # Set result to one to show that the branch was found
   });
  describe($b, $d, $r);                                                         # Descriptor for the new branch
 }

sub assignScalarD($$)                                                           # Assign scalar dword
 {my ($y, $value) = @_;                                                         # Yggdrasil, value to assign

  $y->tree->insert(key => refScalar, data => $value);
  $y->result->getConst(0);
 }

sub retrieveScalarD($)                                                          # Retrieve a scalar dword
 {my ($y) = @_;                                                                 # Yggdrasil

  $y->tree->find(key => refScalar, $y->data, found=>$y->result);
  $y
 }

sub assignTree($$)                                                              # Assign a tree
 {my ($y, $Y) = @_;                                                             # Yggdrasil to assign to, tree to be assigned

  $y->tree->insert(key => refTree, data => $Y->tree->first);
  $y->result->getConst(0);
 }

sub retrieveTree($)                                                             # Retrieve a tree
 {my ($y) = @_;                                                                 # Yggdrasil

  my $data  = Vq(data);                                                         # The data associated with the key
  my $found = Vq(found);                                                        # Whether the key was found or not
  $y->tree->find(key => refTree, $data, $found);                                # Try to find the key provided
  my $d = Nasm::X86::BlockMultiWayTree::DescribeBlockMultiWayTree               # Descriptor for the tree representing the new branch
   ($y->byteString, $data);

  describe($y->byteString, $d);                                                 # Descriptor for the retrieved branch
 }

#d
#-------------------------------------------------------------------------------
# Export - eeee
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw();
%EXPORT_TAGS  = (all => [@EXPORT, @EXPORT_OK]);

# podDocumentation
=pod

=encoding utf-8

=head1 Name

Yggdrasil - the world tree.

=head1 Synopsis

Create a world tree

=head1 Description

=cut

# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
__DATA__
use Time::HiRes qw(time);
use Test::More;

my $localTest = ((caller(1))[0]//'Yggdrasil') eq "Yggdrasil";                   # Local testing mode

Test::More->builder->output("/dev/null") if $localTest;                         # Reduce number of confirmation messages during testing

if ($^O =~ m(bsd|linux|cygwin)i)                                                # Supported systems
 {plan tests => 99;
 }
else
 {plan skip_all => qq(Not supported on: $^O);
 }

my $startTime = time;                                                           # Tests

$debug = 1;                                                                     # Debug during testing

eval {goto latest} if !caller(0) and -e "/home/phil";                           # Go to latest test if specified

if (1) {
  my $y = new;
  my @y =
   ($y->locateOrCreateBranch(Vq(key, 1)),
    $y->locateOrCreateBranch(Vq(key, 2)),
    $y->locateOrCreateBranch(Vq(key, 1)),
    $y->locateOrCreateBranch(Vq(key, 2)),
   );

  for my $i(keys @y)
   {PrintOutStringNL "AAAA $i";
    $y[$i]->tree->first ->outNL;
    $y[$i]->result->outNL;
   }

  ok Assemble(debug => 0, eq => <<END);
AAAA 0
first: 0000 0000 0000 0098
result: 0000 0000 0000 0001
AAAA 1
first: 0000 0000 0000 0118
result: 0000 0000 0000 0001
AAAA 2
first: 0000 0000 0000 0098
result: 0000 0000 0000 0000
AAAA 3
first: 0000 0000 0000 0118
result: 0000 0000 0000 0000
END
 }

if (1) {
  my $y = new;

  for my $i(1..2)
   {my $Y = $y->locateOrCreateBranch(Vq(key,  1));
    $Y->assignScalarD               (Vq(data, 2));

    $Y->tree->first->outNL;
    $Y->retrieveScalarD;
    $Y->data->outNL('data : ');
   }

  ok Assemble(debug => 0, eq => <<END);
first: 0000 0000 0000 0098
data : 0000 0000 0000 0002
first: 0000 0000 0000 0098
data : 0000 0000 0000 0002
END
 }

latest:;
if (1) {
  my $y = new;
  my $b = $y->locateOrCreateBranch(Vq(key,  2));
     $b->assignScalarD            (Vq(data, 4));

  my $a = $y->locateOrCreateBranch(Vq(key,  1));
     $a->assignTree($b);

  my $c = $y->locateOrCreateBranch(Vq(key,  1));
  my $d = $c->retrieveTree($c);
  my $e = $d->locateOrCreateBranch(Vq(key,  2));
#  $e->outNL;

  ok Assemble(debug => 0, eq => <<END);
END
 }

ok 1 for 2..99;

unlink $_ for qw(hash print2 sde-log.txt sde-ptr-check.out.txt z.txt);          # Remove incidental files

lll "Finished:", time - $startTime;
