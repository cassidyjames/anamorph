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

        var stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        var welcome_view = new WelcomeView ();
        stack.add_titled (welcome_view, "welcome", "Welcome");

        var setup_view = new SetupView ();
        stack.add_titled (setup_view, "setup", "Setup");

        var progress_view = new ProgressView ();
        stack.add_titled (progress_view, "progress", "Progress");

        var success_view = new SuccessView ();
        stack.add_titled (success_view, "success", "Success");

        var error_view = new ErrorView ();
        stack.add_titled (error_view, "error", "Error");

        // FIXME: Temporary for prototyping/debugging
        var switcher = new Gtk.StackSwitcher ();
        switcher.halign = Gtk.Align.CENTER;
        switcher.margin_bottom = 12;
        switcher.stack = stack;

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (switcher);
        grid.add (stack);

        add (grid);
        set_titlebar (header);
    }
}

