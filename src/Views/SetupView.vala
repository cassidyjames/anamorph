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
    public SetupView () {
        Object (
            column_spacing: 6,
            halign: Gtk.Align.CENTER,
            margin: 12,
            row_spacing: 12
        );
    }

    construct {
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

        var fullscreen_label = new Gtk.Label ("""<span size="x-small" weight="bold">%s</span>""".printf ("FULLSCREEN"));
        fullscreen_label.tooltip_text = "Video will be desqueezed and resized to its natural height";
        fullscreen_label.use_markup = true;

        var fullscreen_box = new Gtk.EventBox ();
        fullscreen_box.add_events (Gdk.EventMask.BUTTON_RELEASE_MASK);
        fullscreen_box.add (fullscreen_label);
        fullscreen_box.button_release_event.connect (() => {
            letterbox_switch.active = false;
            return Gdk.EVENT_STOP;
        });

        var letterbox_label = new Gtk.Label ("""<span size="x-small" weight="bold">%s</span>""".printf ("LETTERBOX"));
        letterbox_label.tooltip_text = "Video will be desqueezed and black bars added to keep its original height";
        letterbox_label.use_markup = true;

        var letterbox_box = new Gtk.EventBox ();
        letterbox_box.add_events (Gdk.EventMask.BUTTON_RELEASE_MASK);
        letterbox_box.add (letterbox_label);
        letterbox_box.button_release_event.connect (() => {
            letterbox_switch.active = true;
            return Gdk.EVENT_STOP;
        });

        var letterbox_grid = new Gtk.Grid ();
        letterbox_grid.column_spacing = 6;
        letterbox_grid.halign = Gtk.Align.START;
        letterbox_grid.valign = Gtk.Align.END;

        letterbox_grid.add (fullscreen_box);
        letterbox_grid.add (letterbox_switch);
        letterbox_grid.add (letterbox_box);

        var button = new Gtk.Button.with_label ("De-squeeze");
        button.halign = Gtk.Align.END;
        button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        attach (squeezed_image, 0, 0);
        attach (arrow,          1, 0);
        attach (image,          2, 0);
        attach (label,          0, 1, 3);
        attach (letterbox_grid, 0, 2);
        attach (button,         1, 2, 2);

        button.clicked.connect (() => {
            // TODO: Do the thing, then go to success/error view
            critical ("Clicky");
        });
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

