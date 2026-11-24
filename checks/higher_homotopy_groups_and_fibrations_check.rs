// Higher homotopy groups and the Hopf fibration -- the same check as the Python, in Rust.  No crates.
// A point of S^3 is a pair of complex numbers (z, w) with |z|^2 + |w|^2 = 1.  The Hopf map h sends
// it to the ratio z/w on the Riemann sphere, drawn as the point (2 z conj(w), |z|^2 - |w|^2) of S^2.
use std::f64::consts::PI;

#[derive(Clone, Copy, PartialEq)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }
fn div(a: C, b: C) -> C { let n = b.re * b.re + b.im * b.im; let t = mul(a, c(b.re, -b.im)); c(t.re / n, t.im / n) }
fn phase(t: f64) -> C { c(t.cos(), t.sin()) }
fn scale(s: f64, a: C) -> C { mul(c(s, 0.0), a) }

fn f6(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-7 { 0.0 } else { x }) } // no "-0.000000"
fn cf(a: C) -> String { format!("{} {} {}i", f6(a.re), if a.im < -5e-7 { "-" } else { "+" }, f6(a.im.abs())) }
fn yes(ok: bool) -> &'static str { if ok { "yes" } else { "no" } }

fn bloch(z: C, w: C) -> [f64; 3] {           // road one to h: the point of S^2
    let q = mul(scale(2.0, z), c(w.re, -w.im));
    [q.re, q.im, abs(z).powi(2) - abs(w).powi(2)]
}
fn stereo(p: [f64; 3]) -> C { div(c(p[0], p[1]), c(1.0 - p[2], 0.0)) } // S^2 minus its top pole -> plane
fn winding(s: &[C]) -> f64 {                 // turns of a closed walk round 0, adding short angle steps
    s.windows(2).map(|v| { let q = div(v[1], v[0]); q.im.atan2(q.re) }).sum::<f64>() / (2.0 * PI)
}

struct Mix(u64);                             // SplitMix64, seed 2026: the same points in Python and Rust
impl Mix {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut x = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((x ^ (x >> 31)) >> 11) as f64 / 2f64.powi(53) * 2.0 - 1.0
    }
}
fn random_s3(g: &mut Mix) -> (C, C) {
    let v: Vec<f64> = (0..4).map(|_| g.next()).collect();
    let r = v.iter().map(|x| x * x).sum::<f64>().sqrt();
    (div(c(v[0], v[1]), c(r, 0.0)), div(c(v[2], v[3]), c(r, 0.0)))
}
fn s3_to_r3(a: C, b: C) -> [f64; 3] { [a.re / (1.0 - b.im), a.im / (1.0 - b.im), b.re / (1.0 - b.im)] }

fn gauss_link(p: (C, C), q: (C, C), n: usize) -> f64 { // road one to linking: Gauss's double sum
    let ring = |x: (C, C)| -> Vec<[f64; 3]> { (0..n).map(|k| { let e = phase(2.0 * PI * k as f64 / n as f64);
        s3_to_r3(mul(e, x.0), mul(e, x.1)) }).collect() };
    let (pp, qq) = (ring(p), ring(q));
    let mut tot = 0.0;
    for i in 0..n {
        let (a0, a1) = (pp[i], pp[(i + 1) % n]);
        for j in 0..n {
            let (c0, c1) = (qq[j], qq[(j + 1) % n]);
            let r: Vec<f64> = (0..3).map(|k| (a0[k] + a1[k] - c0[k] - c1[k]) / 2.0).collect();
            let u: Vec<f64> = (0..3).map(|k| a1[k] - a0[k]).collect();
            let v: Vec<f64> = (0..3).map(|k| c1[k] - c0[k]).collect();
            let cr = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]];
            tot += (0..3).map(|k| r[k] * cr[k]).sum::<f64>() / r.iter().map(|x| x * x).sum::<f64>().sqrt().powi(3);
        }
    }
    tot / (4.0 * PI)
}
fn disc_crossings(p: (C, C), q: (C, C)) -> i64 { // road two: crossings of the disc that fibre p bounds
    let d = sub(mul(p.0, q.1), mul(p.1, q.0));
    let vals: Vec<C> = (0..=360).map(|k| mul(phase(2.0 * PI * k as f64 / 360.0), d)).collect();
    vals.windows(2).filter(|v| v[0].re > 0.0 && v[1].re > 0.0)
        .map(|v| (v[1].im > 0.0) as i64 - (v[0].im > 0.0) as i64).sum()
}
fn tri_angle(a: [f64; 3], b: [f64; 3], d: [f64; 3]) -> f64 { // signed solid angle of a small spherical triangle
    let det = a[0] * (b[1] * d[2] - b[2] * d[1]) - a[1] * (b[0] * d[2] - b[2] * d[0]) + a[2] * (b[0] * d[1] - b[1] * d[0]);
    2.0 * det.atan2(1.0 + (0..3).map(|k| a[k] * b[k] + b[k] * d[k] + d[k] * a[k]).sum::<f64>())
}

fn main() {
    let r2 = 1.0 / 2f64.sqrt();
    let (z, w) = (c(r2, 0.0), c(r2, 0.0));   // the example qubit
    let b = bloch(z, w);
    println!("example (z, w) = ({}, {}): |z|^2 + |w|^2 = {}, chance of 0 = {}", f6(r2), f6(r2),
             f6(abs(z).powi(2) + abs(w).powi(2)), f6(abs(z).powi(2)));
    println!("  ratio z/w = {}; point of S^2 = ({}, {}, {})", cf(div(z, w)), f6(b[0]), f6(b[1]), f6(b[2]));
    let fib: Vec<(C, C)> = (0..12).map(|k| { let e = phase(2.0 * PI * k as f64 / 12.0); (mul(e, z), mul(e, w)) }).collect();
    let dev = fib.iter().map(|&(a, d)| abs(sub(div(a, d), c(1.0, 0.0)))).fold(0.0, f64::max);
    println!("  12 points (e^(it) z, e^(it) w), t = 0, 30, ..., 330 deg: every ratio within 1e-12 of 1: {}", yes(dev < 1e-12));
    println!("  t = 90 deg: ({}, {})", cf(fib[3].0), cf(fib[3].1));
    let (z2, w2) = (c(0.6, 0.0), c(0.0, 0.8));
    let (b2, q2) = (bloch(z2, w2), div(z2, w2));
    println!("second qubit (3/5, 4i/5): ratio = {}; point = ({}, {}, {}); stereographic = {}",
             cf(q2), f6(b2[0]), f6(b2[1]), f6(b2[2]), cf(stereo(b2)));
    let mut g = Mix(2026);
    let pts: Vec<(C, C)> = (0..1000).map(|_| random_s3(&mut g)).collect();
    let e1 = pts.iter().map(|&(a, d)| abs(sub(stereo(bloch(a, d)), div(a, d)))).fold(0.0, f64::max);
    let mut e2: f64 = 0.0;
    for &(a, d) in &pts { for t in [1.0, 2.0, 3.0] {
        let (x, y) = (bloch(a, d), bloch(mul(phase(t), a), mul(phase(t), d)));
        for k in 0..3 { e2 = e2.max((x[k] - y[k]).abs()) }
    } }
    println!("1000 random points: two roads to h agree within 1e-9: {}; a phase moves h under 1e-12: {}", yes(e1 < 1e-9), yes(e2 < 1e-12));
    let others = [("-1", (c(r2, 0.0), c(-r2, 0.0))), ("infinity", (c(1.0, 0.0), c(0.0, 0.0))), ("i", (c(r2, 0.0), c(0.0, -r2)))];
    let mut links = Vec::new();
    for (name, v) in others.iter() {
        let l = gauss_link((z, w), *v, 200); links.push(l);
        println!("fibre over 1 and fibre over {}: Gauss sum {:.3}, disc crossings {}", name, l, disc_crossings((z, w), *v));
    }
    let cross: Vec<i64> = (0..500).map(|i| disc_crossings(pts[2 * i], pts[2 * i + 1])).collect();
    let mut set = cross.clone(); set.sort(); set.dedup();
    println!("500 random pairs of fibres: disc crossings {:?}", set);
    println!("boundary map: the map (theta, phi) -> (theta, d phi) of S^2, lifted to S^3");
    let (tt, ff) = (24, 48);
    let mut bmap = Vec::new();
    for d in -2i64..3 {
        let df = d as f64;
        let pt = |i: usize, j: usize| { let (th, ph) = (PI * i as f64 / tt as f64, df * 2.0 * PI * j as f64 / ff as f64);
            [th.sin() * ph.cos(), th.sin() * ph.sin(), th.cos()] };
        let lift = |i: usize, j: usize| (c((PI * i as f64 / tt as f64 / 2.0).cos(), 0.0),
            scale((PI * i as f64 / tt as f64 / 2.0).sin(), phase(-df * 2.0 * PI * j as f64 / ff as f64)));
        let (mut deg, mut err) = (0.0, 0.0f64);
        for i in 0..tt { for j in 0..ff {
            deg += tri_angle(pt(i, j), pt(i + 1, j), pt(i + 1, j + 1)) + tri_angle(pt(i, j), pt(i + 1, j + 1), pt(i, j + 1));
        } }
        deg /= 4.0 * PI;
        for i in 0..=tt { for j in 0..ff {
            let (l, p) = (lift(i, j), pt(i, j));
            let x = bloch(l.0, l.1);
            for k in 0..3 { err = err.max((x[k] - p[k]).abs()) }
        } }
        let wind = winding(&(0..=ff).map(|j| lift(tt, j).1).collect::<Vec<C>>());
        bmap.push((d, deg, wind, err));
        println!("  d = {:2}: degree by area {}; lift within 1e-12: {}; rim in the fibre winds {}", d, f6(deg), yes(err < 1e-12), f6(wind));
    }
    let mut ops: Vec<[[usize; 3]; 3]> = Vec::new(); // Eckmann-Hilton: every operation on {0, 1, 2} with unit 0
    for v in 0..81 {
        let (a, b, d, e) = (v / 27 % 3, v / 9 % 3, v / 3 % 3, v % 3);
        ops.push([[0, 1, 2], [1, a, b], [2, d, e]]);
    }
    let r3 = 0..3usize;
    let comm_ok = |o: &[[usize; 3]; 3]| r3.clone().all(|a| r3.clone().all(|b| o[a][b] == o[b][a]));
    let (mut inter, mut same) = (0, 0);
    for o in &ops { for s in &ops {
        let ok = (0..81).all(|q| { let (a, b, c2, d) = (q / 27, q / 9 % 3, q / 3 % 3, q % 3); s[o[a][b]][o[c2][d]] == o[s[a][c2]][s[b][d]] });
        if ok { inter += 1; if o == s && comm_ok(o) { same += 1 } }
    } }
    let mon: Vec<&[[usize; 3]; 3]> = ops.iter().filter(|o| (0..27).all(|q| { let (a, b, e) = (q / 9, q / 3 % 3, q % 3); o[o[a][b]][e] == o[a][o[b][e]] })).collect();
    let comm = mon.iter().filter(|o| comm_ok(o)).count();
    println!("Eckmann-Hilton on 3 elements: {} operations, {} pairs; {} pairs obey the interchange law, {} of them equal and commutative",
             ops.len(), ops.len() * ops.len(), inter, same);
    println!("  monoids with unit 0: {}; commutative {}; not commutative {}", mon.len(), comm, mon.len() - comm);
    let pi_s1 = |k: usize| if k == 1 { "Z" } else { "0" };            // from the cover R -> S^1
    let pi_s3 = |k: usize| match k { 3 => "Z", 4 | 5 => "Z2", 6 => "Z12", _ => "0" }; // stated: Hatcher's table
    let pi_s2 = |k: usize| if k <= 2 { pi_s1(k - 1) } else { pi_s3(k) };  // exactness, neighbours 0
    for k in 1..4 {
        println!("Hopf sequence, k = {}: pi_{}(S^3) = {}, pi_{}(S^1) = {} -> pi_{}(S^2) = {}", k, k, pi_s3(k), k - 1,
                 if k > 1 { pi_s1(k - 1) } else { "point" }, k, pi_s2(k));
    }
    let s4 = ["0", "0", "0", "Z", "Z2", "Z2"];                         // S^4: stated, Hatcher's table
    for n in 1..5 {
        let row: Vec<String> = (1..7).map(|k| format!("{:>3}", match n { 1 => pi_s1(k), 2 => pi_s2(k), 3 => pi_s3(k), _ => s4[k - 1] })).collect();
        println!("pi_1..pi_6 of S^{}: {}", n, row.join(" "));
    }
    let loop1 = winding(&(0..361).map(|k| phase(2.0 * PI * k as f64 / 360.0)).collect::<Vec<C>>());
    println!("mistake, [0, 1) -> S^1 as a fibration: fibres are points, so exactness says pi_1(S^1) = 0; the loop e^(2 pi i t) winds {}", f6(loop1));
    println!("mistake, judge h by homology: H_3(S^2) = 0, so h gives 0 there; fibres still link {}", links[0].round());
    assert!((b[0] - 1.0).abs() < 1e-12 && dev < 1e-12 && e1 < 1e-9 && e2 < 1e-12); // two roads to h; phases invisible
    assert!(links.iter().all(|x| (x - 1.0).abs() < 0.01));            // Gauss sum near 1 ...
    assert!(set == vec![1] && others.iter().all(|(_, v)| disc_crossings((z, w), *v) == 1)); // ... crossings 1
    assert!(bmap.iter().all(|&(d, dg, wd, er)| (dg - d as f64).abs() < 1e-9 && (wd + d as f64).abs() < 1e-9 && er < 1e-12));
    assert!(inter == 9 && same == 9 && comm == 9 && mon.len() - comm == 2); // Eckmann-Hilton, exhaustively
    assert!(abs(sub(q2, stereo(b2))) < 1e-12 && abs(sub(q2, c(0.0, -0.75))) < 1e-12 && (loop1 - 1.0).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
