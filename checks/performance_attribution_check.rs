// Brinson attribution -- the check behind the card.  Rust std only, no crates.
// Every number quoted on the card is printed here, in percentage points (pp).
// Roads: direct totals, the per-sector formula, four notional portfolios,
// two one-decision-at-a-time paths, and 1,000 random ledgers.

fn total(weights: &[f64], returns: &[f64]) -> f64 {
    weights.iter().zip(returns).map(|(w, x)| w * x).sum()
}

// Brinson-Fachler, one entry per sector: (allocation, selection, interaction)
fn effects(w: &[f64], wb: &[f64], r: &[f64], b: &[f64]) -> (Vec<f64>, Vec<f64>, Vec<f64>) {
    let bt = total(wb, b);
    let n = w.len();
    let a = (0..n).map(|i| (w[i] - wb[i]) * (b[i] - bt)).collect();
    let s = (0..n).map(|i| wb[i] * (r[i] - b[i])).collect();
    let x = (0..n).map(|i| (w[i] - wb[i]) * (r[i] - b[i])).collect();
    (a, s, x)
}

fn sum(v: &[f64]) -> f64 {
    v.iter().sum()
}

fn show(label: &str, x: f64) {
    println!("{:<44} {:+.4}", label, 100.0 * x + 0.0);
}

struct Lcg(u64);
impl Lcg {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        (self.0 >> 11) as f64 / (1u64 << 53) as f64
    }
}

fn main() {
    // ---- the example: shares and bonds, one month ----
    let w = [0.60, 0.40]; // fund's weights at the start
    let wb = [0.50, 0.50]; // benchmark's weights
    let r = [0.068, -0.022]; // fund's return inside each sector
    let b = [0.060, -0.020]; // benchmark's return inside each sector
    let (rt, bt) = (total(&w, &r), total(&wb, &b));
    let (a, s, x) = effects(&w, &wb, &r, &b);
    show("fund return R", rt);
    show("benchmark return B", bt);
    show("road 1  active return R - B", rt - bt);
    for (k, name) in ["shares", "bonds"].iter().enumerate() {
        show(&format!("{}: allocation", name), a[k]);
        show(&format!("{}: selection", name), s[k]);
        show(&format!("{}: interaction", name), x[k]);
    }
    let (sa, ss, si) = (sum(&a), sum(&s), sum(&x));
    show("allocation A", sa);
    show("selection S", ss);
    show("interaction I", si);
    show("road 2  A + S + I", sa + ss + si);

    // ---- road 3: four notional portfolios, whole-portfolio returns only ----
    let (q1, q2, q3, q4) = (total(&wb, &b), total(&w, &b), total(&wb, &r), total(&w, &r));
    show("Q1 benchmark weights, benchmark returns", q1);
    show("Q2 fund weights, benchmark returns", q2);
    show("Q3 benchmark weights, fund returns", q3);
    show("Q4 fund weights, fund returns", q4);
    show("road 3  allocation Q2 - Q1", q2 - q1);
    show("road 3  selection Q3 - Q1", q3 - q1);
    show("road 3  interaction Q4 - Q3 - Q2 + Q1", q4 - q3 - q2 + q1);

    // ---- road 4: change one decision at a time, in both orders ----
    let sel_at_fund_w: f64 = (0..2).map(|k| w[k] * (r[k] - b[k])).sum();
    let alloc_at_fund_r: f64 = (0..2).map(|k| (w[k] - wb[k]) * r[k]).sum();
    show("allocation first: then selection", sel_at_fund_w);
    show("selection first: then allocation", alloc_at_fund_r);
    show("staircase: benchmark", bt);
    show("staircase: + allocation", bt + sa);
    show("staircase: + selection", bt + sa + ss);
    show("staircase: + interaction = fund", bt + sa + ss + si);

    // ---- what breaks ----
    show("wrong: drop interaction", sa + ss);
    show("wrong: fund-weight selection + interaction", sa + sel_at_fund_w + si);
    show("uncentred allocation, shares", (w[0] - wb[0]) * b[0]);
    show("uncentred allocation, bonds", (w[1] - wb[1]) * b[1]);

    // ---- try changing ----
    let act = |e: (Vec<f64>, Vec<f64>, Vec<f64>)| sum(&e.0) + sum(&e.1) + sum(&e.2);
    show("try: copy benchmark weights, active", act(effects(&wb, &wb, &r, &b)));
    show("try: copy benchmark returns, active", act(effects(&w, &wb, &b, &b)));
    show("try: flip to 40/60, allocation", sum(&effects(&[0.4, 0.6], &wb, &r, &b).0));
    show("try: flip to 40/60, active", total(&[0.4, 0.6], &r) - bt);

    // ---- two months: link before adding ----
    let (r2, b2) = ([0.000, -0.025], [0.030, -0.010]); // month 2, same starting weights
    let (rt2, bt2) = (total(&w, &r2), total(&wb, &b2));
    let (a2, s2, x2) = effects(&w, &wb, &r2, &b2);
    show("month 2: fund", rt2);
    show("month 2: benchmark", bt2);
    show("month 2: allocation", sum(&a2));
    show("month 2: selection", sum(&s2));
    show("month 2: interaction", sum(&x2));
    let naive = (rt - bt) + (rt2 - bt2);
    let compound = (1.0 + rt) * (1.0 + rt2) - (1.0 + bt) * (1.0 + bt2);
    let (f1, f2) = (1.0 + bt2, 1.0 + rt); // month 1 scaled by later benchmark growth, month 2 by earlier fund growth
    let linked = [sa * f1 + sum(&a2) * f2, ss * f1 + sum(&s2) * f2, si * f1 + sum(&x2) * f2];
    show("two months: sum of monthly active", naive);
    show("two months: compounded fund", (1.0 + rt) * (1.0 + rt2) - 1.0);
    show("two months: compounded benchmark", (1.0 + bt) * (1.0 + bt2) - 1.0);
    show("two months: compounded active", compound);
    show("linked allocation", linked[0]);
    show("linked selection", linked[1]);
    show("linked interaction", linked[2]);
    show("linked total", sum(&linked));

    // ---- road 5: 1,000 random ledgers, five sectors, home-made random numbers ----
    let mut g = Lcg(20260928);
    let mut worst: f64 = 0.0;
    for _ in 0..1000 {
        let raw_w: Vec<f64> = (0..5).map(|_| g.next()).collect();
        let raw_wb: Vec<f64> = (0..5).map(|_| g.next()).collect();
        let tw: Vec<f64> = raw_w.iter().map(|x| x / sum(&raw_w)).collect();
        let twb: Vec<f64> = raw_wb.iter().map(|x| x / sum(&raw_wb)).collect();
        let tr: Vec<f64> = (0..5).map(|_| 0.4 * g.next() - 0.2).collect();
        let tb: Vec<f64> = (0..5).map(|_| 0.4 * g.next() - 0.2).collect();
        let (ta, ts, ti) = effects(&tw, &twb, &tr, &tb);
        let gap = sum(&ta) + sum(&ts) + sum(&ti) - (total(&tw, &tr) - total(&twb, &tb));
        worst = worst.max(gap.abs());
    }
    println!("{:<44} {}", "1000 random ledgers reconcile to 1e-12", if worst < 1e-12 { "yes" } else { "no" });

    // ---- mutants: break the formula three ways; each must fail to reconcile ----
    let mutants: [&dyn Fn(usize) -> f64; 3] = [
        &|k| (w[k] - wb[k]) * (b[k] - bt) + wb[k] * (r[k] - b[k]),
        &|k| (w[k] - wb[k]) * (b[k] - bt) + w[k] * (r[k] - b[k]) + (w[k] - wb[k]) * (r[k] - b[k]),
        &|k| (w[k] - wb[k]) * (r[k] - bt) + wb[k] * (r[k] - b[k]) + (w[k] - wb[k]) * (r[k] - b[k]),
    ];
    let caught = mutants.iter().filter(|f| ((0..2).map(|k| f(k)).sum::<f64>() - (rt - bt)).abs() > 1e-9).count();
    println!("{:<44} {}", "mutants caught (of 3)", caught);

    // ---- asserts: each side computed a different way ----
    assert!(((rt - bt) - 0.012).abs() < 1e-12); // the headline, from the example's statement
    assert!((sa + ss + si - (rt - bt)).abs() < 1e-12); // formula vs direct totals
    assert!((sa - (q2 - q1)).abs() < 1e-12); // centred sector formula vs notional portfolios
    assert!((si - (q4 - q3 - q2 + q1)).abs() < 1e-12);
    for k in 0..2 {
        // per sector: effects miss the raw contribution by (w - W) B
        assert!((a[k] + s[k] + x[k] + (w[k] - wb[k]) * bt - (w[k] * r[k] - wb[k] * b[k])).abs() < 1e-12);
    }
    assert!((si - (alloc_at_fund_r - sa)).abs() < 1e-12); // interaction = how much the order matters
    assert!((sum(&linked) - compound).abs() < 1e-12); // linking vs compounding
    assert!(worst < 1e-12); // 1,000 ledgers nobody chose
    assert_eq!(caught, 3); // every broken formula fails to reconcile
    println!("all checks passed");
}
