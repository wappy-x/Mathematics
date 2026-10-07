// The spread -- the check behind the card.  Rust std only, no crates.
// Glosten-Milgrom: quotes from Bayes' rule.  Roll: a spread read off trade prices.
// Money in cents.  Acme is worth 9980 or 10020 cents; 10% of traders know which.
use std::collections::HashMap;

const LO: f64 = 9980.0; const HI: f64 = 10020.0; const PRIOR: f64 = 0.5; const MU: f64 = 0.10;

fn closed(prior: f64, mu: f64, gap: f64) -> f64 { // road 1: the formula on the card
    let d = 2.0 * prior - 1.0;
    gap * 4.0 * mu * prior * (1.0 - prior) / (1.0 - mu * mu * d * d)
}

// road 2: add up the four cells (value high or low) x (buy or sell)
fn quotes(prior: f64, mu: f64) -> (f64, f64, f64, f64) {
    let cell = |w: f64, knows: bool| w * ((if knows { mu } else { 0.0 }) + (1.0 - mu) / 2.0);
    let (hbuy, hsell) = (cell(prior, true), cell(prior, false));
    let (lbuy, lsell) = (cell(1.0 - prior, false), cell(1.0 - prior, true));
    let (pb, ps) = (hbuy + lbuy, hsell + lsell);
    let ask = (HI * hbuy + LO * lbuy) / pb;
    let bid = (HI * hsell + LO * lsell) / ps;
    (bid, ask, hbuy / pb, hsell / ps)
}

struct Rng(u64); // splitmix64, written out
impl Rng {
    fn u(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn show(label: &str, vals: &[f64]) {
    let mut s = format!("{:<34}", label);
    for v in vals { s += &format!("{:>13.6}", v); }
    println!("{}", s);
}

fn belief(d: i64) -> f64 { // P(high) after d more buys than sells
    let mut x = 1.0;
    for _ in 0..d.abs() { x *= 9.0 / 11.0; }
    if d >= 0 { 1.0 / (1.0 + x) } else { x / (1.0 + x) }
}

fn main() {
    let (gap, (bid, ask, hb, hs)) = (HI - LO, quotes(PRIOR, MU));
    let s1 = closed(PRIOR, MU, gap);
    show("1 formula: spread", &[s1]);
    show("2 Bayes cells: bid, ask", &[bid, ask]);
    show("  P(high | buy), P(high | sell)", &[hb, hs]);
    let (take, pay) = (MU * (gap / 2.0 - s1 / 2.0), (1.0 - MU) * s1 / 2.0);
    show("3 informed take, uninformed pay", &[take, pay]);
    assert!(((ask - bid) - s1).abs() < 1e-9, "Bayes cells must match the formula");
    assert!((take - pay).abs() < 1e-12, "the books must balance at the formula's spread");
    let (mut rng, n) = (Rng(2026), 200_000);
    let (mut prof, mut naive, mut vbuy, mut nbuy) = (0.0, 0.0, 0.0, 0u64);
    for _ in 0..n { // road 4: simulate one-trade rounds
        let high = rng.u() < PRIOR; let v = if high { HI } else { LO };
        let buy = if rng.u() < MU { high } else { rng.u() < 0.5 };
        if buy { prof += ask - v; naive += 10000.0 - v; vbuy += v; nbuy += 1; }
        else { prof += v - bid; naive += v - 10000.0; }
    }
    show("4 simulated E[V | buy], profit", &[vbuy / nbuy as f64, prof / n as f64]);
    assert!((vbuy / nbuy as f64 - ask).abs() < 0.3, "simulated E[V | buy] must land on the ask");
    show("wrong: quote 10000 both, sim/exact", &[naive / n as f64, -MU * gap / 2.0]);
    show("wrong: everyone informed", &[closed(PRIOR, 1.0, gap)]);
    let (b2, a2, _, _) = quotes(0.75, 0.2);
    show("try: prior 3/4, 20% informed", &[b2, a2, a2 - b2]);
    show("try: 50% informed; gap 100", &[closed(PRIOR, 0.5, gap), closed(PRIOR, MU, 100.0)]);
    let mus: Vec<f64> = (0..11).map(|i| i as f64 / 10.0).collect();
    let row = |f: &dyn Fn(f64) -> String| mus.iter().map(|&m| f(m)).collect::<Vec<_>>().join(" ");
    println!("chart, informed share      {}", row(&|m| format!("{:5.1}", m)));
    for p in [0.5, 0.75] {
        println!("chart, spread, prior {:<5}  {}", p, row(&|m| format!("{:5.2}", closed(p, m, gap))));
    }
    for p10 in 1..10 { // grid: formula = cells, rises with mu
        let mut last = -1.0;
        for &m in &mus {
            let (b, a, _, _) = quotes(p10 as f64 / 10.0, m);
            assert!(((a - b) - closed(p10 as f64 / 10.0, m, gap)).abs() < 1e-9, "cells must match the formula");
            assert!(a - b > last, "spread must rise with the informed share");
            last = a - b;
        }
    }
    println!("path: trade, side, bid-10000, ask-10000, spread, P(high)");
    let (mut prior, mut hb, mut hs) = (PRIOR, hb, hs);
    for (k, side) in " BBSBBBSBBB".chars().enumerate() {
        if side != ' ' { prior = if side == 'B' { hb } else { hs }; }
        let (b, a, nb, ns) = quotes(prior, MU);
        hb = nb; hs = ns;
        println!("  {:>2} {} {:9.2} {:9.2} {:9.2} {:9.4}", k, side, b - 10000.0, a - 10000.0, a - b, prior);
    }
    assert!((belief(6) - prior).abs() < 1e-12, "net buys must match trade-by-trade Bayes");
    let (checks, t_max) = ([0usize, 25, 50, 100, 200, 400], 400usize);
    let (mut dist, mut exact): (HashMap<i64, f64>, [f64; 6]) = (HashMap::from([(0, 1.0)]), [0.0; 6]);
    for t in 0..=t_max { // exact: walk the distribution of d
        if let Some(i) = checks.iter().position(|&c| c == t) {
            exact[i] = dist.iter().map(|(&d, &p)| p * closed(belief(d), MU, gap)).sum();
        }
        let mut nxt: HashMap<i64, f64> = HashMap::new();
        for (&d, &p) in &dist {
            *nxt.entry(d + 1).or_insert(0.0) += p * (1.0 + MU) / 2.0;
            *nxt.entry(d - 1).or_insert(0.0) += p * (1.0 - MU) / 2.0;
        }
        dist = nxt;
    }
    let (days, mut sim) = (2000, [0.0f64; 6]);
    for _ in 0..days { // simulated: true value high, 2000 days
        let mut d: i64 = 0;
        for t in 0..=t_max {
            if let Some(i) = checks.iter().position(|&c| c == t) { sim[i] += closed(belief(d), MU, gap) / days as f64; }
            let buy = if rng.u() < MU { true } else { rng.u() < 0.5 };
            d += if buy { 1 } else { -1 };
        }
    }
    println!("expected spread after n trades, value high: exact, simulated");
    for i in 0..6 {
        println!("  after {:>3} trades {:9.2} {:9.2}", checks[i], exact[i], sim[i]);
        assert!((exact[i] - sim[i]).abs() < 0.1, "walk and simulation must agree");
    }

    for c in 0i64..5 { // Roll, exact: 32 equally likely cases
        let (mut tot, pm) = (0i64, [-1i64, 1]);
        for e1 in pm { for e0 in pm { for q2 in pm { for q1 in pm { for q0 in pm {
            tot += (e1 + c * (q2 - q1)) * (e0 + c * (q1 - q0));
        } } } } }
        assert_eq!(tot, -32 * c * c, "Roll: lag covariance must be -c^2");
        if c == 2 { show("Roll exact, c = 2: covariance", &[tot as f64 / 32.0]); }
    }
    let (mut m, mut p_prev, w) = (10000.0f64, 10002.0f64, 3.0f64.sqrt());
    let mut r: Vec<f64> = Vec::with_capacity(200_000);
    for _ in 0..200_000 { // Roll, simulated: c = 2, 1-cent news
        m += w * (2.0 * rng.u() - 1.0);
        let q = if rng.u() < 0.5 { 1.0 } else { -1.0 };
        let p = m + 2.0 * q;
        r.push(p - p_prev); p_prev = p;
    }
    let mean = r.iter().sum::<f64>() / r.len() as f64;
    let g = (1..r.len()).map(|t| (r[t] - mean) * (r[t - 1] - mean)).sum::<f64>() / (r.len() - 1) as f64;
    show("Roll simulated: covariance, spread", &[g, 2.0 * (-g).sqrt()]);
    assert!((2.0 * (-g).sqrt() - 4.0).abs() < 0.1, "Roll estimate must land near the 4-cent spread");
    show("wrong: forgot the 2", &[(-g).sqrt()]);
    let ch = [-2.0f64, -2.0, 2.0, 2.0]; // a short record: covariance positive
    show("short record: sample covariance", &[(1..4).map(|t| ch[t] * ch[t - 1]).sum::<f64>() / 3.0]);
    let mut noise = 0i64; // no spread at all, prices pure noise
    for z2 in [-1i64, 1] { for z1 in [-1i64, 1] { for z0 in [-1i64, 1] { noise += (z2 - z1) * (z1 - z0); } } }
    let noise = noise as f64 / 8.0;
    show("no spread: cov, fake spread", &[noise, 2.0 * (-noise).sqrt()]);
    let (mut e2, mut e3, mut e23) = (0.0, 0.0, 0.0); // Roll on Glosten-Milgrom trade prices
    for high in [true, false] {
        for h in 0..8 {
            let (mut pr, mut prob, mut path) = (PRIOR, 0.5, vec![10000.0]);
            for k in 0..3 {
                let sd = (h >> k) & 1 == 1;
                let (b, a, nb, ns) = quotes(pr, MU);
                prob *= if sd == high { (1.0 + MU) / 2.0 } else { (1.0 - MU) / 2.0 };
                path.push(if sd { a } else { b });
                pr = if sd { nb } else { ns };
            }
            let (d2, d3) = (path[2] - path[1], path[3] - path[2]);
            e2 += prob * d2; e3 += prob * d3; e23 += prob * d2 * d3;
        }
    }
    show("GM trade prices: lag covariance", &[(((e23 - e2 * e3) * 1e9).round() / 1e9) + 0.0]);
    assert!((e23 - e2 * e3).abs() < 1e-9, "Glosten-Milgrom trade prices must not bounce");
    println!("ALL CHECKS PASS");
}
