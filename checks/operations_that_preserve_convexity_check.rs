// Building convex functions -- the same check as the Python, in Rust.  No crates.
// A roaster blends Brazil, Colombia and Ethiopia beans (shares x1, x2, x3 of a
// kilo).  Cost: the worst of three supplier quotes, a 50% surcharge on any part
// above a £10 budget, and a £2 taste penalty per squared strength point off 7.
// Roads: nested ternary search, every blend on a 1/128 grid, a subgradient
// certificate, and chord tests on random pairs.  Breaking a rule shows a dent.
type V3 = [f64; 3];
const QUOTES: [V3; 3] = [[8.0, 12.0, 11.0], [10.0, 9.0, 12.0], [9.0, 11.0, 9.0]];
const STRENGTH: V3 = [5.0, 9.0, 7.0];
const TARGET: f64 = 7.0;
const W: f64 = 2.0;
const BUDGET: f64 = 10.0;

fn dot(p: &V3, x: &V3) -> f64 { p[0] * x[0] + p[1] * x[1] + p[2] * x[2] }
fn worst(x: &V3) -> f64 { QUOTES.iter().map(|q| dot(q, x)).fold(f64::MIN, f64::max) }
fn best_quote(x: &V3) -> f64 { QUOTES.iter().map(|q| dot(q, x)).fold(f64::MAX, f64::min) }
fn surcharge(c: f64) -> f64 { c + 0.5 * f64::max(0.0, c - BUDGET) }     // slopes 1, then 1.5
fn discount(c: f64) -> f64 { c - 0.5 * f64::max(0.0, c - BUDGET) }      // slopes 1, then 0.5
fn taste(x: &V3) -> f64 { let d = dot(&STRENGTH, x) - TARGET; W * d * d }
fn cost(x: &V3) -> f64 { surcharge(worst(x)) + taste(x) }

fn ternary(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {   // valid only because f is convex
    for _ in 0..100 {
        let (m1, m2) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if f(m1) <= f(m2) { hi = m2 } else { lo = m1 }
    }
    (lo + hi) / 2.0
}

fn inner(x1: f64) -> (f64, f64) {          // V(x1): best Colombia share for a fixed Brazil share
    let r = 1.0 - x1;
    let x2 = ternary(&|t| cost(&[x1, t, r - t]), 0.0, r);
    (cost(&[x1, x2, r - x2]), x2)
}

fn all_or_nothing(x1: f64) -> f64 {        // Colombia either 0 or all the rest: not a convex choice
    f64::min(cost(&[x1, 0.0, 1.0 - x1]), cost(&[x1, 1.0 - x1, 0.0]))
}

fn splitmix(state: u64) -> (u64, u64) {
    let s = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = s;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, (z ^ (z >> 31)) >> 11)
}

fn chord_test(f: &dyn Fn(&V3) -> f64, pairs: usize, seed: u64) -> (usize, f64) {
    let (mut state, mut bad, mut worst_gap) = (seed, 0, 0.0f64);
    for _ in 0..pairs {
        let mut u = [0.0; 5];
        for k in 0..5 {
            let (s, r) = splitmix(state);
            state = s;
            u[k] = r as f64 / 9007199254740992.0;
        }
        let blend = |a: f64, b: f64| { let (lo, hi) = (a.min(b), a.max(b)); [lo, hi - lo, 1.0 - hi] };
        let (x, y, th) = (blend(u[0], u[1]), blend(u[2], u[3]), u[4]);
        let m: V3 = [0, 1, 2].map(|i| th * x[i] + (1.0 - th) * y[i]);
        let gap = f(&m) - (th * f(&x) + (1.0 - th) * f(&y));
        if gap > 1e-9 { bad += 1 }
        worst_gap = worst_gap.max(gap);
    }
    (bad, worst_gap)
}

fn fmt(v: &V3) -> String { format!("({:.2}, {:.2}, {:.2})", v[0], v[1], v[2]) }
fn ints(v: &V3) -> String { format!("({}, {}, {})", v[0] as i64, v[1] as i64, v[2] as i64) }
fn join(v: &[f64]) -> String { v.iter().map(|t| format!("{:.2}", t)).collect::<Vec<_>>().join(", ") }

fn show(label: &str, f: &dyn Fn(&V3) -> f64, x: V3, y: V3) -> f64 {
    let m: V3 = [0, 1, 2].map(|i| (x[i] + y[i]) / 2.0);
    let (mid, chord) = (f(&m), (f(&x) + f(&y)) / 2.0);
    println!("{}: ends {:.4} and {:.4}, midpoint {:.4}, chord {:.4}, bulge {:.4}",
             label, f(&x), f(&y), mid, chord, mid - chord);
    mid - chord
}

fn main() {
    println!("inputs: quotes A {}, B {}, C {}; strength {}, target {}, weight {}, budget {}",
             ints(&QUOTES[0]), ints(&QUOTES[1]), ints(&QUOTES[2]), ints(&STRENGTH), TARGET, W, BUDGET);
    // Road 1: nested ternary search, outer over Brazil, inner over Colombia.
    let x1 = ternary(&|t| inner(t).0, 0.0, 1.0);
    let (v1, x2) = inner(x1);
    println!("road 1, nested ternary search: shares {:.7}, {:.7}, {:.7}; cost {:.7}", x1, x2, 1.0 - x1 - x2, v1);
    // Road 2: every blend whose shares are multiples of 1/128.
    let n = 128usize;
    let (mut gbest, mut gat) = (f64::MAX, (0, 0, 0));
    for i in 0..=n {
        for j in 0..=(n - i) {
            let c = cost(&[i as f64 / n as f64, j as f64 / n as f64, (n - i - j) as f64 / n as f64]);
            if c < gbest { gbest = c; gat = (i, j, n - i - j) }
        }
    }
    println!("road 2, all {} blends in steps of 1/128: best {}/128, {}/128, {}/128; cost {:.7}",
             (n + 1) * (n + 2) / 2, gat.0, gat.1, gat.2, gbest);
    let xs: V3 = [gat.0 as f64 / n as f64, gat.1 as f64 / n as f64, gat.2 as f64 / n as f64];
    let (qa, qb, qc) = (dot(&QUOTES[0], &xs), dot(&QUOTES[1], &xs), dot(&QUOTES[2], &xs));
    let s = dot(&STRENGTH, &xs);
    let g: V3 = [gat.0 as f64, gat.1 as f64, gat.2 as f64];
    println!("in 128ths of a pound: quotes A {}, B {}, C {}; strength {} in 128ths of a point",
             dot(&QUOTES[0], &g), dot(&QUOTES[1], &g), dot(&QUOTES[2], &g), dot(&STRENGTH, &g));
    println!("at that blend: quotes A {:.7}, B {:.7}, C {:.7}; worst {:.7}, after surcharge {:.7}",
             qa, qb, qc, worst(&xs), surcharge(worst(&xs)));
    println!("strength {:.4}, miss {:.4}, taste penalty {:.7}; total {:.7}", s, s - TARGET, taste(&xs), cost(&xs));
    // Road 3: the certificate.  Half of A's prices plus half of C's, plus the taste slope.
    let half: V3 = [0, 1, 2].map(|i| (QUOTES[0][i] + QUOTES[2][i]) / 2.0);
    let slope: V3 = [0, 1, 2].map(|i| 2.0 * W * (s - TARGET) * STRENGTH[i]);
    let cert: V3 = [0, 1, 2].map(|i| half[i] + slope[i]);
    println!("certificate: half A + half C {}, taste slope {}, sum {}", fmt(&half), fmt(&slope), fmt(&cert));
    // Road 4: chord tests on 20000 random pairs of blends and random mixes.
    let (bad, _gap) = chord_test(&cost, 20000, 2026);
    println!("chord test, built cost: {} of 20000 mixes above the chord", bad);
    let (bad_b, gap_b) = chord_test(&best_quote, 20000, 2026);
    println!("chord test, best quote instead of worst: {} of 20000 above, worst by {:.4}", bad_b, gap_b);
    // The chart: V(x1), best cost for each Brazil share, against the all-or-nothing version.
    let ts: Vec<f64> = (0..11).map(|k| k as f64 / 10.0).collect();
    let vs: Vec<f64> = ts.iter().map(|&t| inner(t).0).collect();
    let an: Vec<f64> = ts.iter().map(|&t| all_or_nothing(t)).collect();
    println!("chart, V by Brazil share 0.0 to 1.0: {}", join(&vs));
    println!("chart, all-or-nothing Colombia:      {}", join(&an));
    let d2: Vec<f64> = (1..10).map(|k| vs[k - 1] + vs[k + 1] - 2.0 * vs[k]).collect();
    let d2n: Vec<f64> = (1..10).map(|k| an[k - 1] + an[k + 1] - 2.0 * an[k]).collect();
    let (min_d2, min_d2n) = (d2.iter().cloned().fold(f64::MAX, f64::min), d2n.iter().cloned().fold(f64::MAX, f64::min));
    let at = d2n.iter().position(|&v| v == min_d2n).unwrap();
    println!("smallest second difference: V {:.4}; all-or-nothing {:.4} at Brazil {:.1}", min_d2, min_d2n, ts[1 + at]);
    // What breaks: one chord each, mid = the halfway blend.
    let b1 = show("break 1, best quote", &best_quote, [1.0, 0.0, 0.0], [0.0, 1.0, 0.0]);
    let b2 = show("break 2, squared miss of budget", &|x| (worst(x) - BUDGET) * (worst(x) - BUDGET),
                  [1.0, 0.0, 0.0], [0.5, 0.5, 0.0]);
    let b3 = show("break 3, bulk discount above budget", &|x| discount(worst(x)), [0.7, 0.3, 0.0], [0.8, 0.0, 0.2]);
    println!("break 4, all-or-nothing Colombia: at Brazil 0.2, 0.3, 0.4 cost {:.4}, {:.4}, {:.4}; bulge {:.4}",
             an[2], an[3], an[4], an[3] - (an[2] + an[4]) / 2.0);
    assert!((v1 - gbest).abs() < 1e-9 && (x1 - xs[0]).abs() < 1e-6);      // two searches, one answer
    assert!((cert[0] - cert[1]).abs() < 1e-12 && (cert[1] - cert[2]).abs() < 1e-12 && worst(&xs) < BUDGET);
    assert!(bad == 0 && bad_b > 0);                                      // rules hold, broken rule shows
    assert!(min_d2 > -1e-9 && min_d2n < 0.0);                            // V is a bowl, the dented one is not
    assert!(b1 > 0.0 && b2 > 0.0 && b3 > 0.0);                           // each broken rule bulges
    println!("ALL CHECKS PASS");
}
