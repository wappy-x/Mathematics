// Z-spread and asset-swap spread -- the same check as the Python, in Rust, std
// only and no crates: the root finders, the forward rates and the swap legs
// are all written out here.  The curve is this morning's bootstrapped zero
// curve, 1 to 5 years.  The bond is Northwind 4s of 2031.  Each answer is
// reached twice by roads that share no arithmetic: discount factors straight
// from the zero rates against the same factors chained out of the one-year
// forwards; bisection against Newton; the asset-swap spread in closed form
// against the whole package priced cash flow by cash flow and solved to zero.
const ZERO: [f64; 5] = [0.0300, 0.0330, 0.0355, 0.0375, 0.0390];   // continuously compounded
const YEAR: [f64; 5] = [1.0, 2.0, 3.0, 4.0, 5.0];
const FACE: f64 = 100.0;
const CPN: f64 = 4.00;
const QUOTE: f64 = 94.833;

fn fwd() -> [f64; 5] {                     // the one-year forwards hiding in the zero rates
    let mut f = [0.0f64; 5];
    f[0] = ZERO[0] * YEAR[0];
    for i in 1..5 { f[i] = ZERO[i] * YEAR[i] - ZERO[i - 1] * YEAR[i - 1] }
    f
}

fn df(i: usize, s: f64) -> f64 {           // road one: one exponential per pillar
    (-(ZERO[i] + s) * YEAR[i]).exp()
}

fn df_chain(i: usize, s: f64) -> f64 {     // road two: multiply the one-year factors together
    let f = fwd();
    let mut out = 1.0;
    for k in 0..=i { out *= (-(f[k] + s)).exp() }
    out
}

fn price(s: f64, cpn: f64, chain: bool) -> f64 {        // the bond, at curve plus spread
    let g = |i: usize| if chain { df_chain(i, s) } else { df(i, s) };
    let mut p = 0.0;
    for i in 0..5 { p += cpn * g(i) }
    p + FACE * g(4)
}

fn slope(s: f64, cpn: f64) -> f64 {        // dP/ds, differentiated by hand, for Newton
    let mut body = 0.0;
    for i in 0..5 { body += YEAR[i] * cpn * df_chain(i, s) }
    -(body + YEAR[4] * FACE * df_chain(4, s))
}

fn bisect<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64) -> f64 {   // f falls from + at lo to - at hi
    let (mut lo, mut hi) = (lo, hi);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if f(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn newton<F: Fn(f64) -> f64, G: Fn(f64) -> f64>(f: F, fp: G, x: f64) -> f64 {
    let mut x = x;                         // the other solver: follow the slope
    for _ in 0..60 { x -= f(x) / fp(x) }
    x
}

fn package(a: f64) -> f64 {                // buy the bond, pay par, swap fixed for floating + a
    let f = fwd();
    let mut pv = QUOTE - FACE;
    for i in 0..5 { pv += (FACE * (f[i].exp() - 1.0) + FACE * a - CPN) * df_chain(i, 0.0) }
    pv
}

fn main() {
    let f = fwd();
    let curve_price = price(0.0, CPN, false);
    let chain_price = price(0.0, CPN, true);
    let z_bisect = bisect(|s| price(s, CPN, false) - QUOTE, -0.5, 1.0);
    let z_newton = newton(|s| price(s, CPN, true) - QUOTE, |s| slope(s, CPN), 0.0);
    let mut annuity = 0.0;
    for i in 0..5 { annuity += df(i, 0.0) }
    let float_par = FACE * (1.0 - df(4, 0.0));
    let mut float_fwd = 0.0;
    for i in 0..5 { float_fwd += FACE * (f[i].exp() - 1.0) * df_chain(i, 0.0) }
    let asw = (curve_price - QUOTE) / annuity / FACE;
    let asw_pkg = bisect(|a| -package(a), -0.5, 1.0);
    let ytm = bisect(|y| {
        let mut p = 0.0;
        for t in YEAR { p += CPN * (-y * t).exp() }
        p + FACE * (-y * YEAR[4]).exp() - QUOTE
    }, -0.5, 1.0);
    let ytm_annual = ytm.exp() - 1.0;
    let par_rate = (FACE - FACE * df(4, 0.0)) / annuity / FACE;
    let flat_z = bisect(|s| {
        let mut p = 0.0;
        for t in YEAR { p += CPN * (-(ZERO[4] + s) * t).exp() }
        p + FACE * (-(ZERO[4] + s) * YEAR[4]).exp() - QUOTE
    }, -0.5, 1.0);
    let mut risky_annuity = 0.0;
    for i in 0..5 { risky_annuity += df(i, z_bisect) }
    let asw_risky = (curve_price - QUOTE) / risky_annuity / FACE;
    let asw8 = (price(0.0, 8.0, false) - price(z_bisect, 8.0, false)) / annuity / FACE;
    let widened = price(z_bisect + 0.01, CPN, false);
    let bps = [0, 60, 120, 180, 240, 300];
    let prices: Vec<f64> = bps.iter().map(|&b| price(b as f64 / 10000.0, CPN, false)).collect();
    let coupons = [3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
    let asw_curve: Vec<f64> = coupons.iter()
        .map(|&c| (price(0.0, c, false) - price(z_bisect, c, false)) / annuity / FACE).collect();

    println!("the curve this morning, bootstrapped from deposits, futures and swaps");
    for i in 0..5 {
        println!("   {}y  zero {:.4}%   D {:.6}   one-year forward {:.4}%",
                 YEAR[i] as i64, ZERO[i] * 100.0, df(i, 0.0), f[i] * 100.0);
    }
    println!();
    println!("Northwind 4.000% of 2031, face 100, five annual coupons");
    for (label, v) in [("price on the curve, from the zero rates", curve_price),
                       ("price on the curve, from chained forwards", chain_price),
                       ("market price, the dealer's quote", QUOTE),
                       ("price gap, curve minus market", curve_price - QUOTE)] {
        println!("{:<45}{:>12.6}", label, v);
    }
    println!("{:<45}{:>12.4} bp", "z-spread, bisection", z_bisect * 10000.0);
    println!("{:<45}{:>12.4} bp", "z-spread, Newton", z_newton * 10000.0);
    for (label, v) in [("the bond repriced at the z-spread", price(z_bisect, CPN, false)),
                       ("floating leg, par minus the final factor", float_par),
                       ("floating leg, forward by forward", float_fwd),
                       ("annuity, the discount factors added up", annuity)] {
        println!("{:<45}{:>12.6}", label, v);
    }
    println!("{:<45}{:>12.4} bp", "asset-swap spread, closed form", asw * 10000.0);
    println!("{:<45}{:>12.4} bp", "asset-swap spread, package solved to zero", asw_pkg * 10000.0);
    println!("{:<45}{:>12.4}% {:.4}%", "the bond yield, continuous then annual", ytm * 100.0, ytm_annual * 100.0);
    println!();
    println!("as the card quotes them: curve {:.2}, market {:.2}, gap {:.2}, z {:.2} bp, asw {:.2} bp",
             curve_price, QUOTE, curve_price - QUOTE, z_bisect * 10000.0, asw * 10000.0);
    println!();
    println!("what breaks");
    println!("{:<45}{:>12.4} bp", "spread over the 5-year zero rate alone", flat_z * 10000.0);
    println!("I-spread, yield {:.4}% less par rate {:.4}%{:>12.4} bp",
             ytm_annual * 100.0, par_rate * 100.0, (ytm_annual - par_rate) * 10000.0);
    println!("{:<45}{:>12.4} bp", "asset-swap annuity discounted with the spread", asw_risky * 10000.0);
    println!("{:<45}{:>12.4} bp", "the same z-spread on an 8% coupon bond, asw", asw8 * 10000.0);
    println!();
    println!("how the price moves when the spread moves");
    println!("{:<45}{:>12.4}", "price slope, minus dP/dz at the quote", -slope(z_bisect, CPN));
    println!("{:<45}{:>12.6}", "price given up per basis point of widening", -slope(z_bisect, CPN) / 10000.0);
    println!("{:<45}{:>12.6}, a drop of {:.6}", "widen the spread by 100 bp: price",
             widened, price(z_bisect, CPN, false) - widened);
    println!();
    let row = |label: &str, cells: String| println!("{:<32}{}", label, cells);
    row("chart, spread in basis points", bps.iter().map(|b| format!("{:>8}", b)).collect());
    row("chart, price", prices.iter().map(|p| format!("{:>8.2}", p)).collect());
    row("chart, the market quote", bps.iter().map(|_| format!("{:>8.2}", QUOTE)).collect());
    row("bars, price given up per 100 face",
        prices.iter().map(|p| format!("{:>8.2}", curve_price - p)).collect());
    row("chart, coupon in percent", coupons.iter().map(|c| format!("{:>8.2}", c)).collect());
    row("chart, asset-swap spread in bp",
        asw_curve.iter().map(|a| format!("{:>8.2}", a * 10000.0)).collect());
    row("chart, z-spread in bp",
        coupons.iter().map(|_| format!("{:>8.2}", z_bisect * 10000.0)).collect());
    println!();
    println!("try changing");
    println!("{:<45}{:>12.4} bp", "quote 94.733 instead of 94.833: z-spread",
             bisect(|s| price(s, CPN, false) - 94.733, -0.5, 1.0) * 10000.0);
    println!("{:<45}{:>12.4} bp", "quote 101.000, a bond richer than the curve",
             bisect(|s| price(s, CPN, false) - 101.000, -0.5, 1.0) * 10000.0);
    println!("{:<45}{:>12.4} bp", "every zero rate flattened to 3.9000%: z", flat_z * 10000.0);
    assert!((curve_price - chain_price).abs() < 1e-10);      // zero rates against chained forwards
    assert!((z_bisect - z_newton).abs() < 1e-12);            // bisection against Newton
    assert!((float_par - float_fwd).abs() < 1e-10);          // par identity against forward by forward
    assert!((asw - asw_pkg).abs() < 1e-12);                  // closed form against the package priced out
    assert!((price(z_bisect, CPN, false) - QUOTE).abs() < 1e-9);   // the spread reprices the bond
    println!("ALL CHECKS PASS");
}
