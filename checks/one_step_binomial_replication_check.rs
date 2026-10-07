// One-step binomial replication -- the same check as the Python, in Rust.  No
// crates.  Acme: S = 100, K = 100, one year, r = 5%, q = 2%, sigma = 20%, so
// the share ends at 122.14 or 81.87.  The holding and the bank balance that
// copy the call are found four ways: elimination; a bisection that never
// divides by u - d; the regrouped weights; exact fractions on a toy market.
const S: f64 = 100.0;
const K: f64 = 100.0;
const R: f64 = 0.05;
const Q: f64 = 0.02;
const SIGMA: f64 = 0.20;
const T: f64 = 1.0;

fn reduced(n: i64, m: i64) -> (i64, i64) {          // a fraction in lowest terms
    let (mut a, mut b) = (n.abs(), m.abs());
    while b != 0 { (a, b) = (b, a % b) }
    (n / a, m / a)
}

fn clean(v: f64) -> f64 {                           // a residue below a billionth is zero
    if v.abs() < 1e-9 { 0.0 } else { v }
}

fn row(name: &str, v: f64) {
    println!("  {:<43}{:>12.6}", name, v);
}

fn main() {
    let u = (SIGMA * T.sqrt()).exp();               // up factor: one year of 20% jumpiness
    let d = 1.0 / u;                                // down factor
    let (disc, grow) = ((-R * T).exp(), (R * T).exp());   // the bank, backward and forward
    let drag = (-Q * T).exp();                      // shares to buy today to hold one at delivery
    let (su, sd) = (S * u, S * d);                  // the two delivery prices
    let (hu, hd) = ((su - K).max(0.0), (sd - K).max(0.0));   // the call's two payoffs
    let solved = |hu: f64, hd: f64, s: f64, uu: f64, dd: f64| -> (f64, f64) {
        ((hu - hd) / (s * (uu - dd)), disc * (uu * hd - dd * hu) / (uu - dd))
    };                                              // road 1: subtract, then substitute
    let cost = |delta: f64, bank: f64, s: f64| delta * s * drag + bank;
    let bank_for_down = |delta: f64| (hd - delta * sd) * disc;   // matches the down state alone
    let up_shortfall = |delta: f64| delta * su + bank_for_down(delta) * grow - hu;
    let bisect = |f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64| -> f64 {
        for _ in 0..200 {                           // road 2: a search, written out here
            let mid = 0.5 * (lo + hi);
            if (f(lo) > 0.0) == (f(mid) > 0.0) { lo = mid } else { hi = mid }
        }
        0.5 * (lo + hi)
    };

    let (delta, bank) = solved(hu, hd, S, u, d);
    let v = cost(delta, bank, S);
    let (copy_up, copy_down) = (delta * su + bank * grow, delta * sd + bank * grow);
    let delta_b = bisect(&up_shortfall, 0.0, 2.0);                    // road 2
    let v_b = cost(delta_b, bank_for_down(delta_b), S);
    let fwd = ((R - Q) * T).exp();                                    // the forward's growth factor
    let (w_up, w_down) = ((fwd - d) / (u - d), (u - fwd) / (u - d));  // road 3
    let v_w = disc * (w_up * hu + w_down * hd);
    let (d80, b80) = solved((su - 80.0).max(0.0), (sd - 80.0).max(0.0), S, u, d);  // both states pay
    let sold = 11.50_f64;                                             // a call sold too dear
    let banked = sold - v;
    let arb_up = copy_up - hu + banked * grow;
    let arb_down = copy_down - hd + banked * grow;
    let spread = delta * drag * 0.20;                                 // a 20-cent wider share price
    let (un, dn, ud, rn, rd, s0, hu0) = (6_i64, 4, 5, 21, 20, 100, 20);   // road 4: the toy market
    let (dl_n, dl_d) = reduced(hu0 * ud, s0 * (un - dn));
    let (cs_n, cs_d) = reduced(-dn * hu0 * rd, rn * (un - dn));
    let (v_n, v_d) = reduced(dl_n * s0 * cs_d + cs_n * dl_d, dl_d * cs_d);
    let wrong_gap = (hu - hd) / (u - d);                              // share price left out
    let wrong_drag = delta * S + bank;                                // a whole share per Delta
    let wrong_face = delta * S * drag + (u * hd - d * hu) / (u - d);  // the debt at face value
    let sx = S * drag;
    let (dx, bx) = solved((sx * u - K).max(0.0), (sx * d - K).max(0.0), sx, u, d);
    let wrong_twice = (dx * sx + bx) * drag;                          // dividend taken out twice
    let wrong_coin = disc * 0.5 * (hu + hd);                          // a fair coin, not a hedge

    println!("Acme: S = {:.2}  K = {:.2}  T = {:.0} year  r = 5%  q = 2%  sigma = 20%", S, K, T);
    row("up factor u = e^(sigma sqrt T)", u);
    row("down factor d = 1/u", d);
    row("share at delivery, up state", su);
    row("share at delivery, down state", sd);
    row("the gap between the two, S u - S d", su - sd);
    row("call payoff, up state", hu);
    row("call payoff, down state", hd);
    println!("  bank growth e^rT {:.6}, discount e^-rT {:.6}, dividend drag e^-qT {:.6}",
             grow, disc, drag);
    println!("road 1, the two delivery equations solved");
    row("Delta, shares held at delivery", delta);
    row("shares bought today, Delta e^-qT", delta * drag);
    row("the share leg costs today", delta * S * drag);
    row("B, cash in the bank today", bank);
    row("the debt at delivery, B e^rT", bank * grow);
    row("V, what the pair costs today", v);
    row("the copy at delivery, up state", clean(copy_up));
    row("the call pays, up state", hu);
    row("the copy at delivery, down state", clean(copy_down));
    row("the call pays, down state", hd);
    println!("road 2, bisection for Delta, no formula used");
    row("Delta", delta_b);
    row("V", v_b);
    println!("road 3, the two payoffs regrouped as weights");
    row("weight on the up payoff", w_up);
    row("weight on the down payoff", w_down);
    row("the two weights add to", w_up + w_down);
    row("V", v_w);
    row("the weights price the share itself", disc * (w_up * su + w_down * sd));
    println!("the band: d {:.6} < forward factor {:.6} < u {:.6}", d, fwd, u);
    println!("sell the call at {:.2} and build the copy", sold);
    row("banked today", banked);
    row("at delivery, up state", arb_up);
    row("at delivery, down state", arb_down);
    row("a 0.20 wider share price costs", spread);
    println!("road 4, whole-number fractions, toy market u = 6/5, d = 4/5, bank x 21/20");
    println!("  Delta = {}/{}   cash = {}/{}   cost = {}/{} = {:.6}",
             dl_n, dl_d, cs_n, cs_d, v_n, v_d, v_n as f64 / v_d as f64);
    println!("hedge ratio by strike, shares at delivery per call");
    for strike in [80.0_f64, 90.0, 100.0, 110.0, 120.0, 130.0] {
        row(&format!("strike {:.0}", strike),
            ((su - strike).max(0.0) - (sd - strike).max(0.0)) / (S * (u - d)));
    }
    println!("what breaks");
    row("payoff gap over factor gap, shares", wrong_gap);
    row("dividend ignored on the share leg", wrong_drag);
    row("the debt borrowed at its face value", wrong_face);
    row("the dividend taken out twice", wrong_twice);
    row("a fair coin instead of the hedge", wrong_coin);
    let grid = [70.0_f64, 80.0, 90.0, 100.0, 110.0, 120.0, 130.0];
    let join = |vals: Vec<String>| vals.join(" ");
    println!("chart, delivery price   {}",
             join(grid.iter().map(|x| format!("{:6.2}", x)).collect()));
    println!("chart, the copy         {}",
             join(grid.iter().map(|x| format!("{:6.2}", delta * x + bank * grow)).collect()));
    println!("chart, the call's payoff{}",
             join(grid.iter().map(|x| format!("{:6.2}", (x - K).max(0.0))).collect()));

    assert!((v - 11.073540703840).abs() < 1e-9);      // the cost the card quotes
    assert!((copy_up - hu).abs() < 1e-9);             // the copy really pays the call, up state
    assert!((copy_down - hd).abs() < 1e-9);           // and down
    assert!((d80 - 1.0).abs().max((b80 + 80.0 * disc).abs()) < 1e-10);  // both states clear 80
    assert!((v_b - v).abs() < 1e-10);                 // the search lands on the solved road
    assert!((v_w - v).abs() < 1e-12);                 // the weights land there too
    assert!((disc * (w_up * su + w_down * sd) - S * drag).abs() < 1e-10);  // and price the share
    assert!((arb_up - arb_down).abs() < 1e-12);       // a mispriced call pays the same either way
    assert!(arb_up > 0.0);                            // and the difference is a gain out of nothing
    assert!(d < fwd && fwd < u);                      // the band that makes a cost a price
    assert!((v_n, v_d) == (250, 21));                 // the toy market, in exact fractions
    println!("ALL CHECKS PASS");
}
