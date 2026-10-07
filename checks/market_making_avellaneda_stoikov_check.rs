// Market making, Avellaneda-Stoikov -- the same check as the Python, in Rust.  No crates.
// Units: one lot = 100 shares; prices, sigma, distances in dollars per lot; time in trading days;
// gamma per dollar.  The normal average, maximiser, ODE solver and random numbers are written here.
use std::f64::consts::PI;

const S0: f64 = 10000.0; const SIG: f64 = 20.0; const GAM: f64 = 0.001; const K: f64 = 0.5;
const A: f64 = 30.0; const Q0: i32 = 5; const T: f64 = 1.0; const STEPS: usize = 1000; const QCAP: i32 = 10; const QM: i32 = 30;

fn conc(g: f64, k: f64) -> f64 { (1.0 + g / k).ln() / g }        // c: the price of being filled less often

fn quotes(s: f64, q: i32, tau: f64, g: f64, sig: f64, k: f64, skew: bool) -> (f64, f64, f64, f64) {
    let risk = g * sig * sig * tau;                                  // road 1: the closed form
    let r = if skew { s - q as f64 * risk } else { s };             // reservation centre
    let w = risk + 2.0 * conc(g, k);                                 // full spread
    (r - w / 2.0, r + w / 2.0, r, w)
}
fn qt(q: i32, tau: f64) -> (f64, f64, f64, f64) { quotes(S0, q, tau, GAM, SIG, K, true) }

fn cert_equiv(q: i32, tau: f64) -> f64 {                              // road 2: frozen inventory, bell-curve average
    let f = |z: f64| (-GAM * q as f64 * SIG * tau.sqrt() * z - z * z / 2.0).exp() / (2.0 * PI).sqrt();
    let (n, a, b, mut acc) = (4000, -12.0, 12.0, 0.0);
    let h = (b - a) / n as f64;
    for i in 1..n { acc += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    let m = (f(a) + f(b) + acc) * h / 3.0;
    q as f64 * S0 - m.ln() / GAM
}

fn gain(delta: f64, d: f64) -> f64 { A / GAM * (-K * delta).exp() * (1.0 - (-GAM * (delta + d)).exp()) }
fn golden_max<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {   // road 2 to the best distance
    let g = (5.0_f64.sqrt() - 1.0) / 2.0;
    for _ in 0..120 {
        let (x1, x2) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if f(x1) < f(x2) { lo = x1 } else { hi = x2 }
    }
    (lo + hi) / 2.0
}

fn exact_v(tau: f64, a: f64) -> Vec<f64> {                           // road 3: full HJB, linear after v = e^{k h}; RK4
    let eta = a * (1.0 + GAM / K).powf(-(1.0 + K / GAM));
    let alf = K * GAM * SIG * SIG / 2.0;
    let m = (2 * QM + 1) as usize;
    let rhs = |v: &Vec<f64>| -> Vec<f64> {
        (0..m).map(|i| {
            let q = i as f64 - QM as f64;
            let (lo, hi) = (if i > 0 { v[i - 1] } else { 0.0 }, if i < m - 1 { v[i + 1] } else { 0.0 });
            -alf * q * q * v[i] + eta * (lo + hi)
        }).collect()
    };
    let (n, mut v) = (2000, vec![1.0; m]);
    let h = tau / n as f64;
    let step = |v: &Vec<f64>, k: &Vec<f64>, c: f64| -> Vec<f64> { v.iter().zip(k).map(|(x, y)| x + c * y).collect() };
    for _ in 0..n {
        let k1 = rhs(&v); let k2 = rhs(&step(&v, &k1, h / 2.0));
        let k3 = rhs(&step(&v, &k2, h / 2.0)); let k4 = rhs(&step(&v, &k3, h));
        v = (0..m).map(|i| v[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])).collect();
    }
    v
}

fn exact_quotes(v: &[f64], q: i32) -> (f64, f64) {                   // distances from mid: ask, bid
    let i = (q + QM) as usize;
    (conc(GAM, K) + (v[i] / v[i - 1]).ln() / K, conc(GAM, K) + (v[i] / v[i + 1]).ln() / K)
}

struct Lcg { state: u64 }                                            // 32-bit linear congruential generator
impl Lcg {
    fn uniform(&mut self) -> f64 {
        self.state = (1664525 * self.state + 1013904223) & 0xFFFF_FFFF;
        (self.state as f64 + 0.5) / 4294967296.0
    }
    fn normal(&mut self) -> f64 {                                    // Box-Muller
        let (u1, u2) = (self.uniform(), self.uniform());
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn day(seed: u64, skew: bool) -> (f64, i32, Vec<i32>) {              // at most one fill per step, then the mid moves
    let (mut rng, mut s, mut q, mut cash, mut path) = (Lcg { state: seed }, S0, Q0, 0.0, Vec::new());
    let dt = T / STEPS as f64;
    for i in 0..STEPS {
        if i % 100 == 0 { path.push(q) }
        let (bid, ask, _, _) = quotes(s, q, T - i as f64 * dt, GAM, SIG, K, skew);
        let ra = if q > -QCAP { A * (-K * (ask - s)).exp() } else { 0.0 };
        let rb = if q < QCAP { A * (-K * (s - bid)).exp() } else { 0.0 };
        let u = rng.uniform();
        if u < ra * dt { cash += ask; q -= 1 } else if u < (ra + rb) * dt { cash -= bid; q += 1 }
        s += SIG * dt.sqrt() * rng.normal();
    }
    path.push(q);
    (cash + q as f64 * s - Q0 as f64 * S0, q, path)
}

fn show(label: &str, vals: &[f64], dp: usize) {
    let body: Vec<String> = vals.iter().map(|v| format!("{:.*}", dp, v)).collect();
    println!("{:<48}{}", label, body.join("  "));
}
fn line(name: &str, xs: &[f64]) { println!("{:<32}{}", name, xs.iter().map(|x| format!("{:6.2}", x)).collect::<Vec<_>>().join(" ")) }
fn line_i(name: &str, xs: &[i32]) { println!("{:<32}{}", name, xs.iter().map(|x| format!("{:6}", x)).collect::<Vec<_>>().join(" ")) }

fn main() {
    let (bid, ask, r, w) = qt(Q0, T);
    let rb_q = cert_equiv(Q0 + 1, T) - cert_equiv(Q0, T);           // most the dealer pays for one more lot
    let ra_q = cert_equiv(Q0, T) - cert_equiv(Q0 - 1, T);           // least the dealer takes for one lot fewer
    let risk = GAM * SIG * SIG * T;
    let da_g = golden_max(|x| gain(x, risk * (Q0 as f64 - 0.5)), -50.0, 50.0);
    let db_g = golden_max(|x| gain(x, -risk * (Q0 as f64 + 0.5)), -50.0, 50.0);
    let (v_full, v_none) = (exact_v(T, A), exact_v(T, 1e-9));      // with fills, and with none at all
    let ((ea, eb), (ta, tb)) = (exact_quotes(&v_full, Q0), exact_quotes(&v_none, Q0));
    let hs: Vec<Vec<f64>> = [exact_v(T - 1e-3, A), v_full.clone(), exact_v(T + 1e-3, A)].iter().map(|v| v.iter().map(|x| x.ln() / K).collect()).collect();
    let i5 = (Q0 + QM) as usize; let (d_a, d_b) = (hs[1][i5 - 1] - hs[1][i5], hs[1][i5 + 1] - hs[1][i5]);   // h_q = ln(v_q)/k
    let (da_x, db_x) = (golden_max(|x| gain(x, d_a), -50.0, 50.0), golden_max(|x| gain(x, d_b), -50.0, 50.0));
    let (hjb, fd) = (-GAM * SIG * SIG * (Q0 * Q0) as f64 / 2.0 + gain(da_x, d_a) + gain(db_x, d_b), (hs[2][i5] - hs[0][i5]) / 2e-3);
    show("concession c = ln(1 + gamma/k)/gamma", &[conc(GAM, K)], 6);
    show("risk per lot gamma sigma^2 T", &[risk], 6);
    show("1 closed form: centre r = S - q gamma sigma^2 T", &[r], 6);
    show("2 bell-curve average: reservation bid, ask", &[rb_q, ra_q], 6);
    show("2 bell-curve average: centre, gap", &[(rb_q + ra_q) / 2.0, ra_q - rb_q], 6);
    show("spread w = gamma sigma^2 T + 2c", &[w], 6);
    show("quotes per share, long 5 lots: bid, ask", &[bid / 100.0, ask / 100.0], 4);
    let (fb, fa, _, _) = qt(0, T);
    show("quotes per share, flat: bid, ask", &[fb / 100.0, fa / 100.0], 4);
    show("ask distance: closed form, golden search", &[ask - S0, da_g], 6);
    show("bid distance: closed form, golden search", &[S0 - bid, db_g], 6);
    show("fills per day at those distances: ask, bid", &[A * (-K * (ask - S0)).exp(), A * (-K * (S0 - bid)).exp()], 2);
    show("3 full HJB solve: ask distance, bid distance", &[ea, eb], 6);
    show("3 full HJB: centre shift, spread", &[(ea - eb) / 2.0, ea + eb], 6);
    show("3 full HJB with no fills: ask, bid distance", &[ta, tb], 6);
    show("3 golden search on solved h: ask, bid distance", &[da_x, db_x], 6);
    show("3 dh/dtau: finite difference, HJB right side", &[fd, hjb], 6);
    let cents = |x: f64| x - S0;                                     // dollars per lot from $10,000 = cents per share from $100
    let (qs1, qs2): (Vec<i32>, Vec<i32>) = ((-5..6).collect(), (0..11).collect());
    line_i("chart, inventory q (lots)", &qs1);
    line("chart, bid, cents from $100", &qs1.iter().map(|&q| cents(qt(q, T).0)).collect::<Vec<_>>());
    line("chart, ask, cents from $100", &qs1.iter().map(|&q| cents(qt(q, T).1)).collect::<Vec<_>>());
    line_i("chart, inventory q (lots)", &qs2);
    line("chart, closed-form centre shift", &qs2.iter().map(|&q| cents(qt(q, T).2)).collect::<Vec<_>>());
    line("chart, full-HJB centre shift", &qs2.iter().map(|&q| { let (a, b) = exact_quotes(&v_full, q); (a - b) / 2.0 }).collect::<Vec<_>>());
    for tau in [1.0, 0.5, 0.1] {
        let (b5, a5, _, _) = qt(5, tau); let (b0, a0, _, _) = qt(0, tau);
        show(&format!("time left {:.1}: long bid, ask; flat bid, ask", tau), &[b5 / 100.0, a5 / 100.0, b0 / 100.0, a0 / 100.0], 4);
    }
    for (name, cen) in [("wrong: skew added, not subtracted", S0 + Q0 as f64 * risk), ("wrong: sigma for sigma^2", S0 - Q0 as f64 * GAM * SIG),
                        ("wrong: tau left at 1 when 0.1 remains", S0 - Q0 as f64 * risk), ("  right at tau = 0.1", qt(Q0, 0.1).2)] {
        show(&format!("{}, centre", name), &[cen / 100.0], 4);
    }
    let ((pnl_s, _, path_s), (pnl_m, _, path_m)) = (day(20260928, true), day(20260928, false));
    line("story, fraction of the day", &(0..11).map(|i| i as f64 / 10.0).collect::<Vec<_>>());
    line_i("story, lots, skewed quotes", &path_s);
    line_i("story, lots, centred quotes", &path_m);
    show("story P&L: skewed, centred", &[pnl_s, pnl_m], 2);
    let mut stats = Vec::new();
    for skew in [true, false] {
        let runs: Vec<(f64, i32, Vec<i32>)> = (0..400).map(|j| day(1000 + j, skew)).collect();
        let mean = runs.iter().map(|x| x.0).sum::<f64>() / 400.0;
        let sd = (runs.iter().map(|x| (x.0 - mean).powi(2)).sum::<f64>() / 399.0).sqrt();
        stats.push([mean, sd, runs.iter().map(|x| x.1.abs() as f64).sum::<f64>() / 400.0]);
        show(&format!("400 days {}: mean P&L, sd, mean |q| end", if skew { "skewed" } else { "centred" }), &stats[stats.len() - 1], 2);
    }
    let g2 = quotes(S0, Q0, T, 0.002, SIG, K, true);
    show("try: gamma 0.002: centre, spread per share", &[g2.2 / 100.0, g2.3 / 100.0], 4);
    show("try: k 0.25: spread per share", &[quotes(S0, Q0, T, GAM, SIG, 0.25, true).3 / 100.0], 4);
    let s40 = quotes(S0, Q0, T, GAM, 40.0, K, true);
    show("try: sigma 40: centre, spread per share", &[s40.2 / 100.0, s40.3 / 100.0], 4);
    assert!(((rb_q + ra_q) / 2.0 - r).abs() < 1e-6 && (ra_q - rb_q - risk).abs() < 1e-6, "quadrature vs closed form");
    assert!((da_g - (ask - S0)).abs() < 1e-5 && (db_g - (S0 - bid)).abs() < 1e-5, "golden search vs c - d");
    assert!((ta - (ask - S0)).abs() < 1e-6 && (tb - (S0 - bid)).abs() < 1e-6, "HJB with no fills = frozen inventory");
    assert!((da_x - ea).abs() < 1e-5 && (db_x - eb).abs() < 1e-5 && (fd - hjb).abs() < 1e-4, "full solve satisfies the HJB");
    assert!(stats[0][1] < stats[1][1] && stats[0][2] < stats[1][2], "skew cuts risk and inventory");
    println!("ALL CHECKS PASS");
}
