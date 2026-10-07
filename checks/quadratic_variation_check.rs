// Quadratic variation -- the check behind the card.  Rust std only.
// A pollen grain's position W_t, in micrometres after t seconds, is Brownian
// motion: a step over dt seconds is normal, mean 0, variance dt square um.
// Road 1: the formulas E[Q_n] = t, Var Q_n = 2 t^2 / n, E[V_n] = sqrt(2 n t / pi).
// Road 2: the normal's moments E[Z^2], E[Z^4], E|Z| by Simpson's rule.
// Road 3: 400 seeded paths of 10000 steps, coarsened to 1000, 100, 10 steps.
use std::f64::consts::PI;
const SEED: u64 = 20260930;
const PATHS: usize = 400;
const FINE: usize = 10000;
const T: f64 = 1.0;
const MU: f64 = 3.0;
const GRIDS: [usize; 4] = [10, 100, 1000, 10000];

struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn unit(&mut self) -> f64 { // a uniform draw in [0, 1)
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * (1.0 / 9007199254740992.0)
    }
    fn normals(&mut self, k: usize) -> Vec<f64> { // Box-Muller, both outputs used
        let mut out = Vec::with_capacity(k);
        while out.len() < k {
            let r = (-2.0 * (1.0 - self.unit()).ln()).sqrt();
            let a = 2.0 * PI * self.unit();
            out.push(r * a.cos());
            out.push(r * a.sin());
        }
        out
    }
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let mut s = f(a) + f(b);
    for i in 1..m {
        s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h);
    }
    s * h / 3.0
}

fn coarsen(steps: &[f64], b: usize) -> Vec<f64> { // add b consecutive steps into one
    steps.chunks(b).map(|c| { let mut s = 0.0; for x in c { s += x; } s }).collect()
}

fn sq_abs(steps: &[f64]) -> (f64, f64) { // sum of squares, sum of sizes
    let (mut q, mut v) = (0.0, 0.0);
    for x in steps { q += x * x; v += x.abs(); }
    (q, v)
}

fn mean_se(xs: &[f64]) -> (f64, f64) {
    let mut m = 0.0;
    for x in xs { m += x; }
    m /= xs.len() as f64;
    let mut s = 0.0;
    for x in xs { s += (x - m) * (x - m); }
    (m, (s / (xs.len() - 1) as f64 / xs.len() as f64).sqrt())
}

fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * PI).sqrt() }

fn main() {
    let ez2 = simpson(&|z| z * z * phi(z), -12.0, 12.0, 4000);
    let ez4 = simpson(&|z| z * z * z * z * phi(z), -12.0, 12.0, 4000);
    let eaz = 2.0 * simpson(&|z| z * phi(z), 0.0, 12.0, 4000);

    let mut gen = SplitMix64 { s: SEED };
    let mut qs: Vec<Vec<f64>> = vec![Vec::new(); 4];
    let mut vs: Vec<Vec<f64>> = vec![Vec::new(); 4];
    let (mut left, mut right, mut w2, mut drift) = (Vec::new(), Vec::new(), Vec::new(), Vec::new());
    let (mut path1, mut steps1) = (Vec::new(), Vec::new());
    for p in 0..PATHS {
        let fine: Vec<f64> = gen.normals(FINE).iter().map(|z| z * (T / FINE as f64).sqrt()).collect();
        let s1000 = coarsen(&fine, 10);
        let s100 = coarsen(&s1000, 10);
        let s10 = coarsen(&s100, 10);
        for (g, st) in [&s10, &s100, &s1000, &fine].iter().enumerate() {
            let (q, v) = sq_abs(st);
            qs[g].push(q);
            vs[g].push(v);
        }
        let (mut w, mut l, mut r) = (0.0f64, 0.0f64, 0.0f64);
        let mut path = vec![0.0];
        for x in &s1000 {
            l += 2.0 * w * x; w += x; r += 2.0 * w * x; path.push(w);
        }
        left.push(l); right.push(r); w2.push(w * w);
        let ds: Vec<f64> = s1000.iter().map(|x| MU * T / 1000.0 + x).collect();
        drift.push(sq_abs(&ds).0);
        if p == 0 { path1 = path; steps1 = s1000; }
    }

    println!("seed {}, {} paths, {} steps each, t = {:.1} seconds", SEED, PATHS, FINE, T);
    println!("{:<44}{:10.6}{:10.6}{:10.6}", "road 2, Simpson: E[Z^2], E[Z^4], E|Z|", ez2, ez4, eaz);
    println!("{:<44}{:10.6}", "road 1, formula sd of Q at n = 1000", (2.0 * T * T / 1000.0).sqrt());
    println!("{:<44}{:10.6}", "road 2, sd from Simpson moments, n = 1000", ((ez4 - ez2 * ez2) / 1000.0).sqrt());
    let (q1, v1) = sq_abs(&steps1);
    let big = steps1.iter().fold(0.0f64, |m, x| if x.abs() > m { x.abs() } else { m });
    println!("{:<44}{:10.6}", "path 1, n = 1000: sum of squared steps", q1);
    println!("{:<44}{:10.6}", "path 1, n = 1000: sum of step sizes", v1);
    println!("{:<44}{:10.6}", "path 1, n = 1000: largest step size", big);
    println!("{:<44}{:10.3}", "house scale, 1000 s at one step a second", 1000.0 * q1);
    let mut rmss = Vec::new();
    println!("     n   Q path1   V path1    mean Q   se    rms err   se    formula   mean V    se    formula");
    for (g, &n) in GRIDS.iter().enumerate() {
        let nf = n as f64;
        let (mq, sq) = mean_se(&qs[g]);
        let (mv, sv) = mean_se(&vs[g]);
        let d: Vec<f64> = qs[g].iter().map(|x| (x - T) * (x - T)).collect();
        let (md, sd) = mean_se(&d);
        let rms = md.sqrt();
        rmss.push(rms * nf.sqrt());
        println!("{:>6}{:10.4}{:10.3}{:10.4}{:7.4}{:9.4}{:7.4}{:10.4}{:10.3}{:7.3}{:10.3}", n, qs[g][0], vs[g][0], mq, sq, rms,
                 sd / (2.0 * rms), T * (2.0 / nf).sqrt(), mv, sv, (2.0 * nf * T / PI).sqrt());
        assert!((md - 2.0 * T * T / nf).abs() < 4.0 * sd, "variance of Q must match 2 t^2 / n");
        assert!((mv - (nf * T).sqrt() * eaz).abs() < 4.0 * sv, "mean V must match sqrt(n t) E|Z|");
    }
    let j2 = |v: Vec<f64>| v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ");
    println!("chart, rms err x sqrt(n): {}   sqrt(2): {:.2}", j2(rmss), 2.0f64.sqrt());
    println!("chart, path 1 sizes: {}   squares: {}", j2(vs.iter().map(|v| v[0]).collect()), j2(qs.iter().map(|q| q[0]).collect()));
    let (mq, sq) = mean_se(&qs[2]);
    assert!((mq - T).abs() < 4.0 * sq, "mean of Q at n = 1000 must be t");
    assert!((ez4 - 3.0).abs() < 1e-9, "Simpson's E[Z^4] must be the normal's 3");

    println!("smooth path sin(2 pi t):  n   Q   n*Q   2n sin^2(pi/n)   V");
    for &n in GRIDS.iter() {
        let nf = n as f64;
        let st: Vec<f64> = (1..=n).map(|k| (2.0 * PI * k as f64 / nf).sin() - (2.0 * PI * (k - 1) as f64 / nf).sin()).collect();
        let (q, v) = sq_abs(&st);
        let sp = (PI / nf).sin();
        let exact = 2.0 * nf * sp * sp;
        println!("  {:>6}{:12.6}{:10.4}{:12.6}{:10.4}", n, q, nf * q, exact, v);
        assert!((q - exact).abs() < 1e-12, "direct sum must match the closed form");
    }
    println!("{:<44}{:10.4}", "  limit of n*Q, 2 pi^2", 2.0 * PI * PI);

    let (ml, sl) = mean_se(&left);
    let (mr, sr) = mean_se(&right);
    let (mw, sw) = mean_se(&w2);
    println!("{:<44}{:10.4}{:10.4}{:10.4}", "path 1: W_1^2, left sum, right sum", w2[0], left[0], right[0]);
    println!("{:<44}{:10.4}{:10.4}", "path 1: W_1^2 - left sum, (right - left)/2", w2[0] - left[0], (right[0] - left[0]) / 2.0);
    println!("{:<44}{:10.4}{:10.4}", "400 paths: mean W_1^2 (se)", mw, sw);
    println!("{:<44}{:10.4}{:10.4}", "400 paths: mean left sum (se)", ml, sl);
    println!("{:<44}{:10.4}{:10.4}", "400 paths: mean right sum (se)", mr, sr);
    assert!(ml.abs() < 4.0 * sl, "the left-point sum must average 0, not W_1^2");
    assert!((mr - 2.0 * T).abs() < 4.0 * sr, "the right-point sum must average 2t");
    let (md, sd) = mean_se(&drift);
    println!("{:<44}{:10.4}{:10.4}{:10.4}", format!("drift {:.1} um/s, n = 1000: path 1, mean (se)", MU), drift[0], md, sd);
    println!("{:<44}{:10.4}", "  formula t + mu^2 t^2 / n", T + MU * MU * T * T / 1000.0);
    assert!((md - (T + MU * MU * T * T / 1000.0)).abs() < 4.0 * sd, "drift adds only mu^2 t^2 / n");

    let mut best = vec![0.0f64; path1.len()]; // cut points chosen after seeing path 1
    for j in 1..path1.len() {
        let mut b = 0.0;
        for i in 0..j {
            let e = path1[j] - path1[i];
            let c = best[i] + e * e;
            if c > b { b = c; }
        }
        best[j] = b;
    }
    println!("{:<44}{:10.4}", "path 1: best partition of the 1000-step grid", best[path1.len() - 1]);
    println!("figure, path 1 at t = 0.00, 0.05, ..., 1.00:");
    println!("{}", j2((0..=1000).step_by(50).map(|k| path1[k]).collect()));
    println!("ALL CHECKS PASS");
}
