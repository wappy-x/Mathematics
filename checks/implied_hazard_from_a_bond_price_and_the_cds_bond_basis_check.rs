// Implied hazard from a bond price, and the CDS-bond basis -- the check behind the card.
// Rust std only; nothing imported knows the answer.  Northwind: five-year bond, coupon
// 6 a year on 100 face, 40% of face recovered at the moment of default, coupons stop at
// default, riskless rate 5% flat and continuous.  CDS: quarterly premiums, no accrual.
const F: f64 = 100.0;
const C: f64 = 6.0;
const R: f64 = 0.40;
const RATE: f64 = 0.05;
const T: f64 = 5.0;
const HOUSE: f64 = 98.28;
const QUOTE: f64 = 97.00;

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn bond_sum(lam: f64) -> f64 { // road 1: legs term by term, recovery leg by Simpson
    let mut v = F * (-(RATE + lam) * T).exp();
    for t in 1..=5 {
        let t = t as f64;
        v += C * (-(RATE + lam) * t).exp();
        v += simpson(&|s: f64| R * F * lam * (-(RATE + lam) * s).exp(), t - 1.0, t, 40);
    }
    v
}
fn bond(lam: f64, c: f64, rec: f64, rr: f64) -> f64 { // road 2: the closed form on the card
    let u = rr + lam;
    let cp: f64 = (1..=5).map(|t| c * (-u * t as f64).exp()).sum();
    cp + F * (-u * T).exp() + rec * F * lam / u * (1.0 - (-u * T).exp())
}
fn b(lam: f64) -> f64 { bond(lam, C, R, RATE) }
fn bond_slope(lam: f64) -> f64 { // its derivative, worked out by hand
    let u = RATE + lam;
    let s: f64 = (1..=5).map(|t| C * t as f64 * (-u * t as f64).exp()).sum();
    -s - F * T * (-u * T).exp() + R * F * (RATE / (u * u) * (1.0 - (-u * T).exp()) + lam / u * T * (-u * T).exp())
}
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // needs f(lo) > 0 > f(hi)
    for _ in 0..60 {
        let mid = 0.5 * (lo + hi);
        if f(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn cash_price(z: f64, c: f64) -> f64 {
    let cp: f64 = (1..=5).map(|t| c * (-(RATE + z) * t as f64).exp()).sum();
    cp + F * (-(RATE + z) * T).exp()
}
fn zspread(p: f64, c: f64) -> f64 { bisect(&|z| cash_price(z, c) - p, -0.05, 1.0) }
fn z_newton(p: f64) -> f64 { // road B for z: Newton on the continuous yield, then y - r
    let mut y = 0.05;
    for _ in 0..30 {
        let v: f64 = (1..=5).map(|t| C * (-y * t as f64).exp()).sum::<f64>() + F * (-y * T).exp();
        let d: f64 = -(1..=5).map(|t| C * t as f64 * (-y * t as f64).exp()).sum::<f64>() - F * T * (-y * T).exp();
        y -= (v - p) / d;
    }
    y - RATE
}
fn cds_par(lam: f64) -> (f64, f64) { // CDS legs term by term (not the closed form)
    let ann: f64 = (1..=20).map(|j| 0.25 * (-(RATE + lam) * 0.25 * j as f64).exp()).sum();
    (simpson(&|s: f64| (1.0 - R) * lam * (-(RATE + lam) * s).exp(), 0.0, 5.0, 400) / ann, ann)
}
fn cds_closed(lam: f64) -> f64 {
    let x = (RATE + lam) * 0.25;
    (1.0 - R) * lam * (x.exp() - 1.0) / x
}
fn row(label: &str, v: f64, d: usize) { println!("{:<42} {:.*}", label, d, v); }
fn package(tau: f64, s_cds: f64) -> f64 { // basis trade worth today if default comes at tau (99: never)
    let cpn: f64 = (1..=5).filter(|&t| (t as f64) < tau).map(|t| C * (-RATE * t as f64).exp()).sum();
    let prem: f64 = (1..=20).filter(|&j| 0.25 * (j as f64) < tau)
        .map(|j| s_cds * F * 0.25 * (-RATE * 0.25 * j as f64).exp()).sum();
    cpn - prem + F * (-RATE * tau.min(T)).exp() - QUOTE
}

fn main() {
    let s_cds = cds_closed(0.02);
    let lam_house = bisect(&|l| bond_sum(l) - HOUSE, 0.0, 1.85);
    let lam_bond = bisect(&|l| bond_sum(l) - QUOTE, 0.0, 1.85);
    let mut path = vec![0.0f64];
    for _ in 0..6 { let l = *path.last().unwrap(); path.push(l - (b(l) - QUOTE) / bond_slope(l)); }
    let lam_cds = bisect(&|l| s_cds - cds_par(l).0, 0.0, 1.0);
    let (z_house, z_bond) = (zspread(HOUSE, C), zspread(QUOTE, C));
    row("risk-free price, hazard 0", b(0.0), 4);
    row("house price at 2%, closed form", b(0.02), 4);
    row("house price at 2%, legs by Simpson", bond_sum(0.02), 4);
    row("slope of price at 2%, per unit hazard", bond_slope(0.02), 4);
    let cp: f64 = (1..=5).map(|t| C * (-0.07 * t as f64).exp()).sum();
    println!("house legs at 2%: coupons {:.4}  face {:.4}  recovery {:.4}", cp, F * (-0.35f64).exp(), R * F * 0.02 / 0.07 * (1.0 - (-0.35f64).exp()));
    row("hand estimate from 2% with the slope (%)", 100.0 * (0.02 - (b(0.02) - QUOTE) / bond_slope(0.02)), 4);
    row("hazard from 98.28, bisection (%)", 100.0 * lam_house, 4);
    row("hazard from 97, road 1 bisection (%)", 100.0 * lam_bond, 4);
    row("hazard from 97, road 2 Newton (%)", 100.0 * path[6], 4);
    let np: Vec<String> = path[..5].iter().map(|x| format!("{:.4}", 100.0 * x)).collect();
    println!("Newton path from 0 (%)  {}", np.join(" "));
    row("CDS quote at 2%, closed form (bp)", 1e4 * s_cds, 4);
    row("CDS par at 2%, legs term by term (bp)", 1e4 * cds_par(0.02).0, 4);
    row("CDS risky annuity at 2%", cds_par(0.02).1, 4);
    row("hazard from the CDS quote (%)", 100.0 * lam_cds, 4);
    row("z-spread at 98.28 (bp)", 1e4 * z_house, 4);
    row("z-spread at 97, bisection (bp)", 1e4 * z_bond, 4);
    row("z-spread at 97, yield Newton (bp)", 1e4 * z_newton(QUOTE), 4);
    row("basis at 98.28, CDS - z (bp)", 1e4 * (s_cds - z_house), 4);
    row("basis at 97, CDS - z (bp)", 1e4 * (s_cds - z_bond), 4);
    row("hazard gap x (1-R) at 97 (bp)", 1e4 * (1.0 - R) * (lam_cds - lam_bond), 4);
    row("funding spread that prices 97 at 2% (bp)", 1e4 * bisect(&|f| bond(0.02, C, R, RATE + f) - QUOTE, 0.0, 0.05), 4);
    let mut exp_pkg = (-0.02 * T).exp() * package(99.0, s_cds);
    for k in 1..=40 {
        let (a, bb) = ((k - 1) as f64 / 8.0 + 1e-12, k as f64 / 8.0 - 1e-12);
        exp_pkg += simpson(&|s: f64| 0.02 * (-0.02 * s).exp() * package(s, s_cds), a, bb, 8);
    }
    for (label, tau) in [("immediately", 1e-9), ("at 0.999 years", 0.999), ("at 1.001 years", 1.001),
                         ("at 4.999 years", 4.999), ("never", 99.0)] {
        row(&format!("package value, default {}", label), package(tau, s_cds), 4);
    }
    row("package, expected at 2%, by default time", exp_pkg, 4);
    row("package, expected at 2%, B(2%) - 97", b(0.02) - QUOTE, 4);
    // road 3: simulate default times at the implied hazard, reprice the bond
    let mut seed: u64 = 20260928;
    let (n, mut tot, mut tot2) = (200000usize, 0.0f64, 0.0f64);
    for _ in 0..n {
        seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        let u = ((seed >> 11) as f64 + 0.5) / 9007199254740992.0;
        let tau = -u.ln() / lam_bond;
        let cp: f64 = (1..=5).filter(|&t| (t as f64) < tau).map(|t| C * (-RATE * t as f64).exp()).sum();
        let v = cp + if tau < T { R * F * (-RATE * tau).exp() } else { F * (-RATE * T).exp() };
        tot += v;
        tot2 += v * v;
    }
    let mc = tot / n as f64;
    let se = ((tot2 / n as f64 - mc * mc) / n as f64).sqrt();
    row("road 3 simulated price at that hazard", mc, 3);
    row("  its standard error", se, 3);
    // uniqueness: strictly falling while the coupon beats R F r g(u); never back above later
    let lam_g = bisect(&|l| 3.0 - ((RATE + l).exp() - 1.0) / (RATE + l), 0.0, 5.0);
    let falls = (0..4000).all(|k| b(lam_g * (k + 1) as f64 / 4000.0) < b(lam_g * k as f64 / 4000.0));
    let tail = (1..=10000).map(|k| b(lam_g + 0.01 * k as f64)).fold(f64::MIN, f64::max);
    let (mut low, mut at) = (f64::MAX, 0);
    for k in 1..=2000 { let v = b(0.01 * k as f64); if v < low { low = v; at = k; } }
    row("proof reaches hazard (%)", 100.0 * lam_g, 2);
    row("price there", b(lam_g), 4);
    row("highest price beyond it, to 10,000%", tail, 4);
    println!("{:<42} {:.4} at {}", "lowest price anywhere, and its hazard (%)", low, at);
    let line = |lab: &str, v: Vec<String>| println!("{:<22} {}", lab, v.join(" "));
    line("chart, hazard (%)", (0..=10).map(|k| format!("{:7}", k)).collect());
    line("chart, bond price", (0..=10).map(|k| format!("{:7.2}", b(k as f64 / 100.0))).collect());
    line("chart, quoted price", (94..=100).map(|p| format!("{:7}", p)).collect());
    line("chart, basis (bp)", (94..=100).map(|p| format!("{:7.2}", 1e4 * (s_cds - zspread(p as f64, C)))).collect());
    for cc in [2.0, 4.0, 6.0, 8.0, 10.0] { // same 2% hazard, different coupons
        let zc = zspread(bond(0.02, cc, R, RATE), cc);
        println!("coupon {:4.1}: price {:7.2}  z {:7.2} bp  basis {:6.2} bp", cc, bond(0.02, cc, R, RATE), 1e4 * zc, 1e4 * (s_cds - zc));
    }
    row("wrong: recovery 0, hazard from 97 (%)", 100.0 * bisect(&|l| bond(l, C, 0.0, RATE) - QUOTE, 0.0, 1.0), 4);
    row("wrong: hazard gap without (1-R) (bp)", 1e4 * (lam_cds - lam_bond), 4);
    row("try: recovery 25%, hazard from 97 (%)", 100.0 * bisect(&|l| bond(l, C, 0.25, RATE) - QUOTE, 0.0, 1.0), 4);
    row("try: price 96, hazard (%)", 100.0 * bisect(&|l| b(l) - 96.0, 0.0, 1.0), 4);
    row("try: price 96, basis (bp)", 1e4 * (s_cds - zspread(96.0, C)), 4);

    assert!((lam_house - 0.02).abs() < 1e-4, "98.28 must solve back to 2%");
    assert!((lam_bond - path[6]).abs() < 1e-10, "bisection on Simpson legs vs Newton on the closed form");
    assert!((z_bond - z_newton(QUOTE)).abs() < 1e-12, "z-spread two ways");
    assert!((cds_par(0.02).0 - s_cds).abs() < 1e-9, "CDS legs term by term vs closed form");
    assert!((mc - QUOTE).abs() < 4.0 * se, "simulated price at the implied hazard must be 97");
    assert!((exp_pkg - (b(0.02) - QUOTE)).abs() < 1e-6, "basis trade value two ways");
    assert!(falls, "price must fall strictly up to the proof's reach");
    assert!(tail < b(lam_g), "beyond it the price never climbs back");
    println!("ALL CHECKS PASS");
}
