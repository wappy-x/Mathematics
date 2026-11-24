// Treasury bond futures: conversion factors, the cheapest to deliver, the implied
// repo rate and the switch option -- the same check as the Python, in Rust.  No crates.
// Three bonds deliverable on 15 June 2027 (a coupon date for all three); today is
// 15 March 2027, a quarter of a year earlier.  Flat curve at 5%, repo 4.50%.
// Roads: conversion factor by summing cash flows and by the closed form; cash price
// today two ways; implied repo by formula and by bisection on the net basis; cheapest
// by implied repo and by net basis; the 6% crossing by bisection on closed-form prices;
// switch option by quadrature and by simulation; futures DV01 by formula and by bumping.
use std::f64::consts::PI;

const BONDS: [(&str, f64, i32); 3] = [("4% 10-year", 4.0, 20), ("5% 15-year", 5.0, 30), ("6.5% 25-year", 6.5, 50)];
const Y: f64 = 0.05; const REPO: f64 = 0.045; const T: f64 = 0.25; // yield, repo, years to delivery
const F: f64 = 108.0 + 4.0 / 32.0; // quote 108-04

fn price_sum(c: f64, n: i32, y: f64) -> f64 { // clean price per 100 face on a coupon date: add every payment
    let v = 1.0 / (1.0 + y / 2.0);
    let mut p = 0.0;
    for k in 1..=n { p += c / 2.0 * v.powf(k as f64); }
    p + 100.0 * v.powf(n as f64)
}
fn price_closed(c: f64, n: i32, y: f64) -> f64 { // the same price by the annuity closed form
    let v = 1.0 / (1.0 + y / 2.0);
    c / 2.0 * (1.0 - v.powf(n as f64)) / (y / 2.0) + 100.0 * v.powf(n as f64)
}
fn dv01(c: f64, n: i32, y: f64) -> f64 { // price fall for one basis point, from the derivative
    let v = 1.0 / (1.0 + y / 2.0);
    let mut d = 0.0;
    for k in 1..=n { d += k as f64 * (c / 2.0) * v.powf((k + 1) as f64); }
    (d + n as f64 * 100.0 * v.powf((n + 1) as f64)) / 2.0 / 10000.0
}
fn bisect(g: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // the root, by halving
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (g(lo) > 0.0) == (g(mid) > 0.0) { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn row(name: &str, xs: &[f64], dp: usize) {
    let cells: String = xs.iter().map(|x| format!("{:14.*}", dp, x)).collect();
    println!("{:<24}{}", name, cells);
}
fn ratios(y: f64, cf: &[f64]) -> Vec<f64> {
    BONDS.iter().enumerate().map(|(i, b)| price_sum(b.1, b.2, y) / cf[i]).collect()
}
fn vmin(q: &[f64]) -> f64 { q.iter().cloned().fold(f64::INFINITY, f64::min) }
fn argmin(q: &[f64]) -> usize { let m = vmin(q); q.iter().position(|&x| x == m).unwrap() }

fn option_quad(sd: f64, cf: &[f64]) -> (f64, f64, f64, f64, usize) { // midpoint rule over the normal density
    let m = 4000;
    let (lo, w) = (-8.0 * sd, 16.0 * sd / m as f64);
    let (mut ev, mut emin, mut pswitch) = (vec![0.0; 3], 0.0, 0.0);
    for j in 0..m {
        let d = lo + (j as f64 + 0.5) * w;
        let p = (-d * d / (2.0 * sd * sd)).exp() / (sd * (2.0 * PI).sqrt()) * w;
        let q = ratios(Y + d, cf);
        for i in 0..3 { ev[i] += p * q[i]; }
        emin += p * vmin(&q);
        if vmin(&q) < q[0] { pswitch += p; }
    }
    (vmin(&ev) - emin, vmin(&ev), emin, pswitch, argmin(&ev))
}

fn option_sim(sd: f64, cf: &[f64]) -> (f64, f64, f64) { // same value by simulation: own generator, Box-Muller
    let paths = 100000;
    let mut s: u64 = 88172645463325252;
    let (mut tot, mut tot2, mut sw) = (0.0, 0.0, 0u32);
    let mut u = || {
        s = s.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((s >> 11) as f64 + 0.5) / 9007199254740992.0
    };
    for _ in 0..paths {
        let (u1, u2) = (u(), u());
        let d = sd * (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
        let q = ratios(Y + d, cf);
        let g = q[0] - vmin(&q); // what switching away from the 10-year saves on this path
        tot += g; tot2 += g * g;
        if g > 0.0 { sw += 1; }
    }
    let mean = tot / paths as f64;
    (mean, ((tot2 / paths as f64 - mean * mean) / paths as f64).sqrt(), sw as f64 / paths as f64)
}

fn main() {
    let cf: Vec<f64> = BONDS.iter().map(|b| price_sum(b.1, b.2, 0.06) / 100.0).collect();
    let cf_closed: Vec<f64> = BONDS.iter().map(|b| price_closed(b.1, b.2, 0.06) / 100.0).collect();
    println!("bond                    {}", BONDS.iter().map(|b| format!("{:>14}", b.0)).collect::<String>());
    row("CF, payments added", &cf, 6);
    row("CF, closed form", &cf_closed, 6);
    row("CF, exchange, 4 decimals", &cf, 4);
    let (mut dirty, mut ai0, mut coup, mut nb, mut irr, mut irr_b, mut gross, mut carry) =
        (vec![], vec![], vec![], vec![], vec![], vec![], vec![], vec![]);
    for (i, b) in BONDS.iter().enumerate() {
        let (c, n) = (b.1, b.2);
        let at_delivery = price_sum(c, n, Y) + c / 2.0;           // value on 15 June, coupon included
        dirty.push(at_delivery / (1.0 + Y / 2.0).powf(0.5));     // discounted back half a coupon period
        ai0.push(c / 4.0); coup.push(c / 2.0);                   // accrued today; coupon paid on 15 June
        let clean = dirty[i] - ai0[i];
        gross.push(clean - F * cf[i]);
        carry.push(coup[i] - ai0[i] - dirty[i] * REPO * T);      // accrued at delivery is zero
        nb.push(gross[i] - carry[i]);
        irr.push(((F * cf[i] + coup[i]) / dirty[i] - 1.0) / T);
        let (di, ki, fi) = (dirty[i], coup[i], F * cf[i]);
        irr_b.push(bisect(&|r| di * (1.0 + r * T) - ki - fi, -1.0, 1.0));
    }
    let dirty_flows: Vec<f64> = BONDS.iter().map(|b| (0..=b.2).map(|k| // road 2: each payment discounted for its own time
        (b.1 / 2.0 + if k == b.2 { 100.0 } else { 0.0 }) / (1.0 + Y / 2.0).powf(k as f64 + 0.5)).sum()).collect();
    let pc = |v: &Vec<f64>| v.iter().map(|r| 100.0 * r).collect::<Vec<f64>>();
    row("clean price today", &(0..3).map(|i| dirty[i] - ai0[i]).collect::<Vec<_>>(), 4);
    row("accrued today", &ai0, 4);
    row("cash paid today", &dirty, 4);
    row("invoice at 108-04", &cf.iter().map(|x| F * x).collect::<Vec<_>>(), 4);
    row("coupon on 15 June", &coup, 4);
    row("gross basis", &gross, 4);
    row("carry to delivery", &carry, 4);
    row("net basis", &nb, 4);
    row("net basis, identity", &(0..3).map(|i| dirty[i] * T * (REPO - irr[i])).collect::<Vec<_>>(), 4);
    row("implied repo, formula %", &pc(&irr), 4);
    row("implied repo, bisect %", &pc(&irr_b), 4);
    row("forward price / CF", &(0..3).map(|i| (dirty[i] * (1.0 + REPO * T) - coup[i]) / cf[i]).collect::<Vec<_>>(), 4);
    let ctd_r = argmin(&irr.iter().map(|r| -r).collect::<Vec<_>>());
    let ctd_b = argmin(&nb);
    println!("cheapest by implied repo: {};  by net basis: {}", BONDS[ctd_r].0, BONDS[ctd_b].0);

    println!("\ndelivery yield %   price/CF:  10-year  15-year  25-year   cheapest");
    for k in 0..9 {
        let yd = 0.03 + 0.005 * k as f64;
        let q = ratios(yd, &cf);
        let spread = q.iter().cloned().fold(f64::NEG_INFINITY, f64::max) - vmin(&q);
        let name = if spread < 1e-9 { "all equal" } else { BONDS[argmin(&q)].0 };
        println!("{:13.1} {:10}{}   {}", 100.0 * yd, "", q.iter().map(|x| format!("{:9.2}", x)).collect::<String>(), name);
    }
    let ystar = bisect(&|y| price_closed(4.0, 20, y) / cf[0] - price_closed(6.5, 50, y) / cf[2], 0.03, 0.09);
    println!("10-year and 25-year lines cross at {:.6}% (closed-form prices, bisection)", 100.0 * ystar);

    let (val, best_mean, mean_min, psw, best) = option_quad(0.005, &cf);
    let (sim, se, psw_sim) = option_sim(0.005, &cf);
    println!("\nswitch option, move SD 50 bp: quadrature {:.4}, simulation {:.4} (+/- {:.4})", val, sim, se);
    println!("  lowest average price/CF {:.4} ({}), average of cheapest {:.4}", best_mean, BONDS[best].0, mean_min);
    println!("  net basis of the 10-year in futures points: {:.4}", nb[0] / cf[0]);
    println!("  chance the cheapest switches: quadrature {:.2}%, simulation {:.2}%", 100.0 * psw, 100.0 * psw_sim);
    println!("  move SD 75 bp: {:.4};  SD 100 bp: {:.4}", option_quad(0.0075, &cf).0, option_quad(0.01, &cf).0);

    let d_ctd = dv01(4.0, 20, Y);
    let bump = (vmin(&ratios(Y - 0.0001, &cf)) - vmin(&ratios(Y + 0.0001, &cf))) / 2.0;
    println!("\nCTD DV01 per 100 at 5%: {:.6};  / CF = {:.6};  bumped futures {:.6}", d_ctd, d_ctd / cf[0], bump);
    println!("futures DV01 per 100,000 contract: {:.2} dollars", 1000.0 * d_ctd / cf[0]);
    println!("try: quote 107-04, implied repo of the 10-year {:.4}%", 100.0 * ((107.125 * cf[0] + 2.0) / dirty[0] - 1.0) / T);
    println!("try: repo 5.50%, net basis of the 10-year {:.4}", dirty[0] * T * (0.055 - irr[0]));

    let lowest = argmin(&BONDS.iter().map(|b| price_sum(b.1, b.2, 0.065)).collect::<Vec<_>>());
    println!("\nwrong: cheapest by lowest price at 6.5%: {}", BONDS[lowest].0);
    println!("wrong: implied repo without the coupon {:.4}%", 100.0 * ((F * cf[0]) / dirty[0] - 1.0) / T);
    println!("wrong: implied repo on the clean price {:.4}%", 100.0 * ((F * cf[0] + 2.0) / (dirty[0] - 1.0) - 1.0) / T);
    println!("wrong: futures DV01 = CTD DV01 {:.6}", d_ctd);

    assert!((0..3).all(|i| (cf[i] - cf_closed[i]).abs() < 1e-12), "two roads to each CF");
    assert!((0..3).all(|i| (irr[i] - irr_b[i]).abs() < 1e-10), "implied repo: formula = bisection");
    assert!((0..3).all(|i| (gross[i] - carry[i] - dirty[i] * T * (REPO - irr[i])).abs() < 1e-10));
    assert!(ctd_r == 0 && ctd_b == 0, "highest implied repo and lowest net basis pick the same bond");
    assert!((0..3).all(|i| (dirty[i] - dirty_flows[i]).abs() < 1e-9), "cash price today: two roads");
    let card_cf = [0.851225, 0.901998, 1.064324];
    assert!((0..3).all(|i| ((cf[i] * 1e6).round() / 1e6 - card_cf[i]).abs() < 1e-12), "the factors quoted on the card");
    assert!((ystar - 0.06).abs() < 1e-9 && BONDS.iter().enumerate()
        .all(|(i, b)| (price_closed(b.1, b.2, ystar) / cf[i] - 100.0).abs() < 1e-7), "all three tie at 6%");
    assert!(argmin(&ratios(0.065, &cf)) == 2, "+150 bp switches to the 25-year");
    assert!(best == 0 && (sim - val).abs() < 4.0 * se, "simulation agrees with quadrature");
    assert!((psw - 0.02275).abs() < 1e-3, "switch beyond +100 bp: two SDs, 2.28%");
    assert!((bump - d_ctd / cf[0]).abs() < 1e-6, "futures DV01 = CTD DV01 / CF");
    println!("ALL CHECKS PASS");
}
