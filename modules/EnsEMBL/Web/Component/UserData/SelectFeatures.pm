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

# $Id: SelectFeatures.pm,v 1.3 2014-01-10 14:30:08 nl2 Exp $

package EnsEMBL::Web::Component::UserData::SelectFeatures;

use strict;


sub content {
  my $self              = shift;
  my $hub               = $self->hub;
  my $session           = $hub->session;
  my $species_defs      = $hub->species_defs;
  my $species           = $hub->data_species;
  my @valid_species     = $species_defs->valid_species;
  my %assembly_mappings = map { $_ => $species_defs->get_config($_, 'ASSEMBLY_MAPPINGS') } @valid_species;
  my @mapping_species   = sort grep $assembly_mappings{$_}, @valid_species;
  my $html;

  if (scalar @mapping_species) {
    my $user      = $hub->user;
    my $subheader = 'Upload file';
    my $form      = $self->modal_form('select', $hub->url({ action => 'CheckConvert', __clear => 1 }));
    my (@forward, @backward, @species_values);
    
    $form->add_notes({
      heading => 'Tips',
      text    => qq{
        <p>
          Map your data to the current assembly. 
          The tool accepts a <a href="/info/website/upload/bed.html#required">list of simple coordinates</a>, 
          or files in these formats: 
          <a href="/info/website/upload/gff.html">GFF</a>,
          <a href="/info/website/upload/gff.html">GTF</a>,
          <a href="/info/website/upload/bed.html">BED</a>,
          <a href="/info/website/upload/psl.html">PSL</a>
        </p>
        <p>N.B. Export is currently in GFF only</p>
        <p>For large data sets, you may find it more efficient to use our <a href="http://cvs.sanger.ac.uk/cgi-bin/viewvc.cgi/ensembl-tools/scripts/assembly_converter/?root=ensembl">ready-made converter script</a>.</p>
      }
    });
    
    ## Munge data needed for form elements
## EG : Triticum is a ghost species - only exist in ENA - we display the mappings on anothe page
    foreach (grep { $_ !~ /Triticum/} @mapping_species) {
      push @species_values, { value => $_, caption => $species_defs->species_label($_, 1) };
     
      my @mappings = ref($assembly_mappings{$_}) eq 'ARRAY' ? @{$assembly_mappings{$_}} : ($assembly_mappings{$_});
 
      foreach my $string (sort { $b cmp $a } @mappings) {
        my ($to, $from) = split '#', $string;
        ## Which mapping set? Have to fetch all, for easy JS auto-changing with species
        push @forward,  { caption => "$from -> $to", value => "${from}:$to", class => "_stt_$_" };
        push @backward, { caption => "$to -> $from", value => "${to}:$from", class => "_stt_$_" };
      }
    }
##

## EG - use species selector instead of simple dropdown
    my $select = $form->add_element(
      'type'    => 'DropDown',
      'name'    => 'species',
      'label'   => "Species",
      'values'  => @species_values <= 100 ? \@species_values : [{ value => $species, caption => $hub->species_defs->species_display_label($species) }],
      'value'   => $species,
      'select'  => 'select',
      'class'   => @species_values <= 100 ? '_stt species-selector' : '_stt ajax-species-selector',
    );
    $select->set_attribute('class', $select->get_attribute('class') . ' species-selector');
##

    $form->add_field({
      type   => 'dropdown',
      name   => 'conversion',
      label  => 'Assembly/coordinates to convert',
      values => [ @forward, @backward ]
    });

    ## Check for uploaded data for this species
    my @data = grep { $_->{'species'} eq $species } map { $user ? $user->get_records($_) : (), $session->get_data(type => substr $_, 0, -1) } qw(uploads urls);
  
    if (scalar @data) {
      $form->add_element(type => 'SubHeader', value => 'Select existing upload(s)');
      
      $subheader = 'Or upload new file';
      
      foreach my $file (@data) {
        my ($name, $id) = ref($file) =~ /Record/ ? ($file->name, join('-', 'user', $file->type, $file->id)) : ($file->{'name'}, "temp-$file->{'type'}-$file->{'code'}");
        
        $form->add_element(
          type  => 'CheckBox',
          name  => 'convert_file',
          label => $name,
          value => "${id}:$name",
        );
      }
    }

    $form->add_element(type => 'SubHeader', value => $subheader);
    $form->add_element(type => 'Hidden', name => 'filetype', value => 'Assembly Converter');
    $form->add_element(type => 'String', name => 'name', label => 'Name for this data (optional)');
    $form->add_element(type => 'Text',   name => 'text', label => 'Paste data');
    $form->add_element(type => 'File',   name => 'file', label => 'Upload file');
    $form->add_element(type => 'URL',    name => 'url',  label => 'or provide file URL', size => 30);
    
    $html .= $form->render;
  } else {
    $html .= $self->_info('No mappings', '<p>Sorry, no species currently have assembly mappings.</p>');
  }
  
  return $html;
}

1;
