// CDS risk numbers -- the check behind the card.  Rust std only, no crates.
// Northwind: $10m of five-year protection bought at par, quarterly premiums,
// hazard 2% flat, recovery 40%, riskless rate 5%.  Each risk number is found
// twice: move the market and revalue, and differentiate the leg formulas.
const N: f64 = 10_000_000.0; const T: f64 = 5.0; const DT: f64 = 0.25;
const LAM: f64 = 0.02; const R: f64 = 0.40; const RATE: f64 = 0.05; const BP: f64 = 1e-4;
const FAR: f64 = 1e9; // "for ever": the last knot of every curve

type Curve = Vec<(f64, f64)>; // (end year, hazard)

fn flat(h: f64) -> Curve { vec![(FAR, h)] }

fn surv(curve: &Curve, t: f64) -> f64 {
    let (mut area, mut a) = (0.0, 0.0);
    for &(b, h) in curve {
        area += h * (t.min(b) - a);
        if t <= b { break; }
        a = b;
    }
    (-area).exp()
}

fn annuity(curve: &Curve, mat: f64, r: f64) -> f64 {
    let n = (mat / DT).round() as usize;
    (0..n).map(|j| DT * (j + 1) as f64).fold(0.0, |acc, t| acc + DT * (-r * t).exp() * surv(curve, t))
}

fn protection(curve: &Curve, mat: f64, r: f64, rec: f64) -> f64 {
    let (mut total, mut a) = (0.0, 0.0); // road 1 for P: closed form, knot to knot
    for &(b, h) in curve {
        let (e, k) = (b.min(mat), r + h);
        total += (1.0 - rec) * h / k * (-r * a).exp() * surv(curve, a) * (1.0 - (-k * (e - a)).exp());
        if b >= mat { break; }
        a = b;
    }
    total
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let step = (b - a) / n as f64;
    let inner: f64 = (1..n).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * step)).sum();
    step / 3.0 * (f(a) + f(b) + inner)
}

fn protection_simpson(curve: &Curve, mat: f64, r: f64, rec: f64) -> f64 {
    let (mut total, mut a) = (0.0, 0.0); // road 2 for P: integrate the default density
    for &(b, h) in curve {
        let e = b.min(mat);
        total += (1.0 - rec) * simpson(|t| h * (-r * t).exp() * surv(curve, t), a, e, 400);
        if b >= mat { break; }
        a = b;
    }
    total
}

type Leg = fn(&Curve, f64, f64, f64) -> f64;

fn value(curve: &Curve, mat: f64, r: f64, rec: f64, s0: f64, prot: Leg) -> f64 {
    N * (prot(curve, mat, r, rec) - s0 * annuity(curve, mat, r))
}

fn val(curve: &Curve, mat: f64, r: f64, rec: f64, s0: f64) -> f64 { value(curve, mat, r, rec, s0, protection) }

fn par(curve: &Curve, mat: f64, r: f64, rec: f64) -> f64 {
    protection(curve, mat, r, rec) / annuity(curve, mat, r)
}

fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi);
        if f(lo) * f(mid) > 0.0 { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

fn implied(s: f64, r: f64, rec: f64, mat: f64) -> f64 { // the flat hazard that reprices a quote
    bisect(|h| par(&flat(h), mat, r, rec) - s, 1e-9, 3.0)
}

fn bumped(s_mkt: f64, s0: f64) -> (f64, f64, f64, f64) {
    let v = |s: f64, r: f64, rec: f64| val(&flat(implied(s, r, rec, T)), T, r, rec, s0);
    (v(s_mkt + BP, RATE, R) - v(s_mkt, RATE, R),
     (v(s_mkt + BP, RATE, R) - v(s_mkt - BP, RATE, R)) / 2.0,
     (v(s_mkt, RATE + BP, R) - v(s_mkt, RATE - BP, R)) / 2.0,
     (v(s_mkt, RATE, R + 0.01) - v(s_mkt, RATE, R - 0.01)) / 2.0)
}

fn analytic(lam: f64, s0: f64, r: f64, rec: f64) -> (f64, f64, f64, f64) {
    let k = r + lam;
    let ts: Vec<f64> = (0..(T / DT).round() as usize).map(|j| DT * (j + 1) as f64).collect();
    let a = ts.iter().fold(0.0, |acc, t| acc + DT * (-k * t).exp());
    let a_k = -ts.iter().fold(0.0, |acc, t| acc + DT * t * (-k * t).exp()); // dA/dlambda = dA/dr
    let g = (1.0 - (-k * T).exp()) / k;
    let g_k = T * (-k * T).exp() / k - g / k;
    let (p, p_lam, p_r) = ((1.0 - rec) * lam * g, (1.0 - rec) * (g + lam * g_k), (1.0 - rec) * lam * g_k);
    let s_lam = (p_lam * a - p * a_k) / a.powi(2);
    let (s_r, s_rec) = ((p_r * a - p * a_k) / a.powi(2), -p / a / (1.0 - rec));
    let v_lam = N * (p_lam - s0 * a_k);
    (v_lam / s_lam * BP, (N * (p_r - s0 * a_k) - v_lam * s_r / s_lam) * BP,
     (-N * p / (1.0 - rec) - v_lam * s_rec / s_lam) * 0.01, N * a * BP)
}

fn main() {
    let (a0, p0) = (annuity(&flat(LAM), T, RATE), protection(&flat(LAM), T, RATE, R));
    let s0 = p0 / a0; // the contract spread, fixed from today on
    let (cs_up, cs_c, ir_c, rec_c) = bumped(s0, s0);
    let (cs_a, ir_a, rec_a, cs_na) = analytic(LAM, s0, RATE, R);
    let v_dead = val(&flat(1e7), T, RATE, R, s0); // hazard so large that default is immediate
    let lam200 = implied(0.02, RATE, R, T);
    let v200 = val(&flat(lam200), T, RATE, R, s0);
    let (_, w_c, w_ir, w_rec) = bumped(0.02, s0);
    let (w_cs_a, w_ir_a, w_rec_a, _) = analytic(lam200, s0, RATE, R);
    let lam1 = implied(0.01, RATE, R, 4.0); // rising curve: 4y quotes 100 bp, 5y at s0
    let lam2 = bisect(|h| par(&vec![(4.0, lam1), (FAR, h)], T, RATE, R) - s0, 1e-9, 3.0);
    let rise: Curve = vec![(4.0, lam1), (FAR, lam2)];
    let fl = flat(LAM);
    let roll = val(&rise, 4.75, RATE, R, s0);
    let roll_simp = value(&rise, 4.75, RATE, R, s0, protection_simpson);
    let rows: Vec<(&str, f64, usize)> = vec![
        ("risky annuity A", a0, 6), ("protection leg P per $1", p0, 6), ("contract spread s0, bp", s0 / BP, 4),
        ("CS01 bump +1bp", cs_up, 2), ("CS01 bump +-1bp", cs_c, 2), ("CS01 derivative", cs_a, 2),
        ("  N x A x 1bp", cs_na, 2), ("IR01 bump +-1bp", ir_c, 2), ("IR01 derivative", ir_a, 2),
        ("Rec01 bump +-1pt", rec_c, 2), ("Rec01 derivative", rec_a, 2),
        ("JTD (1-R)N - V", N * (1.0 - R) - val(&fl, T, RATE, R, s0), 2), ("JTD hazard 1e7", v_dead, 2),
        ("JTD per recovery point", -N * 0.01, 2),
        ("widened: hazard at 200 bp", lam200, 6), ("widened: value V", v200, 2),
        ("widened: value, Simpson", value(&flat(lam200), T, RATE, R, s0, protection_simpson), 2),
        ("widened: CS01 bump +-1bp", w_c, 2), ("widened: CS01 derivative", w_cs_a, 2),
        ("widened: IR01 bump +-1bp", w_ir, 2), ("widened: IR01 derivative", w_ir_a, 2),
        ("widened: Rec01 bump +-1pt", w_rec, 2), ("widened: Rec01 derivative", w_rec_a, 2),
        ("widened: JTD", N * (1.0 - R) - v200, 2), ("widened: JTD hazard 1e7", v_dead - v200, 2),
        ("carry paid per quarter", s0 * N * DT, 2), ("expected payout, first quarter", N * (1.0 - R) * (1.0 - surv(&fl, DT)), 2),
        ("flat: par spread 4.75y, bp", par(&fl, 4.75, RATE, R) / BP, 4),
        ("flat: roll-down", val(&fl, 4.75, RATE, R, s0), 2),
        ("rising: hazard to 4y", lam1, 6), ("rising: hazard 4y to 5y", lam2, 6),
        ("rising: par spread 4.75y, bp", par(&rise, 4.75, RATE, R) / BP, 4),
        ("rising: roll-down", roll, 2), ("rising: roll-down, Simpson", roll_simp, 2),
        ("wrong: Rec01 hazard held", val(&fl, T, RATE, R + 0.01, s0) - val(&fl, T, RATE, R, s0), 2),
        ("wrong: IR01 hazard held", val(&fl, T, RATE + BP, R, s0) - val(&fl, T, RATE, R, s0), 2),
        ("wrong: CS01, riskless annuity", N * BP * annuity(&flat(0.0), T, RATE), 2),
        ("wrong: V at 200 bp from CS01", cs_a * (0.02 - s0) / BP, 2),
    ];
    for (name, v, d) in &rows {
        let shown = if v.abs() >= 0.5 * 10f64.powi(-(*d as i32)) { *v } else { 0.0 };
        println!("{:<32}{:>18.*}", name, *d, shown);
    }
    println!();
    let spreads = [40i32, 80, 120, 160, 200, 240, 280, 320];
    let row = |f: &dyn Fn(i32) -> String| spreads.iter().map(|&s| f(s)).collect::<String>();
    println!("chart, 5y spread bp  {}", row(&|s| format!("{:>9}", s)));
    println!("chart, value $k      {}", row(&|s| format!("{:>9.2}",
        val(&flat(implied(s as f64 * BP, RATE, R, T)), T, RATE, R, s0) / 1e3)));
    println!("chart, CS01 line $k  {}", row(&|s| format!("{:>9.2}", cs_a * (s as f64 * BP - s0) / BP / 1e3)));
    for s in [200i32, 400, 800] {
        let lam_s = implied(s as f64 * BP, RATE, R, T);
        println!("bars, CS01 at {:>3} bp  bump {:>10.2}  derivative {:>10.2}", s,
                 bumped(s as f64 * BP, s0).1, analytic(lam_s, s0, RATE, R).0);
    }
    assert!((cs_c - cs_a).abs() < 0.01, "CS01: central bump vs derivative of the legs");
    assert!((cs_a - cs_na).abs() < 1e-6, "CS01 at par: derivative vs N x A x 1bp");
    assert!((w_ir - w_ir_a).abs() < 0.01, "IR01, widened: bump vs derivative");
    assert!((w_rec - w_rec_a).abs() < 0.5, "Rec01, widened: bump vs derivative (bump is 1 point wide)");
    assert!((N * (1.0 - R) - v_dead).abs() < 1.0, "JTD: formula vs revalue at an immediate default");
    assert!([ir_c, ir_a, rec_c, rec_a].iter().all(|x| x.abs() < 0.01), "at par: IR01 and Rec01 vanish, both roads");
    assert!((v200 - value(&flat(lam200), T, RATE, R, s0, protection_simpson)).abs() < 0.01, "value at 200 bp, two roads");
    assert!((par(&fl, 4.75, RATE, R) - s0).abs() < 1e-12, "flat curve: par spread does not depend on maturity");
    assert!(w_c < cs_up && cs_up < cs_c, "CS01 falls as the spread widens");
    assert!((roll - roll_simp).abs() < 0.01, "roll-down, two roads");
    println!("ALL CHECKS PASS");
}
