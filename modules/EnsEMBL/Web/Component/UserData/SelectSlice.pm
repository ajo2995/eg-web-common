=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Component::UserData::SelectSlice;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Component::UserData);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub caption {
  my $self = shift;
  return '';
}

sub content {
  my $self = shift;
  my $hub = $self->hub;
  
  my $current_species = $hub->species_path($hub->data_species);
  my $form = $self->modal_form('select_vcf', "$current_species/UserData/SliceFile", {'wizard' => 1, 'back_button' => 0});
  my $user = $hub->user;
  my $sitename = $hub->species_defs->ENSEMBL_SITETYPE;

  # URL-based section
  $form->add_notes({'heading'=>'Tip', 'text'=> qq(
    When slicing a VCF or BAM file, both the data file and its index file should be present on the web server and named correctly. <br />
    The VCF file should have a ".vcf.gz" extension, and the index file should have a ".vcf.gz.tbi" extension, E.g: MyData.vcf.gz, MyData.vcf.gz.tbi <br />
    The BAM file should have a ".bam" extension, and the index file should have a ".bam.bai" extension, E.g: MyData.bam, MyData.bam.bai
  )});

  $form->add_element('type'  => 'URL',
                     'name'  => 'url',
                     'label' => 'VCF / BAM File URL',
                     'size'  => '30',
                     'value' => $hub->param('url'),
                     'notes' => '( e.g. http://www.example.com/MyProject/MyData.vcf.gz )');

  $form->add_element('type'  => 'String',
                     'name'  => 'region',
                     'label' => 'Region',
                     'size'  => '30',
                     'notes' => '( e.g. 1:1-50000 )');


  return $form->render;
}

1;
