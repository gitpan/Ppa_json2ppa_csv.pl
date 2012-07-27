#!/usr/bin/perl -w

use strict;
use utf8;
use JSON -support_by_pp;
use LWP::Simple;
use IO::Uncompress::Unzip qw(unzip $UnzipError) ;
use IO::File;

=head1 NAME

ppa_json2ppa_csv.pl

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS
perl -f ppa_json2ppa_csv.pl URL

DESCRIPTION

This script is able to convert
http://www.acessoainformacao.rs.gov.br/upload/20120515155323ppa_orcamento_2012.zip
into a CSV. The resultant file can be used to upload data for the Coletivo 28 project,
that will generate an unlimited set of questions about titles and descriptions
of the projects available at the URL 

=cut


my $url = shift;
my $file = 'ppa.zip';

getstore($url, $file);

my $input = "ppa.zip";
my $output = "ppa.json";

unzip $input => $output
or die "unzip failed: $UnzipError\n";

my $fh = IO::File->new();
$fh->open("< ppa.json");

open (my $saida, ">", "taxo.csv") || die "Não posso escrever o arquivo taxo.csv: $!";

fetch_json_page();

$fh->close;
 
sub fetch_json_page
{
  eval{
    print "Culto,Categoria,Comentario\n";
    my $json = new JSON;
    my $json_text = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode(<$fh>);
    my $programa_num = 1;
    foreach my $programa(@{$json_text->{programa}}){
      my %ep_hash = ();
      $ep_hash{nome_programa} = '"'.$programa->{nome_programa}.'"';
      
      $ep_hash{objetivo_programa} = $programa->{objetivo_programa};
      
      if (length($programa->{objetivo_programa})>58){ #58 e não 64 por causa do marcador de supressão [...] que será adicionado
        $ep_hash{objetivo_programa} = substr($programa->{objetivo_programa},0,58);
        $ep_hash{objetivo_programa} =~ s/\s+\w+$//;
        $ep_hash{objetivo_programa} = '"'.$ep_hash{objetivo_programa}."[...]".'"';
        #print $saida $ep_hash{objetivo_programa}."\n";
      }
      else{
        $ep_hash{objetivo_programa} = '"'.$programa->{objetivo_programa}.'"';
        #print $saida $ep_hash{objetivo_programa}."\n";
      };
      
      if ($ep_hash{objetivo_programa} ne '" "' and $ep_hash{nome_programa} ne '" "'){
        print $saida $ep_hash{objetivo_programa}."\n";
        while (my($k, $v) = each (%ep_hash)){
          for ($v,$programa->{objetivo_programa}) {
              s/\t+|\r\n//g;              
          }
          print "$v,";
        }        
        print '"'.$programa->{objetivo_programa}.'"';
        
        print "\n";
      }
      $programa_num++;
    }
  };
  if($@){
    print "[[JSON ERROR]] O parser JSON falhou! $@\n";
  }
}

close $saida;

1;

=head1 AUTHOR

Rodrigo Panchiniak Fernandes, C<< <fernandes at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 Rodrigo Panchiniak Fernandes, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut