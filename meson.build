project ('com.github.cassidyjames.anamorph', 'vala', 'c')

gnome = import ('gnome')
i18n = import ('i18n')

add_global_arguments ('-DGETTEXT_PACKAGE="' + meson.project_name () + '"', language:'c')

asresources = gnome.compile_resources (
    'as-resources', join_paths ('data', 'gresource.xml'),
    source_dir: 'data',
    c_name: 'as'
)

anamorph_files = files (
    'src/Application.vala',
    'src/Fraction.vala',
    'src/GstreamerDesqueezer.vala',
    'src/GstreamerFileDesqueezer.vala',
    'src/GstreamerMetadataReader.vala',
    'src/MainWindow.vala',
    'src/Views/ErrorView.vala',
    'src/Views/ProgressView.vala',
    'src/Views/SetupView.vala',
    'src/Views/SuccessView.vala',
    'src/Views/WelcomeView.vala'
)

executable (
    meson.project_name (),
    asresources,
    anamorph_files,
    dependencies: [
        dependency ('glib-2.0'),
        dependency ('granite'),
        dependency ('gtk+-3.0'),
        meson.get_compiler('vala').find_library('posix'),
        dependency ('gstreamer-1.0')
    ],
    install: true
)

subdir ('data')

meson.add_install_script (join_paths ('meson', 'post_install.py'))

