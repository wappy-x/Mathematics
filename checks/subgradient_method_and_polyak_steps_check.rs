// The subgradient method -- the check behind the card.  Rust std only, no crates.
// A depot goes on a straight road with shops at km 1, 2 and 6.  f(x) is the total
// distance in km from a depot at km x to the three shops; it is minimised from km 10.
// Roads: the method under three step rules; the zero-subgradient certificate; a scan
// of the whole road; the one-step inequality at every step; the proved bounds.
const SHOPS: [f64; 3] = [1.0, 2.0, 6.0];
const X0: f64 = 10.0; // start
const XSTAR: f64 = 2.0; // the median, certified below
const FSTAR: f64 = 5.0; // its value
const R: f64 = 8.0; // |X0 - XSTAR|, distance to the optimum
const G: f64 = 3.0; // number of shops: the largest |subgradient|

fn sq(v: f64) -> f64 { v * v }
fn f(x: f64) -> f64 { SHOPS.iter().map(|s| (x - s).abs()).sum() }
// Slope just right of x.  A shop within 1e-9 km counts as reached: exact moves of 1/3 km
// land on km 6, and rounding must not leave the point a hair short, on the wrong side.
fn sub(x: f64) -> f64 {
    SHOPS.iter().map(|&s| if x >= s - 1e-9 { 1.0 } else { -1.0 }).sum()
}

// K steps of x <- x - a_k g_k.  Returns points x_0..x_K, step sizes, one-step checks kept.
fn run(step: &dyn Fn(usize, f64, f64) -> f64, k_max: usize, fstar: f64) -> (Vec<f64>, Vec<f64>, usize) {
    let (mut x, mut xs, mut al, mut kept) = (X0, vec![X0], vec![], 0);
    for k in 0..k_max {
        let g = sub(x);
        let a = step(k, x, g);
        let nx = x - a * g;
        let lhs = sq(nx - XSTAR); // one-step inequality, Step 1
        let rhs = sq(x - XSTAR) - 2.0 * a * (f(x) - fstar) + a * a * g * g;
        if lhs <= rhs + 1e-9 { kept += 1; }
        xs.push(nx); al.push(a); x = nx;
    }
    (xs, al, kept)
}
fn best_gap(xs: &[f64], k: usize) -> f64 { xs[..k].iter().map(|&x| f(x)).fold(f64::INFINITY, f64::min) - FSTAR }
fn bound(al: &[f64]) -> f64 { (R * R + G * G * al.iter().map(|a| a * a).sum::<f64>()) / (2.0 * al.iter().sum::<f64>()) }
fn rises(xs: &[f64]) -> usize { xs.windows(2).filter(|w| f(w[1]) > f(w[0]) + 1e-9).count() }
fn polyak(fs: f64) -> impl Fn(usize, f64, f64) -> f64 { move |_, x, g| if g != 0.0 { (f(x) - fs) / (g * g) } else { 0.0 } }
fn row(label: &str, vals: &[f64]) {
    let v: Vec<String> = vals.iter().map(|x| format!("{:.4}", x)).collect();
    println!("{:<46}{}", label, v.join(" "));
}
fn line(label: &str, v: String) { println!("{:<46}{}", label, v); }

fn main() {
    let h = 1e-6;
    let (left, right) = ((f(XSTAR) - f(XSTAR - h)) / h, (f(XSTAR + h) - f(XSTAR)) / h);
    row("start km 10: f, subgradient", &[f(X0), sub(X0)]);
    row("km 2: f, slope left, slope right", &[f(XSTAR), left, right]);
    let mut xb = 0.0;
    for i in 0..12001 { let x = i as f64 / 1000.0; if f(x) < f(xb) { xb = x; } }
    row("scan of 12001 points, 0 to 12 km: best x, f", &[xb, f(xb)]);
    assert!((left + 1.0).abs() < 1e-6 && (right - 1.0).abs() < 1e-6 && left <= 0.0 && 0.0 <= right);
    assert!((xb - XSTAR).abs() < 1e-12 && (f(xb) - FSTAR).abs() < 1e-12); // scan meets certificate

    let k = sq(R * G / 1.0).ceil() as usize; // steps for a gap of 1 km
    let a = R / (G * (k as f64).sqrt());
    row("R, G, R*G", &[R, G, R * G]);
    line("steps for a guaranteed gap of 1 km, step a", format!("{} {:.4}", k, a));
    let (xs, al, kept) = run(&|_, _, _| a, k, FSTAR);
    row("fixed step: x_0 .. x_3", &xs[..4]);
    let lhs0 = sq(xs[1] - XSTAR);
    let rhs0 = sq(X0 - XSTAR) - 2.0 * a * (f(X0) - FSTAR) + a * a * G * G;
    row("step 0: |x_1 - x*|^2, one-step bound", &[lhs0, rhs0]);
    let k6 = xs.iter().position(|&x| (x - 6.0).abs() < 1e-9).unwrap();
    let first = xs.iter().position(|&x| (x - XSTAR).abs() < 1e-9).unwrap();
    line("one-step inequality kept, of 576 steps", format!("{}", kept));
    line("first step within 1e-9 km of km 6, of km 2", format!("{} {}", k6, first));
    line("steps on which f rose, of 576", format!("{}", rises(&xs)));
    let fk: Vec<f64> = xs[40..61].iter().map(|&x| f(x)).collect();
    row("f(x_k), k = 40 .. 60", &fk);
    let bk: Vec<f64> = (40..61).map(|j| best_gap(&xs, j + 1) + FSTAR).collect();
    row("best f so far, k = 40 .. 60", &bk);
    row("576 steps: best gap, proved bound", &[best_gap(&xs, k), bound(&al)]);
    assert!(kept == k && rises(&xs) > 0 && best_gap(&xs, k) <= bound(&al) + 1e-12);
    assert!((bound(&al) - R * G / (k as f64).sqrt()).abs() < 1e-9); // bound(al) is RG/sqrt(K)
    assert!(k6 == 12 && first == 12 + 1 + 33); // by hand: 12 moves of 1/3 km, 1 at km 6, 33 of 1/9
    assert!(rises(&xs) == (k - first) / 2 && best_gap(&xs, k) < 1e-9 && f(xs[k - 1]) - FSTAR > 1e-9);

    let (mut gaps, mut bnds) = (vec![], vec![]);
    for &k2 in &[16usize, 36, 144] {
        let a2 = R / (G * (k2 as f64).sqrt());
        let (x2, al2, kp) = run(&|_, _, _| a2, k2, FSTAR);
        gaps.push(best_gap(&x2, k2)); bnds.push(bound(&al2));
        assert!(kp == k2 && gaps[gaps.len() - 1] <= bnds[bnds.len() - 1]);
    }
    row("K = 16, 36, 144: guarantee RG/sqrt(K)", &bnds);
    row("K = 16, 36, 144: best gap found", &gaps);

    let (xd, ad, kd) = run(&|j, _, _| 1.0 / ((j + 1) as f64).sqrt(), 576, FSTAR);
    let ns = [10usize, 100, 576];
    let bg: Vec<f64> = ns.iter().map(|&n| best_gap(&xd, n)).collect();
    let bd: Vec<f64> = ns.iter().map(|&n| bound(&ad[..n])).collect();
    row("a_k = 1/sqrt(k+1): best gap at 10, 100, 576", &bg);
    row("  proved bound at 10, 100, 576", &bd);
    row("  last point's gap at 576", &[f(xd[576]) - FSTAR]);
    line("  steps on which f rose, of 576", format!("{}", rises(&xd)));
    assert!(kd == 576 && (0..3).all(|i| bg[i] <= bd[i]));
    assert!(f(xd[576]) - FSTAR > bg[2] + 0.04); // the last point is not the best

    let (xp, ap, kp) = run(&polyak(FSTAR), 2, FSTAR);
    row("Polyak: x_0, x_1, x_2", &xp);
    let fp: Vec<f64> = xp.iter().map(|&x| f(x)).collect();
    row("Polyak: f at those points", &fp);
    row("Polyak: step sizes a_0, a_1", &ap);
    let prom = R * R - sq(f(X0) - FSTAR) / (G * G);
    row("Polyak: |x_1 - x*|^2, promised at most", &[sq(xp[1] - XSTAR), prom]);
    assert!((xp[2] - XSTAR).abs() < 1e-12 && kp == 2);
    assert!(sq(xp[1] - XSTAR) <= prom);
    row("many-variable lower bound RG/(2(1 + sqrt K))", &[R * G / (2.0 * (1.0 + 576f64.sqrt()))]);

    println!("what breaks:");
    let (xc, _, _) = run(&|_, _, _| 0.7, 5000, FSTAR);
    row("  fixed step 0.7: best gap at 50, 5000", &[best_gap(&xc, 50), best_gap(&xc, 5000)]);
    row("  fixed step 0.7: x_7 .. x_10", &xc[7..11]);
    let rs = 0.5;
    let ars = rs / (G * (k as f64).sqrt());
    let (xr, ar, _) = run(&|_, _, _| ars, k, FSTAR);
    row("  R guessed 0.5: step, x_576, gap, promised", &[ar[0], xr[k], best_gap(&xr, k), rs * G / (k as f64).sqrt()]);
    let (x0g, _, _) = run(&polyak(0.0), 100, 0.0);
    row("  Polyak, guess f(x*) = 0: x_0 .. x_4", &x0g[..5]);
    row("  Polyak, guess f(x*) = 0: best gap at 100", &[best_gap(&x0g, 100)]);
    let (x4g, _, _) = run(&polyak(4.0), 4, 4.0);
    row("  Polyak, guess f(x*) = 4: x_0 .. x_4", &x4g);
    let (x6, _, _) = run(&polyak(6.0), 100, 6.0);
    let mut v6 = x6[..4].to_vec(); v6.push(best_gap(&x6, 100));
    row("  Polyak, guess f(x*) = 6: x_0 .. x_3, gap", &v6);
    assert!(best_gap(&xc, 5000) > 0.29 && best_gap(&xr, k) > rs * G / (k as f64).sqrt());
    assert!((xr[k] - 239.0 / 72.0).abs() < 1e-9); // by hand: 192 moves of 1/48 km, 1 at km 6, 383 of 1/144
    assert!(best_gap(&x0g, 100) > 0.99 && (x6[x6.len() - 1] - 3.0).abs() < 1e-12 && (x4g[4] - 1.0).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
