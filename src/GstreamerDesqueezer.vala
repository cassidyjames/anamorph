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

    private GstreamerMetadataReader metadata_reader;

    private Gst.Element input_preview_gtk_sink;
    private Gst.Element output_preview_gtk_sink;

    private Gst.Pipeline pipeline;
    private Gst.Element tee;

    construct {
        metadata_reader = new GstreamerMetadataReader (input_path);
        metadata_reader.ready.connect (construct_pipelines);
        metadata_reader.read ();

        input_preview_gtk_sink = Gst.ElementFactory.make ("gtksink", "input_preview");
        output_preview_gtk_sink = Gst.ElementFactory.make ("gtksink", "output_preview");

        input_preview_gtk_sink.get ("widget", out _input_preview_area);
        output_preview_gtk_sink.get ("widget", out _output_preview_area);
    }

    private void construct_pipelines () {
        pipeline = new Gst.Pipeline (null);
        pipeline.get_bus ().add_watch (Priority.DEFAULT, on_bus_message);

        var decodebin = Gst.ElementFactory.make ("uridecodebin", "input");
        tee = Gst.ElementFactory.make ("tee", "splitter");
        var output_convert = Gst.ElementFactory.make ("videoconvert", "output_converter");
        var input_convert = Gst.ElementFactory.make ("videoconvert", "input_converter");
        var input_queue = Gst.ElementFactory.make ("queue", "input_queue");
        var output_queue = Gst.ElementFactory.make ("queue", "output_queue");
        var output_scaler = Gst.ElementFactory.make ("vaapipostproc", "output_scaler");
        var input_scaler = Gst.ElementFactory.make ("vaapipostproc", "input_scaler");
        if (input_scaler == null) {
            warning ("falling back to software scaler");
            input_scaler = Gst.ElementFactory.make ("videoscale", "input_scaler");
        }

        if (output_scaler == null) {
            output_scaler = Gst.ElementFactory.make ("videoscale", "output_scaler");
        }

        var input_caps_filter = Gst.ElementFactory.make ("capsfilter", "input_filter");
        var output_caps_filter = Gst.ElementFactory.make ("capsfilter", "output_filter");

        var input_caps = new Gst.Caps.simple ("video/x-raw", 
            "width", typeof(int), metadata_reader.video_width, 
            "height", typeof(int), metadata_reader.video_height,
            "pixel-aspect-ratio", typeof(Gst.Fraction), 1, 1
        );

        var output_caps = new Gst.Caps.simple ("video/x-raw", 
            "width", typeof(int), (int)(metadata_reader.video_width * 1.33f),
            "height", typeof(int), metadata_reader.video_height, 
            "pixel-aspect-ratio", typeof (Gst.Fraction), 1, 1
        );

        input_caps_filter["caps"] = input_caps;
        output_caps_filter["caps"] = output_caps;

        input_scaler["add-borders"] = false;
        output_scaler["add-borders"] = false;

        pipeline.add_many (decodebin, tee, input_queue, output_queue, input_scaler, output_scaler, input_caps_filter, output_caps_filter, output_convert, input_convert, input_preview_gtk_sink, output_preview_gtk_sink);

        decodebin.pad_added.connect (on_pad_added);

        var input_split = tee.get_request_pad ("src_%u");
        var output_split = tee.get_request_pad ("src_%u");

        input_split.link (input_queue.get_static_pad ("sink"));
        output_split.link (output_queue.get_static_pad ("sink"));

        input_queue.link_many (input_scaler, input_caps_filter, input_convert, input_preview_gtk_sink);
        output_queue.link_many (output_scaler, output_caps_filter, output_convert, output_preview_gtk_sink);

        decodebin["uri"] = input_path;
    }

    private void on_pad_added (Gst.Element src, Gst.Pad pad) {
        var sink_pad = tee.get_static_pad ("sink");
        if (sink_pad.is_linked ()) {
            return;
        }

        var new_pad_caps = pad.query_caps (null);
        weak Gst.Structure new_pad_struct = new_pad_caps.get_structure (0);
        var new_pad_type = new_pad_struct.get_name ();
        warning (new_pad_type);
        if (new_pad_type.has_prefix ("video/x-raw")) {
            pad.link (sink_pad);
        }
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
