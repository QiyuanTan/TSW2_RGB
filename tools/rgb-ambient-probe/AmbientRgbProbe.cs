using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Threading;
using Windows.Devices.Enumeration;
using Windows.Devices.Lights;
using Windows.Foundation;
using Windows.System;

internal static class AmbientRgbProbe
{
    private sealed class ProbeKey
    {
        internal VirtualKey Key;
        internal byte Red;
        internal byte Green;
        internal byte Blue;
    }

    private static readonly ProbeKey[] ProbeKeys =
    {
        Key(VirtualKey.Escape, 255, 0, 0),
        Key(VirtualKey.A, 255, 96, 0),
        Key(VirtualKey.D, 255, 255, 0),
        Key(VirtualKey.G, 0, 255, 0),
        Key(VirtualKey.J, 0, 255, 255),
        Key(VirtualKey.L, 0, 96, 255),
        Key(VirtualKey.Space, 96, 0, 255),
        Key(VirtualKey.Left, 255, 0, 255),
        Key(VirtualKey.Down, 255, 64, 128),
        Key(VirtualKey.Right, 255, 255, 255)
    };

    private static volatile bool stopping;

    private static ProbeKey Key(VirtualKey key, byte red, byte green, byte blue)
    {
        return new ProbeKey { Key = key, Red = red, Green = green, Blue = blue };
    }

    private static void Diagnostic(string code, string message, string level = "info")
    {
        Console.WriteLine("{{\"level\":\"{0}\",\"code\":\"{1}\",\"message\":\"{2}\"}}",
            Escape(level), Escape(code), Escape(message));
    }

    private static string Escape(string value)
    {
        return value.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", "\\r").Replace("\n", "\\n");
    }

    private static int ArgumentInt(string[] args, string name, int fallback, int minimum, int maximum)
    {
        int index = Array.FindIndex(args, value => string.Equals(value, name, StringComparison.OrdinalIgnoreCase));
        int parsed;
        if (index < 0) return fallback;
        if (index + 1 >= args.Length || !int.TryParse(args[index + 1], out parsed) || parsed < minimum || parsed > maximum)
            throw new ArgumentException(name + " must be an integer from " + minimum + " through " + maximum + ".");
        return parsed;
    }

    private static string Argument(string[] args, string name, string fallback)
    {
        int index = Array.FindIndex(args, value => string.Equals(value, name, StringComparison.OrdinalIgnoreCase));
        if (index < 0) return fallback;
        if (index + 1 >= args.Length) throw new ArgumentException(name + " requires a value.");
        return args[index + 1];
    }

    private static bool HasArgument(string[] args, string name)
    {
        return args.Any(value => string.Equals(value, name, StringComparison.OrdinalIgnoreCase));
    }

    private static byte[] Hsv(double hue)
    {
        double scaled = hue * 6.0;
        int sector = (int)Math.Floor(scaled) % 6;
        double fraction = scaled - Math.Floor(scaled);
        byte a = (byte)Math.Round(255 * (1 - fraction));
        byte b = (byte)Math.Round(255 * fraction);
        switch (sector)
        {
            case 0: return new byte[] { 255, b, 0 };
            case 1: return new byte[] { a, 255, 0 };
            case 2: return new byte[] { 0, 255, b };
            case 3: return new byte[] { 0, a, 255 };
            case 4: return new byte[] { b, 0, 255 };
            default: return new byte[] { 255, 0, a };
        }
    }

    private static dynamic CreateColor(byte red, byte green, byte blue)
    {
        Type colorType = typeof(LampArray).GetMethod("SetColor").GetParameters()[0].ParameterType;
        dynamic color = Activator.CreateInstance(colorType);
        color.A = (byte)255;
        color.R = red;
        color.G = green;
        color.B = blue;
        return color;
    }

    private static double Percentile95(IEnumerable<double> values)
    {
        double[] sorted = values.OrderBy(value => value).ToArray();
        if (sorted.Length == 0) return 0;
        int index = Math.Max(0, (int)Math.Ceiling(sorted.Length * 0.95) - 1);
        return sorted[index];
    }

    private static void SetKeyColor(dynamic lampArray, int[] indices, byte red, byte green, byte blue)
    {
        lampArray.SetSingleColorForIndices(CreateColor(red, green, blue), indices);
    }

    private static bool HasPackageIdentity()
    {
        try
        {
            return Windows.ApplicationModel.Package.Current.Id.Name == "QiyuanTan.TSW2RGB.AmbientProbe";
        }
        catch
        {
            return false;
        }
    }

    private static T WaitFor<T>(IAsyncOperation<T> operation)
    {
        using (ManualResetEvent completed = new ManualResetEvent(false))
        {
            operation.Completed = delegate { completed.Set(); };
            completed.WaitOne();
            return operation.GetResults();
        }
    }

    private static int Main(string[] args)
    {
        if (args.Any(value => string.Equals(value, "--self-test", StringComparison.OrdinalIgnoreCase)))
        {
            if (ProbeKeys.Length != 10 || ProbeKeys.Select(value => value.Key).Distinct().Count() != 10)
                return 1;
            if (Percentile95(Enumerable.Range(1, 100).Select(value => (double)value)) != 95)
                return 1;
            Diagnostic("self_test_passed", "Pure ambient probe validation passed; no device APIs were invoked.");
            return 0;
        }

        LampArray lampArray = null;
        bool controlAcquired = false;
        try
        {
            string mode = Argument(args, "--mode", "discover").ToLowerInvariant();
            if (mode != "discover" && mode != "diagnose" && mode != "smoke" && mode != "soak")
                throw new ArgumentException("--mode must be discover, diagnose, smoke, or soak.");
            if ((mode == "smoke" || mode == "soak") && !HasArgument(args, "--accept-lighting-control"))
            {
                Diagnostic("consent_required", "Smoke and soak modes change device lighting; pass --accept-lighting-control.", "error");
                return 2;
            }
            int duration = ArgumentInt(args, "--duration-seconds", mode == "soak" ? 600 : 15, 1, 3600);
            int fps = ArgumentInt(args, "--frames-per-second", 20, 1, 60);
            int startDelay = ArgumentInt(args, "--start-delay-seconds", 10, 0, 60);
            int availabilityTimeout = ArgumentInt(args, "--availability-timeout-seconds", 120, 1, 600);
            int deviceIndex = ArgumentInt(args, "--device-index", 0, 0, 64);

            Console.CancelKeyPress += delegate(object sender, ConsoleCancelEventArgs eventArgs)
            {
                eventArgs.Cancel = true;
                stopping = true;
            };

            if (!HasPackageIdentity())
            {
                Diagnostic("package_identity_required", "Register and launch the ambient probe using Register-AmbientProbe.ps1.", "error");
                return 3;
            }
            Diagnostic("package_identity", "name=" + Windows.ApplicationModel.Package.Current.Id.Name +
                "; family=" + Windows.ApplicationModel.Package.Current.Id.FamilyName);

            DeviceInformationCollection devices = WaitFor(DeviceInformation.FindAllAsync(LampArray.GetDeviceSelector()));
            for (int index = 0; index < devices.Count; index++)
                Diagnostic("device_found", "index=" + index + "; name=" + devices[index].Name);
            if (devices.Count == 0)
            {
                Diagnostic("no_lamp_array", "No HID LampArray device is available.", "error");
                return 3;
            }
            if (mode == "discover") return 0;
            if (deviceIndex >= devices.Count)
            {
                Diagnostic("invalid_device_index", "The selected device index is unavailable.", "error");
                return 4;
            }

            lampArray = WaitFor(LampArray.FromIdAsync(devices[deviceIndex].Id));
            if (lampArray == null || !lampArray.IsConnected)
            {
                Diagnostic("device_unavailable", "Windows could not open a connected LampArray.", "error");
                return 5;
            }
            Diagnostic("device_state", string.Format(CultureInfo.InvariantCulture,
                "connected={0}; available={1}; enabled={2}; brightness={3:F3}; kind={4}; vid={5:X4}; pid={6:X4}; lamps={7}; min_update_ms={8:F3}",
                lampArray.IsConnected, lampArray.IsAvailable, lampArray.IsEnabled, lampArray.BrightnessLevel,
                lampArray.LampArrayKind, lampArray.HardwareVendorId, lampArray.HardwareProductId,
                lampArray.LampCount, lampArray.MinUpdateInterval.TotalMilliseconds));

            if (mode == "diagnose")
            {
                bool initialAvailability = lampArray.IsAvailable;
                bool previousAvailability = initialAvailability;
                Stopwatch observation = Stopwatch.StartNew();
                while (observation.Elapsed.TotalSeconds < duration)
                {
                    bool currentAvailability = lampArray.IsAvailable;
                    if (currentAvailability != previousAvailability)
                    {
                        Diagnostic("availability_changed", "available=" + currentAvailability);
                        previousAvailability = currentAvailability;
                    }
                    Thread.Sleep(100);
                }
                Diagnostic("diagnosis_complete", string.Format(CultureInfo.InvariantCulture,
                    "seconds={0:F2}; initial_available={1}; final_available={2}; connected={3}; enabled={4}",
                    observation.Elapsed.TotalSeconds, initialAvailability, lampArray.IsAvailable,
                    lampArray.IsConnected, lampArray.IsEnabled));
                return 0;
            }
            if (!lampArray.SupportsVirtualKeys)
            {
                Diagnostic("virtual_keys_unsupported", "The LampArray does not expose virtual-key mappings.", "error");
                return 6;
            }

            Stopwatch availabilityWait = Stopwatch.StartNew();
            int nextProgressSecond = 10;
            if (!lampArray.IsAvailable)
                Diagnostic("ambient_control_waiting", "Waiting for Windows Dynamic Lighting to transfer background control; timeout_seconds=" + availabilityTimeout + ".");
            while (!stopping && lampArray.IsConnected && !lampArray.IsAvailable &&
                availabilityWait.Elapsed.TotalSeconds < availabilityTimeout)
            {
                if (availabilityWait.Elapsed.TotalSeconds >= nextProgressSecond)
                {
                    Diagnostic("ambient_control_pending", string.Format(CultureInfo.InvariantCulture,
                        "elapsed_seconds={0:F1}; timeout_seconds={1}", availabilityWait.Elapsed.TotalSeconds, availabilityTimeout));
                    nextProgressSecond += 10;
                }
                Thread.Sleep(100);
            }
            if (stopping)
            {
                Diagnostic("cancelled", "Control wait was cancelled before a lighting frame was submitted.");
                return 130;
            }
            if (!lampArray.IsConnected)
            {
                Diagnostic("device_disconnected", "The LampArray disconnected while waiting for ambient control.", "error");
                return 9;
            }
            if (!lampArray.IsAvailable)
            {
                Diagnostic("ambient_control_unavailable", string.Format(CultureInfo.InvariantCulture,
                    "Windows did not transfer ambient control within {0:F1} seconds. Keep the probe first in Background light control and retry after the priority change has settled.",
                    availabilityWait.Elapsed.TotalSeconds), "error");
                return 7;
            }

            var resolved = ProbeKeys.Select(item => new { Item = item, Indices = lampArray.GetIndicesForKey(item.Key) }).ToArray();
            ProbeKey unsupported = resolved.Where(item => item.Indices.Length == 0).Select(item => item.Item).FirstOrDefault();
            if (unsupported != null)
            {
                Diagnostic("key_unsupported", "The device did not map virtual key " + unsupported.Key + ".", "error");
                return 8;
            }

            Diagnostic("ambient_control_acquired", string.Format(CultureInfo.InvariantCulture,
                "lamps={0}; supports_virtual_keys={1}; min_update_ms={2:F3}; wait_seconds={3:F3}",
                lampArray.LampCount, lampArray.SupportsVirtualKeys, lampArray.MinUpdateInterval.TotalMilliseconds,
                availabilityWait.Elapsed.TotalSeconds));
            controlAcquired = true;
            Diagnostic("focus_test_ready", "Switch focus to TSW2 or another application during the start delay and keep it focused.");
            Thread.Sleep(startDelay * 1000);

            List<double> latencies = new List<double>();
            int errors = 0;
            int frames = 0;
            Process process = Process.GetCurrentProcess();
            long initialPrivateBytes = process.PrivateMemorySize64;
            Stopwatch run = Stopwatch.StartNew();
            double intervalMs = Math.Max(1000.0 / fps, lampArray.MinUpdateInterval.TotalMilliseconds);

            while (!stopping && run.Elapsed.TotalSeconds < duration)
            {
                Stopwatch frame = Stopwatch.StartNew();
                try
                {
                    if (!lampArray.IsConnected || !lampArray.IsAvailable)
                        throw new InvalidOperationException("Ambient LampArray control was lost while another application was focused.");
                    for (int index = 0; index < resolved.Length; index++)
                    {
                        byte[] color = mode == "smoke"
                            ? new byte[] { resolved[index].Item.Red, resolved[index].Item.Green, resolved[index].Item.Blue }
                            : Hsv(((frames + (index * 7)) % 120) / 120.0);
                        SetKeyColor(lampArray, resolved[index].Indices, color[0], color[1], color[2]);
                    }
                }
                catch (Exception exception)
                {
                    errors++;
                    Diagnostic("frame_failed", exception.Message, "error");
                    break;
                }
                finally
                {
                    frame.Stop();
                    latencies.Add(frame.Elapsed.TotalMilliseconds);
                }

                frames++;
                int remaining = (int)Math.Floor(intervalMs - frame.Elapsed.TotalMilliseconds);
                if (remaining > 0) Thread.Sleep(remaining);
            }

            process.Refresh();
            double p95 = Percentile95(latencies);
            Diagnostic("run_complete", string.Format(CultureInfo.InvariantCulture,
                "mode={0}; seconds={1:F2}; frames={2}; errors={3}; p95_ms={4:F3}; private_bytes_delta={5}",
                mode, run.Elapsed.TotalSeconds, frames, errors, p95, process.PrivateMemorySize64 - initialPrivateBytes));
            return errors == 0 ? 0 : 10;
        }
        catch (Exception exception)
        {
            Diagnostic("probe_failed", exception.Message, "error");
            return 10;
        }
        finally
        {
            if (lampArray != null)
            {
                if (controlAcquired && lampArray.IsAvailable)
                {
                    try
                    {
                        ((dynamic)lampArray).SetColor(CreateColor(0, 0, 0));
                        Diagnostic("cleared", "All lamps were set to black before control was released.");
                    }
                    catch (Exception exception)
                    {
                        Diagnostic("clear_failed", exception.Message, "error");
                    }
                }
                else Diagnostic("clear_skipped", controlAcquired
                    ? "Ambient control was lost before cleanup; no clear command was submitted."
                    : "No ambient control lease was acquired; no clear command was submitted.");
                lampArray = null;
                Diagnostic("released", "The LampArray reference was released.");
            }
        }
    }
}
