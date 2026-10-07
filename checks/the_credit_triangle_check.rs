// The credit triangle -- the check behind the card.  Rust std only.
// Every number quoted on the card is printed here.  Roads to the par spread:
// the triangle, the closed form for dated premiums, the two legs added up
// (Simpson's rule and a premium-date sum), and a Monte Carlo of default dates.
const R: f64 = 0.40;
const RATE: f64 = 0.05;
const DL: f64 = 0.25;
const T: f64 = 5.0;
const M: usize = 20;
const L: f64 = 1.0 - R;

fn f(x: f64) -> f64 { if x == 0.0 { 1.0 } else { (x.exp() - 1.0) / x } }

fn closed(lam: f64, d: f64) -> f64 { L * lam * f((RATE + lam) * d) }

fn w(t: f64, haz: &[f64], knots: &[f64]) -> f64 {
    let (mut a, mut prev) = (0.0, 0.0);
    for (h, k) in haz.iter().zip(knots) {
        a += h * (t.min(*k) - prev);
        prev = *k;
        if t <= *k { break; }
    }
    (-RATE * t - a).exp()
}

// returns protection leg, quarterly risky annuity, continuous annuity
fn legs(haz: &[f64], knots: &[f64]) -> (f64, f64, f64) {
    let n = 2000;
    let (mut prot, mut cont, mut prev) = (0.0, 0.0, 0.0);
    for (h, k) in haz.iter().zip(knots) {
        let step = (k - prev) / n as f64;
        for i in 0..=n {
            let wt = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
            let c = wt * step / 3.0;
            let v = w(prev + i as f64 * step, haz, knots);
            prot += c * L * h * v;
            cont += c * v;
        }
        prev = *k;
    }
    let mut ann = 0.0;
    for j in 1..=M { ann += DL * w(j as f64 * DL, haz, knots); }
    (prot, ann, cont)
}

fn monte_carlo(lam: f64, paths: usize, seed: u64) -> f64 {
    let mut disc = vec![0.0f64];
    for j in 1..=M { let last = disc[j - 1]; disc.push(last + DL * (-RATE * j as f64 * DL).exp()); }
    let (mut s, mut prot, mut ann) = (seed, 0.0, 0.0);
    for _ in 0..paths {
        s = s.wrapping_add(0x9E3779B97F4A7C15);                   // splitmix64
        let mut z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        let u = ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 + 0.5 / 9007199254740992.0;
        let tau = -u.ln() / lam;
        if tau < T { prot += L * (-RATE * tau).exp(); }
        ann += disc[M.min((tau / DL) as usize)];
    }
    prot / ann
}

fn solve(s: f64) -> f64 {                                         // bisection on the closed form
    let (mut lo, mut hi) = (0.0, 1.0);
    while hi - lo > 1e-14 {
        let mid = 0.5 * (lo + hi);
        if closed(mid, DL) < s { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

fn fixed_point(s: f64, mut lam: f64) -> (f64, usize) {           // seed, then correct for timing
    for it in 1..50 {
        let new = s / (L * f((RATE + lam) * DL));
        if (new - lam).abs() < 1e-14 { return (new, it); }
        lam = new;
    }
    (lam, 50)
}

fn row(label: &str, v: f64, dp: usize) { println!("{:<38}{:>12.*}", label, dp, v); }

fn main() {
    let bp = 1e4;
    let lam = 0.02;
    let tri = L * lam;
    let (p, a, c) = legs(&[lam], &[T]);
    let mc = monte_carlo(lam, 4_000_000, 20260928);
    let x = (RATE + lam) * DL;
    println!("Northwind, flat 2% hazard, 40% recovery, r = 5%, 5 years");
    row("triangle (1-R) lambda, bp", tri * bp, 4);
    row("protection leg per $1 (Simpson)", p, 6);
    row("risky annuity, quarterly (sum)", a, 4);
    row("par spread, legs, bp", p / a * bp, 4);
    row("par spread, closed form, bp", closed(lam, DL) * bp, 4);
    row("par spread, Monte Carlo 4e6, bp", mc * bp, 2);
    row("continuous premiums, legs, bp", p / c * bp, 4);
    row("timing term x = (r+lambda) delta", x, 4);
    row("rule of thumb x/2, %", x / 2.0 * 100.0, 4);
    row("rule of thumb 120 (1 + x/2), bp", tri * (1.0 + x / 2.0) * bp, 4);
    row("premium on $10m, triangle, $", tri * 1e7, 2);
    row("premium on $10m, exact, $", closed(lam, DL) * 1e7, 2);
    println!("{:<38}{:>6.4}  {:.4}", "recovery, 2% with 120 / 121.06 bp, %", (1.0 - tri / lam) * 100.0, (1.0 - closed(lam, DL) / lam) * 100.0);
    row("5-year default chance at 2%, %", (1.0 - (-5.0 * lam).exp()) * 100.0, 4);
    println!();
    println!("300 bp quote, 40% recovery");
    let s3 = 0.03;
    let seed = s3 / L;
    let root = solve(s3);
    let (fp, its) = fixed_point(s3, seed);
    let corr = seed / (1.0 + (RATE + seed) * DL / 2.0);
    row("seed s/(1-R), %", seed * 100.0, 4);
    row("timing term x/2 at the seed, %", (RATE + seed) * DL / 2.0 * 100.0, 4);
    row("seed with timing, %", corr * 100.0, 4);
    row("bisection on the closed form, %", root * 100.0, 4);
    row("fixed point from the seed, %", fp * 100.0, 4);
    println!("{:<38}{:>12}", "fixed-point steps from the seed", its);
    let (pr, an, _) = legs(&[root], &[T]);
    row("legs re-priced at the root, bp", pr / an * bp, 4);
    row("spread the seed prices at, bp", closed(seed, DL) * bp, 4);
    row("5-year default chance at root, %", (1.0 - (-5.0 * root).exp()) * 100.0, 4);
    println!();
    println!("shelf quotes, flat hazard to each tenor: seed %, solved %");
    let mut seeds = Vec::new();
    for (ten, q) in [(1, 0.012), (3, 0.020), (5, 0.025)] {
        seeds.push((q / L, solve(q)));
        let lab = format!("{}y {:.0} bp", ten, q * bp);
        println!("{:<38}{:>6.4}  {:.4}", lab, q / L * 100.0, solve(q) * 100.0);
    }
    println!();
    println!("error of the triangle, bp: hazard, quarterly gap, annual gap");
    for h in 1..=10 {
        let hz = h as f64 / 100.0;
        let (g1, g2) = ((closed(hz, DL) - L * hz) * bp, (closed(hz, 1.0) - L * hz) * bp);
        println!("gap {:>2}%{:<31}{:>6.2}  {:.2}", h, "", g1, g2);
    }
    println!();
    println!("hazard curves, 5 years: calendar triangle, continuous, quarterly (bp)");
    let up = legs(&[0.01, 0.03], &[2.0, 5.0]);
    let dn = legs(&[0.03, 0.01], &[2.0, 5.0]);
    let cal_up = L * (0.01 * 2.0 + 0.03 * 3.0) / T;
    let cal_dn = L * (0.03 * 2.0 + 0.01 * 3.0) / T;
    println!("{:<38}{:>8.4}", "calendar average, rising curve, %", (0.01 * 2.0 + 0.03 * 3.0) / T * 100.0);
    println!("{:<38}{:>8.4}  {:.4}  {:.4}", "rising 1% then 3%", cal_up * bp, up.0 / up.2 * bp, up.0 / up.1 * bp);
    println!("{:<38}{:>8.4}  {:.4}  {:.4}", "falling 3% then 1%", cal_dn * bp, dn.0 / dn.2 * bp, dn.0 / dn.1 * bp);
    println!();
    println!("what breaks");
    row("R in place of 1-R, bp", R * lam * bp, 4);
    row("300 bp divided by R, %", s3 / R * 100.0, 4);
    row("spread read as hazard, %", s3 * 100.0, 4);
    row("5 x 2% as 5-year default chance, %", 5.0 * lam * 100.0, 4);

    // asserts: each side computed a different way
    assert!((p / a - closed(lam, DL)).abs() < 1e-12);            // legs summed vs closed form
    assert!((mc - closed(lam, DL)).abs() < 0.6e-4);              // simulation vs closed form
    assert!((p / c - tri).abs() < 1e-12);                        // continuous premiums: triangle exact
    assert!((root - fp).abs() < 1e-12);                          // two solvers agree
    assert!(its <= 8);                                           // the seed is close
    assert!((pr / an - s3).abs() < 1e-12);                       // the root re-priced by the legs
    let gap = closed(lam, DL) - tri * (1.0 + x / 2.0);
    assert!(gap > 0.0 && gap < tri * x * x * x.exp() / 6.0);     // rule of thumb within its bound
    assert!(up.0 / up.2 < cal_up);                               // a rising curve pulls the spread down
    assert!(dn.0 / dn.2 > cal_dn);                               // a falling curve pushes it up
    assert!(seeds.iter().all(|(s0, s1)| s0 > s1));               // triangle seed always above the root
    println!("All checks passed.");
}
