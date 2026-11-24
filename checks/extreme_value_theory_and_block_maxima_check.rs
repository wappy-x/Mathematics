// Extreme value theory -- the check behind the card.  std only, no crates.
// Part 1: largest of n exponential waits minus ln n: exact formula, Gumbel limit, simulation.
// Part 2: max-stability of the three limits; the von Mises shape of three laws.
// Part 3: 30 yearly flood maxima simulated from a known GEV, fitted by maximum likelihood
//   (Nelder-Mead) and by a brute-force grid; the 100-year level by formula and by bisection.
struct Rng { s: u64 }
impl Rng {
    fn u(&mut self) -> f64 { // SplitMix64 mapped into (0, 1)
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.s ^ (self.s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}
fn gev_cdf(z: f64, mu: f64, sg: f64, xi: f64) -> f64 {
    let t = (z - mu) / sg; let w = 1.0 + xi * t;
    if xi.abs() < 1e-12 { return (-(-t).exp()).exp(); }
    if w <= 0.0 { return if xi > 0.0 { 0.0 } else { 1.0 }; }
    (-w.powf(-1.0 / xi)).exp()
}
fn gev_level(p: f64, mu: f64, sg: f64, xi: f64) -> f64 { // the level a year stays under with chance p
    let y = -p.ln();
    if xi.abs() < 1e-12 { mu - sg * y.ln() } else { mu + sg * (y.powf(-xi) - 1.0) / xi }
}
fn nll(x: &[f64], mu: f64, sg: f64, xi: f64) -> f64 { // minus the log-likelihood of the GEV
    if sg <= 0.0 { return f64::INFINITY; }
    let mut s = x.len() as f64 * sg.ln();
    for &v in x {
        let t = (v - mu) / sg;
        if xi.abs() < 1e-12 { s += t + (-t).exp(); continue; }
        let w = 1.0 + xi * t;
        if w <= 0.0 { return f64::INFINITY; }
        s += (1.0 + 1.0 / xi) * w.ln() + w.powf(-1.0 / xi);
    }
    s
}
fn nelder_mead(f: &dyn Fn(&[f64]) -> f64, p0: &[f64], steps: &[f64], iters: usize) -> (Vec<f64>, f64) {
    let d = p0.len();
    let mut pts: Vec<Vec<f64>> = vec![p0.to_vec()];
    for i in 0..d { pts.push((0..d).map(|j| p0[j] + if i == j { steps[j] } else { 0.0 }).collect()); }
    let mut val: Vec<f64> = pts.iter().map(|p| f(p)).collect();
    for _ in 0..iters {
        let mut idx: Vec<usize> = (0..=d).collect();
        idx.sort_by(|&a, &b| val[a].partial_cmp(&val[b]).unwrap());
        pts = idx.iter().map(|&i| pts[i].clone()).collect(); val = idx.iter().map(|&i| val[i]).collect();
        let c: Vec<f64> = (0..d).map(|j| (0..d).map(|i| pts[i][j]).sum::<f64>() / d as f64).collect();
        let r: Vec<f64> = (0..d).map(|j| c[j] + (c[j] - pts[d][j])).collect(); let fr = f(&r);
        if fr < val[0] {
            let e: Vec<f64> = (0..d).map(|j| c[j] + 2.0 * (c[j] - pts[d][j])).collect(); let fe = f(&e);
            if fe < fr { pts[d] = e; val[d] = fe; } else { pts[d] = r; val[d] = fr; }
        } else if fr < val[d - 1] { pts[d] = r; val[d] = fr; }
        else {
            let k: Vec<f64> = (0..d).map(|j| c[j] + 0.5 * (pts[d][j] - c[j])).collect(); let fk = f(&k);
            if fk < val[d] { pts[d] = k; val[d] = fk; } else {
                for i in 1..=d {
                    pts[i] = (0..d).map(|j| pts[0][j] + 0.5 * (pts[i][j] - pts[0][j])).collect(); val[i] = f(&pts[i]);
                }
            }
        }
    }
    let mut b = 0;
    for i in 1..=d { if val[i] < val[b] { b = i; } }
    (pts[b].clone(), val[b])
}
fn row(v: &[f64]) -> String { v.iter().map(|x| format!("{:5.3}", x)).collect::<Vec<_>>().join(" ") }
fn main() {
    // Part 1 -- the largest of n exponential waits
    let (n, x) = (365usize, 2.0f64); let nf = n as f64;
    let exact = (1.0 - (-x).exp() / nf).powf(nf);
    let gumbel = (-(-x).exp()).exp();
    let (mut rng, t, mut hits) = (Rng { s: 20261123 }, 20000usize, 0usize); // t simulated years of n daily waits
    for _ in 0..t {
        let mut m = f64::NEG_INFINITY;
        for _ in 0..n { m = m.max(-rng.u().ln()); }
        if m - nf.ln() <= x { hits += 1; }
    }
    let sim = hits as f64 / t as f64; let se = (sim * (1.0 - sim) / t as f64).sqrt();
    println!("ln 365 {:.6}  e^-2 {:.6}  e^-2/365 {:.9}", nf.ln(), (-x).exp(), (-x).exp() / nf);
    println!("exp max n=365 x=2: exact {:.6}  gumbel {:.6}  sim {:.4} (se {:.4})", exact, gumbel, sim, se);
    assert!((exact - gumbel).abs() < 1e-4 && (sim - exact).abs() < 4.0 * se);
    for &k in &[3.0f64, 10.0, 100.0, 365.0, 10000.0] {
        println!("n={:5}: P(max - ln n <= 2) = {:.6}", k as u64, (1.0 - (-x).exp() / k).powf(k));
    }
    let xs: Vec<f64> = (0..15).map(|i| i as f64 / 2.0 - 2.0).collect();
    println!("chart x: {}", xs.iter().map(|x| format!("{:5.1}", x)).collect::<Vec<_>>().join(" "));
    for &k in &[3.0f64, 365.0] {
        println!("chart n={:3}: {}", k as u64, row(&xs.iter().map(|x| (1.0 - (-x).exp() / k).max(0.0).powf(k)).collect::<Vec<_>>()));
    }
    println!("chart gumbel: {}", row(&xs.iter().map(|x| (-(-x).exp()).exp()).collect::<Vec<_>>()));
    let ns = (1.0 - (-x).exp()).powf(nf);
    println!("no shift: P(max <= 2) = {:.3e}", ns);
    // Part 2 -- max-stability: G(x)^k equals G at a shifted or rescaled point
    let (a, mut worst) = (1.5f64, 0.0f64); // Pareto shape a = 1.5, as on the heavy-tails card
    let fr = |y: f64| if y > 0.0 { (-y.powf(-a)).exp() } else { 0.0 }; // Frechet, shape 1/a
    let wb = |y: f64| if y < 0.0 { y.exp() } else { 1.0 }; // reversed Weibull, ceiling 0
    for &k in &[2.0f64, 10.0, 365.0] {
        for &x in &[-1.0f64, 0.5, 2.0] {
            let g = gev_cdf(x, 0.0, 1.0, 0.0).powf(k);
            worst = worst.max((g - gev_cdf(x - k.ln(), 0.0, 1.0, 0.0)).abs());
            worst = worst.max((fr(x + 2.0).powf(k) - fr((x + 2.0) * k.powf(-1.0 / a))).abs());
            worst = worst.max((wb(x - 3.0).powf(k) - wb((x - 3.0) * k)).abs());
        }
    }
    println!("max-stability, largest gap over 27 tests: {:.1e}", worst);
    assert!(worst < 1e-12);
    let par = (1.0 - 2.0f64.powf(-a) / nf).powf(nf); let uni = (1.0 - 1.0 / nf).powf(nf);
    let frl = (-2.0f64.powf(-a)).exp(); let wbl = (-1.0f64).exp();
    println!("pareto a=1.5, P(max <= 2 n^(2/3)): {:.4}  frechet {:.4}", par, frl);
    println!("uniform, P(n(max - 1) <= -1): {:.4}  weibull {:.4}", uni, wbl);
    assert!((par - frl).abs() < 2e-3 && (uni - wbl).abs() < 1e-3);
    let h = 1e-4; // (1 - F)/f; its slope far out is the shape xi
    let laws: [(&str, Box<dyn Fn(f64) -> f64>, Box<dyn Fn(f64) -> f64>, f64, f64); 3] = [
        ("exponential", Box::new(|x: f64| (-x).exp()), Box::new(|x: f64| (-x).exp()), 20.0, 0.0),
        ("pareto 1.5", Box::new(move |x: f64| x.powf(-a)), Box::new(move |x: f64| a * x.powf(-a - 1.0)), 50.0, 1.0 / a),
        ("uniform", Box::new(|x: f64| 1.0 - x), Box::new(|_x: f64| 1.0), 0.99, -1.0)];
    for (name, sf, pdf, x0, xi) in laws.iter() {
        let r = |x: f64| sf(x) / pdf(x);
        let sl = (r(x0 + h) - r(x0 - h)) / (2.0 * h);
        println!("von Mises slope, {}: {:+.4}", name, sl); assert!((sl - xi).abs() < 1e-6);
    }
    // Part 3 -- 30 yearly flood maxima, cubic metres per second
    let (mu0, sg0, xi0, years) = (1000.0f64, 250.0f64, 0.1f64, 30usize); let mut g = Rng { s: 7 };
    let data: Vec<f64> = (0..years).map(|_| gev_level(g.u(), mu0, sg0, xi0).round()).collect();
    println!("flows: {}", data.iter().map(|v| format!("{}", *v as i64)).collect::<Vec<_>>().join(" "));
    let mean = data.iter().sum::<f64>() / years as f64;
    let sd = (data.iter().map(|v| (v - mean).powi(2)).sum::<f64>() / (years as f64 - 1.0)).sqrt();
    let s0 = sd * 6.0f64.sqrt() / std::f64::consts::PI; let m0 = mean - 0.5772156649 * s0;
    let big = data.iter().cloned().fold(f64::MIN, f64::max);
    println!("mean {:.1}  sd {:.1}  largest {:.0}  start mu {:.1} sigma {:.1}", mean, sd, big, m0, s0);
    let f3 = |p: &[f64]| nll(&data, p[0], p[1], p[2]);
    let (p, best) = nelder_mead(&f3, &[m0, s0, 0.1], &[50.0, 25.0, 0.1], 1500);
    let (mu, sg, xi) = (p[0], p[1], p[2]);
    let z100 = gev_level(0.99, mu, sg, xi);
    println!("ML fit: mu {:.1}  sigma {:.1}  xi {:.4}  loglik {:.3}", mu, sg, xi, -best);
    let dens: f64 = data.iter().map(|&v| -((gev_cdf(v + 1e-3, mu, sg, xi) - gev_cdf(v - 1e-3, mu, sg, xi)) / 2e-3).ln()).sum();
    println!("log-likelihood from the slope of G: {:.3}", -dens); assert!((dens - best).abs() < 1e-6);
    let mut gb = (0.0, 0.0, 0.0, f64::INFINITY);
    for i in 0..61 { for j in 0..41 { for k in 0..51 {
        let (a1, b1, c1) = (700.0 + 10.0 * i as f64, 100.0 + 10.0 * j as f64, -0.4 + 0.02 * k as f64);
        let v = nll(&data, a1, b1, c1);
        if v < gb.3 { gb = (a1, b1, c1, v); }
    } } }
    println!("grid fit ({} points): mu {}  sigma {}  xi {:.2}  loglik {:.3}", 61 * 41 * 51, gb.0, gb.1, gb.2, -gb.3);
    assert!(best <= gb.3 && (gb.0 - mu).abs() <= 10.0 && (gb.1 - sg).abs() <= 10.0 && (gb.2 - xi).abs() <= 0.02);
    let bump = |q: usize, e: f64| vec![mu + if q == 0 { e } else { 0.0 }, sg + if q == 1 { e } else { 0.0 }, xi + if q == 2 { e } else { 0.0 }];
    let grad: Vec<f64> = [(0usize, 0.01f64), (1, 0.01), (2, 1e-5)].iter().map(|&(q, e)| (f3(&bump(q, e)) - f3(&bump(q, -e))) / (2.0 * e)).collect();
    let gmax = grad.iter().fold(0.0f64, |m, v| m.max(v.abs()));
    println!("largest slope of the log-likelihood at the fit: {:.4}", gmax); assert!(gmax < 0.01);
    let (mut lo, mut hi) = (mu, mu + 100.0 * sg);
    for _ in 0..200 { let mid = (lo + hi) / 2.0; if gev_cdf(mid, mu, sg, xi) < 0.99 { lo = mid } else { hi = mid } }
    let y1 = -0.99f64.ln(); println!("by hand: mu {:.3}  sigma {:.3}  xi {:.6}  y {:.6}  y^-xi {:.6}  sigma/xi {:.1}  rise {:.3}", mu, sg, xi, y1, y1.powf(-xi), sg / xi, sg * (y1.powf(-xi) - 1.0) / xi);
    println!("100-year level: formula {:.1}  bisection {:.1}  true {:.1}", z100, lo, gev_level(0.99, mu0, sg0, xi0));
    assert!((lo - z100).abs() < 1e-6);
    for &tp in &[2.0f64, 5.0, 10.0, 20.0, 50.0, 100.0, 200.0, 500.0] {
        println!("return period {:3} years: fitted {:7.1}  true {:7.1}", tp as u64, gev_level(1.0 - 1.0 / tp, mu, sg, xi), gev_level(1.0 - 1.0 / tp, mu0, sg0, xi0));
    }
    let (q, gbv) = nelder_mead(&|p: &[f64]| nll(&data, p[0], p[1], 0.0), &[m0, s0], &[50.0, 25.0], 800);
    println!("gumbel fit (xi forced to 0): mu {:.1}  sigma {:.1}  100-year {:.1}  loglik {:.3}", q[0], q[1], gev_level(0.99, q[0], q[1], 0.0), -gbv);
    assert!(-gbv <= -best);
    let mut boot: Vec<f64> = Vec::new();
    for _ in 0..200 {
        let y: Vec<f64> = (0..years).map(|_| gev_level(g.u(), mu, sg, xi)).collect();
        let (b, _v) = nelder_mead(&|p: &[f64]| nll(&y, p[0], p[1], p[2]), &[mu, sg, xi], &[50.0, 25.0, 0.1], 600);
        boot.push(gev_level(0.99, b[0], b[1], b[2]));
    }
    boot.sort_by(|a, b| a.partial_cmp(b).unwrap());
    println!("bootstrap 90% range of the 100-year level: {:.0} to {:.0}", boot[9], boot[189]);
    println!("chance of at least one 100-year flood: in 30 years {:.4}, in 100 years {:.4}", 1.0 - 0.99f64.powi(30), 1.0 - 0.99f64.powi(100));
    println!("ALL CHECKS PASS");
}
