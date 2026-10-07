// NPV and IRR -- the same check as net_present_value_and_irr_check.py, in Rust.
// Standard library only, no crates, and nothing that already knows the answer:
// the powers, the square root, the bisection and the Newton steps are written out
// below.  The project is a $100.00 dust-filter kit for a printing press that saves
// $60.00 at the end of each of two years.  Money in dollars, rates as decimals.

fn power(base: f64, n: usize) -> f64 {   // repeated multiplication, so that the
    let mut out = 1.0;                   // Python and the Rust agree bit for bit
    for _ in 0..n { out *= base; }
    out
}

fn npv(flows: &[f64], y: f64) -> f64 {   // road 1: shrink each dated amount, add
    let mut total = 0.0;
    for (i, c) in flows.iter().enumerate() {
        total += c / power(1.0 + y, i);
    }
    total
}

fn terminal(flows: &[f64], y: f64) -> f64 {   // road 2: run a real bank account forward
    let mut bal = 0.0;
    for c in flows {
        bal = bal * (1.0 + y) + c;
    }
    bal
}

fn ledger_npv(flows: &[f64], y: f64) -> f64 { // the end balance, shrunk back to today
    terminal(flows, y) / power(1.0 + y, flows.len() - 1)
}

fn slope(flows: &[f64], y: f64) -> f64 {      // how NPV moves when the rate moves
    let mut total = 0.0;
    for (i, c) in flows.iter().enumerate() {
        total += -(i as f64) * c / power(1.0 + y, i + 1);
    }
    total
}

fn bisect(flows: &[f64], lo0: f64, hi0: f64) -> f64 {   // our own root finder
    let (mut lo, mut hi) = (lo0, hi0);
    let lo_is_positive = npv(flows, lo) > 0.0;
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (npv(flows, mid) > 0.0) == lo_is_positive { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn newton(flows: &[f64], start: f64) -> f64 {  // our own Newton: slide down the slope
    let mut y = start;
    for _ in 0..40 { y -= npv(flows, y) / slope(flows, y); }
    y
}

fn square_root(a: f64) -> f64 {                // our own square root, the same method
    let mut x = a;
    for _ in 0..60 { x = 0.5 * (x + a / x); }
    x
}

fn sign_changes(flows: &[f64]) -> usize {      // how often the cash switches direction
    let marks: Vec<bool> = flows.iter().filter(|c| **c != 0.0).map(|c| *c > 0.0).collect();
    (1..marks.len()).filter(|k| marks[*k] != marks[k - 1]).count()
}

fn crossings(flows: &[f64]) -> Vec<f64> {      // every rate where NPV is zero
    let (lo, hi, n) = (-0.90, 1.50, 2400);
    let step = (hi - lo) / n as f64;
    let mut found = Vec::new();
    let mut before = npv(flows, lo);
    for k in 1..=n {
        let after = npv(flows, lo + k as f64 * step);
        if (after > 0.0) != (before > 0.0) {
            found.push(bisect(flows, lo + (k - 1) as f64 * step, lo + k as f64 * step));
        }
        before = after;
    }
    found
}

fn zeroed(v: f64) -> f64 { if v.abs() < 1e-9 { 0.0 } else { v } }  // a rounding crumb is zero

fn row(name: &str, v: f64) { println!("{:<52}{:>13.6}", name, v); }

fn main() {
    let kit = [-100.0, 60.0, 60.0];            // the card's project
    let big = [-250.0, 145.0, 145.0];          // the same press, a bigger kit
    let cleanup = [-100.0, 230.0, -132.0];     // a cleanup bill at the end: two IRRs
    let never = [-100.0, 150.0, -100.0];       // a cleanup bill too big: no IRR at all
    let r = 0.08;
    println!("project: pay 100.00 today, save 60.00 at the end of year 1 and 60.00 at the end of year 2");
    println!("growth factors at 8 percent: one year {:.6}, two years {:.6}", 1.0 + r, power(1.08, 2));
    row("discount factor for year 1, 1/1.08", 1.0 / power(1.08, 1));
    row("discount factor for year 2, 1/(1.08 x 1.08)", 1.0 / power(1.08, 2));
    row("year 1 saving in today's money", 60.0 / power(1.08, 1));
    row("year 2 saving in today's money", 60.0 / power(1.08, 2));
    row("both savings in today's money", 60.0 / power(1.08, 1) + 60.0 / power(1.08, 2));
    row("1 NPV at 8 percent, by shrinking each amount", npv(&kit, r));
    row("2 NPV at 8 percent, by the bank ledger", ledger_npv(&kit, r));
    row("3 NPV at 8 percent, the exact fraction 5100/729", 5100.0 / 729.0);
    println!("{:<52}{:>13.2}", "NPV at 8 percent, to the cent", npv(&kit, r));
    row("bank balance at the end of year 2", terminal(&kit, r));
    let mut ledger = vec![kit[0]];
    for c in &kit[1..] {
        let grown = ledger[ledger.len() - 1] * (1.0 + r);
        ledger.push(grown);
        ledger.push(grown + c);
    }
    let moves: Vec<String> = ledger.iter().map(|v| format!("{:.2}", v)).collect();
    println!("bank ledger at 8 percent, after each move: {}", moves.join(", "));
    let irr_bisect = bisect(&kit, 0.0, 1.0);
    let irr_newton = newton(&kit, 0.20);
    let irr_exact = (3.0 + square_root(69.0)) / 10.0 - 1.0;
    row("1 IRR by bisection, percent", 100.0 * irr_bisect);
    row("2 IRR by Newton, percent", 100.0 * irr_newton);
    row("3 IRR from the exact root (3 + sqrt 69)/10, percent", 100.0 * irr_exact);
    row("NPV at that rate, distance from zero", npv(&kit, irr_bisect).abs());
    row("wrong: the three amounts added with no dates", kit[0] + kit[1] + kit[2]);
    row("wrong: today's 100.00 shrunk as well", npv(&kit, r) - kit[0] + kit[0] / power(1.08, 1));
    row("wrong: year 1's factor used for both years", kit[0] + (kit[1] + kit[2]) / power(1.08, 1));
    let npv_big = npv(&big, r);
    row("bigger kit: pay 250.00, save 145.00 twice -- its NPV", npv_big);
    row("bigger kit, its IRR, percent", 100.0 * bisect(&big, 0.0, 1.0));
    row("dollars the bigger kit adds over the small one", npv_big - npv(&kit, r));
    println!("cleanup kit: -100.00 today, +230.00 at year 1, -132.00 at year 2");
    println!("  times the cash switches direction: {}", sign_changes(&cleanup));
    let roots = crossings(&cleanup);
    let listed: Vec<String> = roots.iter().map(|y| format!("{:.6}", 100.0 * y)).collect();
    println!("  rates where its NPV is zero, percent: {}", listed.join(", "));
    row("  its NPV at 15 percent, between those two rates", npv(&cleanup, 0.15));
    println!("doomed kit: -100.00 today, +150.00 at year 1, -100.00 at year 2");
    println!("  times the cash switches direction: {}", sign_changes(&never));
    println!("  rates where its NPV is zero: {} found between -90 and 150 percent", crossings(&never).len());
    row("  the best its NPV ever reaches, at 33.33 percent", npv(&never, 1.0 / 3.0));
    let mut price = 0.0;
    for i in 1..=5 { price += 60.0 / power(1.05, i); }
    price += 1000.0 / power(1.05, 5);
    let bond = [-price, 60.0, 60.0, 60.0, 60.0, 1060.0];
    row("house bond at a 5 percent yield: its price today", price);
    row("  the IRR of that bond's cashflows, percent", 100.0 * bisect(&bond, 0.0, 0.50));
    let rates: Vec<f64> = (0..11).map(|i| 0.02 * i as f64).collect();
    let heads: Vec<String> = rates.iter().map(|y| format!("{:6.0}", 100.0 * y)).collect();
    let vals: Vec<String> = rates.iter().map(|y| format!("{:6.2}", zeroed(npv(&kit, *y)))).collect();
    println!("chart, rate percent        {}", heads.join(" "));
    println!("chart, NPV dollars         {}", vals.join(" "));
    let cleanup_rates: Vec<f64> = (0..7).map(|i| 0.05 * i as f64).collect();
    let ch: Vec<String> = cleanup_rates.iter().map(|y| format!("{:6.0}", 100.0 * y)).collect();
    let cv: Vec<String> = cleanup_rates.iter().map(|y| format!("{:6.2}", zeroed(npv(&cleanup, *y)))).collect();
    println!("chart, cleanup rate percent{}", ch.join(" "));
    println!("chart, cleanup NPV dollars {}", cv.join(" "));
    let bars: Vec<String> = [0.0, 0.04, 0.08, 0.12].iter().map(|y| format!("{:.2}", npv(&kit, *y))).collect();
    println!("bars, NPV at 0, 4, 8 and 12 percent: {}", bars.join(" "));

    assert!((npv(&kit, r) - ledger_npv(&kit, r)).abs() < 1e-12);   // shrinking vs the ledger
    assert!((npv(&kit, r) - 5100.0 / 729.0).abs() < 1e-12);        // vs the exact fraction
    assert!((irr_bisect - irr_exact).abs() < 1e-10);               // bisection vs the root formula
    assert!((irr_newton - irr_exact).abs() < 1e-10);               // Newton vs the root formula
    assert!((slope(&kit, r) - (npv(&kit, r + 1e-6) - npv(&kit, r - 1e-6)) / 2e-6).abs() < 1e-4);
    assert!(npv(&kit, irr_bisect).abs() < 1e-9);                   // that rate really breaks even
    assert!(roots.len() == 2 && (roots[0] - 0.10).abs().max((roots[1] - 0.20).abs()) < 1e-9);
    assert!((sign_changes(&kit), sign_changes(&cleanup), sign_changes(&never)) == (1, 2, 2));
    assert!(crossings(&never).is_empty() && npv(&never, 1.0 / 3.0) < 0.0);
    assert!((bisect(&bond, 0.0, 0.50) - 0.05).abs() < 1e-12);      // the bond's IRR is its yield
    assert!(npv_big > npv(&kit, r) && bisect(&big, 0.0, 1.0) < irr_bisect);
    println!("ALL CHECKS PASS");
}
