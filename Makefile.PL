use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Data::LinkedList',
    VERSION_FROM => 'lib/Data/LinkedList.pm',
    AUTHOR       => 'Lloyd Griffiths (lloydg@cpan.org)',
    ABSTRACT     => 'Perl implementation of the GNU Classpath LinkedList.',
    LICENSE => 'perl',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/LloydGriffiths/Data-LinkedList',
        },
    },
    PREREQ_PM    => {
        'Test::Simple'   => 0.44,
        'Storable'       => 2.34,
        'Iterator::Util' => 0.02,
    },
);