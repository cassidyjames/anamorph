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

public class ErrorView : Gtk.Grid {
    public Gtk.Stack stack { get; construct; }

    public ErrorView (Gtk.Stack _stack) {
        Object (
            halign: Gtk.Align.FILL,
            stack: _stack
        );
    }

    construct {
        var welcome = new Granite.Widgets.Welcome (
            "✖ Uh-Oh",
            "Your video has not been de-squeezed."
        );
        welcome.get_style_context ().add_class ("error");
        welcome.append (
            "view-refresh",
            "Try Again",
            "Attempt to de-squeeze with the same settings."
        );
        welcome.append (
            "go-previous",
            "Go Back",
            "Go back to change settings."
        );

        add (welcome);

        welcome.activated.connect ((index) => {
            switch (index) {
                case 0:
                    try {
                        critical ("not implemented");
                    } catch (Error e) {
                        warning (e.message);
                    }

                    break;
                case 1:
                    stack.visible_child_name = "welcome";
                    break;
            }
        });
    }
}

