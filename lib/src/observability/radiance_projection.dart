// lib/src/observability/radiance_projection.dart

import 'dart:math' as math;

import '../coherence/resonon_cluster.dart';

/// Ein Punkt in der Beobachtungsebene Ω ⊂ ℝ².
typedef FieldPoint = ({double x, double y});

/// Ein Beobachtungsstrahl: Randpunkt auf der Schale + reflektierte Richtung.
typedef RadianceRay = ({FieldPoint origin, FieldPoint direction});

/// Der Projektionsoperator 𝒫: ℂᴺ → L²(Ω) der Beobachtungsschicht.
///
///     (𝒫A)(p) = Σ_k A(φ_k) · G_k(p),      I(p) = |(𝒫A)(p)|²
///
/// Reine Observable im Sinne von ADR_001 und INPUT_002: Der Physikkern
/// (ResononCluster) kennt keinerlei Geometrie - diese Klasse liest ihn nur
/// und projiziert seinen komplexen Zustand in den Raum. Sie ist zustandslos,
/// nicht-invasiv und vollständig austauschbar (andere Kerne G, andere
/// Schalengeometrien erzeugen andere Kaustiken, ohne den Kern zu berühren).
///
/// Geometrie (V0.1): Parallele Beobachtungsstrahlen entlang -x treffen die
/// kreisförmige Resonanzschale (Radius R) und werden nach dem
/// Reflexionsgesetz gespiegelt - der Householder-Operator
///
///     u = d - 2(d·n)n
///
/// an seinem architektonisch richtigen Ort: als Grenzflächen-Geometrie der
/// Beobachtung, normerhaltend, matrixfrei (Rang-1). Die Einhüllende der
/// reflektierten Strahlen ist die Nephroiden-Kaustik mit Cusp bei (-R/2, 0);
/// die Singularitätsbedingung det ∂Φ/∂(φ,s) = 0 liefert s*(φ) = -R·cosφ/2.
///
/// Zentrale Observable-Identität (einbandig, exakt):
///
///     I_max = C_geo · energy()
///
/// Die Helligkeit der Kaustik misst die kohärente Energie des Feldes -
/// r(t) → 1 lässt die Brennlinie aufleuchten, r(t) → 0 verdunkelt sie
/// vollständig (destruktive Auslöschung: viele inkohärente Quellen,
/// keine Erkenntnis). Die FORM der Kaustik kommt allein aus der Geometrie.
class RadianceProjection {
  /// Radius R der reflektierenden Resonanzschale.
  final double shellRadius;

  /// Breite σ des transversalen Gauß-Kerns G_k (räumliche Auflösung).
  final double kernelWidth;

  /// Anzahl M der Abtaststrahlen auf S¹.
  final int rayCount;

  const RadianceProjection({
    this.shellRadius = 1.0,
    this.kernelWidth = 0.06,
    this.rayCount = 64,
  });

  /// Householder-Reflexion u = d - 2(d·n)n. Normerhaltend und involutiv.
  FieldPoint reflect(FieldPoint d, FieldPoint n) {
    final dn = d.x * n.x + d.y * n.y;
    return (x: d.x - 2 * dn * n.x, y: d.y - 2 * dn * n.y);
  }

  /// Der Beobachtungsstrahl zum Randwinkel φ: einfallende Richtung (-1, 0),
  /// reflektiert an der Schalennormalen (cosφ, sinφ).
  RadianceRay ray(double phi) {
    final n = (x: math.cos(phi), y: math.sin(phi));
    final u = reflect((x: -1.0, y: 0.0), n);
    return (origin: (x: shellRadius * n.x, y: shellRadius * n.y), direction: u);
  }

  /// Analytischer Kaustik-Punkt zum Randwinkel φ (Referenz/Erwartung):
  /// p*(φ) = Φ(φ, s*) mit s*(φ) = -R·cosφ/2 aus det ∂Φ/∂(φ,s) = 0.
  /// Physikalisch nur für die beleuchtete Innenwand (cosφ < 0) definiert.
  FieldPoint causticPoint(double phi) {
    final r = ray(phi);
    final s = -shellRadius * math.cos(phi) / 2;
    return (
      x: r.origin.x + s * r.direction.x,
      y: r.origin.y + s * r.direction.y,
    );
  }

  /// Komplexe Randamplitude A(φ) = Σᵢ aᵢ·e^(i(fᵢφ + θᵢ)) - die analytische
  /// Fortsetzung von ResononCluster.psi(φ) (deren Realteil sie ist).
  ({double re, double im}) boundaryAmplitude(
      ResononCluster cluster, double phi) {
    double re = 0.0;
    double im = 0.0;
    for (final w in cluster.waves) {
      final arg = w.frequency * phi + w.phase;
      re += w.amplitude * math.cos(arg);
      im += w.amplitude * math.sin(arg);
    }
    return (re: re, im: im);
  }

  /// Die Intensität I(p) = |Σ_k A(φ_k)·G_k(p)|² am Punkt p.
  ///
  /// G_k ist ein transversaler Gauß-Kern um den reflektierten Strahl k
  /// (Abstand Punkt-Strahl, s ≥ 0 geklemmt). Komplexe Summation über alle
  /// Strahlen - Interferenz zwischen Strahlen und zwischen Bändern findet
  /// hier, in der Beobachtung, statt. O(M·N) pro Punkt, matrixfrei.
  double intensityAt(ResononCluster cluster, FieldPoint p) {
    if (cluster.waves.isEmpty) return 0.0;

    final twoSigmaSq = 2 * kernelWidth * kernelWidth;
    double totalRe = 0.0;
    double totalIm = 0.0;

    for (int k = 0; k < rayCount; k++) {
      final phi = 2 * math.pi * k / rayCount;
      final r = ray(phi);

      // Projektion von p auf den Strahl (nur vorwärts, s >= 0).
      final relX = p.x - r.origin.x;
      final relY = p.y - r.origin.y;
      double s = relX * r.direction.x + relY * r.direction.y;
      if (s < 0) s = 0;
      final dx = relX - s * r.direction.x;
      final dy = relY - s * r.direction.y;
      final g = math.exp(-(dx * dx + dy * dy) / twoSigmaSq);

      final a = boundaryAmplitude(cluster, phi);
      totalRe += a.re * g;
      totalIm += a.im * g;
    }
    return totalRe * totalRe + totalIm * totalIm;
  }

  /// Tastet I(p) auf einem quadratischen Gitter [-R, R]² ab (row-major).
  /// Punkte außerhalb der Schale werden nicht ausgewertet (Intensität 0).
  List<double> intensityGrid(ResononCluster cluster, {required int gridSize}) {
    final values = List<double>.filled(gridSize * gridSize, 0.0);
    final rSq = shellRadius * shellRadius * 0.98;
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final p = (
          x: -shellRadius + 2 * shellRadius * i / (gridSize - 1),
          y: -shellRadius + 2 * shellRadius * j / (gridSize - 1),
        );
        if (p.x * p.x + p.y * p.y > rSq) continue;
        values[i * gridSize + j] = intensityAt(cluster, p);
      }
    }
    return values;
  }
}
