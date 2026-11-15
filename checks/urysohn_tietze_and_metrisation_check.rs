// Urysohn, Tietze and metrisation -- the check behind the card.  Rust std only.
// Room floor in metres: corners (0,0), (6,0), (3,4), (0,4).  Wall A runs (0,0)-(0,4); the far
// wall B runs (6,0)-(3,4), a 3-4-5 slant.  Temperatures on the walls are in degrees C.
use std::f64::consts::PI;
type Pt = (f64, f64);
fn seg(p: Pt, a: Pt, b: Pt) -> f64 { // distance from p to the segment a-b: project, clamp, measure
    let t = ((p.0 - a.0) * (b.0 - a.0) + (p.1 - a.1) * (b.1 - a.1)) / ((b.0 - a.0).powi(2) + (b.1 - a.1).powi(2));
    let t = t.max(0.0).min(1.0);
    ((p.0 - a.0 - t * (b.0 - a.0)).powi(2) + (p.1 - a.1 - t * (b.1 - a.1)).powi(2)).sqrt()
}
fn da(p: Pt) -> f64 { seg(p, (0.0, 0.0), (0.0, 4.0)) }
fn db(p: Pt) -> f64 { seg(p, (6.0, 0.0), (3.0, 4.0)) }
fn dial(p: Pt) -> f64 { da(p) / (da(p) + db(p)) } // Urysohn's dial in a metric space
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i64, d: i64) -> String { let g = gcd(n, d); if d / g == 1 { format!("{}", n / g) } else { format!("{}/{}", n / g, d / g) } }
// second road: wall A is x itself, wall B is the 3-4-5 line; exact fractions in tenths, as (num, den)
fn exact(x10: i64, y10: i64) -> ((i64, i64), (i64, i64), (i64, i64)) {
    let (a, b) = ((x10, 10), (240 - 4 * x10 - 3 * y10, 50)); // dA = x, dB = (24 - 4x - 3y)/5
    let (fnum, fden) = (a.0 * b.1, a.0 * b.1 + b.0 * a.1);
    (a, b, (fnum, fden))
}
fn dist(p: Pt, q: Pt) -> f64 { ((p.0 - q.0).powi(2) + (p.1 - q.1).powi(2)).sqrt() }
fn near(p: Pt, s: &[Pt]) -> f64 { s.iter().map(|&q| dist(p, q)).fold(f64::INFINITY, f64::min) }
struct Step { m: f64, lo: Vec<Pt>, hi: Vec<Pt> } // one Urysohn dial: -M/3 on lo, +M/3 on hi
impl Step { fn u(&self, p: Pt) -> f64 { let (l, h) = (near(p, &self.lo), near(p, &self.hi)); self.m / 3.0 * (l - h) / (l + h) } }
fn blend(p: Pt) -> f64 { // a second extension: weigh the nearest reading on each wall by the dial
    let ga = (2.0 * p.1.max(0.0).min(4.0) - 4.0) / 4.0;
    let t = ((-3.0 * (p.0 - 6.0) + 4.0 * p.1) / 5.0).max(0.0).min(5.0);
    (db(p) * ga + da(p) * (4.0 - 1.6 * t) / 4.0) / (da(p) + db(p))
}
fn dials(j: i64) -> [i64; 3] { // dial values in twelfths: 12 - (24ths of circle distance to the centre)
    let mut v = [0; 3];
    for (k, c) in [0i64, 8, 16].iter().enumerate() { v[k] = 12 - (j - c).rem_euclid(24).min((c - j).rem_euclid(24)); }
    v
}
fn dd(i: i64, j: i64) -> i64 { let (a, b) = (dials(i), dials(j)); 4 * (a[0] - b[0]).abs() + 2 * (a[1] - b[1]).abs() + (a[2] - b[2]).abs() } // 96ths
fn arc(i: i64, j: i64) -> i64 { (i - j).rem_euclid(24).min((j - i).rem_euclid(24)) } // 24ths
fn main() {
    let mut room = vec![];
    for i in 0..25 { for j in 0..17 { if 4 * i + 3 * j <= 96 { room.push((i as f64 / 4.0, j as f64 / 4.0)); } } }
    let gap = room.iter().map(|&p| da(p) + db(p)).fold(f64::INFINITY, f64::min);
    println!("room grid every 0.25 m: {} points; gap between walls {:.4} m", room.len(), gap);
    let (a, b, f) = exact(30, 10);
    println!("P=(3,1): dA={} dB={} dial={} = {:.4}; by projection {:.4}", fr(a.0, a.1), fr(b.0, b.1), fr(f.0, f.1), f.0 as f64 / f.1 as f64, dial((3.0, 1.0)));
    assert!(f.0 * 8 == f.1 * 5 && (dial((3.0, 1.0)) - 0.625).abs() < 1e-12);
    let mut row = vec![];
    for (x10, s) in [(0, "0"), (10, "1"), (20, "2"), (30, "3"), (40, "4"), (45, "4.5")] {
        let (_, _, f) = exact(x10, 20);
        let v = f.0 as f64 / f.1 as f64;
        assert!((dial((x10 as f64 / 10.0, 2.0)) - v).abs() < 1e-12);
        row.push(format!("{}:{:.4}", s, v));
    }
    println!("along y=2, x:dial  {}", row.join("  "));
    let ea: Vec<f64> = (0..5).map(|y| dial((0.0, y as f64))).collect();
    let eb: Vec<f64> = (0..6).map(|s| dial((6.0 - 3.0 * s as f64 / 5.0, 4.0 * s as f64 / 5.0))).collect();
    let fmt = |v: &[f64]| v.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(" ");
    println!("on wall A: {}; on wall B: {}", fmt(&ea), fmt(&eb));
    assert!(ea.iter().all(|&v| v == 0.0) && eb.iter().all(|&v| v > 1.0 - 1e-12));
    let mut slope: f64 = 0.0;
    for i in 0..room.len() { for j in 0..i { slope = slope.max((dial(room[i]) - dial(room[j])).abs() / dist(room[i], room[j])); } }
    println!("steepest dial change between grid points: {:.4} per m; proved bound 1/gap = {:.4}", slope, 1.0 / 3.0);
    assert!(slope > 0.0 && slope <= 1.0 / 3.0 + 1e-12);
    // Tietze: wall A reads 16 + 2y, wall B reads 24 - 1.6 s (s = metres from (6,0)); scaled g = (T - 20)/4
    let mut r: Vec<(Pt, f64)> = (0..25).map(|k| ((0.0, k as f64 / 6.0), (2.0 * k as f64 / 6.0 - 4.0) / 4.0)).collect();
    r.extend((0..25).map(|k| { let s = 5.0 * k as f64 / 24.0; ((6.0 - 3.0 * s / 5.0, 4.0 * s / 5.0), (4.0 - 1.6 * 5.0 * k as f64 / 24.0) / 4.0) }));
    let walls = r.clone();
    let (p, mut m) = ((3.0, 1.0), 1.0f64);
    let (mut us, mut errs): (Vec<Step>, Vec<f64>) = (vec![], vec![]);
    for n in 0..13 {
        errs.push(r.iter().map(|x| x.1.abs()).fold(0.0, f64::max));
        assert!((errs[n] - (2.0f64 / 3.0).powi(n as i32)).abs() < 1e-9); // the remainder meets (2/3)^n
        if n == 12 { break; }
        let st = Step { m, lo: r.iter().filter(|x| x.1 <= -m / 3.0 + 1e-12).map(|x| x.0).collect(),
                        hi: r.iter().filter(|x| x.1 >= m / 3.0 - 1e-12).map(|x| x.0).collect() };
        if n == 0 {
            println!("step 1 at P: nearest hot {:.4} m (sqrt37/3 = {:.4}), nearest cold {:.4} m (sqrt34/3 = {:.4}), u = {:.6}",
                     near(p, &st.hi), 37f64.sqrt() / 3.0, near(p, &st.lo), 34f64.sqrt() / 3.0, st.u(p));
        }
        r = r.iter().map(|&(q, v)| (q, v - st.u(q))).collect();
        us.push(st);
        m = 2.0 * m / 3.0;
    }
    let ff = |q: Pt, nn: usize| us[..nn].iter().map(|s| s.u(q)).sum::<f64>();
    println!("chart,n {}", (0..13).map(|n| n.to_string()).collect::<Vec<_>>().join(" "));
    println!("chart,log10 worst wall error {}", errs.iter().map(|e| format!("{:.3}", e.log10())).collect::<Vec<_>>().join(" "));
    println!("Tietze at P, degrees C: {}", [1, 2, 3, 6, 12].iter().map(|&nn| format!("N={}:{:.3}", nn, 20.0 + 4.0 * ff(p, nn))).collect::<Vec<_>>().join("  "));
    let top = room.iter().map(|&q| ff(q, 12).abs()).fold(0.0, f64::max);
    println!("after 12 steps: worst wall error {:.4} C; room spans {:.3} to {:.3} C (proved inside 20 +- {:.3})",
             4.0 * errs[12], 20.0 - 4.0 * top, 20.0 + 4.0 * top, 4.0 * (1.0 - (2.0f64 / 3.0).powi(12)));
    let (s34, s37) = (34f64.sqrt(), 37f64.sqrt());
    assert!(top <= 1.0 - (2.0f64 / 3.0).powi(12) + 1e-12 && (20.0 + 4.0 * ff(p, 1) - (20.0 + 4.0 / 3.0 * (s34 - s37) / (s34 + s37))).abs() < 1e-12);
    let bw = walls.iter().map(|&(q, v)| (blend(q) - v).abs()).fold(0.0, f64::max);
    let inside = room.iter().map(|&q| blend(q).abs()).fold(0.0, f64::max) <= 1.0;
    let cap = |b: bool| if b { "True" } else { "False" };
    println!("blend extension at P {:.3} C; largest miss on the walls below 1e-12 {}; inside 16 to 24 C {}", 20.0 + 4.0 * blend(p), cap(bw < 1e-12), cap(inside));
    assert!(bw < 1e-12 && (20.0 + 4.0 * blend(p) - 19.15).abs() < 1e-9);
    // metrisation on the circle, [0,1] with its ends glued: t = j/24; three tent dials centred at 0, 1/3, 2/3
    let pairs: Vec<(i64, i64)> = (0..24).flat_map(|i| (0..24).map(move |j| (i, j))).filter(|&(i, j)| i != j).collect();
    let mut tri = true;
    for i in 0..24 { for j in 0..24 { for k in 0..24 { tri &= dd(i, k) <= dd(i, j) + dd(j, k); } } }
    let pos = pairs.iter().all(|&(i, j)| dd(i, j) > 0);
    println!("dial metric on 24 points: zero only on the diagonal {}, symmetric {}, triangle on 13824 triples {}",
             cap(pos), cap(pairs.iter().all(|&(i, j)| dd(i, j) == dd(j, i))), cap(tri));
    assert!(tri && pos);
    let (mut lo, mut hi) = ((1000i64, 1i64), (0i64, 1i64)); // D / arc as num/den = dd / (4 arc)
    for &(i, j) in &pairs {
        let (n, d) = (dd(i, j), 4 * arc(i, j));
        if n * lo.1 < lo.0 * d { lo = (n, d); }
        if n * hi.1 > hi.0 * d { hi = (n, d); }
    }
    println!("D / arc length: from {} to {}", fr(lo.0, lo.1), fr(hi.0, hi.1));
    assert!(lo.0 * 2 == lo.1);
    let (d1, d23) = (dials(1), dials(23));
    println!("dials at 1/24: [{}, {}, {}], at 23/24: [{}, {}, {}] (twelfths); D(1/24, 23/24) = {} though |1/24 - 23/24| = 11/12; D(1/4, 3/4) = {}",
             d1[0], d1[1], d1[2], d23[0], d23[1], d23[2], fr(dd(1, 23), 96), fr(dd(6, 18), 96));
    assert!(dd(1, 23) < dd(6, 18));
    // what breaks
    println!("B touching A along (x,2), 0<x<=1: the dial must jump 1 across x m, slope {} per m at x = 0.1, 0.01, 0.001",
             [0.1f64, 0.01, 0.001].iter().map(|x| format!("{:.0}", 1.0 / x)).collect::<Vec<_>>().join(", "));
    println!("Tietze from (0,1], zigzag at 1, 1/2, ..., 1/6: {}", (1..7).map(|k| if k % 2 == 1 { "1" } else { "-1" }).collect::<Vec<_>>().join(" "));
    let ring: Vec<Pt> = (0..25).map(|k| ((2.0 * PI * k as f64 / 24.0).cos(), (2.0 * PI * k as f64 / 24.0).sin())).collect();
    let wind = ring.windows(2).map(|w| (w[0].0 * w[1].1 - w[0].1 * w[1].0).atan2(w[0].0 * w[1].0 + w[0].1 * w[1].1)).sum::<f64>() / (2.0 * PI);
    println!("circle-valued: the identity loop winds {:.6} times; a loop that shrinks in the disc winds 0", wind);
    assert!((wind - 1.0).abs() < 1e-9);
    let split: Vec<String> = [(1i64, 4i64), (1, 3), (1, 2)].iter().map(|&(n, d)| {
        let (a, b) = (d - n, 2 * n); format!("at {} shrinks by {}", fr(n, d), fr(a.max(b), d)) }).collect();
    println!("Tietze split: {}", split.join("; "));
    println!("doubled origin: 1/k near both origins forces D(0, 0') <= 2/k: {}", [10.0f64, 100.0, 1000.0].iter().map(|k| format!("{}", 2.0 / k)).collect::<Vec<_>>().join(", "));
    println!("ALL CHECKS PASS");
}
