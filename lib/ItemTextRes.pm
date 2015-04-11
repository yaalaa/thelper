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
# Text resource
#
package ItemTextRes;


use strict;
use CommonUtils;
use ItemText;
use Scalar::Util qw(blessed reftype);
use Data::Dumper;


#
# Denotes plain text string resource
#
my $TYPE_PLAIN = "plain";
#
# Denotes plural text string resource
#
my $TYPE_PLURAL = "plural";
#
# Denotes ONE plural variant
#
my $PLURAL_ONE = "one";
#
# Denotes TWO plural variant
#
my $PLURAL_TWO = "two";
#
# Denotes FEW plural variant
#
my $PLURAL_FEW = "few";
#
# Denotes MANY plural variant
#
my $PLURAL_MANY = "many";
#
# Denotes OTHER plural variant
#
my $PLURAL_OTHER = "other";

#
# Plural variants
#
our $VARIANTS = [
    $PLURAL_ONE,
    $PLURAL_TWO,
    $PLURAL_FEW,
    $PLURAL_MANY,
    $PLURAL_OTHER,
];
#
# Maps plural variant to member name
#
my $_VARIANT_FIELDS = {
    $PLURAL_ONE => $PLURAL_ONE,
    $PLURAL_TWO => $PLURAL_TWO,
    $PLURAL_FEW => $PLURAL_FEW,
    $PLURAL_MANY => $PLURAL_MANY,
    $PLURAL_OTHER => $PLURAL_OTHER,
};

#
# Initializes object
# 
# @param type - resource type, @see TYPE_XXX constants
# @param id   - identifier
#
# @return initialized object
#
sub new
{
    my ( $class, $id, $options ) = @_;
    
    my $plural = 0;
    my $translatable = 1;
    my $alias = 0;
    
    if ( reftype $options == "HASH" )  # options are specified
    {
        if ( $options->{plural} )
        {
            $plural = 1;
        }
        
        if ( $options->{nontranslatable} )
        {
            $translatable = 0;
        }
        
        if ( $options->{alias} )
        {
            $alias = 1;
        }
    }

    my $self = bless 
    {
        id => $id,
        plural => $plural,
        translatable => $translatable,
        alias => $alias,
    }, $class;
    
    return $self;
}

#
# Retrieves copy of this object
#
# @return copy of this object
#
sub clone
{
    my $self = shift;
    
    my $out = ItemTextRes->new( $self->getId(), {
        plural => $self->isPlural(),
        } );
    
    if ( !$self->isEmpty() )
    {
        if ( !$self->isPlural() ) # plain
        {
            $out->setText( $self->getText()->clone() );
        }
        else # plural
        {
            for my $curVariant ( @{ $VARIANTS } )
            {
                my $field = $_VARIANT_FIELDS->{$curVariant};
                
                my $var = $self->getVariant( $curVariant );
                
                if ( defined( $var ) )
                {
                    $out->setVariant( $curVariant, $var->clone() );
                }
            }
        }
    }
    
    return $out;
}

#
# Retrieves ID
#
# @return ID
#
sub getId
{
    my $self = shift;

    return $self->{id};
}

#
# Checks whether it's plural resource
#
# @return 1, if it's plural resource
#
sub isPlural
{
    my $self = shift;

    return $self->{plural};
}

#
# Checks whether it's translatable resource
#
# @return 1, if it's translatable resource
#
sub isTranslatable
{
    my $self = shift;

    return $self->{translatable};
}

#
# Checks whether it's alias to another resource
#
# @return 1, if it's alias to another resource
#
sub isAlias
{
    my $self = shift;

    return $self->{alias};
}

#
# Sets/resets alias flag
#
# @param value - !0, to set alias flag
#
sub setAlias
{
    my ( $self, $value ) = @_;

    $self->{alias} = $value != 0 ? 1 : 0;
}

#
# Retrieves text.
# Works for plain resources.
#
# @return text as ItemText, if any
#
sub getText
{
    my $self = shift;

    return $self->{text};
}

#
# Sets text.
# Works for plain resources.
#
# @param text - text as ItemText
#
sub setText
{
    my ( $self, $text ) = @_;
    
    if ( ! defined( $text ) )
    {
        delete $self->{text};
    }
    elsif ( blessed $text && $text->isa( "ItemText" ) )
    {
        $self->{text} = $text;
    } 
    else # unsupported type
    {
        printf "ItemTextRes::setText: unsupported type:[%s]\n", blessed( $text );
    }
}

#
# Retrieves plural variant text.
# Works for plural resources.
#
# @param variant - plural variant, @see PLURAL_XXX constants
#
# @return text as ItemText, if any
#
sub getVariant
{
    my ( $self, $variant ) = @_;
    
    my $out;
    
    {{
        if ( !$self->isPlural() ) # not a plural
        {
            printf "ItemTextRes::getVariant: not a plural\n";
            last;
        }
        
        if ( !defined( $variant ) ) # no variant
        {
            printf "ItemTextRes::getVariant: no variant\n";
            last;
        }
        
        if ( ! exists $_VARIANT_FIELDS->{$variant} ) # unsupported variant
        {
            printf "ItemTextRes::getVariant: unsupported variant: [%s]\n", $variant;
            last;
        }
        
        my $field = $_VARIANT_FIELDS->{$variant};
        
        $out = $self->{$field};
    }}

    return $out;
}

#
# Sets plural variant text.
# Works for plural resources.
#
# @param variant - plural variant, @see PLURAL_XXX constants
# @param text    - text as ItemText
#
sub setVariant
{
    my ( $self, $variant, $text ) = @_;
    
    my $out;
    
    {{
        if ( !$self->isPlural() ) # not a plural
        {
            printf "ItemTextRes::setVariant: not a plural\n";
            last;
        }
        
        if ( !defined( $variant ) ) # no variant
        {
            printf "ItemTextRes::setVariant: no variant\n";
            last;
        }
        
        if ( ! exists $_VARIANT_FIELDS->{$variant} ) # unsupported variant
        {
            printf "ItemTextRes::setVariant: unsupported variant: [%s]\n", $variant;
            last;
        }
        
        my $field = $_VARIANT_FIELDS->{$variant};

        if ( !defined( $text ) )
        {
            delete $self->{$field};
            last;
        }

        if ( blessed $text && $text->isa( "ItemText" ) )
        {
            $self->{$field} = $text;
            last;
        }
        
        printf "ItemTextRes::setVariant: unsupported type:[%s]\n", blessed( $text );
  }}

    return $out;
}

#
# Checks whether it has no text
#
# @return !=0, if it has no text
#
sub isEmpty
{
    my $self = shift;
    
    my $out = 0;
    
    if ( !$self->isPlural() ) # plain text
    {
        if ( !defined( $self->getText() ) )
        {
            $out = 1;
        }
    }
    else # plural
    {
        $out = 1;
        
        for my $curVariant ( @{ $VARIANTS } )
        {
            my $field = $_VARIANT_FIELDS->{$curVariant};
            
            if ( defined( $self->{$field} ) )
            {
                $out = 0;
                last;
            }
        }
    }
    
    return $out;
}




1;