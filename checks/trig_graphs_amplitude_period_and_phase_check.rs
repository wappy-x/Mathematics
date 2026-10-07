// Trig graphs -- the same check as the Python, in Rust.  std only.  A tide
// table is read into y = a sin(b(t - c)) + d by the reading rules (road one).
// Road two builds that curve, samples it once a minute and measures it back:
// highs, lows, midline crossings, the shortest repeat.  It must return the table.
use std::collections::BTreeSet;
use std::f64::consts::PI;

fn wave(a: f64, b: f64, c: f64, d: f64) -> impl Fn(f64) -> f64 { move |t| a * (b * (t - c)).sin() + d }
fn hm(t: f64) -> String { let m = (t * 60.0).round() as i64; format!("{:02}:{:02}", m / 60, m % 60) }
fn extremes(f: &dyn Fn(f64) -> f64, s: f64) -> Vec<(f64, f64)> {  // road two: highs (s = 1) or lows (s = -1)
    let v: Vec<f64> = (0..1441).map(|m| s * f(m as f64 / 60.0)).collect();
    (1..1440).filter(|&m| v[m - 1] < v[m] && v[m] >= v[m + 1]).map(|m| (m as f64 / 60.0, s * v[m])).collect()
}
fn pin(f: &dyn Fn(f64) -> f64, level: f64, mut l: f64, mut h: f64) -> f64 {  // bisection, 60 halvings
    for _ in 0..60 { let m = (l + h) / 2.0; if f(m) < level { l = m } else { h = m } }
    h
}
fn rising(f: &dyn Fn(f64) -> f64, level: f64) -> Vec<f64> {  // road two: climbs through level, by the minute, then pinned
    (1..1441).map(|m| ((m - 1) as f64 / 60.0, m as f64 / 60.0))
        .filter(|&(l, h)| f(l) < level && level <= f(h)).map(|(l, h)| pin(f, level, l, h)).collect()
}
fn shortest_repeat(f: &dyn Fn(f64) -> f64) -> f64 {  // road two: the first shift, in steps of 0.01 h, that repeats f
    (1..2001).map(|k| k as f64 / 100.0)
        .find(|&p| (0..25).map(|t| (f(t as f64 + p) - f(t as f64)).abs()).fold(0.0, f64::max) < 1e-9)
        .unwrap_or(f64::INFINITY)
}
fn at(pts: &[(f64, f64)]) -> String {
    pts.iter().map(|&(t, v)| format!("{:.1} m at {}", v, hm(t))).collect::<Vec<_>>().join(", ")
}
fn main() {
    let table = [(4.1, 3.5), (10.3, 0.5), (16.5, 3.5), (22.7, 0.5)];  // (hours after midnight, m)
    let ((t1, hi), (_, lo), (t3, _)) = (table[0], table[1], table[2]);
    let (a, d) = ((hi - lo) / 2.0, (hi + lo) / 2.0);  // road one: half the swing, and the middle of it
    let p = t3 - t1;                                  // high water to high water
    let b = 2.0 * PI / p;                             // one full turn, 2 pi radians, per period
    let c = t1 - p / 4.0;                             // the sine starts rising a quarter period before its peak
    let y = wave(a, b, c, d);
    let (highs, lows) = (extremes(&y, 1.0), extremes(&y, -1.0));
    let mid = (highs[0].1 + lows[0].1) / 2.0;         // the midline as measured, not as read
    let (ups, downs, rep) = (rising(&y, mid), rising(&|t| -y(t), -mid), shortest_repeat(&y));
    let cosine = move |t: f64| a * (b * (t - t1)).cos() + d;
    let forms: [&dyn Fn(f64) -> f64; 3] = [&cosine, &wave(a, b, c + p, d), &wave(-a, b, c + p / 2.0, d)];
    let yr = &y;
    let gap = forms.iter().flat_map(|f| (0..25).map(move |t| (f(t as f64) - yr(t as f64)).abs())).fold(0.0, f64::max);
    let join = |ts: &[f64]| ts.iter().map(|&t| hm(t)).collect::<Vec<_>>().join(", ");
    println!("tide table: {}", at(&table));
    println!("road 1, reading rules: swing {:.1} m, a = {:.1} m, d = {:.1} m, P = {:.1} h ({}), P/4 = {:.1} h, c = {:.1} h ({})",
             hi - lo, a, d, p, hm(p), p / 4.0, c, hm(c));
    println!("road 1: b = 2 pi / {:.1} = {:.4} radians per hour = {:.2} degrees per hour", p, b, b.to_degrees());
    println!("road 2, measured off the curve: highs {}; lows {}; midline {:.1} m", at(&highs), at(&lows), mid);
    println!("road 2, midline crossings: rising {}; falling {}", join(&ups), join(&downs));
    println!("road 2, shortest shift that repeats the curve, tried in steps of 0.01 h: {:.2} h", rep);
    println!("cosine from {}, sine from {}, sine with a = {:.1} from {}: all agree: {}", hm(t1), hm(c + p), -a, hm(c + p / 2.0), if gap < 1e-12 { "yes" } else { "no" });
    println!("height at 09:00: angle {:.4} rad, sine {:.4}, height {:.2} m", b * (9.0 - c), (b * (9.0 - c)).sin(), y(9.0));
    println!("tomorrow's first high water: {}, {} min later", hm(t1 + 2.0 * p - 24.0), ((2.0 * p - 24.0) * 60.0).round());
    let sw = wave(hi - lo, b, c, d);
    println!("mistake, swing as amplitude: highs {:.1} m, lows {:.1} m", extremes(&sw, 1.0)[0].1, extremes(&sw, -1.0)[0].1);
    println!("mistake, high-water time as c in the sine: first high at {}", hm(extremes(&wave(a, b, t1, d), 1.0)[0].0));
    println!("mistake, shift read before factoring, {:.4} h: first high at {}", b * c, hm(extremes(&wave(a, b, b * c, d), 1.0)[0].0));
    println!("mistake, period where b goes: repeats every {:.2} h, {} highs a day", 2.0 * PI / p, extremes(&wave(a, p, c, d), 1.0).len());
    let (xs, ys) = (|t: f64| 40.0 + 12.5 * t, |h: f64| 200.0 - 40.0 * h);  // figure: 1 h = 12.5, 1 m = 40, datum y = 200
    let pt = |t: f64, h: f64| format!("({:.2},{:.1})", xs(t), ys(h));
    println!("figure, key (1 h = 12.5, 1 m = 40, datum at y = 200): highs {} {}, lows {} {}, c {}", pt(t1, hi), pt(t3, hi), pt(table[1].0, lo), pt(table[3].0, lo), pt(c, d));
    let mut tenths: BTreeSet<i64> = (0..49).map(|k| 5 * k).collect();
    tenths.extend((0..8).map(|k| (10.0 * (c + k as f64 * p / 4.0)).round() as i64));
    let curve: Vec<String> = tenths.iter().map(|&n| format!("{:.2},{:.1}", xs(n as f64 / 10.0), ys(y(n as f64 / 10.0)))).collect();
    println!("figure, curve: {}", curve.join(" "));
    let mut got: Vec<(f64, f64)> = highs.iter().chain(lows.iter()).copied().collect();
    got.sort_by(|u, v| u.0.partial_cmp(&v.0).unwrap());
    assert!(got.len() == 4 && got.iter().zip(table.iter()).all(|(g, w)| (g.0 * 60.0).round() == (w.0 * 60.0).round() && (g.1 - w.1).abs() < 1e-9));
    assert!((ups[0] - c).abs() < 1e-9 && (downs[0] - ups[0] - p / 2.0).abs() < 1e-9);  // starts at c; rises and falls alike
    assert!((rep - p).abs() < 0.005);                                            // the shortest repeat is the table's period
    assert!(gap < 1e-12);                                                        // four formulas, one tide
    println!("ALL CHECKS PASS");
}
