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
# SAX handler for iOS String resource 
#
package IosStringResourceSaxHandler;

use strict;
use CommonUtils;
use ItemTextRes;
use ItemText;
use Data::Dumper;
use ItemCommentRes;


sub new
{
    my $class = shift;

    my $self = bless 
    {
        res => undef,
        acc => "",
        q => "",
        key => "",
        item => undef,
    }, $class;

    return $self;
}

#
# Binds handlers to parser
#
# @param parser - parser
#
sub setHandlers
{
    my ( $self, $parser ) = @_;
    
    $parser->setHandlers( 
        'Start' => sub{ $self->_start_element( @_ ) },
        'End'   => sub{ $self->_end_element( @_ ) },
        'Char'  => sub{ $self->_characters( @_ ) },
        );
}

#
# Set resource file
#
# @param res - resource file as ItemFileRes
#
sub setRes
{
    my ( $self, $res ) = @_;
    
    $self->{res} = $res;
}

sub _start_element 
{
    my ( $self, $p, $el, @attrs ) = @_;
    
    #printf "IosStringResourceSaxHandler::_start_element: [%s] deep=%d\n", $el, $p->depth();
    
    my $resetKey = 0;
    
    if ( $el eq "plist" ) # plist
    {
        # do nothing
    }
    elsif ( $el eq "key" ) # key
    {
        $self->{key} = "";
    }
    elsif ( $el eq "string" ) # string
    {
        # do nothing
    } 
    elsif ( $el eq "dict" ) # dict
    {
        my $deep = $p->depth();
        
        if ( $deep == 2 ) 
        {
            my $item = ItemTextRes->new( $self->{key}, {
                plural => 1,
            } );
            
            $self->{item} = $item;
            
            $resetKey = 1;
        }
    } 
    else # unsupported tag
    {
        printf "IosStringResourceSaxHandler::_start_element: unsupported [%s] at %s\n", $el, $self->_getContext( $p );
    }
    
    $self->{acc} = "";
    
    if ( $resetKey ) 
    {
        $self->{key} = "";
    }
}

sub _end_element 
{
    my ( $self, $p, $el ) = @_;
    
    #printf "IosStringResourceSaxHandler::_end_element: [%s] deep=%d\n", $el, $p->depth();
    
    my $resetKey = 1;
    my $resetQ = 1;
    my $resetItem = 0;
    
    my $item = $self->{item};
    my $key = $self->{key};
    
    if ( $el eq "plist" ) # plist
    {
        # do nothings
    }
    elsif ( $el eq "key" ) # key
    {
        $self->{key} = $self->{acc};
        $resetKey = 0;
    }
    elsif ( $el eq "string" ) # string
    {
        if ( defined( $item ) )
        {
            my $s = $self->{acc};
            
            my $deep = $p->depth();
            
            if ( $deep == 3 ) 
            {
                if ( $key eq "NSStringLocalizedFormatKey" )
                {
                    if ( $s =~ /%#\@([^\@]+)\@/ )
                    {
                        $item->{iosvar} = $1;
                    }
                }
            }
            elsif ( $deep == 4 )
            {
                if ( $key eq "NSStringFormatSpecTypeKey" )
                {
                    # do nothing
                }
                elsif ( $key eq "NSStringFormatValueTypeKey" )
                {
                    $item->{iosvarspec} = $s;
                }
                else
                {
                    my $text = ItemText->new( $s );
                    
                    $item->setVariant( $key, $text );
                }
            }
        }
    } 
    elsif ( $el eq "dict" ) # dict
    {
        my $deep = $p->depth();
        
        if ( $deep == 2 ) # item completed
        {
            $resetItem = 1;
            
            if ( defined( $item ) && !$item->isEmpty() ) 
            {
                $self->{res}->addItem( $item );
            }
        }
        elsif ( $deep == 3 ) # item's variable completed
        {
            # do nothing
        }
    }
    
    $self->{acc} = "";
    
    if ( $resetKey ) 
    {
        $self->{key} = "";
    }
    
    if ( $resetQ ) 
    {
        $self->{q} = "";
    }
    
    if ( $resetItem )
    {
        delete $self->{item};
    }
}

sub _characters
{
    my ( $self, $p, $data ) = @_;
    
    #printf "IosStringResourceSaxHandler::_characters: [%s]\n", $data;
    
    $self->{acc} .= $data;
}

#
# Retrieves context string
#
# @param parser - parser
#
# @return context string
#
sub _getContext
{
    my ( $self, $p ) = @_;
    
    return $self->{res}->getFileName()." line ".$p->current_line();
}

1;
