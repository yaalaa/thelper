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
# SAX handler for Android String resource 
#
package AndroidStringResourceSaxHandler;

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
        item => undef,
        comment => undef,
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
        'Comment'  => sub{ $self->_comment( @_ ) },
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
    
    #printf "AndroidStringResourceSaxHandler::_start_element: [%s] at %s\n", $el, $self->_getContext( $p );
    
    my %hattrs = @attrs;
    
    #printf "AndroidStringResourceSaxHandler::_start_element: [%s] attrs: %s\n\n%s\n", $el, Dumper( \%hattrs ), $p->recognized_string();
    
    if ( defined( $self->{comment} ) )
    {
        my $linesAfter = ( $self->{acc} =~ tr/\n/\n/ );

        #printf "AndroidStringResourceSaxHandler::_start_element: [%s] after comment[%s] nl=%d\n", $el, $self->{acc}, $linesAfter;
        
        $self->{comment}->setLinesAfter( $linesAfter );
    
        delete $self->{comment};
    }
    
    my $item = $self->{item};
    
    my $resetAcc = 1;
        
    if ( defined( $item ) ) # inside item
    {
        $resetAcc = 0;
    }
    
    if ( $el eq "string" ) # plain string
    {
        if ( !defined( $item ) ) # no item
        {
            $item = ItemTextRes->new( $hattrs{name}, {
                plural => 0,
                nontranslatable => ( $hattrs{translatable} eq "false" ? 1 : 0 ),
            } );
            
            $self->{item} = $item;
            
            $resetAcc = 1;
        }
        else
        {
            printf "AndroidStringResourceSaxHandler::_start_element: %s - inside item at %s\n", $el, $self->_getContext( $p );
        }
    } 
    elsif ( $el eq "plurals" ) # plural text
    {
        if ( !defined( $item ) ) # no item
        {
            $item = ItemTextRes->new( $hattrs{name}, {
                plural => 1,
                nontranslatable => ( $hattrs{translatable} eq "false" ? 1 : 0 ),
            } );
            
            $self->{item} = $item;
            
            $resetAcc = 1;
        }
        else
        {
            printf "AndroidStringResourceSaxHandler::_start_element: %s - inside item at %s\n", $el, $self->_getContext( $p );
        }
    }
    elsif ( $el eq "item" ) # item?
    {
        if ( !defined( $item ) )
        {
            printf "AndroidStringResourceSaxHandler::_start_element: item - no item\n";
        }
        elsif ( !$item->isPlural() )
        {
            printf "AndroidStringResourceSaxHandler::_start_element: item - not a plural\n";
        }
        
    
        if ( defined( $item ) && $item->isPlural() ) # it's for plural
        {
            my $q = $hattrs{quantity};
            
            if ( $q eq "" ) # no quantity 
            {
                printf "AndroidStringResourceSaxHandler::_start_element: %s - no quantity specified at %s\n", $el, $self->_getContext( $p );
            }

            $self->{q} = $q;
        
            $resetAcc = 1;
        }
        else # it's for nothing
        {
            printf "AndroidStringResourceSaxHandler::_start_element: %s for nothing at %s\n", $el, $self->_getContext( $p );
        }
    }
    elsif ( $el eq "xliff:g" )
    {
        # do not warn
    }
    else # unsupported tag
    {
        if ( defined( $item ) )
        {
            printf "AndroidStringResourceSaxHandler::_start_element: unsupported [%s] at %s\n", $el, $self->_getContext( $p );
        }
    }
    
    if ( $resetAcc ) 
    {
        $self->{acc} = "";
    }
}

sub _end_element 
{
    my ( $self, $p, $el ) = @_;
    
    #printf "AndroidStringResourceSaxHandler::_end_element: [%s] at %s\n", $el, $self->_getContext( $p );
    
    my $resetAcc = 1;
    my $resetQ = 1;
    my $resetItem = 1;
    
    my $item = $self->{item};
        
    if ( defined( $item ) ) # inside item
    {
        $resetAcc = 0;
        $resetQ = 0;
        $resetItem = 0;
    }
    
    if ( $el eq "string" ) # plain string
    {
        if ( defined $item )
        {
            my $s = $self->{acc};
            
            my $text = ItemText->new( $s );
            
            $item->setText( $text );
            
            if ( $s =~ /^\@(?:android:)?string\/.+$/ ) # looks like an alias
            {
                $item->setAlias( 1 );
            }
            
            $self->{res}->addItem( $item );
        
            $resetAcc = 1;
            $resetQ = 1;
            $resetItem = 1;
        }
    } 
    elsif ( $el eq "plurals" ) # plural text
    {
        if ( defined $item )
        {
            $self->{res}->addItem( $item );
        
            $resetAcc = 1;
            $resetQ = 1;
            $resetItem = 1;
        }
    }
    elsif ( $el eq "item" ) # item?
    {
        if ( defined( $item ) && $item->isPlural() ) # it's for plural
        {
            my $item = $self->{item};
            my $q = $self->{q};
            my $s = $self->{acc};
            
            my $text = ItemText->new( $s );
            
            $item->setVariant( $q, $text );
            
            $resetAcc = 1;
            $resetQ = 1;
            $resetItem = 0;
        }
    }
    
    if ( $resetAcc ) 
    {
        $self->{acc} = "";
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
    
    #printf "AndroidStringResourceSaxHandler::_characters: [%s]\n", $data;
    
    $self->{acc} .= $data;
}

sub _comment
{
    my ( $self, $p, $data ) = @_;

    #printf "AndroidStringResourceSaxHandler::_comment: [%s]\n", $data;
    
    my $linesBefore = ( $self->{acc} =~ tr/\n/\n/ );
    
    my $item = ItemCommentRes->new( $data, $linesBefore );
    
    $self->{res}->addItem( $item );
    
    $self->{comment} = $item;
    
    $self->{acc} = "";
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
