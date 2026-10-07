// Forward points and the FX swap -- the check behind the card.  std only.
// Road 1 is the formula.  Road 2 sums e^x by hand and finds the far-leg rate by bisection
// on the dollar lender's ledger.  Road 3 is the money-market form.  Road 4 rolls 3M forwards.
const PIP: f64 = 0.0001;
const N: f64 = 10_000_000.0; // EUR notional

fn ex(x: f64) -> f64 { // e^x as 1 + x + x^2/2! + ..., summed by hand
    let (mut total, mut term) = (1.0, 1.0);
    for k in 1..40 { term *= x / k as f64; total += term; }
    total
}

fn pts(s: f64, rd: f64, rf: f64, t: f64) -> f64 { s * (((rd - rf) * t).exp() - 1.0) / PIP } // road 1

fn lender_gap(fq: f64, s: f64, rd: f64, rf: f64, t: f64) -> f64 {
    let far_leg = fq; // hand back 1 euro, receive fq dollars
    let euro_int = (ex(rf * t) - 1.0) * fq; // interest on the euro collateral, sold at fq
    far_leg + euro_int - s * ex(rd * t) // minus an unsecured dollar deposit
}

fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (f(lo) < 0.0) == (f(mid) < 0.0) { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

fn pts_ledger(s: f64, rd: f64, rf: f64, t: f64) -> f64 { // road 2
    (bisect(|f| lender_gap(f, s, rd, rf, t), 0.5 * s, 2.0 * s) - s) / PIP
}

fn pts_mm(s: f64, rd: f64, rf: f64, t: f64) -> f64 { // road 3: simple rates, tau = t
    let (rdm, rfm) = ((ex(rd * t) - 1.0) / t, (ex(rf * t) - 1.0) / t);
    s * (rdm - rfm) * t / (1.0 + rfm * t) / PIP
}

fn main() {
    let (s, rd, rf) = (1.10_f64, 0.05_f64, 0.03_f64);
    let (p1y, p3m) = (pts(s, rd, rf, 1.0), pts(s, rd, rf, 0.25));
    let (f1y, f3m) = (s + p1y * PIP, s + p3m * PIP);
    let p1y_roll = (s * (f3m / s).powi(4) - s) / PIP; // road 4
    let (rule1y, rule3m) = (s * (rd - rf) * 1.0 / PIP, s * (rd - rf) * 0.25 / PIP);
    let second = s * ((rd - rf) * 1.0).powi(2) / 2.0 / PIP;
    let p6m = pts(s, rd, rf, 0.5);
    let p6m_lin = p3m + (0.5 - 0.25) / (1.0 - 0.25) * (p1y - p3m);
    let p1y_s111 = pts(1.11, rd, rf, 1.0);
    let (flip3m, flip1y) = (pts(s, rf, rd, 0.25), pts(s, rf, rd, 1.0));

    // two-way quote: low/high adds, high/low subtracts
    let (sb, sa) = (1.0999_f64, 1.1001_f64);
    let outright = |pb: f64, pa: f64| -> (f64, f64) {
        if pb <= pa { (sb + pb * PIP, sa + pa * PIP) } else { (sb - pb * PIP, sa - pa * PIP) }
    };
    let (up_b, up_a) = outright(55.0, 55.3);
    let (dn_b, dn_a) = outright(55.3, 55.0);
    let (wr_b, wr_a) = (sb + 55.3 * PIP, sa + 55.0 * PIP);

    // the 3M swap on EUR 10m
    let t = 0.25;
    let (near_usd, far_usd) = (N * s, N * f3m);
    let points_leg = far_usd - near_usd;
    let usd_int = N * s * (ex(rd * t) - 1.0);
    let eur_int = N * (ex(rf * t) - 1.0);
    let two_loans = usd_int - eur_int * f3m;
    let gap_rule = N * s * (rd - rf) * t;
    let lender_value = |s_new: f64| -> f64 {
        let held = N * s_new - near_usd;
        let far = far_usd * ex(-rd * t) - N * s_new * ex(-rf * t);
        held + far
    };
    let swap_move = lender_value(1.20) - lender_value(s);
    let fwd_move = N * (1.20 - s) * ex(-rf * t);
    let ndf = N * (1.12 - f3m);

    let rows: Vec<(&str, f64)> = vec![
        ("1Y points, formula", p1y), ("1Y points, ledger + bisection", pts_ledger(s, rd, rf, 1.0)),
        ("1Y points, money-market form", pts_mm(s, rd, rf, 1.0)), ("1Y points, 3M rolled 4 times", p1y_roll),
        ("1Y outright", f1y),
        ("3M points, formula", p3m), ("3M points, ledger + bisection", pts_ledger(s, rd, rf, 0.25)),
        ("3M points, money-market form", pts_mm(s, rd, rf, 0.25)), ("3M outright", f3m),
        ("3M carry factor minus one", ((rd - rf) * 0.25).exp() - 1.0), ("3M forward minus spot", f3m - s),
        ("1Y carry factor", (rd - rf).exp()), ("wrong: 3M points added 4 times", 4.0 * p3m),
        ("rule of thumb 1Y, S(rd-rf)T", rule1y), ("rule of thumb 3M", rule3m),
        ("1Y exact minus rule", p1y - rule1y), ("  square term S((rd-rf)T)^2/2", second),
        ("6M points, formula", p6m), ("6M points, straight line 3M-1Y", p6m_lin),
        ("1Y points at spot 1.1100", p1y_s111),
        ("flipped rates: 3M points", flip3m), ("flipped rates: 3M ledger", pts_ledger(s, rf, rd, 0.25)),
        ("flipped rates: 1Y points", flip1y),
        ("spot bid", sb), ("spot ask", sa),
        ("quote 55.0/55.3: outright bid", up_b), ("  outright ask", up_a),
        ("quote 55.3/55.0: outright bid", dn_b), ("  outright ask", dn_a),
        ("wrong: 55.3/55.0 added, bid", wr_b), ("  ask", wr_a),
        ("wrong: pip read as 0.001, 3M", s + p3m * 0.001),
        ("swap near leg, USD", near_usd), ("swap far leg, USD", far_usd),
        ("one pip on EUR 10m, USD", N * PIP), ("points leg, USD", points_leg), ("  USD interest on 11m, 5%", usd_int),
        ("  EUR interest on 10m, 3%", eur_int), ("  EUR interest, in USD at F", eur_int * f3m),
        ("  USD interest minus EUR interest", two_loans), ("  rule: 2% gap on 11m, a quarter", gap_rule),
        ("lender value at trade", lender_value(s)), ("spot to 1.20: swap moves", swap_move),
        ("spot to 1.20: outright moves", fwd_move), ("NDF paid on a 1.1200 fixing", ndf),
    ];
    for (name, v) in &rows { println!("{:<36} {:>16.6}", name, v); }
    let ts = [0.25_f64, 0.5, 1.0, 2.0, 3.0, 5.0];
    println!();
    println!("chart, years          {}", ts.iter().map(|t| format!("{:>8.2}", t)).collect::<Vec<_>>().join(" "));
    println!("chart, points exact   {}", ts.iter().map(|&t| format!("{:>8.2}", pts(s, rd, rf, t))).collect::<Vec<_>>().join(" "));
    println!("chart, rule of thumb  {}", ts.iter().map(|&t| format!("{:>8.2}", s * (rd - rf) * t / PIP)).collect::<Vec<_>>().join(" "));

    assert!((p1y - pts_ledger(s, rd, rf, 1.0)).abs() < 1e-6, "formula and ledger must agree, 1Y");
    assert!((p3m - pts_ledger(s, rd, rf, 0.25)).abs() < 1e-6, "formula and ledger must agree, 3M");
    assert!((p1y - pts_mm(s, rd, rf, 1.0)).abs() < 1e-6, "money-market form must agree");
    assert!((p1y - p1y_roll).abs() < 1e-6, "the forward curve is multiplicative");
    assert!(((p1y - rule1y) - second).abs() < 0.02, "rule of thumb misses the square term, and little else");
    assert!((flip3m - pts_ledger(s, rf, rd, 0.25)).abs() < 1e-6, "flipped rates: the ledger agrees");
    assert!(p6m_lin > p6m, "points curve bends up, so a straight line overstates a broken date");
    let grid: Vec<(f64, f64)> = (0..900).step_by(37).flat_map(|b| (0..900).step_by(41).map(move |a| (b as f64 / 10.0, a as f64 / 10.0))).filter(|(b, a)| b != a).collect();
    assert!(grid.iter().all(|&(b, a)| { let (ob, oa) = outright(b, a); oa - ob > sa - sb }), "the add/subtract rule always widens the spread");
    assert!((points_leg - two_loans).abs() < 1e-4, "points leg = dollar interest minus euro interest");
    assert!(lender_value(s).abs() < 1e-4, "a swap at market is worth nothing at inception");
    assert!((swap_move - N * (1.20 - s) * (1.0 - (-rf * t).exp())).abs() < 1e-4, "swap feels spot only through euro interest");
    println!("all checks passed");
}
