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

public class GstreamerFileDesqueezer : Object {
    public signal void complete ();
    public signal void progress (double progress);

    public string input_uri { get; construct; }
    public string output_path { get; construct; }
    public Fraction stretch_factor { get; set construct; }
    public uint speed_value { get; construct; }

    public GstreamerFileDesqueezer (string uri, string output_path, Fraction stretch_factor = {4, 3}, uint speed = 5) {
        Object (
            input_uri: uri,
            output_path: output_path,
            stretch_factor: stretch_factor,
            speed_value: speed
        );
    }

    private GstreamerMetadataReader metadata_reader;

    private Gst.Pipeline pipeline;
    private Gst.Element video_queue;
    private Gst.Element audio_queue;
    private Gst.Element progress_report;

    construct {
        metadata_reader = new GstreamerMetadataReader (input_uri);
        metadata_reader.ready.connect (construct_pipelines);
        metadata_reader.read ();
    }

    private void construct_pipelines () {
        pipeline = new Gst.Pipeline (null);
        pipeline.get_bus ().add_watch (Priority.DEFAULT, on_bus_message);

        var decodebin = Gst.ElementFactory.make ("uridecodebin", "input");
        progress_report = Gst.ElementFactory.make ("progressreport", "progress_report");
        progress_report["silent"] = true;
        progress_report["update-freq"] = 1;

        video_queue = Gst.ElementFactory.make ("queue", "video_queue");
        audio_queue = Gst.ElementFactory.make ("queue", "audio_queue");

        // Try using a hardware accelerated scaler
        var video_scaler = Gst.ElementFactory.make ("vaapipostproc", "video_scaler");

        // If it's not available, fall back to software
        if (video_scaler == null) {
            warning ("falling back to software scaler");
            video_scaler = Gst.ElementFactory.make ("videoscale", "video_scaler");
            video_scaler["add-borders"] = false;
        }

        var video_caps_filter = Gst.ElementFactory.make ("capsfilter", "video_caps_filter");
        var video_caps = new Gst.Caps.simple ("video/x-raw",
            "width", typeof(int), (int)(metadata_reader.video_width),
            "height", typeof(int), metadata_reader.video_height,
            "pixel-aspect-ratio", typeof (Gst.Fraction), stretch_factor.numerator, stretch_factor.denominator
        );

        video_caps_filter["caps"] = video_caps;

        var video_convert = Gst.ElementFactory.make ("videoconvert", "video_convert");
        var audio_convert = Gst.ElementFactory.make ("audioconvert", "audio_convert");

        var video_encode = Gst.ElementFactory.make ("vp8enc", "video_encode");
        // VPX_DL_GOOD_QUALITY (https://github.com/webmproject/libvpx/blob/a5d499e16570d00d5e1348b1c7977ced7af3670f/vpx/vpx_encoder.h#L848)
        video_encode["deadline"] = 1000000;
        // Vary this parameter to adjust trade off between encode time and quality
        // 5 is fastest (lowest quality), while 0 is longest (best quality)
        video_encode["cpu-used"] = speed_value;
        var audio_encode = Gst.ElementFactory.make ("vorbisenc", "audio_encode");

        var webm_mux = Gst.ElementFactory.make ("webmmux", "webm_mux");
        var file_sink = Gst.ElementFactory.make ("filesink", "file_sink");
        file_sink["location"] = output_path;
        file_sink["sync"] = false;

        pipeline.add_many (
            decodebin, progress_report, // Decode the input file/stream
            video_queue, video_scaler, video_caps_filter, video_convert, video_encode, // Video pipeline
            audio_queue, audio_convert, audio_encode, // Audio pipline
            webm_mux, file_sink // File output
        );

        decodebin.pad_added.connect (on_pad_added);

        video_queue.link_many (progress_report, video_scaler, video_caps_filter, video_convert, video_encode, webm_mux);
        audio_queue.link_many (audio_convert, audio_encode, webm_mux);
        webm_mux.link (file_sink);

        decodebin["uri"] = input_uri;

        pipeline.set_state (Gst.State.PLAYING);
    }

    private void on_pad_added (Gst.Element src, Gst.Pad pad) {
        var video_sink_pad = video_queue.get_static_pad ("sink");
        var audio_sink_pad = audio_queue.get_static_pad ("sink");

        if (video_sink_pad.is_linked () && audio_sink_pad.is_linked ()) {
            return;
        }

        var new_pad_caps = pad.query_caps (null);
        weak Gst.Structure new_pad_struct = new_pad_caps.get_structure (0);
        var new_pad_type = new_pad_struct.get_name ();
        if (new_pad_type.has_prefix ("video/x-raw")) {
            pad.link (video_sink_pad);
        }

        if (new_pad_type.has_prefix ("audio")) {
            pad.link (audio_sink_pad);
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
            case Gst.MessageType.EOS:
                complete ();
                break;
            case Gst.MessageType.ELEMENT:
                if (message.src == progress_report) {
                    unowned Gst.Structure? structure = message.get_structure ();
                    if (structure != null) {
                        double percent;
                        if (structure.get_double ("percent-double", out percent)) {
                            progress (percent);
                        }
                    }
                }
                break;
            default:
                break;
        }

        return true;
    }
}
