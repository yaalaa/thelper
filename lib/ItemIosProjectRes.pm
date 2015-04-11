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
# iOS resource project
#
package ItemIosProjectRes;


use strict;
use parent qw(ItemProjectRes);
use CommonUtils;
use ItemIosFileRes;


#
# Source string
#
our $SOURCE = "ios";
#
# Resource sub-folder suffix
#
my $RES_DIR_SUFFIX = ".lproj";
#
# Plain items for resource file suffix
#
our $RES_PLURAL_SUFFIX = "dict";
#
# Resource filename
#
my $RES_FILE_NAME = "Localizable.strings";
#
# Base resource languag
#
my $RES_BASE_LANG = "en";
#
# Base resource folder name
#
my $RES_DIR_BASE = $RES_BASE_LANG.$RES_DIR_SUFFIX;
#
# Base resource filename
#
my $RES_BASE = $RES_DIR_BASE."/".$RES_FILE_NAME;

#
# Initializes object
# 
# @param root - project root folder
#
# @return initialized object
#
sub new
{
    my ( $class, $root ) = @_;

    my $self = $class->SUPER::new( $root, $SOURCE );
    
    return bless $self, $class;
}

#
# Retrieves list of languages of existing translations
#
# @return list of languages of existing translations(hash: lang->filename)
#
sub _loadLangs
{
    my $self = shift;
    
    my $out;
    
    {{
        my $resDir = $self->{root};
        
        if ( ! -d $resDir )  # no root resource folder
        {
            last;
        }
        
        my @subDirs;

        my $resDirH;

        if ( !opendir( $resDirH, $resDir ) )
        {
            printf "ItemIosProjectRes::_loadLangs: opendir[%s] failed [%s]\n", $resDir, $!;
            last;
        }

        @subDirs = grep( /^[a-zA-Z_-]+\.lproj$/i ,readdir( $resDirH ) );

        closedir( $resDirH );

        my $langs = {};
        
        for my $curDir ( @subDirs )
        {
            my $curFile = $resDir."/".$curDir."/".$RES_FILE_NAME;
            
            if ( ! -f $curFile ) # no resource file
            {
                next;
            }
            
            $curDir =~ /^([a-zA-Z_-]+)\.lproj$/;
            
            if ( $1 ne $RES_BASE_LANG )
            {
                $langs->{$1} = $curDir."/".$RES_FILE_NAME;
            }
        }
        
        $out = $langs;
    }}
    
    return $out;
}

#
# Creates resource file object
#
# @param fileName - filename relative to project root folder
# @param lang     - language
#
# @return resource file as ItemFileRes, if succeeded
#
sub _createRes
{
    my ( $self, $fileName, $lang ) = @_;
    
    return ItemIosFileRes->new( $fileName, $self->{source}, $lang );
}

#
# Loads resource file
#
# @param fileName - filename relative to project root folder
# @param lang     - language
#
# @return resource file as ItemFileRes, if succeeded
#
sub _loadRes
{
    my ( $self, $fileName, $lang ) = @_;
    
    my $out;
    
    {{
        my $resFileName = $self->{root}."/".$fileName;
        
        if ( ! -f $resFileName )  # no resource file
        {
            #printf "ItemIosProjectRes::_loadRes: file not found [%s]\n", $resFileName;
            last;
        }
        
        my $res = $self->_createRes( $resFileName, $lang );
        
        if ( !$res->load( $resFileName ) ) # failed
        {
            printf "ItemIosProjectRes::_loadRes: load failed on [%s]\n", $resFileName;
            last;
        }
        
        $res->loadPlurals( $resFileName.$RES_PLURAL_SUFFIX );
        
        $out = $res;
    }}
    
    return $out;
}

#
# Loads base resource file
#
# @return resource file as ItemFileRes, if succeeded
#
sub _loadResBase
{
    my $self = shift;
    
    return $self->_loadRes( $RES_BASE, "" );
}

#
# Retrieves resource file for specified language
#
# @param lang - language
#
# @return resource file as ItemFileRes, if succeeded
#
sub _loadResForLang
{
    my ( $self, $lang ) = @_;
    
    return $self->_loadRes( $lang.$RES_DIR_SUFFIX."/".$RES_FILE_NAME, $lang );
}

#
# Retrieves item merged from the base and translated
#
# @param base       - base item
# @param translated - translated item
#
# @return merged item
sub _mergeItem
{
    my ( $self, $base, $translated ) = @_;
    
    my $out = $self->SUPER::_mergeItem( $base, $translated );
    
    if ( defined( $out ) && defined( $base ) )
    {
        $out->{iosvar} = $base->{iosvar};
        $out->{iosvarspec} = $base->{iosvarspec};
    }
    
    return $out;
}


1;

