// Delta-gamma-vega hedging -- the same check as delta_gamma_vega_hedging_check.py, in Rust.
// Standard library only, no crates.  The bell-curve area is built by Simpson's rule
// (a different road from the Python power series).  Same three roads, same printed rows.
use std::f64::consts::PI;

const S0: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20;
const NBOOK: f64 = -10000.0;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {                                       // 0.5 plus the slice from 0 to x
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let n = 4000; let h = x / n as f64;
    let mut s = phi(0.0) + phi(x);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * phi(i as f64 * h); }
    0.5 + s * h / 3.0
}

#[derive(Clone, Copy, PartialEq)]
enum Leg { Call(f64, f64), Put(f64, f64), Share }                // strike, years left

fn d1(k: f64, t: f64, s: f64, sig: f64) -> f64 { ((s / k).ln() + (R - Q + 0.5 * sig * sig) * t) / (sig * t.sqrt()) }

fn price(leg: Leg, s: f64, sig: f64, dt: f64) -> f64 {
    match leg {
        Leg::Share => s,
        Leg::Call(k, t0) | Leg::Put(k, t0) => {
            let t = t0 - dt; let call = matches!(leg, Leg::Call(..));
            if t <= 0.0 { return if call { (s - k).max(0.0) } else { (k - s).max(0.0) }; }
            let a = d1(k, t, s, sig); let b = a - sig * t.sqrt();
            if call { s * (-Q * t).exp() * n_cdf(a) - k * (-R * t).exp() * n_cdf(b) }
            else { k * (-R * t).exp() * n_cdf(-b) - s * (-Q * t).exp() * n_cdf(-a) }
        }
    }
}

fn greeks(leg: Leg, s: f64, dt: f64) -> [f64; 3] {              // delta, gamma, vega per vol point
    match leg {
        Leg::Share => [1.0, 0.0, 0.0],
        Leg::Call(k, t0) | Leg::Put(k, t0) => {
            let t = t0 - dt; let a = d1(k, t, s, SIG); let dq = (-Q * t).exp();
            let delta = if matches!(leg, Leg::Call(..)) { dq * n_cdf(a) } else { dq * (n_cdf(a) - 1.0) };
            [delta, dq * phi(a) / (s * SIG * t.sqrt()), s * dq * phi(a) * t.sqrt() / 100.0]
        }
    }
}

fn bumped(leg: Leg) -> [f64; 3] {                                // the same three, by nudging the price
    let (h, e) = (0.01, 1e-4);
    let p = |s: f64, sig: f64| price(leg, s, sig, 0.0);
    [(p(S0 + h, SIG) - p(S0 - h, SIG)) / (2.0 * h),
     (p(S0 + h, SIG) - 2.0 * p(S0, SIG) + p(S0 - h, SIG)) / (h * h),
     (p(S0, SIG + e) - p(S0, SIG - e)) / (2.0 * e) / 100.0]
}

fn det(ga: [f64; 3], gb: [f64; 3]) -> f64 { ga[1] * gb[2] - gb[1] * ga[2] }

fn cramer(gp: [f64; 3], ga: [f64; 3], gb: [f64; 3]) -> [f64; 4] { // road 1: 2x2, then shares
    let d = det(ga, gb);
    let na = (-gp[1] * gb[2] + gb[1] * gp[2]) / d;
    let nb = (-ga[1] * gp[2] + gp[1] * ga[2]) / d;
    [na, nb, -(gp[0] + na * ga[0] + nb * gb[0]), d]
}

fn gauss(mut m: Vec<Vec<f64>>) -> Vec<f64> {                    // road 2: elimination, partial pivoting
    let n = m.len();
    for c in 0..n {
        let piv = (c..n).max_by(|&i, &j| m[i][c].abs().partial_cmp(&m[j][c].abs()).unwrap()).unwrap();
        m.swap(c, piv);
        for i in c + 1..n {
            let f = m[i][c] / m[c][c];
            for j in c..=n { let v = m[c][j]; m[i][j] -= f * v; }
        }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() {
        let s: f64 = (i + 1..n).map(|j| m[i][j] * x[j]).sum();
        x[i] = (m[i][n] - s) / m[i][i];
    }
    x
}

fn value(pos: &[(f64, Leg)], s: f64, sig: f64) -> f64 { pos.iter().map(|&(n, l)| n * price(l, s, sig, 0.0)).sum() }
fn pnl(pos: &[(f64, Leg)], s: f64, sig: f64) -> f64 { value(pos, s, sig) - value(pos, S0, SIG) }
fn g_of(pos: &[(f64, Leg)], s: f64, dt: f64) -> [f64; 3] {      // a book's Greeks: position-weighted sums
    let mut t = [0.0; 3];
    for &(n, l) in pos { let g = greeks(l, s, dt); for i in 0..3 { t[i] += n * g[i]; } }
    t
}
fn show(label: &str, xs: &[f64], prec: usize) {
    let mut line = format!("{:<30}", label);
    for x in xs { line.push_str(&format!("{:>13.*}", prec, x)); }
    println!("{}", line);
}

fn main() {
    let (book, a, b) = (Leg::Call(100.0, 1.0), Leg::Put(100.0, 0.25), Leg::Call(110.0, 2.0));
    let g1 = greeks(book, S0, 0.0);
    let gp = g1.map(|x| NBOOK * x); let (ga, gb) = (greeks(a, S0, 0.0), greeks(b, S0, 0.0));
    let [na, nb, ns, d] = cramer(gp, ga, gb);
    let bp = bumped(book).map(|x| NBOOK * x); let (ba, bb) = (bumped(a), bumped(b));
    let x = gauss(vec![vec![1.0, ba[0], bb[0], -bp[0]], vec![0.0, ba[1], bb[1], -bp[1]], vec![0.0, ba[2], bb[2], -bp[2]]]);
    let (ns2, na2, nb2) = (x[0], x[1], x[2]);
    let full = [(NBOOK, book), (na, a), (nb, b), (ns, Leg::Share)];
    let donly = [(NBOOK, book), (-gp[0], Leg::Share)];
    let bare = [(NBOOK, book)];
    let (h, e) = (0.01, 1e-4); let v0 = value(&full, S0, SIG);
    let rev = [(value(&full, S0 + h, SIG) - value(&full, S0 - h, SIG)) / (2.0 * h),
               (value(&full, S0 + h, SIG) - 2.0 * v0 + value(&full, S0 - h, SIG)) / (h * h),
               (value(&full, S0, SIG + e) - value(&full, S0, SIG - e)) / (2.0 * e) / 100.0];

    println!("{:<30}{:>13}{:>13}{:>13}{:>13}", "per option", "price", "delta", "gamma", "vega/pt");
    for (lab, leg, g) in [("book: 1y call K100", book, g1), ("A: 3m put K100", a, ga), ("B: 2y call K110", b, gb)] {
        show(lab, &[price(leg, S0, SIG, 0.0), g[0], g[1], g[2]], 6);
    }
    for (lab, g) in [("bumped: book call", bumped(book)), ("bumped: A", ba), ("bumped: B", bb)] {
        println!("{:<30}{:>13}{:>13.6}{:>13.6}{:>13.6}", lab, "", g[0], g[1], g[2]);
    }
    show("book x -10000: value, Greeks", &[NBOOK * price(book, S0, SIG, 0.0), gp[0], gp[1], gp[2]], 2);
    show("vega/gamma: A, book, B", &[ga[2] / ga[1], g1[2] / g1[1], gb[2] / gb[1]], 4);
    show("S^2 sigma T / 100: A, book, B", &[0.25, 1.0, 2.0].map(|t| S0 * S0 * SIG * t / 100.0), 4);
    show("determinant D", &[d], 8);
    show("Cramer tops: nA x D, nB x D", &[na * d, nb * d], 6);
    let (ra, rp, rb) = (ga[2] / ga[1], g1[2] / g1[1], gb[2] / gb[1]);
    show("gamma shares wA, wB", &[(rb - rp) / (rb - ra), (rp - ra) / (rb - ra)], 6);
    show("road 1 Cramer: nA nB nS", &[na, nb, ns], 2);
    show("road 2 Gauss, bumped: nA nB nS", &[na2, nb2, ns2], 2);
    show("delta: book, from A, from B", &[gp[0], na * ga[0], nb * gb[0]], 2);
    show("hedge cost: A, B, shares", &[na * price(a, S0, SIG, 0.0), nb * price(b, S0, SIG, 0.0), ns * S0], 2);
    show("road 3 revalued: |d| |g| |v|", &rev.map(f64::abs), 4);
    println!("{:<30}{:>13}{:>13}{:>13}", "spot", "no hedge", "delta only", "all three");
    for s in (80..=120).step_by(5) {
        let sp = s as f64;
        show(&format!("  S = {}", s), &[pnl(&bare, sp, SIG), pnl(&donly, sp, SIG), pnl(&full, sp, SIG)], 2);
    }
    show("Taylor at 90: gamma_P x 10^2 / 2", &[0.5 * gp[1] * 100.0], 2);
    for (lab, sp, sg) in [("vol 20% -> 25%", S0, 0.25), ("S 100 -> 95, vol -> 21%", 95.0, 0.21), ("S 100 -> 90, vol -> 25%", 90.0, 0.25)] {
        show(lab, &[pnl(&bare, sp, sg), pnl(&donly, sp, sg), pnl(&full, sp, sg)], 2);
    }
    let rnd = [(NBOOK, book), (2700.0, a), (6000.0, b), (4183.0, Leg::Share)];
    show("rounded 27, 60 lots, 4183 sh", &g_of(&rnd, S0, 0.0), 2);
    show("stale: S moves to 110", &g_of(&full, 110.0, 0.0), 2);
    show("stale: one month passes", &g_of(&full, S0, 1.0 / 12.0), 2);
    let same = det(ga, greeks(Leg::Call(110.0, 0.25), S0, 0.0)).abs();
    show("wrong: A and a 3m K110 call, D", &[same], 8);
    let old = g_of(&[(NBOOK, book), (na, a), (nb, b), (-gp[0], Leg::Share)], S0, 0.0);
    show("wrong: options added, old shares", &old.map(|x| (x * 100.0).round() / 100.0 + 0.0), 2);
    let flip = [(NBOOK, book), (-na, a), (-nb, b), (-(gp[0] - na * ga[0] - nb * gb[0]), Leg::Share)];
    show("wrong: sold A, B; P&L 90, 110", &[pnl(&flip, 90.0, SIG), pnl(&flip, 110.0, SIG)], 2);
    let mix = cramer(gp, ga, [gb[0], gb[1], gb[2] * 100.0]);
    show("wrong: B vega per unit, Greeks", &g_of(&[(NBOOK, book), (mix[0], a), (mix[1], b), (mix[2], Leg::Share)], S0, 0.0), 2);
    show("try: 3m call for A: nA nB nS", &cramer(gp, greeks(Leg::Call(100.0, 0.25), S0, 0.0), gb)[..3], 2);
    let g6 = greeks(Leg::Call(105.0, 0.5), S0, 0.0);
    show("try: 6m K105 vega/gamma", &[g6[2] / g6[1]], 4);
    show("try: B = 6m call K105: nA nB nS", &cramer(gp, ga, g6)[..3], 2);

    assert!((price(book, S0, SIG, 0.0) - 9.227005508154).abs() < 1e-9, "house call price");
    assert!((na - na2).abs().max((nb - nb2).abs()).max((ns - ns2).abs()) < 0.01, "Cramer (analytic) vs Gauss (bumped)");
    assert!(rev[0].abs() < 1e-3 && rev[1].abs() < 1e-3, "revalued hedged book has no delta and no gamma");
    assert!(rev[2].abs() < 1e-3, "revalued hedged book has no vega");
    assert!((ga[2] / ga[1] - S0 * S0 * SIG * 0.25 / 100.0).abs() < 1e-9, "vega/gamma = S^2 sigma T / 100");
    assert!(pnl(&full, 98.0, SIG).abs() < 0.01 * pnl(&donly, 98.0, SIG).abs(), "gamma hedged: a $2 drop");
    assert!(pnl(&full, S0, 0.21).abs() < 0.01 * pnl(&donly, S0, 0.21).abs(), "vega hedged: one vol point");
    assert!(same < 1e-12, "same expiry: determinant vanishes");
    println!("ALL CHECKS PASS");
}
