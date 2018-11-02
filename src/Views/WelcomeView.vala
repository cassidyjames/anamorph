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
    public WelcomeView () {
        Object (
            column_spacing: 6,
            halign: Gtk.Align.CENTER,
            margin_bottom: 12,
            margin_end: 12,
            margin_start: 12,
            row_spacing: 12
        );
    }

    construct {
        var label = new Gtk.Label ("Welcome");
        label.max_width_chars = 50;
        label.use_markup = true;
        label.wrap = true;

        attach (label, 0, 0);
    }
}

