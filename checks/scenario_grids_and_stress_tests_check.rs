// Stress tests on the Acme options book: grid, replays, reverse stress.
// Standard library only, no crates. The normal CDF, the integrator and the
// searches are written out here; nothing used already knows the answer.
use std::f64::consts::PI;

const R: f64 = 0.05; const Q: f64 = 0.02; const S0: f64 = 100.0; const VOL0: f64 = 0.20; // the house market
const MV: f64 = 4.0; const RHO: f64 = -0.7; const LIMIT: f64 = -3.0e6; // reverse stress inputs
type Pricer = fn(f64, f64, f64, f64) -> f64;
type Book = [(f64, f64, f64)];

fn n_cdf(x: f64) -> f64 { // bell-curve area left of x, by Marsaglia's series
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() {
        k += 2.0; term *= x * x / k; total += term;
    }
    0.5 + total * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}

fn put(s: f64, k: f64, vol: f64, t: f64) -> f64 { // road 1: Black-Scholes put formula
    let d1 = ((s / k).ln() + (R - Q + 0.5 * vol * vol) * t) / (vol * t.sqrt());
    let d2 = d1 - vol * t.sqrt();
    k * (-R * t).exp() * n_cdf(-d2) - s * (-Q * t).exp() * n_cdf(-d1)
}

fn put_simpson(s: f64, k: f64, vol: f64, t: f64) -> f64 { // road 2: average the payoff over the bell curve
    let (drift, w, n) = ((R - Q - 0.5 * vol * vol) * t, vol * t.sqrt(), 4000);
    let zk = ((k / s).ln() - drift) / w;
    let (a, h) = (-12.0, (zk + 12.0) / n as f64);
    let f = |z: f64| (k - s * (drift + w * z).exp()) * (-0.5 * z * z).exp() / (2.0 * PI).sqrt();
    let mut tot = f(a) + f(zk);
    for i in 1..n { tot += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    (-R * t).exp() * tot * h / 3.0
}

fn greeks(s: f64, k: f64, vol: f64, t: f64) -> [f64; 3] { // delta, gamma, vega per vol point
    let d1 = ((s / k).ln() + (R - Q + 0.5 * vol * vol) * t) / (vol * t.sqrt());
    let pdf = (-0.5 * d1 * d1).exp() / (2.0 * PI).sqrt();
    [-(-Q * t).exp() * n_cdf(-d1), (-Q * t).exp() * pdf / (s * vol * t.sqrt()),
     s * (-Q * t).exp() * pdf * t.sqrt() / 100.0]
}

fn hedge(opts: &Book) -> f64 {
    -opts.iter().map(|&(n, k, t)| n * greeks(S0, k, VOL0, t)[0]).sum::<f64>().round()
}

fn value(s: f64, vol: f64, opts: &Book, pricer: Pricer, sh: f64) -> f64 {
    opts.iter().map(|&(n, k, t)| n * pricer(s, k, vol, t)).sum::<f64>() + sh * s
}

// s: spot move in percent, v: vol move in points
fn loss_with(s: f64, v: f64, opts: &Book, pricer: Pricer, sh: f64) -> f64 {
    value(S0 * (1.0 + s / 100.0), VOL0 + v / 100.0, opts, pricer, sh) - value(S0, VOL0, opts, pricer, sh)
}

const OPTS: [(f64, f64, f64); 2] = [(-380000.0, 90.0, 1.0), (140000.0, 100.0, 0.25)];
fn loss(s: f64, v: f64) -> f64 { loss_with(s, v, &OPTS, put, hedge(&OPTS)) }

fn ms() -> f64 { 20.0 / 12f64.sqrt() }
fn dist(s: f64, v: f64, rho: f64) -> f64 { // how many typical months away (s, v) lies
    let (zs, zv) = (s / ms(), v / MV);
    ((zs * zs - 2.0 * rho * zs * zv + zv * zv) / (1.0 - rho * rho)).sqrt()
}

fn rays(rho: f64, limit: f64) -> (f64, f64, f64) { // reverse road 1: walk out along 720 rays, bisect
    let mut best = (99.0, 0.0, 0.0);
    for k in 0..720 {
        let th = 2.0 * PI * k as f64 / 720.0;
        let pt = |d: f64| (ms() * d * th.cos(), MV * (rho * d * th.cos() + (1.0 - rho * rho).sqrt() * d * th.sin()));
        let (mut lo, mut d) = (0.0, 0.1);
        while d < best.0 {
            let (s, v) = pt(d);
            if s <= -99.0 || v <= -19.0 { d = 99.0; break; }
            if loss(s, v) <= limit { break; }
            lo = d; d += 0.1;
        }
        if d >= best.0 { continue; }
        for _ in 0..40 {
            let mid = 0.5 * (lo + d);
            let (s, v) = pt(mid);
            if loss(s, v) <= limit { d = mid; } else { lo = mid; }
        }
        let (s, v) = pt(d);
        best = (d, s, v);
    }
    best
}

fn brute() -> (f64, f64, f64) { // reverse road 2: every point on a 0.25 grid
    let mut best = (99.0, 0.0, 0.0);
    for i in 0..241 {
        for j in 0..241 {
            let (s, v) = (-60.0 + 0.25 * i as f64, -15.0 + 0.25 * j as f64);
            let dd = dist(s, v, RHO);
            if dd < best.0 && loss(s, v) <= LIMIT { best = (dd, s, v); }
        }
    }
    best
}

fn main() {
    let shares = hedge(&OPTS);
    let mut g = [0.0; 3];
    for &(n, k, t) in OPTS.iter() { for j in 0..3 { g[j] += n * greeks(S0, k, VOL0, t)[j]; } }
    g[0] += shares;
    let taylor = |s: f64, v: f64| { let ds = S0 * s / 100.0; g[0] * ds + 0.5 * g[1] * ds * ds + g[2] * v };
    let m = |x: f64| format!("{:8.2}", x / 1e6);
    println!("house put, formula        {:.12}", put(100.0, 100.0, 0.2, 1.0));
    println!("book: {:.0} x 1y $90 put at {:.4}   {:.0} x 3m $100 put at {:.4}   shares {:.0}",
             OPTS[0].0, put(S0, 90.0, VOL0, 1.0), OPTS[1].0, put(S0, 100.0, VOL0, 0.25), shares);
    println!("book delta {:.1}   gamma {:.1}   vega per point {:.0}", g[0], g[1], g[2]);
    let (spots, vols) = ([-30, -20, -10, 0, 10, 20], [-5, 0, 5, 10, 15]);
    println!("grid, $ million, vol points across{}", vols.iter().map(|v| format!("{:>+8}", v)).collect::<String>());
    for &s in spots.iter() {
        println!("  spot move {:+4}%{}{}", s, " ".repeat(14), vols.iter().map(|&v| m(loss(s as f64, v as f64))).collect::<String>());
    }
    let (l1, l2) = (loss(-20.0, 15.0), loss_with(-20.0, 15.0, &OPTS, put_simpson, shares));
    println!("headline -20%, +15 vol: formula {:.2}   Simpson {:.2}", l1, l2);
    let (p1, p2) = (put(80.0, 90.0, 0.35, 1.0), put(80.0, 100.0, 0.35, 0.25));
    println!("stressed at $80, 35%: 1y $90 put {:.4}   3m $100 put {:.4}", p1, p2);
    println!("by position: 1y puts {:.2}   3m puts {:.2}   shares {:.2}", OPTS[0].0 * (p1 - put(S0, 90.0, VOL0, 1.0)),
             OPTS[1].0 * (p2 - put(S0, 100.0, VOL0, 0.25)), shares * -20.0);
    println!("book vega per point at $80, 20%: {:.0}", OPTS.iter().map(|&(n, k, t)| n * greeks(80.0, k, VOL0, t)[2]).sum::<f64>());
    let (a, b) = (loss(-20.0, 0.0), loss(0.0, 15.0));
    println!("spot alone {:.2}   vol alone {:.2}   sum {:.2}   joint minus sum {:.2}", a, b, a + b, l1 - a - b);
    println!("Greeks estimate at -20%, +15 vol {:.2}   wrong: vol +15% of 20 (to 23%) {:.2}", taylor(-20.0, 15.0), loss(-20.0, 3.0));
    println!("tiny move -0.05%, +0.01 vol: full {:.4}   Greeks {:.4}", loss(-0.05, 0.01), taylor(-0.05, 0.01));
    let replays = [("2008", 2261.270, 1649.510, 25.66, 69.95), ("2020", 9817.180, 6860.670, 14.38, 61.59)];
    let mut rl = Vec::new();
    for &(name, n0, n1, x0, x1) in replays.iter() { // Nasdaq for spot, VIX change for vol points
        let (s, v): (f64, f64) = (100.0 * (n1 / n0 - 1.0), x1 - x0);
        println!("replay {} inputs: Nasdaq {:.2} -> {:.2}   VIX {:.2} -> {:.2}   book vol to {:.2}%", name, n0, n1, x0, x1, 20.0 + v);
        println!("replay {}: spot {:.4}%  vol {:+.2} pts  formula {:.2}  Simpson {:.2}  Greeks {:.2}",
                 name, s, v, loss(s, v), loss_with(s, v, &OPTS, put_simpson, shares), taylor(s, v));
        rl.push(loss(s, v));
        let dd = dist(s, v, RHO);
        println!("replay {} distance {:.3}   log10 of chance bound {:.2}", name, dd, -dd * dd / (2.0 * 10f64.ln()));
    }
    let (r1, r2) = (rays(RHO, LIMIT), brute());
    println!("reverse inputs: limit {:.0}   typical month: spot {:.4}%  vol {:.2} pts  correlation {:.2}", LIMIT, ms(), MV, RHO);
    println!("reverse, rays:  distance {:.3}  spot {:+.2}%  vol {:+.2} pts  loss {:.0}", r1.0, r1.1, r1.2, loss(r1.1, r1.2));
    println!("reverse, grid:  distance {:.3}  spot {:+.2}%  vol {:+.2} pts  loss {:.0}", r2.0, r2.1, r2.2, loss(r2.1, r2.2));
    println!("reverse, check: distance of ray point by formula {:.3}", dist(r1.1, r1.2, RHO));
    println!("chance bound exp(-d^2/2) per million months {:.2}   one month in {:.0}", 1e6 * (-0.5 * r1.0 * r1.0).exp(), (0.5 * r1.0 * r1.0).exp());
    let dh = dist(-20.0, 15.0, RHO);
    println!("distance of -20%, +15 vol {:.3}   one month in {:.0}", dh, (0.5 * dh * dh).exp());
    println!("bars, $ million: Greeks {:.2}  one at a time {:.2}  full {:.2}  2008 {:.2}  2020 {:.2}",
             -taylor(-20.0, 15.0) / 1e6, -(a + b) / 1e6, -l1 / 1e6, -rl[0] / 1e6, -rl[1] / 1e6);
    println!("chart, spot move       {}", spots.iter().map(|s| format!("{:8}", s)).collect::<String>());
    println!("chart, full, vol +0    {}", spots.iter().map(|&s| m(loss(s as f64, 0.0))).collect::<String>());
    println!("chart, full, vol +15   {}", spots.iter().map(|&s| m(loss(s as f64, 15.0))).collect::<String>());
    println!("chart, Greeks, vol +15 {}", spots.iter().map(|&s| m(taylor(s as f64, 15.0))).collect::<String>());
    let (t1, t3, one) = (rays(0.0, LIMIT), rays(RHO, -2.0e6), [OPTS[0]]);
    let t2 = loss_with(-20.0, 15.0, &one, put, hedge(&one));
    println!("try: correlation 0 -> distance {:.3}  spot {:+.2}%  vol {:+.2} pts", t1.0, t1.1, t1.2);
    println!("try: no 3m puts, shares re-hedged {:.0} -> headline {:.2}", hedge(&one), t2);
    println!("try: limit $2m -> distance {:.3}  spot {:+.2}%  vol {:+.2} pts", t3.0, t3.1, t3.2);

    assert!((put(100.0, 100.0, 0.2, 1.0) - 6.330080627550).abs() < 1e-9, "house put");
    assert!((l1 - l2).abs() < 1.0 && (l1 / 1e5).round() == -21.0, "two revaluations agree; the headline loses 2.1 million");
    assert!((loss(-0.05, 0.01) - taylor(-0.05, 0.01)).abs() < 0.01 * loss(-0.05, 0.01).abs(), "Greeks right for tiny moves");
    let fd = |f: &dyn Fn(f64, f64) -> f64, h: f64| [(f(h, 0.0) - f(-h, 0.0)) / (2.0 * h),
        (f(h, 0.0) + f(-h, 0.0) - 2.0 * f(0.0, 0.0)) / (h * h), (f(0.0, h) - f(0.0, -h)) / (2.0 * h)];
    let (fl, ft) = (fd(&loss, 0.01), fd(&taylor, 0.01));
    assert!((0..3).all(|j| (fl[j] - ft[j]).abs() < 0.01 * ft[j].abs().max(1.0)), "Greeks match slopes of the repricing");
    assert!((r1.0 - r2.0).abs() < 0.05, "ray search and grid search find the same nearest scenario");
    assert!(loss(r1.1, r1.2) <= LIMIT && LIMIT < loss(r1.1 * 0.999, r1.2 * 0.999), "the reverse scenario sits on the edge");
    println!("ALL CHECKS PASS");
}
