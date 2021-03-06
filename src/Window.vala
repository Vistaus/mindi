using Gtk;
using Mindi.Configs;

namespace Mindi {
    public class Window : Gtk.ApplicationWindow {
        private Dialog? dialog = null;
        private DialogOverwrite? dialogoverwrite = null;
        private ObjectConverter? converter;
        private CheckLink? checklink;
        private NotifySilent? notifysilent;
        private LightDark? light_dark;
        private StreamPc? streampc;
        private Remover? remover;

        private Grid content;
        private Button open_video;
        private Image video_logo;
        private Label video_name;
        private Label title_video;
        private Grid video_container;

        private Button select_format;
        private Popover format_popover;
        private Image format_logo;
        private FlowBox format_list;
        private Label format_name;
        private Grid format_container;
        private Grid changed_container;

        private Grid convert_container;
        private Label convert_label;
        private Button convert_start;
        private Button convert_cancel;

        private LinkButton output_location;
        private LinkButton output_custom_location;
        private Label ask_location;
        private Button location_button;

        private Revealer choose_revealer;
        private Revealer convert_revealer;
        private Revealer cancel_revealer;
        private Revealer progressbar_revealer;
        private Revealer spinner_revealer;
        private Revealer cancel_checking_revealer;

        private Spinner spinner;
        private Stack stack;
        private Image stream_logo;
        private Stack stream_stack;
        private Stack reload_stack;
        private Stack change_and_format;
        private Label stream_name;
        private Grid stream_container;
        private Button open_stream;
        private Button reload_stream;
        private Entry entry;

        private string message;
        private bool ask_active {get;set;}
        private bool stream {get;set;}
        private bool other {get;set;}
        private bool warning_notify {get;set; default = false;}

        Notification desktop_notification;
        Mindi.Widgets.Toast app_notification;

        private GLib.Icon format_icon { 
            owned get {
                return format_logo.gicon;
            }
            set {
                format_logo.set_from_gicon (value, Gtk.IconSize.DIALOG);
            }
        }

        private GLib.Icon video_icon { 
            owned get {
                return video_logo.gicon;
            }
            set {
                video_logo.set_from_gicon (value, Gtk.IconSize.DIALOG);
            }
        }

        File _selected_video = null;
        public File selected_video {
            get { return _selected_video; }
            set {
                _selected_video = value;
                format_container.sensitive = selected_video != null;
                convert_container.sensitive = selected_video != null;

                if (selected_video != null) {
                    open_video.label = Mindi.StringPot.Change;
                    video_name.label = (selected_video.get_basename ());
                    open_video.tooltip_text = (selected_video.get_basename ());
                    status_location ();
                    input_find_location ();
                    convert_label.label = Mindi.StringPot.Ready;
                }
            }
        }

        Mindi.Formataudio _selected_formataudio = null;
        Mindi.Formataudio selected_formataudio {
            get { return _selected_formataudio; }
            set {
                if (selected_formataudio == value) {
                    return;
                }
                _selected_formataudio = value;
                format_name.label = selected_formataudio.formataudio.get_name ();
                update_formataudio_label ();
            }
        }

        public  Window (Gtk.Application application) {
                Object (application: application,
                        icon_name: "com.github.torikulhabib.mindi",
                        resizable: false,
                        hexpand: true
                );
        }

        construct {
		    Mindi.Configs.Settings.get_settings ().notify["folder-mode"].connect (() => {
                folder_symbol ();
		    });

            location_button = new Gtk.Button ();
            location_button.clicked.connect (() => {
                if (!converter.is_running) {
                    Mindi.Configs.Settings.get_settings ().folder_switch ();
                }
            });

            var open_button =  new Button.from_icon_name ("folder-open-symbolic", IconSize.SMALL_TOOLBAR);
            open_button.tooltip_text = Mindi.StringPot.SetLocation;
            open_button.clicked.connect (() => {
                if (!converter.is_running) {
                    costum_location ();
                }
            });

            var cancel_checking =  new Button.from_icon_name ("process-stop-symbolic", IconSize.SMALL_TOOLBAR);
            cancel_checking.tooltip_text = Mindi.StringPot.Stop;
            cancel_checking.clicked.connect (() => {
                checklink.cancel_now.begin ();
            });

            cancel_checking_revealer = new Gtk.Revealer ();
            cancel_checking_revealer.add (cancel_checking);
            cancel_checking_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;

            spinner = new Gtk.Spinner ();
            spinner_revealer = new Gtk.Revealer ();
            spinner_revealer.add (spinner);
            spinner_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;


            choose_revealer = new Gtk.Revealer ();
            choose_revealer.add (open_button);
            choose_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;

            var close_button = new Button.from_icon_name ("window-close-symbolic", IconSize.SMALL_TOOLBAR);
            close_button.tooltip_text = Mindi.StringPot.Close;
            close_button.clicked.connect (() => {
                signal_close ();
            });

            Timeout.add (50,() => {
                folder_symbol ();
                if (MindiApp.settings.get_boolean ("stream-mode")) {
                    stream_stack.visible_child_name = "stream";
                }
                return false;
            });

            light_dark = LightDark.instance;
            notifysilent = NotifySilent.instance;
            streampc = StreamPc.instance;
            var headerbar = new Gtk.HeaderBar ();
            headerbar.title = "Mindi";
            headerbar.has_subtitle = false;
            headerbar.show_close_button = false;
            headerbar.pack_end (light_dark.light_dark_button);
            headerbar.pack_end (notifysilent.notify_button);
            headerbar.pack_end (spinner_revealer);
            headerbar.pack_end (cancel_checking_revealer);
            headerbar.pack_start (close_button);
            headerbar.pack_start (streampc.stream_button);
            headerbar.pack_start (location_button);
            headerbar.pack_start (choose_revealer);
            set_titlebar (headerbar);

            var header_context = headerbar.get_style_context ();
            header_context.add_class ("default-decoration");
            header_context.add_class (Gtk.STYLE_CLASS_FLAT);

            var style_context = get_style_context ();
            style_context.add_class ("rounded");
            style_context.add_class ("widget_background");
            style_context.add_class ("flat");

            build_ui();

            converter = ObjectConverter.instance;
            checklink = CheckLink.instance;
            converter.begin.connect (on_converter_started);
            checklink.begin.connect (begin_check);
            streampc.signal_stream.connect (button_stream);
            remover = Remover.instance;

            show_all ();
            event.connect (listen_to_window_events);
        }

        void build_ui () {
            content = new Gtk.Grid ();
            content.margin = 20;
            content.column_spacing = 25;
            content.column_homogeneous = true;
            content.row_spacing = 20;
            content.halign = Gtk.Align.CENTER;
            content.valign = Gtk.Align.CENTER;

            app_notification = new Mindi.Widgets.Toast ("");
            var overlay = new Gtk.Overlay ();
            overlay.add (content);
            overlay.add_overlay (app_notification);

            desktop_notification = new Notification ("");

            build_video_area ();
            build_stream_area ();
            build_format_area ();
            build_convert_area ();
            stack_video_stream ();
            build_change_area ();
            stack_change ();
            add (overlay);
            show_all ();

            button_press_event.connect ((e) => {
                if (e.button == Gdk.BUTTON_PRIMARY) {
                    begin_move_drag ((int) e.button, (int) e.x_root, (int) e.y_root, e.time);
                    return true;
                }
                return false;
            });

            Timeout.add_seconds (1, () => {
                converter.read_name.begin ();
                return false;
            });

            if (selected_formataudio == null) {
                int default_audio = MindiApp.settings.get_enum ("format-audios");
                selected_formataudio = format_list.get_child_at_index(default_audio) as Mindi.Formataudio;
            }
        }

        public void signal_close () {
            if (converter.is_running) {
                if (dialog == null) {
                    dialog = new Dialog (this);
                    dialog.show_all ();
                    dialog.dialog_cancel_convert.connect (() => {
                        cancel_convert ();
                        converter.finished.connect (() => {
                            Timeout.add_seconds (1, () => {
                                destroy ();
                                return false;
                            });
                        });
                    });
                    dialog.destroy.connect (() => {
                        dialog = null;
                    });
                }
                dialog.present ();
            } else {
                destroy ();
            }
        }

       private void costum_location () {
            var location = new Gtk.FileChooserDialog (
                _(""), this, Gtk.FileChooserAction.SELECT_FOLDER,
                Mindi.StringPot.Cancel, Gtk.ResponseType.CANCEL,
                Mindi.StringPot.Open, Gtk.ResponseType.ACCEPT);

            var folder = new Gtk.FileFilter ();
            folder.add_mime_type ("inode/directory");
            location.set_filter (folder);

            if (location.run () == Gtk.ResponseType.ACCEPT) {
                MindiApp.settings.set_string ("output-folder", location.get_file ().get_path ());
                status_location ();
            }
            location.destroy ();
        }

        private void status_location () {
            output_custom_location.label = (Utils.limitstring (MindiApp.settings.get_string ("output-folder")));
            ask_location.label = "<i>%s</i>".printf (Mindi.StringPot.AskWhereSave);

            Timeout.add (50,() => {
                output_custom_location.set_uri ("file://"+ MindiApp.settings.get_string ("output-folder"));
                return false;
            });
        }

        private void build_video_area () {
            video_container = new Gtk.Grid ();
            video_container.row_spacing = 10;
            video_container.width_request = 16;
            video_container.column_homogeneous = true;

            title_video = new Gtk.Label (Mindi.StringPot.Offline);
            title_video.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
            title_video.hexpand = true;
            video_container.attach (title_video, 0, 0, 1, 1);

            video_logo = new Image ();
            video_icon = new ThemedIcon ("applications-multimedia");
            video_container.attach (video_logo, 0, 1, 1, 1);

            video_name = new Gtk.Label ("<i>%s</i>".printf (Mindi.StringPot.VideoFile));
            video_name.max_width_chars = 15;
            video_name.use_markup = true;
            video_name.ellipsize = Pango.EllipsizeMode.END;
            video_name.halign = Gtk.Align.CENTER;
            video_name.wrap = true;
            video_container.attach (video_name, 0, 2, 1, 1);

            open_video = new Gtk.Button.with_label (Mindi.StringPot.SelectVideo);
            open_video.clicked.connect (select_video);
            video_container.attach (open_video, 0, 3, 1, 1);
        }

        private void build_stream_area () {
            stream_container = new Gtk.Grid ();
            stream_container.row_spacing = 10;
            stream_container.width_request = 16;
            stream_container.column_homogeneous = true;

            var title_stream = new Gtk.Label (Mindi.StringPot.Online);
            title_stream.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
            title_stream.hexpand = true;
            stream_container.attach (title_stream, 0, 0, 1, 1);

            stream_logo = new Image.from_icon_name ("internet-web-browser", Gtk.IconSize.DIALOG);
            stream_container.attach (stream_logo, 0, 1, 1, 1);

            stream_name = new Gtk.Label (Mindi.StringPot.GetNow);
            stream_name.max_width_chars = 15;
            stream_name.ellipsize = Pango.EllipsizeMode.END;
            stream_name.halign = Gtk.Align.CENTER;
            stream_name.wrap = true;
            stream_name.show ();
            stream_container.attach (stream_name, 0, 2, 1, 1);

            var button = new Button.from_icon_name ("list-add-symbolic", IconSize.SMALL_TOOLBAR);
            button.tooltip_text = Mindi.StringPot.Add;
            button.sensitive = false;
            var clip_button = new Button.from_icon_name ("edit-paste-symbolic", IconSize.SMALL_TOOLBAR);
            clip_button.tooltip_text = Mindi.StringPot.Paste;
            entry = new Gtk.Entry ();
            entry.tooltip_text = Mindi.StringPot.PasteHere;

            var stream_grid = new Gtk.Grid ();
            stream_grid.orientation = Gtk.Orientation.HORIZONTAL;
            stream_grid.row_spacing = 10;
            stream_grid.column_spacing = 10;
            stream_grid.border_width = 10;
            stream_grid.add (entry);
            stream_grid.add (clip_button);
            stream_grid.add (button);
            stream_grid.show_all ();
            entry.has_focus = true;

            clip_button.clicked.connect (() => {
                Gdk.Display display = get_display ();
                Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);
                string text = clipboard.wait_for_text ().strip ();
                entry.set_text (text);
            });

            entry.changed.connect (() => {
                button.sensitive = entry.text != "" ? true : false;
            });

            open_stream = new Gtk.Button.with_label (Mindi.StringPot.AddUrl);
            open_stream.valign = Gtk.Align.CENTER;

            reload_stream = new Gtk.Button.with_label (Mindi.StringPot.Reload);
            reload_stream.valign = Gtk.Align.CENTER;

            reload_stack = new Stack ();
            reload_stack.add_named (open_stream, "addurl");
            reload_stack.add_named (reload_stream, "reload");

            var add_url_popover = new Gtk.Popover (open_stream);
            add_url_popover.position = Gtk.PositionType.TOP;
            add_url_popover.add (stream_grid);
            open_stream.clicked.connect (() => { add_url_popover.visible = !add_url_popover.visible;});
            button.clicked.connect (() => {
                check_clicked ();
                add_url_popover.hide ();
            });

            reload_stream.clicked.connect (() => {
                check_clicked ();
            });

            stream_container.attach (reload_stack, 0, 3, 1, 1);
        }

        private void stack_video_stream () {
            stream_stack = new Stack ();
            stream_stack.add_named (video_container, "video");
            stream_stack.add_named (stream_container, "stream");
            content.attach (stream_stack, 0, 0, 1, 1);
        }

        private void check_clicked () {
            string url = entry.get_text().strip ();
            if (url.contains ("youtu")) {
                other = true;
                if (url.contains ("&" + "list")) {
                    string [] link = url.split ("&");
                    check_link (link [0], other);
                } else if (url.contains ("?" + "list")) {
                    string [] link = url.split ("?list");
                    check_link (link [0], other);
                } else {
                    check_link (url, other);
                }
            } else {
                other = false;
                check_link (url, other);
            }
        }

        private void check_link (string url, bool other) {
            checklink.check_link.begin (url, other);
            checklink.finished.connect (checklink_finished);
            checklink.notif.connect (send_notify);
        }

        private void begin_check () {
            stream_name.label = Mindi.StringPot.CheckLink;
            open_stream.sensitive = false;
            video_logo.sensitive = false;
            select_format.sensitive = false;
            format_logo.sensitive = false;
            format_name.sensitive = false;
            convert_start.sensitive = false;
            stream_logo.sensitive = false;
            reload_stream.sensitive = false;
            changed_container.sensitive = false;
            spinner.active = true;
            spinner_revealer.set_reveal_child (true);
            cancel_checking_revealer.set_reveal_child (true);
            Timeout.add (50,() => {
                app_notification.title = Mindi.StringPot.Checking;
                app_notification.send_notification ();
                return false;
            });
        }

        private void send_notify () {
            stream_name.label = Mindi.StringPot.GetNow;
            open_stream.sensitive = true;
            video_logo.sensitive = true;
            select_format.sensitive = true;
            format_logo.sensitive = true;
            format_name.sensitive = true;
            stream_logo.sensitive = true;
            reload_stream.sensitive = true;
            changed_container.sensitive = true;
            spinner.active = false;
            spinner_revealer.set_reveal_child (false);
            cancel_checking_revealer.set_reveal_child (false);
            Timeout.add (50,() => {
                app_notification.title = checklink.status;
                app_notification.send_notification ();
                return false;
            });
        }

        private void checklink_finished (bool finish) {
            add_url_clicked (stream, finish);
        }

        private void add_url_clicked (bool stream, bool finish) {
            string url = entry.get_text().strip ();
            if (url.contains ("youtu")) {
                stream = true;
                if (url.contains ("&" + "list")) {
                    string [] link = url.split ("&");
                    add_download (link [0], stream, finish);
                } else if (url.contains ("?" + "list")) {
                    string [] link = url.split ("?list");
                    add_download (link [0], stream, finish);
                } else {
                    add_download (url, stream, finish);
                }
            } else {
                stream = false;
                add_download (url, stream, finish);
            }
        }

        private void add_download (string url, bool stream, bool finish) {
            if (!converter.is_running) {
                converter.finished.connect (on_converter_finished);
                converter.finished.connect (notify_signal);
                converter.get_video.begin (url, stream, finish);
            }
        }

        private void select_video () {
            var file = new Gtk.FileChooserDialog (
                _(""), this, Gtk.FileChooserAction.OPEN,
                Mindi.StringPot.Cancel, Gtk.ResponseType.CANCEL,
                Mindi.StringPot.Open, Gtk.ResponseType.ACCEPT);

            var all_files_filter = new Gtk.FileFilter ();
            all_files_filter.set_filter_name (Mindi.StringPot.AllFiles);
            all_files_filter.add_pattern ("*");
            var video_filter = new Gtk.FileFilter ();
            video_filter.set_filter_name (Mindi.StringPot.VideoFiles);
            video_filter.add_mime_type ("video/mpeg;");
            video_filter.add_mime_type ("video/mp4");
            video_filter.add_mime_type ("video/webm");
            video_filter.add_mime_type ("video/flv");
            var audio_filter = new Gtk.FileFilter ();
            audio_filter.set_filter_name (Mindi.StringPot.AudioFiles);
            audio_filter.add_mime_type ("audio/mp3");
            audio_filter.add_mime_type ("audio/wav");
            audio_filter.add_mime_type ("audio/m4a");

            file.add_filter (video_filter);
            file.add_filter (audio_filter);
            file.add_filter (all_files_filter);

            if (file.run () == Gtk.ResponseType.ACCEPT) {
                selected_video = file.get_file ();
                input_find_location ();
            }
            file.destroy ();
        }

        private void input_find_location () {
            string [] output = selected_video.get_path ().split ("/" + selected_video.get_basename ());
            MindiApp.settings.set_string ("folder-link", output [0]);
            output_location.label = (Utils.limitstring (MindiApp.settings.get_string ("folder-link")));
            Timeout.add (50,() => {
                output_location.set_uri ("file://" + MindiApp.settings.get_string ("folder-link"));
                return false;
            });
            input_type ();
        }

        private void input_type () {
	        int i = selected_video.get_basename ().last_index_of (".");
            string up = selected_video.get_basename ().substring (i + 1).up ();
            if (up.contains ("MP4")) {
                video_icon = new ThemedIcon ("com.github.torikulhabib.mindi.mp4");
                title_video.label = ("Video");
            } else if (up.contains ("FLV")) {
                video_icon = new ThemedIcon ("com.github.torikulhabib.mindi.flv");
                title_video.label = ("Video");
            } else if (up.contains ("WEBM")) {
                video_icon = new ThemedIcon ("com.github.torikulhabib.mindi.webm");
                title_video.label = ("Video");
            } else if (up.contains ("AVI")) {
                video_icon = new ThemedIcon ("com.github.torikulhabib.mindi.avi");
                title_video.label = ("Video");
            } else if (up.contains ("MPG")) {
                video_icon = new ThemedIcon ("com.github.torikulhabib.mindi.mpg");
                title_video.label = ("Video");
            } else if (up.contains ("MPEG")) {
                video_icon = new ThemedIcon ("com.github.torikulhabib.mindi.mpeg");
                title_video.label = ("Video");
            } else if (up.contains ("MKV")) {
                video_icon = new ThemedIcon ("com.github.torikulhabib.mindi.mkv");
                title_video.label = ("Video");
            } else if (up.contains ("AAC")) {
                video_icon = new ThemedIcon ("com.github.torikulhabib.mindi.aac");
                title_video.label = ("Audio");
            } else if (up.contains ("AC3")) {
                video_icon = new ThemedIcon ("com.github.torikulhabib.mindi.ac3");
                title_video.label = ("Audio");
            } else if (up.contains ("AIFF")) {
                video_icon = new ThemedIcon ("com.github.torikulhabib.mindi.aiff");
                title_video.label = ("Audio");
            } else if (up.contains ("FLAC")) {
                video_icon = new ThemedIcon ("com.github.torikulhabib.mindi.flac");
                title_video.label = ("Audio");
            } else if (up.contains ("MMF")) {
                video_icon = new ThemedIcon ("com.github.torikulhabib.mindi.mmf");
                title_video.label = ("Audio");
            } else if (up.contains ("MP3")) {
                video_icon = new ThemedIcon ("com.github.torikulhabib.mindi.mp3");
                title_video.label = ("Audio");
            } else if (up.contains ("M4A")) {
                video_icon = new ThemedIcon ("com.github.torikulhabib.mindi.m4a");
                title_video.label = ("Audio");
            } else if (up.contains ("OGG")) {
                video_icon = new ThemedIcon ("com.github.torikulhabib.mindi.ogg");
                title_video.label = ("Audio");
            } else if (up.contains ("WMA")) {
                video_icon = new ThemedIcon ("com.github.torikulhabib.mindi.wma");
                title_video.label = ("Audio");
            } else if (up.contains ("WAV")) {
                video_icon = new ThemedIcon ("com.github.torikulhabib.mindi.wav");
                title_video.label = ("Audio");
            } else {
                video_icon = new ThemedIcon ("applications-multimedia");
                title_video.label = ("A / V");
            }
        }

        private void build_format_area () {
            format_container = new Gtk.Grid ();
            format_container.row_spacing = 10;
            format_container.width_request = 16;
            format_container.column_homogeneous = true;
            format_container.sensitive = false;

            var title = new Gtk.Label (Mindi.StringPot.Audio);
            title.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
            title.hexpand = true;
            format_container.attach (title, 0, 0, 1, 1);

            var format_grid = new Gtk.Grid ();
            format_list = new Gtk.FlowBox ();
            format_list.child_activated.connect (on_select_fileformat);
            format_grid.add (format_list);

            format_logo = new Gtk.Image ();
            format_container.attach (format_logo, 0, 1, 1, 1);

            format_name = new Gtk.Label ("");
            format_name.use_markup = true;
            format_container.attach (format_name, 0, 2, 1, 1);

            select_format = new Gtk.Button.with_label (Mindi.StringPot.Select);
            select_format.valign = Gtk.Align.CENTER;
            select_format.vexpand = true;
            select_format.clicked.connect (() => { format_popover.visible = !format_popover.visible;});
            format_container.attach (select_format, 0, 3, 1, 1);

            format_popover = new Gtk.Popover (select_format);
            format_popover.position = Gtk.PositionType.TOP;
            format_popover.add (format_grid);
            format_popover.show.connect (() => {
                if (selected_formataudio != null) {
                    format_list.select_child (selected_formataudio);
                }
                selected_formataudio.grab_focus ();
            });

            foreach (var formataudio in Mindi.Formataudios.get_all ()) {
                var item = new Mindi.Formataudio (formataudio);
                format_list.add (item);
            }
            format_grid.show_all ();
        }

        private void build_change_area () {
            changed_container = new Gtk.Grid ();
            changed_container.row_spacing = 10;
            changed_container.width_request = 16;
            changed_container.column_homogeneous = true;

            var title = new Gtk.Label (Mindi.StringPot.Link);
            title.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
            title.hexpand = true;
            changed_container.attach (title, 0, 0, 1, 1);

            var link_logo = new Gtk.Image.from_icon_name ("insert-link", Gtk.IconSize.DIALOG);
            changed_container.attach (link_logo, 0, 1, 1, 1);

            var change_name = new Gtk.Label (Mindi.StringPot.ChangeLink);
            change_name.use_markup = true;
            changed_container.attach (change_name, 0, 2, 1, 1);

            var change_link = new Gtk.Button.with_label (Mindi.StringPot.Change);
            change_link.valign = Gtk.Align.CENTER;
            change_link.vexpand = true;
            change_link.clicked.connect (() => {
                reload_stack.visible_child_name = "addurl";
                change_and_format.visible_child_name = "format";
            });
            changed_container.attach (change_link, 0, 3, 1, 1);
        }

        private void stack_change () {
            change_and_format = new Stack ();
            change_and_format.add_named (format_container, "format");
            change_and_format.add_named (changed_container, "change");
            content.attach (change_and_format, 1, 0, 1, 1);
        }

        private void on_select_fileformat (Gtk.FlowBoxChild item) {
            selected_formataudio = item as Mindi.Formataudio;
            MindiApp.settings.set_enum ("format-audios", (int) selected_formataudio.formataudio);
            format_popover.hide ();
        }

        private void build_convert_area () {
            convert_container = new Gtk.Grid ();
            convert_container.row_spacing = 10;
            convert_container.width_request = 16;
            convert_container.column_homogeneous = true;
            convert_container.sensitive = false;

            convert_label = new Gtk.Label ("<i>%s</i>".printf (Mindi.StringPot.NoVideoChoosen));
            convert_label.use_markup = true;
            convert_label.vexpand = true;
            convert_container.attach (convert_label, 0, 0, 2, 1);

            progressbar_revealer = new Gtk.Revealer ();
            progressbar_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
            progressbar_revealer.valign = Gtk.Align.CENTER;
            convert_container.attach (progressbar_revealer, 0, 0, 2, 1);
            convert_start = new Gtk.Button.with_label (Mindi.StringPot.Convert);
            convert_start.vexpand = true;
            convert_start.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            convert_start.clicked.connect (convert_video);

            convert_revealer = new Gtk.Revealer ();
            convert_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            convert_revealer.add (convert_start);
            convert_revealer.valign = Gtk.Align.CENTER;
            convert_container.attach (convert_revealer, 0, 4, 2,1);
            convert_revealer.set_reveal_child (true);

            convert_cancel = new Gtk.Button.with_label (Mindi.StringPot.Cancel);
            convert_cancel.vexpand = true;
            convert_cancel.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            convert_cancel.clicked.connect (() => {
                if (dialog == null) {
                    dialog = new Dialog (this);
                    dialog.show_all ();
                    dialog.dialog_cancel_convert.connect ( () => {
                        warning_notify = false;
                        cancel_convert ();
                        });
                    dialog.destroy.connect (() => {
                    dialog = null;
                        });
                }
                dialog.present ();
            });

            cancel_revealer = new Gtk.Revealer ();
            cancel_revealer.add (convert_cancel);
            cancel_revealer.valign = Gtk.Align.CENTER;
            cancel_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            convert_container.attach (cancel_revealer, 0, 4, 2,1);

            var string_location = new Label (Mindi.StringPot.Location);
            output_location = new Gtk.LinkButton (Mindi.StringPot.Input);
            var grid_location = new Grid ();
            grid_location.orientation = Gtk.Orientation.HORIZONTAL;
            grid_location.halign = Gtk.Align.CENTER;
            grid_location.add (string_location);
            grid_location.add (output_location);

            var string_custom_location = new Label (Mindi.StringPot.Location);
            output_custom_location = new Gtk.LinkButton (Mindi.StringPot.SelectAudioLocation);
            var grid_custom_location = new Grid ();
            grid_custom_location.orientation = Gtk.Orientation.HORIZONTAL;
            grid_custom_location.halign = Gtk.Align.CENTER;
            grid_custom_location.add (string_custom_location);
            grid_custom_location.add (output_custom_location);

            ask_location = new Gtk.Label ("<i>%s</i>".printf (Mindi.StringPot.AskWhereSave));
            ask_location.ellipsize = Pango.EllipsizeMode.END;
            ask_location.max_width_chars = 15;
            ask_location.use_markup = true;
            ask_location.valign = Gtk.Align.CENTER;
            ask_location.wrap = true;

            var label_download = new Gtk.Label ("<i>%s</i>".printf (Mindi.StringPot.Downloading));
            label_download.use_markup = true;
            label_download.valign = Gtk.Align.CENTER;

            stack = new Stack ();
            stack.add_named (grid_location, "name");
            stack.add_named (grid_custom_location, "name_custom");
            stack.add_named (ask_location, "ask");
            stack.add_named (label_download, "download");
            convert_container.attach (stack, 0, 3, 2, 1);

            content.attach (convert_container, 0, 1, 2, 1);
        }

        private void on_converter_started (bool now_converting) {
            ask_location.label = (Mindi.StringPot.Location + MindiApp.settings.get_string ("ask-location"));

            open_video.sensitive = false;
            open_stream.sensitive = false;
            video_logo.sensitive = false;
            select_format.sensitive = false;
            format_logo.sensitive = false;
            format_name.sensitive = false;
            convert_start.sensitive = false;
            stream_logo.sensitive = false;

            convert_revealer.visible = false;
            convert_revealer.set_reveal_child (false);
            cancel_revealer.set_reveal_child (true);
            progressbar_revealer.add (converter);

            Timeout.add_seconds (1, () => {
                progressbar_revealer.set_reveal_child (true);
                convert_label.visible = false;
                return false;
            });
            if (streampc.stream_active) {
            convert_container.sensitive = true;
            format_container.sensitive = true;
                if (!now_converting) {
                    Timeout.add (50,() => {
                        stack.visible_child_name = "download";
                        stream_name.label = Mindi.StringPot.PleaseWait;
                        open_stream.sensitive = false;
                        select_format.sensitive = false;
                        reload_stream.sensitive = false;
                        changed_container.sensitive = false;
                        return false;
                    });
                } else {
                    stream_name.label = Mindi.StringPot.Converting;
                }
            } else {
                video_name.label = Mindi.StringPot.Converting;
            }
        }

        private void on_converter_finished (bool success) {
            converter.finished.disconnect (on_converter_finished);
            converter.finished.disconnect (notify_signal);
            progressbar_revealer.remove (converter);
            folder_symbol ();
            ask_location.label = "<i>%s</i>".printf (Mindi.StringPot.AskWhereSave);

            Timeout.add_seconds (1, () => {
                convert_revealer.set_reveal_child (true);
                convert_revealer.visible = true;
                cancel_revealer.set_reveal_child (false);
                progressbar_revealer.set_reveal_child (false);
                convert_label.visible = true;
                return false;
            });

            open_video.sensitive = true;
            open_stream.sensitive = true;
            video_logo.sensitive = true;
            select_format.sensitive = true;
            format_logo.sensitive = true;
            format_name.sensitive = true;
            convert_start.sensitive = true;
            stream_logo.sensitive = true;
            reload_stream.sensitive = true;
            changed_container.sensitive = true;
            if (streampc.stream_active) {
                stream_name.label = converter.name_file_stream;
                if (converter.is_downloading){
                    status_location ();
                    if (success) {
                        stream_name.label = converter.name_file_stream;
                        entry.set_text ("");
                        app_notification.title = Mindi.StringPot.DownloadSucces;
                        convert_label.label = Mindi.StringPot.ReadyConvert;
                        app_notification.send_notification ();
                        convert_start.sensitive = true;
                        select_format.sensitive = true;
                        reload_stack.visible_child_name = "addurl";
                        change_and_format.visible_child_name = "format";
                        open_stream.tooltip_text = (converter.name_file_stream);
                    } else {
                        app_notification.title = Mindi.StringPot.DownloadError;
                        app_notification.send_notification ();
                        stream_name.label = Mindi.StringPot.FailedRetrieve;
                        convert_label.label = "<i>%s</i>".printf (Mindi.StringPot.NotYet);
                        convert_start.sensitive = false;
                        select_format.sensitive = false;
                        reload_stack.visible_child_name = "reload";
                        change_and_format.visible_child_name = "change";
                        open_stream.tooltip_text = ("");
                    }
                } else {
                    if (success) {
                        message = Mindi.StringPot.WasConverted.printf (converter.name_file_stream, selected_formataudio.formataudio.get_name ());
                    } else {
                        message = Mindi.StringPot.ErrorWhile.printf (converter.name_file_stream, selected_formataudio.formataudio.get_name ());
                    }
                    notify_signal (success);
                }
            } else {
                video_name.label = (selected_video.get_basename ());
                if (success) {
                    message = Mindi.StringPot.WasConverted.printf (selected_video.get_basename (), selected_formataudio.formataudio.get_name ());
                } else {
                    message = Mindi.StringPot.ErrorWhile.printf (selected_video.get_basename (), selected_formataudio.formataudio.get_name ());
                    }
                notify_signal (success);
                }
        }

        private void notify_signal (bool success) {
            if (!warning_notify) {
                Timeout.add (50,() => {
                    if (is_active) {
                        if (success) {
                            if (notifysilent.notify_active) {
                                create_dialog_finish ("%s".printf (message));
                            } else {
                                app_notification.title = Mindi.StringPot.Finished;
                                app_notification.send_notification ();
                            }
                        } else {
                            if (notifysilent.notify_active) {
                                create_dialog_error ("%s".printf (message));
                            } else {
                                app_notification.title = Mindi.StringPot.Error;
                                app_notification.send_notification ();
                            }
                            fail_convert ();
                        }
                    } else {
                        if (success) {
                            desktop_notification.set_title (Mindi.StringPot.Finished);
                        } else {
                            desktop_notification.set_title (Mindi.StringPot.Error);
                            fail_convert ();
                        }
                        if (notifysilent.notify_active) {
                            desktop_notification.set_body (message);
                            application.send_notification ("notify.app", desktop_notification);
                        }
                    }
                return false;
                });
            }
        }

        private void create_dialog_finish (string text) {
            var message_dialog = new Mindi.MessageDialog.with_image_from_icon_name (this, Mindi.StringPot.Finished, text, "com.github.torikulhabib.mindi",
 Gtk.ButtonsType.CLOSE);
            var auto_close = new Gtk.CheckButton.with_label (Mindi.StringPot.AutomaticClose);
            auto_close.show ();
            auto_close.toggled.connect (() => {
                Timeout.add_seconds (1, () => {
                    message_dialog.destroy ();
                    return false;
                });
            });
            message_dialog.custom_bin.add (auto_close);
            MindiApp.settings.bind ("auto-close", auto_close, "active", GLib.SettingsBindFlags.DEFAULT);
            message_dialog.run ();
            message_dialog.destroy ();
        }

        private void create_dialog_error (string text) {
            var message_dialog = new Mindi.MessageDialog.with_image_from_icon_name (this, Mindi.StringPot.Error, text, "com.github.torikulhabib.mindi",
 Gtk.ButtonsType.CLOSE);
            var auto_close = new Gtk.CheckButton.with_label (Mindi.StringPot.AutomaticClose);
            auto_close.show ();
            auto_close.toggled.connect (() => {
                Timeout.add_seconds (1, () => {
                    message_dialog.destroy ();
                    return false;
                });
            });
            message_dialog.custom_bin.add (auto_close);
            MindiApp.settings.bind ("auto-close", auto_close, "active", GLib.SettingsBindFlags.DEFAULT);
            message_dialog.run ();
            message_dialog.destroy ();
        }

       private void ask_costum_location () {
            var ask_location = new Gtk.FileChooserDialog (
                _(""), this, Gtk.FileChooserAction.SELECT_FOLDER,
                Mindi.StringPot.Cancel, Gtk.ResponseType.CANCEL,
                Mindi.StringPot.Ok, Gtk.ResponseType.ACCEPT);

            var folder_ask = new Gtk.FileFilter ();
            folder_ask.add_mime_type ("inode/directory");
            ask_location.set_filter (folder_ask);

            if (ask_location.run () == Gtk.ResponseType.ACCEPT) {
                MindiApp.settings.set_string ("ask-location", ask_location.get_file ().get_path ());
                converter.finished.connect (on_converter_finished);
                converter.finished.connect (notify_signal);
                converter.warning_notif.connect (warning_notif);
                converter.set_folder.begin (selected_video, streampc.stream_active);
                converter.converter_now.begin (selected_formataudio.formataudio);
            }
            ask_location.destroy ();
        }

        private void convert_video () {
            warning_notify = false;
            if (!converter.is_running) {
                if (ask_active) {
                    ask_costum_location ();
                } else {
                    converter.finished.connect (on_converter_finished);
                    converter.finished.connect (notify_signal);
                    converter.warning_notif.connect (warning_notif);
                    converter.set_folder.begin (selected_video, streampc.stream_active);
                    converter.converter_now.begin (selected_formataudio.formataudio);
                }
            }
        }

        private void warning_notif (bool notif) {
            if (notif) {
                warning_notify = true;
                if (dialogoverwrite == null) {
                    dialogoverwrite = new DialogOverwrite (this, converter.notify_string);
                    dialogoverwrite.show_all ();
                    dialogoverwrite.dialog_overwrite_convert.connect (() => {
                        converter.set_folder.begin (selected_video, streampc.stream_active);
                        remover.remove_file.begin (selected_formataudio.formataudio);
                            Timeout.add_seconds (1, () => {
                                if (!converter.is_running) {
                                    converter.finished.connect (on_converter_finished);
                                    converter.finished.connect (notify_signal);
                                    converter.set_folder.begin (selected_video, streampc.stream_active);
                                    converter.converter_now.begin (selected_formataudio.formataudio);
                                }
                                return false;
                            });
                    });
                    dialogoverwrite.destroy.connect (() => {
                        dialogoverwrite = null;
                    });
                }
                dialogoverwrite.present ();
            } else {
                warning_notify = false;
            }
        }

        private void cancel_convert () {
            if (converter.is_running) {
                converter.cancel_now.begin ();
            }
        }

        private void fail_convert () {
            if (!converter.is_running) {
                converter.set_folder.begin (selected_video, streampc.stream_active);
                remover.remove_file.begin (selected_formataudio.formataudio);
            }
        }

        private void update_formataudio_label () {
            switch (selected_formataudio.formataudio) {
                case Mindi.Formataudios.AC3:
                    format_icon = new ThemedIcon ("com.github.torikulhabib.mindi.ac3");
                    break;
                case Mindi.Formataudios.AIFF:
                    format_icon = new ThemedIcon ("com.github.torikulhabib.mindi.aiff");
                    break;
                case Mindi.Formataudios.FLAC:
                    format_icon = new ThemedIcon ("com.github.torikulhabib.mindi.flac");
                    break;
                case Mindi.Formataudios.MMF:
                    format_icon = new ThemedIcon ("com.github.torikulhabib.mindi.mmf");
                    break;
                case Mindi.Formataudios.MP3:
                    format_icon = new ThemedIcon ("com.github.torikulhabib.mindi.mp3");
                    break;
                case Mindi.Formataudios.M4A:
                    format_icon = new ThemedIcon ("com.github.torikulhabib.mindi.m4a");
                    break;
                case Mindi.Formataudios.OGG:
                    format_icon = new ThemedIcon ("com.github.torikulhabib.mindi.ogg");
                    break;
                case Mindi.Formataudios.WMA:
                    format_icon = new ThemedIcon ("com.github.torikulhabib.mindi.wma");
                    break;
                case Mindi.Formataudios.WAV:
                    format_icon = new ThemedIcon ("com.github.torikulhabib.mindi.wav");
                    break;
                default:
                    format_icon = new ThemedIcon ("com.github.torikulhabib.mindi.aac");
                    break;
            }
        }

        private void button_stream () {
            if (streampc.stream_active) {
                stream_stack.visible_child_name = "video";
            } else {
                stream_stack.visible_child_name = "stream";
            }
        }

        private bool listen_to_window_events (Gdk.Event event) {
            converter.is_active_signal (is_active);
            return false;
        }

        private void folder_symbol () {
            switch (Mindi.Configs.Settings.get_settings ().folder_mode) {
                case FolderMode.PLACE :
                    location_button.set_image (new Gtk.Image.from_icon_name ("document-save-symbolic", Gtk.IconSize.BUTTON));
                    location_button.tooltip_text = Mindi.StringPot.LocationInput;
                    ask_active = false;
                    choose_revealer.set_reveal_child (false);
                    stack.visible_child_name = "name";
                    break;
                case FolderMode.CUSTOM :
                    location_button.set_image (new Gtk.Image.from_icon_name ("document-save-as-symbolic", Gtk.IconSize.BUTTON));
                    location_button.tooltip_text = Mindi.StringPot.Custom;
                    ask_active = false;
                    choose_revealer.set_reveal_child (true);
                    stack.visible_child_name = "name_custom";
                    break;
                case FolderMode.ASK :
                    location_button.set_image (new Gtk.Image.from_icon_name ("system-help-symbolic", Gtk.IconSize.BUTTON));
                    location_button.tooltip_text = Mindi.StringPot.Ask;
                    ask_active = true;
                    choose_revealer.set_reveal_child (false);
                    stack.visible_child_name = "ask";
                    break;
            }
            location_button.show_all ();
        }
    }
}
