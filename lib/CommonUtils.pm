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
# Common utilities
#
package CommonUtils;

use strict;
use File::stat;


sub TrimStr
{
  my $str = shift( @_ );
  
  $str =~ s/^\s+([^\s].*)$/$1/g;
  $str =~ s/^(.*[^\s])\s+$/$1/g;
  
  return $str;
}

sub ToStraightSlash
{
  my $src = shift( @_ );
  
  $src =~ s/\\/\//g;
  
  return $src;
}

sub ToBackSlash
{
  my $src = shift( @_ );
  
  $src =~ s/\//\\/g;
  
  return $src;
}

sub GetTimeStr
{
  my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime( time );

  return sprintf( "%04d.%02d.%02d %02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );
}

sub getFileContent
{
    my $out;
    
    my $srcFile;

    {{
        my $srcFileName = shift( @_ );
        
        if ( $srcFileName eq "" ) # no source filename
        {
            printf "%s CommonUtils::getFileContent: no source filename \n", CommonUtils::GetTimeStr();
            last;
        }
        
        if ( !open( $srcFile, "<$srcFileName" ) ) # failed
        {
            printf "%s CommonUtils::getFileContent: open[%s] failed: %s \n", CommonUtils::GetTimeStr(), $srcFileName, $!;
            last;
        }

        binmode( $srcFile );

        my $srcStat = stat( $srcFile );

        my $srcDataLen = $srcStat->size;

        if ( $srcDataLen <= 0 ) # no data 
        {
            last;
        }
        
        my $srcData;
        
        if ( !read( $srcFile, $srcData, $srcDataLen ) ) # failed
        {
            printf "%s CommonUtils::getFileContent: read[%s] failed: %s \n", CommonUtils::GetTimeStr(), $srcFileName, $!;
            last;
        }

        if ( length( $srcData ) != $srcDataLen ) # sizes mismatch
        {
            printf "%s CommonUtils::getFileContent: input file read error (need %d, read %d) [%s]\n", CommonUtils::GetTimeStr(), $srcDataLen, length( $srcData ), $srcFileName;
            last;
        }

        $out = $srcData;
    }}
    
    if ( defined( $srcFile ) ) 
    {
        close( $srcFile );
    }
    
    return $out;
}



1;
