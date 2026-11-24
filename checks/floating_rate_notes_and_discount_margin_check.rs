// Floating-rate notes and the discount margin -- the same check as the Python,
// in Rust, std only and no crates.  The forward rates, the two pricings and both
// root finders are written out here.  The note: 3 years, annual, pays the 1-year
// rate plus a quoted margin of 1.00% on a face of 100.  Every rate compounds once
// a year.  Independent roads: the telescoping identity (par, exactly 100) against
// both pricings; on the flat curve, the bond formula F + F(m - d) x annuity
// against the solved margin; bisection against Newton's method.  The backward walk
// is the payment-by-payment sum regrouped, so comparing the two catches coding slips.
const FACE: f64 = 100.0;
const QM: f64 = 0.01;
const YEARS: usize = 3;
const FLAT: [f64; 3] = [0.04, 0.04, 0.04];     // spot rates, 1 to 3 years: a flat 4% curve
const SLOPED: [f64; 3] = [0.03, 0.04, 0.05];   // spot rates on a rising curve, for the contrast

fn forwards(spot: &[f64]) -> Vec<f64> {        // the 1-year rate each later year is priced at
    let (mut out, mut prev) = (Vec::new(), 1.0);
    for (i, s) in spot.iter().enumerate() {
        let grow = (1.0 + s).powi(i as i32 + 1);
        out.push(grow / prev - 1.0);
        prev = grow;
    }
    out
}

fn price_sum(fwd: &[f64], dm: f64, qm: f64) -> f64 {   // road one: each payment, down the chain
    let (mut pv, mut chain) = (0.0, 1.0);
    for f in fwd {
        chain *= 1.0 + f + dm;
        pv += FACE * (f + qm) / chain;
    }
    pv + FACE / chain
}

fn price_back(fwd: &[f64], dm: f64, qm: f64) -> f64 {  // road two: from maturity, a reset at a time
    let mut value = FACE;
    for f in fwd.iter().rev() {
        value = (FACE * (f + qm) + value) / (1.0 + f + dm);
    }
    value
}

fn slope(fwd: &[f64], dm: f64, qm: f64) -> f64 {       // d price / d dm, by hand, for Newton
    let (mut total, mut chain, mut run) = (0.0, 1.0, 0.0);
    for (i, f) in fwd.iter().enumerate() {
        chain *= 1.0 + f + dm;
        run += 1.0 / (1.0 + f + dm);
        let cash = FACE * (f + qm) + if i == fwd.len() - 1 { FACE } else { 0.0 };
        total -= cash / chain * run;
    }
    total
}

fn bisect<G: Fn(f64) -> f64>(g: G) -> f64 {   // g falls from positive at -0.5 to negative at 1.0
    let (mut lo, mut hi) = (-0.5, 1.0);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if g(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn newton<G: Fn(f64) -> f64, H: Fn(f64) -> f64>(g: G, gp: H) -> f64 {
    let mut x = 0.0;
    for _ in 0..60 { x -= g(x) / gp(x) }
    x
}

fn zspread(spot: &[f64], fwd: &[f64], p: f64, cont: bool) -> f64 {   // one extra rate per date
    let pv = |z: f64| {
        let mut out = 0.0;
        for (i, (s, f)) in spot.iter().zip(fwd).enumerate() {
            let t = (i + 1) as f64;
            let d = if cont { (-((1.0 + s).ln() + z) * t).exp() } else { (1.0 + s + z).powf(-t) };
            out += (FACE * (f + QM) + if i == spot.len() - 1 { FACE } else { 0.0 }) * d;
        }
        out
    };
    bisect(|z| pv(z) - p)
}

fn pct(x: f64) -> String { format!("{:.4}%", x * 100.0) }
fn show(label: &str, v: String, unit: &str) { println!("{:<50}{:>12}{}", label, v, unit) }
fn list(v: &[f64], f: &dyn Fn(f64) -> String) -> String {
    v.iter().map(|x| f(*x)).collect::<Vec<_>>().join(", ")
}

fn main() {
    let (ff, fs) = (forwards(&FLAT), forwards(&SLOPED));
    let dm_bis = bisect(|d| price_sum(&ff, d, QM) - 99.0);
    let dm_new = newton(|d| price_back(&ff, d, QM) - 99.0, |d| slope(&ff, d, QM));
    let annuity5: f64 = (1..=YEARS).map(|t| 1.05f64.powi(-(t as i32))).sum();
    let hand = QM + (FACE - 99.0) / (FACE * annuity5);
    let annuity_dm: f64 = (1..=YEARS).map(|t| (1.0 + FLAT[0] + dm_bis).powi(-(t as i32))).sum();   // 4% plus the answer
    let dm_s = bisect(|d| price_sum(&fs, d, QM) - 99.0);
    let z_s = zspread(&SLOPED, &fs, 99.0, false);
    let z_par = zspread(&SLOPED, &fs, 100.0, false);
    let simple = QM + (FACE - 99.0) / FACE / YEARS as f64;
    let no_qm = bisect(|d| price_sum(&ff, d, 0.0) - 99.0);
    let z_cont = zspread(&FLAT, &ff, 99.0, true);
    let fixed = |y: f64| (1..=3).map(|t| 5.0 / (1.0 + y).powi(t)).sum::<f64>() + FACE / (1.0 + y).powi(3);
    let after_fix = (FACE * (0.04 + QM) + price_back(&[0.05, 0.05], QM, QM)) / (1.0 + 0.05 + QM);

    println!("flat 4% curve: forwards {}; projected coupons {}",
             list(&ff, &|f| pct(f)), list(&ff, &|f| format!("{:.2}", FACE * (f + QM))));
    show("price at DM 1.00%, payment by payment", format!("{:.6}", price_sum(&ff, QM, QM)), "");
    show("price at DM 1.00%, backwards from maturity", format!("{:.6}", price_back(&ff, QM, QM)), "");
    show("price on the curve alone, DM 0", format!("{:.6}", price_sum(&ff, 0.0, QM)), "");
    show("DM at a price of 99, bisection", pct(dm_bis), "");
    show("DM at a price of 99, Newton", pct(dm_new), "");
    show("the note repriced at that DM", format!("{:.6}", price_back(&ff, dm_bis, QM)), "");
    show("hand estimate: annuity at 5%", format!("{:.6}", annuity5), "");
    show("hand estimate: 1.00% + 1.00 / (100 x annuity)", pct(hand), "");
    println!();
    println!("rising curve 3%, 4%, 5%: forwards {}; coupons {}",
             list(&fs, &|f| pct(f)), list(&fs, &|f| format!("{:.4}", FACE * (f + QM))));
    show("price at DM 1.00%, payment by payment", format!("{:.6}", price_sum(&fs, QM, QM)), "");
    show("price at DM 1.00%, backwards from maturity", format!("{:.6}", price_back(&fs, QM, QM)), "");
    show("DM at a price of 99", pct(dm_s), "");
    show("z-spread at a price of 99", pct(z_s), "");
    show("z-spread minus DM", format!("{:.4}", (z_s - dm_s) * 10000.0), " bp");
    show("z-spread of the same note at 100", format!("{:.4}", z_par * 10000.0), " bp");
    println!();
    println!("what breaks (the right DM is {})", pct(dm_bis));
    show("the 1.00 discount spread evenly, undiscounted", pct(simple), "");
    show("quoted margin left out of the coupons", pct(no_qm), "");
    show("continuously compounded z-spread read as DM", pct(z_cont), "");
    println!();
    println!("how it moves");
    show("curve up to 5%, DM still 1.00%: the floater", format!("{:.6}", price_back(&forwards(&[0.05; 3]), QM, QM)), "");
    show("a 3-year 5% fixed bond at a 5% yield", format!("{:.6}", fixed(0.05)), "");
    show("curve up to 5%: a 3-year 5% fixed bond, yield 6%", format!("{:.6}", fixed(0.06)), "");
    show("curve at 4%, DM widens to 2.00%: the floater", format!("{:.6}", price_back(&ff, 0.02, QM)), "");
    show("curve jumps to 5% just after the fixing", format!("{:.6}", after_fix), "");
    let dms = [0.0050, 0.0075, 0.0100, 0.0125, 0.0150, 0.0175, 0.0200];
    println!("{:<26}{}", "chart, DM in percent", dms.iter().map(|d| format!("{:>8.2}", d * 100.0)).collect::<String>());
    println!("{:<26}{}", "chart, price", dms.iter().map(|d| format!("{:>8.2}", price_sum(&ff, *d, QM))).collect::<String>());
    println!();
    println!("try changing");
    show("price 98 instead of 99: DM", pct(bisect(|d| price_sum(&ff, d, QM) - 98.0)), "");
    show("quoted margin 0.50%, market DM 1.00%: price", format!("{:.6}", price_sum(&ff, QM, 0.005)), "");
    let long: Vec<f64> = (0..10).map(|k| 0.03 + 0.005 * k as f64).collect();   // 10 years, 3.0% to 7.5%
    let fl = forwards(&long);
    let gap = zspread(&long, &fl, 99.0, false) - bisect(|d| price_sum(&fl, d, QM) - 99.0);
    show("10-year note, rising 3% to 7.5%, price 99: z - DM", format!("{:.4}", gap * 10000.0), " bp");
    assert!((price_sum(&ff, QM, QM) - FACE).abs() < 1e-9 && (price_sum(&fs, QM, QM) - FACE).abs() < 1e-9);
    assert!((price_sum(&fs, 0.0137, QM) - price_back(&fs, 0.0137, QM)).abs() < 1e-10);   // two roads
    assert!((slope(&fs, 0.0137, QM) - (price_back(&fs, 0.013701, QM) - price_back(&fs, 0.013699, QM)) / 2e-6).abs() < 1e-5);   // P'(d)
    assert!((dm_bis - dm_new).abs() < 1e-12);                                         // two solvers
    assert!((dm_bis * 1e6).round() == 13698.0 && (hand - dm_bis).abs() < 3e-5);      // 1.3698%, by hand
    assert!(z_s - dm_s > 0.0 && z_s - dm_s < 1e-5 && (z_par - QM).abs() > 1e-7);      // close, not equal
    assert!((FACE + FACE * (QM - dm_bis) * annuity_dm - 99.0).abs() < 1e-9);         // flat curve: bond formula
    println!("ALL CHECKS PASS");
}
