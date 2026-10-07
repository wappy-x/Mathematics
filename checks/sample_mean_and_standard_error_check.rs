// Standard error -- the check behind the card, in Rust, std only.
// A poll of 1,000 voters: 520 answer yes (1) and 480 no (0).  Roads: the
// formulas; every possible answer list of a small poll, enumerated exactly;
// and 1,000 seeded polls from an electorate whose true yes share is 0.52.
const P: f64 = 0.52;
const N: usize = 1000;
const YES: usize = 520;
const POLLS: usize = 1000;
const SEED: u64 = 20260928;
const PREFIX: [usize; 5] = [10, 25, 100, 250, 1000]; // poll sizes read off each simulated poll
const HOMES: usize = 100; // the clustered poll: 100 homes of 10 alike
const SIZE: usize = 10;
const SIG2: f64 = P * (1.0 - P); // one answer's variance, p(1 - p)

fn splitmix64(s: u64) -> (u64, u64) { // the generator both languages share
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

fn uniform(s: u64) -> (u64, f64) { // a draw in [0, 1) from 53 random bits
    let (s, z) = splitmix64(s);
    (s, (z >> 11) as f64 * 2f64.powi(-53))
}

fn summaries(xs: &[f64]) -> (f64, f64) { // the mean, and squared deviations from it
    let mut t = 0.0;
    for x in xs { t += x; }
    let m = t / xs.len() as f64;
    let mut q = 0.0;
    for x in xs { q += (x - m) * (x - m); }
    (m, q)
}

fn exact(values: &[f64], probs: &[f64], n: usize) -> [f64; 5] { // expectations over every answer list
    let (mut em, mut em2, mut es2, mut ev, mut es) = (0.0, 0.0, 0.0, 0.0, 0.0);
    let (k, nf) = (values.len(), n as f64);
    for code in 0..k.pow(n as u32) {
        let (mut xs, mut w, mut c) = (Vec::new(), 1.0, code);
        for _ in 0..n {
            xs.push(values[c % k]);
            w *= probs[c % k];
            c /= k;
        }
        let (m, q) = summaries(&xs);
        em += w * m;
        em2 += w * m * m;
        es2 += w * q / (nf - 1.0);
        ev += w * q / nf;
        es += w * (q / (nf - 1.0)).sqrt();
    }
    [em, em2 - em * em, es2, ev, es]
}

fn row(label: &str, v: f64) { println!("{:<50} {:>11.6}", label, v); }

fn main() {
    let nf = N as f64;
    let mut data = vec![1.0; YES];
    data.extend(vec![0.0; N - YES]);
    let (m, q) = summaries(&data); // road 1: the poll's own data
    let s2 = q / (nf - 1.0);
    let se_hat = s2.sqrt() / nf.sqrt();
    row("one answer: variance p(1 - p)", SIG2);
    row("one answer: SD, sqrt(p(1 - p))", SIG2.sqrt());
    row("formula: SE of the average, sqrt(p(1-p)/n)", (SIG2 / nf).sqrt());
    row("poll data: average of the 1,000 answers", m);
    println!("poll data: 520 x {:.4} = {:.3}; 480 x {:.4} = {:.3}; sqrt(1000) = {:.4}",
             (1.0 - m) * (1.0 - m), YES as f64 * (1.0 - m) * (1.0 - m), m * m, (N - YES) as f64 * m * m, nf.sqrt());
    row("poll data: sum of squared deviations", q);
    row("poll data: S^2, that sum over n - 1 = 999", s2);
    row("poll data: s, its square root", s2.sqrt());
    row("poll data: estimated SE, s / sqrt(1000)", se_hat);
    row("poll data: plug-in SE, sqrt(0.52 x 0.48 / 1000)", (m * (1.0 - m) / nf).sqrt());
    row("poll data: 95% margin, 1.96 x estimated SE", 1.96 * se_hat);

    println!("exact, n  E[mean]  Var(mean)  p(1-p)/n  E[S^2]  E[V]    E[S]    as % of p(1-p): S^2, V");
    let mut ex = Vec::new();
    for n in 2..9usize { // road 2: every answer list, 2^n of them
        let e = exact(&[0.0, 1.0], &[1.0 - P, P], n);
        println!("exact, {}  {:.4}  {:.6}  {:.6}  {:.4}  {:.4}  {:.4}  {:6.2} {:6.2}",
                 n, e[0], e[1], SIG2 / n as f64, e[2], e[3], e[4], 100.0 * e[2] / SIG2, 100.0 * e[3] / SIG2);
        ex.push((n, e));
    }
    let mix = 2.0 * P * (1.0 - P); // a poll of 2: one yes and one no
    println!("exact, n = 2: chance of a mixed pair {:.4}; its S^2 0.5000, V 0.2500, S {:.4}", mix, 0.5f64.sqrt());
    let t = exact(&[1.0, 2.0, 3.0], &[0.25, 0.5, 0.25], 4); // a three-answer question, n = 4
    println!("exact, answers 1/2/3 at 0.25/0.5/0.25, n = 4: E[S^2] {:.4}, E[V] {:.4}", t[2], t[3]);

    let mut state = SEED; // road 3: 1,000 seeded polls
    let mut acc = [[0.0f64; 2]; 5];
    let (mut s2_2, mut s2_2sq, mut v_2, mut se_sum, mut inside) = (0.0f64, 0.0f64, 0.0f64, 0.0f64, 0usize);
    for _ in 0..POLLS {
        let (mut tt, mut xs) = (0.0f64, Vec::with_capacity(N));
        for i in 1..=N {
            let (s, u) = uniform(state);
            state = s;
            let x = if u < P { 1.0 } else { 0.0 };
            xs.push(x);
            tt += x;
            if let Some(j) = PREFIX.iter().position(|&p| p == i) {
                let a = tt / i as f64;
                acc[j][0] += a;
                acc[j][1] += a * a;
            }
        }
        let (_, q2) = summaries(&xs[..2]); // the first two voters as a poll of 2
        s2_2 += q2;
        s2_2sq += q2 * q2;
        v_2 += q2 / 2.0;
        let (a, qq) = summaries(&xs);
        se_sum += (qq / (nf - 1.0)).sqrt() / nf.sqrt();
        inside += ((a - P).abs() <= (SIG2 / nf).sqrt()) as usize;
    }
    let pf = POLLS as f64;
    let mut sd_sim = [0.0f64; 5];
    println!("chart, n, SE by formula, SD of 1,000 simulated averages and its SE, in points");
    for (j, &n) in PREFIX.iter().enumerate() {
        let mu = acc[j][0] / pf;
        sd_sim[j] = (acc[j][1] / pf - mu * mu).sqrt();
        println!("chart, {:>4} {:6.2} {:6.2} {:6.3}", n, 100.0 * (SIG2 / n as f64).sqrt(), 100.0 * sd_sim[j], 100.0 * sd_sim[j] / (2.0 * pf).sqrt());
    }
    let mean_s2 = s2_2 / pf;
    let se_s2 = (s2_2sq / pf - mean_s2 * mean_s2).sqrt() / pf.sqrt();
    row("sim, polls of 2: average S^2", mean_s2);
    row("sim, polls of 2: its standard error", se_s2);
    row("sim, polls of 2: average V, over n", v_2 / pf);
    row("sim, polls of 1,000: average estimated SE", se_sum / pf);
    row("sim, polls of 1,000: share within one SE of 0.52", inside as f64 / pf);
    row("sim, polls of 1,000: that share's standard error", (inside as f64 / pf * (1.0 - inside as f64 / pf) / pf).sqrt());

    let (mut cs, mut cs2, mut cse) = (0.0f64, 0.0f64, 0.0f64); // clustered: whole homes answer alike
    for _ in 0..POLLS {
        let mut xs = Vec::with_capacity(N);
        for _ in 0..HOMES {
            let (s, u) = uniform(state);
            state = s;
            xs.extend(vec![if u < P { 1.0 } else { 0.0 }; SIZE]);
        }
        let (a, qq) = summaries(&xs);
        cs += a;
        cs2 += a * a;
        cse += (qq / (nf - 1.0)).sqrt() / nf.sqrt();
    }
    let sd_cl = (cs2 / pf - (cs / pf) * (cs / pf)).sqrt();
    row("clustered: SD of the averages, simulated", sd_cl);
    row("clustered: formula for 100 answers", (SIG2 / HOMES as f64).sqrt());
    row("clustered: average estimated SE, s / sqrt(1000)", cse / pf);

    for (n, e) in &ex { // enumerated against the proved formulas
        let n = *n as f64;
        assert!((e[1] - SIG2 / n).abs() < 1e-12 && (e[0] - P).abs() < 1e-12);
        assert!((e[2] - SIG2).abs() < 1e-12 && (e[3] - SIG2 * (n - 1.0) / n).abs() < 1e-12);
    }
    assert!((t[2] - 0.5).abs() < 1e-12 && (t[3] - 0.375).abs() < 1e-12, "three-answer law");
    assert!((ex[0].1[4] - mix * 0.5f64.sqrt()).abs() < 1e-12 && (ex[0].1[2] - mix * 0.5).abs() < 1e-12, "n = 2 by hand");
    assert!((s2 - m * (1.0 - m) * nf / (nf - 1.0)).abs() < 1e-12, "data loop vs closed form");
    for (j, &n) in PREFIX.iter().enumerate() { // simulated spread within 4 standard errors
        let f = (SIG2 / n as f64).sqrt();
        assert!((sd_sim[j] - f).abs() < 4.0 * (SIG2 / n as f64 / (2.0 * pf)).sqrt(), "n = {}", n);
    }
    assert!((acc[4][0] / pf - P).abs() < 4.0 * (SIG2 / nf / pf).sqrt(), "averages centre on p");
    assert!((mean_s2 - SIG2).abs() < 4.0 * se_s2 && SIG2 - v_2 / pf > 5.0 * se_s2, "n - 1");
    assert!((sd_cl - (SIG2 / 100.0).sqrt()).abs() < 4.0 * (SIG2 / 100.0 / (2.0 * pf)).sqrt(), "cluster");
    assert!(sd_cl > 2.5 * cse / pf, "the estimated SE misses the clustering");
    println!("ALL CHECKS PASS");
}
