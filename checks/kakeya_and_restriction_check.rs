// Kakeya: the check behind the card. Rust std only, no crates.
// A Perron tree: cut a triangle of height 1 into 2^k thin triangles and slide them
// sideways so they pile up. Sliding never turns a triangle, so every needle
// direction survives while the area shrinks. Every area is computed here.

// half-base of the equilateral triangle of height 1, and also its area
fn half_base() -> f64 { 1.0 / 3f64.sqrt() }

// thin triangles [left base x, right base x, apex x]; base at y = 0, apex at y = 1
fn tree(k: u32, al: f64) -> Vec<[f64; 3]> {
    let b = half_base();
    let n = 1usize << k;
    let mut tris: Vec<[f64; 3]> = (0..n)
        .map(|i| [-b + 2.0 * b * i as f64 / n as f64, -b + 2.0 * b * (i + 1) as f64 / n as f64, 0.0])
        .collect();
    // a group: its triangle numbers, and its main triangle (left base, right base, apex x, apex y)
    let mut groups: Vec<(Vec<usize>, [f64; 4])> =
        (0..n).map(|i| (vec![i], [tris[i][0], tris[i][1], 0.0, 1.0])).collect();
    while groups.len() > 1 {
        let mut new = Vec::new();
        for pair in groups.chunks(2) {
            let (i1, m1) = (&pair[0].0, pair[0].1);
            let (i2, m2) = (&pair[1].0, pair[1].1);
            let s = m1[1] - m2[0]; // close the gap: the two main triangles become one triangle M
            let (b2, p2x) = (m2[1] + s, m2[2] + s);
            assert!((m1[2] - p2x).abs() < 1e-12 && (m1[3] - m2[3]).abs() < 1e-12); // common apex
            let t = (1.0 - al) * (b2 - m1[0]); // slide the right group left by (1 - alpha) of M's base
            for &i in i2 { for j in 0..3 { tris[i][j] += s - t; } }
            let mut ids = i1.clone();
            ids.extend(i2.iter().cloned());
            new.push((ids, [m1[0], b2 - t, m1[0] + al * (m1[2] - m1[0]), al * m1[3]]));
        }
        groups = new;
    }
    tris
}

// length of the union of the triangles' cross-sections at height y
fn width(tris: &[[f64; 3]], y: f64) -> f64 {
    let mut iv: Vec<(f64, f64)> =
        tris.iter().map(|t| (t[0] + (t[2] - t[0]) * y, t[1] + (t[2] - t[1]) * y)).collect();
    iv.sort_by(|p, q| p.partial_cmp(q).unwrap());
    let (mut tot, mut cl, mut cr) = (0.0, iv[0].0, iv[0].1);
    for &(l, r) in &iv[1..] {
        if l > cr { tot += cr - cl; cl = l; cr = r; } else { cr = cr.max(r); }
    }
    tot + cr - cl
}

// road 1: between edge crossings the width is linear, so midpoints are exact
fn area_exact(tris: &[[f64; 3]]) -> f64 {
    let lines: Vec<(f64, f64)> =
        tris.iter().flat_map(|t| [(t[0], t[2] - t[0]), (t[1], t[2] - t[1])]).collect();
    let mut ys = vec![0.0, 1.0];
    for i in 0..lines.len() {
        let (c1, m1) = lines[i];
        for &(c2, m2) in &lines[i + 1..] {
            let y = (c2 - c1) / (m1 - m2);
            if m1 != m2 && 0.0 < y && y < 1.0 { ys.push(y); }
        }
    }
    ys.sort_by(|p, q| p.partial_cmp(q).unwrap());
    ys.dedup();
    ys.windows(2).map(|w| (w[1] - w[0]) * width(tris, (w[0] + w[1]) / 2.0)).sum()
}

// road 2: plain midpoint rule on m slices
fn area_sampled(tris: &[[f64; 3]], m: usize) -> f64 {
    (0..m).map(|j| width(tris, (j as f64 + 0.5) / m as f64)).sum::<f64>() / m as f64
}

// main triangle alpha^(2k), plus 2(1 - alpha)^2 of each merged triangle
fn bound(k: u32, al: f64) -> f64 {
    let a2k = al.powi(2 * k as i32);
    a2k + 2.0 * (1.0 - al).powi(2) * (1.0 - a2k) / (1.0 - al * al)
}

fn sci(x: f64) -> String { // Python's {:.4e}: mantissa, then e+NN or e-NN
    let mut e = x.abs().log10().floor() as i32;
    if format!("{:.4}", x / 10f64.powi(e)) == "10.0000" { e += 1; }
    format!("{:.4}e{}{:02}", x / 10f64.powi(e), if e < 0 { "-" } else { "+" }, e.abs())
}

fn main() {
    let b = half_base();
    let t_area = b;
    let pts = [(-b, 0.0), (b, 0.0), (0.0, 1.0)];
    let sh: f64 = (0..3).map(|i| pts[i].0 * pts[(i + 1) % 3].1 - pts[(i + 1) % 3].0 * pts[i].1).sum();
    let shoe = sh.abs() / 2.0;
    assert!((shoe - 1.0 / 3f64.sqrt()).abs() < 1e-15);
    println!("starting triangle, height 1: area {:.6} (1/sqrt 3 = {:.6}); disc pi/4 = {:.6}",
             shoe, 1.0 / 3f64.sqrt(), std::f64::consts::PI / 4.0);
    println!("one merge (k=1): exact area = (alpha^2 + 2(1-alpha)^2) T");
    for al in [1.0, 2.0 / 3.0, 0.5] {
        let a = area_exact(&tree(1, al));
        let f = (al * al + 2.0 * (1.0 - al) * (1.0 - al)) * t_area;
        assert!((a - f).abs() < 1e-12);
        println!("  alpha={:.4}: sweep {:.6}, formula {:.6}, share of T {:.4}", al, a, f, a / t_area);
    }
    let (a4, f4) = (area_exact(&tree(1, 0.4)) / t_area, 0.4 * 0.4 + 2.0 * 0.6 * 0.6); // alpha below 1/2: the formula fails
    println!("  alpha=0.4000: sweep share {:.4}, formula share {:.4}: below 1/2 the formula overstates", a4, f4);
    assert!(f4 - a4 > 0.01);
    println!("k  alpha     area(exact)  area(sampled) share  bound   3 trees");
    let mut bars = Vec::new();
    let mut a8 = 0.0;
    for k in 1..=8u32 {
        let al = 1.0 - ((k + 1) as f64).ln() / (2.0 * k as f64);
        let tr = tree(k, al);
        let (a, s) = (area_exact(&tr), area_sampled(&tr, 20000));
        assert!((a - s).abs() < 1e-6 && a <= bound(k, al) * t_area + 1e-12);
        assert!(a > 0.95 * bound(k, al) * t_area); // the sprouts barely overlap
        bars.push(a / t_area);
        println!("{}  {:.6}  {:.6}     {:.6}       {:.4}  {:.4}  {:.6}",
                 k, al, a, s, a / t_area, bound(k, al), 3.0 * a);
        if k == 8 {
            a8 = a;
            // every direction in the 60-degree wedge: a needle from some apex to the base
            let mut hit = 0;
            for j in 0..=2000 {
                let u = -b + 2.0 * b * j as f64 / 2000.0; // base point x - apex x
                hit += tr.iter().any(|t| t[0] - 1e-12 <= t[2] + u && t[2] + u <= t[1] + 1e-12) as u32;
            }
            assert_eq!(hit, 2001);
            let lo = tr.iter().map(|t| t[0]).fold(f64::INFINITY, f64::min);
            let hi = tr.iter().map(|t| t[1]).fold(f64::NEG_INFINITY, f64::max);
            println!("k=8: directions with a needle from apex to base: {} of 2001; x from {:.4} to {:.4}",
                     hit, lo, hi);
        }
    }
    let bs: Vec<String> = bars.iter().map(|v| format!("{:.4}", v)).collect();
    println!("bars: {}", bs.join(", "));
    let fixed = area_exact(&tree(8, 2.0 / 3.0)) / t_area;
    println!("fixed alpha=2/3 at k=8: share {:.4}, bound floor 2(1-a)/(1+a) = {:.4}",
             fixed, 2.0 * (1.0 / 3.0) / (5.0 / 3.0));
    assert!(fixed > bars[7]);

    // Pal join: move a needle to a parallel line h away by turning theta, sliding, turning back
    for th in [0.01f64, 0.001] {
        let m = 100000;
        let fan: f64 = (0..m).map(|_| 0.5 * (th / m as f64).sin()).sum();
        assert!((fan - th / 2.0).abs() < 1e-9);
        println!("Pal join theta={}: two sectors {:.6} (formula theta {}), slide 1/sin = {:.4}",
                 th, 2.0 * fan, th, 1.0 / th.sin());
    }
    let joins = 3 * (1 << 8) - 1;
    let total = 3.0 * a8 + joins as f64 * 1e-7;
    println!("whole half-turn, k=8, theta=1e-7: at most {:.6} + {} x 1e-7 = {:.6} (deltoid pi/8 = {:.6})",
             3.0 * a8, joins, total, std::f64::consts::PI / 8.0);
    assert!(total < std::f64::consts::PI / 8.0);
    let room = std::f64::consts::PI / 8.0 - 3.0 * a8;
    println!("room under the deltoid: {:.6}, so each of {} joins may use theta up to {}", room, joins, sci(room / joins as f64));

    // Hausdorff sums for the middle-thirds Cantor set: 2^k pieces of length 3^-k
    let s0 = 2f64.ln() / 3f64.ln();
    println!("Cantor set: critical s = log 2 / log 3 = {:.6}", s0);
    for s in [0.5, s0, 0.7] {
        let sums: Vec<f64> = [10, 20, 40].iter().map(|&k| 2f64.powi(k) * 3f64.powf(-(k as f64) * s)).collect();
        println!("  s={:.4}: k=10 {}, k=20 {}, k=40 {}", s, sci(sums[0]), sci(sums[1]), sci(sums[2]));
        if s == s0 { assert!((sums[2] - 1.0).abs() < 1e-9); } else { assert_eq!(sums[2] > sums[0], s < s0); }
    }

    let tr = tree(3, 1.0 - 4f64.ln() / 6.0);
    let parts: Vec<String> = tr.iter().map(|t| format!("{:.4} {:.4} {:.4}", t[0], t[1], t[2])).collect();
    println!("figure, k=3 tree, base x and apex x: {}", parts.join("; "));
    println!("ALL CHECKS PASS");
}
