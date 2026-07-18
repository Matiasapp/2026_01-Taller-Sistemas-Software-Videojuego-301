
# Crossy Road: entrenamiento con ML

El entorno de entrenamiento está en
`Scenes/Minigames/Crossy_Road/Crossy Road_entrenamiento.tscn`. La escena normal
mantiene el control manual y no intenta conectarse al servidor de entrenamiento.

## Entrenamiento desde el editor

1. Usa la edición .NET de Godot 4.6 y abre la escena de entrenamiento.
2. Crea y activa un entorno virtual de Python.
3. Instala las dependencias con `pip install -r requirements-ml.txt`.
4. Inicia el servidor con:

   ```text
   gdrl --env=gdrl --experiment_name=CrossyRoad --onnx_export_path=CrossyRoad.onnx --viz
   ```

5. Ejecuta la escena de entrenamiento desde Godot. El servidor escucha por defecto
   en `127.0.0.1:11008`.

Para repetir un experimento se puede pasar la misma semilla a Godot mediante
`--env_seed=<numero>`. Cada episodio conserva su estado terminal hasta que Python
solicita el reinicio; el reinicio reconstruye las franjas, vehículos y temporizadores.

## Inferencia

Para usar el modelo exportado, cambia el `control_mode` del nodo `Sync` a
`ONNX_INFERENCE` y asigna la ruta del archivo `.onnx`. La inferencia requiere que el
proyecto se ejecute con la edición .NET de Godot.

## Plugin Godot RL Agents

This repository contains the Godot 4 asset / plugin for the Godot RL Agents library, you can find out more about the library on its Github page [here](https://github.com/edbeeching/godot_rl_agents).

The Godot RL Agents is a fully Open Source package that allows video game creators, AI researchers and hobbyists the opportunity to learn complex behaviors for their Non Player Characters or agents. 
This libary provided this following functionaly:
* An interface between games created in the [Godot Engine](https://godotengine.org/) and Machine Learning algorithms running in Python
* Wrappers for three well known rl frameworks: StableBaselines3, Sample Factory and [Ray RLLib](https://docs.ray.io/en/latest/rllib-algorithms.html)
* Support for memory-based agents, with LSTM or attention based interfaces
* Support for 2D and 3D games
* A suite of AI sensors to augment your agent's capacity to observe the game world
* Godot and Godot RL Agents are completely free and open source under the very permissive MIT license. No strings attached, no royalties, nothing. 

You can find out more about Godot RL agents in our AAAI-2022 Workshop [paper](https://arxiv.org/abs/2112.03636).
