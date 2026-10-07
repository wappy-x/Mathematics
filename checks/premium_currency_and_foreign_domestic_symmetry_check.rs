// One option, two currencies -- the check behind the card.  Rust std only.
// Same rows and labels as the Python check.  The normal CDF here is a different
// road: Simpson's rule over the bell curve from 0 to x, not a series.
const S: f64 = 1.10; // EURUSD: USD per 1 EUR
const RD: f64 = 0.05; // USD rate, continuously compounded
const RF: f64 = 0.03; // EUR rate
const VOL: f64 = 0.10;
const T: f64 = 1.0;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * std::f64::consts::PI).sqrt() }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut total = f(a) + f(b);
    for i in 1..n {
        total += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h);
    }
    total * h / 3.0
}

fn n_cdf(x: f64) -> f64 {
    if x.abs() > 9.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    0.5 + simpson(phi, 0.0, x, 2000)
}

// Garman-Kohlhagen: premium in domestic per 1 unit of foreign
fn gk(s: f64, k: f64, rd: f64, rf: f64, vol: f64, t: f64, call: bool) -> f64 {
    let v = vol * t.sqrt();
    let d1 = ((s / k).ln() + (rd - rf + 0.5 * vol * vol) * t) / v;
    let d2 = d1 - v;
    if call { s * (-rf * t).exp() * n_cdf(d1) - k * (-rd * t).exp() * n_cdf(d2) }
    else { k * (-rd * t).exp() * n_cdf(-d2) - s * (-rf * t).exp() * n_cdf(-d1) }
}

// Average the payoff over the bell curve where it pays, discount at the domestic rate.
fn by_integral(s: f64, k: f64, rd: f64, rf: f64, vol: f64, t: f64, call: bool) -> f64 {
    let (m, v) = ((rd - rf - 0.5 * vol * vol) * t, vol * t.sqrt());
    let z0 = ((k / s).ln() - m) / v;
    let (a, b) = if call { (z0, 12.0) } else { (-12.0, z0) };
    let f = |z: f64| {
        let st = s * (m + v * z).exp();
        (if call { st - k } else { k - st }) * phi(z)
    };
    (-rd * t).exp() * simpson(f, a, b, 2000)
}

fn out(rows: &mut Vec<String>, label: &str, v: f64) { rows.push(format!("{:<34} {:>14.8}", label, v)); }
fn money(rows: &mut Vec<String>, label: &str, v: f64) { rows.push(format!("{:<34} {:>14.2}", label, v)); }

fn four_quotes(rows: &mut Vec<String>, k: f64, tag: &str) -> f64 {
    let c = gk(S, k, RD, RF, VOL, T, true); // road 1: USD side
    let p_eur = gk(1.0 / S, 1.0 / k, RF, RD, VOL, T, false); // road 2: EUR side, EUR per USD
    let c_int = by_integral(S, k, RD, RF, VOL, T, true);
    let pe_int = by_integral(1.0 / S, 1.0 / k, RF, RD, VOL, T, false);
    out(rows, &format!("{} 1 GK call, USD per EUR", tag), c);
    out(rows, &format!("{} 2 USD put from EUR side", tag), p_eur);
    out(rows, &format!("{} 3 S*K*(2), USD per EUR", tag), S * k * p_eur);
    out(rows, &format!("{} 4 integral, USD side", tag), c_int);
    out(rows, &format!("{} 5 integral, EUR side, *S*K", tag), S * k * pe_int);
    let quotes = [
        ("USD pips", c * 1e4, S * k * p_eur * 1e4),
        ("% EUR notional", c / S * 100.0, k * p_eur * 100.0),
        ("% USD notional", c / k * 100.0, S * p_eur * 100.0),
        ("EUR pips", c / (S * k) * 1e4, p_eur * 1e4),
    ];
    for (name, a, b) in quotes.iter() {
        rows.push(format!("{}   {:<16} {:>12.4} {:>12.4}", tag, name, a, b));
    }
    assert!((c_int - c).abs() < 1e-11, "integral road, USD side");
    assert!((S * k * pe_int - c).abs() < 1e-11, "integral road, EUR side, converted");
    assert!((S * k * p_eur - c).abs() < 1e-12, "symmetry: C(S,K,rd,rf) = S K P(1/S,1/K,rf,rd)");
    c
}

fn main() {
    let mut rows: Vec<String> = Vec::new();
    // the hand table at strike 1.20, both sides
    let v = VOL * T.sqrt();
    let ln_sk = (S / 1.20f64).ln();
    let d1 = (ln_sk + (RD - RF + 0.5 * VOL * VOL) * T) / v;
    let e1 = (((1.0 / S) / (1.0 / 1.20f64)).ln() + (RF - RD + 0.5 * VOL * VOL) * T) / v; // EUR side
    let hand = [
        ("hand 1/S, EUR per USD", 1.0 / S), ("hand 1/K, EUR per USD", 1.0 / 1.20), ("hand ln(S/K)", ln_sk), ("hand d1, USD side", d1), ("hand d2, USD side", d1 - v),
        ("hand N(d1)", n_cdf(d1)), ("hand N(d2)", n_cdf(d1 - v)), ("hand e^-rfT", (-RF * T).exp()),
        ("hand e^-rdT", (-RD * T).exp()), ("hand share half S e^-rfT N(d1)", S * (-RF * T).exp() * n_cdf(d1)),
        ("hand cash half K e^-rdT N(d2)", 1.20 * (-RD * T).exp() * n_cdf(d1 - v)),
        ("hand d1, EUR side", e1), ("hand d2, EUR side", e1 - v),
    ];
    for (label, x) in hand.iter() { out(&mut rows, label, *x); }
    let c12 = four_quotes(&mut rows, 1.20, "K1.20");
    let c11 = four_quotes(&mut rows, 1.10, "K1.10");
    assert!((c11 - 0.053556).abs() < 5e-7, "house call at strike 1.10");

    // the mirror: EUR put / USD call, priced three ways
    let p11 = gk(S, 1.10, RD, RF, VOL, T, false);
    let p11_eur = S * 1.10 * gk(1.0 / S, 1.0 / 1.10, RF, RD, VOL, T, true);
    out(&mut rows, "mirror EUR put, USD per EUR", p11);
    out(&mut rows, "mirror S*K*USD call from EUR side", p11_eur);
    out(&mut rows, "mirror integral, USD side", by_integral(S, 1.10, RD, RF, VOL, T, false));
    assert!((p11 - 0.032418).abs() < 5e-7, "house put at strike 1.10");
    assert!((p11_eur - p11).abs() < 1e-12, "mirror: a EUR put is a USD call");

    // the payoff identity, path by path, at strike 1.20
    let mut agree = 0;
    for i in 0..81 {
        let st = 0.80 + 0.01 * i as f64;
        let usd = (st - 1.20f64).max(0.0); // EUR call, paid in USD per 1 EUR
        let eur = 1.20 * (1.0 / 1.20 - 1.0 / st).max(0.0); // USD put on 1.20 USD, paid in EUR
        if (eur * st - usd).abs() < 1e-14 { agree += 1; }
    }
    rows.push(format!("{:<34} {:>14}", "payoffs agree, of 81 expiry rates", agree));
    assert!(agree == 81, "the two payoffs agree at every expiry rate");

    out(&mut rows, "S*K, USD pips per EUR pip", S * 1.20);
    // a 10 million EUR ticket at strike 1.20
    money(&mut rows, "ticket USD notional", 1.20 * 1e7);
    money(&mut rows, "ticket premium, USD", c12 * 1e7);
    money(&mut rows, "ticket premium, EUR", c12 / S * 1e7);

    // what breaks, strike 1.20
    out(&mut rows, "wrong: USD notional at spot, %", c12 / S * 100.0);
    out(&mut rows, "wrong: rates not swapped, USD", S * 1.20 * gk(1.0 / S, 1.0 / 1.20, RD, RF, VOL, T, false));
    out(&mut rows, "wrong: %EUR read as %USD, USD", c12 / S * 1.20);
    out(&mut rows, "wrong: USD pips read as EUR pips", c12 * S * 1.20);

    // try changing
    let c10 = gk(S, 1.00, RD, RF, VOL, T, true);
    out(&mut rows, "try: K 1.00, % EUR notional", c10 / S * 100.0);
    out(&mut rows, "try: K 1.00, % USD notional", c10 / 1.00 * 100.0);
    let c20v = gk(S, 1.20, RD, RF, 0.20, T, true);
    out(&mut rows, "try: vol 20%, K 1.20, USD pips", c20v * 1e4);
    out(&mut rows, "try: vol 20%, K 1.20, EUR pips", c20v / (S * 1.20) * 1e4);
    let c1212 = gk(1.20, 1.20, RD, RF, VOL, T, true);
    out(&mut rows, "try: S 1.20, K 1.20, % EUR", c1212 / 1.20 * 100.0);
    out(&mut rows, "try: S 1.20, K 1.20, % USD", c1212 / 1.20 * 100.0);

    // chart: the two percentages across strikes
    let ks: Vec<f64> = (0..6).map(|i| 1.00 + 0.05 * i as f64).collect();
    let line = |f: &dyn Fn(f64) -> f64| ks.iter().map(|&k| format!("{:6.2}", f(k))).collect::<Vec<_>>().join(" ");
    rows.push(format!("chart, strike      {}", line(&|k| k)));
    rows.push(format!("chart, % EUR       {}", line(&|k| gk(S, k, RD, RF, VOL, T, true) / S * 100.0)));
    rows.push(format!("chart, % USD       {}", line(&|k| gk(S, k, RD, RF, VOL, T, true) / k * 100.0)));
    println!("{}", rows.join("\n"));
    println!("ALL CHECKS PASS");
}
