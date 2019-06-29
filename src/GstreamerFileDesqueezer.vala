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

    public struct AudioStreamCaps {
        string stream_id;
        Gst.Caps caps;
        Gst.Pad corresponding_pad;
    }

    public GstreamerFileDesqueezer (string uri, string output_path, Fraction stretch_factor = {4, 3}) {
        Object (
            input_uri: uri,
            output_path: output_path,
            stretch_factor: stretch_factor
        );
    }

    private Gst.Pipeline pipeline;
    private Gst.Element encodebin;
    private Gst.Element progress_report;
    protected Gee.ArrayList<AudioStreamCaps?> audio_caps = new Gee.ArrayList<AudioStreamCaps?> ();
    private Gee.HashSet<string> used_stream_ids = new Gee.HashSet<string> ();
    private Gst.Pad[] audio_pads;
    protected string video_stream_id;
    private Gst.PbUtils.EncodingContainerProfile encodebin_profile;

    construct {
        // Media discoverer with a 5 second timeout
        var discoverer = new Gst.PbUtils.Discoverer (5 * Gst.SECOND);
        discoverer.discovered.connect (construct_pipelines);
        discoverer.start ();
        discoverer.discover_uri_async (input_uri);
    }

    private void construct_pipelines (Gst.PbUtils.DiscovererInfo info) {
        if (info.get_result () != Gst.PbUtils.DiscovererResult.OK) {
            critical ("Error while reading input metadata");
            // TODO: show error screen
        }

        // Get all of the information about the input stream
        uint par_num = 0, par_denom = 0;
        Gst.Caps? container_caps = null, video_caps = null;
        if (info.get_stream_info () is Gst.PbUtils.DiscovererContainerInfo) {
            var container = info.get_stream_info () as Gst.PbUtils.DiscovererContainerInfo;
            container_caps = container.get_caps ();
            warning (container_caps.to_string ());
            container.get_streams ().foreach ((stream) => {
                if (stream is Gst.PbUtils.DiscovererVideoInfo && video_caps == null) {
                    var video_stream = stream as Gst.PbUtils.DiscovererVideoInfo;
                    video_stream_id = video_stream.get_stream_id ();
                    video_caps = video_stream.get_caps ();
                    par_num = video_stream.get_par_num ();
                    par_denom = video_stream.get_par_denom ();
                } else if (stream is Gst.PbUtils.DiscovererAudioInfo) {
                    var audio_stream = stream as Gst.PbUtils.DiscovererAudioInfo;
                    audio_caps.add ({audio_stream.get_stream_id (), audio_stream.get_caps ()});
                }
            });
        }

        pipeline = new Gst.Pipeline (null);
        pipeline.set_state (Gst.State.PAUSED);
        pipeline.get_bus ().add_watch (Priority.DEFAULT, on_bus_message);

        // Set up an encoding profile that perfectly matches the source to avoid re-encoding
        encodebin_profile = new Gst.PbUtils.EncodingContainerProfile ("containerformat", null, container_caps, null);
        var video_profile = new Gst.PbUtils.EncodingVideoProfile (video_caps, null, null, 0);
        encodebin_profile.add_profile (video_profile);

        audio_pads = new Gst.Pad[audio_caps.size];
        for (int x = 0; x < audio_caps.size; x++) {
            var audio_profile = new Gst.PbUtils.EncodingAudioProfile (audio_caps[x].caps, null, null, 0);
            audio_profile.set_name ("audioprofilename" + x.to_string ());
            encodebin_profile.add_profile (audio_profile);
        }

        encodebin = Gst.ElementFactory.make ("encodebin", "output");
        encodebin["profile"] = encodebin_profile;
        encodebin["avoid-reencoding"] = true;
        pipeline.add (encodebin);
        encodebin.set_state (Gst.State.PAUSED);

        for (int i = 0; i < audio_caps.size; i++) {
            Gst.Pad audio_pad;
            Signal.emit_by_name (encodebin, "request-profile-pad", "audioprofilename" + i.to_string (), out audio_pad);
            audio_pads[i] = audio_pad;
        }

        var decodebin = Gst.ElementFactory.make ("uridecodebin", "input");
        decodebin.connect ("signal::autoplug-continue", on_autoplug_continue, this, null);
        decodebin.pad_added.connect (on_pad_added);
        decodebin["uri"] = input_uri;
        pipeline.add (decodebin);
        decodebin.set_state (Gst.State.PAUSED);

        progress_report = Gst.ElementFactory.make ("progressreport", "progress_report");
        progress_report["silent"] = true;
        progress_report["update-freq"] = 1;

        // video_queue = Gst.ElementFactory.make ("queue", "video_queue");
        // audio_queue = Gst.ElementFactory.make ("queue", "audio_queue");

        // // Try using a hardware accelerated scaler
        // var video_scaler = Gst.ElementFactory.make ("vaapipostproc", "video_scaler");

        // // If it's not available, fall back to software
        // if (video_scaler == null) {
        //     warning ("falling back to software scaler");
        //     video_scaler = Gst.ElementFactory.make ("videoscale", "video_scaler");
        //     video_scaler["add-borders"] = false;
        // }

        // var video_caps_filter = Gst.ElementFactory.make ("capsfilter", "video_caps_filter");
        // var video_caps = new Gst.Caps.simple ("video/x-raw",
        //     "width", typeof(int), (int)(metadata_reader.video_width),
        //     "height", typeof(int), metadata_reader.video_height,
        //     "pixel-aspect-ratio", typeof (Gst.Fraction), stretch_factor.numerator, stretch_factor.denominator
        // );

        // video_caps_filter["caps"] = video_caps;

        // var video_convert = Gst.ElementFactory.make ("videoconvert", "video_convert");
        // var audio_convert = Gst.ElementFactory.make ("audioconvert", "audio_convert");

        // var video_encode = Gst.ElementFactory.make ("vp8enc", "video_encode");
        // // VPX_DL_GOOD_QUALITY (https://github.com/webmproject/libvpx/blob/a5d499e16570d00d5e1348b1c7977ced7af3670f/vpx/vpx_encoder.h#L848)
        // video_encode["deadline"] = 1000000;
        // // Vary this parameter to adjust trade off between encode time and quality
        // // 5 is fastest (lowest quality), while 0 is longest (best quality)
        // video_encode["cpu-used"] = speed_value;
        // var audio_encode = Gst.ElementFactory.make ("vorbisenc", "audio_encode");

        // var webm_mux = Gst.ElementFactory.make ("webmmux", "webm_mux");
        var file_sink = Gst.ElementFactory.make ("filesink", "file_sink");
        file_sink["location"] = output_path;
        pipeline.add (file_sink);
        encodebin.link (file_sink);

        // pipeline.add_many (
        //     decodebin, progress_report, // Decode the input file/stream
        //     video_queue, video_scaler, video_caps_filter, video_convert, video_encode, // Video pipeline
        //     audio_queue, audio_convert, audio_encode, // Audio pipline
        //     webm_mux, file_sink // File output
        // );

        // decodebin.pad_added.connect (on_pad_added);

        // video_queue.link_many (progress_report, video_scaler, video_caps_filter, video_convert, video_encode, webm_mux);
        // audio_queue.link_many (audio_convert, audio_encode, webm_mux);
        // webm_mux.link (file_sink);

        decodebin.no_more_pads.connect (() => {
            Idle.add (() => {
                warning ("trying to play");
                pipeline.set_state (Gst.State.PLAYING);
                Gst.Debug.bin_to_dot_file (pipeline, Gst.DebugGraphDetails.ALL, "debug");
                return false;
            });
        });
    }

    private static bool on_autoplug_continue (Gst.Element uridecodebin, Gst.Pad pad, Gst.Caps caps, GstreamerFileDesqueezer instance) {
        var event = pad.get_sticky_event (Gst.EventType.STREAM_START, 0);
        if (event != null) {
            string stream_id = "";
            event.parse_stream_start (out stream_id);
            foreach (var audio_stream in instance.audio_caps) {
                if (stream_id == audio_stream.stream_id) {
                    return false;
                }
            }

            if (stream_id == instance.video_stream_id) {
                return false;
            }

            var capsvalue = caps.to_string ();
            if (capsvalue.has_prefix ("subtitle/")) {
                return false;
            }

            if (capsvalue.has_prefix ("audio/")) {
                return false;
            }

            return true;
        } else {
            return true;
        }
    }

    private void on_pad_added (Gst.Element src, Gst.Pad pad) {
        var origin = pad.query_caps (null);
        var c = origin.to_string ();
        warning (c);
        if (c.has_prefix ("video/") || c.has_prefix ("image/")) {
            warning ("linking video pad");
            Gst.Pad video_pad;
            Signal.emit_by_name (encodebin, "request-pad", origin, out video_pad);
            pad.link (video_pad);
            return;
        }

        if (c.has_prefix ("audio/")) {
            pad.add_probe (Gst.PadProbeType.EVENT_DOWNSTREAM, padprobe);
            return;
        }
    }

    private Gst.PadProbeReturn padprobe (Gst.Pad pad, Gst.PadProbeInfo info) {
        var event = info.get_event ();
        if (event.type == Gst.EventType.STREAM_START) {
            string probe_stream_id;
            event.parse_stream_start (out probe_stream_id);
            int x = 0;
            while (x < audio_caps.size) {
                if (probe_stream_id == audio_caps[x].stream_id) {
                    if (!(probe_stream_id in used_stream_ids)) {
                        used_stream_ids.add (probe_stream_id);
                        warning (pad.link (audio_pads[x]).to_string ());
                    }
                }

                x++;
            }
        }

        return Gst.PadProbeReturn.OK;
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
