// Valuing an old currency forward -- the check behind the card.  Rust std only.
// Nothing used holds the answer: the pricing-world average is Simpson's rule
// written out, the discount is also rebuilt by compounding a deposit step by
// step, and the flat rate of a book is found by bisection.
// A year ago: bought EUR 10,000,000 for delivery in 15 months at 1.1500 USD/EUR.
// Today: three months left, spot 1.1000, three-month forward quoted 1.1055.

const A: f64 = 10_000_000.0; // euros bought
const K: f64 = 1.1500; // contract rate, dollars per euro
const TAU: f64 = 0.25; // years left
const S: f64 = 1.1000; // spot today
const F: f64 = 1.1055; // today's three-month forward quote
const RD: f64 = 0.05; // dollar rate, continuously compounded

fn rf() -> f64 {
    RD - (F / S).ln() / TAU // euro rate the quote implies (parity)
}

// spot form: euros on deposit minus a dollar loan
fn mark_usd(s: f64, t: f64) -> f64 {
    A * (s * (-rf() * t).exp() - K * (-RD * t).exp())
}

// Road 4: the pricing-world average of the payoff, by Simpson's rule
fn by_simpson(vol: f64, n: usize) -> f64 {
    let (lo, hi) = (-10.0_f64, 10.0_f64);
    let h = (hi - lo) / n as f64;
    let f = |z: f64| {
        let st = S * ((RD - rf() - 0.5 * vol * vol) * TAU + vol * TAU.sqrt() * z).exp();
        (st - K) * (-0.5 * z * z).exp() / (2.0 * std::f64::consts::PI).sqrt()
    };
    let mut tot = f(lo) + f(hi);
    for i in 1..n {
        let w = if i % 2 == 1 { 4.0 } else { 2.0 };
        tot += w * f(lo + i as f64 * h);
    }
    A * (-RD * TAU).exp() * tot * h / 3.0
}

fn main() {
    let rf = rf();
    let f_house = S * ((RD - 0.03) * TAU).exp(); // the shelf's house forward at 3% euros
    let (dd, df) = ((-RD * TAU).exp(), (-rf * TAU).exp());

    // Road 1: the formula
    let per_eur = (F - K) * dd;
    let v_usd = A * per_eur;
    let v_eur = v_usd / S;
    // Road 2: close out, discount by compounding a deposit in 100,000 steps
    let locked = A * F - A * K;
    let mut grow = 1.0_f64;
    for _ in 0..100_000 {
        grow *= 1.0 + RD * TAU / 100_000.0;
    }
    let v_close = locked / grow;
    // Road 3: count in euros from the start
    let locked_eur = A - A * K / F;
    let v_eur_road = locked_eur * df;
    // Road 4: Simpson at two vols
    let (v_simp8, v_simp16) = (by_simpson(0.08, 4000), by_simpson(0.16, 4000));
    // Road 5: sensitivities by formula, then by nudging
    let (pip, bp) = (0.0001_f64, 0.0001_f64);
    let df_pip = A * dd * pip;
    let ds_pip = A * df * pip;
    let ds_bump = (mark_usd(S + pip, TAU) - mark_usd(S - pip, TAU)) / 2.0;
    let drd_bp = A * K * TAU * dd * bp;
    let rd_bump = (A * K * (-(RD - bp) * TAU).exp() - A * K * (-(RD + bp) * TAU).exp()) / 2.0;
    let drf_bp = -A * S * TAU * df * bp;
    let rf_bump = (A * S * (-(rf + bp) * TAU).exp() - A * S * (-(rf - bp) * TAU).exp()) / 2.0;
    let eur_ds = A * K * dd / (S * S) * pip;
    let eur_bump =
        (mark_usd(S + pip, TAU) / (S + pip) - mark_usd(S - pip, TAU) / (S - pip)) / 2.0;
    // The book: long EUR 10m at 1.1500, short EUR 4m at 1.1300, same delivery day
    let legs = [(10_000_000.0_f64, 1.1500_f64), (-4_000_000.0, 1.1300)];
    let book = |f: f64| legs.iter().map(|&(a, k)| a * (f - k)).sum::<f64>() * dd;
    let f_flat = legs.iter().map(|&(a, k)| a * k).sum::<f64>()
        / legs.iter().map(|&(a, _)| a).sum::<f64>();
    let (mut lo, mut hi) = (0.5_f64, 2.0_f64); // value rises with f: one root
    for _ in 0..80 {
        let mid = 0.5 * (lo + hi);
        if book(mid) < 0.0 { lo = mid } else { hi = mid }
    }
    let s_flat = K * (-(RD - rf) * TAU).exp();

    let rows: Vec<(&str, f64)> = vec![
        ("house forward, 3% euros", f_house), ("forward premium ln(F/S)/tau", (F / S).ln() / TAU),
        ("implied euro rate", rf), ("gap F - K", F - K), ("K / F", K / F),
        ("dollar discount", dd), ("euro discount", df),
        ("1 per euro, USD", per_eur), ("1 mark, USD", v_usd), ("  restated, EUR", v_eur),
        ("2 USD paid, old contract", A * K),
        ("  USD received, new contract", A * F), ("  locked at delivery, USD", locked), ("  compounded deposit", grow),
        ("  close-out today, USD", v_close), ("3 locked at delivery, EUR", locked_eur),
        ("  counted in euros, EUR", v_eur_road), ("4 Simpson, vol 8%, USD", v_simp8),
        ("  Simpson, vol 16%, USD", v_simp16), ("5 per pip of forward, USD", df_pip),
        ("  per pip of spot, USD", ds_pip), ("  by bump", ds_bump),
        ("  per bp dollar rate, USD", drd_bp), ("  by bump", rd_bump),
        ("  per bp euro rate, USD", drf_bp), ("  by bump", rf_bump),
        ("  EUR mark per pip of spot", eur_ds), ("  by bump", eur_bump),
        ("6 book value, USD", book(F)), ("  flat forward, weights", f_flat),
        ("  flat forward, bisection", hi), ("  flat spot, one contract", s_flat),
        ("wrong: no discount", locked), ("wrong: euro discount", A * (F - K) * df),
        ("wrong: spot for forward", A * (S - K) * dd),
        ("wrong: to EUR at forward", v_usd / F), ("wrong: to EUR at contract", v_usd / K),
    ];
    for (name, v) in &rows {
        println!("{:<28} {:>17.6}", name, v);
    }
    println!();
    println!("mark in thousands, by spot today (3 months left, at delivery, EUR count)");
    for s in [1.06_f64, 1.08, 1.10, 1.12, 1.14, 1.16, 1.18] {
        let m = mark_usd(s, TAU);
        println!("spot {:.2}  {:9.2}  {:9.2}  {:9.2}", s, m / 1e3, A * (s - K) / 1e3, m / s / 1e3);
    }
    println!("mark in thousands USD, spot stuck at 1.1000, by months left");
    for m in [3, 2, 1, 0] {
        println!("months {}  {:9.2}", m, mark_usd(S, m as f64 / 12.0) / 1e3);
    }

    assert!((v_close - v_usd).abs() < 0.01, "close-out by compounding must match the formula");
    assert!((v_eur_road - v_eur).abs() < 0.01, "counting in euros must match the dollar mark over spot");
    assert!((v_simp8 - v_usd).abs() < 0.01, "pricing-world average must match, vol 8%");
    assert!((v_simp16 - v_usd).abs() < 0.01, "pricing-world average must match, vol 16%");
    assert!((ds_bump - ds_pip).abs() < 1e-6, "spot nudge must match the spot slope");
    assert!((rd_bump - drd_bp).abs() < 1e-3, "dollar-rate nudge must match its slope");
    assert!((rf_bump - drf_bp).abs() < 1e-3, "euro-rate nudge must match its slope");
    assert!((eur_bump - eur_ds).abs() < 1e-3, "euro-count nudge must match its slope");
    assert!((hi - f_flat).abs() < 1e-12, "bisection must find the weighted delivery rate");
    assert!(((f_house * 1e4).round() / 1e4 - F).abs() < 1e-12, "the quote is the house forward rounded to the pip");
    println!("PASS");
}
