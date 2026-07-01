// lib/src/wave/orbit_clock.dart

/// Repräsentiert den diskreten Zeittakt des Systems.
/// Ermöglicht dem Feld zu altern, zu relaxieren und zu oszillieren.
class OrbitTick {
  final int sequenceNumber;
  final DateTime timestamp;
  final double deltaTime; // Zeitdifferenz zum letzten Tick in Sekunden

  const OrbitTick({
    required this.sequenceNumber,
    required this.timestamp,
    required this.deltaTime,
  });
}
