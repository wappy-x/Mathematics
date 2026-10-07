// Bootstrapping a CDS hazard curve: Northwind quotes 120, 200, 250 bp at 1, 3, 5 years.
// Quarterly premiums paid while alive, protection paid at the default date. Rust std only.
const RATE: f64 = 0.05; // riskless rate
const LOSS: f64 = 0.60; // loss on default = 1 - recovery 40%
const KNOTS: [f64; 4] = [0.0, 1.0, 3.0, 5.0];
const QUOTES: [f64; 3] = [0.0120, 0.0200, 0.0250];

fn surv(t: f64, lam: &[f64]) -> f64 { // S(t) = exp(-area under the step hazard); last piece runs on
    let mut area = 0.0;
    for (i, h) in lam.iter().enumerate() {
        let right = if i + 1 < lam.len() { KNOTS[i + 1] } else { f64::INFINITY };
        area += h * (t.min(right) - KNOTS[i]).max(0.0);
    }
    (-area).exp()
}

fn annuity(t: f64, lam: &[f64]) -> f64 { // risky annuity: 0.25 years of premium per quarter survived, discounted
    (1..=(4.0 * t).round() as usize).map(|j| 0.25 * (-RATE * j as f64 / 4.0).exp() * surv(j as f64 / 4.0, lam)).sum()
}

fn pieces(t: f64, lam: &[f64]) -> Vec<(f64, f64, f64)> { // (left, right, hazard) for each flat piece in [0, T]
    let mut edges: Vec<f64> = [0.0].iter().chain(KNOTS[1..lam.len()].iter().filter(|k| **k < t)).cloned().collect();
    edges.push(t);
    (0..edges.len() - 1).map(|i| (edges[i], edges[i + 1], lam[i])).collect()
}

fn prot_closed(t: f64, lam: &[f64]) -> f64 { // road 1: protection leg, exact integral on each flat piece
    pieces(t, lam).iter().map(|&(a, b, h)| { let k = RATE + h;
        LOSS * (-RATE * a).exp() * surv(a, lam) * h / k * (1.0 - (-k * (b - a)).exp()) }).sum()
}

fn prot_simpson(t: f64, lam: &[f64]) -> f64 { // road 2: the same integral, L * D(t) * hazard * S(t), by Simpson's rule
    let (n, mut total) = (64, 0.0);
    for (a, b, h) in pieces(t, lam) {
        let (w, mut s) = ((b - a) / n as f64, 0.0);
        for j in 0..=n {
            let (c, u) = (if j == 0 || j == n { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 }, a + j as f64 * w);
            s += c * (LOSS * (-RATE * u).exp() * h * surv(u, lam));
        }
        total += w / 3.0 * s;
    }
    total
}

fn par(t: f64, lam: &[f64]) -> f64 { prot_closed(t, lam) / annuity(t, lam) }
fn par2(t: f64, lam: &[f64]) -> f64 { prot_simpson(t, lam) / annuity(t, lam) }

fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 { // own root finder; f rises through zero
    for _ in 0..100 { let mid = 0.5 * (lo + hi); if f(mid) < 0.0 { lo = mid; } else { hi = mid; } }
    0.5 * (lo + hi)
}

fn bootstrap(quotes: &[f64], low: f64) -> Vec<f64> { // one piece at a time, earlier pieces frozen
    let mut lam: Vec<f64> = Vec::new();
    for (i, s) in quotes.iter().enumerate() {
        let h = bisect(|h| { let mut l = lam.clone(); l.push(h); par(KNOTS[i + 1], &l) - s }, low, 1.0);
        lam.push(h);
    }
    lam
}

fn f6(x: f64) -> String { format!("{:.6}", x) }
fn bp(x: f64) -> String { format!("{:.2}", 10000.0 * x) }
fn row(label: &str, v: Vec<String>) { println!("{}{}", label, v.join(" ")); }

fn main() {
    let lam = bootstrap(&QUOTES, 0.0);
    println!("Northwind: r 0.05, recovery 0.40, quarterly premiums, quotes 120/200/250 bp");
    println!("road 1: one piece at a time, bisection on closed-form legs");
    for i in 0..3 {
        println!("  piece {:.0}-{:.0}y  hazard {}  S({:.0}) {}", KNOTS[i], KNOTS[i + 1], f6(lam[i]), KNOTS[i + 1], f6(surv(KNOTS[i + 1], &lam)));
    }
    for t in [1.0, 3.0, 5.0] {
        println!("  legs to {:.0}y  annuity {}  protection {}", t, f6(annuity(t, &lam)), f6(prot_closed(t, &lam)));
    }
    println!("  frozen weight D(1)S(1) {}  triangle guess 1y {}  flat 2% 5y par {} bp", f6((-RATE).exp() * surv(1.0, &lam)), f6(QUOTES[0] / LOSS), bp(par(5.0, &[0.02])));
    println!("round trip: reprice every quote with the Simpson protection leg");
    let trip: Vec<f64> = (0..3).map(|i| par2(KNOTS[i + 1], &lam)).collect();
    for i in 0..3 {
        println!("  {:.0}y quote {} bp  repriced {:.6} bp", KNOTS[i + 1], bp(QUOTES[i]), 10000.0 * trip[i]);
    }

    // road 2: all three equations at once, Newton from the triangle guesses
    let mut x: Vec<f64> = QUOTES.iter().map(|s| s / LOSS).collect();
    let mut upper = [1.0; 3];
    for _ in 0..8 {
        let g: Vec<f64> = (0..3).map(|i| par2(KNOTS[i + 1], &x) - QUOTES[i]).collect();
        let mut a = [[0.0f64; 4]; 3];
        for i in 0..3 {
            for j in 0..3 { let mut xb = x.clone(); xb[j] += 1e-6; a[i][j] = (par2(KNOTS[i + 1], &xb) - QUOTES[i] - g[i]) / 1e-6; }
            a[i][3] = -g[i];
        }
        upper = [a[0][1], a[0][2], a[1][2]];
        for c in 0..3 { // Gaussian elimination, written out
            for r in c + 1..3 { let m = a[r][c] / a[c][c]; for k in 0..4 { a[r][k] -= m * a[c][k]; } }
        }
        let mut dx = [0.0; 3];
        for r in (0..3).rev() {
            dx[r] = (a[r][3] - (r + 1..3).map(|k| a[r][k] * dx[k]).sum::<f64>()) / a[r][r];
        }
        for i in 0..3 { x[i] += dx[i]; }
    }
    println!("road 2: all three at once, Newton on Simpson legs, from triangle guesses");
    println!("  hazards {} {} {}  Jacobian above diagonal {}", f6(x[0]), f6(x[1]), f6(x[2]), upper.iter().map(|u| f6(*u)).collect::<Vec<_>>().join(" "));

    // road 3: simulate default dates on the fitted curve, own generator
    let (mut state, n, mut cum): (u64, usize, Vec<f64>) = (42, 1_000_000, vec![0.0]);
    for j in 1..41 { let c = cum[j - 1] + 0.25 * (-RATE * j as f64 / 4.0).exp(); cum.push(c); }
    let (mut pr2, mut pp2, mut pr5, mut pp5, mut alive5) = (0.0, 0.0, 0.0, 0.0, 0.0);
    for _ in 0..n {
        state = state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        let (mut e, mut tau) = (-((((state >> 11) as f64) + 0.5) / 9007199254740992.0).ln(), 0.0);
        for (i, h) in lam.iter().enumerate() {
            let width = if i < 2 { KNOTS[i + 1] - KNOTS[i] } else { f64::INFINITY };
            if e <= h * width { tau = KNOTS[i] + e / h; break; }
            e -= h * width;
        }
        let q = ((4.0 * tau) as usize).min(40);
        pr2 += cum[q.min(8)]; pr5 += cum[q.min(20)];
        pp2 += if tau <= 2.0 { LOSS * (-RATE * tau).exp() } else { 0.0 };
        pp5 += if tau <= 5.0 { LOSS * (-RATE * tau).exp() } else { 0.0 };
        alive5 += if tau > 5.0 { 1.0 } else { 0.0 };
    }
    let (mc2, mc5, mcs5) = (pp2 / pr2, pp5 / pr5, alive5 / n as f64);
    println!("road 3: Monte Carlo, {} default dates on the road-1 curve", n);
    let (s2, s5) = (surv(2.0, &lam), surv(5.0, &lam));
    let se2 = 10000.0 * par(2.0, &lam) * ((s2 / (1.0 - s2)) / n as f64).sqrt();
    println!("  2y par {} bp (standard error {:.2})  5y par {} bp  S(5) {:.4}", bp(mc2), se2, bp(mc5), mcs5);

    println!("unquoted tenors, hazard held at the last piece after 5y");
    println!("  2y par {} bp  straight line between quotes {} bp  S(2) {}", bp(par(2.0, &lam)), bp(0.5 * (QUOTES[0] + QUOTES[1])), f6(s2));
    println!("  10y par {} bp  S(10) {}", bp(par(10.0, &lam)), f6(surv(10.0, &lam)));
    let yrs: Vec<usize> = (1..11).collect();
    let line = |t: f64| if t <= 3.0 { QUOTES[0] + (QUOTES[1] - QUOTES[0]) * (t - 1.0) / 2.0 } else { (QUOTES[1] + (QUOTES[2] - QUOTES[1]) * (t - 3.0) / 2.0).min(QUOTES[2]) };
    row("chart, tenor (years)      ", yrs.iter().map(|t| format!("{:6}", t)).collect());
    row("chart, fitted par (bp)    ", yrs.iter().map(|t| format!("{:6.2}", 10000.0 * par(*t as f64, &lam))).collect());
    row("chart, straight line (bp) ", yrs.iter().map(|t| format!("{:6.2}", 10000.0 * line(*t as f64))).collect());
    row("chart, hazard in year (%) ", yrs.iter().map(|t| format!("{:6.2}", 100.0 * lam[if *t <= 1 { 0 } else if *t <= 3 { 1 } else { 2 }])).collect());
    row("chart, par / loss (%)     ", yrs.iter().map(|t| format!("{:6.2}", 100.0 * par(*t as f64, &lam) / LOSS)).collect());

    // what breaks: the triangle, or each tenor's flat hazard, as the pieces
    let tri: Vec<f64> = QUOTES.iter().map(|s| s / LOSS).collect();
    let flat: Vec<f64> = (0..3).map(|i| bisect(|h| par(KNOTS[i + 1], &[h]) - QUOTES[i], 0.0, 1.0)).collect();
    let mut tail0 = lam.clone(); tail0.push(0.0);
    println!("what breaks");
    println!("  triangle s/L as the pieces: 3y reprices {} bp, 5y {} bp", bp(par(3.0, &tri)), bp(par(5.0, &tri)));
    println!("  each tenor's flat hazard as its piece {} {}: 3y {} bp, 5y {} bp", f6(flat[1]), f6(flat[2]), bp(par(3.0, &flat)), bp(par(5.0, &flat)));
    println!("  no defaults after 5y: 10y par {} bp", bp(par(10.0, &tail0)));

    // the failure case: an inverted pair
    let bad = [0.0600, 0.0200];
    let (b1, neg, ok) = (bootstrap(&bad[..1], 0.0), bootstrap(&bad, -0.04), bootstrap(&[0.0600, 0.0300], 0.0));
    let floor = par(3.0, &[b1[0], 0.0]);
    println!("failure case: 1y 600 bp, then 3y 200 bp");
    println!("  1y piece {}  3y floor at zero hazard {} bp", f6(b1[0]), bp(floor));
    println!("  3y piece needed {}  S(1) {}  S(3) {}", f6(neg[1]), f6(surv(1.0, &neg)), f6(surv(3.0, &neg)));
    println!("  1y 600 then 3y 300 bp fits: piece {}", f6(ok[1]));

    assert!((0..3).all(|i| (x[i] - lam[i]).abs() < 1e-9), "Newton on Simpson legs must find the bisection pieces");
    assert!((0..3).all(|i| (trip[i] - QUOTES[i]).abs() < 1e-10), "round trip through the other integrator");
    assert!(upper == [0.0, 0.0, 0.0], "a quote must not depend on later pieces");
    assert!((10000.0 * (mc2 - par(2.0, &lam))).abs() < 4.0 * se2, "simulation agrees with the formula at 2y");
    assert!((mcs5 - s5).abs() < 4.0 * (s5 * (1.0 - s5) / n as f64).sqrt(), "simulated survival");
    assert!(floor > bad[1] && neg[1] < 0.0 && ok[1] > 0.0, "200 bp sits below the floor; 300 bp does not");
    assert!((10000.0 * par(5.0, &[0.02]) - 121.06).abs() < 0.005, "shelf's flat-hazard Northwind CDS");
    assert!((10000.0 * par(2.0, &lam) - 180.1).abs() < 0.05, "card's 2y number");
    assert!((10000.0 * par(10.0, &lam) - 285.7).abs() < 0.05, "card's 10y number");
    println!("ALL CHECKS PASS");
}
