using Godot;
using Microsoft.ML.OnnxRuntime;

namespace GodotONNX;

public static class SessionConfigurator
{
    public static SessionOptions MakeConfiguredSessionOptions()
    {
        var options = new SessionOptions
        {
            LogSeverityLevel = OrtLoggingLevel.ORT_LOGGING_LEVEL_WARNING
        };

        GD.Print($"ONNX Runtime: CPU ({OS.GetName()})");
        return options;
    }
}
