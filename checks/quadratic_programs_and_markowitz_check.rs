// Quadratic programs: minimum-variance weights over five assets, no shorting.
// Standard library only, no crates. Same roads and output as the Python check.
const NAMES: [&str; 5] = ["UK shares", "World shares", "Property", "Gilts", "Gold"];
const SD: [f64; 5] = [16.0, 15.0, 18.0, 8.0, 14.0]; // yearly standard deviation, percent
const N: usize = 5;
type M = Vec<Vec<f64>>;

fn cov(rho: &[(usize, usize, f64)]) -> M { // Sigma: correlation times both deviations
    let mut s = vec![vec![0.0; N]; N];
    for i in 0..N { s[i][i] = SD[i] * SD[i]; }
    for &(i, j, r) in rho { s[i][j] = SD[i] * SD[j] * r; s[j][i] = SD[j] * SD[i] * r; }
    s
}

fn solve(m: &M, r: &[f64]) -> Vec<f64> { // Gaussian elimination, partial pivoting
    let n = r.len();
    let mut a: M = (0..n).map(|i| { let mut row = m[i].clone(); row.push(r[i]); row }).collect();
    for c in 0..n {
        let mut p = c;
        for i in c..n { if a[i][c].abs() > a[p][c].abs() { p = i; } }
        a.swap(c, p);
        for i in 0..n {
            if i != c {
                let f = a[i][c] / a[c][c];
                for j in c..=n { a[i][j] -= f * a[c][j]; }
            }
        }
    }
    (0..n).map(|i| a[i][n] / a[i][i]).collect()
}

fn kkt(q: &M, rows: &M, rhs: &[f64]) -> (Vec<f64>, Vec<f64>) { // [[Q, A^T], [A, 0]] [x; nu] = [-c; b], c = 0
    let m = rows.len();
    let mut big: M = (0..N).map(|i| { let mut r = q[i].clone(); for k in 0..m { r.push(rows[k][i]); } r }).collect();
    for k in 0..m { let mut r = rows[k].clone(); r.extend(vec![0.0; m]); big.push(r); }
    let mut b = vec![0.0; N]; b.extend_from_slice(rhs);
    let z = solve(&big, &b);
    (z[..N].to_vec(), z[N..].to_vec())
}

fn var(q: &M, w: &[f64]) -> f64 { let mut s = 0.0; for i in 0..N { for j in 0..N { s += w[i] * q[i][j] * w[j]; } } s }
fn mvec(q: &M, w: &[f64]) -> Vec<f64> { (0..N).map(|i| { let mut s = 0.0; for j in 0..N { s += q[i][j] * w[j]; } s }).collect() }
fn unit(i: usize) -> Vec<f64> { (0..N).map(|j| if j == i { 1.0 } else { 0.0 }).collect() }
fn pct(w: &[f64]) -> String { w.iter().map(|x| format!("{:7.2}", 100.0 * x)).collect::<Vec<_>>().join(" ") }
fn pounds(x: f64) -> String { // thousands separated with commas
    let s = format!("{}", x.round() as i64);
    let mut out = String::new();
    for (k, ch) in s.chars().enumerate() { if k > 0 && (s.len() - k) % 3 == 0 { out.push(','); } out.push(ch); }
    out
}

fn pinned(q: &M, pins: &[usize]) -> (Vec<f64>, Vec<f64>) { // least variance with the assets in pins held at 0
    let mut rows = vec![vec![1.0; N]]; let mut rhs = vec![1.0];
    for &i in pins { rows.push(unit(i)); rhs.push(0.0); }
    kkt(q, &rows, &rhs)
}

fn active_set(q: &M, w0: &[f64], show: bool) -> (Vec<f64>, Vec<f64>, Vec<f64>) {
    let (mut w, mut wset, mut k, mut path): (Vec<f64>, Vec<usize>, usize, Vec<f64>) = (w0.to_vec(), vec![], 0, vec![]);
    loop {
        path.push(var(q, &w)); assert!(k < 20, "the method must finish");
        let (target, mult) = pinned(q, &wset);
        let d: Vec<f64> = (0..N).map(|i| target[i] - w[i]).collect();
        if d.iter().fold(0.0f64, |a, x| a.max(x.abs())) < 1e-12 { // at the target: read the multipliers
            let lam: Vec<f64> = (0..wset.len()).map(|t| -mult[1 + t]).collect();
            if show {
                let parts: Vec<String> = wset.iter().zip(&lam).map(|(&i, l)| format!("lambda {} {:.4}", NAMES[i], l)).collect();
                println!("k={}  V {:.4}  check: {}", k, path[k], parts.join("  "));
            }
            let mut lo = 0;
            for t in 0..lam.len() { if lam[t] < lam[lo] { lo = t; } }
            if lam.is_empty() || lam[lo] >= 0.0 { return (w, path, lam); }
            wset.remove(lo);
        } else {
            let (mut alpha, mut block) = (1.0, None);
            for i in 0..N { if d[i] < -1e-12 && -w[i] / d[i] < alpha { alpha = -w[i] / d[i]; block = Some(i); } }
            w = (0..N).map(|i| w[i] + alpha * d[i]).collect();
            if let Some(b) = block { wset.push(b); }
            for &i in &wset { w[i] = 0.0; }
            if show {
                let what = match block { Some(b) => format!("blocked by {}", NAMES[b]), None => "full step".to_string() };
                println!("k={}  V {:.4}  alpha {:.4}  {}  w {}", k, path[k], alpha, what, pct(&w));
            }
        }
        k += 1;
    }
}

fn enumerate_supports(q: &M) -> (Vec<f64>, usize) { // every set of held assets, keep the long-only ones
    let (mut best, mut feasible): (Option<Vec<f64>>, usize) = (None, 0);
    for mask in 1..(1usize << N) {
        let pins: Vec<usize> = (0..N).filter(|i| mask >> i & 1 == 0).collect();
        let (x, _) = pinned(q, &pins);
        if x.iter().cloned().fold(f64::INFINITY, f64::min) >= -1e-12 {
            feasible += 1;
            if best.as_ref().map_or(true, |b| var(q, &x) < var(q, b)) { best = Some(x); }
        }
    }
    (best.unwrap(), feasible)
}

fn grid(q: &M) -> (f64, Vec<f64>, usize) { // every weight a multiple of 2.5%
    let s = 40usize; let sf = s as f64;
    let (mut bv, mut bw, mut count) = (f64::INFINITY, vec![], 0);
    for a in 0..=s { for b in 0..=(s - a) { for c in 0..=(s - a - b) { for d in 0..=(s - a - b - c) {
        let w = vec![a as f64 / sf, b as f64 / sf, c as f64 / sf, d as f64 / sf, (s - a - b - c - d) as f64 / sf];
        count += 1;
        let v = var(q, &w);
        if v < bv { bv = v; bw = w; }
    } } } }
    (bv, bw, count)
}

fn main() {
    let rho = [(0, 1, 0.9), (0, 2, 0.7), (1, 2, 0.5), (1, 4, 0.2), (2, 3, 0.3), (2, 4, 0.2), (3, 4, 0.3)];
    let s = cov(&rho);
    let eq = vec![0.2; N];
    println!("covariance, percent squared: UK, World, Property, Gilts, Gold");
    for row in &s { println!("  {}", row.iter().map(|x| format!("{:6.1}", x)).collect::<Vec<_>>().join(" ")); }
    let (wu, nu) = pinned(&s, &[]);
    println!("shorts allowed, one KKT solve: w {}  V {:.4}  sd {:.4}  nu {:.4}", pct(&wu), var(&s, &wu), var(&s, &wu).sqrt(), nu[0]);
    println!("equal weights: V {:.4}  sd {:.4}", var(&s, &eq), var(&s, &eq).sqrt());
    let (w, path, lam) = active_set(&s, &eq, true);
    let v = var(&s, &w); let m = mvec(&s, &w);
    println!("answer w {}  V {:.4}  sd {:.4}", pct(&w), v, v.sqrt());
    println!("answer on 1,000,000 pounds: {}", w.iter().map(|x| pounds(1e6 * x)).collect::<Vec<_>>().join("  "));
    println!("cov with portfolio (Sigma w): {}  lambda Property {:.4}", m.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(" "), m[2] - v);
    let det = 64.0 * 196.0 - 33.6f64.powi(2);
    let (g, o) = (196.0 - 33.6, 64.0 - 33.6); // rows of the 2-by-2 inverse, times det, summed
    println!("by hand on UK, Gilts, Gold: det {:.2}  gilts {:.1}  gold {:.1}  1/256 {:.8}  {:.1}/det {:.8}", det, g, o, 1.0 / 256.0, g + o, (g + o) / det);
    let vh = 1.0 / (1.0 / 256.0 + (g + o) / det);
    let h = vec![vh / 256.0, 0.0, 0.0, vh * g / det, vh * o / det];
    let mh = mvec(&s, &h);
    println!("  V {:.4}  w {}  World row {:.4}  lambda World {:.4}", vh, pct(&h), mh[1], mh[1] - vh);
    let (we, feas) = enumerate_supports(&s);
    println!("enumeration: 31 supports, {} long-only, best V {:.4}  w {}", feas, var(&s, &we), pct(&we));
    let (gv, gw, cnt) = grid(&s);
    println!("grid: {} portfolios, best V {:.4}  w {}", cnt, gv, pct(&gw));
    let (wf, _) = kkt(&s, &vec![vec![1.0; N], unit(2)], &[1.0, 0.01]);
    println!("force 1% into Property: V {:.4}  rise {:.4}  2*lambda*0.01 {:.4}", var(&s, &wf), var(&s, &wf) - v, 2.0 * lam[0] * 0.01);
    let c0: Vec<f64> = wu.iter().map(|x| x.max(0.0)).collect(); let cs: f64 = c0.iter().sum();
    let clip: Vec<f64> = c0.iter().map(|x| x / cs).collect();
    println!("wrong, clip and rescale: w {}  V {:.4}", pct(&clip), var(&s, &clip));
    println!("wrong, drop the shorted, re-solve: V {:.4}  sd {:.4}", vh, vh.sqrt());
    let mut rp = rho.to_vec(); rp[2].2 = -0.2;
    let p = cov(&rp);
    let (wp, _, _) = active_set(&p, &eq, false); let (wpe, _) = enumerate_supports(&p); let (gpv, _, _) = grid(&p);
    println!("patched World-Property -0.2: active set V {:.4}  w {}", var(&p, &wp), pct(&wp));
    println!("  enumeration V {:.4}  w {}  grid V {:.4}", var(&p, &wpe), pct(&wpe), gpv);
    let mut rt = rho.to_vec(); rt[6].2 = 0.6;
    let t = cov(&rt); let (wt, _, _) = active_set(&t, &eq, false);
    println!("try, Gilts-Gold correlation 0.6: w {}  V {:.4}", pct(&wt), var(&t, &wt));
    let f: Vec<f64> = (0..N).map(|i| if i == 2 { 2.0 / 3.0 } else { 1.0 }).collect(); // Property's deviation 18 -> 12
    let t: M = (0..N).map(|i| (0..N).map(|j| s[i][j] * f[i] * f[j]).collect()).collect(); let (wt, _, _) = active_set(&t, &eq, false);
    println!("try, Property deviation 12: w {}  V {:.4}", pct(&wt), var(&t, &wt));
    println!("chart, pass k        {}", (0..path.len()).map(|k| format!("{:7}", k)).collect::<Vec<_>>().join(" "));
    println!("chart, variance      {}", path.iter().map(|x| format!("{:7.2}", x)).collect::<Vec<_>>().join(" "));

    assert!((0..N).filter(|&i| w[i] > 0.0).all(|i| (m[i] - v).abs() < 1e-9), "held assets: equal covariance with the portfolio");
    assert!(((m[2] - v) - lam[0]).abs() < 1e-9 && lam[0] > 0.0, "Property's multiplier, two ways, and its sign");
    assert!(w.iter().all(|&x| x >= 0.0) && (w.iter().sum::<f64>() - 1.0).abs() < 1e-12, "long-only and fully invested");
    assert!((var(&s, &we) - v).abs() < 1e-9 && (0..N).all(|i| (w[i] - we[i]).abs() < 1e-9), "enumeration agrees");
    assert!(v <= gv && gv < v + 0.05, "grid never beats the answer and gets close");
    assert!(wu.iter().any(|&x| x < 0.0) && var(&s, &wu) < v, "shorts allowed: lower but infeasible");
    assert!(wf.iter().all(|&x| x >= 0.0) && ((var(&s, &wf) - v) - 2.0 * lam[0] * 0.01).abs() < 0.015, "multiplier predicts the rise");
    assert!((vh - var(&s, &pinned(&s, &[1, 2]).0)).abs() < 1e-9, "hand algebra agrees with elimination");
    assert!(mh[1] - vh < -1.0, "World's multiplier is negative where the shorted assets were dropped");
    assert!(var(&p, &wp) > gpv + 1.0, "non-convex: the KKT point is beaten by the grid");
    println!("ALL CHECKS PASS");
}
