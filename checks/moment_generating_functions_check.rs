// Moment generating functions -- the check behind the card, in Rust, std only.
// A fair coin scores X = 1 for heads and 0 for tails; S counts the heads in
// ten independent flips.  Each moment E[S^k] is reached four ways: Taylor
// coefficients of M_X(t) multiplied ten times, an average over all 1,024 flip
// sequences, numerical derivatives of E[e^(tS)] at t = 0, and a seeded
// simulation.  Then two failures: copies, and a heavy tail.
const P: f64 = 0.5;
const N: i32 = 10;
const KMAX: usize = 4;

fn mgf(law: &[(f64, f64)], t: f64) -> f64 {
    // the definition: sum of chance * e^(t x)
    law.iter().map(|&(x, c)| c * (t * x).exp()).sum()
}

fn factorial(k: usize) -> f64 {
    (1..=k).map(|i| i as f64).product()
}

fn poly_mul(a: &[f64], b: &[f64]) -> Vec<f64> {
    // product of two series, cut at t^KMAX
    let mut out = vec![0.0; KMAX + 1];
    for (i, ai) in a.iter().enumerate() {
        for (j, bj) in b.iter().enumerate() {
            if i + j <= KMAX {
                out[i + j] += ai * bj;
            }
        }
    }
    out
}

fn derivs_at_zero(f: &dyn Fn(f64) -> f64, h: f64) -> Vec<f64> {
    // road 3: central differences, orders 1 to 4
    let (f2, f1, f0, g1, g2) = (f(2.0 * h), f(h), f(0.0), f(-h), f(-2.0 * h));
    vec![f0, (f1 - g1) / (2.0 * h), (f1 - 2.0 * f0 + g1) / h.powi(2),
         (f2 - 2.0 * f1 + 2.0 * g1 - g2) / (2.0 * h.powi(3)), (f2 - 4.0 * f1 + 6.0 * f0 - 4.0 * g1 + g2) / h.powi(4)]
}

fn splitmix64(state: u64) -> (u64, u64) {
    // the generator both languages share
    let state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (state, z ^ (z >> 31))
}

fn row(label: &str, v: f64) {
    println!("{:<44}{:>14.6}", label, v);
}

fn main() {
    let law_x: [(f64, f64); 2] = [(0.0, 1.0 - P), (1.0, P)]; // (value, chance) for one flip
    let seqs: Vec<(f64, f64)> = (0..(1u32 << N)) // every sequence of ten flips, as (heads, chance)
        .map(|code| { let h = code.count_ones() as i32; (h as f64, P.powi(h) * (1.0 - P).powi(N - h)) })
        .collect();
    let mgf_s_enum = |t: f64| mgf(&seqs, t); // E[e^(tS)] straight from the 1,024 sequences
    let moment_enum = |k: i32| -> f64 { seqs.iter().map(|&(h, c)| c * h.powi(k)).sum() }; // road 2
    let taylor_x: Vec<f64> = (0..=KMAX) // coefficients E[X^k] / k! of M_X(t)
        .map(|k| law_x.iter().map(|&(x, c)| c * x.powi(k as i32)).sum::<f64>() / factorial(k)).collect();
    let mut series_s = vec![0.0; KMAX + 1]; // road 1: M_S = M_X ten times over
    series_s[0] = 1.0;
    for _ in 0..N {
        series_s = poly_mul(&series_s, &taylor_x);
    }
    let m_taylor: Vec<f64> = (0..=KMAX).map(|k| series_s[k] * factorial(k)).collect();
    let m_diff = derivs_at_zero(&mgf_s_enum, 1e-3);

    let (runs, mut state, mut sums) = (200_000usize, 20260928u64, [0.0f64; 6]); // road 4
    for _ in 0..runs {
        let mut s = 0i32;
        for _ in 0..N {
            let (st, z) = splitmix64(state);
            state = st;
            if ((z >> 11) as f64) * 2f64.powi(-53) < P { s += 1; }
        }
        let sf = s as f64;
        for (i, v) in [sf, sf * sf, (0.1 * sf).exp()].iter().enumerate() {
            sums[i] += v;
            sums[i + 3] += v * v;
        }
    }
    let rf = runs as f64;
    let est: Vec<f64> = (0..3).map(|i| sums[i] / rf).collect();
    let se: Vec<f64> = (0..3).map(|i| ((sums[i + 3] / rf - est[i].powi(2)) / rf).sqrt()).collect();

    row("coin: M_X(0)", mgf(&law_x, 0.0));
    let coin_slope = derivs_at_zero(&|t| mgf(&law_x, t), 1e-3)[1];
    row("coin: M_X'(0) by central difference", coin_slope);
    row("coin: E[X^2] = E[X^3] = E[X^4]", law_x.iter().map(|&(x, c)| c * x.powi(3)).sum());
    row("coin: variance E[X^2] - E[X]^2", P - P * P);
    println!("ten flips, E[S^k]:  k   Taylor x k!   all 1,024   derivative   simulated (se)");
    for k in 1..=KMAX {
        let sim = if k <= 2 { format!("{:>10.4} ({:.4})", est[k - 1], se[k - 1]) } else { String::new() };
        let line = format!("{:<20}{:>2} {:>12.4} {:>11.4} {:>12.4}  {}", "", k, m_taylor[k], moment_enum(k as i32), m_diff[k], sim);
        println!("{}", line.trim_end());
    }
    let (mean_s, var_s) = (moment_enum(1), moment_enum(2) - moment_enum(1).powi(2));
    row("ten flips: variance E[S^2] - E[S]^2", var_s);
    row("ten flips: standard deviation", var_s.sqrt());
    row("ten flips: third central moment", moment_enum(3) - 3.0 * mean_s * moment_enum(2) + 2.0 * mean_s.powi(3));
    row("Taylor coefficient of t^2 in M_S", series_s[2]);
    row("Taylor coefficient of t^3 in M_S", series_s[3]);
    row("P(S = 5): count of sequences with 5 heads", seqs.iter().filter(|&&(h, _)| h == 5.0).map(|&(_, c)| c).sum());
    println!("product rule:   t    E[e^(tS)] over 1,024   M_X(t)^10");
    for &t in [-1.0f64, -0.5, 0.1, 0.5, 1.0].iter() {
        let (e, m) = (mgf_s_enum(t), mgf(&law_x, t).powi(N));
        println!("{:<12}{:>6.1} {:>21.6} {:>11.6}", "", t, e, m);
        assert!((e - m).abs() < 1e-12 * e, "{}", t);
    }
    row("simulated E[e^(0.1 S)]", est[2]);
    row("  its standard error", se[2]);

    let copy: [(f64, f64); 2] = [(0.0, 1.0 - P), (N as f64, P)]; // one flip copied ten times: S = 10 X
    row("wrong: copies, M(0.1) of 10X", mgf(&copy, 0.1));
    row("wrong: copies, E[(10X)^2] by derivative", derivs_at_zero(&|t| mgf(&copy, t), 1e-3)[2]);
    row("wrong: copies, variance", (N * N) as f64 * (P - P * P));
    row("wrong: slope at t = 1, M_X'(1)", P * 1f64.exp());
    row("wrong: t^2 coefficient read as E[S^2]", series_s[2]);
    let tail: Vec<(f64, f64)> = (0..=40_000).map(|k| (k as f64, (-(k as f64).sqrt()).exp())).collect();
    let c_tail: f64 = tail.iter().map(|&(_, w)| w).sum(); // heavy tail: chance of k proportional to e^(-sqrt k)
    row("heavy tail: E[L]", tail.iter().map(|&(k, w)| k * w).sum::<f64>() / c_tail);
    row("heavy tail: E[L^2]", tail.iter().map(|&(k, w)| k * k * w).sum::<f64>() / c_tail);
    let mut logs = Vec::new();
    for &(cut, name) in [(2_500usize, "2,500"), (10_000, "10,000"), (40_000, "40,000")].iter() {
        let part: f64 = tail[..=cut].iter().map(|&(k, w)| (0.01 * k).exp() * w).sum::<f64>() / c_tail;
        logs.push(part.ln());
        row(&format!("heavy tail: ln of E[e^(0.01 L)], k <= {}", name), part.ln());
    }
    let join = |v: Vec<f64>| v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ");
    let ts: Vec<f64> = (0..9).map(|i| -2.0 + 0.5 * i as f64).collect();
    println!("chart1, M_X(t):   {}", join(ts.iter().map(|&t| mgf(&law_x, t)).collect()));
    println!("chart1, 1 + t/2:  {}", join(ts.iter().map(|&t| 1.0 + t / 2.0).collect()));
    println!("chart1, + t^2/4:  {}", join(ts.iter().map(|&t| 1.0 + t / 2.0 + t * t / 4.0).collect()));
    let ts2: Vec<f64> = (0..7).map(|i| -0.3 + 0.1 * i as f64).collect();
    println!("chart2, independent: {}", join(ts2.iter().map(|&t| mgf(&law_x, t).powi(N)).collect()));
    println!("chart2, copies 10X:  {}", join(ts2.iter().map(|&t| mgf(&copy, t)).collect()));

    for k in 1..=KMAX {
        let exact = moment_enum(k as i32);
        assert!((m_taylor[k] - exact).abs() < 1e-9 * exact, "Taylor vs sequences, k={}", k);
        assert!((m_diff[k] - exact).abs() < 1e-3 * exact, "derivative vs sequences, k={}", k);
    }
    for (i, &exact) in [moment_enum(1), moment_enum(2), mgf_s_enum(0.1)].iter().enumerate() {
        assert!((est[i] - exact).abs() < 4.0 * se[i], "simulation {} within four standard errors", i);
    }
    assert!((mgf(&copy, 0.1) - mgf(&law_x, 0.1).powi(N)).abs() > 0.1, "copies must break the product rule");
    assert!((coin_slope - law_x.iter().map(|&(x, c)| c * x).sum::<f64>()).abs() < 1e-6, "coin slope at zero is the mean");
    assert!(logs[0] < 1.0 && 1.0 < 10.0 * logs[1] && 10.0 * logs[1] < logs[2], "heavy tail: partial sums must run away");
    println!("ALL CHECKS PASS");
}
