// Almgren-Chriss optimal execution -- the check behind the card.  Rust std only.
// Sell 100,000 Acme shares ($100, 1,000,000 traded a day) over one day in 13 half-hour slices.
// Roads: the sinh formula; coordinate descent on E + lambda V; a Monte Carlo of the trades
// themselves; random nudges that must never do better; the frontier's slope equal to -lambda.
const X: f64 = 100_000.0; const N: usize = 13; const T: f64 = 1.0; const S0: f64 = 100.0; // shares, slices, days, price
const EPS: f64 = 0.01; const GAM: f64 = 2e-7; const ETA: f64 = 2e-6; // half-spread; permanent and temporary impact slopes
const LAM: f64 = 1e-5;                    // the risk-averse trader: dollars of cost per dollar^2 of variance
fn tau() -> f64 { T / N as f64 }
fn sig() -> f64 { S0 * 0.20 / 252f64.sqrt() }
fn eta_t() -> f64 { ETA - 0.5 * GAM * tau() }

// expected cost and variance of a schedule x[0..N]
fn ev(x: &[f64], s: f64, g: f64, e: f64, et: f64) -> (f64, f64) {
    let mut sn = 0.0;
    for k in 1..=N { let n = x[k - 1] - x[k]; sn += n * n; }
    let sx: f64 = x[1..].iter().map(|v| v * v).sum();
    (0.5 * g * X * X + e * X + et / tau() * sn, s * s * tau() * sx)
}
fn ev0(x: &[f64]) -> (f64, f64) { ev(x, sig(), GAM, EPS, eta_t()) }
fn u(x: &[f64]) -> f64 { let (e, v) = ev0(x); e + LAM * v }

fn kappas(lam: f64, s: f64, et: f64) -> (f64, f64) {
    let kt = (lam * s * s / et).sqrt();                        // continuous-time urgency, per day
    (kt, (1.0 + 0.5 * (kt * tau()).powi(2)).acosh() / tau())   // and its discrete version
}
// road 1: holdings X sinh(k(T-t))/sinh(kT)
fn closed_form(lam: f64, s: f64, et: f64, discrete: bool) -> Vec<f64> {
    if lam == 0.0 { return (0..=N).map(|k| X * (1.0 - k as f64 / N as f64)).collect(); }
    let (kt, kd) = kappas(lam, s, et);
    let kap = if discrete { kd } else { kt };
    (0..=N).map(|k| X * (kap * (T - k as f64 * tau())).sinh() / (kap * T).sinh()).collect()
}
fn cf(lam: f64) -> Vec<f64> { closed_form(lam, sig(), eta_t(), true) }

// road 2: set each holding to its best value given its neighbours, repeat
fn coordinate_descent(lam: f64) -> (Vec<f64>, usize) {
    let mut x: Vec<f64> = (0..=N).map(|k| X * (1.0 - k as f64 / N as f64)).collect();
    let (a, b) = (eta_t() / tau(), lam * sig() * sig() * tau());
    for sweep in 1..=100000 {
        let mut change: f64 = 0.0;
        for k in 1..N {
            let new = a * (x[k - 1] + x[k + 1]) / (2.0 * a + b);
            change = change.max((new - x[k]).abs());
            x[k] = new;
        }
        if change < 1e-9 { return (x, sweep); }
    }
    panic!("no convergence");
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {                          // splitmix64, written out
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {                           // Box-Muller
        let r = (-2.0 * self.uniform().ln()).sqrt();
        r * (2.0 * std::f64::consts::PI * self.uniform()).cos()
    }
}
// road 3: trade the schedule against random prices, add up the cash
fn simulate(x: &[f64], paths: usize, noise: f64, rng: &mut Rng) -> (f64, f64) {
    let n: Vec<f64> = (1..=N).map(|k| x[k - 1] - x[k]).collect();
    let (mut tot, mut tot2) = (0.0, 0.0);
    for _ in 0..paths {
        let (mut s, mut cash) = (S0, 0.0);
        for k in 0..N {
            cash += n[k] * (s - EPS - ETA * n[k] / tau());      // half-spread and temporary impact
            s += noise * sig() * tau().sqrt() * rng.normal() - GAM * n[k]; // the price wanders, keeps the dent
        }
        let short = X * S0 - cash;
        tot += short; tot2 += short * short;
    }
    let m = tot / paths as f64;
    (m, (tot2 / paths as f64 - m * m).sqrt())
}
fn fmt(x: &[f64]) -> String { x.iter().map(|v| format!("{:.0}", v)).collect::<Vec<_>>().join(" ") }
fn report(name: &str, x: &[f64]) {
    let (e, v) = ev0(x);
    println!("{:<34} E {:>10.2}  sd {:>9.2}  U {:>10.2}", name, e, v.sqrt(), e + LAM * v);
}

fn main() {
    let (tau, sig, eta_t) = (tau(), sig(), eta_t());
    let mut rng = Rng(20260928);
    let (kt, kap) = kappas(LAM, sig, eta_t);
    let (x_opt, (x_cd, sweeps)) = (cf(LAM), coordinate_descent(LAM));
    let (e, v) = ev0(&x_opt);
    println!("sigma {:.6}  eta_tilde (millionths) {:.6}  kappa_tilde {:.6}  kappa {:.6}", sig, eta_t * 1e6, kt, kap);
    println!("sigma^2 {:.6}  kappa_tilde^2 {:.6}  cosh(kappa*tau) {:.6}", sig * sig, kt * kt, 1.0 + 0.5 * (kt * tau).powi(2));
    println!("kappa*tau {:.6}  holdings fall by e^-kappa*tau = {:.6} a slice at first", kap * tau, (-kap * tau).exp());
    for (lab, lam) in [("0", 0.0), ("1e-5", LAM), ("1e-4", 1e-4)] {
        println!("holdings lambda={}: {}", lab, fmt(&cf(lam)));
    }
    let trades: Vec<f64> = (1..=N).map(|k| x_opt[k - 1] - x_opt[k]).collect();
    println!("trades lambda=1e-5: {}", fmt(&trades));
    let gap = x_opt.iter().zip(&x_cd).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
    println!("road 2 coordinate descent: {} sweeps, largest gap to sinh schedule {:.9} shares", sweeps, gap);
    let (perm, spread) = (0.5 * GAM * X * X, EPS * X);
    println!("E parts: permanent {:.2}  spread {:.2}  temporary {:.2}", perm, spread, e - perm - spread);
    println!("optimal  E {:.2}  sd {:.2}  lambda*V {:.2}  U {:.2}", e, v.sqrt(), LAM * v, e + LAM * v);
    let m0 = simulate(&x_opt, 1, 0.0, &mut rng).0;
    println!("road 3, the same trades with the noise switched off: shortfall {:.2}", m0);
    let (m, sd) = simulate(&x_opt, 200000, 1.0, &mut rng);
    println!("road 3 Monte Carlo, 200000 days: mean {:.2}  sd {:.2}  (standard error of mean {:.2})", m, sd, sd / 200000f64.sqrt());
    let (mut worse, mut best) = (0, f64::INFINITY);
    for _ in 0..2000 {                          // road 4: nudge every interior holding by up to 2,000 shares
        let mut y = vec![x_opt[0]];
        for k in 1..N { y.push(x_opt[k] + 4000.0 * (rng.uniform() - 0.5)); }
        y.push(0.0);
        if u(&y) > u(&x_opt) { worse += 1; }
        best = best.min(u(&y));
    }
    println!("road 4: {} of 2000 nudged schedules cost more; cheapest is {:.2} above the optimum", worse, best - u(&x_opt));
    let h = 1e-8; let ((e1, v1), (e2, v2)) = (ev0(&cf(LAM - h)), ev0(&cf(LAM + h)));
    let slope = (e2 - e1) / (v2 - v1);
    println!("road 5: frontier slope dE/dV at lambda=1e-5, divided by -lambda: {:.6}", slope / -LAM);
    let (a, b) = (eta_t / tau, LAM * sig * sig * tau);
    let (mut d0, mut d1, mut ok) = (1.0, 2.0 * (2.0 * a + b), true); // leading minors of the tridiagonal Hessian
    for _ in 2..N {
        let d2 = 2.0 * (2.0 * a + b) * d1 - 4.0 * a * a * d0;
        d0 = d1; d1 = d2; ok = ok && d1 > 0.0;
    }
    let lmin = 2.0 * a * (2.0 - 2.0 * (std::f64::consts::PI / N as f64).cos()) + 2.0 * b;
    println!("smallest Hessian eigenvalue (millionths) {:.6}; leading minors positive: {}", lmin * 1e6, if ok { "yes" } else { "no" });

    let lam_for_sd = |target: f64| -> f64 {     // sd falls as lambda rises: bisect on log lambda
        let (mut lo, mut hi) = (1e-10f64.ln(), 1e-2f64.ln());
        for _ in 0..200 {
            let mid = 0.5 * (lo + hi);
            if ev0(&cf(mid.exp())).1.sqrt() > target { lo = mid; } else { hi = mid; }
        }
        lo.exp()
    };
    let (e0, v0) = ev0(&cf(0.0));
    println!("frontier end, sell evenly: E {:.2}  sd {:.2}", e0, v0.sqrt());
    for t in (20000..=65000).step_by(5000) {
        let l = lam_for_sd(t as f64);
        println!("frontier sd {}  lambda (x1e-5) {:.4}  E {:.0}", t, l * 1e5, ev0(&cf(l)).0);
    }
    println!("versus selling evenly: E +{:.2}  sd -{:.2}  U saved {:.2}", e - e0, v0.sqrt() - v.sqrt(), e0 + LAM * v0 - e - LAM * v);
    println!("first step off the even end, sd {:.0} -> 65000: E +{:.2}", v0.sqrt(), ev0(&cf(lam_for_sd(65000.0))).0 - e0);
    report("optimal", &x_opt);
    report("wrong: sell evenly, ignore risk", &cf(0.0));
    let mut dump = vec![X]; dump.extend(vec![0.0; N]); report("wrong: sell it all in slice one", &dump);
    report("wrong: sigma per year as per day", &closed_form(LAM, S0 * 0.20, eta_t, true));
    report("wrong: continuous kappa", &closed_form(LAM, sig, eta_t, false));
    report("wrong: eta in place of eta_tilde", &closed_form(LAM, sig, ETA, true));
    let tries = [("try: sigma doubled", 2.0 * sig, GAM, EPS, eta_t), ("try: eta halved", sig, GAM, EPS, 0.5 * ETA - 0.5 * GAM * tau),
                 ("try: gamma doubled", sig, 2.0 * GAM, EPS, ETA - GAM * tau), ("try: eps doubled", sig, GAM, 2.0 * EPS, eta_t)];
    for (name, s, g, ep, et) in tries {
        let x = closed_form(LAM, s, et, true);
        let (e, v) = ev(&x, s, g, ep, et);
        println!("{:<20} E {:.2}  sd {:.2}  held at 10:30 {:.0}", name, e, v.sqrt(), x[2]);
    }

    assert!(gap < 1e-3);                                                   // sinh formula and coordinate descent agree
    assert!((m0 - e).abs() < 1e-6);                                        // the trades, noise off, cost exactly E
    assert!((m - e).abs() < 4.0 * sd / 200000f64.sqrt());                 // the trades cost, on average, what E says
    assert!((sd / v.sqrt() - 1.0).abs() < 0.01);                           // and spread as widely as V says
    assert!(worse == 2000);                                                // no nudge beats the optimum
    assert!((slope / -LAM - 1.0).abs() < 1e-4);                            // lambda is the price of variance on the frontier
    assert!(ok && ((1..N).map(|j| 2.0 * a * (2.0 - 2.0 * (j as f64 * std::f64::consts::PI / N as f64).cos()) + 2.0 * b).product::<f64>() / d1 - 1.0).abs() < 1e-9); // eigenvalues vs determinant
    assert!([cf(0.0), closed_form(LAM, S0 * 0.20, eta_t, true), closed_form(LAM, sig, eta_t, false), closed_form(LAM, sig, ETA, true)].iter().all(|y| u(y) > u(&x_opt))); // every mistake scores worse
}
