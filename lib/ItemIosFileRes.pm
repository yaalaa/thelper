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
# iOS resource file
#
package ItemIosFileRes;


use strict;
use parent qw(ItemFileRes);
use CommonUtils;
use Scalar::Util qw(reftype blessed);
use ItemText;
use ItemCommentRes;


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

    return $self;
}

#
# Loads items from the file
#
# @param fileName - filename
#
# @return !=0, if succeeded
#
sub load
{
    my ( $self, $fileName ) = @_;
    
    my $out = 0;
    
    my $file;
    
    {{
        if ( !defined( $fileName ) || $fileName eq "" ) # no filename
        {
            printf "ItemIosFileRes::load: no filename specified\n";
            last;
        }
        
        if ( ! -f $fileName ) # not found
        {
            printf "ItemIosFileRes::load: file is not found[%s]\n", $fileName;
            last;
        }
        
        if ( !open( $file, "<:raw:encoding(UTF-16LE)", $fileName ) ) # failed
        {
            printf "ItemIosFileRes::load: open[%s] failed: %s\n", $fileName, $!;
            last;
        }
        
        my $comment = "";
        
        my $ok = 1;
        
        while ( <$file> )
        {
            my $s = $_;
            
            # cleanup eol
            $s =~ s/\n\r?$/\n/;

            #printf "ItemIosFileRes::load: s[%s]\n", $s;
            
            if ( $s =~ /^\s*"([a-zA-Z_\.-]+)"\s*=\s*"(.+)"\s*;\s*\n?$/ ) # ID
            {
                my $id = $1;
                my $val = $2;

                $val =~ s/\\"/"/g;
                $val =~ s/\\\\/\\/g;
                
                #printf "ItemIosFileRes::load: id[%s] v[%s]\n", $id, $val;
                
                if ( $comment ne "" )
                {
                    #printf "ItemIosFileRes::load: comment[%s]\n", $comment;
                    
                    my $item = ItemCommentRes->new( $comment, 0 );
                    
                    if ( !$self->addItem( $item ) ) # failed
                    {
                        printf "ItemIosFileRes::load: addItem(comment) failed\n";
                        last;
                    }
                    
                    $comment = "";
                }

                my $item = ItemTextRes->new( $id );
                    
                my $text = ItemText->new( $val );
                
                $item->setText( $text );
                
                if ( !$self->addItem( $item ) ) # failed
                {
                    printf "ItemIosFileRes::load: addItem(text) failed\n";
                    $ok = 0;
                    last;
                }
            }
            else
            {
                $comment .= $s;
            }
        }
        
        if ( !$ok ) # failed
        {
            last;
        }
        
        if ( $comment ne "" )
        {
            #printf "ItemIosFileRes::load: comment.last[%s]\n", $comment;
            
            my $item = ItemCommentRes->new( $comment, 0 );
            
            if ( !$self->addItem( $item ) ) # failed
            {
                printf "ItemIosFileRes::load: addItem(comment.last) failed\n";
                last;
            }
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
# Saves to file
#
# @param fileName - filename to write to
#
# @return !=0, if succeeded
#
sub save
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
            printf "ItemIosFileRes::save: no filename specified\n";
            last;
        }
        
        if ( !open( $file, ">:raw:encoding(UTF-16LE)", $fileName ) ) # failed
        {
            printf "ItemIosFileRes::save: open failed[%s]: %s\n", $fileName, $!;
            last;
        }
        
        my $newline = "\n";
        
        my $ok = 1;
        
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
                
                if ( !$curItem->isPlural() ) # plain text
                {
                    my $id = $curItem->getId();
                    my $text = $curItem->getText()->getData();
                    
                    $text =~ s/\\/\\\\/g;
                    $text =~ s/"/\\"/g;
                    
                    $ok = printf $file "\"%s\" = \"%s\";".$newline, $id, $text;
                    
                    if ( !$ok ) # failed
                    {
                        printf "ItemIosFileRes::save: printf failed\n";
                        last;
                    }
                }
                else # plural text
                {
                    # TODO support
                }
            }
            else # comment
            {
                $ok = print $file $curItem->getData();
                    
                if ( !$ok ) # failed
                {
                    printf "ItemIosFileRes::save: print(comment) failed\n";
                    last;
                }
            }
        }
        
        if ( !$ok ) # failed
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


1;
