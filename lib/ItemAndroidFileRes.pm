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
# Android resource file
#
package ItemAndroidFileRes;


use strict;
use parent qw(ItemFileRes);
use CommonUtils;
use Scalar::Util qw(reftype blessed);
use XML::Writer;
use IO::File;

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
    
    my $self = bless $class->SUPER::new( $fileName, $source, $lang ), $class;
    
    $self->{namespaces} = {};

    return $self;
}

#
# Saves to XML file
#
# @param fileName - filename to write to
#
# @return !=0, if succeeded
#
sub saveToXml
{
    my ( $self, $fileName, $options ) = @_;
    
    my $out = 0;
    
    my $file;
    
    {{
        my $optNotTranslatable = 0;
        my $optAlias = 0;
        
        if ( reftype $options eq "HASH" )
        {
            if ( $options->{NOTTRANSLATABLE} )
            {
                $optNotTranslatable = 1;
            }
            
            if ( $options->{ALIAS} )
            {
                $optAlias = 1;
            }
        }
    
        if ( $fileName eq "" ) # no filename
        {
            printf "ItemAndroidFileRes::saveToXml: no filename specified\n";
            last;
        }
        
        if ( !open( $file, ">:raw:encoding(UTF-8)", $fileName ) ) # failed
        {
            printf "ItemAndroidFileRes::saveToXml: open failed[%s]: %s\n", $fileName, $!;
            last;
        }
        
        my $writer = XML::Writer->new( 
            #OUTPUT => "self",
            OUTPUT => $file,
            ENCODING => "utf-8",
            CHECK_PRINT => 1,
            );
        
        my $indent = " "x4;
        my $newline = "\n";
        
        $writer->xmlDecl();
        $writer->startTag( "resources" );
        $writer->characters( $newline );
        
        for my $curItem ( @{ $self->{itemsExt} } )
        {
            if ( $curItem->isa( "ItemTextRes" ) ) # text resource
            {
                if ( !$curItem->isTranslatable() && !$optNotTranslatable )
                {
                    next;
                }
                
                if ( $curItem->isAlias() && !$optAlias )
                {
                    next;
                }
                
                $writer->characters( $newline.$indent );
                
                if ( !$curItem->isPlural() ) # plain text
                {
                    my @attrs;
                    
                    push( @attrs, "name", $curItem->getId() );
                    
                    if ( !$curItem->isTranslatable() )
                    {
                        push( @attrs, "translatable", "false" );
                    }
                    
                    $writer->startTag( "string",  
                        @attrs,
                        );
                        
                    $writer->characters( $curItem->getText()->getData() );
                    
                    $writer->endTag( "string" );
                }
                else # plural text
                {
                    my @attrs;
                    
                    push( @attrs, "name", $curItem->getId() );
                    
                    if ( !$curItem->isTranslatable() )
                    {
                        push( @attrs, "translatable", "false" );
                    }
                    
                    $writer->startTag( "plurals",  
                        @attrs,
                        );
                        
                    for my $curVariant ( @$ItemTextRes::VARIANTS ) 
                    {
                        my $text = $curItem->getVariant( $curVariant );
                        
                        if ( defined( $text ) )
                        {
                            $writer->characters( $newline. ( $indent x 2 ) );

                            $writer->startTag( "item",  
                                "quantity" => $curVariant,
                                );
                         
                            $writer->characters( $text->getData() );
                            
                            $writer->endTag( "item" );
                        }
                    }
                        
                    $writer->characters( $newline.$indent );
                    $writer->endTag( "plurals" );
                }
            }
            else # comment
            {
                $writer->characters( ( $newline x $curItem->getLinesBefore() ).$indent );
                $writer->comment( CommonUtils::TrimStr( $curItem->getData() ) );
                
                my $linesAfter = $curItem->getLinesAfter();
                
                if ( $linesAfter > 1 )
                {
                    $writer->characters( $newline x ( $linesAfter - 1 ) );
                }
            }
        }
        
        $writer->characters( $newline x 2 );
        $writer->endTag( "resources" );
        $writer->end();
        
        $out = 1;
    }}
    
    if ( defined( $file ) )
    {
        close( $file );
    }
    
    return $out;
}


1;
