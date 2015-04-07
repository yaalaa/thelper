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
# Android resource project
#
package ItemAndroidProjectRes;


use strict;
use parent qw(ItemProjectRes);
use CommonUtils;
use XML::Parser::Expat;
use AndroidStringResourceSaxHandler;
use ItemFileRes;
use ItemAndroidFileRes;
use Locale::Language;
use Locale::Country;


#
# Source string
#
our $SOURCE = "android";
#
# Resource root folder
#
my $RES_DIR_ROOT = "res";
#
# Resource sub-folder
#
my $RES_DIR_SUB = "values";
#
# Resource filename
#
my $RES_FILE_NAME = "strings.xml";
#
# Base resource filename
#
my $RES_BASE = $RES_DIR_ROOT."/".$RES_DIR_SUB."/".$RES_FILE_NAME;

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
        my $resDir = $self->{root}."/".$RES_DIR_ROOT;
        
        if ( ! -d $resDir )  # no root resource folder
        {
            last;
        }

        
        my @allLangCodes = all_language_codes();
        my @allCountryCodes = all_country_codes( LOCALE_CODE_ALPHA_2 );
        
        my $langSuffixRegex = "(?:".join( "|", @allLangCodes ).")(?:r(?:".join( "|", @allCountryCodes )."))?";

        
        my @subDirs;

        my $resDirH;

        if ( !opendir( $resDirH, $resDir ) )
        {
            printf "ItemAndroidProjectRes::_loadLangs: opendir[%s] failed [%s]\n", $resDir, $!;
            last;
        }

        @subDirs = grep( /^values-${langSuffixRegex}$/i ,readdir( $resDirH ) );

        closedir( $resDirH );

        my $langs = {};
        
        for my $curDir ( @subDirs )
        {
            my $curFile = $resDir."/".$curDir."/".$RES_FILE_NAME;
            
            if ( ! -f $curFile ) # no resource file
            {
                next;
            }
            
            $curDir =~ /^values-(.+)$/;
            
            $langs->{$1} = $RES_DIR_ROOT."/".$curDir."/".$RES_FILE_NAME;
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
    
    return ItemAndroidFileRes->new( $fileName, $self->{source}, $lang );
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
            #printf "ItemAndroidProjectRes::_loadRes: file not found [%s]\n", $resFileName;
            last;
        }
        
        my $resData = CommonUtils::getFileContent( $resFileName );
        
        if ( length( $resData ) <= 0 ) # no data
        {
            last;
        }
        
        my $res = $self->_createRes( $resFileName, $lang );
        
        $res->setFileData( $resData );
        
        my $handler = AndroidStringResourceSaxHandler->new;
        
        my $parser = XML::Parser::Expat->new;
        
        $handler->setRes( $res );
        $handler->setHandlers( $parser );
        
        $parser->parsestring( $resData );
        
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
    
    return $self->_loadRes( $RES_DIR_ROOT."/values-".$lang."/".$RES_FILE_NAME, $lang );
}


1;

