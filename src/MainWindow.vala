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

public class MainWindow : Gtk.Window {
    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            // border_width: 12,
            icon_name: Anamorph.ID,
            resizable: false,
            title: _("Anamorph"),
            window_position: Gtk.WindowPosition.CENTER
        );
    }

    construct {
        var context = get_style_context ();
        context.add_class ("anamorph");
        context.add_class ("rounded");

        var header = new Gtk.HeaderBar ();
        header.show_close_button = true;

        var header_context = header.get_style_context ();
        header_context.add_class ("titlebar");
        header_context.add_class ("default-decoration");
        header_context.add_class (Gtk.STYLE_CLASS_FLAT);

        // TODO: Use real filename
        var label = new Gtk.Label ("De-squeezing will create a new file named <b>video.desqueezed.mp4</b> alongside the input file.");
        label.max_width_chars = 50;
        label.use_markup = true;
        label.wrap = true;

        var squeezed_image = new Gtk.Image.from_resource (Anamorph.PATH + "preview-squeezed.jpg");
        squeezed_image.get_style_context ().add_class ("thumb");

        var arrow = new Gtk.Image.from_icon_name ("go-next-symbolic", Gtk.IconSize.BUTTON);

        var image = new Gtk.Image.from_resource (Anamorph.PATH + "preview.jpg");
        image.valign = Gtk.Align.CENTER;
        image.get_style_context ().add_class ("thumb");

        var letterbox_switch = new Gtk.Switch ();
        letterbox_switch.get_style_context ().add_class (Granite.STYLE_CLASS_MODE_SWITCH);
        letterbox_switch.bind_property (
            "active",
            image,
            "valign",
            BindingFlags.SYNC_CREATE,
            letterbox_transform_func
        );

        var fullscreen_label = new Gtk.Label ("""<span size="smaller" weight="600">%s</span>""".printf ("FULLSCREEN"));
        fullscreen_label.use_markup = true;

        var letterbox_label = new Gtk.Label ("""<span size="smaller" weight="600">%s</span>""".printf ("LETTERBOX"));
        letterbox_label.use_markup = true;

        var letterbox_grid = new Gtk.Grid ();
        letterbox_grid.column_spacing = 6;
        letterbox_grid.halign = Gtk.Align.START;
        letterbox_grid.valign = Gtk.Align.END;

        letterbox_grid.add (fullscreen_label);
        letterbox_grid.add (letterbox_switch);
        letterbox_grid.add (letterbox_label);

        var button = new Gtk.Button.with_label ("De-squeeze");
        button.halign = Gtk.Align.END;
        button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.halign = grid.valign = Gtk.Align.CENTER;
        grid.margin_bottom = 12;
        grid.margin_start = grid.margin_end = 12;
        grid.row_spacing = 24;

        grid.attach (squeezed_image, 0, 0);
        grid.attach (arrow,          1, 0);
        grid.attach (image,          2, 0);
        grid.attach (label,          0, 1, 3);
        grid.attach (letterbox_grid, 0, 2);
        grid.attach (button,         1, 2, 2);

        set_titlebar (header);
        add (grid);
    }

    private bool letterbox_transform_func (Binding binding, Value source_value, ref Value target_value) {
        if (source_value == true) {
            target_value = Gtk.Align.FILL;
        } else {
            target_value = Gtk.Align.CENTER;
        }

        return true;
    }
}

