i18n.merge_file(
    input: meson.project_name() + '.desktop.in',
    output: meson.project_name() + '.desktop',
    po_dir: join_paths(meson.source_root (), 'po', 'extra'),
    type: 'desktop',
    install_dir: join_paths(get_option('datadir'), 'applications'),
    install: true
)

i18n.merge_file(
    input: meson.project_name() + '.appdata.xml.in',
    output: meson.project_name() + '.appdata.xml',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    type: 'xml',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo'),
)

install_data(
    '49-' + meson.project_name() + '.pkla',
    install_dir: join_paths(get_option('sharedstatedir'), 'polkit-1', 'localauthority', '10-vendor.d')
)

# Test the desktop file
validate_desktop_exe = find_program('desktop-file-validate')
test ('Validate desktop file', validate_desktop_exe,
    args: join_paths(meson.current_build_dir (), meson.project_name() + '.desktop')
)
