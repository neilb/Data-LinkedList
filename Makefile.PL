

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Data::LinkedList',
    VERSION_FROM => 'lib/Data/LinkedList.pm', # finds \$VERSION
    AUTHOR       => 'Lloyd Griffiths (lloyd.griffiths.sw@gmail.com)',
    ABSTRACT     => 'Perl implementation of the Java LinkedList class.',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
