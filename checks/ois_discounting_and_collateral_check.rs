// OIS discounting and collateral -- the same check as ois_discounting_and_collateral_check.py, in Rust.
// Standard library only, no crates.  Three roads to the swap's value once discounting moves
// to the overnight curve: rebuilt forecasts, par-minus-fixed times the annuity, and the
// collateral account rolled back one year at a time.
const N: f64 = 10_000_000.0;
const DEP1: f64 = 0.042;
const PAR: [f64; 6] = [0.0, 0.0, 0.044, 0.0455, 0.0462, 0.0465];   // par quotes by maturity in years

fn forecasts(disc: &[f64]) -> Vec<f64> {                           // index rates that keep every quote at zero
    let mut f = vec![0.0, DEP1];
    for n in 2..6 {
        let annuity: f64 = disc[1..=n].iter().sum();
        let known: f64 = (1..n).map(|j| disc[j] * f[j]).sum();
        f.push((PAR[n] * annuity - known) / disc[n]);
    }
    f
}

fn value(disc: &[f64], f: &[f64], k: f64) -> f64 {                // receive floating, pay fixed k
    N * (1..6).map(|j| disc[j] * (f[j] - k)).sum::<f64>()
}

fn main() {
    let (k, s) = (0.01_f64, 0.0025_f64);
    let mut l = vec![1.0, 1.0 / (1.0 + DEP1)];                      // term curve: one curve does everything
    for n in 2..6 {
        let b: f64 = l[1..n].iter().sum();
        l.push((1.0 - PAR[n] * b) / (1.0 + PAR[n]));
    }
    let d: Vec<f64> = (0..6).map(|j| l[j] * (s * j as f64).exp()).collect();   // overnight curve
    let (f_old, f_new) = (forecasts(&l), forecasts(&d));
    let mut f_ois = vec![0.0];
    for j in 1..6 { f_ois.push(d[j - 1] / d[j] - 1.0); }
    let (a_l, a_d): (f64, f64) = (l[1..].iter().sum(), d[1..].iter().sum());
    println!("year   term L_j   overnight D_j   g_f      g_c      F old %   F new %");
    for j in 1..6 {
        println!("{:>4}   {:.8}   {:.8}   {:.6} {:.6} {:8.4}  {:8.4}", j, l[j], d[j],
                 l[j - 1] / l[j], d[j - 1] / d[j], 100.0 * f_old[j], 100.0 * f_new[j]);
    }
    println!("annuity on the term curve       {:.8}", a_l);
    println!("annuity on the overnight curve  {:.8}", a_d);

    // ---- the one-period model: the first coupon alone, paid in one year ----
    let x = N * (DEP1 - k);
    let (gf, gc) = (1.0 + DEP1, d[0] / d[1]);
    let (v_none, v_full) = (x / gf, x / gc);
    let v_half = x / (0.5 * gf + 0.5 * gc);
    let (mut lo, mut hi) = (0.0_f64, x);                            // bisection with C = V / 2
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if gf * (mid - 0.5 * mid) - (x - gc * 0.5 * mid) < 0.0 { lo = mid; } else { hi = mid; }
    }
    println!();
    println!("one period: coupon X                   {:14.2}", x);
    println!("one period: g_f, g_c                   {:.8}  {:.8}", gf, gc);
    println!("one period: no collateral   X / g_f    {:14.2}", v_none);
    println!("one period: half collateral            {:14.2}  bisection {:.2}", v_half, 0.5 * (lo + hi));
    println!("one period: full collateral X / g_c    {:14.2}", v_full);
    println!("one period: bought at X / g_f, surplus in a year {:10.2}", x - gc * v_none);

    // ---- the seasoned swap: three roads ----
    let v_old = value(&l, &f_old, k);
    let v1 = value(&d, &f_new, k);
    let v2 = N * (PAR[5] - k) * a_d;
    let mut v3 = 0.0_f64;
    for j in (1..6).rev() { v3 = (N * (f_new[j] - k) + v3) / (d[j - 1] / d[j]); }
    println!();
    println!("swap, old single curve                 {:14.2}", v_old);
    println!("swap, old way by par-minus-fixed       {:14.2}", N * (PAR[5] - k) * a_l);
    println!("road 1: new forecasts, overnight disc  {:14.2}", v1);
    println!("road 2: (par - fixed) x N x annuity    {:14.2}", v2);
    println!("road 3: collateral rolled back         {:14.2}", v3);
    println!("the move when discounting switches     {:14.2}", v1 - v_old);
    println!("the move, to the nearest thousand      {:14.2}", 1000.0 * ((v1 - v_old) / 1000.0).round());
    println!("par minus fixed, S_5 - K               {:14.4}", PAR[5] - k);

    // ---- the collateral ledger, with values from direct sums ----
    let value_at = |i: usize| N * ((i + 1)..6).map(|j| d[j] / d[i] * (f_new[j] - k)).sum::<f64>() + 0.0;
    println!("year   coupon in      collateral+interest out   new collateral in   |net|");
    let mut worst = 0.0_f64;
    for i in 1..6 {
        let (cpn, back, new) = (N * (f_new[i] - k), d[i - 1] / d[i] * value_at(i - 1), value_at(i));
        worst = worst.max((cpn - back + new).abs());
        println!("{:>4}   {:12.2}   {:24.2}   {:17.2}   {:6.2}", i, cpn, back, new, (cpn - back + new).abs());
    }
    let bars: Vec<String> = (1..6)
        .map(|j| format!("{:.2}", N * (d[j] * (f_new[j] - k) - l[j] * (f_old[j] - k)))).collect();
    println!("the move, year by year: {}", bars.join("  "));

    // ---- what breaks ----
    println!();
    println!("wrong: new discount, old forecasts     {:14.2}", value(&d, &f_old, k));
    println!("wrong: forecast off overnight curve    {:14.2}", value(&d, &f_ois, k));
    println!("wrong: collateral earns no interest    {:14.2}", N * (1..6).map(|j| f_new[j] - k).sum::<f64>());
    let (h_old, h_new) = (value(&l, &f_old, 0.045), value(&d, &f_new, 0.045));
    println!("house swap at 4.50%: old {:.2}  new {:.2}  move {:.2}", h_old, h_new, h_new - h_old);
    let a_wide: f64 = (1..6).map(|j| l[j] * (0.005 * j as f64).exp()).sum();
    println!("try: gap 0.50%, fixed 1.00%: move {:.2}", N * (PAR[5] - k) * (a_wide - a_l));
    println!("try: fixed 8.00%: move {:.2}", value(&d, &f_new, 0.08) - value(&l, &f_old, 0.08));
    let ks = [0.0, 0.01, 0.02, 0.03, 0.04, 0.045, 0.05, 0.06];
    let head: Vec<String> = ks.iter().map(|kk| format!("{:8.2}", 100.0 * kk)).collect();
    let moves: Vec<String> = ks.iter().map(|&kk| format!("{:8.2}", value(&d, &f_new, kk) - value(&l, &f_old, kk))).collect();
    println!("chart, fixed rate %   {}", head.join(" "));
    println!("chart, move           {}", moves.join(" "));

    assert!((v1 - v2).abs() < 1e-6, "rebuilt forecasts vs par-minus-fixed times annuity");
    assert!((v3 - v1).abs() < 1e-6, "collateral roll-back vs discounted sum");
    let gap = (1..6).map(|j| (f_old[j] - (l[j - 1] / l[j] - 1.0)).abs()).fold(0.0_f64, f64::max);
    assert!(gap < 1e-12, "single curve: forecasts are its own forwards");
    assert!((0.5 * (lo + hi) - v_half).abs() < 1e-6, "bisection vs the partial-collateral formula");
    assert!(worst < 1e-6, "collateral ledger nets to zero every year");
    assert!(((v1 - v_old) - 12000.0).abs() < 500.0, "the move is about 12,000");
    println!("ALL CHECKS PASS");
}
