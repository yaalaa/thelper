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
# Resource project
#
package ItemProjectRes;


use strict;
use CommonUtils;
use Scalar::Util qw(blessed);
use Data::Dumper;


#
# Initializes object
# 
# @param root   - project root folder
# @param source - type of source of the project (android, etc.)
#
# @return initialized object
#
sub new
{
    my ( $class, $root, $source ) = @_;

    my $self = bless 
    {
        root => $root,
        source => $source,
        langs => undef,
        baseFile => undef,
        files => {},
    }, $class;
    
    return $self;
}

#
# Retrieves project root folder
#
# @return project root folder
#
sub getRoot
{
    my $self = shift;

    return $self->{root};
}

#
# Retrieves project source type
#
# @return project source type
#
sub getSource
{
    my $self = shift;

    return $self->{source};
}

#
# Checks whether it has translation to specified language
#
# @param lang - language
#
# @return !=0, if it has translation to specified language
#
sub hasTranslation
{
    my ( $self, $lang ) = @_;
    
    my $out = 0;
    
    {{
        my $langs = $self->getLangs();
        
        $out = exists $langs->{$lang} ? 1 : 0;
    }}

    return $out;
}

#
# Retrieves list of languages of existing translations
#
# @return list of languages of existing translations(hash: lang->filename)
#
sub getLangs
{
    my ( $self, $lang ) = @_;
    
    my $out;
    
    {{
        my $langs = $self->{langs};
        
        if ( !defined( $langs ) ) # not loaded yet
        {
            if ( ! defined $self->can( "_loadLangs" ) ) #  method is not supported
            {
                printf "ItemProjectRes::getLangs: no _loadLangs provided in [%s]\n", blessed( $self );
                last;
            }
        
            $langs = $self->_loadLangs();
            
            $self->{langs} = $langs;
        }
        
        $out = $langs;
    }}

    return $out;
}

#
# Retrieves base resource file
#
# @return resource file as ItemFileRes, if succeeded
#
sub getResBase
{
    my $self = shift;
    
    my $out;
    
    {{
        $out = $self->{baseFile};
        
        if ( !defined( $out ) ) # not loaded yet
        {
            if ( ! defined $self->can( "_loadResBase" ) ) #  method is not supported
            {
                printf "ItemProjectRes::getResBase: no _loadResBase provided in [%s]\n", blessed( $self );
                last;
            }
        
            $out = $self->_loadResBase();
            
            $self->{baseFile} = $out;
        }
    }}

    return $out;
}

#
# Retrieves resource file for specified language
#
# @param lang - language
#
# @return resource file as ItemFileRes, if succeeded
#
sub getResForLang
{
    my ( $self, $lang ) = @_;
    
    my $out;
    
    {{
        if ( $lang eq "" ) # no langauge
        {
            last;
        }
        
        if ( exists $self->{files}->{$lang} ) # loaded
        {
            $out = $self->{files}->{$lang};
            last;
        }
        
        my $langs = $self->getLangs();
    
        if ( !defined( $langs ) )  # no translation at all
        {
            last;
        }
        
        if ( ! exists $langs->{$lang} ) # no translation found
        {
            last;
        }

        # found 
        # will try to load
        
        if ( ! defined $self->can( "_loadResForLang" ) ) #  method is not supported
        {
            printf "ItemProjectRes::getResForLang: no _loadResForLang provided in [%s]\n", blessed( $self );
            last;
        }
        
        $out = $self->_loadResForLang( $lang );
        
        if ( !defined( $out ) ) # not loaded
        {
            last;
        }
        
        $self->{files}->{$lang} = $out;
    }}

    return $out;
}

#
# Saves not translated items to CSV file
#
# @param lang     - language to check
# @param fileName - output CSV file name
#
# @return !=0, if succeeded
#
sub saveNotTraslatedToCsv
{
    my ( $self, $lang, $fileName ) = @_;
    
    my $out = 0;

    my $file;
    
    {{
        if ( !defined( $lang ) || $lang eq "" ) # no language
        {
            printf "ItemProjectRes::saveNotTraslatedToCsv: no language specified\n";
            last;
        }
    
        if ( $fileName eq "" ) # no filename
        {
            printf "ItemProjectRes::saveNotTraslatedToCsv: no filename specified\n";
            last;
        }
        
        my $resBase = $self->getResBase();
        
        if ( !defined( $resBase ) ) # no base resource
        {
            printf "ItemProjectRes::saveNotTraslatedToCsv: no base resource\n";
            last;
        }
        
        my $resLang = $self->getResForLang( $lang );
        
        my $items = $resBase->getItems();
        
        my $csv;
        
        my $ok = 1;
        
        my $notTranslatedCnt = 0;
        
        for my $curItem ( @$items )
        {
            if ( !$curItem->isTranslatable() || $curItem->isAlias() ) # item is not tranlatable or it's alias to another resource
            {
                next;
            }
            
            my $id = $curItem->getId();
            
            my $found;
            
            if ( defined( $resLang ) ) # has translation file
            {
                $found = $curItem->isPlural() ? $resLang->getItemPluralById( $id ) : $resLang->getItemPlainById( $id );
            }
            
            if ( defined( $found ) )  # found translation
            {
                next;
            }
            
            if ( !defined( $file ) ) # not opened yet
            {
                if ( !open( $file, ">:raw:encoding(UTF-8)", $fileName ) ) # failed
                {
                    printf "ItemProjectRes::saveNotTraslatedToCsv: open failed[%s]: %s\n", $fileName, $!;
                    $ok = 0;
                    last;
                }
                
                $csv = Text::CSV_XS->new( { binary => 1, eol => $/ } );

                if ( !$csv->print( $file, [ "ID", "Modifier", "Original", "Translation" ] ) ) # failed
                {
                    printf "ItemProjectRes::saveNotTraslatedToCsv: csv::print failed: %s\n", $csv->status();
                    $ok = 0;
                    last;
                }

                if ( !$csv->print( $file, [ "", "", "", "" ] ) ) # failed
                {
                    printf "ItemProjectRes::saveNotTraslatedToCsv: csv::print failed: %s\n", $csv->status();
                    $ok = 0;
                    last;
                }
            }
            
            if ( !$curItem->isPlural() )
            {
                if ( !$csv->print( $file, [ $id, "", $curItem->getText()->getData(), "" ] ) ) # failed
                {
                    printf "ItemFileRes::saveItemsToCsv: csv::printf failed: %s\n", $csv->status();
                    $ok = 0;
                    last;
                }
            } 
            else 
            {
                if ( !$csv->print( $file, [ $id, "", "", "" ] ) ) # failed
                {
                    printf "ItemFileRes::saveItemsToCsv: csv::printf failed: %s\n", $csv->status();
                    $ok = 0;
                    last;
                }

                for my $curVariant ( @$ItemTextRes::VARIANTS ) 
                {
                    my $text = $curItem->getVariant( $curVariant );
                    
                    my $s = defined( $text ) ? $text->getData() : "";
                    
                    if ( !$csv->print( $file, [ "", $curVariant, $s, "" ] ) ) # failed
                    {
                        printf "ItemFileRes::saveItemsToCsv: csv::printf failed: %s\n", $csv->status();
                        $ok = 0;
                        last;
                    }
                }
                
                if ( !$ok ) # failed
                {
                    last;
                }
            }
            
            $notTranslatedCnt++;
        }
        
        if ( !$ok )
        {
            last;
        }
        
        if ( $notTranslatedCnt > 0 )
        {
            printf "ItemFileRes::saveItemsToCsv: %d items to translate to[%s]\n", $notTranslatedCnt, $lang;
        } 
        else
        {
            printf "ItemFileRes::saveItemsToCsv: [%s] is translated completely\n", $lang;
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
# Retrieves item merged from the base and translated
#
# @param base       - base item
# @param translated - translated item
#
# @return merged item
sub _mergeItem
{
    my ( $self, $base, $translated ) = @_;
    
    my $out;
    
    if ( defined( $translated ) )
    {
        $out = $translated->clone();
    }
    
    return $out;
}

#
# Merges existing and new translations
#
# @param lang - language
# @param news - new translations as ItemFileRes
# 
# @return merged in ItemFileRes, if succeeded
#
sub mergeTranslation
{
    my ( $self, $lang, $news ) = @_;
    
    my $out;
    
    {{
        if ( !defined( $lang ) || $lang eq "" ) # no language
        {
            printf "ItemProjectRes::mergeTranslation: no language specified\n";
            last;
        }
    
        if ( !defined( $news ) ) # no news
        {
            printf "ItemProjectRes::mergeTranslation: no news specified\n";
            last;
        }
        
        if ( !( blessed( $news ) && $news->isa( "ItemFileRes" ) ) ) # not an instance of ItemFileRes
        {
            printf "ItemProjectRes::mergeTranslation: no news is of unsupported type:[%s]\n", blessed( $news );
            last;
        }
        
        my $resBase = $self->getResBase();
        
        if ( !defined( $resBase ) ) # no base resource
        {
            printf "ItemProjectRes::mergeTranslation: no base resource\n";
            last;
        }
        
        my $resLang = $self->getResForLang( $lang );

        if ( ! defined $self->can( "_createRes" ) ) #  method is not supported
        {
            printf "ItemProjectRes::mergeTranslation: no _createRes provided in [%s]\n", blessed( $self );
            last;
        }
        
        my $merge = $self->_createRes( "", $lang );
        
        if ( !defined( $merge ) ) # failed
        {
            printf "ItemProjectRes::mergeTranslation: _createRes failed\n";
            last;
        }
        
        my $baseItemsExt = $resBase->getItemsExt();
        
        my $ok = 1;
        
        my $cntTotal = 0;
        my $cntTranslated = 0;
        my $cntAdded = 0;
        my $cntOverridden = 0;
        
        for my $curItem ( @{ $baseItemsExt } )
        {
            my $toAdd = $curItem;
            
            if ( $curItem->isa( "ItemTextRes" ) ) # text resource
            {
                undef $toAdd;
                
                {{
                    if ( !$curItem->isTranslatable() || $curItem->isAlias() ) # not tranlatable or alias
                    {
                        last;
                    }
                    
                    $cntTotal++;
                    
                    my $id = $curItem->getId();
                    my $plural = $curItem->isPlural();
                    
                    my $oldItem;

                    if ( defined( $resLang ) ) # has old translation
                    {
                        $oldItem = $resLang->getItemById( $id, $plural );
                    }
                    
                    my $newItem = $news->getItemById( $id, $plural );
                    
                    $toAdd = defined( $newItem ) ? $self->_mergeItem( $curItem, $newItem ) : $oldItem;
                    
                    if ( !defined( $toAdd ) ) # still no translation 
                    {
                        last;
                    }
                    
                    if ( defined( $newItem ) && defined( $oldItem ) ) # new item will override old one
                    {
                        $cntOverridden++;
                    }
                    elsif ( defined( $newItem ) ) # pure new item
                    {
                        $cntAdded++;
                    }
                    
                    $cntTranslated++;
                }}
            }
            
            if ( !defined( $toAdd ) )
            {
                next;
            }
            
            if ( !$merge->addItem( $toAdd ) ) # failed
            {
                $ok = 1;
                last;
            }
        }
        
        if ( !$ok ) # failed
        {
            last;
        }
        
        my $percent = 0;
        
        if ( $cntTotal > 0 )
        {
            $percent = 100.0 * $cntTranslated / $cntTotal;
        }
        
        printf "[%s] status: %.2f%% added: %d overridden: %d\n", $lang, $percent, $cntAdded, $cntOverridden;
        
        if ( $cntAdded + $cntOverridden <= 0 ) # no news
        {
            last;
        }
        
        $out = $merge;
    }}
    
    return $out;
}

#
# Prints summary report
#
# @param options - options
#
# @return !=0, if succeeded
#
sub reportSummary
{
    my ( $self, $options ) = @_;
    
    my $out = 0;
    
    {{
        my $resBase = $self->getResBase();
        
        if ( !defined( $resBase ) ) # no base resource
        {
            printf "ItemProjectRes::reportSummary: no base resource\n";
            last;
        }
        
        my $items = $resBase->getItems();
        
        my $cntTotal = 0;
        my $cntPlain = 0;
        my $cntPlural = 0;
        
        for ( @{ $items } )
        {
            if ( !$_->isTranslatable() ) # non-translatable
            {
                next;
            }
            
            if ( $_->isAlias() ) # alias
            {
                next;
            }
            
            $cntTotal++;
            
            if ( !$_->isPlural() ) # plain
            {
                $cntPlain++;
            }
            else
            {
                $cntPlural++;
            }
        }
        
        printf "Items: total %d (plurals %d)\n", $cntTotal, $cntPlural;
        
        if ( $cntTotal <= 0 ) # no item to translate
        {
            $out = 1;
            last;
        }
        
        my $langs = $self->getLangs();
        
        if ( !defined( $langs ) ) # failed
        {
            printf "ItemProjectRes::reportSummary: getLangs failed\n";
        }
        
        my @langsSorted = sort { CORE::fc($a) cmp CORE::fc($b) } keys %$langs;

        my $cntLangs = scalar( @langsSorted );
        
        if ( $cntLangs <= 0 ) # no translation
        {
            printf "No translation yet\n";
            $out = 1;
            last;
        }
        
        printf "Language count: %d\n", $cntLangs;
        printf "Languages: %s\n", join( " ", @langsSorted );
        
        my $totalNotTranslated = 0;
        
        for my $lang ( @langsSorted )
        {
            my $res = $self->getResForLang( $lang );
            
            if ( !defined( $res ) ) # failed
            {
                last;
            }
            
            my $cntTranslated = 0;
            
            for my $item ( @{ $items } )
            {
                if ( defined( $res->getItemById( $item->getId(), $item->isPlural() ) ) )
                {
                    $cntTranslated++;
                }
            }
            
            if ( $cntTranslated < $cntTotal )
            {
                printf "[%s] %.2f% translated\n", $lang, ( 100.0 * $cntTranslated / $cntTotal );
                
                $totalNotTranslated += ( $cntTotal - $cntTranslated );
            }
            else
            {
                printf "[%s] 100% translated\n", $lang;
            }
        }

        printf "\nItems to translate: %d\n", $totalNotTranslated;
        
        $out = 1;
    }}
    
    return $out;
}

1;
