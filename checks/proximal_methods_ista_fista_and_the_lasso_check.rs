// Proximal gradient on a lasso -- the check behind the card; std only.
// A garden centre explains weekly sales (GBP thousand, measured from the average week) by
// 200 candidate signals over 100 weeks.  Every signal shares half its swing with one
// seasonal factor.  Truth: nine signals matter, noise SD 1.  Minimise
// F(x) = 1/2 |y - Ax|^2 + LAM |x|_1 by ISTA, by FISTA and by coordinate descent.
// The coefficients x are called b below; a[j] is signal j's column.
const N: usize = 100; const P: usize = 200; const LAM: f64 = 40.0; const RHO: f64 = 0.5;
const K: usize = 3000;

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 { // SplitMix64: a draw in (0, 1]
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 * 2f64.powi(-53)
    }
    fn normal(&mut self) -> f64 { // Box-Muller, cosine half only
        let u = self.uniform();
        (-2.0 * u.ln()).sqrt() * (2.0 * std::f64::consts::PI * self.uniform()).cos()
    }
}
fn dot(u: &[f64], v: &[f64]) -> f64 { u.iter().zip(v).fold(0.0, |s, (a, b)| s + a * b) }
fn l1(b: &[f64]) -> f64 { b.iter().fold(0.0, |s, x| s + x.abs()) }
fn soft(v: f64, t: f64) -> f64 { (v.abs() - t).max(0.0).copysign(v) + 0.0 } // prox of t|.|
fn kept(b: &[f64]) -> usize { b.iter().filter(|x| **x != 0.0).count() }

struct Lasso { a: Vec<Vec<f64>>, y: Vec<f64> }
impl Lasso {
    fn ab(&self, b: &[f64]) -> Vec<f64> {
        (0..N).map(|i| (0..P).filter(|&j| b[j] != 0.0).fold(0.0, |s, j| s + b[j] * self.a[j][i])).collect()
    }
    fn at(&self, r: &[f64]) -> Vec<f64> { self.a.iter().map(|c| dot(c, r)).collect() } // A'r
    fn resid(&self, b: &[f64]) -> Vec<f64> { self.y.iter().zip(self.ab(b)).map(|(u, v)| u - v).collect() }
    fn f(&self, b: &[f64]) -> f64 { let r = self.resid(b); 0.5 * dot(&r, &r) + LAM * l1(b) }
    fn dual_gap(&self, b: &[f64]) -> f64 { // F(b) minus a dual value: a bound on F(b) - F*
        let r = self.resid(b);
        let s = (LAM / self.at(&r).iter().fold(0.0f64, |m, x| m.max(x.abs()))).min(1.0);
        let d = self.y.iter().zip(&r).fold(0.0, |acc, (u, v)| acc + (u - s * v) * (u - s * v));
        self.f(b) - (0.5 * dot(&self.y, &self.y) - 0.5 * d)
    }
    fn run(&self, k_max: usize, step: f64, thr: f64, momentum: bool, subgrad: bool) -> (Vec<f64>, Vec<f64>, Vec<usize>) {
        let (mut b, mut z, mut t) = (vec![0.0; P], vec![0.0; P], 1.0f64);
        let (mut hist, mut kp) = (vec![self.f(&b)], vec![P]);
        for _ in 0..k_max {
            let g: Vec<f64> = self.at(&self.ab(&z).iter().zip(&self.y).map(|(u, w)| u - w).collect::<Vec<_>>());
            let bn: Vec<f64> = z.iter().zip(&g).map(|(x, gi)| if subgrad {
                x - step * (gi + LAM * ((*x > 0.0) as i32 - (*x < 0.0) as i32) as f64)
            } else { soft(x - step * gi, thr) }).collect();
            let tn = if momentum { (1.0 + (1.0 + 4.0 * t * t).sqrt()) / 2.0 } else { 1.0 };
            z = bn.iter().zip(&b).map(|(u, w)| u + (t - 1.0) / tn * (u - w)).collect();
            b = bn; t = tn; hist.push(self.f(&b)); kp.push(kept(&b));
        }
        (b, hist, kp)
    }
    fn cd(&self, sweeps: usize) -> (Vec<f64>, Vec<f64>) { // road 2: one signal at a time
        let (mut b, mut r) = (vec![0.0; P], self.y.clone());
        let nn: Vec<f64> = self.a.iter().map(|c| dot(c, c)).collect();
        let mut hist = vec![self.f(&b)];
        for _ in 0..sweeps {
            for j in 0..P {
                let new = soft(dot(&self.a[j], &r) + nn[j] * b[j], LAM) / nn[j];
                if new != b[j] { for i in 0..N { r[i] -= (new - b[j]) * self.a[j][i]; } b[j] = new; }
            }
            hist.push(self.f(&b));
        }
        (b, hist)
    }
}
fn prox_by_search(v: f64, t: f64) -> f64 { // minimise t|x| + (x - v)^2 / 2 by golden section
    let (mut lo, mut hi, g) = (-v.abs() - 1.0, v.abs() + 1.0, (5f64.sqrt() - 1.0) / 2.0);
    for _ in 0..200 {
        let (a, b) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if t * a.abs() + (a - v) * (a - v) / 2.0 < t * b.abs() + (b - v) * (b - v) / 2.0 { hi = b } else { lo = a }
    }
    (lo + hi) / 2.0
}

fn main() {
    let mut rng = Rng(11);
    let mut truth = vec![0.0; P];
    truth[..9].copy_from_slice(&[3.0, -2.5, 2.0, -2.0, 1.5, 1.5, -1.2, 1.0, 1.0]);
    let f: Vec<f64> = (0..N).map(|_| rng.normal()).collect(); // the seasonal factor
    let mut a = Vec::new(); // a[j] = signal j over the 100 weeks, standardised
    for _ in 0..P {
        let c: Vec<f64> = (0..N).map(|i| RHO.sqrt() * f[i] + (1.0 - RHO).sqrt() * rng.normal()).collect();
        let m = c.iter().sum::<f64>() / N as f64;
        let c: Vec<f64> = c.iter().map(|t| t - m).collect();
        let sd = (dot(&c, &c) / N as f64).sqrt();
        a.push(c.iter().map(|t| t / sd).collect::<Vec<f64>>());
    }
    let y: Vec<f64> = (0..N).map(|i| dot(&(0..9).map(|j| a[j][i]).collect::<Vec<_>>(), &truth[..9]) + rng.normal()).collect();
    let m = y.iter().sum::<f64>() / N as f64;
    let ls = Lasso { a, y: y.iter().map(|t| t - m).collect() };
    let mut v = vec![1.0; P]; // power iteration: L = largest eigenvalue of A'A
    for _ in 0..200 { let w = ls.at(&ls.ab(&v)); let n = dot(&w, &w).sqrt(); v = w.iter().map(|t| t / n).collect(); }
    let av = ls.ab(&v);
    let l = dot(&av, &av); let al = 1.0 / l;
    let eig_res = ls.at(&av).iter().zip(&v).fold(0.0, |s, (x, w)| s + (x - l * w) * (x - l * w)).sqrt();
    let c0 = ls.at(&ls.y);
    let cmax = c0.iter().fold(0.0f64, |m, x| m.max(x.abs()));
    println!("setup: {} weeks, {} signals, lambda {:.0} (the regularisation card's {:.0}), L {:.2}, step 1/L {:.8}", N, P, LAM, 2.0 * LAM, l, al);
    println!("lambda_max = max |A_j . y| = {:.2}: at or above it every coefficient is 0; F(0) = {:.2}", cmax, ls.f(&vec![0.0; P]));
    println!("first ISTA step from x = 0, signals 1, 2, 10, 11:");
    for j in [0usize, 1, 9, 10] {
        let (x1, xs) = (soft(al * c0[j], al * LAM), prox_by_search(al * c0[j], al * LAM));
        println!("  signal {:3}: A_j.y {:8.2}  step*A_j.y {:.6}  shrink {:.6}  x_1 {:.6}  by search {:.6}",
                 j + 1, c0[j], al * c0[j], al * LAM, x1, xs);
    }
    let kept1 = c0.iter().filter(|t| t.abs() > LAM).count();
    println!("  signals kept after step 1: {} (those with |A_j . y| > {:.0})", kept1, LAM);
    let (bi, hi, ki) = ls.run(K, al, al * LAM, false, false);
    let (bf, hf, kf) = ls.run(K, al, al * LAM, true, false);
    let (bstar, hc) = ls.cd(300);
    let (fs, gs) = (ls.f(&bstar), ls.dual_gap(&bstar));
    let d0 = dot(&bstar, &bstar); // |b_0 - b*|^2 with b_0 = 0
    let first = |h: &Vec<f64>| h.iter().position(|x| x - fs < 1e-6).map_or("none".to_string(), |k| k.to_string());
    let lg = |x: f64| x.max(1e-16).log10(); // log10, floored where the gap is exactly 0
    println!("F* = {:.6}, certified: dual gap {:.12}", fs, gs);
    println!("first within 0.000001 of F*: ISTA step {}, FISTA step {}, coordinate descent sweep {}",
             first(&hi), first(&hf), first(&hc));
    println!("   k  kept: ISTA  FISTA");
    for k in [1usize, 10, 50, 100, 200, 500, 1000] { println!("{:4} {:11} {:6}", k, ki[k], kf[k]); }
    println!("   k  log10 gap: ISTA  FISTA | log10 bound: ISTA  FISTA");
    let bi_bound = |k: usize| l * d0 / (2 * k) as f64;
    let bf_bound = |k: usize| 2.0 * l * d0 / ((k + 1) * (k + 1)) as f64;
    for k in [1usize, 10, 100, 1000, 3000] {
        println!("{:4} {:16.2} {:6.2} | {:17.2} {:6.2}", k, lg(hi[k] - fs), lg(hf[k] - fs),
                 bi_bound(k).log10(), bf_bound(k).log10());
    }
    let ks: Vec<usize> = (0..=2000).step_by(200).collect();
    let row = |h: &Vec<f64>| ks.iter().map(|&k| format!("{:6.2}", lg(h[k] - fs))).collect::<Vec<_>>().join(" ");
    println!("chart, k      {}", ks.iter().map(|k| format!("{:6}", k)).collect::<Vec<_>>().join(" "));
    println!("chart, ISTA   {}", row(&hi));
    println!("chart, FISTA  {}", row(&hf));
    let rises = |h: &Vec<f64>| (0..1000).filter(|&k| h[k + 1] > h[k]).count();
    println!("steps where F rose, of the first 1000: ISTA {}, FISTA {}", rises(&hi), rises(&hf));
    let gstar = ls.at(&ls.resid(&bstar));
    let kkt = bstar.iter().zip(&gstar).fold(0.0f64, |m, (b, g)| m.max(if *b != 0.0 {
        (g - LAM * 1f64.copysign(*b)).abs() } else { (g.abs() - LAM).max(0.0) }));
    let gap_cd = bf.iter().zip(&bstar).fold(0.0f64, |m, (a, b)| m.max((a - b).abs()));
    println!("optimality conditions at coordinate descent's answer, worst miss: {:.9}", kkt);
    println!("FISTA against coordinate descent, largest coefficient gap: {:.9}", gap_cd);
    println!("kept: FISTA {}, ISTA {}, coordinate descent {}", kept(&bf), kept(&bi), kept(&bstar));
    for j in 0..P {
        if bf[j] != 0.0 {
            let bar = "#".repeat((10.0 * bf[j].abs()).round() as usize);
            println!("  signal {:3}  {:<28}  {:5.2}  true {:5.2}", j + 1, bar, bf[j], truth[j]);
        }
    }
    println!("F* splits as half squared misses {:.2} plus charge {:.2}", fs - LAM * l1(&bstar), LAM * l1(&bstar));
    let (_, hb, _) = ls.run(100, 3.0 * al, 3.0 * al * LAM, false, false);
    let (bl, hl, _) = ls.run(50, al, LAM, false, false);
    let (bs, hs, _) = ls.run(K, al, 0.0, false, true);
    println!("mistake, step 3/L: log10 F after 100 steps {:.2}", hb[100].log10());
    println!("mistake, shrink by lambda not step*lambda: kept {}, F {:.2}", kept(&bl), hl[50]);
    println!("mistake, subgradient steps: kept {}, F - F* after {} steps {:.4}", kept(&bs), K, hs[K] - fs);
    assert!(eig_res < 1e-6 * l); // L is an eigenvalue of A'A
    assert!((0..P).all(|j| (soft(al * c0[j], al * LAM) - prox_by_search(al * c0[j], al * LAM)).abs() < 1e-7));
    assert!(gs.abs() < 1e-6 && kkt < 1e-6 && gap_cd < 1e-5); // certificate; two roads agree
    assert!((1..=K).all(|k| hi[k] - fs <= bi_bound(k))); // ISTA's rate
    assert!((1..=K).all(|k| hf[k] - fs <= bf_bound(k))); // FISTA's rate
    assert!((0..K).all(|k| hi[k + 1] <= hi[k] + 1e-9)); // ISTA never goes uphill
    assert!(hb[100] > 1e6 * hb[0] && hl[50] == ls.f(&vec![0.0; P]));
    println!("ALL CHECKS PASS");
}
