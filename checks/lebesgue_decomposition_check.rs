// Lebesgue decomposition -- the same check as the Python, in Rust.  No crates.
// Exact rationals by hand on i64 for the die; a hand-written exponential,
// Cantor function and Simpson rule for the line.  Waits in minutes.
use std::collections::HashSet;

#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug)]
struct Q { n: i64, d: i64 }                   // n / d, d > 0, lowest terms
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
fn add(a: Q, b: Q) -> Q { q(a.n * b.d + b.n * a.d, a.d * b.d) }
fn sub(a: Q, b: Q) -> Q { q(a.n * b.d - b.n * a.d, a.d * b.d) }
fn mul(a: Q, b: Q) -> Q { q(a.n * b.n, a.d * b.d) }
fn div(a: Q, b: Q) -> Q { q(a.n * b.d, a.d * b.n) }
fn fl(a: Q) -> f64 { a.n as f64 / a.d as f64 }
fn zero() -> Q { q(0, 1) }

fn exp_pos(x: f64) -> f64 {                   // e^x for x >= 0, summed term by term
    let (mut total, mut term, mut k) = (1.0f64, 1.0f64, 0.0f64);
    while term > 1e-17 * total { k += 1.0; term *= x / k; total += term; }
    total
}
fn e_neg(x: f64) -> f64 { 1.0 / exp_pos(x) }  // e^(-x)

fn cantor(mut p: i64, qd: i64) -> f64 {       // Cantor function at p/qd in [0, 1], base-3 digits
    if p >= qd { return 1.0; }
    let (mut value, mut half) = (0.0f64, 0.5f64);
    for _ in 0..40 {
        p *= 3;
        let d = p / qd; p %= qd;
        if d == 1 { return value + half; }    // inside a removed middle third: flat
        if d == 2 { value += half; }
        half /= 2.0;
    }
    value
}

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {   // Simpson's rule, 6000 steps
    let m = 6000; let h = (b - a) / m as f64;
    let s = g(a) + g(b) + (1..m).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h)).sum::<f64>();
    s * h / 3.0
}

fn mass(w: &[Q], a: &[usize]) -> Q { a.iter().fold(zero(), |s, &i| add(s, w[i])) }
fn decompose(mu: &[Q], nu: &[Q], sets: &[Vec<usize>]) -> (usize, Vec<usize>, Vec<Q>, Vec<Q>, Vec<Q>) {
    let nulls: Vec<&Vec<usize>> = sets.iter().filter(|a| mass(mu, a) == zero()).collect();
    let mut n = nulls[0].clone();             // largest mu-null set in nu's eyes, first found
    for a in &nulls { if fl(mass(nu, a)) > fl(mass(nu, &n)) { n = (*a).clone(); } }
    let s: Vec<Q> = (0..6).map(|i| if n.contains(&i) { nu[i] } else { zero() }).collect();
    let ac: Vec<Q> = (0..6).map(|i| sub(nu[i], s[i])).collect();
    let f = (0..6).map(|i| if mu[i] != zero() { div(ac[i], mu[i]) } else { zero() }).collect();
    (nulls.len(), n, s, ac, f)
}
fn fmt(v: &[Q]) -> String { v.iter().map(|&x| format!("{:?}", fl(x))).collect::<Vec<_>>().join(", ") }
fn census(n: u32, wj: f64, we: f64, wc: f64) -> (f64, f64, f64) {   // cells of width 3^-n on (-1, 2]
    let t = 3i64.pow(n);
    let (mut jump, mut steep, mut flat, mut prev) = (0.0, 0.0, we * e_neg(2.0), 0.0);   // beyond 2: density
    for j in (-t + 1)..=(2 * t) {
        let cur = if j < 0 { 0.0 } else { wj + we * (1.0 - e_neg(j as f64 / t as f64)) + wc * cantor(j, t) };
        let rise = cur - prev; prev = cur;
        if rise >= 0.05 { jump += rise } else if rise * t as f64 > 1.0 { steep += rise } else { flat += rise }
    }
    (jump, steep, flat)
}
fn split_count(nn: &HashSet<Q>, e: &[Q]) -> (usize, usize) {   // counting measure split on N: (would-be nu_ac(E), nu_s(E))
    (e.iter().filter(|x| !nn.contains(x)).count(), e.iter().filter(|x| nn.contains(x)).count())
}
fn j2(v: Vec<f64>) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    // ---- Road 0: the proof's construction on a die, every set listed ----
    let sets: Vec<Vec<usize>> = (0..64).map(|m: usize| (0..6).filter(|i| m >> i & 1 == 1).collect()).collect();
    let mu = [q(1, 4), q(1, 4), q(1, 4), q(1, 4), zero(), zero()];       // faces 5 and 6 never come up
    let nu = [q(1, 10), q(1, 10), q(1, 10), q(1, 10), q(2, 10), q(4, 10)];   // the loaded die
    let (nn, n, s, ac, f) = decompose(&mu, &nu, &sets);
    println!("die: mu = ({}); nu = ({})", fmt(&mu), fmt(&nu));
    let faces: Vec<usize> = n.iter().map(|i| i + 1).collect();
    println!("die: {} of 64 sets are mu-null; the one nu weighs most is faces {:?}, nu mass {:?}", nn, faces, fl(mass(&nu, &n)));
    println!("die: nu_s = ({}); nu_ac = ({}); density f = ({})", fmt(&s), fmt(&ac), fmt(&f));
    for a in &sets {                          // nu(A) = integral of f over A against mu + nu_s(A)
        assert!(mass(&nu, a) == add(a.iter().fold(zero(), |t, &i| add(t, mul(f[i], mu[i]))), mass(&s, a)));
    }
    let (mut total, mut splits) = (0, Vec::new());   // every split into tenths: odometer over faces
    let tops: Vec<i64> = nu.iter().map(|x| x.n * 10 / x.d).collect();
    let mut a = vec![0i64; 6];
    loop {
        total += 1;
        let aq: Vec<Q> = a.iter().map(|&k| q(k, 10)).collect();
        if (0..6).all(|i| mu[i] != zero() || aq[i] == zero())              // a << mu
            && (0..6).all(|i| mu[i] == zero() || sub(nu[i], aq[i]) == zero()) { splits.push(aq); }
        let mut i = 0;
        while i < 6 && a[i] == tops[i] { a[i] = 0; i += 1; }
        if i == 6 { break; }
        a[i] += 1;
    }
    println!("die: splits of nu into tenths checked: {}, valid: {}", total, splits.len());
    assert!(splits == vec![ac.clone()]);     // uniqueness, found by search
    let (_, n2, s2, _, f2) = decompose(&[q(1, 6); 6], &nu, &sets);
    println!("die against the fair die instead: largest null set {:?}, nu_s = ({}); density ({})", n2, fmt(&s2), fmt(&f2));

    // ---- Road 1: the bus, pieces from the story ----
    let f_ac = |x: f64| if x > 0.0 { 0.7 * (1.0 - e_neg(x)) } else { 0.0 };
    let f_d = |x: f64| if x >= 0.0 { 0.3 } else { 0.0 };
    let ff = |x: f64| f_ac(x) + f_d(x);
    let xs = [-1.0, -1e-9, 0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0];
    let lines: [(&str, &dyn Fn(f64) -> f64); 3] = [("F", &ff), ("F_ac", &f_ac), ("F_d", &f_d)];
    for (name, g) in lines.iter() {
        println!("chart, bus {} at -1, just below 0, 0, 0.5, 1, 1.5, 2, 3, 4, 5: {}", name, j2(xs.iter().map(|&x| g(x)).collect()));
    }
    println!("bus: F(1) = {:.6} = F_ac(1) {:.6} + F_d(1) {:.1}; P(0 < X <= 2) = {:.6}", ff(1.0), f_ac(1.0), f_d(1.0), ff(2.0) - ff(0.0));
    let dens = simpson(&|x| 0.7 * e_neg(x), 0.0, 40.0);                   // second road: integrate the density
    let mean = simpson(&|x| x * 0.7 * e_neg(x), 0.0, 40.0);                // the atom at 0 adds 0.3 x 0
    println!("bus, second road: integral of 0.7 e^(-x) over (0, 40] = {:.6}; jump 0.3; left for a staircase {:.6}; mean wait {:.6}",
             dens, ((1.0 - dens - 0.3) * 1e6).round() / 1e6 + 0.0, mean);
    assert!((dens - f_ac(40.0)).abs() < 1e-9 && (1.0 - dens - 0.3).abs() < 1e-9 && (mean - 0.7).abs() < 1e-9);

    // ---- Road 2: the three-piece law read from F alone, cell by cell ----
    let f3 = |j: i64, t: i64| 0.3 + 0.5 * (1.0 - e_neg(j as f64 / t as f64)) + 0.2 * cantor(j, t);
    println!("three-piece law: 0.3 at zero, 0.5 exponential at rate 1, 0.2 Cantor on [0, 1]");
    println!("chart, three-piece at 0, 1/9, ..., 1: F {}", j2((0..10).map(|k| f3(k, 9)).collect()));
    println!("chart, three-piece at 0, 1/9, ..., 1: staircase piece {}", j2((0..10).map(|k| 0.2 * cantor(k, 9)).collect()));
    println!("three-piece: F(1/3) = {:.6}; C(1/3) = {:?}", f3(3, 9), cantor(1, 3));
    println!("census of cells of width 3^-n on (-1, 2]: jump (rise >= 0.05), steep (slope > 1), flat");
    let (mut jump, mut steep, mut flat, mut bound) = (0.0, 0.0, 0.0, 0.0);
    for n in [2u32, 4, 6, 8, 10] {
        let r = census(n, 0.3, 0.5, 0.2); jump = r.0; steep = r.1; flat = r.2;
        bound = 0.5 * (2.0f64 / 3.0).powi(n as i32);
        println!("  n = {:2}: jump {:.6}, steep {:.6}, flat {:.6}; bound 0.5(2/3)^n = {:.6}", n, jump, steep, flat, bound);
    }
    assert!((jump - 0.3).abs() < 1e-12 && (steep - 0.2).abs() <= bound && (flat - 0.5).abs() <= bound);
    let (cj, cs, cf) = census(10, 0.0, 0.0, 1.0);
    let m = 3i64.pow(9);                      // layer cake: mean = integral of P(X > x)
    let mut cake = (0..m).map(|k| 0.2 * (1.0 - cantor(2 * k + 1, 2 * m)) + 0.5 * e_neg((2 * k + 1) as f64 / (2 * m) as f64)).sum::<f64>() / m as f64;
    cake += simpson(&|x| 0.5 * e_neg(x), 1.0, 40.0);
    println!("three-piece mean: pieces 0.3 x 0 + 0.5 x 1 + 0.2 x 0.5 = {:.6}; layer cake {:.6}", 0.3 * 0.0 + 0.5 * 1.0 + 0.2 * 0.5, cake);
    assert!((cake - 0.6).abs() < 1e-6);

    // ---- What breaks ----
    println!("mistake 1, density only on the bus: total {:.6}, missing {:.6}", dens, 1.0 - dens);
    println!("mistake 2, jumps plus density on the Cantor law alone, n = 10: jump {:.6}, flat {:.6}, steep {:.6}", cj, cf, cs);
    assert!(cj == 0.0 && cf == 0.0 && (cs - 1.0).abs() < 1e-12);
    println!("mistake 3, the loaded die against the fair die: singular part {:?}, not 0.6", fl(s2.iter().fold(zero(), |t, &x| add(t, x))));
    for (name, t) in [("dyadic", 4096i64), ("triadic", 6561)] {      // two length-zero candidates for N
        let nn: HashSet<Q> = (0..=t).map(|k| q(k, t)).collect();
        let x = (1..1_000_000i64).map(|m| q(1, m)).find(|y| !nn.contains(y)).unwrap();   // search: a point of [0, 1] off N
        let (ac, sing) = split_count(&nn, &[x]);
        println!("mistake 4, counting measure on [0, 1]: N = {} {} points, counting mass {}, length 0; first 1/m off N: {}/{}; nu_ac({{{}/{}}}) = {}, nu_s({{{}/{}}}) = {}, length 0",
                 nn.len(), name, nn.len(), x.n, x.d, x.n, x.d, ac, x.n, x.d, sing);
        assert!(ac == 1);                     // the would-be density part charges a set of length 0
    }
    println!("ALL CHECKS PASS");
}
