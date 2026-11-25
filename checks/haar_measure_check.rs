// Haar measure -- the same check as the Python, in Rust.  No crates; f64::ln
// appears once, as a cross-check labelled 'library'.  Groups: the positive
// reals under multiplication, the ax + b group and GL2(R).  Every size is
// found by a closed form and again by brute force (grids, covers, sampling).
fn ln(x: f64) -> f64 {                       // ln x = 2 atanh((x-1)/(x+1)), summed
    let z = (x - 1.0) / (x + 1.0);
    let (mut s, mut p) = (0.0, z);
    for k in (1..800).step_by(2) { s += p / k as f64; p = p * z * z; }
    2.0 * s
}

fn mid(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {   // midpoint rule
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 0..n { s += f(a + (i as f64 + 0.5) * h); }
    h * s
}

fn cover(a: f64, b: f64, eps: f64) -> usize {   // Haar's count: slid copies of [1, 1+eps)
    let (mut n, mut x) = (0, a);
    while x < b { x *= 1.0 + eps; n += 1; }
    n
}

fn grid(dens: &dyn Fn(f64) -> f64, inside: &dyn Fn(f64, f64) -> bool,
        a0: f64, a1: f64, b0: f64, b1: f64, n: usize, m: usize) -> f64 {   // count cells
    let (ha, hb) = ((a1 - a0) / n as f64, (b1 - b0) / m as f64);
    let mut tot = 0.0;
    for i in 0..n {
        let a = a0 + (i as f64 + 0.5) * ha;
        let cnt = (0..m).filter(|&j| inside(a, b0 + (j as f64 + 0.5) * hb)).count();
        tot += dens(a) * cnt as f64 * hb * ha;
    }
    tot
}

fn in_e(a: f64, b: f64) -> bool { 1.0 <= a && a <= 2.0 && 0.0 <= b && b <= 1.0 }

struct Mix(u64);                             // SplitMix64, seed stated, written out
impl Mix {
    fn u(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * (2.0f64).powi(-53)
    }
}

fn in_box(x: [f64; 4]) -> bool {             // E: entries within 0.1 of the identity
    (x[0] - 1.0).abs() <= 0.1 && x[1].abs() <= 0.1 && x[2].abs() <= 0.1 && (x[3] - 1.0).abs() <= 0.1
}

fn nu_grid(g: usize) -> f64 {                // 4-D midpoint grid on E, g cells a side
    let (h, mut tot) = (0.2 / g as f64, 0.0);
    for i in 0..g.pow(4) {
        let mut q = [0.0; 4];
        for k in 0..4 { q[k] = (((i / g.pow(k as u32)) % g) as f64 + 0.5) * h - 0.1; }
        let d = (1.0 + q[0]) * (1.0 + q[3]) - q[1] * q[2];
        tot += h * h * h * h / (d * d);
    }
    tot
}

fn sample(inside: &dyn Fn([f64; 4]) -> bool, lo: [f64; 4], hi: [f64; 4], n: usize, rng: &mut Mix)
    -> (f64, f64, f64) {                     // Monte Carlo of dX/|det X|^2 and of dX
    let (mut vol, mut s, mut s2, mut hits) = (1.0, 0.0, 0.0, 0usize);
    for k in 0..4 { vol *= hi[k] - lo[k]; }
    for _ in 0..n {
        let mut y = [0.0; 4];
        for k in 0..4 { y[k] = lo[k] + (hi[k] - lo[k]) * rng.u(); }
        if inside(y) {
            let d = y[0] * y[3] - y[1] * y[2];
            let w = 1.0 / (d * d);
            s += w; s2 += w * w; hits += 1;
        }
    }
    let (mean, msq) = (s / n as f64, s2 / n as f64);
    (vol * mean, vol * ((msq - mean * mean) / n as f64).sqrt(), vol * hits as f64 / n as f64)
}

fn main() {
    let (ln2, ln10) = (ln(2.0), ln(10.0));
    let recip = |x: f64| 1.0 / x;
    println!("ln 2 = {:.12} (library {:.12}); log10 2 = {:.6}", ln2, 2f64.ln(), ln2 / ln10);
    println!("positive reals, ordinary length dx  vs  fair size dx/x");
    for (a, b) in [(1, 2), (2, 4), (4, 8), (5, 10)] {
        let (fa, fb) = (a as f64, b as f64);
        println!("  [{}, {}]: dx {}, dx/x closed form {:.6}, midpoint 100 cells {:.6}, 1000 cells {:.9}",
                 a, b, b - a, ln(fb / fa), mid(&recip, fa, fb, 100), mid(&recip, fa, fb, 1000));
    }
    for eps in [0.01, 0.001, 0.0001] {
        let (c12, c510, c110) = (cover(1.0, 2.0, eps), cover(5.0, 10.0, eps), cover(1.0, 10.0, eps));
        println!("  cover by [g, g(1+{})): [1,2] needs {}, [5,10] needs {}, [1,10] needs {}; ratio {:.6}",
                 eps, c12, c510, c110, c510 as f64 / c110 as f64);
    }
    let mut digits = [0usize; 10];                  // leading digits of 2^1 .. 2^1000, exact
    let mut p: Vec<u8> = vec![1];                   // decimal digits, lowest first
    for _ in 1..=1000 {
        let mut carry = 0;
        for d in p.iter_mut() { let v = *d * 2 + carry; *d = v % 10; carry = v / 10; }
        if carry > 0 { p.push(carry); }
        digits[*p.last().unwrap() as usize] += 1;
    }
    let frac_road = (1..=1000).filter(|&k| (k as f64 * ln2 / ln10) % 1.0 < ln2 / ln10).count();
    println!("Benford: 2^1..2^1000 starting with 1: {} by digits, {} by k log10 2 mod 1; Haar share {:.5}",
             digits[1], frac_road, ln2 / ln10);

    let in_ge = |a: f64, b: f64| in_e(a / 2.0, (b - 3.0) / 2.0);   // g*(a,b) = (2a, 2b + 3)
    let in_eg = |a: f64, b: f64| in_e(a / 2.0, b - 1.5 * a);       // (a,b)*g = (2a, 3a + b)
    let left = |a: f64| 1.0 / (a * a);
    let names = ["E", "gE", "Eg"];
    let closed = [(0.5, ln2), (0.5, 2.0 * ln2), (0.25, ln2)];
    let boxes: [(&dyn Fn(f64, f64) -> bool, f64, f64, f64, f64); 3] =
        [(&in_e, 1.0, 2.0, 0.0, 1.0), (&in_ge, 2.0, 4.0, 3.0, 5.0), (&in_eg, 2.0, 4.0, 3.0, 7.0)];
    println!("ax + b group, (a,b)(c,d) = (ac, ad + b), E = [1,2] x [0,1], g = (2, 3)");
    let mut brute = [(0.0, 0.0); 3];
    for i in 0..3 {
        let (ins, a0, a1, b0, b1) = boxes[i];
        let l = grid(&left, ins, a0, a1, b0, b1, 200, 1000);
        let r = grid(&recip, ins, a0, a1, b0, b1, 200, 1000);
        brute[i] = (l, r);
        println!("  {:2}: left da db/a^2 = {:.6} (grid {:.5}), right da db/a = {:.6} (grid {:.5})",
                 names[i], closed[i].0, l, closed[i].1, r);
    }
    let delta = brute[2].0 / brute[0].0;
    println!("  modular function at g: left size of Eg over E = {:.4}; 1/a = {:.4}", delta, 1.0 / 2.0);

    // A = [[2, 1], [0, 1]], det 2.  X is stored as [x11, x12, x21, x22].
    let in_ae = |y: [f64; 4]| in_box([(y[0] - y[2]) / 2.0, (y[1] - y[3]) / 2.0, y[2], y[3]]);
    let in_ea = |y: [f64; 4]| in_box([y[0] / 2.0, y[1] - y[0] / 2.0, y[2] / 2.0, y[3] - y[2] / 2.0]);
    let (nu16, nue_grid) = (nu_grid(16), nu_grid(32));             // second cut-off: 32^4 cells
    let mut rng = Mix(2026);
    let run_e = sample(&in_box, [0.9, -0.1, -0.1, 0.9], [1.1, 0.1, 0.1, 1.1], 100000, &mut rng);
    let run_ae = sample(&in_ae, [1.7, 0.7, -0.1, 0.9], [2.3, 1.3, 0.1, 1.1], 100000, &mut rng);
    let run_ea = sample(&in_ea, [1.8, 0.8, -0.2, 0.8], [2.2, 1.2, 0.2, 1.2], 100000, &mut rng);
    println!("GL2(R), A = [[2, 1], [0, 1]], det A = 2; E = matrices within 0.1 of I, dX-volume {:.4}",
             0.2 * 0.2 * 0.2 * 0.2);
    println!("  E : dX/|det X|^2 by midpoint grid, 16^4 cells {:.7}, 32^4 cells {:.7}", nu16, nue_grid);
    for (name, (nu, se, vol)) in [("E", run_e), ("AE", run_ae), ("EA", run_ea)] {
        println!("  {:2}: dX/|det X|^2 = {:.7} +- {:.7} (100000 samples), plain dX = {:.7}", name, nu, se, vol);
    }
    println!("  plain dX ratio AE/E = {:.3}; |det A|^2 = 4", run_ae.2 / run_e.2);
    println!("clock Z/12: each hour {:.6}; circle d(theta)/2pi: a 30-degree arc {:.6}", 1.0 / 12.0, 30.0 / 360.0);
    let r2 = 2f64.sqrt();
    println!("l2, not locally compact: |e1 - e2| = {:.6}, so balls of radius {:.6} round every e_k are disjoint inside one ball of radius {:.6}",
             r2, r2 / 2.0, 1.0 + r2 / 2.0);
    assert!((ln2 - 2f64.ln()).abs() < 1e-12 && (ln10 - 10f64.ln()).abs() < 1e-12);
    assert!([(1.0, 2.0), (5.0, 10.0)].iter().all(|&(a, b)| (mid(&recip, a, b, 1000) - ln2).abs() < 1e-6));
    assert!(cover(1.0, 2.0, 1e-4) == cover(5.0, 10.0, 1e-4));
    assert!((cover(5.0, 10.0, 1e-4) as f64 / cover(1.0, 10.0, 1e-4) as f64 - ln2 / ln10).abs() < 1e-4);
    assert!(digits[1] == frac_road && frac_road == 301);
    for i in 0..3 {                                         // grid against closed form
        assert!((brute[i].0 - closed[i].0).abs() < 0.01 * closed[i].0);
        assert!((brute[i].1 - closed[i].1).abs() < 0.01 * closed[i].1);
    }
    assert!((delta - 0.5).abs() < 0.01);
    assert!((run_e.0 - nue_grid).abs() < 4.0 * run_e.1);
    for run in [run_ae, run_ea] {                           // invariance, within 4 standard errors
        assert!((run.0 - nue_grid).abs() < 4.0 * run.1);
    }
    assert!((run_ae.2 / run_e.2 - 4.0).abs() < 0.05);
    println!("ALL CHECKS PASS");
}
