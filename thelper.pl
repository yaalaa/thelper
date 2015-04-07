#!/usr/bin/perl

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
# Manages translations, source and exported
#

BEGIN
{
    use File::stat;
    use File::Spec::Functions qw(rel2abs);
    use File::Basename;

    my $myDir = dirname( rel2abs( __FILE__ ) );

    push( @INC, $myDir."/lib" );
}


use strict;
use Getopt::Long;
use CommonUtils;
use ItemAndroidProjectRes;
use ItemIosProjectRes;
use ItemFileRes;

$|=1;

# hello message
printf "%s Hi there, I'm %s\n", CommonUtils::GetTimeStr(), $0;

my $usage = <<EOT;
Helps in exporting/importing translations

Usage:
  <me> command [option ..]
  
  Commands:
    n|print-not-translated   - prints not translated items for specified language
    a|apply-new-translations - merges new translations for specified language
    i|summary-report         - prints summary report
  
  Options:
    --help                  - this help screen
    --android <path>        - specifies Android project root folder
    --ios <path>            - specifies iOS project root folder
    --out-csv <path>        - specifies output CSV file
    --out-xml <path>        - output XML file (for Android project)
    --out-strings <path>    - output strings file (for iOS project)
    --in-csv <path>         - specifies input CSV file
    --lang <lang>           - langauge to operate for

EOT

if ( scalar( @ARGV ) <= 0 ) # no arguments
{
    printf $usage;
    exit( 0 );
}

my $cmd = shift( @ARGV );

my $needLang = 0;

my $cmdPrintNotTranslated = 0;
my $cmdApplyNewTranslations = 0;
my $cmdReportSummary = 0;

if ( ( $cmd eq "n" ) || ( $cmd eq "print-not-translated" ) )
{
    $cmdPrintNotTranslated = 1;
    $needLang = 1;
}
elsif ( ( $cmd eq "a" ) || ( $cmd eq "apply-new-translations" ) )
{
    $cmdApplyNewTranslations = 1;
    $needLang = 1;
}
elsif ( ( $cmd eq "i" ) || ( $cmd eq "summary-report" ) )
{
    $cmdReportSummary = 1;
}
elsif ( ( $cmd eq "help" ) || ( $cmd eq "--help" ) || ( $cmd eq "-h" ) || ( $cmd eq "-?" ) )
{
    printf $usage;
    exit( 0 );
}
else # not a command
{
    printf "Not a command: %s\n\n", $cmd;
    printf $usage;
    exit( 0 );
}

my $optResult = GetOptions( 
    "help"          => \my $printHelp,
    "android=s"     => \my $optAndroid,
    "ios=s"         => \my $optIos,
    "out-csv=s"     => \my $optOutCsv,
    "out-xml=s"     => \my $optOutXml,
    "out-strings=s" => \my $optOutStrings,
    "in-csv=s"      => \my $optInCsv,
    "lang=s"        => \my $optLang,
    );

if ( !$optResult || $printHelp )
{
    printf $usage;
    exit( 0 );
}

if ( !defined( $optAndroid ) && !defined( $optIos ) ) # no project
{
    printf "Please, specify project.\nTry --help\n";
    exit( 0 );
}

if ( $needLang && 
    !$optLang ) # no language
{
    printf "Please, specify language.\nTry --help\n";
    exit( 0 );
}

# execute commands
if ( $cmdPrintNotTranslated ) # to print not translated items
{
    if ( !defined( $optOutCsv ) || $optOutCsv eq "" ) # no output
    {
        printf "Please, specify CSV output filename.\nTry --help\n";
        exit( 0 );
    }

    if ( defined( $optOutCsv ) ) # check for future
    {
        unlink( $optOutCsv );
    }
    
    my $prj;
    
    if ( defined( $optAndroid ) ) # android
    {
        $prj = ItemAndroidProjectRes->new( $optAndroid );
    }
    elsif ( defined( $optIos ) ) # ios
    {
        $prj = ItemIosProjectRes->new( $optIos );
    }
    else # no project
    {
        printf "Please, specify project.\nTry --help\n";
        exit( 0 );
    }

    if ( !$prj->saveNotTraslatedToCsv( $optLang, $optOutCsv ) ) # failed
    {
        printf "saveNotTraslatedToCsv failed\n";
    }
    
}
elsif ( $cmdApplyNewTranslations ) # to apply new translations
{
    if ( !defined( $optInCsv ) || $optInCsv eq "" ) # no input
    {
        printf "Please, specify CSV input filename.\nTry --help\n";
        exit( 0 );
    }

    my $prj;
    
    if ( defined( $optAndroid ) ) # android
    {
        $prj = ItemAndroidProjectRes->new( $optAndroid );

        if ( !defined( $optOutXml ) || $optOutXml eq "" ) # no output
        {
            printf "Please, specify XML output filename.\nTry --help\n";
            exit( 0 );
        }

        if ( defined( $optOutXml ) ) # check for future
        {
            unlink( $optOutXml );
        }
    }
    elsif ( defined( $optIos ) ) # ios
    {
        $prj = ItemIosProjectRes->new( $optIos );

        if ( !defined( $optOutStrings ) || $optOutStrings eq "" ) # no output
        {
            printf "Please, specify strings output filename.\nTry --help\n";
            exit( 0 );
        }

        if ( defined( $optOutStrings ) ) # check for future
        {
            unlink( $optOutStrings );
        }
    }
    else # no project
    {
        printf "Please, specify project.\nTry --help\n";
        exit( 0 );
    }

    
    my $news = ItemFileRes->new( "", "", $optLang );
    
    my $newsCount = $news->loadItemsFromCsv( $optInCsv );
    
    if ( $newsCount <= 0 ) # no news
    {
        printf "No new item is found.\n";
        exit( 0 );
    }

    #printf "%d new item is found.\n", $newsCount;
    
    my $merge = $prj->mergeTranslation( $optLang, $news );
    
    if ( !defined( $merge ) ) # failed on no news
    {
        exit( 0 );
    }

    if ( $prj->getSource() eq $ItemAndroidProjectRes::SOURCE ) # android
    {
        if ( !$merge->saveToXml( $optOutXml ) ) # failed
        {
            #printf "saveToXml failed\n";
            exit( 0 );
        }
    }
    elsif ( $prj->getSource() eq $ItemIosProjectRes::SOURCE ) # iOS
    {
        if ( !$merge->save( $optOutStrings ) ) # failed
        {
            #printf "save failed\n";
            exit( 0 );
        }
    }
    else
    {
        # do nothing for now
    }
}
elsif ( $cmdReportSummary ) # summary report
{
    my $prj;
    
    if ( defined( $optAndroid ) ) # android
    {
        $prj = ItemAndroidProjectRes->new( $optAndroid );
    }
    elsif ( defined( $optIos ) ) # ios
    {
        $prj = ItemIosProjectRes->new( $optIos );
    }
    else # no project
    {
        printf "Please, specify project.\nTry --help\n";
        exit( 0 );
    }
    
    if ( !$prj->reportSummary() ) # failed
    {
        exit( 0 );
    }
}


printf "%s .Done.\n", CommonUtils::GetTimeStr();

exit( 0 );

#-----------------------------------------------------------------------------------------------------------


