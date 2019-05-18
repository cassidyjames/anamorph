/*
* Copyright ⓒ 2018 Cassidy James Blaede (https://cassidyjames.com)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Cassidy James Blaede <c@ssidyjam.es>
*/

public class SetupView : Gtk.Grid {
    public signal void desqueeze_file (string input_uri, string output_path);

    private string file_uri;
    private string output_path;

    private Gtk.Label info_label;
    private GstreamerDesqueezer desqueezer;
    private string LABEL_TEMPLATE = _("De-squeezing will create a new file named <b>%s</b> alongside the input file.");

    public SetupView () {
        Object (
            column_spacing: 6,
            halign: Gtk.Align.CENTER,
            margin: 12,
            row_spacing: 12
        );
    }

    construct {
        info_label = new Gtk.Label (null);
        info_label.max_width_chars = 50;
        info_label.use_markup = true;
        info_label.wrap = true;

        desqueezer = new GstreamerDesqueezer ();

        var arrow = new Gtk.Image.from_icon_name ("go-next-symbolic", Gtk.IconSize.BUTTON);

        var button = new Gtk.Button.with_label ("De-squeeze");
        button.halign = Gtk.Align.END;
        button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        attach (desqueezer.input_preview_area, 0, 0);
        attach (arrow, 1, 0);
        attach (desqueezer.output_preview_area, 2, 0);
        attach (info_label, 0, 1, 3);
        attach (button, 1, 1, 2);

        button.clicked.connect (() => {
            desqueeze_file (file_uri, output_path);
        });
    }

    public void set_uri (string uri) {
        file_uri = uri;

        desqueezer.set_file (uri);
        var file = File.new_for_uri (uri);
        var basename = file.get_basename ();
        basename = basename.substring (0, basename.last_index_of ("."));
        basename = Markup.escape_text (basename);
        var output_filename = basename + ".desqueezed.webm";

        info_label.label = LABEL_TEMPLATE.printf (output_filename);

        output_path = Path.build_filename (file.get_parent ().get_path (), output_filename);
    }
}

