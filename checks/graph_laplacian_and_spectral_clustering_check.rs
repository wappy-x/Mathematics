// The graph Laplacian and spectral clustering -- the check behind the card.  std only, no crates.
// The network is synthetic, generated here from seed 2026 by SplitMix64.  Eigenvalues come from
// Jacobi rotations (six friends) and power iteration (5,000 people); pieces are counted by flooding.
use std::collections::HashSet;

struct SplitMix(u64);
impl SplitMix {  // SplitMix64: the same stream in Python and Rust
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}
type Edges = Vec<(usize, usize)>;
fn towns(n: usize, inside: usize, across: usize, seed: u64) -> Edges {
    let (mut rng, half, mut seen, mut edges) = (SplitMix(seed), (n / 2) as u64, HashSet::new(), Vec::new());
    let mut add = |u: u64, v: u64, edges: &mut Edges| -> usize {
        let key = (u.min(v) as usize, u.max(v) as usize);
        if u == v || seen.contains(&key) { return 0; }
        seen.insert(key); edges.push(key); 1
    };
    for base in [0, half] {
        let mut made = 0;
        while made < inside { let u = base + rng.next() % half; let v = base + rng.next() % half; made += add(u, v, &mut edges); }
    }
    let mut left = across;
    while left > 0 { let u = rng.next() % half; let v = half + rng.next() % half; left -= add(u, v, &mut edges); }
    edges
}
fn neighbours(n: usize, edges: &Edges) -> Vec<Vec<usize>> {
    let mut nb = vec![Vec::new(); n];
    for &(u, v) in edges { nb[u].push(v); nb[v].push(u); }
    nb
}
fn lap(nb: &[Vec<usize>], x: &[f64]) -> Vec<f64> {
    (0..nb.len()).map(|i| nb[i].len() as f64 * x[i] - nb[i].iter().map(|&j| x[j]).sum::<f64>()).collect()
}
fn rayleigh(edges: &Edges, x: &[f64]) -> f64 {
    edges.iter().map(|&(u, v)| (x[u] - x[v]).powi(2)).sum::<f64>() / x.iter().map(|v| v * v).sum::<f64>()
}
fn power(nb: &[Vec<usize>], c: f64, steps: usize, deflate: bool) -> Vec<f64> { powerw(nb, c, steps, deflate, &vec![1.0; nb.len()]) }
fn powerw(nb: &[Vec<usize>], c: f64, steps: usize, deflate: bool, r: &[f64]) -> Vec<f64> { // r: square-root degrees, for the normalised Laplacian
    let (n, mut rng) = (nb.len(), SplitMix(7));
    let mut x: Vec<f64> = (0..n).map(|_| (rng.next() >> 11) as f64 / 9007199254740992.0 - 0.5).collect();
    for _ in 0..steps {
        if deflate { let m = x.iter().zip(r).map(|(a, b)| a * b).sum::<f64>() / r.iter().map(|b| b * b).sum::<f64>(); x = x.iter().zip(r).map(|(v, b)| v - m * b).collect(); }
        let xr: Vec<f64> = x.iter().zip(r).map(|(a, b)| a / b).collect();
        x = x.iter().zip(lap(nb, &xr).iter().zip(r)).map(|(a, (l, b))| c * a - l / b).collect();
        let s = x.iter().map(|v| v * v).sum::<f64>().sqrt();
        x = x.iter().map(|v| v / s).collect();
    }
    x
}
fn residual(nb: &[Vec<usize>], x: &[f64], lam: f64) -> f64 { lap(nb, x).iter().zip(x).map(|(a, b)| (a - lam * b).powi(2)).sum::<f64>().sqrt() }
fn judge(edges: &Edges, x: &[f64], n: usize) -> (usize, usize, usize) {
    let side: Vec<bool> = x.iter().map(|&v| v > 0.0).collect();
    let right = (0..n).filter(|&i| side[i] == (i < n / 2)).count();
    (side.iter().filter(|&&b| b).count(), right.max(n - right), edges.iter().filter(|&&(u, v)| side[u] != side[v]).count())
}
fn jacobi(m: &[Vec<f64>]) -> Vec<f64> {
    let (mut a, n) = (m.to_vec(), m.len());
    for _ in 0..50 {
        for p in 0..n {
            for q in p + 1..n {
                if a[p][q].abs() < 1e-300 { continue; }
                let th = (a[q][q] - a[p][p]) / (2.0 * a[p][q]);
                let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (th * th + 1.0).sqrt());
                let c = 1.0 / (t * t + 1.0).sqrt(); let s = t * c;
                for k in 0..n { let (y, z) = (a[k][p], a[k][q]); a[k][p] = c * y - s * z; a[k][q] = s * y + c * z; }
                for k in 0..n { let (y, z) = (a[p][k], a[q][k]); a[p][k] = c * y - s * z; a[q][k] = s * y + c * z; }
            }
        }
    }
    let mut d: Vec<f64> = (0..n).map(|i| a[i][i]).collect();
    d.sort_by(|u, v| u.partial_cmp(v).unwrap());
    d
}
fn pieces(nb: &[Vec<usize>]) -> usize {
    let (mut seen, mut count) = (vec![false; nb.len()], 0);
    for s in 0..nb.len() {
        if seen[s] { continue; }
        let mut stack = vec![s];
        count += 1; seen[s] = true;
        while let Some(v) = stack.pop() {
            for &w in &nb[v] { if !seen[w] { seen[w] = true; stack.push(w); } }
        }
    }
    count
}
fn f6(vs: &[f64]) -> String {
    vs.iter().map(|v| if v.abs() > 5e-7 { format!("{:.6}", v) } else { "0.000000".to_string() }).collect::<Vec<_>>().join(" ")
}
fn matrix(n: usize, edges: &Edges) -> Vec<Vec<f64>> {
    let nb = neighbours(n, edges);
    (0..n).map(|i| (0..n).map(|j| if i == j { nb[i].len() as f64 } else if nb[i].contains(&j) { -1.0 } else { 0.0 }).collect()).collect()
}
fn main() {
    // ---- six friends: Ana Ben Cal | Dev Eve Fay, one bridge Cal-Dev ----
    let six: Edges = vec![(0, 1), (0, 2), (1, 2), (2, 3), (3, 4), (3, 5), (4, 5)];
    let ev = jacobi(&matrix(6, &six));
    let closed = (5.0 - 17f64.sqrt()) / 2.0;
    let f0 = power(&neighbours(6, &six), 6.0, 400, true);
    let f: Vec<f64> = f0.iter().map(|v| v / f0[0]).collect();
    println!("six: degrees {:?}  Cal's row {:?}", neighbours(6, &six).iter().map(|r| r.len()).collect::<Vec<_>>(),
             matrix(6, &six)[2].iter().map(|&v| v as i64).collect::<Vec<_>>());
    println!("six: eigenvalues {}", f6(&ev));
    println!("six: lambda2 Jacobi {:.6}  (5 - sqrt 17)/2 {:.6}  Rayleigh {:.6}", ev[1], closed, rayleigh(&six, &f));
    let esum: f64 = six.iter().map(|&(u, v)| (f[u] - f[v]).powi(2)).sum();
    println!("six: Fiedler vector, Ana = 1: {}  links cut {}  edge sum {:.6}  length^2 {:.6}", f6(&f), judge(&six, &f, 6).2, esum, f.iter().map(|v| v * v).sum::<f64>());
    let nobridge: Edges = six.iter().enumerate().filter(|&(i, _)| i != 3).map(|(_, &e)| e).collect();
    let ev0 = jacobi(&matrix(6, &nobridge));
    let zeros = ev0.iter().filter(|v| v.abs() < 1e-9).count();
    println!("six, bridge cut: eigenvalues {}  zeros {}  pieces by flood {}  exactly 0.0: {}", f6(&ev0), zeros,
             pieces(&neighbours(6, &nobridge)), ev0.iter().filter(|&&v| v == 0.0).count());
    let prod = ev[1] * ev[2] * ev[3] * ev[4] * ev[5];
    let trees = (0..49).filter(|k| k / 7 < k % 7).filter(|k| pieces(&neighbours(6, &six.iter().enumerate()
        .filter(|&(i, _)| i != k / 7 && i != k % 7).map(|(_, &e)| e).collect())) == 1).count();
    println!("six: product of nonzero eigenvalues / 6 = {:.6}  spanning trees by listing {}  4 x cut / n for Ana Ben Cal | Dev Eve Fay {:.6}", prod / 6.0, trees, 4.0 / 6.0);
    assert!((ev[1] - closed).abs() < 1e-9 && (rayleigh(&six, &f) - closed).abs() < 1e-9 && judge(&six, &f, 6).2 == 1);
    assert!(zeros == 2 && pieces(&neighbours(6, &nobridge)) == 2 && (prod / 6.0).round() as usize == trees && trees == 9);
    // ---- 5,000 people in two towns of 2,500: 25,000 links inside each town, 1,250 across ----
    let (n, inside, across) = (5000usize, 25000usize, 1250usize);
    let e = towns(n, inside, across, 2026);
    let (nb, sq) = (neighbours(n, &e), (n as f64).sqrt());
    let deg: Vec<usize> = nb.iter().map(|r| r.len()).collect();
    println!("big: people {}  links {} = 2 x {} inside + {} across  degree min {} mean {:.6} max {}", n, e.len(), inside, across, deg.iter().min().unwrap(),
             deg.iter().sum::<usize>() as f64 / n as f64, deg.iter().max().unwrap());
    let top = power(&nb, 0.0, 300, false);
    let (lmax, bound) = (rayleigh(&e, &top), 4.0 * across as f64 / n as f64);
    let (c, x) = (lmax + 1.0, power(&nb, lmax + 1.0, 400, true));
    let (lam2, (size, right, cut)) = (rayleigh(&e, &x), judge(&e, &x, n));
    let res = residual(&nb, &x, lam2);
    println!("big: largest eigenvalue, 300-step estimate {:.6}  shift c {:.6}", lmax, c);
    println!("big: lambda2 {:.6}  residual below 1e-9 {}  bound 4 x 1250 / 5000 {:.6}", lam2, if res < 1e-9 { "yes" } else { "no" }, bound);
    println!("big: sign split {} | {}  in their right town {}  links cut {}", size, n - size, right, cut);
    let mut s: Vec<f64> = x.iter().map(|v| v * sq).collect();
    s.sort_by(|u, v| u.partial_cmp(v).unwrap());
    let pts: Vec<String> = (0..21).map(|i| format!("{}:{:.2}", (i * 250).min(n - 1) + 1, s[(i * 250).min(n - 1)])).collect();
    println!("chart, rank:entry x sqrt(n): {}", pts.join(" "));
    assert!(lam2 <= bound && right == n && cut == across && res < 1e-6 && pieces(&nb) == 1);
    let ecut: Edges = e.iter().filter(|&&(u, v)| (u < n / 2) == (v < n / 2)).cloned().collect();
    let z = power(&neighbours(n, &ecut), c, 200, true);
    println!("big, the 1250 across removed: lambda2 {}  pieces by flood {}", f6(&[rayleigh(&ecut, &z)]), pieces(&neighbours(n, &ecut)));
    assert!(rayleigh(&ecut, &z) < 1e-9 && pieces(&neighbours(n, &ecut)) == 2);
    // ---- what breaks ----
    let w = power(&nb, c, 400, false);
    let ws = judge(&e, &w, n).0;
    println!("mistake, average not removed: value {}  split {} | {}", f6(&[rayleigh(&e, &w)]), ws, n - ws);
    let (ts, tr, tc) = judge(&e, &top, n);
    println!("mistake, top eigenvector after 300 steps: split {} | {}  in right town {}  links cut {} of {}", ts, n - ts, tr, tc, e.len());
    let et: Edges = e.iter().cloned().chain([(0, 5000), (5000, 5001), (5001, 5002)]).collect();
    let t = power(&neighbours(n + 3, &et), c, 1000, true);
    let weight = t[n..].iter().map(|v| v * v).sum::<f64>() + t[0] * t[0];
    let (ts, tr, tc) = judge(&et, &t, n);
    println!("tail of 3 on person 0: lambda2 {:.6}  weight on the 4 {:.6}  split {} | {}  right town {}  links cut {}",
             rayleigh(&et, &t), weight, ts, n + 3 - ts, tr, tc);
    assert!(rayleigh(&et, &t) < lam2 && weight > 0.5);
    for a in [10000usize, 20000] {
        let (ew, half) = (towns(n, inside, a, 2026), (n / 2) as f64); let nw = neighbours(n, &ew);
        let (xw, xn) = (power(&nw, c, 400, true), powerw(&nw, 2.0, 400, true, &nw.iter().map(|r| (r.len() as f64).sqrt()).collect::<Vec<_>>()));
        let ((sw, rw, _), rn) = (judge(&ew, &xw, n), judge(&ew, &xn, n).1);
        println!("try: {} across (each person: {:.0} home, {:.0} across), lambda2 {:.4}  town split 4 x cut / n {:.6}  sign split {} | {}  in their right town {}  normalised L {}",
                 a, 2.0 * inside as f64 / half, a as f64 / half, rayleigh(&ew, &xw), 4.0 * a as f64 / n as f64, sw, n - sw, rw, rn);
    }
    let x30 = power(&nb, c, 30, true);
    println!("try: 30 steps only, in their right town {}  lambda2 {:.6}", judge(&e, &x30, n).1, rayleigh(&e, &x30));
    println!("ALL CHECKS PASS");
}
