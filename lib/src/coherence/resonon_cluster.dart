// lib/src/coherence/resonon_cluster.dart

class ResononCluster {
  final List<Resonon> waves;

  const ResononCluster({this.waves = const []});

  /// Energiezufuhr in die schnelle Dynamik (Wellen)
  ResononCluster injectEnergy(double energy) {
    if (waves.isEmpty) return this;

    // 1. Energie pro Welle verteilen (gleichmäßig oder später gewichtet)
    final double energyPerWave = energy / waves.length;

    // 2. Jede Welle bekommt:
    //    - Amplitudenboost proportional zur Energie
    //    - leichte Phasenverschiebung (Störung)
    final updatedWaves = waves.map((w) {
      if (w == null) return w;
      final newAmplitude = w.amplitude + energyPerWave * 0.5;
      final newPhase = w.phase + (energyPerWave * 0.1);

      return w.copyWith(
        amplitude: newAmplitude.clamp(0.0, 1.0),
        phase: newPhase % (2 * math.pi),
      );
    }).toList();

    // 3. Normalisierung: Verhindert Explosionen im Cluster
    final double totalAmp =
        updatedWaves.fold(0.0, (sum, w) => sum + w.amplitude);

    final normalizedWaves = updatedWaves.map((w) {
      return w.copyWith(
        amplitude: (w.amplitude / totalAmp).clamp(0.0, 1.0),
      );
    }).toList();

    // 4. Neuer Cluster (immutable)
    return ResononCluster(waves: normalizedWaves);
  }

  // Beispielmethoden, die FieldState nutzt:
  double coherence() {
    if (waves.isEmpty) return 1.0;
    final phases = waves.map((w) => math.cos(w.phase)).toList();
    return phases.reduce((a, b) => a + b) / waves.length;
  }
