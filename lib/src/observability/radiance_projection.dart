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
/// Geometrie (V0.2): Parallele Beobachtungsstrahlen entlang -x treffen die
/// Resonanzschale und werden nach dem Reflexionsgesetz gespiegelt - der
/// Householder-Operator
///
///     u = d - 2(d·n)n
///
/// an seinem architektonisch richtigen Ort: als Grenzflächen-Geometrie der
/// Beobachtung, normerhaltend, matrixfrei (Rang-1).
///
/// Die Schale selbst ist keine starre Kreislinie mehr, sondern trägt die
/// 8-Häuser-Geometrie (Architektur-Review V1.0: die Häuser als Organe des
/// Feldes): eine polare Kurve
///
///     ρ(φ) = R · (1 + Σ_k c_k · exp(κ·(cos(φ - φ_k) - 1))),   φ_k = 2πk/8
///
/// mit acht lokalen, glatten von-Mises-Ausbuchtungen. c_k = 0 überall ergibt
/// exakt den Kreis - und damit die klassische Nephroiden-Kaustik mit Cusp
/// bei (-R/2, 0), wo die Singularitätsbedingung det ∂Φ/∂(φ,s) = 0 analytisch
/// s*(φ) = -R·cosφ/2 liefert. Für gekrümmte Schalen liefert dieselbe
/// Bedingung den numerischen Kaustik-Punkt: da Φ(φ,s) = P(φ) + s·u(φ) affin
/// in s ist, ist die Determinante LINEAR in s - eine Division pro Strahl,
/// matrixfrei, O(1):
///
///     s*(φ) = -(P'×u) / (u'×u)
///
/// Kaustiken verschieben sich stetig mit der Krümmung, reorganisieren sich
/// aber nur an Bifurkationsschwellen (Katastrophentheorie, INPUT_002 Punkt 6)
/// - der Stabilitätsgradient von FieldObserver.detectEvent() ist der Sensor,
/// der diese Resonanzsprünge sehen wird.
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
  /// Anzahl der Häuser auf der Schale (Naturkonstante der Zielkarte).
  static const int houseCount = 8;

  /// Radius R der ungekrümmten Resonanzschale.
  final double shellRadius;

  /// Breite σ des transversalen Gauß-Kerns G_k (räumliche Auflösung).
  final double kernelWidth;

  /// Anzahl M der Abtaststrahlen auf S¹.
  final int rayCount;

  /// Krümmungsgewichte c_k der acht Häuser (Haus k zentriert bei φ_k = 2πk/8).
  /// Alle null (Default): die Schale ist der Kreis, die Kaustik die Nephroide.
  ///
  /// Kontrakt: exakt [houseCount] Einträge. (Nicht per assert im
  /// const-Konstruktor prüfbar - List.length ist kein konstanter Ausdruck;
  /// eine kürzere Liste fällt in radiusAt() sofort als RangeError auf.)
  final List<double> houseCurvatures;

  /// Konzentration κ der von-Mises-Ausbuchtungen: bestimmt, wie lokal ein
  /// Haus die Schale krümmt (κ = 10 → Halbwertsbreite ≈ ein Haus-Sektor).
  final double houseConcentration;

  const RadianceProjection({
    this.shellRadius = 1.0,
    this.kernelWidth = 0.06,
    this.rayCount = 64,
    this.houseCurvatures = const [0, 0, 0, 0, 0, 0, 0, 0],
    this.houseConcentration = 10.0,
  });

  /// Leitet die Haus-Krümmungen nicht-invasiv aus dem Feld ab: Frequenzband
  /// f nährt Haus (f-1) mod 8 mit seinem Substanz-Anteil. Die Organe atmen
  /// mit dem Feld - Geometrie und Dynamik sind ko-emergent, ohne dass die
  /// Kern-Physik von der Schale weiß (reine Leseoperation, ADR_001).
  static List<double> houseCurvaturesFromCluster(ResononCluster cluster,
      {double scale = 0.15}) {
    final curvatures = List<double>.filled(houseCount, 0.0);
    final total = cluster.substance();
    if (total <= 1e-12) return curvatures;
    for (final w in cluster.waves) {
      final house = (w.frequency - 1) % houseCount;
      curvatures[house] += scale * (w.amplitude * w.amplitude) / total;
    }
    return curvatures;
  }

  /// Der Schalenradius ρ(φ) = R·(1 + Σ_k c_k·exp(κ(cos(φ-φ_k)-1))).
  double radiusAt(double phi) {
    double bump = 0.0;
    for (int k = 0; k < houseCount; k++) {
      final c = houseCurvatures[k];
      if (c == 0.0) continue;
      final delta = phi - 2 * math.pi * k / houseCount;
      bump += c * math.exp(houseConcentration * (math.cos(delta) - 1));
    }
    return shellRadius * (1 + bump);
  }

  /// Analytische Ableitung dρ/dφ (matrixfrei, kein Differenzenquotient).
  double radiusDerivativeAt(double phi) {
    double d = 0.0;
    for (int k = 0; k < houseCount; k++) {
      final c = houseCurvatures[k];
      if (c == 0.0) continue;
      final delta = phi - 2 * math.pi * k / houseCount;
      d += c *
          houseConcentration *
          -math.sin(delta) *
          math.exp(houseConcentration * (math.cos(delta) - 1));
    }
    return shellRadius * d;
  }

  /// Randpunkt P(φ) = ρ(φ)·(cosφ, sinφ) der Schale.
  FieldPoint boundaryPoint(double phi) {
    final rho = radiusAt(phi);
    return (x: rho * math.cos(phi), y: rho * math.sin(phi));
  }

  /// Die echte äußere Einheitsnormale der Kurve ρ(φ). Für den Kreis (ρ'=0)
  /// fällt sie auf die radiale Richtung (cosφ, sinφ) zurück.
  FieldPoint outwardNormalAt(double phi) {
    final rho = radiusAt(phi);
    final dRho = radiusDerivativeAt(phi);
    final c = math.cos(phi);
    final s = math.sin(phi);
    // Tangente T = P'(φ), Normale = T um -90° gedreht (zeigt nach außen).
    final nx = rho * c + dRho * s;
    final ny = rho * s - dRho * c;
    final norm = math.sqrt(nx * nx + ny * ny);
    return (x: nx / norm, y: ny / norm);
  }

  /// Householder-Reflexion u = d - 2(d·n)n. Normerhaltend und involutiv.
  FieldPoint reflect(FieldPoint d, FieldPoint n) {
    final dn = d.x * n.x + d.y * n.y;
    return (x: d.x - 2 * dn * n.x, y: d.y - 2 * dn * n.y);
  }

  /// Der Beobachtungsstrahl zum Randwinkel φ: einfallende Richtung (-1, 0),
  /// reflektiert an der echten Kurvennormalen der (ggf. gekrümmten) Schale.
  RadianceRay ray(double phi) {
    final u = reflect((x: -1.0, y: 0.0), outwardNormalAt(phi));
    return (origin: boundaryPoint(phi), direction: u);
  }

  /// Analytischer Kaustik-Punkt der UNGEKRÜMMTEN Schale (Nephroiden-
  /// Referenz): p*(φ) = Φ(φ, s*) mit s*(φ) = -R·cosφ/2 aus
  /// det ∂Φ/∂(φ,s) = 0. Physikalisch nur für die beleuchtete Innenwand
  /// (cosφ < 0) definiert. Für gekrümmte Schalen: [numericalCausticPoint].
  FieldPoint causticPoint(double phi) {
    final r = ray(phi);
    final s = -shellRadius * math.cos(phi) / 2;
    return (
      x: r.origin.x + s * r.direction.x,
      y: r.origin.y + s * r.direction.y,
    );
  }

  /// Numerischer Kaustik-Punkt für beliebige Schalengeometrie.
  ///
  /// Φ(φ,s) = P(φ) + s·u(φ) ist affin in s, also ist
  /// det ∂Φ/∂(φ,s) = P'×u + s·(u'×u) LINEAR in s: die Singularität liegt
  /// exakt bei s* = -(P'×u)/(u'×u). P' analytisch, u' als zentraler
  /// Differenzenquotient - eine Division pro Strahl, O(1), matrixfrei.
  /// Im Grenzfall c_k = 0 reproduziert dies die Nephroide von
  /// [causticPoint] (Invarianten-Test).
  FieldPoint numericalCausticPoint(double phi, {double h = 1e-5}) {
    final r = ray(phi);

    // P'(φ) analytisch aus ρ und ρ'.
    final rho = radiusAt(phi);
    final dRho = radiusDerivativeAt(phi);
    final c = math.cos(phi);
    final sn = math.sin(phi);
    final pPrime = (x: dRho * c - rho * sn, y: dRho * sn + rho * c);

    // u'(φ) zentral differenziert.
    final uPlus = ray(phi + h).direction;
    final uMinus = ray(phi - h).direction;
    final uPrime = (x: (uPlus.x - uMinus.x) / (2 * h),
        y: (uPlus.y - uMinus.y) / (2 * h));

    double cross(FieldPoint a, FieldPoint b) => a.x * b.y - a.y * b.x;
    final denominator = cross(uPrime, r.direction);
    if (denominator.abs() < 1e-12) {
      // Entarteter Strahl (keine Fokussierung): kein Kaustik-Punkt.
      return r.origin;
    }
    final s = -cross(pPrime, r.direction) / denominator;
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


  /// Tastet I(p) auf einem quadratischen Gitter [-R_max, R_max]² ab
  /// (row-major). Punkte außerhalb der (ggf. gekrümmten) Schale werden
  /// nicht ausgewertet (Intensität 0).
  List<double> intensityGrid(ResononCluster cluster, {required int gridSize}) {
    final values = List<double>.filled(gridSize * gridSize, 0.0);

    double maxRadius = shellRadius;
    for (int k = 0; k < rayCount; k++) {
      final rho = radiusAt(2 * math.pi * k / rayCount);
      if (rho > maxRadius) maxRadius = rho;
    }

    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final p = (
          x: -maxRadius + 2 * maxRadius * i / (gridSize - 1),
          y: -maxRadius + 2 * maxRadius * j / (gridSize - 1),
        );
        final rho = radiusAt(math.atan2(p.y, p.x));
        if (p.x * p.x + p.y * p.y > rho * rho * 0.98) continue;
        values[i * gridSize + j] = intensityAt(cluster, p);
      }
    }
    return values;
  }
}
