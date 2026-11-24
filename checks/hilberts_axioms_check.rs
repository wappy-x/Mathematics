// Hilbert's axioms -- the same check as the Python, in Rust.  No crates.
// Euclid I.1: A = (0, 0), B = (4, 0), a circle of radius 4 cm about each.
// The crossing is found by subtracting the circle equations and by bisection
// along circle A's arc; the rational plane is searched; Pasch is tested twice.
type P = (f64, f64);
const R: f64 = 4.0;
const D: P = (1.0, 0.0);

fn dist(p: P, q: P) -> f64 { ((p.0 - q.0).powi(2) + (p.1 - q.1).powi(2)).sqrt() }

fn bisect(r: f64, d: f64) -> P {      // P on circle A's upper arc, from (0, r) to (r, 0)
    let (mut lo, mut hi) = (0.0, r);  // P starts outside circle B and ends inside it
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if dist((mid, (r * r - mid * mid).sqrt()), (d, 0.0)) > r { lo = mid } else { hi = mid }
    }
    (lo, (r * r - lo * lo).sqrt())
}

fn hits(n: i64, qmax: i64) -> Vec<(i64, i64)> {   // whole p, q with p * p == n * q * q
    (1..=qmax).map(|q| (((n * q * q) as f64).sqrt().round() as i64, q))
        .filter(|&(p, q)| p * p == n * q * q).collect()
}

fn meet(u: P, p0: P, p1: P) -> (f64, P) {        // line D + t u against segment p0 + s (p1 - p0)
    let (ex, ey, bx, by) = (p1.0 - p0.0, p1.1 - p0.1, p0.0 - D.0, p0.1 - D.1);
    let det = ex * u.1 - u.0 * ey;
    let (t, s) = ((ex * by - bx * ey) / det, (u.0 * by - u.1 * bx) / det);
    (s, (D.0 + t * u.0, D.1 + t * u.1))
}

fn sign(b: bool) -> &'static str { if b { "+" } else { "-" } }

fn main() {
    let (a, b): (P, P) = ((0.0, 0.0), (4.0, 0.0));
    let (x1, yy) = (R / 2.0, R * R - (R / 2.0) * (R / 2.0));   // road one
    let y1 = yy.sqrt();
    let (x2, y2) = bisect(R, 4.0);                              // road two: bisection
    let c: P = (x1, y1);
    println!("Hilbert's groups: connection 7, order 5, parallels 1, congruence 6, continuity 1, total {}", 7 + 5 + 1 + 6 + 1);
    println!("road one, subtract the equations: x = {:.6}, y = {:.6}, y*y = {:.6}", x1, y1, yy);
    println!("road two, bisection along circle A's arc: x = {:.6}, y = {:.6}", x2, y2);
    println!("rational plane, whole p, q up to 1000 with p*p = 12*q*q: {} found", hits(12, 1000).len());
    let err = |q: i64| { let p = (q as f64 * y1).round() as i64; (p * p - 12 * q * q).abs() as f64 / (q * q) as f64 };
    let q = (1..31).fold(1, |best, q| if err(q) < err(best) { q } else { best });
    let p = (q as f64 * y1).round() as i64;
    println!("closest fraction with q up to 30: {}/{} = {:.6}, squared {:.6}", p, q, p as f64 / q as f64, (p * p) as f64 / (q * q) as f64);
    let ctl = hits(16, 5)[0];
    println!("control, radius 5, centres 6 apart: y*y = {}, rational crossing (3, {})", 25 - 9, ctl.0 / ctl.1);
    let sides = [("BC", b, c), ("CA", c, a)];
    let mut exits: Vec<P> = Vec::new();
    for u in [(1.0, 1.0), (-1.0, 2.0)] {
        let leave: Vec<(&str, P, P, P)> = sides.iter().map(|&(n, p0, p1)| (n, meet(u, p0, p1), p0, p1))
            .filter(|(_, (s, _), _, _)| 0.0 < *s && *s < 1.0).map(|(n, (_, pt), p0, p1)| (n, pt, p0, p1)).collect();
        let side = |v: P| u.0 * (v.1 - D.1) - u.1 * (v.0 - D.0);  // the sign test; zero on the line
        let sg = |v: P| side(v) > 0.0;
        let by_sign: Vec<&str> = sides.iter().filter(|(_, p0, p1)| sg(*p0) != sg(*p1)).map(|s| s.0).collect();
        let (n, pt, p0, p1) = leave[0];
        exits.push(pt);
        println!("line through D (1, 0) heading ({}, {}): leaves through {} at ({:.3}, {:.3}); signs at A, B, C: {}{}{}",
                 u.0, u.1, n, pt.0, pt.1, sign(sg(a)), sign(sg(b)), sign(sg(c)));
        assert!(leave.len() == 1 && by_sign == vec![n] && (dist(p0, pt) + dist(pt, p1) - dist(p0, p1)).abs() < 1e-9
                && side(pt).abs() < 1e-9);
    }
    let (s, far) = meet((-1.0, 2.0), b, c);
    println!("mistake, exit assumed on BC for heading (-1, 2): line BC met at ({:.3}, {:.3}), s = {:.3}", far.0, far.1, s);
    println!("mistake, centres 9 apart: y*y = 16 - {} = {}, no crossing", 4.5f64 * 4.5, 16.0 - 4.5f64 * 4.5);
    println!("other crossing (2, {:.6}); signs of y at C and C': {}, {}", -y1, sign(y1 > 0.0), sign(-y1 > 0.0));
    println!("figure, A (200, 200), B (360, 200), C ({:.1}, {:.1}), D (240, 200), E ({:.1}, {:.1}), C' ({:.1}, {:.1})",
             200.0 + 40.0 * x1, 200.0 - 40.0 * y1, 200.0 + 40.0 * exits[0].0, 200.0 - 40.0 * exits[0].1,
             200.0 + 40.0 * x1, 200.0 + 40.0 * y1);
    assert!((x2 - x1).abs() < 1e-9 && (y2 - y1).abs() < 1e-9 && (dist(c, b) - R).abs() < 1e-9);
    assert!(hits(12, 1000).is_empty() && ctl == (4, 1) && s > 1.0);
    println!("ALL CHECKS PASS");
}
