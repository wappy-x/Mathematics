// An American put as an obstacle problem: strike $100, six months left. Rust std only.
// Road 1 solves the variational inequality on a log-price grid: step the equation, lift onto the payoff.
// Road 2 solves the early-exercise integral equation for the boundary alone. Road 3 is a binomial tree.
const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20; const T: f64 = 0.5; const S0: f64 = 100.0;
const MU: f64 = R - Q - 0.5 * SIG * SIG; // drift of log price in the pricing world
const LEFT: [f64; 7] = [0.5, 0.4, 0.3, 0.2, 0.1, 0.05, 0.01]; // years left, for the boundary chart

fn ncdf(x: f64) -> f64 { // normal CDF from its Taylor series, no erf
    if x.abs() > 9.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let (mut s, mut t, mut k) = (x, x, 1.0);
    while t.abs() > 1e-17 * s.abs() { k += 2.0; t *= x * x / k; s += t; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * 3.141592653589793f64).sqrt()
}
fn d12(s: f64, b: f64, u: f64) -> (f64, f64) {
    let d1 = ((s / b).ln() + (R - Q + 0.5 * SIG * SIG) * u) / (SIG * u.sqrt()); (d1, d1 - SIG * u.sqrt())
}
fn euro(s: f64, u: f64) -> f64 { // European put with u years left
    let (d1, d2) = d12(s, K, u); K * (-R * u).exp() * ncdf(-d2) - s * (-Q * u).exp() * ncdf(-d1)
}
fn root<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 { // bisection on a sign change
    let mut flo = f(lo);
    for _ in 0..50 {
        let m = 0.5 * (lo + hi); let fm = f(m);
        if (fm > 0.0) == (flo > 0.0) { lo = m; flo = fm; } else { hi = m; }
    }
    0.5 * (lo + hi)
}
fn psi(s: f64) -> f64 { (K - s).max(0.0) } // the obstacle: what exercising pays

// ---- road 1: projected explicit scheme in x = ln(S/K) on [-0.8, 0.8], ratio sig^2 dt / h^2 = 0.8
struct Run { s: Vec<f64>, v: Vec<f64>, g: Vec<f64>, push: Vec<f64>, seen: Vec<f64> }
fn edge(s: &[f64], v: &[f64], g: &[f64]) -> f64 { // last contact node, then V - psi ~ c (x - xb)^2 above it
    let i = (0..s.len()).filter(|&k| s[k] < K && v[k] - g[k] < 1e-12).max().unwrap();
    let (d1, d2) = ((v[i + 1] - g[i + 1]).sqrt(), (v[i + 2] - g[i + 2]).sqrt()); s[i + 1] * (s[i + 2] / s[i + 1]).powf(-d1 / (d2 - d1))
}
fn grid(h: f64) -> Run {
    let n = (1.6 / h).round() as usize; let nt = (T * SIG * SIG / (0.8 * h * h)).round() as usize; let dt = T / nt as f64;
    let s: Vec<f64> = (0..=n).map(|i| K * (-0.8 + i as f64 * h).exp()).collect();
    let g: Vec<f64> = s.iter().map(|&x| psi(x)).collect();
    let (a, b) = (0.5 * SIG * SIG / (h * h), MU / (2.0 * h));
    let (mut v, mut old, mut lv) = (g.clone(), g.clone(), vec![0.0; n + 1]); let mut seen = vec![0.0; 7];
    for step in 1..=nt {
        old = v.clone();
        for i in 1..n { lv[i] = a * (old[i + 1] - 2.0 * old[i] + old[i - 1]) + b * (old[i + 1] - old[i - 1]) - R * old[i]; }
        v = (0..=n).map(|i| if i == 0 { g[0] } else if i == n { 0.0 } else { g[i].max(old[i] + dt * lv[i]) }).collect();
        for (k, &t) in LEFT.iter().enumerate() {
            if (step as f64 * dt * 1e6).round() == (t * 1e6).round() { seen[k] = edge(&s, &v, &g); }
        }
    }
    let push = (0..n).map(|i| (v[i] - old[i]) / dt - lv[i]).collect(); // -(V_t + LV) on the last step
    Run { s, v, g, push, seen }
}

// ---- road 2: early-exercise integral equation, marched back from expiry on 100 bunched dates
fn prem(s: f64, us: &[f64], bs: &[f64], i: usize) -> f64 { // discounted carry r K - q S below the line
    let (mut tot, mut pu, mut pf) = (0.0, -1.0, 0.0);
    for j in (0..=i).rev() {
        let u = us[i] - us[j];
        let f = if u == 0.0 { 0.5 * (R * K - Q * s) } else {
            let (d1, d2) = d12(s, bs[j], u); R * K * (-R * u).exp() * ncdf(-d2) - Q * s * (-Q * u).exp() * ncdf(-d1) };
        if pu >= 0.0 { tot += 0.5 * (f + pf) * (u - pu); }
        pu = u; pf = f;
    }
    tot
}
struct Line { us: Vec<f64>, bs: Vec<f64> }
impl Line {
    fn b(&self, t: f64) -> f64 { // boundary t years left, linear between dates
        let t = t.max(0.0); let m = self.us.len() - 1;
        let i = (0..m).filter(|&k| self.us[k] <= t).max().unwrap();
        let w = (t - self.us[i]) / (self.us[i + 1] - self.us[i]); self.bs[i] + w * (self.bs[i + 1] - self.bs[i]) }
    fn v(&self, s: f64) -> f64 { // price: European put plus premium, Simpson in v = sqrt(u)
        if s <= self.bs[self.bs.len() - 1] { return K - s; }
        let n = 400; let hv = T.sqrt() / n as f64; let mut tot = 0.0;
        for k in 1..=n {
            let u = (k as f64 * hv).powi(2); let (d1, d2) = d12(s, self.b(T - u), u);
            let f = R * K * (-R * u).exp() * ncdf(-d2) - Q * s * (-Q * u).exp() * ncdf(-d1);
            tot += (if k % 2 == 1 { 4.0 } else if k < n { 2.0 } else { 1.0 }) * f * 2.0 * k as f64 * hv;
        }
        euro(s, T) + tot * hv / 3.0
    }
}

// ---- road 3: CRR binomial tree: at each node take the larger of exercising and waiting
fn tree(n: usize, rule: Option<f64>) -> f64 {
    let dt = T / n as f64; let u = (SIG * dt.sqrt()).exp();
    let p = ((((R - Q) * dt).exp()) - 1.0 / u) / (u - 1.0 / u); let d = (-R * dt).exp();
    let mut w: Vec<f64> = (0..=n).map(|j| psi(S0 * u.powi(2 * j as i32 - n as i32))).collect();
    for k in (0..n).rev() {
        for j in 0..=k {
            let s = S0 * u.powi(2 * j as i32 - k as i32); let c = d * (p * w[j + 1] + (1.0 - p) * w[j]);
            w[j] = match rule { None => psi(s).max(c), Some(b) => if s <= b { psi(s) } else { c } };
        }
    }
    w[0]
}

fn main() {
    // ---- the perpetual put: exact boundary, and trial triggers glued at matching height only
    let lam = (-MU - (MU * MU + 2.0 * SIG * SIG * R).sqrt()) / (SIG * SIG); let sstar = K * lam / (lam - 1.0);
    let trial = |l: f64| -> (f64, f64, f64) { // (K - L)(S/L)^lam above L: value matches, slope may not
        let jump = lam * (K - l) / l + 1.0;
        let low = [l + 1.0, l + 5.0, l + 10.0].iter().map(|&s| (K - l) * (s / l).powf(lam) - psi(s)).fold(f64::INFINITY, f64::min);
        (jump, (K - l) * (S0 / l).powf(lam), low)
    };
    let hs = [0.01, 0.005, 0.0025, 0.00125];
    let runs: Vec<Run> = hs.iter().map(|&h| grid(h)).collect();
    let fine = &runs[3]; let i0 = (0.8f64 / 0.00125).round() as usize;
    let (s, v, g, push) = (&fine.s, &fine.v, &fine.g, &fine.push);
    let m = 100; let us: Vec<f64> = (0..=m).map(|i| T * (i as f64 / m as f64).powi(2)).collect();
    let mut bs = vec![K];
    for i in 1..=m {
        let prev = bs.clone(); let usr = &us;
        let b = root(|b| { let mut t = prev.clone(); t.push(b); K - b - euro(b, usr[i]) - prem(b, usr, &t, i) }, 40.0, prev[i - 1]);
        bs.push(b);
    }
    let line = Line { us: us.clone(), bs: bs.clone() }; let (b1, a_tree) = (bs[m], tree(2000, None));
    println!("six-month put, S = {:.0}: grid {:.4}, integral {:.4}, tree {:.4} dollars", S0, v[i0], line.v(S0), a_tree);
    println!("European put {:.4} dollars, early-exercise premium {:.4}", euro(S0, T), line.v(S0) - euro(S0, T));
    let pg: Vec<f64> = runs.iter().zip(hs.iter()).map(|(rn, &h)| rn.v[(0.8 / h).round() as usize]).collect();
    let bg: Vec<f64> = runs.iter().map(|rn| edge(&rn.s, &rn.v, &rn.g)).collect();
    for k in 0..4 { println!("grid h = {:.5}: price {:.5} dollars, boundary {:.3} dollars, gap to integral road {:+.3}", hs[k], pg[k], bg[k], bg[k] - b1); }
    let ord: Vec<String> = (0..2).map(|k| format!("{:.2}", ((pg[k] - pg[k + 1]) / (pg[k + 1] - pg[k + 2])).ln() / 2f64.ln())).collect();
    println!("price order from successive halvings: {}", ord.join(", "));
    println!("boundary today: integral {:.3} dollars, finest grid {:.3} dollars", b1, bg[3]);
    let join = |xs: Vec<String>| xs.join(", ");
    println!("years left: {}, 0.00", join(LEFT.iter().map(|t| format!("{:.2}", t)).collect()));
    println!("boundary integral: {}, {:.2}", join(LEFT.iter().map(|&t| format!("{:.2}", line.b(t))).collect()), K);
    println!("boundary grid: {}, {:.2}", join(fine.seen.iter().map(|x| format!("{:.2}", x)).collect()), K);
    let xs: Vec<f64> = (0..9).map(|k| 70.0 + 5.0 * k as f64).collect();
    println!("chart S: {}", join(xs.iter().map(|x| format!("{:.0}", x)).collect()));
    println!("chart V: {}", join(xs.iter().map(|&x| format!("{:.2}", line.v(x))).collect()));
    println!("chart payoff: {}", join(xs.iter().map(|&x| format!("{:.2}", psi(x))).collect()));
    let cont: Vec<usize> = (1..s.len() - 1).filter(|&k| v[k] - g[k] > 1e-9).collect();
    let ex: Vec<usize> = (1..s.len() - 1).filter(|&k| !cont.contains(&k) && s[k] < K).collect();
    for &x in &[60.0, 70.0, 80.0] {
        let k = *ex.iter().min_by(|&&a, &&b| (s[a] - x).abs().partial_cmp(&(s[b] - x).abs()).unwrap()).unwrap();
        println!("push at S = {:.2}: grid {:.4}, rK - qS {:.4} dollars a year", s[k], push[k], R * K - Q * s[k]);
    }
    let sl: Vec<f64> = [2.0, 1.0, 0.5].iter().map(|&e| (line.v(b1 + e) - (K - b1)) / e).collect();
    println!("slope from the line out by 2, 1, 0.5 dollars: {:.4}, {:.4}, {:.4}", sl[0], sl[1], sl[2]);
    let gam = 2.0 * (R * K - Q * b1) / (SIG * SIG * b1 * b1);
    let (j, h) = (cont[0] + 1, hs[3]); // the finest grid's second node above the line; Gamma = (V_xx - V_x) / S^2
    let gm = ((v[j + 1] - 2.0 * v[j] + v[j - 1]) / (h * h) - (v[j + 1] - v[j - 1]) / (2.0 * h)) / (s[j] * s[j]);
    println!("curvature just above the line: predicted {:.5}, finest grid at {:.2} dollars {:.5} per dollar", gam, s[j], gm);
    println!("carry on the line rK - qB {:.4} dollars a year; predicted slope out by 2, 1, 0.5: {:.4}, {:.4}, {:.4}", R * K - Q * b1, -1.0 + gam, -1.0 + gam / 2.0, -1.0 + gam / 4.0);
    println!("perpetual: log-price drift mu {:.4}, lambda {:.6}, boundary {:.2}, value at 100 {:.4}", MU, lam, sstar, (K - sstar) * (S0 / sstar).powf(lam));
    for &l in &[50.0, sstar, 80.0] {
        let (jump, v100, low) = trial(l); let jump = (jump * 1e9).round() / 1e9 + 0.0;
        println!("trigger {:5.2}: slope jump {:+.4}, point push {:+.2}, value at 100 {:.4}, lowest gap to payoff {:+.4}",
                 l, jump, -0.5 * SIG * SIG * l * l * jump + 0.0, v100, low);
    }
    let (wf, wp, we) = (tree(2000, Some(b1)), tree(2000, Some(sstar)), tree(2000, Some(0.0)));
    println!("breaks on the tree: never exercise {:.4}; boundary frozen at {:.2}: {:.4}; perpetual {:.2}: {:.4}", we, b1, wf, sstar, wp);

    assert!((euro(S0, 1.0) - 6.330080627550).abs() < 1e-9); // CDF series: the one-year European put
    assert!((v[i0] - a_tree).abs() < 0.005 && (line.v(S0) - a_tree).abs() < 0.002); // three roads, one price
    assert!((bg[3] - b1).abs() < 0.02 && (bg[3] - b1).abs() < (bg[0] - b1).abs()); // two roads, one boundary
    assert!(LEFT.iter().zip(fine.seen.iter()).all(|(&t, &x)| (x - line.b(t)).abs() < 0.15));
    assert!(sstar < b1 && b1 < K && LEFT.windows(2).all(|w| line.b(w[0]) < line.b(w[1])));
    assert!(ex.iter().all(|&k| push[k] > 0.0)); // the floor pushes wherever V rests on it
    assert!(ex.iter().filter(|&&k| s[k] < b1 - 2.0).all(|&k| (push[k] - (R * K - Q * s[k])).abs() < 0.01));
    assert!((0..2).all(|k| (1.0 + sl[k]).abs() / (1.0 + sl[k + 1]).abs() > 1.8)); // slope tends to -1: no corner
    assert!((gm - gam).abs() < 0.02 * gam); // curvature jumps from 0 to 2(rK-qB)/(sig B)^2
    assert!(trial(sstar).0.abs() < 1e-12 && trial(80.0).0 > 0.0 && trial(50.0).2 < 0.0);
    assert!(trial(50.0).1.max(trial(80.0).1) < trial(sstar).1 && wf.max(wp).max(we) < a_tree - 0.05);
    assert!((we - euro(S0, T)).abs() < 0.002 && (wp - we).abs() < 0.001); // the far line almost never acts
    println!("ALL CHECKS PASS");
}
