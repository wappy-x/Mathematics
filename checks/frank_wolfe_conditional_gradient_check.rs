// Frank-Wolfe (conditional gradient) on the weight simplex -- the check behind the card.
// std only.  Minimise f(w) over weights w >= 0 that sum to 1.
// Part 1: three assets, f(w) = |w - t|^2 with t = (0.7, 0.4, -0.1), start (1, 0, 0).
// Part 2: a 2,000-asset index tracker fitted to 250 simulated daily returns (percent).
const T3: [f64; 3] = [0.7, 0.4, -0.1];

fn sum(it: impl Iterator<Item = f64>) -> f64 { // compensated, as Python's sum of floats
    let (mut f, mut c) = (0.0f64, 0.0f64);
    for x in it {
        let t = f + x; c += if f.abs() >= x.abs() { (f - t) + x } else { (x - t) + f }; f = t;
    }
    if c != 0.0 && c.is_finite() { f + c } else { f }
}
fn dot(u: &[f64], v: &[f64]) -> f64 { sum(u.iter().zip(v).map(|(a, b)| a * b)) }
fn corner(g: &[f64]) -> usize { // the oracle: best corner
    let mut s = 0; for i in 1..g.len() { if g[i] < g[s] { s = i } } s
}
fn fw_gap(g: &[f64], w: &[f64], s: usize) -> f64 { dot(g, w) - g[s] }
fn fmt(v: &[f64]) -> String { v.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(" ") }
fn f3(w: &[f64]) -> f64 { sum(w.iter().zip(&T3).map(|(a, b)| (a - b) * (a - b))) }
fn g3(w: &[f64]) -> Vec<f64> { w.iter().zip(&T3).map(|(a, b)| 2.0 * (a - b)).collect() }
fn line3(w: &[f64], d: &[f64]) -> f64 {
    -sum((0..3).map(|i| (w[i] - T3[i]) * d[i])) / sum(d.iter().map(|c| c * c))
}
fn ind(i: usize, j: usize) -> f64 { if i == j { 1.0 } else { 0.0 } }
fn project(v: &[f64]) -> Vec<f64> { // projection onto the simplex: sort, shift, clip
    let mut u = v.to_vec(); u.sort_by(|a, b| b.partial_cmp(a).unwrap());
    let (mut run, mut tau) = (0.0, 0.0);
    for (j, x) in u.iter().enumerate() {
        run += x;
        if x - (run - 1.0) / (j as f64 + 1.0) > 0.0 { tau = (run - 1.0) / (j as f64 + 1.0) }
    }
    v.iter().map(|x| (x - tau).max(0.0)).collect()
}
fn run3(mut w: Vec<f64>, step: f64, away: bool, kmax: usize) -> (usize, Vec<f64>, Vec<Vec<f64>>, f64) {
    let mut path = vec![w.clone()];
    for k in 0..kmax {
        let g = g3(&w); let s = corner(&g); let gw = dot(&g, &w);
        if gw - g[s] <= 1e-6 { return (k, w, path, gw - g[s]) }
        let mut a = 3;
        for i in 0..3 { if w[i] > 0.0 && (a == 3 || g[i] > g[a]) { a = i } }
        let on = w.iter().filter(|x| **x > 0.0).count();
        let drop = away && on > 1 && g[a] - gw > gw - g[s]; // away beats toward
        let (d, top): (Vec<f64>, f64) = if drop {
            ((0..3).map(|i| w[i] - ind(i, a)).collect(), w[a] / (1.0 - w[a]))
        } else { ((0..3).map(|i| ind(i, s) - w[i]).collect(), 1.0) };
        let gam = if step > 0.0 { step } else { top.min(line3(&w, &d).max(0.0)) };
        w = (0..3).map(|i| w[i] + gam * d[i]).collect();
        if drop && gam == top { w[a] = 0.0 } // the away corner leaves the support
        path.push(w.clone());
    }
    let g = g3(&w); let gap = fw_gap(&g, &w, corner(&g)); (kmax, w, path, gap)
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 { // SplitMix64: a draw in (0, 1]
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 * 2f64.powi(-53)
    }
    fn normal(&mut self) -> f64 { // Box-Muller, cosine half only
        let u = self.uniform();
        (-2.0 * u.ln()).sqrt() * (2.0 * std::f64::consts::PI * self.uniform()).cos()
    }
}

fn main() {
    // ---- Part 1: the three-asset example, three roads to one answer ----
    let w = vec![1.0, 0.0, 0.0]; let g = g3(&w); let s = corner(&g);
    let d: Vec<f64> = (0..3).map(|i| ind(i, s) - w[i]).collect();
    let gam = 1f64.min(line3(&w, &d).max(0.0));
    let w1: Vec<f64> = (0..3).map(|i| w[i] + gam * d[i]).collect();
    let s1 = corner(&g3(&w1));
    println!("toy: f(w0) = {:.4}, gradient = {}, corner = e{}, gap = {:.4}", f3(&w), fmt(&g), s + 1, fw_gap(&g, &w, s));
    println!("toy: step = {:.4}, w1 = {}, f(w1) = {:.4}, gradient = {}, gap = {:.4}", gam, fmt(&w1), f3(&w1), fmt(&g3(&w1)), fw_gap(&g3(&w1), &w1, s1));
    let pg = project(&(0..3).map(|i| w[i] - 0.5 * g[i]).collect::<Vec<_>>()); // step 1/L = 1/2
    let mut best = (f64::INFINITY, 0, 0);
    for i in 0..=100 { for j in 0..=(100 - i) {
        let v = f3(&[i as f64 / 100.0, j as f64 / 100.0, (100 - i - j) as f64 / 100.0]);
        if v < best.0 { best = (v, i, j) }
    } }
    println!("toy: projection of t = {}, projected-gradient step = {}", fmt(&project(&T3)), fmt(&pg));
    println!("toy: grid of 5151 points, best = ({:.2}, {:.2}, {:.2}), f = {:.4}, f(w0) - f* = {:.4}", best.1 as f64 / 100.0,
             best.2 as f64 / 100.0, (100 - best.1 - best.2) as f64 / 100.0, best.0, f3(&w) - best.0);
    let cc3 = (0..9).map(|p| 2.0 * sum((0..3).map(|k| (ind(p / 3, k) - ind(p % 3, k)).powi(2)))).fold(0.0, f64::max);
    println!("toy: curvature constant C = 2 * max |e_i - e_j|^2 = {:.4}, bound 2C/(1+2) = {:.4}", cc3, 2.0 * cc3 / 3.0);
    let pt = project(&T3); assert!((0..3).map(|i| (w1[i] - pt[i]).abs()).fold(0.0, f64::max) < 1e-12); // = projection
    assert!((0..3).map(|i| (w1[i] - pg[i]).abs()).fold(0.0, f64::max) < 1e-12); // = projected gradient
    assert!((best.0 - f3(&w1)).abs() < 1e-12); // = the grid's best
    assert!(fw_gap(&g3(&w1), &w1, s1) < 1e-12 && 1e-12 < fw_gap(&g, &w, s)); // the gap certifies it
    assert!((fw_gap(&g, &w, s) + (f3(&(0..3).map(|i| w[i] + 1e-6 * d[i]).collect::<Vec<_>>()) - f3(&(0..3).map(|i| w[i] - 1e-6 * d[i]).collect::<Vec<_>>())) / 2e-6).abs() < 1e-8); // gap = minus the slope

    // ---- what breaks, on the same three assets ----
    let c3 = vec![1.0 / 3.0; 3];
    let (kz, wz, pz, _) = run3(c3.clone(), 0.0, false, 1_000_000);
    let (ka, wa, pa, _) = run3(c3.clone(), 0.0, true, 1_000_000);
    let (_, wf, _, gf) = run3(c3.clone(), 0.5, false, 200);
    let paths = |p: &[Vec<f64>]| p.iter().map(|x| fmt(x)).collect::<Vec<_>>().join(" | ");
    println!("zigzag from the centre: plain {} steps to gap <= 1e-6, third weight {:.7}", kz, wz[2]);
    println!("zigzag from the centre: away steps {} steps, third weight {:.4}", ka, wa[2]);
    println!("figure, plain path {}", paths(&pz[..5]));
    println!("figure, away path {}", paths(&pa));
    println!("fixed step 0.5, 200 steps: gap = {:.4}, f - f* = {:.4}", gf, f3(&wf) - f3(&w1));
    let gc: Vec<f64> = (0..3).map(|i| -2.0 * (c3[i] - c3[i])).collect(); // gradient of -|w - c|^2 at c
    let lowest = (0..3).map(|i| -sum((0..3).map(|j| (ind(i, j) - c3[j]).powi(2)))).fold(f64::INFINITY, f64::min);
    println!("concave cost -|w - c|^2 at the centre: gap = {:.4}, above the minimum by {:.4}", fw_gap(&gc, &c3, corner(&gc)), 0.0 - lowest);
    assert!(ka < 10 && wa[2] == 0.0);
    assert!(kz > 100 * ka); assert!(gf > 0.1);

    // ---- Part 2: the 2,000-asset index tracker ----
    let (n, t, tf) = (2000usize, 250usize, 250.0f64);
    let mut rng = Rng(2026);
    let mkt: Vec<f64> = (0..t).map(|_| rng.normal()).collect(); // the market's daily move, percent
    let mut cols: Vec<Vec<f64>> = Vec::new(); // cols[i] = asset i's 250 daily returns
    for _ in 0..n {
        let (beta, sig) = (0.5 + rng.uniform(), 1.0 + 1.5 * rng.uniform());
        cols.push(mkt.iter().map(|m| beta * m + sig * rng.normal()).collect());
    }
    let cap0: Vec<f64> = (0..n).map(|i| ((i + 1) as f64).powf(-0.8)).collect();
    let tot = sum(cap0.iter().copied()); let cap: Vec<f64> = cap0.iter().map(|c| c / tot).collect();
    let mut b = vec![0.0; t]; // the index: capitalisation-weighted
    for i in 0..n { for r in 0..t { b[r] += cap[i] * cols[i][r] } }
    let rho2 = cols.iter().map(|c| dot(c, c)).fold(f64::NEG_INFINITY, f64::max);
    let cc = 8.0 * rho2 / tf; // curvature bound: (2/T)(2 * longest column)^2
    let res0: Vec<f64> = (0..t).map(|r| cols[0][r] - b[r]).collect();
    let mut ri: Vec<f64> = b.iter().map(|x| -x).collect(); // the index weights, summed in reverse order
    for i in (0..n).rev() { for r in 0..t { ri[r] += cap[i] * cols[i][r] } }
    println!("tracker: {} assets, {} days, index top weight {:.4}, curvature bound C = {:.4}", n, t, cap[0], cc);
    println!("tracker: start in asset 1 alone, f(w0) = {:.4}; index weights give f = {:.4}", dot(&res0, &res0) / tf, dot(&ri, &ri) / tf);
    assert!(dot(&ri, &ri) / tf < 1e-20); assert!((sum(cap.iter().copied()) - 1.0).abs() < 1e-12 && cap.iter().all(|&c| c > 1e-12)); // f* = 0: the index is on the simplex

    let tracker = |line: bool, kk: usize| -> Vec<(usize, f64, f64, usize)> {
        let mut w = vec![0.0; n]; w[0] = 1.0; let mut u = res0.clone(); let mut rows = Vec::new();
        for k in 0..=kk {
            let h = dot(&u, &u) / tf; // f(w_k) - f*, since f* = 0
            let g: Vec<f64> = cols.iter().map(|c| 2.0 / tf * dot(c, &u)).collect();
            let s = corner(&g); let gap = fw_gap(&g, &w, s);
            rows.push((k, h, gap, w.iter().filter(|x| **x > 0.0).count()));
            let v: Vec<f64> = (0..t).map(|r| cols[s][r] - b[r] - u[r]).collect(); // residual change toward s
            let mut gam = 2.0 / (k as f64 + 2.0);
            if line { gam = 1f64.min((-dot(&u, &v) / dot(&v, &v)).max(0.0)) }
            for x in w.iter_mut() { *x *= 1.0 - gam } w[s] += gam;
            for r in 0..t { u[r] += gam * v[r] }
            if !line { assert!(dot(&u, &u) / tf <= (1.0 - gam) * h + gam * gam * cc / 2.0 + 1e-12) } // the proof's step
        }
        rows
    };
    let kk = 400; let (op, ls) = (tracker(false, kk), tracker(true, kk));
    println!("    k   f(w_k) - f*        gap   2C/(k+2)  held | line search: f - f*    gap  held");
    for k in [0usize, 1, 2, 5, 10, 20, 50, 100, 200, 300, 400] {
        let ((_, h, gap, m), (_, h2, gap2, m2)) = (op[k], ls[k]);
        println!("{:5} {:12.6} {:10.6} {:10.4} {:5} | {:12.6} {:9.6} {:4}", k, h, gap, 2.0 * cc / (k as f64 + 2.0), m, h2, gap2, m2);
    }
    println!("tracking error, percent a day: {}", [0usize, 100, 400].iter()
        .map(|&k| format!("k = {}: {:.4} and {:.4}", k, op[k].1.sqrt(), ls[k].1.sqrt())).collect::<Vec<_>>().join(", "));
    for (name, rows) in [("open loop", &op), ("line search", &ls)] {
        println!("figure, {}, log10 gap at k = 0, 40, ..., 400: {}", name, (0..=kk).step_by(40)
            .map(|k| format!("{:.2}", rows[k].2.log10())).collect::<Vec<_>>().join(", "));
    }
    println!("figure, log10 2C/(k+2) at k = 0, 40, ..., 400: {}", (0..=kk).step_by(40)
        .map(|k| format!("{:.2}", (2.0 * cc / (k as f64 + 2.0)).log10())).collect::<Vec<_>>().join(", "));
    for rows in [&op, &ls] {
        assert!(rows.iter().all(|&(_, h, gap, _)| h <= gap + 1e-12)); // the gap bounds the error
        assert!(rows.iter().all(|&(k, _, _, m)| m <= k + 1)); // one new asset per step at most
        assert!(rows[1..].iter().all(|&(k, h, _, _)| h <= 2.0 * cc / (k as f64 + 2.0)));
    }
    println!("ALL CHECKS PASS");
}
