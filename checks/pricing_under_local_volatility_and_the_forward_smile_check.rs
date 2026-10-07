// Pricing with local volatility -- the same check as the Python, in Rust.  No crates; nothing
// imported knows the answer: the bell-curve area is its power series, the random numbers the
// Monte Carlo card's recurrence, the grid a Crank-Nicolson march.  Two roads to every price.
use std::f64::consts::PI;
const S0: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20; const RHO: f64 = -0.7;
const ETA: f64 = 0.5; const T1: f64 = 0.5; const T: f64 = 1.0; const DZ: f64 = 0.01; const ZL: f64 = -3.0;
const NZ: usize = 600; const DT: f64 = 0.01; const NT: usize = 100; const PATHS: usize = 20000; const NP: f64 = PATHS as f64; const H: f64 = NP / 2.0;
fn ncdf(x: f64) -> f64 {                        // bell-curve area left of x, by its power series
    let (mut term, mut total) = (x, x);
    for n in 1..150 { term *= x * x / (2 * n + 1) as f64; total += term; }
    if x.abs() < 9.0 { 0.5 + total * (-0.5 * x * x).exp() / (2.0 * PI).sqrt() } else if x > 0.0 { 1.0 } else { 0.0 }
}
fn bs(s: f64, k: f64, t: f64, vol: f64) -> f64 { // Black-Scholes call
    let d1 = ((s / k).ln() + (R - Q) * t) / (vol * t.sqrt()) + 0.5 * vol * t.sqrt();
    s * (-Q * t).exp() * ncdf(d1) - k * (-R * t).exp() * ncdf(d1 - vol * t.sqrt())
}
fn implied(price: f64, s: f64, k: f64, t: f64) -> f64 { // bisection: the one vol that gives this price
    let (mut lo, mut hi) = (0.01, 1.5);
    for _ in 0..60 { if bs(s, k, t, 0.5 * (lo + hi)) > price { hi = 0.5 * (lo + hi) } else { lo = 0.5 * (lo + hi) } }
    0.5 * (lo + hi)
}
fn w(x: f64, t: f64, eta: f64) -> f64 {         // the skewed surface: total variance at x = log(K/100)
    let (th, p) = (SIG * SIG * t, eta / (SIG * t.sqrt()));
    0.5 * th * (1.0 + RHO * p * x + ((p * x + RHO) * (p * x + RHO) + 1.0 - RHO * RHO).sqrt())
}
fn ivol(k: f64, t: f64) -> f64 { (w((k / S0).ln(), t, ETA) / t).sqrt() }
fn fwd(kap: f64, vol: f64) -> f64 { S0 * (-Q * T1).exp() * bs(1.0, kap, T - T1, vol) }
fn lv(z: f64, t: f64, eta: f64) -> (f64, f64, f64) { // Dupire in implied-vol terms, slopes by small steps
    let ww = |k: f64, tt: f64| w(k + (R - Q) * tt, tt, eta);  // the surface against log(K/forward)
    let (k, h, e) = (z - (R - Q) * t, 1e-4, 1e-5);
    let (w0, w1) = (ww(k, t), (ww(k + h, t) - ww(k - h, t)) / (2.0 * h));
    let w2 = (ww(k + h, t) - 2.0 * ww(k, t) + ww(k - h, t)) / (h * h);
    let g = (1.0 - k * w1 / (2.0 * w0)) * (1.0 - k * w1 / (2.0 * w0)) - w1 * w1 / 4.0 * (1.0 / w0 + 0.25) + w2 / 2.0;
    let wt = (ww(k, t + e) - ww(k, t - e)) / (2.0 * e);
    ((wt / g).sqrt(), g, wt)
}
fn march(n0: usize, s: f64, tab: &[Vec<f64>], n1: usize) -> Vec<f64> { // Dupire's forward equation from price s
    let mut c: Vec<f64> = (0..=NZ).map(|j| (s - S0 * (ZL + DZ * j as f64).exp()).max(0.0)).collect();
    c[(((s / S0).ln() - ZL) / DZ).round() as usize] = s * (0.5 * DZ - 1.0 + (-0.5 * DZ).exp()) / DZ; // kink cell
    for n in n0..n1 {
        let lo = s * (-Q * (n + 1 - n0) as f64 * DT).exp() - S0 * ZL.exp() * (-R * (n + 1 - n0) as f64 * DT).exp();
        let (mut cp, mut dp, mut new) = (vec![0.0; NZ + 1], vec![lo; NZ + 1], vec![0.0; NZ + 1]); new[0] = lo;
        for j in 1..NZ {                            // Thomas sweep down, then back up
            let (p, adv) = (0.5 * tab[n][j] * tab[n][j] / (DZ * DZ), (0.5 * tab[n][j] * tab[n][j] + R - Q) / (2.0 * DZ));
            let (a, b, cc) = (p + adv, -2.0 * p - Q, p - adv);
            let m = 1.0 - 0.5 * DT * b + 0.5 * DT * a * cp[j - 1];
            cp[j] = -0.5 * DT * cc / m; dp[j] = (c[j] + 0.5 * DT * (a * c[j - 1] + b * c[j] + cc * c[j + 1]) + 0.5 * DT * a * dp[j - 1]) / m;
        }
        for j in (1..NZ).rev() { new[j] = dp[j] - cp[j] * new[j + 1]; }
        c = new;
    }
    c
}
fn at(c: &[f64], k: f64) -> f64 {               // read the grid at strike k, three-point fit
    let u = ((k / S0).ln() - ZL) / DZ;
    let (f, j) = (u - u.round(), u.round() as usize);
    c[j] + 0.5 * f * (c[j + 1] - c[j - 1]) + 0.5 * f * f * (c[j + 1] - 2.0 * c[j] + c[j - 1])
}
fn twin(k: f64) -> (f64, f64, f64, f64, f64) {  // coin-flip vol, 40% w.p. 0.12 else 15%, and its twin
    let c = |kk: f64, t: f64| 0.12 * bs(S0, kk, t, 0.40) + 0.88 * bs(S0, kk, t, 0.15);
    let (h, e, x) = (0.001 * k, 1e-4, (k / S0).ln() - R + Q);   // each world's chance per dollar of ending at k
    let f = |p: f64, v: f64| p * (-0.5 * (x + 0.5 * v * v) * (x + 0.5 * v * v) / (v * v)).exp() / (k * v * (2.0 * PI).sqrt());
    let (fa, fb) = (f(0.12, 0.40), f(0.88, 0.15));
    let num = (c(k, T + e) - c(k, T - e)) / (2.0 * e) + (R - Q) * k * (c(k + h, T) - c(k - h, T)) / (2.0 * h) + Q * c(k, T);
    let dup = (2.0 * num / (k * k * (c(k + h, T) - 2.0 * c(k, T) + c(k - h, T)) / (h * h))).sqrt(); // Dupire from prices
    (fa, fb, fa / (fa + fb), dup, ((fa * 0.16 + fb * 0.0225) / (fa + fb)).sqrt())
}
fn row(label: &str, vals: &[f64], width: usize, prec: usize) {
    println!("{}{}", label, vals.iter().map(|v| format!("{:w$.p$}", v, w = width, p = prec)).collect::<String>());
}
fn main() {
    let z: Vec<f64> = (0..=NZ).map(|j| ZL + DZ * j as f64).collect();
    let (ks, kaps): (Vec<f64>, Vec<f64>) = ((0..9).map(|i| 80.0 + 5.0 * i as f64).collect(), (0..9).map(|i| 0.8 + 0.05 * i as f64).collect());
    let lvs: Vec<Vec<(f64, f64, f64)>> = (0..NT).map(|n| z.iter().map(|&zz| lv(zz, (n as f64 + 0.5) * DT, ETA)).collect()).collect();
    let tab: Vec<Vec<f64>> = lvs.iter().map(|r| r.iter().map(|v| v.0).collect()).collect();
    let (full, half) = (march(0, S0, &tab, NT), march(0, S0, &tab, NT / 2));
    let (grid, surf): (Vec<f64>, Vec<f64>) = (ks.iter().map(|&k| at(&full, k)).collect(), ks.iter().map(|&k| bs(S0, k, T, ivol(k, T))).collect());
    let gap6 = ks.iter().map(|&k| (at(&half, k) - bs(S0, k, T1, ivol(k, T1))).abs()).fold(0.0, f64::max);
    let (mut state, mut cv, mut fs, mut acc) = (20260924u64, [0.0f64; 9], [0.0f64; 9], [0.0f64; 8]);
    for _ in 0..PATHS / 2 {
        let (mut zs, mut pv): (Vec<f64>, [f64; 4]) = (Vec::with_capacity(NT), [0.0; 4]); // pv: the pair's averages
        for _ in 0..NT / 2 {                      // the recurrence, then Box-Muller: two fractions, two draws
            state = (1664525 * state + 1013904223) % 4294967296;
            let u = (state as f64 + 0.5) / 4294967296.0; state = (1664525 * state + 1013904223) % 4294967296;
            let (rad, ang) = ((-2.0 * u.ln()).sqrt(), 2.0 * PI * (state as f64 + 0.5) / 4294967296.0);
            zs.extend([rad * ang.cos(), rad * ang.sin()]);
        }
        for sign in [1.0, -1.0] {                 // each path and its mirror image
            let (mut x, mut y, mut sh, mut sfh) = (0.0f64, 0.0f64, 0.0f64, 0.0f64);
            for n in 0..NT {                      // log(price/100): local vol, and flat 20% on the same draws
                let (u, iu) = ((x - ZL) / DZ, ((x - ZL) / DZ) as usize);
                let vol = tab[n][iu] + (u - iu as f64) * (tab[n][iu + 1] - tab[n][iu]);
                x += (R - Q - 0.5 * vol * vol) * DT + vol * sign * zs[n] * DT.sqrt();
                y += (R - Q - 0.5 * SIG * SIG) * DT + SIG * sign * zs[n] * DT.sqrt();
                if n == NT / 2 - 1 { sh = S0 * x.exp(); sfh = S0 * y.exp(); }
            }
            let (st, sf) = (S0 * x.exp(), S0 * y.exp());
            for i in 0..9 {                       // payoff under local vol minus payoff under flat 20%
                cv[i] += (st - ks[i]).max(0.0) - (sf - ks[i]).max(0.0);
                fs[i] += (st - kaps[i] * sh).max(0.0) - (sf - kaps[i] * sfh).max(0.0);
            }
            let (pl, fl) = ((st - 100.0).max(0.0), (sf - sfh).max(0.0)); // plain payoff; the flat control's own forward start
            pv = [pv[0] + 0.5 * pl, pv[1] + 0.5 * (pl - (sf - 100.0).max(0.0)), pv[2] + 0.5 * ((st - sh).max(0.0) - fl), pv[3] + 0.5 * fl];
        }
        for i in 0..8 { acc[i] += if i % 2 == 0 { pv[i / 2] } else { pv[i / 2] * pv[i / 2] }; } // sums, sums of squares
    }
    let se = |m: usize| (-R * T).exp() * ((acc[2 * m + 1] / H - (acc[2 * m] / H) * (acc[2 * m] / H)) / H).sqrt(); // from pair averages
    let (mc, mcfs): (Vec<f64>, Vec<f64>) = ((0..9).map(|i| (-R * T).exp() * cv[i] / NP + bs(S0, ks[i], T, SIG)).collect(), (0..9).map(|i| (-R * T).exp() * fs[i] / NP + fwd(kaps[i], SIG)).collect());
    let (mut fsg, mut reset, mut avg) = ([0.0f64; 9], Vec::new(), [0.0f64; 4]); // road 2: where Acme stands at the reset, times the grid
    for (i, j) in (200..371).step_by(5).enumerate() {
        let s = S0 * z[j].exp();
        let c = march(NT / 2, s, &tab, NT);
        let dens = (R * T1).exp() * (bs(S0, 1.01 * s, T1, ivol(1.01 * s, T1)) - 2.0 * bs(S0, s, T1, ivol(s, T1)) + bs(S0, 0.99 * s, T1, ivol(0.99 * s, T1))) / ((0.01 * s) * (0.01 * s));
        let wi = if i == 0 || i == 34 { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        let wgt = wi * 5.0 * DZ / 3.0 * s * dens * (-R * T1).exp(); // Simpson's rule
        for m in 0..9 { fsg[m] = fsg[m] + wgt * at(&c, kaps[m] * s); }
        let v = implied(at(&c, s), s, s, T - T1);  // the at-the-money vol for the second half-year, from s
        avg = [avg[0] + wgt * v, avg[1] + wgt, avg[2] + wgt * s * v, avg[3] + wgt * s];
        if [280, 290, 300, 310, 320].contains(&j) { reset.push((s, v)); }
    }
    let fvol = |p: f64, kap: f64| implied(p / (S0 * (-Q * T1).exp()), 1.0, kap, T - T1);
    let imp: Vec<Vec<f64>> = (0..NT).map(|n| z.iter().map(|&zz| ivol(S0 * zz.exp(), (n as f64 + 0.5) * DT)).collect()).collect();
    let date: Vec<Vec<f64>> = tab.iter().map(|r| vec![r[300]; NZ + 1]).collect();
    let wrong = [march(0, S0, &imp, NT), march(0, S0, &date, NT), march(0, S0, &vec![tab[8].clone(); NT], NT)];
    let prices: Vec<f64> = (0..7).map(|i| 70.0 + 10.0 * i as f64).collect();
    row("local vol from the skewed surface, %; Acme's price across, date down\nprice    ", &prices, 7, 0);
    for t in [9usize, 49, 99].map(|n| (n as f64 + 0.5) * DT) {
        row(&format!("t = {:.3}", t), &prices.iter().map(|&p| 100.0 * lv((p / S0).ln(), t, ETA).0).collect::<Vec<f64>>(), 7, 2);
    }
    println!("flat 20% surface, local vol at (80, 0.5) and (120, 1.0)  {:.6}  {:.6}", lv(0.8f64.ln(), 0.5, 0.0).0, lv(1.2f64.ln(), 1.0, 0.0).0);
    println!("no arbitrage on the grid: least g {:.6}, least dw/dT {:.6}", lvs.iter().flatten().map(|v| v.1).fold(f64::INFINITY, f64::min), lvs.iter().flatten().map(|v| v.2).fold(f64::INFINITY, f64::min));
    println!("1-year strip  surface vol  surface price   grid price   MC price   MC vol");
    for i in 0..9 {
        println!("{:8.0}{:12.2}{:15.6}{:13.6}{:11.4}{:9.2}", ks[i], 100.0 * ivol(ks[i], T), surf[i], grid[i], mc[i], 100.0 * implied(mc[i], S0, ks[i], T));
    }
    println!("6-month strip, largest gap grid vs surface  {:.6}", gap6);
    println!("$100 call: plain MC {:.4} s.e. {:.4}; flat-20% control s.e. {:.4}", 2.0 * (-R * T).exp() * acc[0] / NP, se(0), se(1));
    println!("coin-flip twin, strike  40% world  15% world  share of 40%  Dupire vol  E[vol^2 | S_T = K]");
    for (k, tw) in [70.0, 100.0, 140.0].map(|k| (k, twin(k))) {
        println!("{:22.0}{:11.6}{:11.6}{:14.4}{:12.2}{:12.2}", k, tw.0, tw.1, tw.2, 100.0 * tw.3, 100.0 * tw.4);
    }
    let (d1, v) = ((R - Q) * (T - T1) / (SIG * (T - T1).sqrt()) + 0.5 * SIG * (T - T1).sqrt(), SIG * (T - T1).sqrt());
    println!("forward start at flat 20% by hand: d1 {:.6} d2 {:.6} N(d1) {:.6} N(d2) {:.6}", d1, d1 - v, ncdf(d1), ncdf(d1 - v));
    println!("  per-dollar call {:.6} x S0 e^-qT1 {:.6} = {:.6}", bs(1.0, 1.0, T - T1, SIG), S0 * (-Q * T1).exp(), fwd(1.0, SIG));
    println!("forward start, strike % of reset  today 6m vol  grid price  MC price  grid vol  MC vol");
    for m in [0usize, 2, 4, 6, 8] {
        println!("{:24.0}{:14.2}{:12.4}{:10.4}{:10.2}{:8.2}", 100.0 * kaps[m], 100.0 * ivol(100.0 * kaps[m], T1), fsg[m], mcfs[m], 100.0 * fvol(fsg[m], kaps[m]), 100.0 * fvol(mcfs[m], kaps[m]));
    }
    println!("at the money: flat 20% {:.6} (flat paths alone {:.4} s.e. {:.4})", fwd(1.0, SIG), 2.0 * (-R * T).exp() * acc[6] / NP, se(3));
    println!("  local vol: grid {:.6}, MC {:.4} s.e. {:.4}, gap {:.4}", fsg[4], mcfs[4], se(2), fsg[4] - fwd(1.0, SIG));
    row("reset level  ", &reset.iter().map(|r| r.0).collect::<Vec<f64>>(), 8, 2);
    row("ATM vol after", &reset.iter().map(|r| 100.0 * r.1).collect::<Vec<f64>>(), 8, 2);
    println!("ATM vol after the reset, averaged over where Acme stands: plain {:.2}%, weighted by its price {:.2}%", 100.0 * avg[0] / avg[1], 100.0 * avg[2] / avg[3]);
    row("chart, strike % of reset", &kaps.iter().map(|k| 100.0 * k).collect::<Vec<f64>>(), 7, 0);
    row("chart, today's 6m vol % ", &kaps.iter().map(|&k| 100.0 * ivol(100.0 * k, T1)).collect::<Vec<f64>>(), 7, 2);
    row("chart, forward vol %    ", &(0..9).map(|m| 100.0 * fvol(fsg[m], kaps[m])).collect::<Vec<f64>>(), 7, 2);
    for (name, c) in ["implied vol as local vol", "local vol by date only", "one-month local vol all year"].iter().zip(wrong.iter()) {
        println!("wrong: {:<29}$80 {:.4} ({:.2}%)  $120 {:.4} ({:.2}%)", name, at(c, 80.0), 100.0 * implied(at(c, 80.0), S0, 80.0, T), at(c, 120.0), 100.0 * implied(at(c, 120.0), S0, 120.0, T));
    }
    assert!(grid.iter().zip(&surf).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max) < 0.005 && gap6 < 0.005); // grid gives the surface back
    assert!(mc.iter().zip(&surf).all(|(a, b)| (a - b).abs() < 0.1));           // so do the simulated paths
    assert!((mc[4] - 9.227005508154).abs() < 3.0 * se(1) + 0.005);              // the house call: 3 s.e. and half a cent
    assert!((mcfs[4] - fsg[4]).abs() < 3.0 * se(2) + 0.005);                    // two roads to the forward start
    assert!((2.0 * (-R * T).exp() * acc[6] / NP - fwd(1.0, SIG)).abs() < 3.0 * se(3)); // the control is honest
    assert!(fsg[4] < fwd(1.0, SIG) - 0.1 && mcfs[4] < fwd(1.0, SIG) - 0.1);     // both below the flat value
    assert!(fvol(fsg[2], 0.9) - fvol(fsg[6], 1.1) < 0.7 * (ivol(90.0, T1) - ivol(110.0, T1))); // forward smile flatter
    assert!((avg[2] / avg[3] - fvol(fsg[4], 1.0)).abs() < 5e-4 && avg[0] / avg[1] > avg[2] / avg[3] + 0.005); // Step 7's weighting
    assert!([70.0, 100.0, 140.0].iter().all(|&k| (twin(k).3 - twin(k).4).abs() < 5e-4)); // Gyongy: two roads, one twin
    println!("ALL CHECKS PASS");
}
