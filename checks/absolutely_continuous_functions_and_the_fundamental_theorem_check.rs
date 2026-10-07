// Absolutely continuous functions and the fundamental theorem -- the check behind the card.
// Rust std only.  The same trip, the same SplitMix64 draws, and the Cantor staircase in
// exact whole numbers: points counted in units of 1/3^12, counter readings in units of 1/2^12.

fn v(t: f64) -> f64 { // speed, km/h; each gear change switches it at an instant
    if t < 0.2 { 300.0 * t } else if t < 0.5 { 90.0 } else if t < 0.6 { 0.0 } else { 45.0 }
}

fn f(t: f64) -> f64 { // odometer, km, written from the legs, not from v
    if t <= 0.2 { 150.0 * t * t } else if t <= 0.5 { 6.0 + 90.0 * (t - 0.2) }
    else if t <= 0.6 { 33.0 } else { 33.0 + 45.0 * (t - 0.6) }
}

fn integral(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // midpoint rule
    let w = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 0..n { s += g(a + (i as f64 + 0.5) * w); }
    s * w
}

fn above(y: f64) -> f64 { // length of {t : v(t) > y}, read off the legs
    (0.2 - y / 300.0).max(0.0) + if y < 90.0 { 0.3 } else { 0.0 } + if y < 45.0 { 0.4 } else { 0.0 }
}

struct Rng(u64); // SplitMix64, seed 20260929
impl Rng {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn worst_move(g: &dyn Fn(f64) -> f64, delta: f64, trials: usize, r: &mut Rng) -> f64 {
    let mut worst: f64 = 0.0;
    for _ in 0..trials {
        let k = 1 + (r.next() * 8.0) as usize;
        let mut pts: Vec<f64> = (0..k).map(|_| r.next()).collect();
        pts.sort_by(|a, b| a.partial_cmp(b).unwrap());
        let ws: Vec<f64> = (0..k).map(|_| r.next()).collect();
        let tot: f64 = ws.iter().fold(0.0, |s, w| s + w);
        let iv: Vec<(f64, f64)> = pts.iter().zip(&ws).map(|(p, w)| (*p, (p + 0.999 * delta * w / tot).min(1.0))).collect();
        if (0..k - 1).any(|i| iv[i].1 > iv[i + 1].0) { continue; }
        worst = worst.max(iv.iter().fold(0.0, |s, (a, b)| s + (g(*b) - g(*a)).abs()));
    }
    worst
}

const D: u64 = 531441; // 3^12: every Cantor endpoint up to stage 12 is a whole number of these
const H: u64 = 4096; // 2^12: every counter reading at those endpoints is a whole number of these

fn cantor(x: u64) -> u64 { // the staircase, read off the ternary digits of x / 3^12
    if x == D { return H; }
    let (mut val, mut rest, mut p3, mut half) = (0, x, D / 3, H / 2);
    while rest != 0 {
        let d = rest / p3; rest %= p3;
        if d == 1 { return val + half; }
        val += half * (d / 2); p3 /= 3; half /= 2;
    }
    val
}

fn main() {
    let legs = [(0.0, 0.2), (0.2, 0.5), (0.5, 0.6), (0.6, 1.0)];
    let ls: Vec<String> = legs.iter().map(|&(a, b): &(f64, f64)| format!("{:.1}-{:.1}: {:.0} to {:.0}, {:.2}", a, b, v(a), v(b - 1e-12), f(b) - f(a))).collect();
    println!("legs, h: speed at start and end km/h, distance km: {}", ls.join("; "));
    let odo_pts: Vec<String> = (0..11).map(|i| format!("{:.2}", f(i as f64 / 10.0))).collect();
    println!("odometer km at t = 0.0, 0.1, ..., 1.0 h: {}", odo_pts.join(" "));
    let (odo, mid, lay) = (f(1.0) - f(0.0), integral(&v, 0.0, 1.0, 100000), integral(&above, 0.0, 90.0, 90000));
    println!("distance: odometer {:.4} | integral of speed, midpoint {:.4} | layer cake {:.4}", odo, mid, lay);
    assert!((mid - odo).abs() < 1e-6);
    assert!((lay - odo).abs() < 1e-6);
    let a_set = [(0.1, 0.3), (0.45, 0.55), (0.7, 0.95)];
    let d_a = a_set.iter().fold(0.0, |s, (a, b)| s + (f(*b) - f(*a)));
    let i_a = integral(&|t: f64| if a_set.iter().any(|(a, b)| *a <= t && t < *b) { v(t) } else { 0.0 }, 0.0, 1.0, 100000);
    println!("distance during A: odometer differences {:.4} | integral of speed over A {:.4}", d_a, i_a);
    assert!((d_a - i_a).abs() < 1e-6);
    for c in [0.2, 0.5, 0.6] {
        let (l, r) = ((f(c) - f(c - 0.001)) / 0.001, (f(c + 0.001) - f(c)) / 0.001);
        println!("gear change t = {}: left quotient {:.2}, right quotient {:.2} (h = 0.001)", c, l, r);
        assert!((l - v(c - 1e-9)).abs() < 0.2);
        assert!((r - v(c + 1e-9)).abs() < 0.2);
        assert!((r - l).abs() > 20.0);
    }
    let mut rng = Rng(20260929);
    let (mut ok, mut near) = (0, 0);
    for _ in 0..1000 {
        let t = 0.001 + 0.998 * rng.next();
        if [0.2, 0.5, 0.6].iter().any(|c: &f64| (t - c).abs() < 1e-6) { near += 1; continue; }
        if ((f(t + 1e-6) - f(t - 1e-6)) / 2e-6 - v(t)).abs() < 1e-4 { ok += 1; }
    }
    println!("1000 random times: quotient within 0.0001 of speed at {}, within 1e-6 of a gear change {}", ok, near);
    assert!(ok + near == 1000);
    let w_trip = worst_move(&f, 0.1 / 90.0, 2000, &mut rng);
    let hand = f(0.2 + 0.999 * 0.1 / 90.0) - f(0.2);
    println!("trip, eps 0.1 km, delta 0.1/90 = {:.6} h ({:.1} s): random worst {:.4}, all in the 90 km/h leg {:.4}", 0.1 / 90.0, 3600.0 * 0.1 / 90.0, w_trip, hand);
    assert!(w_trip < 0.1);
    assert!(hand < 0.1);
    let var = (0..1000).fold(0.0, |s, i| s + (f((i + 1) as f64 / 1000.0) - f(i as f64 / 1000.0)).abs());
    println!("AC gives BV: eps 1, delta 1/90, 91 pieces, variation at most 91; measured variation {:.4}", var);
    assert!(var <= 91.0);
    assert!((var - lay).abs() < 1e-6);
    let w_sq = worst_move(&|x: f64| x.sqrt(), 0.01, 2000, &mut rng);
    println!("sqrt: quotient at 0 is {:.2} (h = 0.01), {:.2} (h = 0.0001)", 0.01f64.sqrt() / 0.01, 0.0001f64.sqrt() / 0.0001);
    println!("sqrt, eps 0.1, delta 0.01: random worst {:.4}, one interval at 0 {:.4}", w_sq, 0.00999f64.sqrt());
    assert!(w_sq <= 0.01f64.sqrt());
    let m1 = integral(&|s: f64| 1.0 / (2.0 * s.sqrt()), 0.0, 1.0, 100);
    let m2 = integral(&|s: f64| 1.0 / (2.0 * s.sqrt()), 0.0, 1.0, 10000);
    println!("sqrt: integral of 1/(2 sqrt s) on [0,1], midpoint n=100 {:.4}, n=10000 {:.4}; sqrt 1 - sqrt 0 = 1", m1, m2);
    assert!((m1 - 1.0).abs() < 0.1);
    assert!((m2 - 1.0).abs() < (m1 - 1.0).abs());

    println!("stage n: kept intervals, their length, counter rise on them, rise on the gaps, gap length");
    let (mut kept, mut gaps): (Vec<(u64, u64)>, Vec<(u64, u64)>) = (vec![(0, D)], vec![]);
    let (mut ln, mut rise, mut pts) = (0u64, 0u64, vec![]);
    for n in 1..=12u32 {
        let mut new = vec![];
        for &(a, b) in &kept {
            let t = (b - a) / 3;
            new.push((a, a + t)); new.push((b - t, b)); gaps.push((a + t, b - t));
        }
        kept = new;
        if [1, 2, 3, 5, 10, 12].contains(&n) {
            ln = kept.iter().map(|(a, b)| b - a).sum();
            rise = kept.iter().map(|(a, b)| cantor(*b) - cantor(*a)).sum();
            let grise: u64 = gaps.iter().map(|(a, b)| cantor(*b) - cantor(*a)).sum();
            let gl: u64 = gaps.iter().map(|(a, b)| b - a).sum();
            println!("stage {:2}: {:4} | {:.6} | {:.4} | {:.4} | {:.6}", n, kept.len(), ln as f64 / D as f64,
                     rise as f64 / H as f64, grise as f64 / H as f64, gl as f64 / D as f64);
            assert!(ln * 3u64.pow(n) == D * 2u64.pow(n)); // length is (2/3)^n exactly
            assert!(rise == cantor(D) - cantor(0));
            assert!(grise == 0);
            assert!(kept.iter().all(|&(a, b)| (cantor(b) - cantor(a)) * 2u64.pow(n) == H)); // each kept interval rises 1/2^n
            if n == 3 { for &(a, b) in &kept { pts.push((a, cantor(a))); pts.push((b, cantor(b))); } }
            if n == 10 {
                let (a, b) = kept[0];
                println!("stage 10, one interval: length {:.7}, rise {:.7}", (b - a) as f64 / D as f64,
                         (cantor(b) - cantor(a)) as f64 / H as f64);
            }
        }
    }
    let n12 = (1..40u32).find(|&n| 100 * 2u128.pow(n) < 3u128.pow(n)).unwrap();
    println!("cantor, eps 0.5, delta 0.01: first stage below delta {}, length {:.6}, rise {:.4}", n12, ln as f64 / D as f64, rise as f64 / H as f64);
    let fig: Vec<String> = pts.iter().map(|(x, y)| format!("{:.2},{:.2}", 60.0 + 200.0 * (*x as f64 / D as f64), 220.0 - 200.0 * (*y as f64 / H as f64))).collect();
    println!("figure, stage-3 staircase at 200 units per unit, origin (60, 220): {}", fig.join(" "));
}
