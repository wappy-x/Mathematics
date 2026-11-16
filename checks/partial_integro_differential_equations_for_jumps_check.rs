// When prices jump -- the check behind the card.  Standard library only, no crates.
// Acme at $100, a one-year call struck at $100; jumps arrive 0.5 times a year
// and multiply the price by Y, log Y normal with mean -0.10 and spread 0.15.
// Roads to the price: (1) Merton's series of Black-Scholes prices, (2) the
// PIDE on a grid in log price at three steps, (3) the PIDE's residual at the
// series by centred differences and Simpson's rule.
use std::f64::consts::PI;

const S0: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20;
const T: f64 = 1.0;
const LAM: f64 = 0.5; const MUJ: f64 = -0.10; const DEL: f64 = 0.15;

fn x0() -> f64 { S0.ln() }
fn kj(muj: f64) -> f64 { (muj + 0.5 * DEL * DEL).exp() - 1.0 }   // average jump k

fn ncdf(x: f64) -> f64 {                          // normal area, Marsaglia's series
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut s, mut b, mut i) = (x, x, 1.0);
    while s + b * x * x / (i + 2.0) != s { i += 2.0; b *= x * x / i; s += b; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}

fn bs(s_: f64, s: f64, q: f64, sig: f64) -> f64 { // Black-Scholes call, s years to go
    let v = sig * s.sqrt();
    let d1 = ((s_ / K).ln() + (R - q + 0.5 * sig * sig) * s) / v;
    s_ * (-q * s).exp() * ncdf(d1) - K * (-R * s).exp() * ncdf(d1 - v)
}

fn merton_full(s_: f64, s: f64, terms: usize, lam: f64, muj: f64, comp: bool) -> f64 {
    let k = kj(muj);
    let (mut tot, mut w) = (0.0, (-lam * s).exp());
    for n in 0..terms {
        if n > 0 { w *= lam * s / n as f64; }
        let qn = Q + (if comp { lam * k } else { 0.0 }) - n as f64 * (1.0 + k).ln() / s;
        tot += w * bs(s_, s, qn, (SIG.powi(2) + n as f64 * DEL.powi(2) / s).sqrt());
    }
    tot
}
fn merton(s_: f64, s: f64) -> f64 { merton_full(s_, s, 40, LAM, MUJ, true) }

fn g(z: f64) -> f64 { (-0.5 * ((z - MUJ) / DEL).powi(2)).exp() / (DEL * (2.0 * PI).sqrt()) }

fn simpson(f: &dyn Fn(f64) -> f64) -> f64 {      // integral of g(z) f(z) over mean +- 8 spreads
    let m = 400;
    let (a, h) = (MUJ - 8.0 * DEL, 16.0 * DEL / m as f64);
    let mut t = 0.0;
    for i in 0..=m {
        let c = if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        let z = a + i as f64 * h; t += c * g(z) * f(z);
    }
    h / 3.0 * t
}

fn far(x: f64, s: f64) -> f64 {                   // the call far from the strike
    if x > x0() { ((x - Q * s).exp() - K * (-R * s).exp()).max(0.0) } else { 0.0 }
}

fn grid(h: f64, nst: usize, l: f64, wd: f64, zero: bool) -> (f64, usize) {
    let m_ = (l / h).round() as i64; let n = (2 * m_ + 1) as usize;
    let xs: Vec<f64> = (0..n).map(|i| x0() + (i as i64 - m_) as f64 * h).collect();
    let (a, b, c) = (0.5 * SIG.powi(2), R - Q - LAM * kj(MUJ) - 0.5 * SIG.powi(2), -(R + LAM));
    let (lo, up, mid) = (a / h.powi(2) - b / (2.0 * h), a / h.powi(2) + b / (2.0 * h), c - 2.0 * a / h.powi(2));
    let (j0, j1) = (((MUJ - wd * DEL) / h) as i64 - 1, ((MUJ + wd * DEL) / h) as i64 + 2);
    let ws: Vec<(i64, f64)> = (j0..j1).map(|j| (j, h * g(j as f64 * h))).collect();
    let jump = |v: &Vec<f64>, s: f64| -> Vec<f64> {
        (0..n).map(|i| {
            let mut t = 0.0;
            for &(j, w) in &ws {
                let ij = i as i64 + j;
                let val = if ij >= 0 && ij < n as i64 { v[ij as usize] }
                          else if zero { 0.0 } else { far(xs[i] + j as f64 * h, s) };
                t += w * val;
            }
            LAM * t
        }).collect()
    };
    let mut v: Vec<f64> = xs.iter().map(|&x| (x.exp() - K).max(0.0)).collect();
    let mut s = 0.0;
    let mut plan = vec![(1.0, T / nst as f64 / 2.0); 4];
    plan.extend(vec![(0.5, T / nst as f64); nst - 2]);
    for (th, dt) in plan {
        let (jn, s1, mut rhs) = (jump(&v, s), s + dt, vec![0.0; n]);
        for i in 1..n - 1 {
            rhs[i] = v[i] + (1.0 - th) * dt * (lo * v[i - 1] + mid * v[i] + up * v[i + 1] + jn[i]);
        }
        rhs[0] = far(xs[0], s1); rhs[n - 1] = far(xs[n - 1], s1);
        let mut guess = v.clone();
        for _ in 0..20 {                           // fixed-point passes on the jump term
            let jg = jump(&guess, s1);
            let d: Vec<f64> = (0..n).map(|i| if i > 0 && i < n - 1 { rhs[i] + th * dt * jg[i] } else { rhs[i] }).collect();
            let (aa, bb, cc) = (-th * dt * lo, 1.0 - th * dt * mid, -th * dt * up);
            let (mut cp, mut dp) = (vec![0.0; n], vec![0.0; n]); dp[0] = d[0];   // Thomas algorithm
            for i in 1..n - 1 {
                let m = bb - aa * cp[i - 1]; cp[i] = cc / m; dp[i] = (d[i] - aa * dp[i - 1]) / m;
            }
            let mut new = vec![0.0; n]; new[0] = d[0]; new[n - 1] = d[n - 1];
            for i in (1..n - 1).rev() { new[i] = dp[i] - cp[i] * new[i + 1]; }
            let done = new.iter().zip(guess.iter()).map(|(p, q)| (p - q).abs()).fold(0.0, f64::max) < 1e-10;
            guess = new;
            if done { break; }
        }
        v = guess; s = s1;
    }
    (v[m_ as usize], ws.len())
}

fn main() {
    let k = kj(MUJ);
    println!("average jump k = {:.6}; compensator lambda k = {:.6}; drift r - q - lambda k = {:.6} a year", k, LAM * k, R - Q - LAM * k);
    println!("E[Y] by Simpson = {:.6}; 1 + k = {:.6}", simpson(&|z: f64| z.exp()), 1.0 + k);
    let bands = [70.0, 80.0, 90.0, 100.0, 110.0, 120.0];
    let mut cdf = vec![0.0]; for b in bands { cdf.push(ncdf(((b / S0).ln() - MUJ) / DEL)); } cdf.push(1.0);
    let names = ["under 70", "70-80", "80-90", "90-100", "100-110", "110-120", "over 120"];
    let parts: Vec<String> = (0..7).map(|i| format!("{} {:.2}", names[i], 100.0 * (cdf[i + 1] - cdf[i]))).collect();
    println!("where one jump from $100 lands (%): {}", parts.join(", "));
    println!("middle 99% of landings: ${:.2} to ${:.2}", S0 * (MUJ - 2.5758 * DEL).exp(), S0 * (MUJ + 2.5758 * DEL).exp());
    let ser: Vec<f64> = [1, 2, 6].iter().map(|&nn| merton_full(S0, T, nn, LAM, MUJ, true)).collect();
    let c = merton(S0, T);
    let fact = [1.0, 1.0, 2.0, 6.0, 24.0, 120.0];
    let mut p6 = 0.0; for n in 0..6 { p6 += (-LAM).exp() * LAM.powf(n as f64) / fact[n]; }   // P(N <= 5)
    let bound = S0 * (-(Q + LAM * k) * T).exp() * (1.0 - p6);
    println!("series after 1, 2, 6 terms: {:.6}, {:.6}, {:.6}; tail {:.6}, bound {:.6}", ser[0], ser[1], ser[2], c - ser[2], bound);
    println!("road 1, Merton series: {:.6}", c);
    assert!(0.0 < c - ser[2] && c - ser[2] <= bound);
    assert!((simpson(&|z: f64| z.exp()) - (1.0 + k)).abs() < 1e-9);
    let ev = simpson(&|z: f64| merton((x0() + z).exp(), T));
    println!("jump average E[V(100 Y)] = {:.6}; V at $80, ${:.2}, $100 = {:.6}, {:.6}, {:.6}",
             ev, S0 * MUJ.exp(), merton(80.0, T), merton(S0 * MUJ.exp(), T), c);
    println!("net jump term lambda (E[V] - V) = {:.4} a year", LAM * (ev - c)); let mut res = vec![];
    for e in [0.02, 0.01] {
        let (vp, vm) = (merton((x0() + e).exp(), T), merton((x0() - e).exp(), T));
        let vs = (merton(S0, T + e) - merton(S0, T - e)) / (2.0 * e);
        let terms = [0.5 * SIG.powi(2) * (vp - 2.0 * c + vm) / e.powi(2),
                     (R - Q - LAM * k - 0.5 * SIG.powi(2)) * (vp - vm) / (2.0 * e), -R * c, -LAM * c, LAM * ev];
        let mut t = 0.0; for x in terms { t += x; }
        res.push(vs - t);
        println!("step {}: V_x {:.4}, V_xx {:.4}, V_s {:.4}; diffusion {:.4}, drift {:.4}, -rV {:.4}, -lambda V {:.4}, lambda E[V] {:.4}; sum {:.4}; residual {:.7}",
                 e, (vp - vm) / (2.0 * e), (vp - 2.0 * c + vm) / e.powi(2), vs, terms[0], terms[1], terms[2], terms[3], terms[4], t, res[res.len() - 1]);
    }
    assert!(res[1].abs() < 1e-3 && 3.5 < res[0] / res[1] && res[0] / res[1] < 4.5);
    println!("grid edges ${:.2} to ${:.2}; nodes {}, {}, {}; derivative stencil 3 nodes", S0 * (-1.2f64).exp(), S0 * 1.2f64.exp(),
             (2.4f64 / 0.04).round() as i64 + 1, (2.4f64 / 0.02).round() as i64 + 1, (2.4f64 / 0.01).round() as i64 + 1);
    let cases = [(0.04, 25), (0.02, 50), (0.01, 100)];
    let runs: Vec<(f64, usize)> = cases.iter().map(|&(h, nst)| grid(h, nst, 1.2, 7.0, false)).collect();
    for (&(h, nst), &(v, nw)) in cases.iter().zip(runs.iter()) {
        println!("road 2, grid h = {}, {} steps, jump stencil {} nodes: {:.6}, error {:.6}", h, nst, nw, v, v - c);
    }
    let e: Vec<f64> = runs.iter().map(|&(v, _)| v - c).collect();
    let rich = (4.0 * runs[2].0 - runs[1].0) / 3.0;
    println!("error ratios {:.3}, {:.3}; observed order {:.3}", e[0] / e[1], e[1] / e[2], (e[1] / e[2]).ln() / 2f64.ln());
    println!("Richardson from h = 0.02 and 0.01: {:.6}, off by {:.6}", rich, rich - c);
    assert!(e[2].abs() < 3e-3 && 3.5 < e[1] / e[2] && e[1] / e[2] < 4.5 && (rich - c).abs() < 2e-5);
    println!("what breaks:");
    println!("  no jumps at all (Black-Scholes at 20%): {:.6}; jumps add {:.6}", bs(S0, T, Q, SIG), c - bs(S0, T, Q, SIG));
    println!("  drop the integral, keep -lambda V: {:.6}", (-LAM * T).exp() * bs(S0, T, Q + LAM * k, SIG));
    println!("  drop the compensator: {:.6}", merton_full(S0, T, 40, LAM, MUJ, false));
    let se = (SIG.powi(2) + LAM * (MUJ.powi(2) + DEL.powi(2))).sqrt();
    let qe = Q + LAM * k - LAM * MUJ - 0.5 * LAM * (MUJ.powi(2) + DEL.powi(2));
    println!("  local Taylor stand-in (vol {:.2}%, yield {:.4}%): {:.6}", 100.0 * se, 100.0 * qe, bs(S0, T, qe, se));
    let w2 = grid(0.02, 50, 1.2, 2.0, false);
    println!("  jump stencil cut to mean +- 2 spreads ({} nodes), h = 0.02: {:.6}", w2.1, w2.0);
    assert!(w2.0 < runs[1].0 - 0.1);
    println!("try changing:");
    println!("  one jump a year: {:.6}; gaps of +10% instead: {:.6}",
             merton_full(S0, T, 40, 1.0, MUJ, true), merton_full(S0, T, 40, LAM, 0.10, true));
    let v6 = grid(0.02, 50, 0.6, 7.0, true).0;
    println!("  grid h = 0.02 on ${:.2} to ${:.2}, zero beyond: {:.6}, error {:.6}", S0 * (-0.6f64).exp(), S0 * 0.6f64.exp(), v6, v6 - c);
    assert!((v6 - c).abs() > 3.0 * e[1].abs());
    println!("ALL CHECKS PASS");
}
