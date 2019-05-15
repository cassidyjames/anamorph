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

public class WelcomeView : Gtk.Grid {
    public signal void open_file (string path);
    public Gtk.Stack stack { get; construct; }

    public WelcomeView () {
        Object (
            halign: Gtk.Align.FILL
        );
    }

    construct {
        var welcome = new Granite.Widgets.Welcome (
            "De-Squeeze",
            "Open a video to get started."
        );
        welcome.append (
            "folder-videos",
            "Open Video",
            "Load a video to de-squeeze."
        );
        welcome.append (
            "payment-card",
            "Get a Lens",
            "Save 10% on an Anamorphic Lens from Moment."
        );

        add (welcome);

        welcome.activated.connect ((index) => {
            switch (index) {
                case 0:
                    var filter = new Gtk.FileFilter ();
                    filter.add_mime_type ("video/*");

                    var chooser = new Gtk.FileChooserNative (
                        _("Open Video"),
                        get_parent_window () as Gtk.Window?,
                        Gtk.FileChooserAction.OPEN,
                        _("_Open"),
                        _("_Cancel")
                    );

                    chooser.add_filter (filter);

                    if (chooser.run () == Gtk.ResponseType.ACCEPT) {
                        open_file (chooser.get_uri ());
                    }

                    break;
                case 1:
                    try {
                        AppInfo.launch_default_for_uri (Anamorph.MOMENT_REFERRAL, null);
                    } catch (Error e) {
                        warning (e.message);
                    }

                    break;
            }
        });
    }
}

