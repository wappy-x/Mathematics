// Best approximation and Bessel's inequality: three harmonics fitted to a tide record.
// Rust std only. Prints exactly what the Python check prints.
use std::f64::consts::PI;

const DAY: f64 = 24.84; const M: usize = 12000; const N: usize = 3;
const SURGE: f64 = 0.40; const X0: f64 = 1.0; const W: f64 = 0.6;
const WAVES: [(usize, f64, f64); 3] = [(1, 0.35, 0.9), (2, 1.20, 0.4), (4, 0.15, 0.8)];

fn tide(x: f64) -> f64 { // illustrative record: height above chart datum, metres
    let mut h = 2.10 + SURGE * f64::max(0.0, 1.0 - (x - X0).abs() / W);
    for &(n, amp, ph) in WAVES.iter() { h += amp * (n as f64 * x - ph).cos(); }
    h
}
fn fsum(v: &[f64]) -> f64 { // compensated sum, the same one Python's sum() uses
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for &x in v {
        let t = s + x;
        if s.abs() >= x.abs() { c += (s - t) + x; } else { c += (x - t) + s; }
        s = t;
    }
    if c != 0.0 && c.is_finite() { s += c; }
    s
}
fn mean(v: &[f64]) -> f64 { fsum(v) / v.len() as f64 }
fn simpson(v: &[f64]) -> f64 { let m = v.len() - 1; fsum(&v.iter().enumerate().map(|(k, x)| x * if k == 0 || k == m { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 }).collect::<Vec<_>>()) / (3 * m) as f64 }
fn grid(m: usize) -> Vec<f64> { (0..m).map(|k| -PI + 2.0 * PI * k as f64 / m as f64).collect() }
fn coeffs(xs: &[f64], hs: &[f64], deg: usize, avg: &dyn Fn(&[f64]) -> f64) -> Vec<f64> { // road 1: by quadrature
    let mut c = vec![avg(hs)];
    for n in 1..=deg {
        let nf = n as f64;
        c.push(2.0 * avg(&xs.iter().zip(hs).map(|(x, h)| h * (nf * x).cos()).collect::<Vec<_>>()));
        c.push(2.0 * avg(&xs.iter().zip(hs).map(|(x, h)| h * (nf * x).sin()).collect::<Vec<_>>()));
    }
    c
}
fn evaluate(c: &[f64], x: f64) -> f64 {
    let t: Vec<f64> = (1..=c.len() / 2).map(|n| c[2 * n - 1] * (n as f64 * x).cos() + c[2 * n] * (n as f64 * x).sin()).collect();
    c[0] + fsum(&t)
}
fn excess(c: &[f64], d: &[f64]) -> f64 {
    let t: Vec<f64> = (1..c.len()).map(|i| (c[i] - d[i]) * (c[i] - d[i])).collect();
    (c[0] - d[0]) * (c[0] - d[0]) + fsum(&t) / 2.0
}
fn kfac(n: usize) -> f64 { (SURGE / PI) * 2.0 * (1.0 - (n as f64 * W).cos()) / ((n * n) as f64 * W) }
fn closed(n: usize) -> (f64, f64) { // road 2: the coefficients in closed form
    if n == 0 { return (2.10 + SURGE * W / (2.0 * PI), 0.0); }
    let k = kfac(n);
    let (mut a, mut b) = (k * (n as f64 * X0).cos(), k * (n as f64 * X0).sin());
    for &(nn, amp, ph) in WAVES.iter() { if n == nn { a += amp * ph.cos(); b += amp * ph.sin(); } }
    (a, b)
}
fn ms(xs: &[f64], hs: &[f64], d: &[f64]) -> f64 {
    mean(&xs.iter().zip(hs).map(|(x, h)| { let r = h - evaluate(d, *x); r * r }).collect::<Vec<_>>())
}
struct Rng(u64);
impl Rng {
    fn next(&mut self) -> f64 { // SplitMix64
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn main() {
    let xs = grid(M); let hs: Vec<f64> = xs.iter().map(|&x| tide(x)).collect();
    let e = mean(&hs.iter().map(|h| h * h).collect::<Vec<_>>());
    let tri = SURGE * W / (2.0 * PI);
    let mut e_closed = 2.10 * 2.10 + fsum(&WAVES.iter().map(|w| w.1 * w.1 / 2.0).collect::<Vec<_>>())
        + SURGE * SURGE * W / (3.0 * PI) + 2.0 * 2.10 * tri;
    for &(n, amp, ph) in WAVES.iter() { e_closed += amp * kfac(n) * (n as f64 * X0 - ph).cos(); }
    let c0 = closed(0).0; let mut energy = vec![c0 * c0];
    for n in 1..=100000 { let (a, b) = closed(n); energy.push((a * a + b * b) / 2.0); }
    let mut bessel = Vec::new(); let mut run = 0.0;
    for &en in energy.iter() { run += en; bessel.push(run); }
    println!("record: lunar day {} h, {} points, surge {:.2} m at {:.2} h", DAY, M, SURGE, (X0 + PI) * DAY / (2.0 * PI));
    println!("||h||^2 (m^2): quadrature {:.9}  closed form {:.9}  Parseval to n=100000 {:.9}", e, e_closed, bessel[100000]);
    let c = coeffs(&xs, &hs, N.max(4), &mean);
    println!(" n    a_n(m)    b_n(m)  ampl.(m)  closed  energy e_n  Bessel B_n  leftover");
    for n in 0..5 {
        let (a, b) = if n == 0 { (c[0], 0.0) } else { (c[2 * n - 1], c[2 * n]) };
        let amp = if n == 0 { a.abs() } else { (a * a + b * b).sqrt() };
        let (ca, cb) = closed(n);
        println!("{:2} {:9.6} {:9.6} {:9.6} {:7.4} {:11.6} {:11.6} {:9.6}", n, a, b, amp,
                 (ca * ca + cb * cb).sqrt(), energy[n], bessel[n], e_closed - bessel[n]);
        assert!((a - ca).abs() < 1e-7 && (b - cb).abs() < 1e-7, "quadrature against closed form");
    }
    let best: Vec<f64> = c[..2 * N + 1].to_vec();
    let left = ms(&xs, &hs, &best);
    println!("best fit leftover: direct {:.6} m^2, E - B_{} {:.6} m^2, rms {:.2} cm", left, N, e - bessel[N], 100.0 * left.sqrt());

    // road 3: least squares by brute force, normal equations solved by elimination
    let mut cols: Vec<Vec<f64>> = vec![vec![1.0; M]];
    for n in 1..=N {
        cols.push(xs.iter().map(|x| (n as f64 * x).cos()).collect());
        cols.push(xs.iter().map(|x| (n as f64 * x).sin()).collect());
    }
    let mut g: Vec<Vec<f64>> = cols.iter().map(|ci| {
        let mut row: Vec<f64> = cols.iter().map(|cj| mean(&ci.iter().zip(cj).map(|(u, v)| u * v).collect::<Vec<_>>())).collect();
        row.push(mean(&ci.iter().zip(&hs).map(|(u, h)| u * h).collect::<Vec<_>>())); row }).collect();
    let k = g.len();
    for i in 0..k {
        let mut p = i;
        for r in i..k { if g[r][i].abs() > g[p][i].abs() { p = r; } }
        g.swap(i, p);
        for r in 0..k {
            if r != i {
                let f = g[r][i] / g[i][i]; let gi = g[i].clone();
                g[r] = g[r].iter().zip(&gi).map(|(u, v)| u - f * v).collect();
            }
        }
    }
    let ls: Vec<f64> = (0..k).map(|i| g[i][k] / g[i][i]).collect();
    let gap = ls.iter().zip(&best).map(|(u, v)| (u - v).abs()).fold(0.0f64, f64::max);
    println!("least squares by elimination: {}; largest gap {:.12}",
             ls.iter().map(|v| format!("{:.4}", v)).collect::<Vec<_>>().join(" "), gap);

    let mut table = vec![2.10, 0.35 * 0.9f64.cos(), 0.35 * 0.9f64.sin(), 1.20 * 0.4f64.cos(), 1.20 * 0.4f64.sin()]; table.resize(2 * N + 1, 0.0);
    let nodes = grid(7); let vals: Vec<f64> = nodes.iter().map(|&x| tide(x)).collect();
    let interp = coeffs(&nodes, &vals, N, &mean);
    let mut nudged = best.clone(); nudged[3] *= 1.05; nudged[4] *= 1.05;
    for (name, d) in [("tide table", table), ("through 7 readings", interp), ("semidiurnal +5%", nudged)] {
        let direct = ms(&xs, &hs, &d);
        println!("{:<19} leftover {:.6}  Pythagoras {:.6}  rms {:.2} cm", name, direct, left + excess(&best, &d), 100.0 * direct.sqrt());
        assert!((direct - left - excess(&best, &d)).abs() < 1e-9, "Pythagoras for the rival");
        assert!(direct > left, "the partial sum beats the rival");
    }
    let mut rng = Rng(20261115);
    let coarse = grid(1200); let hc: Vec<f64> = coarse.iter().map(|&x| tide(x)).collect();
    let lc = ms(&coarse, &hc, &best);
    let mut low = f64::INFINITY;
    for _ in 0..200 {
        let d: Vec<f64> = best.iter().map(|v| v + 0.05 * (2.0 * rng.next() - 1.0)).collect();
        low = low.min(ms(&coarse, &hc, &d));
    }
    println!("200 random rivals within 5 cm: best of them {:.6}, fit {:.6} (coarse grid)", low, lc);
    assert!(low > lc, "no rival beats the partial sum");
    let mut miss = 0; for kk in 0..M { if (hs[kk] - evaluate(&best, xs[kk])).abs() > (hs[miss] - evaluate(&best, xs[miss])).abs() { miss = kk; } }
    println!("largest miss {:.1} cm at {:.2} h; at the surge peak record {:.3} m, fit {:.3} m",
             100.0 * (hs[miss] - evaluate(&best, xs[miss])), (xs[miss] + PI) * DAY / (2.0 * PI), tide(X0), evaluate(&best, X0));
    let u1: Vec<f64> = xs.iter().map(|x| 2f64.sqrt() * x.cos()).collect();
    let u2: Vec<f64> = xs.iter().map(|x| 2f64.sqrt() * (x - 0.5).cos()).collect();
    let n11 = mean(&u1.iter().map(|u| u * u).collect::<Vec<_>>());
    let n12 = mean(&u1.iter().zip(&u2).map(|(u, v)| u * v).collect::<Vec<_>>());
    let skew = n11 * n11 + n12 * n12;
    println!("breaks: skewed pair cos x, cos(x - 0.5): 'Bessel sum' {:.4} against energy {:.4}", skew, n11);
    assert!(skew > 1.5, "Bessel needs an orthonormal family");
    let l24: Vec<f64> = [M / 2, M].iter().map(|&m24| { // a 24.00 h window does not repeat: Simpson's rule at two cut-offs
        let (y24, h24): (Vec<f64>, Vec<f64>) = (0..=m24).map(|kk| (-PI + 2.0 * PI * kk as f64 / m24 as f64, tide(-PI + 2.0 * PI * (24.0 * kk as f64 / m24 as f64) / DAY))).unzip();
        let c24 = coeffs(&y24, &h24, N, &simpson); let l = simpson(&h24.iter().map(|h| h * h).collect::<Vec<_>>()) - excess(&c24, &vec![0.0; 2 * N + 1]);
        println!("breaks: 24.00 h window, {} cells, leftover {:.6} m^2 (rms {:.2} cm), semidiurnal {:.4} m", m24, l, 100.0 * l.sqrt(), (c24[3] * c24[3] + c24[4] * c24[4]).sqrt()); l }).collect();
    assert!((l24[0] - l24[1]).abs() < 1e-8 && l24[1] > left, "the 24 h leftover has settled, and is worse than a lunar day's");
    for n in [10usize, 100, 1000] {
        let bound = (2.0 * (e_closed - bessel[n - 1])).sqrt();
        println!("n = {:4}: amplitude {:.6} mm, Bessel bound {:.6} mm, left after n {:.12}",
                 n, 2000.0 * (energy[n] / 2.0).sqrt(), 1000.0 * bound, e_closed - bessel[n]);
        assert!(energy[n] <= e_closed - bessel[n - 1], "Bessel caps each later coefficient");
    }
    let even = fsum(&(0..=100000).step_by(2).map(|n| energy[n]).collect::<Vec<_>>());
    println!("even harmonics only: Bessel sum {:.6} < {:.6}; gap {:.6} m^2", even, e_closed, e_closed - even);
    println!("chart hours  {}", (0..25).map(|t| format!("{:5}", t)).collect::<Vec<_>>().join(" "));
    let at = |t: usize| -PI + 2.0 * PI * t as f64 / DAY;
    println!("chart record {}", (0..25).map(|t| format!("{:5.2}", tide(at(t)))).collect::<Vec<_>>().join(" "));
    println!("chart fit    {}", (0..25).map(|t| format!("{:5.2}", evaluate(&best, at(t)))).collect::<Vec<_>>().join(" "));
    assert!((e - e_closed).abs() < 1e-7, "quadrature against closed form for ||h||^2");
    assert!((bessel[100000] - e_closed).abs() < 1e-10, "Parseval sum against closed form for ||h||^2");
    assert!((left - (e - bessel[N])).abs() < 1e-7, "leftover equals energy minus Bessel sum");
    assert!(gap < 1e-9, "brute-force least squares lands on the Fourier coefficients");
    println!("ALL CHECKS PASS");
}
