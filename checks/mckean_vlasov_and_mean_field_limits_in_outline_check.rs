// McKean-Vlasov in outline: banks pulled toward the crowd's mean reserve.
// Bank i: dX^i = -K (X^i - crowd mean) dt + S dW^i from X0; limit dX = -K (X - E[X_t]) dt + S dW.
// Roads: closed forms; moment recursions of the Euler scheme; Simpson quadrature;
// Picard iteration on the mean; seeded particle simulation (SplitMix64, Box-Muller).
use std::f64::consts::PI;

const K: f64 = 1.0; const S: f64 = 1.0; const X0: f64 = 2.0; const N: usize = 1000; const T: f64 = 1.0;

struct Rng { s: u64, spare: Option<f64> }

impl Rng {
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {
        if let Some(z) = self.spare.take() { return z; }
        let (u1, u2) = (1.0 - self.u(), self.u());
        let r = (-2.0 * u1.ln()).sqrt();
        self.spare = Some(r * (2.0 * PI * u2).sin());
        r * (2.0 * PI * u2).cos()
    }
}

fn v_lim(t: f64) -> f64 { S * S / (2.0 * K) * (1.0 - (-2.0 * K * t).exp()) }
fn gap2(t: f64, n: f64) -> f64 { S * S / n * (t - 2.0 * (1.0 - (-K * t).exp()) / K + v_lim(t) / (S * S)) }
fn cov2(t: f64, n: f64) -> f64 { S * S / n * (t - v_lim(t) / (S * S)) }

// exact moments of the Euler scheme: spread, mean, gap, pair covariance
fn scheme(n: f64, h: f64, steps: usize) -> (f64, f64, f64, f64) {
    let r = 1.0 - K * h;
    let (mut v, mut q, mut a, mut c) = (0.0, 0.0, 0.0, 0.0);
    for _ in 0..steps {
        (a, c) = (r * r * a + 2.0 * r * K * h * c + K * h * K * h * q, r * c + K * h * q);
        (v, q) = (r * r * v + S * S * h * (1.0 - 1.0 / n), q + S * S * h / n);
    }
    (v, q, a, q - v / (n - 1.0))
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let mut s = f(a) + f(b);
    for j in 1..m {
        let w = if j % 2 == 1 { 4.0 } else { 2.0 };
        s += w * f(a + j as f64 * (b - a) / m as f64);
    }
    s * (b - a) / m as f64 / 3.0
}

// chance a standard normal falls below x
fn phi(x: f64) -> f64 {
    let half = simpson(&|y: f64| (-y * y / 2.0).exp() / (2.0 * PI).sqrt(), 0.0, x.abs(), 2000);
    if x >= 0.0 { 0.5 + half } else { 0.5 - half }
}

// road 4: Euler-Maruyama simulation
fn simulate(rng: &mut Rng, n: usize, reps: usize, h: f64, steps: usize, every: usize)
    -> (f64, f64, f64, Vec<(f64, f64, f64)>) {
    let (mut sm, mut sd, mut sc) = (0.0, 0.0, 0.0);
    let mut trace = Vec::new();
    let (sh, nf, rf) = (S * h.sqrt(), n as f64, reps as f64);
    for _ in 0..reps {
        let (mut x, mut xb, mut m) = (vec![X0; n], vec![X0; n], 0.0);
        for k in 0..=steps {
            let mut tot = 0.0;
            for xi in &x { tot += xi; }
            m = tot / nf;
            if every > 0 && k % every == 0 {
                let mut ss = 0.0;
                for xi in &x { ss += (xi - m) * (xi - m); }
                trace.push((k as f64 * h, m, ss / nf));
            }
            if k == steps { break; }
            for i in 0..n {
                let dw = sh * rng.normal();
                x[i] += -K * (x[i] - m) * h + dw;
                xb[i] += -K * (xb[i] - X0) * h + dw;
            }
        }
        let (mut s1, mut s2) = (0.0, 0.0);
        for xi in &x { s1 += xi - X0; s2 += (xi - X0) * (xi - X0); }
        sm += (m - X0) * (m - X0) / rf;
        sd += (x[0] - xb[0]) * (x[0] - xb[0]) / rf;
        sc += (s1 * s1 - s2) / (nf * (nf - 1.0)) / rf;
    }
    (sm, sd, sc, trace)
}

fn line(label: &str, v: Vec<f64>, d: usize) {
    let parts: Vec<String> = v.iter().map(|x| format!("{:.*}", d, x)).collect();
    println!("{}{}", label, parts.join(" "));
}

fn main() {
    let nf = N as f64;
    let (e1, e2) = ((-1.0f64).exp(), (-2.0f64).exp());
    let (vl, vd) = (v_lim(T), (1.0 - 1.0 / nf) * v_lim(T));
    let (g, cv, vb) = (gap2(T, nf), cov2(T, nf), (1.0 - 1.0 / nf) * v_lim(T) + S * S * T / nf);
    let (p_lend, p_alone) = (phi(-X0 / vb.sqrt()), phi(-X0 / (S * T.sqrt())));
    println!("K = {:.1} per year, S = {:.1} $M per root year, X0 = {:.1} $M, N = {} banks, t = {:.1} year", K, S, X0, N, T);
    println!("hand: e^-1 {:.6}, e^-2 {:.6}, 1 - 2(1 - e^-1) + v(1) = {:.6}", e1, e2, g * nf);
    println!("limit variance v(1)              {:.6}   stationary {:.6}", vl, S * S / (2.0 * K));
    println!("spread around crowd mean, N={} {:.6}   stationary {:.6}", N, vd, (1.0 - 1.0 / nf) * S * S / (2.0 * K));
    println!("crowd mean variance t/N          {:.6}   sd {:.6}", S * S * T / nf, (S * S * T / nf).sqrt());
    println!("gap to limit, mean square        {:.6}   x N {:.6}   rms {:.6}", g, g * nf, g.sqrt());
    println!("covariance of two banks          {:.6}   x N {:.6}", cv, cv * nf);
    println!("variance of one bank             {:.6}   correlation {:.6}", vb, cv / vb);
    println!("chance a bank is below 0         with lending {:.6}   alone {:.6}", p_lend, p_alone);
    assert!((p_alone - 0.0227501319).abs() < 1e-8); // published value of the normal tail at 2
    println!("pull to fixed target 0: mean {:.6}; crowd mean after 1000 years sd {:.6}", X0 * e1, (1000.0 / nf).sqrt());
    // road 2: moments of the Euler scheme with a fine step, against the closed forms
    let (v, q, a, c) = scheme(nf, 1e-4, 10000);
    println!("recursion, step 1e-4: spread {:.6} mean var {:.6} gap {:.6}/N cov {:.6}/N", v, q, a * nf, c * nf);
    for (got, want) in [(v, vd), (q, S * S * T / nf), (a, g), (c, cv)] { assert!((got - want).abs() < 1e-3 * want.abs()); }
    let simp = S * S * simpson(&|u: f64| (1.0 - (-K * u).exp()) * (1.0 - (-K * u).exp()), 0.0, 1.0, 1000);
    println!("Simpson, integral of (1 - e^-u)^2 over [0, 1]: {:.6}", simp);
    assert!((simp - g * nf).abs() < 1e-9);
    // road 3: Picard iteration on the mean path; closed form X0 e^-t (1 + t + ... + t^(k-1)/(k-1)!)
    let (steps, h) = (1000usize, 1e-3);
    let (decay, mut m_path) = ((-K * h).exp(), vec![0.0; steps + 1]);
    for k in 1..7 {
        let (mut new, mut conv) = (vec![X0], 0.0);
        for j in 0..steps {
            conv = decay * conv + K * h / 2.0 * (decay * m_path[j] + m_path[j + 1]);
            new.push(X0 * (-K * (j + 1) as f64 * h).exp() + conv);
        }
        m_path = new;
        let (mut closed, mut term) = (0.0, 1.0);
        for j in 0..k { closed += term; term /= (j + 1) as f64; }
        closed = X0 * e1 * closed;
        println!("Picard round {}: mean at 1 year {:.6}   closed form {:.6}", k, m_path[steps], closed);
        assert!((m_path[steps] - closed).abs() < 1e-6);
    }
    assert!((m_path[steps] - X0).abs() < 0.002);
    let mut rng = Rng { s: 20261123, spare: None };
    println!("-- simulation: one crowd of {}, step 0.01 year, 5 years --", N);
    let (_, _, _, tr) = simulate(&mut rng, N, 1, 0.01, 500, 25);
    for t_mark in [1.0f64, 5.0] {
        let (t, m, sp) = tr[(t_mark * 4.0) as usize];
        let want = scheme(nf, 0.01, (t_mark * 100.0) as usize).0;
        let se = want * (2.0 / nf).sqrt();
        println!("t = {:.0}: spread sim {:.6} +- {:.6}  scheme {:.6}  crowd mean {:.6}", t, sp, se, want, m);
        assert!((sp - want).abs() < 4.0 * se && (m - X0).abs() < 4.0 * (t / nf).sqrt());
    }
    line("chart, t      ", tr.iter().map(|p| p.0).collect(), 2);
    line("chart, spread ", tr.iter().map(|p| p.2).collect(), 3);
    line("chart, v(t)   ", tr.iter().map(|p| (1.0 - 1.0 / nf) * v_lim(p.0)).collect(), 3);
    line("chart, mean   ", tr.iter().map(|p| p.1).collect(), 3);
    line("chart, 2e^-t  ", tr.iter().map(|p| X0 * (-K * p.0).exp()).collect(), 3);
    println!("-- simulation: many small crowds, step 0.02 year, to 1 year --");
    for (n, reps) in [(10usize, 10000usize), (100, 2000)] {
        let (sm, sd, sc, _) = simulate(&mut rng, n, reps, 0.02, 50, 0);
        let (nn, rr) = (n as f64, reps as f64);
        let (_, q, a, c) = scheme(nn, 0.02, 50);
        println!("N = {}, {} crowds: mean var sim {:.6} scheme {:.6} formula {:.6}", n, reps, sm, q, T / nn);
        println!("  gap x N  sim {:.4} +- {:.4}  scheme {:.4}  formula {:.4}", sd * nn, a * nn * (2.0 / rr).sqrt(), a * nn, gap2(T, nn) * nn);
        println!("  cov x N  sim {:.4} +- {:.4}  scheme {:.4}  formula {:.4}", sc * nn, q * nn * (2.0 / rr).sqrt(), c * nn, cov2(T, nn) * nn);
        assert!((sm - q).abs() < 4.0 * q * (2.0 / rr).sqrt());
        assert!((sd - a).abs() < 4.0 * a * (2.0 / rr).sqrt());
        assert!((sc - c).abs() < 4.0 * (2.0 / rr).sqrt() * q);
    }
    println!("ALL CHECKS PASS");
}
