

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Data::LinkedList',
    VERSION_FROM => 'lib/Data/LinkedList.pm', # finds \$VERSION
    AUTHOR       => 'Lloyd Griffiths (lloyd.griffiths.sw@gmail.com)',
    ABSTRACT     => 'Perl implementation of the GNU classpath LinkedList.',
    LICENSE => 'perl',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/LloydGriffiths/Data-LinkedList',
        },
    },
    PREREQ_PM    => {
        'Test::Simple' => 0.44,
    },
);
