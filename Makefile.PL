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
        'Test::Simple'    => 0.98,
        'Test::Exception' => 0.31,
        'Storable'        => 2.34,
        'Iterator::Util'  => 0.02,
        'Carp'            => 1.26,
    },
);
