// Shape across strikes and expiries -- the same check as the Python, in Rust.  No crates.
// Rust has no erf, so the bell-curve area N is built the honest way: add up thin slices
// under the curve (Simpson).  The integrals and the bisection are written out here too.
use std::f64::consts::PI;
const S: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20;
const T1: f64 = 0.5; const T2: f64 = 1.0;          // near and far expiry, in years
const STRIKES: [f64; 5] = [80.0, 90.0, 100.0, 110.0, 120.0];
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height at x
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn n_cdf(x: f64) -> f64 {                                 // bell-curve area left of x
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 4000)                      // half, plus the slice from 0 to x
}
fn disc(t: f64) -> f64 { (-R * t).exp() }                 // D(t): a dollar at t, valued today
fn fwd(t: f64) -> f64 { S * ((R - Q) * t).exp() }         // F(t): the forward price
fn call(k: f64, t: f64, s: f64, sig: f64) -> f64 {        // Black-Scholes call
    let d1 = ((s / k).ln() + (R - Q + 0.5 * sig * sig) * t) / (sig * t.sqrt());
    s * (-Q * t).exp() * n_cdf(d1) - k * (-R * t).exp() * n_cdf(d1 - sig * t.sqrt())
}
fn putp(k: f64, t: f64, s: f64, sig: f64) -> f64 {        // Black-Scholes put
    let d1 = ((s / k).ln() + (R - Q + 0.5 * sig * sig) * t) / (sig * t.sqrt());
    k * (-R * t).exp() * n_cdf(sig * t.sqrt() - d1) - s * (-Q * t).exp() * n_cdf(-d1)
}
fn by_payoff<F: Fn(f64) -> f64>(payoff: F, t: f64) -> f64 {   // road 2: average the payoff
    let f = |z: f64| {
        let st = S * ((R - Q - 0.5 * SIG * SIG) * t + SIG * t.sqrt() * z).exp();
        payoff(st) * phi(z)
    };
    disc(t) * simpson(f, -10.0, 10.0, 40000)
}
fn cnorm(k: f64, w: f64) -> f64 {   // normalized call: moneyness and total variance, nothing else
    let d1 = (-k.ln() + 0.5 * w) / w.sqrt();
    n_cdf(d1) - k * n_cdf(d1 - w.sqrt())
}
fn implied_w(k: f64, c: f64) -> f64 {   // bisection; cnorm climbs strictly in w, so one root
    assert!((1.0 - k).max(0.0) < c && c < 1.0, "at or outside the bounds no total variance exists");
    let (mut lo, mut hi) = (1e-12, 100.0);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if cnorm(k, mid) < c { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn least_of(v: &[f64]) -> f64 { v.iter().fold(f64::INFINITY, |a, &b| a.min(b)) }
fn most_of(v: &[f64]) -> f64 { v.iter().fold(f64::NEG_INFINITY, |a, &b| a.max(b)) }
fn main() {
    let chart = |label: &str, vals: Vec<String>| println!("{}{}", label, vals.join(""));
    // ---- the house market, and the one-year strip ---------------------------------------
    let cash: Vec<f64> = STRIKES.iter().map(|&k| call(k, T2, S, SIG)).collect();
    let integ: Vec<f64> = STRIKES.iter().map(|&k| by_payoff(move |st| (st - k).max(0.0), T2)).collect();
    let cap = disc(T2) * 10.0;
    let spread: Vec<f64> = (0..4).map(|i| cash[i] - cash[i + 1]).collect();
    let fly: Vec<f64> = (1..4).map(|i| cash[i - 1] - 2.0 * cash[i] + cash[i + 1]).collect();
    let tent = by_payoff(|st| (st - 90.0).max(0.0) - 2.0 * (st - 100.0).max(0.0) + (st - 110.0).max(0.0), T2);
    let ramp = by_payoff(|st| (st - 90.0).max(0.0).min(10.0), T2);
    let ok_k = least_of(&spread) > 0.0 && most_of(&spread) < cap && least_of(&fly) > 0.0;
    println!("Acme: S = 100, r = 5%, q = 2%, sigma = 20%; expiries 0.5 and 1 year");
    println!("forward F(1) = S e^((r-q)T) {:12.6}   F(0.5) {:12.6}", fwd(T2), fwd(T1));
    println!("discount D(1) = e^(-rT)     {:12.6}   D(0.5) {:12.6}\n", disc(T2), disc(T1));
    println!("{:>5} {:>15} {:>12} {:>13} {:>12} {:>10}", "K", "C(K,1) formula", "by integral", "C(K)-C(K+10)", "cap D(1)*10", "butterfly");
    for i in 0..5 {
        let sp = if i < 4 { format!("{:13.6}", spread[i]) } else { format!("{:>13}", "--") };
        let bf = if i >= 1 && i <= 3 { format!("{:10.6}", fly[i - 1]) } else { format!("{:>10}", "--") };
        println!("{:5.0} {:15.6} {:12.6} {} {:12.6} {}", STRIKES[i], cash[i], integ[i], sp, cap, bf);
    }
    println!("every spread inside 0 and the cap, every butterfly above zero: {}", yn(ok_k));
    println!("butterfly 90/100/110 from three prices {:11.6};  90/110 average {:11.6}", fly[1], 0.5 * (cash[1] + cash[3]));
    println!("the same tent payoff, integrated       {:11.6};  call spread 90/100 {:11.6}", tent, spread[1]);
    println!("its capped ramp payoff, integrated     {:11.6};  C(100,1)           {:11.6}", ramp, cash[2]);
    // ---- the calendar pair, in forward-adjusted strike ----------------------------------
    let kfar = 100.0 * fwd(T2) / fwd(T1);           // the forward-adjusted strike
    let wgt = (-Q * (T2 - T1)).exp();               // near legs that one far leg can cover
    let (near, far) = (call(100.0, T1, S, SIG), call(kfar, T2, S, SIG));
    let money = 100.0 / fwd(T1);                    // forward moneyness, shared by the pair
    let (nrm_n, nrm_f) = (near / (S * (-Q * T1).exp()), far / (S * (-Q * T2).exp()));
    let (wn, wf) = (implied_w(money, nrm_n), implied_w(money, nrm_f));
    let spots = [60.0_f64, 80.0, 100.0, 120.0, 140.0, 160.0];
    let legf: Vec<f64> = spots.iter().map(|&x| call(kfar, T2 - T1, x, SIG)).collect();
    let short: Vec<f64> = spots.iter().map(|&x| wgt * (x - 100.0).max(0.0)).collect();
    let cover: Vec<f64> = (0..6).map(|i| legf[i] - short[i]).collect();
    let stable = |x: f64| if x <= 100.0 { call(kfar, T2 - T1, x, SIG) } else { putp(kfar, T2 - T1, x, SIG) };
    let byput: Vec<f64> = spots.iter().map(|&x| stable(x)).collect();
    let dense: Vec<f64> = (0..301).map(|i| stable(50.0 + 0.5 * i as f64)).collect();
    println!("\nforward-adjusted strike K2 = 100 F(1)/F(0.5) {:12.6};  weight w = e^(-q(T2-T1)) {:10.6}", kfar, wgt);
    println!("near call C(100, 0.5) {:11.6};  far call C(101.511306, 1) {:11.6};  far - w x near {:10.6}", near, far, far - wgt * near);
    println!("shared moneyness k {:8.6};  normalized c = C/(S e^(-qT)): near {:10.6}, far {:10.6}", money, nrm_n, nrm_f);
    println!("total implied variance by bisection: near {:8.6}, far {:8.6};  sigma^2 T {:8.6} {:8.6}", wn, wf, SIG * SIG * T1, SIG * SIG * T2);
    println!("at the near expiry the far leg covers w near legs, whatever Acme does");
    chart("Acme at T1  ", spots.iter().map(|x| format!("{:10.0}", x)).collect());
    chart("far leg     ", legf.iter().map(|v| format!("{:10.6}", v)).collect());
    chart("w x payoff  ", short.iter().map(|v| format!("{:10.6}", v)).collect());
    chart("cover       ", cover.iter().map(|v| format!("{:10.6}", v)).collect());
    chart("as far put  ", byput.iter().map(|v| format!("{:10.6}", v)).collect());
    println!("cover positive at 301 spots from 50 to 200: {};  peak {:10.6}", yn(least_of(&dense) > 0.0), most_of(&dense));
    // ---- road 3: no model at all.  A lumpy law with the right forward, and a tree -------
    let nodes = [60.0_f64, 85.0, 100.0, 125.0, 170.0];
    let mut prob = [0.10_f64, 0.20, 0.40, 0.0, 0.0];
    let part: f64 = nodes.iter().zip(prob.iter()).map(|(n, p)| n * p).sum();
    prob[3] = (fwd(T2) - part - 170.0 * 0.30) / (125.0 - 170.0);
    prob[4] = 0.30 - prob[3];        // the last two weights are what makes the mean equal F(1)
    let lump = |k: f64| disc(T2) * nodes.iter().zip(prob.iter()).map(|(n, p)| p * (n - k).max(0.0)).sum::<f64>();
    let lsp: Vec<f64> = STRIKES[..4].iter().map(|&k| lump(k) - lump(k + 10.0)).collect();
    let lfly: Vec<f64> = STRIKES[1..4].iter().map(|&k| lump(k - 10.0) - 2.0 * lump(k) + lump(k + 10.0)).collect();
    let (up, dn) = (1.25_f64, 0.80_f64);
    let pu = (1.0 - dn) / (up - dn);  // the weights hold the forward flat: pu*up + (1-pu)*dn = 1
    let law1 = [(up, pu), (dn, 1.0 - pu)];
    let law2 = [(up * up, pu * pu), (up * dn, 2.0 * pu * (1.0 - pu)), (dn * dn, (1.0 - pu) * (1.0 - pu))];
    let cl = |law: &[(f64, f64)], k: f64| law.iter().map(|(x, p)| p * (x - k).max(0.0)).sum::<f64>();
    let gaps: Vec<f64> = (0..33).map(|i| cl(&law2, 0.60 + 0.025 * i as f64) - cl(&law1, 0.60 + 0.025 * i as f64)).collect();
    let ok_lump = least_of(&lsp) > 0.0 && most_of(&lsp) < cap && least_of(&lfly) > 0.0;
    let ns = nodes.iter().map(|n| format!("{:.0}", n)).collect::<Vec<_>>().join(", ");
    let ws = prob.iter().map(|p| format!("{:.6}", p)).collect::<Vec<_>>().join(", ");
    println!("\nlumpy law, no Black-Scholes: nodes {}, weights {}", ns, ws);
    println!("its mean {:11.6} is F(1);  both strike rules hold: {};  its 90/100/110 butterfly {:10.6}",
             nodes.iter().zip(prob.iter()).map(|(n, p)| n * p).sum::<f64>(), yn(ok_lump), lfly[1]);
    println!("two-step flat-forward tree at moneyness 0.90: near {:10.6}, far {:10.6}", cl(&law1, 0.90), cl(&law2, 0.90));
    println!("none of 33 moneynesses from 0.60 to 1.40 falls with expiry: {}", yn(least_of(&gaps) > -1e-15));
    // ---- a hand-made sheet that breaks all three, and the free trade -------------------
    let quote = [(80.0_f64, 24.80_f64), (90.0, 15.10), (100.0, 10.60), (110.0, 5.20), (120.0, 5.40)];
    let (qnear, qfar) = (8.60_f64, 8.40_f64);       // half-year 100-call, one-year 101.511306-call
    let worst = |legs: &[(f64, f64)], csh: f64, t: f64| csh / disc(t) + least_of(&(0..1200).map(|i|
        legs.iter().map(|(k, n)| n * (1.0 + 0.25 * i as f64 - k).max(0.0)).sum()).collect::<Vec<f64>>());
    let (bad_cap, bad_cal) = (quote[0].1 - quote[1].1, wgt * qnear - qfar);
    let (bad_fly, bad_mon) = (2.0 * quote[2].1 - quote[1].1 - quote[3].1, quote[4].1 - quote[3].1);
    let qs = quote.iter().map(|(k, v)| format!("{:.0} at {:.2}", k, v)).collect::<Vec<_>>().join(", ");
    println!("\nhand-made one-year quotes: {};  half-year 100-call {:.2}, one-year 101.511306-call {:.2}", qs, qnear, qfar);
    println!("{:<30}{:>14}{:>20}{:>18}", "rule broken", "cash in today", "least wealth later", "free money today");
    let names = ["cap on the 80/90 spread", "butterfly 90/100/110", "the 120 quoted above the 110", "calendar, near against far"];
    let legs: [&[(f64, f64)]; 3] = [&[(80.0, -1.0), (90.0, 1.0)], &[(90.0, 1.0), (100.0, -2.0), (110.0, 1.0)], &[(110.0, 1.0), (120.0, -1.0)]];
    let cshs = [bad_cap, bad_fly, bad_mon, bad_cal];
    let frees = [bad_cap - cap, bad_fly, bad_mon, bad_cal];
    let leasts: Vec<f64> = (0..4).map(|i| if i < 3 { worst(legs[i], cshs[i], T2) }
                                          else { cshs[i] / disc(T1) + least_of(&dense) }).collect();
    for i in 0..4 { println!("{:<30}{:14.6}{:20.6}{:18.6}", names[i], cshs[i], leasts[i], frees[i]); }
    // ---- what breaks if a piece is dropped ---------------------------------------------
    println!("\nno forward adjustment: cash C(100,200) - C(100,1) {:10.6}", call(100.0, 200.0, S, SIG) - cash[2]);
    println!("cap read as 10.00 not {:.6}: free money per spread {:10.6}", cap, 10.0 - cap);
    println!("unequal wings 90/100/120, weights 2 to 1: bound {:10.6}, plain average {:10.6}", (2.0 * cash[1] + cash[4]) / 3.0, 0.5 * (cash[1] + cash[4]));
    println!("implied vol 25% then 20% is no violation: total variance {:8.6} then {:8.6}, normalized call {:8.6} then {:8.6}",
             0.25 * 0.25 * T1, SIG * SIG * T2, call(100.0, T1, S, 0.25) / (S * (-Q * T1).exp()), nrm_f);
    chart("\nchart, strike K     ", (0..9).map(|i| format!("{:8.0}", 80.0 + 5.0 * i as f64)).collect());
    chart("chart, call C(K,1)  ", (0..9).map(|i| format!("{:8.2}", call(80.0 + 5.0 * i as f64, T2, S, SIG))).collect());
    chart("chart, chord 90-110 ", (0..9).map(|i| format!("{:8.2}", cash[1] + (i as f64 - 2.0) * (cash[3] - cash[1]) / 4.0)).collect());
    chart("chart, Acme at T1   ", spots.iter().map(|x| format!("{:8.0}", x)).collect());
    chart("chart, far leg      ", legf.iter().map(|v| format!("{:8.2}", v)).collect());
    chart("chart, w x payoff   ", short.iter().map(|v| format!("{:8.2}", v)).collect());
    assert!((cash[2] - 9.227005508154).abs() < 1e-9, "the shelf's house call");
    assert!((0..5).map(|i| (cash[i] - integ[i]).abs()).fold(0.0, f64::max) < 1e-6
        && (fly[1] - tent).abs() < 1e-6 && (spread[1] - ramp).abs() < 1e-6, "formula and combinations vs payoffs");
    assert!(ok_k && least_of(&dense) > 0.0, "the house strip obeys both strike rules, and the far leg covers");
    assert!((0..6).map(|i| (cover[i] - byput[i]).abs()).fold(0.0, f64::max) < 1e-12, "cover equals the far put");
    assert!((wn - SIG * SIG * T1).abs() < 1e-9 && (wf - SIG * SIG * T2).abs() < 1e-9, "bisection recovers sigma^2 T");
    assert!(ok_lump && least_of(&gaps) > -1e-15 && (lump(0.0) - disc(T2) * fwd(T2)).abs() < 1e-9
        && (cl(&law1, 0.0) - 1.0).abs() + (cl(&law2, 0.0) - 1.0).abs() < 1e-15,
        "a lumpy law and a tree, each carrying the right forward, obey all three rules");
    assert!(least_of(&cshs) > 0.0 && least_of(&frees) > 0.0 && least_of(&leasts) > 0.0,
            "each broken rule pays cash that outlasts its worst outcome");
    println!("ALL CHECKS PASS");
}
