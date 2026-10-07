// Semimartingales -- the same check as semimartingales_in_outline_check.py, in Rust.
// Standard library only, no crates.  Same generator, same seed, same order of
// draws and additions, so the output matches the Python twin line for line.
// dS = S_-(mu dt + sigma dW + j (dN - lam dt)), S_0 = $100, crashes of 20%.
const S0: f64 = 100.0;
const MU: f64 = 0.05;
const SIG: f64 = 0.20;
const LAM: f64 = 1.0;
const J: f64 = -0.20;
const T: f64 = 1.0;
const NF: usize = 4096;

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {            // SplitMix64, top 53 bits
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {             // Box-Muller, cosine half only
        let u1 = 1.0 - self.uniform();
        let u2 = self.uniform();
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
    }
    fn expo(&mut self) -> f64 { -(1.0 - self.uniform()).ln() / LAM }
}

fn mean_se(xs: &[f64]) -> (f64, f64) {
    let (mut m, mut v) = (0.0, 0.0);
    for x in xs { m += x; }
    m /= xs.len() as f64;
    for x in xs { v += (x - m) * (x - m); }
    (m, (v / (xs.len() as f64 - 1.0) / xs.len() as f64).sqrt())
}

fn g() -> f64 { MU - LAM * J - 0.5 * SIG * SIG }

// fine grid; crash times exact, then put on the grid
fn path(r: &mut Rng) -> (Vec<f64>, Vec<usize>, f64, f64, f64) {
    let dt = T / NF as f64;
    let (mut w, mut ws) = (0.0, vec![0.0]);
    for _ in 0..NF { w += dt.sqrt() * r.normal(); ws.push(w); }
    let (mut jk, mut t) = (Vec::new(), r.expo());
    while t < T { jk.push((t * NF as f64) as usize + 1); t = t + r.expo(); }
    let (mut s, mut m, mut p, mut jsq, mut comp, mut cont) = (Vec::new(), 1.0, 0, 0.0, 0.0, 0.0);
    for k in 0..=NF {
        while p < jk.len() && jk[p] == k {    // crash at grid time k: pre-crash price times j
            let pre = S0 * (g() * k as f64 * dt + SIG * ws[k]).exp() * m;
            jsq += (J * pre) * (J * pre); comp += (1.0 + J).ln() - J;
            m *= 1.0 + J; p += 1;
        }
        s.push(S0 * (g() * k as f64 * dt + SIG * ws[k]).exp() * m);
        if k < NF { cont += SIG * SIG * s[k] * s[k] * dt; }   // sigma^2 * integral of S^2 dt
    }
    (s, jk, jsq, cont, comp)
}

fn grid(s: &[f64], n: usize) -> (f64, f64, f64) {  // sum (dS)^2, left sum S dS, left sum dS/S
    let p: Vec<f64> = s.iter().step_by(NF / n).cloned().collect();
    let (mut qv, mut left, mut ret) = (0.0, 0.0, 0.0);
    for k in 0..n {
        let ds = p[k + 1] - p[k];
        qv += ds * ds; left += p[k] * ds; ret += ds / p[k];
    }
    (qv, left, ret)
}

fn row(label: &str, v: f64) { println!("{:<44}{:>12.4}", label, v); }
fn row_se(label: &str, m: (f64, f64)) { println!("{:<44}{:>12.4}  se {:.4}", label, m.0, m.1); }

fn main() {
    let mut r = Rng(20260930);
    let gg = g();
    println!("A  formulas");
    let c = 2.0 * MU + SIG * SIG + LAM * J * J;
    let ints2 = S0 * S0 * ((c * T).exp() - 1.0) / c;   // integral of E[S_t^2] dt
    let (fs1, fs2) = (S0 * (MU * T).exp(), S0 * S0 * (c * T).exp());
    let (fbr, ford) = (S0 * S0 * ((2.0 * MU + SIG * SIG) * T).exp(), S0 * S0 * (2.0 * MU * T).exp());
    let (fqc, fqj) = (SIG * SIG * ints2, LAM * J * J * ints2);
    let (fl_a, fl_b) = (MU * ints2, 0.5 * (fs2 - S0 * S0 - fqc - fqj));
    let flog_a = S0.ln() + gg * T + LAM * T * (1.0 + J).ln();
    let flog_b = S0.ln() + MU * T - 0.5 * SIG * SIG * T + LAM * T * ((1.0 + J).ln() - J);
    for (lab, v) in [("E[S_1]", fs1), ("E[S_1^2], semimartingale Ito", fs2),
                     ("E[S_1^2], jumps left out of [S]", fbr), ("E[S_1^2], ordinary chain rule", ford),
                     ("E[[S]_1], continuous part", fqc), ("E[[S]_1], jump part", fqj),
                     ("E[int S_- dS], as mu * int E[S^2] dt", fl_a), ("E[int S_- dS], by parts", fl_b),
                     ("E[log S_1], solved path", flog_a), ("E[log S_1], Ito with jump sum", flog_b),
                     ("jump term per crash, log(1+j) - j", (1.0 + J).ln() - J),
                     ("try: E[S_1^2], lam = 4, j = -0.10", S0 * S0 * (2.0 * MU + SIG * SIG + 4.0 * 0.01).exp())] {
        row(lab, v);
    }
    println!("hand: G {:.4}, mu - lam j {:.4}, [S] rate {:.4}, c {:.4}", gg, MU - LAM * J, SIG * SIG + LAM * J * J, c);
    println!("hand: e^c {:.6}, (e^c - 1)/c {:.6}, int E[S^2] dt {:.2}", c.exp(), (c.exp() - 1.0) / c, ints2);

    let (s, jk, jsq, cont, comp) = path(&mut r);
    let qs = cont + jsq;
    let times: Vec<String> = jk.iter().map(|k| format!("{:.4}", *k as f64 / NF as f64)).collect();
    println!("B  one path, 4096 steps: crashes at {}", times.join(" "));
    row("   S_1 on this path", s[NF]);
    row("   [S]_1 = continuous part + jump part", qs);
    row("   jump part, sum of squared crashes", jsq);
    let lim_left = 0.5 * (s[NF] * s[NF] - S0 * S0 - qs);
    row("   left-sum limit (S_1^2 - S_0^2 - [S]_1)/2", lim_left);
    row("   integrand S_t, not S_t-: limit", lim_left + jsq);
    println!("   steps     sum (dS)^2     left sum S dS     identity gap");
    for n in [16usize, 64, 256, 1024, 4096] {
        let (qv, left, _) = grid(&s, n);
        let gap = ((s[NF] * s[NF] - S0 * S0) - (2.0 * left + qv)).abs();
        println!("   n {:>5}   {:>11.4}   {:>14.4}   {:.9}", n, qv, left, gap);
    }
    let (qv_b, _, ret_b) = grid(&s, NF);
    let (log_ito, log_ex) = (S0.ln() + ret_b - 0.5 * SIG * SIG * T + comp, s[NF].ln());
    row("   log S_1, exact", log_ex);
    row("   log S_1, Ito formula, 4096-step integral", log_ito);
    row("   log S_1, jump sum dropped", log_ito - comp);
    let pts: Vec<String> = (0..=NF).step_by(256).map(|k| format!("{:.2}", s[k])).collect();
    println!("chart, path {}", pts.join(" "));

    let (d_n, ns) = (400usize, [16usize, 64, 256, 1024, 4096]);
    let (mut err, mut qsl, mut jsl, mut lsl) = ([0.0f64; 5], Vec::new(), Vec::new(), Vec::new());
    for _ in 0..d_n {
        let (sd, _, jsd, cd, _) = path(&mut r);
        for (a, n) in ns.iter().enumerate() {
            err[a] += (grid(&sd, *n).0 - (cd + jsd)).abs() / d_n as f64;
        }
        qsl.push(cd + jsd); jsl.push(jsd); lsl.push(grid(&sd, NF).1);
    }
    println!("D  400 paths: mean |sum (dS)^2 - [S]_1| by steps");
    for (a, n) in ns.iter().enumerate() { println!("   n {:>5}   {:9.4}", n, err[a]); }
    let ec: Vec<String> = err.iter().map(|e| format!("{:.2}", e)).collect();
    println!("chart, error {}", ec.join(" "));
    let (mq, mj, ml) = (mean_se(&qsl), mean_se(&jsl), mean_se(&lsl));
    for (lab, v) in [("   mean [S]_1", mq), ("   mean jump part", mj), ("   mean left sum S dS, 4096 steps", ml)] {
        row_se(lab, v);
    }
    let np = 20000;
    let (mut s1l, mut s2l, mut lgl, mut nl) = (Vec::new(), Vec::new(), Vec::new(), Vec::new());
    for _ in 0..np {
        let w = r.normal();
        let (mut nj, mut t) = (0, r.expo());
        while t < T { nj += 1; t = t + r.expo(); }
        let mut m = 1.0;
        for _ in 0..nj { m *= 1.0 + J; }
        let x = S0 * (gg * T + SIG * w).exp() * m;
        s1l.push(x); s2l.push(x * x); lgl.push(x.ln()); nl.push(nj as f64);
    }
    let (m1, m2, mlg, mn) = (mean_se(&s1l), mean_se(&s2l), mean_se(&lgl), mean_se(&nl));
    println!("C  20000 exact draws at t = 1");
    for (lab, v) in [("   mean S_1", m1), ("   mean S_1^2", m2), ("   mean log S_1", mlg), ("   mean number of crashes", mn)] {
        row_se(lab, v);
    }
    assert!((m2.0 - fs2).abs() < 4.0 * m2.1, "E[S^2] needs the jump part of [S]");
    assert!(m2.0 - fbr > 4.0 * m2.1, "the Brownian-only Ito formula is too low");
    assert!((mlg.0 - flog_b).abs() < 4.0 * mlg.1, "Ito with jump sum gives E[log S]");
    assert!((m1.0 - fs1).abs() < 4.0 * m1.1, "mean grows at mu");
    assert!((qv_b - qs).abs() < 0.05 * qs, "(dS)^2 sums to [S] on the 4096-step grid");
    assert!((log_ito - log_ex).abs() < 0.01 && 0.01 < (log_ito - comp - log_ex).abs(), "log needs the jump sum");
    assert!(err[4] < err[0] / 4.0, "grid error shrinks");
    assert!((mq.0 - fqc - fqj).abs() < 4.0 * mq.1 && (mj.0 - fqj).abs() < 4.0 * mj.1, "[S] and its jump part");
    assert!((ml.0 - fl_b).abs() < 4.0 * ml.1, "left sums average to the by-parts value");
    println!("ALL CHECKS PASS");
}
