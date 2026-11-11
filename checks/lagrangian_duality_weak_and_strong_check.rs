// Lagrangian duality -- the same check as the Python, in Rust.  No crates.
// Two pumps must deliver 140 L/s at least cost.  The demand rule is priced at
// lam pounds an hour per L/s; each price gives a lower bound q(lam) on the cost.
const A: f64 = 0.30;                               // £ per kWh
const E: [f64; 2] = [2.0, 1.5];                    // L/s per kW
const B: [f64; 2] = [0.00625, 0.00375];            // £/h per kW^2
const D: f64 = 140.0;                              // demand, L/s
const LAM0: f64 = 0.35;                            // trial price
const STEP: f64 = 0.001;                           // ascent step

fn cost(p: &[f64]) -> f64 { (0..2).map(|i| A * p[i] + B[i] * p[i] * p[i]).sum() }
fn flow(p: &[f64]) -> f64 { (0..2).map(|i| E[i] * p[i]).sum() }
fn inner(lam: f64) -> Vec<f64> { (0..2).map(|i| f64::max(0.0, (lam * E[i] - A) / (2.0 * B[i]))).collect() }
fn q_at(lam: f64, d: f64) -> f64 { let p = inner(lam); cost(&p) + lam * (d - flow(&p)) }
fn q(lam: f64) -> f64 { q_at(lam, D) }

fn golden(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    let r = (5f64.sqrt() - 1.0) / 2.0;
    for _ in 0..200 {
        let (m1, m2) = (hi - r * (hi - lo), lo + r * (hi - lo));
        if f(m1) < f(m2) { hi = m2 } else { lo = m1 }
    }
    (lo + hi) / 2.0
}
fn primal(d: f64) -> (Vec<f64>, f64) {             // road 1: the plan itself, demand met exactly
    let pa = golden(&|x: f64| cost(&[x, (d - E[0] * x) / E[1]]), 0.0, d / E[0]);
    let p = vec![pa, (d - E[0] * pa) / E[1]];
    let c = cost(&p);
    (p, c)
}
fn bisect_price(d: f64) -> f64 {                   // road 2: the price at which the pumps meet demand
    let (mut lo, mut hi) = (0.0, 5.0);
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if flow(&inner(mid)) < d { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
fn ascent(mut lam: f64, step: f64, n: usize) -> Vec<(usize, f64, f64, f64)> {
    let mut out = Vec::new();
    for k in 0..=n {
        let short = D - flow(&inner(lam));
        out.push((k, lam, short, q(lam)));
        lam = f64::max(0.0, lam + step * short);
    }
    out
}
const CB: f64 = A * 70.0 + 0.00375 * 70.0 * 70.0;  // fixed-speed pump B: off, or 70 kW
fn q_fixed(lam: f64) -> f64 {
    let pa = f64::max(0.0, (lam * E[0] - A) / (2.0 * B[0]));
    lam * D + A * pa + B[0] * pa * pa - lam * E[0] * pa + f64::min(0.0, CB - lam * E[1] * 70.0)
}

fn main() {
    let (pstar_plan, pstar) = primal(D);
    let p0 = inner(LAM0);
    println!("trial price {:.2}: pumps at {:.2} and {:.2} kW, deliver {:.1} L/s, short {:.1}",
             LAM0, p0[0], p0[1], flow(&p0), D - flow(&p0));
    println!("trial plan costs {:.3} £/h; bound q = {:.3} + {:.2} x {:.1} = {:.3}",
             cost(&p0), cost(&p0), LAM0, D - flow(&p0), q(LAM0));
    println!("road 1, primal search: pumps at {:.4} and {:.4} kW, p* = {:.4} £/h", pstar_plan[0], pstar_plan[1], pstar);
    println!("pumps switch on at prices {:.2} and {:.2}; strictly feasible plan 50 and 50 kW: {:.1} L/s, {:.3} £/h",
             A / E[0], A / E[1], flow(&[50.0, 50.0]), cost(&[50.0, 50.0]));
    println!("gap at the trial price: {:.4} £/h = {:.2}%", pstar - q(LAM0), 100.0 * (pstar - q(LAM0)) / pstar);
    let slope_s = (flow(&inner(0.41)) - flow(&inner(0.39))) / 0.02;  // how fast delivery rises with price
    println!("shortfall falls {:.1} L/s per unit of price; error x {:.2} a step; steps above {:.6} diverge",
             slope_s, 1.0 - STEP * slope_s, 2.0 / slope_s);
    println!(" k   price   short L/s   bound q   gap %");
    for (k, lam, short, qq) in ascent(LAM0, STEP, 6) {
        println!("{:2}  {:.5}  {:9.4}  {:8.4}  {:.4}", k, lam, short, qq, 100.0 * (pstar - qq) / pstar);
    }
    let (mut run, mut k) = (LAM0, 0);
    while (D - flow(&inner(run))).abs() >= 0.01 { run += STEP * (D - flow(&inner(run))); k += 1; }
    println!("ascent from {:.2}, stop when |short| < 0.01 L/s: {} steps, price {:.5}", LAM0, k, run);
    let lstar = bisect_price(D);
    let dstar = q(lstar);
    let pl = inner(lstar);
    println!("road 2, price by bisection: lam* = {:.6}, plan {:.4} and {:.4} kW, d* = {:.4}", lstar, pl[0], pl[1], dstar);
    let sl: Vec<f64> = (0..2).map(|i| E[i] * E[i] / (2.0 * B[i])).collect(); // a running pump delivers sl * lam - ic L/s
    let ic: Vec<f64> = (0..2).map(|i| E[i] * A / (2.0 * B[i])).collect();
    let (num, den) = (D + ic.iter().sum::<f64>(), sl.iter().sum::<f64>());
    let lam_exact = num / den;
    println!("road 3, shortfall {:.0} - ({:.0} lam - {:.0}) - ({:.0} lam - {:.0}) = {:.0} - {:.0} lam = 0 at lam* = {:.6}",
             D, sl[0], ic[0], sl[1], ic[1], num, den, lam_exact);
    let stat = (0..2).map(|i| (A + 2.0 * B[i] * pstar_plan[i] - lstar * E[i]).abs()).fold(0.0, f64::max);
    println!("KKT, road-1 plan with lam*: stationarity residual {:.6}, lam* x shortfall {:.6}",
             stat, (lstar * (D - flow(&pstar_plan))).abs());
    let curv = (q(0.41) - 2.0 * q(0.40) + q(0.39)) / (0.01f64 * 0.01);
    println!("curvature of q near lam*: {:.1} (gap at 0.35 = {:.0} x 0.05^2 = {:.4})", curv, -curv / 2.0, -curv / 2.0 * 0.0025);
    let lams: Vec<f64> = (0..=100).map(|i| i as f64 / 100.0).collect();
    let mut feas = Vec::new();
    for i in 0..41 { for j in 0..41 {
        let p = [i as f64 * 2.0, j as f64 * 2.0];
        if flow(&p) >= D { feas.push(p); }
    } }
    let mut worst = f64::INFINITY;
    for p in &feas { for &l in &lams { worst = worst.min(cost(p) - q(l)); } }
    println!("weak duality: {} feasible plans x {} prices, smallest cost - q = {:.4}", feas.len(), lams.len(), worst);
    let mut mids = 0;
    for &x in &lams { for &y in &lams { if q((x + y) / 2.0) >= (q(x) + q(y)) / 2.0 - 1e-9 { mids += 1; } } }
    println!("concavity: midpoint test passed for {} of {} price pairs", mids, lams.len() * lams.len());
    let slope = (primal(141.0).1 - primal(139.0).1) / 2.0;
    println!("shadow price: (p*(141) - p*(139)) / 2 = {:.4} £/h per L/s", slope);
    let pr: Vec<String> = (0..9).map(|i| format!("{:6.2}", 0.20 + 0.05 * i as f64)).collect();
    let qs: Vec<String> = (0..9).map(|i| format!("{:.3}", q(0.20 + 0.05 * i as f64))).collect();
    println!("chart, price {}", pr.join(" "));
    println!("chart, q     {}", qs.join(" "));
    // ---- what breaks ----
    let fix_p = f64::min(cost(&[D / E[0], 0.0]), CB + cost(&[(D - E[1] * 70.0) / E[0], 0.0]));
    let mut fix_l = (f64::NEG_INFINITY, 0.0);
    for i in 0..=10000 { let l = i as f64 / 10000.0; let v = q_fixed(l); if v >= fix_l.0 { fix_l = (v, l); } }
    println!("break, fixed-speed pump: p* = {:.4}, best bound d* = {:.4} at {:.4}, gap {:.2}%",
             fix_p, fix_l.0, fix_l.1, 100.0 * (fix_p - fix_l.0) / fix_p);
    println!("break, fixed-speed best plan: pump 1 at {:.2} kW, pump 2 at 70 kW ({:.1} L/s), priced cost of pump 2 at {:.4}: {:.4}",
             (D - E[1] * 70.0) / E[0], E[1] * 70.0, fix_l.1, CB - fix_l.1 * E[1] * 70.0);
    let big = ascent(LAM0, 0.004, 6);
    let bp: Vec<String> = big.iter().map(|t| format!("{:.3}", t.1)).collect();
    println!("break, step 0.004, prices: {}", bp.join(" "));
    println!("break, step 0.004, gap after 6 steps: {:.2}%", 100.0 * (pstar - big[6].3) / pstar);
    println!("break, trial plan read as the answer: {:.3} £/h, {:.1} of {:.0} L/s", cost(&p0), flow(&p0), D);
    println!("break, demand term left out: q = {:.3}", cost(&p0) - LAM0 * flow(&p0));
    // ---- try changing ----
    let p160 = primal(160.0);
    println!("try, demand 160: lam* = {:.4}, p* = {:.4}, pumps {:.2} and {:.2}", bisect_price(160.0), p160.1, p160.0[0], p160.0[1]);
    println!("try, trial price 0.45: q = {:.4}; step 1/620 from 0.35: {:.6}", q(0.45), ascent(LAM0, 1.0 / 620.0, 1)[1].1);
    assert!((pstar - 40.0).abs() < 1e-6 && (dstar - pstar).abs() < 1e-6);      // strong duality, two roads
    assert!((lstar - lam_exact).abs() < 1e-9 && (slope - lstar).abs() < 1e-6); // price three ways
    assert!(((pstar - q(LAM0)) / pstar - 0.019375).abs() < 1e-9);             // the 2 percent at the trial price
    assert!(worst >= -1e-9 && mids == lams.len() * lams.len());               // weak duality and concavity
    assert!(fix_p - fix_l.0 > 1.0 && stat < 1e-6);                            // nonconvex: the gap stays open
    println!("ALL CHECKS PASS");
}
