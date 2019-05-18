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
    public Gtk.Stack stack { get; construct; }
    private GstreamerDesqueezer desqueezer;

    public SetupView (Gtk.Stack _stack) {
        Object (
            column_spacing: 6,
            halign: Gtk.Align.CENTER,
            margin: 12,
            row_spacing: 12,
            stack: _stack
        );
    }

    construct {
        // TODO: Use real filename
        var label = new Gtk.Label ("De-squeezing will create a new file named <b>video.desqueezed.mp4</b> alongside the input file.");
        label.max_width_chars = 50;
        label.use_markup = true;
        label.wrap = true;

        desqueezer = new GstreamerDesqueezer ();

        var arrow = new Gtk.Image.from_icon_name ("go-next-symbolic", Gtk.IconSize.BUTTON);

        var button = new Gtk.Button.with_label ("De-squeeze");
        button.halign = Gtk.Align.END;
        button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        attach (desqueezer.input_preview_area, 0, 0);
        attach (arrow,          1, 0);
        attach (desqueezer.output_preview_area,          2, 0);
        attach (label,          0, 1, 3);
        attach (button,         1, 1, 2);

        button.clicked.connect (() => {
            desqueezer.play ();
            //stack.visible_child_name = "success";
        });
    }

    public void open_file (string path) {
        desqueezer.set_file (path);
    }
}

