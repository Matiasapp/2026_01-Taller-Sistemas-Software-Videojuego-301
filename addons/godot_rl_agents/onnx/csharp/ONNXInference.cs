#nullable enable

using Godot;
using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;
using System;
using System.Collections.Generic;
using System.Linq;

namespace GodotONNX;

public partial class ONNXInference : GodotObject
{
    private InferenceSession? _session;
    private SessionOptions? _sessionOptions;
    private int _batchSize;

    public int Initialize(string path, int batchSize)
    {
        _batchSize = batchSize;
        _sessionOptions = SessionConfigurator.MakeConfiguredSessionOptions();

        using Godot.FileAccess file = Godot.FileAccess.Open(path, Godot.FileAccess.ModeFlags.Read);
        if (file is null)
            throw new InvalidOperationException($"No se pudo abrir el modelo ONNX: {path}");

        byte[] model = file.GetBuffer((long)file.GetLength());
        _session = new InferenceSession(model, _sessionOptions);

        if (!_session.OutputMetadata.TryGetValue("output", out NodeMetadata? output))
            throw new InvalidOperationException("El modelo ONNX no contiene una salida llamada 'output'.");

        return output.Dimensions.Last();
    }

    public Godot.Collections.Dictionary<string, Godot.Collections.Array<float>> RunInference(
        Godot.Collections.Array<float> observations,
        int stateIns)
    {
        if (_session is null)
            throw new InvalidOperationException("El modelo ONNX no fue inicializado.");

        float[] observationValues = observations.ToArray();
        var inputs = new List<NamedOnnxValue>
        {
            NamedOnnxValue.CreateFromTensor(
                "obs",
                new DenseTensor<float>(observationValues, new[] { _batchSize, observations.Count })
            ),
            NamedOnnxValue.CreateFromTensor(
                "state_ins",
                new DenseTensor<float>(new[] { (float)stateIns }, new[] { _batchSize })
            )
        };

        string[] outputNames = _session.OutputMetadata.ContainsKey("state_outs")
            ? new[] { "output", "state_outs" }
            : new[] { "output" };

        using IDisposableReadOnlyCollection<DisposableNamedOnnxValue> results =
            _session.Run(inputs, outputNames);

        var output = new Godot.Collections.Dictionary<string, Godot.Collections.Array<float>>();
        foreach (DisposableNamedOnnxValue result in results)
        {
            var values = new Godot.Collections.Array<float>();
            foreach (float value in result.AsEnumerable<float>())
                values.Add(value);
            output[result.Name] = values;
        }

        return output;
    }

    public void FreeDisposables()
    {
        _session?.Dispose();
        _session = null;
        _sessionOptions?.Dispose();
        _sessionOptions = null;
    }
}
