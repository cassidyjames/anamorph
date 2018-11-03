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

public class Anamorph : Gtk.Application {
    public const string ID = "com.github.cassidyjames.anamorph";
    public const string PATH = "/com/github/cassidyjames/anamorph/";
    public const string MOMENT_REFERRAL = "https://www.shopmoment.com/shop?tap_a=30146-d3ce98&tap_s=363496-01e37a&utm_medium=referral&utm_source=ambassador&utm_campaign=Moment%2BReferral%2BProgram&utm_content=cassidyblaede";

    public Anamorph () {
        Object (
          application_id: ID,
          flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        if (get_windows ().length () > 0) {
            get_windows ().data.present ();
            return;
        }

        var main_window = new MainWindow (this);

        var quit_action = new SimpleAction ("quit", null);

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Ctrl>q"});

        quit_action.activate.connect (() => {
            if (main_window != null) {
                main_window.destroy ();
            }
        });

        // CSS provider
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource (PATH + "Application.css");
        Gtk.StyleContext.add_provider_for_screen (
          Gdk.Screen.get_default (),
          provider,
          Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
        main_window.show_all ();
    }

    private static int main (string[] args) {
        Gtk.init (ref args);

        var app = new Anamorph ();
        return app.run (args);
    }
}

