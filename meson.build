# Project name and programming language
project('com.github.torikulhabib.mindi', 'vala', 'c', version: '0.1.0')


# Import main lib files
gnome = import('gnome')
i18n = import('i18n')

# Set our translation domain
add_global_arguments([
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name())
    ],
    language: 'c',
)

# Add deps
dependencies = [
    dependency('gio-unix-2.0', version: '>=2.20'),
    dependency('granite'),
    dependency('gtk+-3.0'),
]

# Add source files
code_files = files(
    'src/Application.vala',
    'src/Window.vala',
    'src/Settings.vala',
    'src/Utils/TimeUtil.vala',
    'src/Utils/StringUtil.vala',
    'src/Utils/StringPot.vala',
    'src/Widgets/Audio.vala',
    'src/Widgets/Dialog.vala',
    'src/Widgets/DialogOverwrite.vala',
    'src/Widgets/MessageDialog.vala',
    'src/Widgets/Toast.vala',
    'src/Widgets/LightDark.vala',
    'src/Widgets/Notify.vala',
    'src/Widgets/AplicaitonView.vala',
    'src/Widgets/StreamPc.vala',
    'src/Objects/Converter.vala',
    'src/Objects/Remover.vala',
    'src/Objects/CheckLink.vala'
)

# Define executable
executable(
    meson.project_name(),
    code_files,
    dependencies: dependencies,
    install: true
)

# Add in a post install script
meson.add_install_script('meson/post_install.py')

# Add subfolders for Meson to look
subdir('data')
subdir('po')
