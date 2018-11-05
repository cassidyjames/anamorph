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

public class GstreamerMetadataReader : Object {
    public signal void ready ();

    public string input_path { get; construct; }

    public int video_width;
    public int video_height;

    private bool ready_fired = false;

    public GstreamerMetadataReader (string path) {
        Object (input_path: path);
    }

    public void read () {
        var pipeline = new Gst.Pipeline (null);

        var decodebin = Gst.ElementFactory.make ("uridecodebin", "input");
        var fakesink = Gst.ElementFactory.make ("fakesink", "fakesink");
        pipeline.add_many (decodebin, fakesink);
        decodebin.pad_added.connect ((pad) => {
            var sink_pad = fakesink.get_static_pad ("sink");
            if (sink_pad.is_linked ()) return;

            var new_pad_caps = pad.query_caps (null);
            weak Gst.Structure new_pad_struct = new_pad_caps.get_structure (0);
            var new_pad_type = new_pad_struct.get_name ();
            if (new_pad_type.has_prefix ("video/x-raw")) {
                pad.link (sink_pad);
            }
        });

        fakesink.get_static_pad ("sink").notify["caps"].connect (() => {
            if (ready_fired) return;

            var sink_caps = fakesink.get_static_pad ("sink").caps;
            weak Gst.Structure? caps_struct = sink_caps.get_structure (0);
            
            caps_struct.get_int ("width", out video_width);
            caps_struct.get_int ("height", out video_height);

            if (video_width != 0 && video_height != 0) {
                ready_fired = true;
                ready ();
            }
        });

        decodebin["uri"] = input_path;
        decodebin.link (fakesink);
        pipeline.set_state (Gst.State.PAUSED);
    }
}
