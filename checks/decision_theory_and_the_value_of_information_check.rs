// Deciding under uncertainty: the market-stall order and the price of a forecast.
// Roads: fold back the tree; expected regret; every message-to-action rule counted on
// 1,000 whole Saturdays; a seeded simulation; bisection on the price of the forecast.
const P_SUN: f64 = 0.6; // chance Saturday is sunny
const ACTS: [(&str, f64, f64); 2] = [("big", 600.0, -300.0), ("small", 250.0, 50.0)]; // (name, sun, rain)
const W0: f64 = 1000.0; // manager's cash buffer, pounds
const Q: f64 = 0.8; // forecast accuracy
const FEE: f64 = 50.0; // what the forecast costs

// Fold back one chance node per action; ties keep the later action, as Python's max does.
fn best(p_sun: f64, u: &dyn Fn(f64) -> f64) -> (f64, &'static str) {
    let mut out = (f64::NEG_INFINITY, "");
    for &(n, s, r) in ACTS.iter() {
        let v = p_sun * u(s) + (1.0 - p_sun) * u(r);
        if v > out.0 || (v == out.0 && n > out.1) { out = (v, n); }
    }
    out
}

fn messages(q: f64) -> [(f64, f64); 2] { // Bayes' rule: (P(message), P(sun | message))
    let pairs = [(P_SUN * q, (1.0 - P_SUN) * (1.0 - q)), (P_SUN * (1.0 - q), (1.0 - P_SUN) * q)];
    let mut out = [(0.0, 0.0); 2];
    for (i, &(ps, pr)) in pairs.iter().enumerate() { out[i] = (ps + pr, ps / (ps + pr)); }
    out
}

fn with_forecast(q: f64, u: &dyn Fn(f64) -> f64) -> f64 {
    messages(q).iter().map(|&(pm, ps)| pm * best(ps, u).0).sum()
}

fn price(q: f64, u: &dyn Fn(f64) -> f64) -> f64 { // largest fee the manager would pay
    let target = best(P_SUN, u).0;
    let (mut lo, mut hi) = (0.0, 500.0);
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if with_forecast(q, &|x: f64| u(x - mid)) > target { lo = mid; } else { hi = mid; }
    }
    lo
}

fn money(x: f64) -> f64 { x }
fn logu(x: f64) -> f64 { (W0 + x).ln() }
fn ce(v: f64) -> f64 { v.exp() - W0 } // certainty equivalent from a log score

struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 { // SplitMix64
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn main() {
    println!("Saturday stall: chance of sun {}, manager's cash buffer {:.0}", P_SUN, W0);
    println!("action   sun   rain   expected   certainty equivalent (log)");
    for &(n, s, r) in ACTS.iter() {
        let em = P_SUN * s + (1.0 - P_SUN) * r;
        let cu = ce(P_SUN * logu(s) + (1.0 - P_SUN) * logu(r));
        println!("{:<6} {:>5} {:>6} {:>10.2} {:>10.2}", n, s, r, em, cu);
    }
    let (v0, a0) = best(P_SUN, &money);
    let (u0, b0) = best(P_SUN, &logu);
    println!("choice by expected money: {}; by expected utility: {}", a0, b0);

    // Perfect information: learn the weather, then choose.
    let sun_best = ACTS.iter().map(|a| a.1).fold(f64::MIN, f64::max);
    let rain_best = ACTS.iter().map(|a| a.2).fold(f64::MIN, f64::max);
    let v_perfect = P_SUN * sun_best + (1.0 - P_SUN) * rain_best;
    let evpi = v_perfect - v0;
    println!("perfect forecast: sun -> big, rain -> small, expected {:.2}", v_perfect);
    println!("EVPI = {:.2} - {:.2} = {:.2}", v_perfect, v0, evpi);
    let chosen = ACTS.iter().find(|a| a.0 == a0).unwrap();
    let regret = P_SUN * (sun_best - chosen.1) + (1.0 - P_SUN) * (rain_best - chosen.2);
    println!("EVPI as expected regret of {}: {:.2} (regret in rain {:.2})", a0, regret, rain_best - chosen.2);
    assert!((evpi - regret).abs() < 1e-9 && (evpi - 140.0).abs() < 1e-9);

    // The 80% forecast, through Bayes' rule.
    let m = messages(Q);
    println!("{:.0}% forecast: P(says sun) {:.4}, P(sun | says sun) {:.4}, P(sun | says rain) {:.4}",
             Q * 100.0, m[0].0, m[0].1, m[1].1);
    for (label, ps) in [("says sun", m[0].1), ("says rain", m[1].1)] {
        let vals: Vec<String> = ACTS.iter().map(|&(n, s, r)| format!("{} {:.2}", n, ps * s + (1.0 - ps) * r)).collect();
        println!("  {}: {} -> {}", label, vals.join("  "), best(ps, &money).1);
    }
    let v_q = with_forecast(Q, &money);
    let evsi = v_q - v0;
    println!("expected with forecast {:.2}, worth {:.2}; fee {:.2} -> {}, ahead {:.2}", v_q, evsi, FEE,
             if evsi > FEE { "buy" } else { "skip" }, evsi - FEE);
    println!("Friday decision: no forecast {:.2}, forecast after fee {:.2}; worth {:.2}", v0, v_q - FEE, v0.max(v_q - FEE));

    // Road 3: 1,000 Saturdays in whole numbers, every rule from message to action.
    let (n_ss, n_sr, n_rs, n_rr) = (480i64, 120i64, 80i64, 320i64);
    println!("1000 Saturdays: sunny says sun {}, says rain {}; rainy says sun {}, says rain {}", n_ss, n_sr, n_rs, n_rr);
    let mut rules: Vec<(i64, String)> = Vec::new();
    for &(an, asun, arain) in ACTS.iter() {
        for &(bn, bsun, brain) in ACTS.iter() {
            let tot = n_ss * asun as i64 + n_rs * arain as i64 + n_sr * bsun as i64 + n_rr * brain as i64;
            rules.push((tot, format!("{}/{}", an, bn)));
        }
    }
    let line: Vec<String> = rules.iter().map(|(t, r)| format!("{} {}", r, t)).collect();
    println!("1000 Saturdays, total profit per rule: {}", line.join("  "));
    let top = rules.iter().fold(&rules[0], |a, b| if b.0 > a.0 { b } else { a });
    assert!(top.0 == (1000.0 * v_q).round() as i64 && top.1 == "big/small");

    // Road 4: simulation, SplitMix64.
    let mut rng = Rng(20261111);
    let n = 200000;
    let (mut tb, mut tp, mut tf) = (0i64, 0i64, 0i64);
    for _ in 0..n {
        let sun = rng.unif() < P_SUN;
        let says_sun = if rng.unif() < Q { sun } else { !sun };
        tb += if sun { 600 } else { -300 };
        tp += if sun { 600 } else { 50 };
        tf += if says_sun { if sun { 600 } else { -300 } } else { if sun { 250 } else { 50 } };
    }
    let nf = n as f64;
    println!("simulated {} Saturdays: always big {:.2}, perfect {:.2}, forecast {:.2}",
             n, tb as f64 / nf, tp as f64 / nf, tf as f64 / nf);
    assert!((tb as f64 / nf - v0).abs() < 5.0 && (tp as f64 / nf - v_perfect).abs() < 5.0
            && (tf as f64 / nf - v_q).abs() < 5.0);

    // Prices by bisection: straight utility must give back EVPI and the forecast's worth.
    assert!((price(1.0, &money) - evpi).abs() < 1e-6 && (price(Q, &money) - evsi).abs() < 1e-6);
    let (c_perfect, c_q) = (price(1.0, &logu), price(Q, &logu));
    println!("cautious manager (log): no forecast {:.2}; perfect worth {:.2}; {:.0}% worth {:.2}",
             ce(u0), c_perfect, Q * 100.0, c_q);
    assert!(c_perfect > evpi && c_q > evsi); // here, minding risk raises the price
    let ce_q = ce(with_forecast(Q, &logu)); // the shortcut: subtract certainty equivalents, fee ignored
    println!("shortcut, difference of certainty equivalents: {:.2} - {:.2} = {:.2}, not {:.2}", ce_q, ce(u0), ce_q - ce(u0), c_q);

    println!("accuracy  money value  cautious price");
    for i in 0..11 {
        let q = 0.5 + 0.05 * i as f64;
        let vm = ((with_forecast(q, &money) - v0) * 1e9).round() / 1e9 + 0.0;
        assert!((vm - (350.0 * q - 210.0).max(0.0)).abs() < 1e-9); // closed form from the tree
        println!("{:.2} {:>12.2} {:>15.2}", q, vm, price(q, &logu));
    }

    println!("money value passes the fee at accuracy {:.4}", (FEE + 210.0) / 350.0);
    let (d_s, d_r) = (logu(600.0) - logu(250.0), logu(50.0) - logu(-300.0)); // log-score edge of big in sun, of small in rain
    let p_tip = d_r / (d_s + d_r); // chance of sun at which the cautious manager switches to big
    let q_tip = (1.0 - P_SUN) * p_tip / (P_SUN * (1.0 - p_tip) + (1.0 - P_SUN) * p_tip); // accuracy where "says sun" gives p_tip
    println!("cautious price leaves zero at accuracy {:.4}, where P(sun | says sun) reaches {:.4}", q_tip, p_tip);
    assert!(price(q_tip - 1e-3, &logu) < 1e-9 && price(q_tip + 1e-3, &logu) > 1e-9); // bisection agrees with the switch point
    let ce_big = ce(P_SUN * logu(600.0) + (1.0 - P_SUN) * logu(-300.0));
    assert!((ce_big - ((W0 + 600.0).powf(0.6) * (W0 - 300.0).powf(0.4) - W0)).abs() < 1e-9); // geometric mean
    let v_small = P_SUN * 250.0 + (1.0 - P_SUN) * 50.0;
    println!("what breaks: best case minus average {:.2}; wrong baseline {:.2}; {:.0}% of perfect {:.2}; cautious manager on big loses {:.2}",
             sun_best - v0, v_perfect - v_small, Q * 100.0, Q * evpi, ce(u0) - ce_big);
    let wet = 0.3; // a wetter season, for "When it holds"
    let wet_plan = ACTS.iter().map(|a| wet * a.1 + (1.0 - wet) * a.2).fold(f64::MIN, f64::max);
    let wet_evpi = wet * sun_best + (1.0 - wet) * rain_best - wet_plan;
    println!("wetter season, sun {}: best plan {:.2}, EVPI {:.2}", wet, wet_plan, wet_evpi);
    assert!((wet_evpi - wet * (sun_best - 250.0)).abs() < 1e-9); // regret of the small order: sun only
    println!("ALL CHECKS PASS");
}
