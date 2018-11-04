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
* Authored by: David Hewitt <davidmhewitt@gmail.com>
*/

public class GstreamerDesqueezer : Object {
    public string input_path { get; set construct; }

    private Gtk.Widget? _input_preview_area;
    public Gtk.Widget? input_preview_area {
        get {
            return _input_preview_area;
        }
        private set {
            _input_preview_area = value;
        }
    }

    private Gtk.Widget? _output_preview_area;
    public Gtk.Widget? output_preview_area {
        get {
            return _output_preview_area;
        }
        private set {
            _output_preview_area = value;
        }
    }

    public GstreamerDesqueezer (string path) {
        Object (input_path: path);
    }

    private Gst.Pipeline pipeline;

    construct {
        pipeline = new Gst.Pipeline (null);
        pipeline.get_bus ().add_watch (Priority.DEFAULT, on_bus_message);

        var decodebin = Gst.ElementFactory.make ("uridecodebin", "input");
        var tee = Gst.ElementFactory.make ("tee", "splitter");
        var converter = Gst.ElementFactory.make ("videoconvert", "converter");
        var input_preview_gtk_sink = Gst.ElementFactory.make ("gtksink", "input_preview");
        var output_preview_gtk_sink = Gst.ElementFactory.make ("gtksink", "output_preview");
        var input_queue = Gst.ElementFactory.make ("queue", "input_queue");
        var output_queue = Gst.ElementFactory.make ("queue", "output_queue");

        input_preview_gtk_sink.get ("widget", out _input_preview_area);
        output_preview_gtk_sink.get ("widget", out _output_preview_area);

        pipeline.add_many (decodebin, tee, converter, input_queue, output_queue, input_preview_gtk_sink, output_preview_gtk_sink);

        decodebin.pad_added.connect ((pad) => { 
            var pad_link_return = pad.link (converter.get_static_pad ("sink")); 
        });

        var input_split = tee.get_request_pad ("src_%u");
        var output_split = tee.get_request_pad ("src_%u");

        input_split.link (input_queue.get_static_pad ("sink"));
        output_split.link (output_queue.get_static_pad ("sink"));

        input_queue.link (input_preview_gtk_sink);
        output_queue.link (output_preview_gtk_sink);

        decodebin["uri"] = input_path;
        converter.link (tee);
    }

    private bool on_bus_message (Gst.Bus bus, Gst.Message message) {
        switch (message.type) {
            case Gst.MessageType.ERROR:
                string error_message;
                Error error_object;
                message.parse_error (out error_object, out error_message);
                warning ("%s, %s", error_message, error_object.message);
                break;
            default:
                break;
        }

        return true;
    }

    public void play () {
        pipeline.set_state (Gst.State.PLAYING);
    }
}
