// Weyl's law -- the check behind the card.  Rust std only.
// Same roads as the Python: a 1 m clamped disc, modes lambda = j^2 counted below 1000
// by Bessel's integral and by Miller's recurrence; the square-grid sandwich; what breaks.
use std::f64::consts::PI;
const LAM: f64 = 1000.0;

fn bj(m: usize, x: f64) -> f64 { // Bessel's integral, midpoint rule (exact to rounding here)
    let n = 160;
    let mut total = 0.0;
    for i in 0..n {
        let t = PI * (i as f64 + 0.5) / n as f64;
        total += (m as f64 * t - x * t.sin()).cos();
    }
    total / n as f64
}

fn bjp(m: usize, x: f64) -> f64 { if m == 0 { -bj(1, x) } else { 0.5 * (bj(m - 1, x) - bj(m + 1, x)) } } // J_m'

fn zeros(f: fn(usize, f64) -> f64, m: usize, top: f64) -> Vec<f64> { // scan by 0.1, bisect
    let mut out = vec![];
    let mut a = (m as f64).max(0.5);
    let mut fa = f(m, a);
    while a < top {
        let b = (a + 0.1).min(top);
        let fb = f(m, b);
        if fa * fb < 0.0 {
            let (mut lo, mut hi) = (a, b);
            for _ in 0..55 {
                let mid = 0.5 * (lo + hi);
                if fa * f(m, mid) <= 0.0 { hi = mid } else { lo = mid }
            }
            out.push(0.5 * (lo + hi));
        }
        a = b; fa = fb;
    }
    out
}

fn count(f: fn(usize, f64) -> f64, extra: Vec<f64>, x: f64) -> (Vec<f64>, usize, usize) {
    let (mut eig, mut m, mut once) = (extra, 0, 0); // m >= 1 counts twice (cos and sin)
    loop {
        let z = zeros(f, m, x);
        if z.is_empty() { break; }
        once += z.len();
        for _ in 0..(if m == 0 { 1 } else { 2 }) { for v in &z { eig.push(v * v); } }
        m += 1;
    }
    eig.sort_by(|a, b| a.partial_cmp(b).unwrap());
    (eig, m - 1, once)
}

fn miller(x: f64, top: usize) -> Vec<f64> { // J_0..J_top at x by backward recurrence
    let start = (x as usize).max(top) + 60;
    let (mut a, mut b) = (0.0f64, 1e-30f64);
    let mut out = vec![0.0; start + 1];
    for k in (1..=start).rev() {
        let nb = 2.0 * k as f64 / x * b - a;
        a = b; b = nb; out[k - 1] = b;
        if b.abs() > 1e250 { for v in out.iter_mut() { *v *= 1e-250; } a *= 1e-250; b *= 1e-250; }
    }
    let mut norm = out[0];
    for k in (2..=start).step_by(2) { norm += 2.0 * out[k]; }
    out[..=top].iter().map(|v| v / norm).collect()
}

fn lattice(r: f64, lo: usize) -> usize {
    let top = r as usize + 2;
    (lo..top).map(|p| (lo..top).filter(|q| ((p * p + q * q) as f64) <= r * r).count()).sum()
}
fn nd(r: f64) -> usize { lattice(r, 1) }
fn nn(r: f64) -> usize { lattice(r, 0) }
fn rect(a: f64, b: f64, lam: f64, lo: usize) -> usize {
    let (pt, qt) = ((a * lam.sqrt() / PI) as usize + 2, (b * lam.sqrt() / PI) as usize + 2);
    let mut c = 0;
    for p in lo..pt { for q in lo..qt { let (p, q) = (p as f64, q as f64); if PI * PI * (p * p / a / a + q * q / b / b) <= lam { c += 1; } } }
    c
}
fn weyl(area: f64, edge: f64, lam: f64, sign: f64) -> f64 { area * lam / (4.0 * PI) + sign * edge * lam.sqrt() / (4.0 * PI) }
fn ilist(v: &[usize]) -> String { format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }

fn sandwich(s: f64, lam: f64) -> (usize, usize, usize, usize) { // floor and ceiling from squares
    let k = (1.0 / s).round() as i64;
    let (mut inn, mut out) = (0, 0);
    for i in -k..k { for j in -k..k {
        let (x0, x1, y0, y1) = (i as f64 * s, (i + 1) as f64 * s, j as f64 * s, (j + 1) as f64 * s);
        let far = (x0 * x0).max(x1 * x1) + (y0 * y0).max(y1 * y1);
        let nx = if x0 <= 0.0 && 0.0 <= x1 { 0.0 } else { (x0 * x0).min(x1 * x1) };
        let ny = if y0 <= 0.0 && 0.0 <= y1 { 0.0 } else { (y0 * y0).min(y1 * y1) };
        if far < 1.0 { inn += 1; } if nx + ny < 1.0 { out += 1; }
    } }
    let r = s * lam.sqrt() / PI;
    let a = PI * r * r / 4.0;
    assert!(a - 2.0 * r - 1.0 <= nd(r) as f64 && nd(r) as f64 <= a && a <= nn(r) as f64 && nn(r) as f64 <= a + 2.0 * r + 1.0); // lattice bounds
    (inn, out, inn * nd(r), out * nn(r))
}

fn main() {
    let x = LAM.sqrt();
    println!("clamped disc, radius 1 m, area {:.5} m^2, rim 2 pi = {:.5} m; count lambda <= {:.0} 1/m^2 (k <= {:.4} 1/m)", PI, 2.0 * PI, LAM, x);
    let (eig, mtop, distinct) = count(bj, vec![], x);
    let (j01, j11, j21, j02) = (zeros(bj, 0, 3.0)[0], zeros(bj, 1, 4.0)[0], zeros(bj, 2, 6.0)[0], zeros(bj, 0, 6.0)[1]);
    println!("first zeros: j01 = {:.6}, j11 = {:.6}, j21 = {:.6}, j02 = {:.6}; lambda1 = {:.4} 1/m^2", j01, j11, j21, j02, j01 * j01);
    let n1 = eig.len();
    println!("road 1, Bessel's integral: N(1000) = {} modes ({} distinct notes), orders m = 0 to {}", n1, distinct, mtop);
    let mut xs: Vec<f64> = (1..=((x / 0.05) as usize)).map(|i| 0.05 * i as f64).collect();
    xs.push(x);
    let vals: Vec<Vec<f64>> = xs.iter().map(|&t| miller(t, x as usize)).collect(); // every order with a zero below x
    let n2: usize = (0..=x as usize).map(|m| (if m == 0 { 1 } else { 2 }) * (0..xs.len() - 1).filter(|&i| vals[i][m] * vals[i + 1][m] < 0.0).count()).sum();
    println!("road 2, Miller recurrence on a 0.05 grid: N(1000) = {} modes; J_5(20) by both roads: {:.10} {:.10}", n2, bj(5, 20.0), miller(20.0, 5)[5]);
    let gap = eig.iter().map(|v| (v - LAM).abs()).fold(f64::INFINITY, f64::min);
    let (w1, w2) = (weyl(PI, 2.0 * PI, LAM, 0.0), weyl(PI, 2.0 * PI, LAM, -1.0));
    println!("nearest eigenvalue to the limit is {:.3} 1/m^2 away; Weyl area term {:.2}, rim term {:.2}, two terms {:.2}; exact {}", gap, w1, w1 - w2, w2, n1);
    println!("errors: area term {:+.2}, two terms {:+.2}; ratio N / area term = {:.4}", w1 - n1 as f64, w2 - n1 as f64, n1 as f64 / w1);
    let lams: Vec<usize> = (1..=10).map(|i| 100 * i).collect();
    let stair: Vec<usize> = lams.iter().map(|&l| eig.iter().filter(|&&v| v <= l as f64).count()).collect();
    println!("chart lambda: {}", ilist(&lams));
    println!("chart exact N: {}", ilist(&stair));
    let fl = |sign: f64, edge: f64| lams.iter().map(|&l| format!("{:.1}", weyl(PI, edge, l as f64, sign))).collect::<Vec<_>>().join(", ");
    println!("chart area term: [{}]", fl(0.0, 0.0));
    println!("chart two terms: [{}]", fl(-1.0, 2.0 * PI));
    let c = (200.0f64 / 0.5).sqrt();
    println!("sheet: tension 200 N/m, 0.5 kg/m^2, c = {:.1} m/s; first note {:.3} Hz; limit {:.2} Hz; modes per Hz there {:.3}", c, c * j01 / (2.0 * PI), c * x / (2.0 * PI), 2.0 * PI * PI * c * x / (2.0 * PI) / (c * c));
    println!("min-max sandwich of lambda1: inner square side sqrt2 {:.4} >= disc {:.4} >= covering square side 2 {:.4}", PI * PI, j01 * j01, PI * PI / 2.0);
    let r = x / PI;
    println!("unit square, l = sqrt(1000)/pi = {:.4}: N_D = {}, N_N = {}, area term pi l^2/4 = {:.2}, slack 2l+1 = {:.2}", r, nd(r), nn(r), PI * r * r / 4.0, 2.0 * r + 1.0);
    println!("unit square with edge term: clamped {:.2} (exact {}), free {:.2} (exact {})", weyl(1.0, 4.0, LAM, -1.0), nd(r), weyl(1.0, 4.0, LAM, 1.0), nn(r));
    let mut fig = (0, 0);
    for &s in &[0.5, 0.25, 0.125] {
        let (inn, out, lo, hi) = sandwich(s, LAM);
        println!("disc at lambda 1000, squares of side {} m: {} inside, {} meeting; {} <= N <= {}", s, inn, out, lo, hi);
        assert!(lo <= n1 && n1 <= hi); // the sandwich holds
        if s == 0.25 { fig = (inn, out); }
    }
    println!("squeeze: side s, lambda, 4 pi N_low/lambda, 4 pi N_high/lambda (target area pi = 3.14159)");
    let mut sq = vec![];
    for &(s, lam) in &[(0.2, 10000usize), (0.1, 100000), (0.05, 1000000), (0.025, 10000000)] {
        let (inn, out, lo, hi) = sandwich(s, lam as f64);
        sq.push((4.0 * PI * lo as f64 / lam as f64, 4.0 * PI * hi as f64 / lam as f64));
        let l = sq[sq.len() - 1];
        println!("  {:<5} {:<8}  {:.4}  {:.4}  (inner area {:.4}, outer {:.4} m^2)", s, lam, l.0, l.1, inn as f64 * s * s, out as f64 * s * s);
    }
    for i in 0..3 { assert!(sq[i].0 < sq[i + 1].0 && sq[i + 1].0 < PI && PI < sq[i + 1].1 && sq[i + 1].1 < sq[i].1); } // closes on the area
    let (eign, _, _) = count(bjp, vec![0.0], x);
    let nn1 = eign.iter().filter(|&&v| v <= LAM).count();
    let w3 = weyl(PI, 2.0 * PI, LAM, 1.0);
    println!("free rim (Neumann, zeros of J_m'): N(1000) = {}; Weyl with + rim term {:.2}", nn1, w3);
    let lsq = (3 * nd(r), 3 * nn(r));
    let lre = (rect(2.0, 1.0, LAM, 1) + nd(r), rect(2.0, 1.0, LAM, 0) + nn(r));
    let (wl1, wl2) = (weyl(3.0, 8.0, LAM, 0.0), weyl(3.0, 8.0, LAM, -1.0));
    println!("L-shaped sheet, three 1 m squares (area 3 m^2, edge 8 m): squares give {} <= N <= {}", lsq.0, lsq.1);
    println!("  2 m x 1 m rectangle plus a square give {} <= N <= {}; Weyl {:.2}, with edge term {:.2}", lre.0, lre.1, wl1, wl2);
    println!("  as notes: about {:.0} modes below {:.2} Hz on a 3 m^2 L-shaped sheet", wl2, c * x / (2.0 * PI));
    let strip: Vec<usize> = [1.0, 10.0, 100.0].iter().map(|&l| rect(l, 1.0, LAM, 1)).collect();
    println!("strip 1 m wide, Dirichlet, lambda <= 1000: length 1, 10, 100 m gives {}; unbounded length, unbounded count", ilist(&strip));
    println!("mistake, m >= 1 counted once: {}; mistake, + rim term on a clamped rim: {:.2} against {}", distinct, w3, n1);
    println!("figure, side 0.25 m, {} squares inside, {} meeting; scale 160 px per m, centre (210, 210), radius 160 px", fig.0, fig.1);
    assert!(n1 == n2 && n2 == 232); // two roads, one count
    assert!((bj(5, 20.0) - miller(20.0, 5)[5]).abs() < 1e-10); // two Bessel roads agree
    assert!((j01 - 2.404825557695773).abs() < 1e-9); // j01 against its tabulated value
    assert!(miller(j01, 0)[0].abs() < 1e-9); // road 2 vanishes at road 1's zero
    assert!((n1 as f64 - w2).abs() < (n1 as f64 - w1).abs() / 5.0); // rim term helps, clamped
    assert!((nn1 as f64 - w3).abs() < 3.0); // rim term helps, free rim
    assert!(lsq.0 <= lre.0 && (lre.0 as f64) <= wl2 && wl1 <= lre.1 as f64 && lre.1 <= lsq.1); // L inside both
    assert!(PI * PI / 2.0 < j01 * j01 && j01 * j01 < PI * PI); // domain monotonicity
    assert!(strip[2] > 9 * strip[1] && 9 * strip[1] > 81 * strip[0]); // count grows with length
    println!("ALL CHECKS PASS");
}
