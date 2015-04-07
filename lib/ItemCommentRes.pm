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
# Comment resource
#
package ItemCommentRes;


use strict;
use parent qw(ItemText);
use CommonUtils;


#
# Initializes object
# 
# @param s           - text string
# @param linesBefore - number of empty lines before comment
#
# @return initialized object
#
sub new
{
    my ( $class, $s, $linesBefore ) = @_;
    
    my $self = bless $class->SUPER::new( $s ), $class;

    $self->{linesBefore} = $linesBefore + 0;
    $self->{linesAfter} = 0;
    
    return $self;
}

#
# Retrieves number of empty lines before comment
# 
# @return number of empty lines before comment
#
sub getLinesBefore
{
    my $self = shift;
    
    return $self->{linesBefore};
}

#
# Retrieves number of empty lines after comment
# 
# @return number of empty lines after comment
#
sub getLinesAfter
{
    my $self = shift;
    
    return $self->{linesAfter};
}

#
# Retrieves number of empty lines after comment
# 
# @return number of empty lines after comment
#
sub setLinesAfter
{
    my ( $self, $linesAfter ) = @_;
    
    $self->{linesAfter} = $linesAfter + 0;
}


1;
