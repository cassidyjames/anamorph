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
    public Gtk.Stack stack { get; construct; }

    public WelcomeView (Gtk.Stack _stack) {
        Object (
            halign: Gtk.Align.FILL,
            stack: _stack
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
            "Buy gear from Moment and help support Anamorph."
        );

        add (welcome);

        welcome.activated.connect ((index) => {
            switch (index) {
                case 0:
                    stack.visible_child_name = "setup";

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

