// State prices and risk-neutral pricing in one period -- the same check as the
// Python, in Rust.  No crates.  Acme is 100.00 today; in a year it is 120.00 or
// 90.00, and a dollar in the bank becomes 1.05.  Every price below is reached
// by roads that meet only at the answer: the two tickets, a share-and-cash copy,
// the fake coin, whole numbers over 21, and 200,000 flips of a built coin.
const S0: f64 = 100.0;
const SU: f64 = 120.0;
const SD: f64 = 90.0;
const R: f64 = 1.05;
const P_UP: f64 = 0.7;
const D: f64 = 1.0 / R;                            // today's price of a sure dollar
const FLIPS: u64 = 200000;
const SEED: u64 = 20260914;
const TWO32: f64 = 4294967296.0;

fn solve2(a11: f64, a12: f64, a21: f64, a22: f64, b1: f64, b2: f64) -> (f64, f64) {
    let det = a11 * a22 - a12 * a21;               // 2x2 solve, Cramer's rule
    ((b1 * a22 - a12 * b2) / det, (a11 * b2 - b1 * a21) / det)
}

fn tickets() -> (f64, f64) { solve2(SU, SD, 1.0, 1.0, S0, D) }   // road 1

fn by_tickets(hu: f64, hd: f64) -> f64 {           // road 1, applied to any payoff
    let (pu, pd) = tickets();
    pu * hu + pd * hd
}

fn by_copy(hu: f64, hd: f64) -> (f64, f64, f64) {  // road 2: shares and cash
    let (delta, cash) = solve2(SU, R, SD, R, hu, hd);
    (delta, cash, delta * S0 + cash)
}

fn q_up() -> f64 { (R * S0 - SD) / (SU - SD) }     // road 3: the fake coin

fn by_coin(hu: f64, hd: f64) -> f64 { D * (q_up() * hu + (1.0 - q_up()) * hd) }

fn coin_flips(threshold: u64) -> u64 {             // road 5: a coin built from scratch
    let (mut x, mut ups) = (SEED, 0u64);
    for _ in 0..FLIPS {
        x = x.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        if (x >> 32) < threshold { ups += 1 }
    }
    ups
}

fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn row(label: &str, value: f64) { println!("  {:<40}{:>11.6}", label, value) }

fn main() {
    let (psi_u, psi_d) = tickets();
    let (q_u, q_d) = (q_up(), 1.0 - q_up());
    // road 4: whole numbers only.  The bank turns 20 into 21, so a sure dollar
    // costs 20/21 and both ticket prices can be written over that same 21.
    let (su_i, sd_i, s0_i, num, den): (i64, i64, i64, i64, i64) = (120, 90, 100, 20, 21);
    let det_i = su_i - sd_i;
    let (a_num, b_num) = (s0_i * den - sd_i * num, su_i * num - s0_i * den);
    let (a_i, b_i) = (a_num / det_i, b_num / det_i);         // 21 x each ticket price
    let (call_i, put_i) = (a_i * 20, b_i * 10);              // 21 x each contract price

    let contracts: [(&str, f64, f64); 5] = [("call K=100", 20.0, 0.0), ("put K=100", 0.0, 10.0),
        ("forward K=105", 15.0, -15.0), ("one share", 120.0, 90.0), ("sure dollar", 1.0, 1.0)];
    let (call_p, put_p) = (by_copy(20.0, 0.0).2, by_copy(0.0, 10.0).2);
    let (du, cu, ku) = by_copy(1.0, 0.0);
    let (dd, cd, kd) = by_copy(0.0, 1.0);
    let eq_s1 = q_u * SU + q_d * SD;
    let ep_s1 = P_UP * SU + (1.0 - P_UP) * SD;
    let (ups_q, ups_p) = (coin_flips((q_u * TWO32) as u64), coin_flips((P_UP * TWO32) as u64));
    let mc_q = D * (ups_q as f64 / FLIPS as f64) * 20.0;
    let mc_p = D * (ups_p as f64 / FLIPS as f64) * 20.0;
    let naive_bank = D * (P_UP * 20.0 + (1.0 - P_UP) * 0.0);      // real odds, bank rate
    let naive_share = (P_UP * 20.0) / (ep_s1 / S0);               // real odds, Acme's own return
    let no_discount = q_u * 20.0 + q_d * 0.0;                     // fake coin, forgot to discount
    let needed_rate = ((P_UP * 20.0) / call_p - 1.0) * 100.0;     // the only real-odds rate that works
    let r_high = 1.25;                                            // a bank that beats Acme everywhere
    let psi_hi_u = (r_high * S0 - SD) / ((SU - SD) * r_high);
    let psi_hi_d = (SU - r_high * S0) / ((SU - SD) * r_high);
    let (free_up, free_dn) = (S0 * r_high - SU, S0 * r_high - SD);
    let grid: Vec<f64> = (0..9).map(|i| (85 + 5 * i) as f64 / 100.0).collect();
    let band: Vec<(f64, f64)> = grid.iter()
        .map(|&g| ((g * S0 - SD) / ((SU - SD) * g), (SU - g * S0) / ((SU - SD) * g))).collect();

    println!("market: Acme {:.2} today, {:.2} up or {:.2} down; bank 1.00 -> {:.2}", S0, SU, SD, R);
    println!("the two tickets, from the two prices the market already quotes");
    row(&format!("up ticket, pays 1.00 if Acme is {:.2}", SU), psi_u);
    row(&format!("down ticket, pays 1.00 if Acme is {:.2}", SD), psi_d);
    row("the two together, a sure dollar", psi_u + psi_d);
    row("a sure dollar the other way, 1 / 1.05", D);
    println!("  in whole numbers: up {}/{}, down {}/{}, sure dollar {}/{}", a_i, den, b_i, den, num, den);
    println!("the same two tickets, copied with shares and cash");
    println!("  up ticket   {:>10.6} shares and {:>10.6} cash, cost {:>10.6}", du, cu, ku);
    println!("  down ticket {:>10.6} shares and {:>10.6} cash, cost {:>10.6}", dd, cd, kd);
    println!("the fake coin: each ticket price divided by {:.6}", D);
    println!("  weight on up {:.6}, weight on down {:.6}, sum {:.6}", q_u, q_d, q_u + q_d);
    row("fake average of Acme in a year", eq_s1);
    row(&format!("the bank turning {:.2} into", S0), S0 * R);
    row(&format!("real average of Acme, up chance {:.2}", P_UP), ep_s1);
    println!("  that is a real return of {:.2} percent, against the bank's 5.00",
             (ep_s1 / S0 - 1.0) * 100.0);
    println!();
    println!("{:<16}{:>10}{:>11}{:>12}{:>12}{:>12}", "contract", "pays up", "pays down",
             "tickets", "copy", "fake coin");
    for (name, hu, hd) in contracts.iter() {
        println!("{:<16}{:>10.2}{:>11.2}{:>12.6}{:>12.6}{:>12.6}", name, hu, hd,
                 by_tickets(*hu, *hd), by_copy(*hu, *hd).2, by_coin(*hu, *hd));
    }
    println!("call minus put {:.6}, and Acme minus 100 sure dollars {:.6}",
             call_p - put_p, S0 - 100.0 * D);
    println!("in whole numbers: call {}/{}, put {}/{}, difference {}/{}",
             call_i, den, put_i, den, call_i - put_i, den);
    println!();
    println!("the coin flipped {} times by the script's own generator, seed {}", FLIPS, SEED);
    println!("  fake coin, weight {:.2}: up {} times, share {:.6}, call {:>9.6} against {:.6}",
             q_u, ups_q, ups_q as f64 / FLIPS as f64, mc_q, call_p);
    println!("  real coin, chance {:.2}: up {} times, share {:.6}, call {:>9.6} against {:.6}",
             P_UP, ups_p, ups_p as f64 / FLIPS as f64, mc_p, call_p);
    println!();
    println!("what breaks, against the call's {:.6}", call_p);
    println!("  real odds, discounted at the bank's 5 percent   {:>10.6}", naive_bank);
    println!("  real odds, discounted at Acme's 11 percent      {:>10.6}", naive_share);
    println!("  the fake coin with no discounting               {:>10.6}", no_discount);
    println!("  the only rate that makes real odds work         {:>10.6} percent", needed_rate);
    println!("  bank at 25 percent: up ticket {:.6}, down ticket {:.6}", psi_hi_u, psi_hi_d);
    println!("    free money there: sell one share, lend {:.2}; up {:.2}, down {:.2}",
             S0, free_up, free_dn);
    println!();
    let mut l1 = String::from("chart, bank factor  ");
    let mut l2 = String::from("chart, up ticket    ");
    let mut l3 = String::from("chart, down ticket  ");
    let mut l4 = String::from("chart, both positive");
    for (g, p) in grid.iter().zip(band.iter()) {
        l1.push_str(&format!("{:>7.2}", g));
        l2.push_str(&format!("{:>7.2}", p.0));
        l3.push_str(&format!("{:>7.2}", p.1));
        l4.push_str(&format!("{:>7}", yn(p.0 > 0.0 && p.1 > 0.0)));
    }
    for l in [l1, l2, l3, l4] { println!("{}", l) }
    println!("bars, the call four ways: {:.2}, {:.2}, {:.2}, {:.2}",
             call_p, no_discount, naive_share, naive_bank);

    assert!((num as f64 / den as f64 - D).abs() < 1e-15, "the whole-number road's sure dollar against 1 / R");
    assert!((psi_u - a_i as f64 / den as f64).abs() < 1e-12, "float solve against whole numbers, up");
    assert!((psi_d - b_i as f64 / den as f64).abs() < 1e-12, "float solve against whole numbers, down");
    assert!((by_tickets(20.0, 0.0) - call_p).abs() < 1e-12, "tickets against the share-and-cash copy");
    assert!((by_coin(20.0, 0.0) - call_p).abs() < 1e-12, "fake coin against the share-and-cash copy");
    assert!((mc_q - call_p).abs() < 0.05, "200,000 flips of the fake coin land on the price");
    assert!(((call_p - put_p) - (S0 - 100.0 * D)).abs() < 1e-12, "call minus put against Acme minus cash");
    assert!((eq_s1 - S0 * R).abs() < 1e-12, "under the fake coin Acme earns the bank rate");
    assert!((naive_bank - 40.0 / 3.0).abs() < 1e-12, "the real-odds answer, by an independent fraction");
    for (g, p) in grid.iter().zip(band.iter()) {
        assert!((p.0 > 0.0 && p.1 > 0.0) == (SD / S0 < *g && *g < SU / S0),
                "positive tickets = no free money");
    }
    println!("ALL CHECKS PASS");
}
