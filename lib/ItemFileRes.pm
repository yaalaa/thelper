#
# The MIT License (MIT)
#
# Copyright (c) 2015 yaalaa
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#
# Resource file
#
package ItemFileRes;


use strict;
use CommonUtils;
use Text::CSV_XS;
use ItemTextRes;
use Scalar::Util qw(blessed);


#
# Initializes object
# 
# @param fileName - filename
# @param source   - type of source of the file (i.e. android resource, etc.)
# @param lang     - language
#
# @return initialized object
#
sub new
{
    my ( $class, $fileName, $source, $lang ) = @_;

    my $self = bless 
    {
        fileName => $fileName,
        source => $source,
        lang => $lang,
        fileData => undef,
        items => [],
        itemsExt => [],
        plains => {},
        plurals => {},
    }, $class;
    
    return $self;
}

#
# Retrieves filename
#
# @return filename
#
sub getFileName
{
    my $self = shift;

    return $self->{fileName};
}

#
# Retrieves source
#
# @return source
#
sub getSource
{
    my $self = shift;

    return $self->{source};
}

#
# Retrieves language
#
# @return language
#
sub getLang
{
    my $self = shift;

    return $self->{lang};
}

#
# Retrieves file data
#
# @return file data
#
sub getFileData
{
    my $self = shift;

    return $self->{fileData};
}

#
# Sets file data
#
# @param data - file data
#
sub setFileData
{
    my ( $self, $data ) = @_;

    $self->{fileData} = $data;
}

#
# Adds item
#
# @param item - text resource as ItemTextRes
#
# @return !=0, if succeeded
#
sub addItem
{
    my ( $self, $item ) = @_;

    my $out = 0;
    
    {{
        if ( blessed $item && $item->isa( "ItemTextRes" ) ) # ItemTextRes
        {
            my $id = $item->getId();
            
            if ( $id eq "" ) # no ID
            {
                printf "ItemFileRes::addItem: no id\n";
                last;
            }
            
            push( @{ $self->{items} }, $item );
            
            if ( $item->isPlural() ) # it's plural
            {
                $self->{plurals}->{$id} = $item;
            }
            else # plain
            {
                $self->{plains}->{$id} = $item;
            }
        }
        elsif ( blessed $item && $item->isa( "ItemCommentRes" ) ) # instance of ItemCommentRes
        {
            # do nothing for now
        }
        else
        {
            printf "ItemFileRes::addItem: unsupported type:[%s]\n", blessed( $item );
            last;
        }
        
        push( @{ $self->{itemsExt} }, $item );
        
        $out = 1;
    }}
    
    return $out;
}

#
# Retrieves items list
#
# @return items list
#
sub getItems
{
    my $self = shift;

    return $self->{items};
}

#
# Retrieves extended items list
#
# @return extended items list
#
sub getItemsExt
{
    my $self = shift;

    return $self->{itemsExt};
}

#
# Retrieves plain item with specified ID
#
# @param id - item ID
#
# @return item as ItemTextRes
#
sub getItemPlainById
{
    my ( $self, $id ) = @_;
    
    my $out;
    
    {{
        if ( $id eq "" ) # no ID
        {
            last;
        }
        
        $out = $self->{plains}->{$id};
    }}
    
    return $out;
}

#
# Retrieves plural item with specified ID
#
# @param id - item ID
#
# @return item as ItemTextRes
#
sub getItemPluralById
{
    my ( $self, $id ) = @_;
    
    my $out;
    
    {{
        if ( $id eq "" ) # no ID
        {
            last;
        }
        
        $out = $self->{plurals}->{$id};
    }}
    
    return $out;
}

#
# Retrieves item with specified ID
#
# @param id     - item ID
# @param plural - != 0 to look for plural
#
# @return item as ItemTextRes
#
sub getItemById
{
    my ( $self, $id, $plural ) = @_;
    
    return $plural ? $self->getItemPluralById( $id ) : $self->getItemPlainById( $id );
}

#
# Saves items to CSV file
#
# @param fileName - output CSV file name
#
# @return !=0, if succeeded
#
sub saveItemsToCsv
{
    my ( $self, $fileName ) = @_;
    
    my $out = 0;

    my $file;
    
    {{
        if ( $fileName eq "" ) # no filename
        {
            printf "ItemFileRes::saveItemsToCsv: no filename\n";
            last;
        }
        
        if ( !open( $file, ">:utf8", $fileName ) ) # failed
        {
            printf "ItemFileRes::saveItemsToCsv: open failed[%s]: %s\n", $fileName, $!;
            last;
        }
        
        my $csv = Text::CSV_XS->new( { binary => 1, eol => $/ } );

        if ( !$csv->print( $file, [ "ID", "Modifier", "Original" ] ) ) # failed
        {
            printf "ItemFileRes::saveItemsToCsv: csv::print failed: %s\n", $csv->status();
            last;
        }
        
        my $ok = 1;
        
        foreach my $item ( @{ $self->{items} } )
        {
            if ( !$item->isPlural() )
            {
                if ( !$csv->print( $file, [ $item->getId(), "", $item->getText()->getData() ] ) ) # failed
                {
                    printf "ItemFileRes::saveItemsToCsv: csv::print failed: %s\n", $csv->status();
                    $ok = 0;
                    last;
                }
            } else 
            {
            }
        }
        
        if ( !$ok )
        {
            last;
        }
        
        $out = 1;
    }}
    
    if ( defined( $file ) )
    {
        close( $file );
    }
    
    return $out;
}

#
# Load items from CSV file
#
# @param fileName - output CSV file name
#
# @return read items count
#
sub loadItemsFromCsv
{
    my ( $self, $fileName ) = @_;
    
    my $out = 0;

    my $file;
    
    {{
        if ( $fileName eq "" ) # no filename
        {
            printf "ItemFileRes::loadItemsFromCsv: no filename\n";
            last;
        }
        
        if ( !open( $file, "<:encoding(UTF-8)", $fileName ) ) # failed
        {
            printf "ItemFileRes::loadItemsFromCsv: open failed[%s]: %s\n", $fileName, $!;
            last;
        }
        
        my $csv = Text::CSV_XS->new( { binary => 1 } );

        my $data = $csv->getline_all( $file, 2 );
        
        if ( !defined( $data ) )
        {
            printf "ItemFileRes::loadItemsFromCsv: getline_all failed[%s]\n", $fileName;
            last;
        }
        
        my $plural;
        
        my $lineIdx = 2;
        
        for my $row ( @{ $data } )
        {
            my ( $id, $variant, $original, $translation ) = @$row;
            
            if ( defined( $translation ) && $translation eq "" )
            {
                undef $translation;
            }
            
            if ( defined( $variant ) && $variant eq "" )
            {
                undef $variant;
            }
            
            #printf "ItemFileRes::loadItemsFromCsv: id[%s] v[%s] t[%s]\n", $id, $variant, $translation;
            
            if ( $id ne "" ) # ID means new item
            {
                if ( defined( $plural ) )
                {
                    #printf "ItemFileRes::loadItemsFromCsv: to add plural: empty=%d\n", $plural->isEmpty();
                    
                    if ( !$plural->isEmpty() )
                    {
                        if ( $self->addItem( $plural ) )
                        {
                            $out++;
                        }
                    }
                    
                    undef $plural;
                }
                
                if ( defined( $translation ) ) # plain text
                {
                    my $item = ItemTextRes->new( $id, {
                        plural => 0,
                        } );
                        
                    my $text = ItemText->new( $translation );
                    
                    $item->setText( $text );

                    if ( $self->addItem( $item ) )
                    {
                        $out++;
                    }
                }
                else # guess plural
                {
                    #printf "ItemFileRes::loadItemsFromCsv: start plural[%s]\n", $id;
                    
                    $plural = ItemTextRes->new( $id, {
                        plural => 1,
                        } );
                }
            }
            else # no ID might be plural 
            {
                if ( defined( $plural ) ) # plural is in progress
                {
                    if ( defined( $variant ) ) # another variant for plural
                    {
                        if ( defined( $translation ) ) # has translation
                        {
                            #printf "ItemFileRes::loadItemsFromCsv: for plural[%s] add v[%s] t[%s]\n", $id, $variant, $translation;
                            
                            my $text = ItemText->new( $translation );
                            
                            $plural->setVariant( $variant, $text );
                        }
                        else # no translation
                        {
                            # skip it 
                        }
                    }
                    else # no variant
                    {
                        # neither ID nor variant - guess it's blank line
                        # skip it
                    }
                }
                else # no plural in progress
                {
                    # neiher ID nor plural -- strange a bit, but it might be blank line too
                    # skip it
                }
            }
            
            $lineIdx++;
        }

        # complete last plural
        if ( defined( $plural ) )
        {
            #printf "ItemFileRes::loadItemsFromCsv: to complete plural: empty=%d\n", $plural->isEmpty();
            
            if ( !$plural->isEmpty() )
            {
                if ( $self->addItem( $plural ) )
                {
                    $out++;
                }
            }
            
            undef $plural;
        }
    }}
    
    if ( defined( $file ) )
    {
        close( $file );
    }
    
    return $out;
}


1;
