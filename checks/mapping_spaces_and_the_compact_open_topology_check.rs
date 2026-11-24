// Mapping spaces and the compact-open topology -- the check behind the card.  Rust std only.
// Two ramp profiles on [0, 1], heights in metres: f(s) = s^2 and g(s) = s.  Ramp heights are exact
// integers on the grid s = j/N; the loops use floats only for turn counts, which are rounded to integers.
use std::f64::consts::PI;

const N: i128 = 1680; // grid s = j/N; N is divisible by 2k for k = 1..8
const M: usize = 360; // samples per loop

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn frac(p: i128, q: i128) -> String { // an exact fraction, printed in lowest terms
    let d = gcd(p, q);
    let (p, q) = (p / d, q / d);
    if q == 1 { format!("{}", p) } else { format!("{}/{}", p, q) }
}
fn h(j: i128, i: i128) -> i128 { (10 - i) * j * j + i * j * N } // frame t = i/10 at s = j/N, units 1/(10 N^2)
fn dec(v: i128, den: i128) -> String { let m = v * 1000 / den; format!("{}.{:03}", m / 1000, m % 1000) }
fn grid() -> std::ops::RangeInclusive<i128> { 0..=N }

fn in_nbhd(c: &[i128], p: i128, w: i128) -> bool {
    (0..p).all(|i| (i * w..=(i + 1) * w).all(|j| {
        let v = c[j as usize];
        100 * (i * w) * (i * w) - 5 * N * N < v && v < 100 * ((i + 1) * w) * ((i + 1) * w) + 5 * N * N
    }))
}
fn sup(c: &[i128]) -> i128 { grid().map(|j| (c[j as usize] - 100 * j * j).abs()).max().unwrap() }

fn wind_turns(th: &dyn Fn(f64) -> f64) -> (i64, Vec<(f64, f64)>) { // road 1: add the small turns
    let m = M;
    let pts: Vec<(f64, f64)> = (0..=m).map(|n| {
        let a = 2.0 * PI * th(n as f64 / m as f64);
        (a.cos(), a.sin())
    }).collect();
    let mut tot = 0.0;
    for k in 0..m {
        let ((x0, y0), (x1, y1)) = (pts[k], pts[k + 1]);
        tot += (x0 * y1 - y0 * x1).atan2(x0 * x1 + y0 * y1);
    }
    ((tot / (2.0 * PI)).round() as i64, pts)
}
fn wind_ray(pts: &[(f64, f64)]) -> i64 { // road 2: signed crossings of the ray at angle 1 radian
    let (ux, uy) = (1.0f64.cos(), 1.0f64.sin());
    let mut w = 0;
    for k in 0..pts.len() - 1 {
        let ((x0, y0), (x1, y1)) = (pts[k], pts[k + 1]);
        let (a, b) = (ux * y0 - uy * x0, ux * y1 - uy * x1);
        if ((a < 0.0 && 0.0 <= b) || (b < 0.0 && 0.0 <= a)) && ux * (x0 + x1) + uy * (y0 + y1) > 0.0 {
            w += if b >= 0.0 { 1 } else { -1 };
        }
    }
    w
}
fn phi(s: f64) -> f64 { 1.0 - (2.0 * s - 1.0).abs() } // out and back

fn main() {
    // ---- the straight-line slide from f to g, as a path of maps ----
    let gap = grid().map(|j| j * N - j * j).max().unwrap();
    assert!(frac(gap, N * N) == "1/4" && (N / 2) * N - (N / 2) * (N / 2) == gap);
    println!("worst gap between the ramps: {} m, at s = {}", frac(gap, N * N), frac(N / 2, N));
    let dist = |i: i128, k: i128| grid().map(|j| (h(j, i) - h(j, k)).abs()).max().unwrap();
    let mut pairs = 0;
    for i in 0..=10 {
        for k in i..=10 {
            assert!(dist(i, k) * 4 == (k - i) * N * N);
            pairs += 1;
        }
    }
    println!("sup distance between frames 0 and 1: {} m; frames 0.3 and 0.7: {} m",
             frac(dist(0, 10), 10 * N * N), frac(dist(3, 7), 10 * N * N));
    println!("all {} pairs of frames on tenths: distance = |t - t'| x 1/4: yes", pairs);
    println!("frame 1/2 at s = 1/2: {} m", frac(h(N / 2, 5), 10 * N * N));
    for (name, i) in [("H_0", 0), ("H_1/2", 5), ("H_1", 10)] {
        let v: Vec<String> = (0..=10).map(|j| dec(h(j * N / 10, i), 10 * N * N)).collect();
        println!("chart {}: [{}]", name, v.join(", "));
    }

    // ---- a sup ball round f against a compact-open neighbourhood built from 40 pieces ----
    let mut c: Vec<Vec<i128>> = Vec::new();
    for m in -20..=20i128 {
        for k in 1..=8i128 {
            if m != 0 {
                c.push(grid().map(|j| 100 * j * j + m * N * (N - (2 * (k * j % N) - N).abs())).collect());
            }
        }
    }
    for m in -12..=12i128 { c.push(grid().map(|j| 100 * j * j + m * N * N).collect()); }
    let (p, w) = (40, N / 40);
    let inside: Vec<&Vec<i128>> = c.iter().filter(|x| in_nbhd(x, p, w)).collect();
    assert!(!inside.is_empty() && inside.iter().all(|x| sup(x) < 10 * N * N));
    let far: Vec<&Vec<i128>> = c.iter().filter(|x| sup(x) >= 10 * N * N).collect();
    assert!(!far.is_empty() && !far.iter().any(|x| in_nbhd(x, p, w)));
    let worst = inside.iter().map(|x| sup(x)).max().unwrap();
    println!("candidates {}: {} pass all {} piece tests, worst sup distance among them {} m < 1/10",
             c.len(), inside.len(), p, frac(worst, 100 * N * N));
    println!("  {} candidates at sup distance >= 1/10 m: none passes", far.len());
    let rise = (0..p).map(|i| 100 * ((i + 1) * w) * ((i + 1) * w) - 100 * (i * w) * (i * w)).max().unwrap();
    assert!(rise <= 200 * w * N); // s^2 rises by at most 2 x the width on [0, 1]
    println!("grid {} points; teeth up to {} m high; largest rise of f on one piece: {} m, bound 2 x {} = {} m",
             N + 1, frac(20, 100), frac(rise, 100 * N * N), frac(w, N), frac(2 * w, N));
    let r = (10 * N * N).min(30 * N * N - 100 * (N / 2) * (N / 2));
    let near: Vec<&Vec<i128>> = c.iter().filter(|x| sup(x) < r).collect();
    assert!(frac(r, 100 * N * N) == "1/20"
        && near.iter().all(|x| (0..=N / 2).all(|j| -10 * N * N < x[j as usize] && x[j as usize] < 30 * N * N)));
    println!("V([0, 1/2], (-1/10, 3/10)) round f: room r = {} m; {} candidates within r, all inside V: yes",
             frac(r, 100 * N * N), near.len());

    // ---- what breaks ----
    let nc: Vec<String> = [1i128, 10, 100].iter().map(|&n| format!("n={}: {}, {}", n,
        frac(grid().max().unwrap(), n * N), frac(grid().map(|j| j * n).max().unwrap(), n * N))).collect();
    println!("mistake, domain not compact: s/n has max on [0, 1] and on [0, n]: {}", nc.join("; "));
    let tent = |n: i128, a: i128, q: i128| frac((q - (n * a - q).abs()).max(0), q);
    let pw: Vec<String> = [10i128, 100, 1000].iter()
        .map(|&n| format!("n={}: {}, {}", n, tent(n, 1, 10), tent(n, 1, n))).collect();
    println!("mistake, pointwise only: tent peaked at 1/n, value at s = 1/10 and at the peak: {}", pw.join("; "));
    let coarse = frac((0..4i128).map(|k| 3 * k - k * k).max().unwrap(), 9);
    assert!(coarse == "2/9" && frac(gap, N * N) != coarse);
    println!("mistake, worst gap on the grid s = 0, 1/3, 2/3, 1: {} m, not 1/4", coarse);

    // ---- loops on the circle: winding number by two roads ----
    let loops: Vec<(&str, Box<dyn Fn(f64) -> f64>)> = vec![
        ("wound once", Box::new(|s| s)), ("wound twice", Box::new(|s| 2.0 * s)),
        ("other way", Box::new(|s: f64| -s)), ("round then back", Box::new(phi)),
        ("stay put", Box::new(|_| 0.0)),
        ("twice, back once", Box::new(|s| if s <= 2.0 / 3.0 { 3.0 * s } else { 4.0 - 3.0 * s }))];
    println!("winding numbers from {} samples per loop, by two roads", M);
    let mut found: Vec<i64> = Vec::new();
    for (name, th) in &loops {
        let (w, pts) = wind_turns(th.as_ref());
        assert!(w == wind_ray(&pts));
        if !found.contains(&w) { found.push(w); }
        println!("loop {}: winding {} (ray count {})", name, w, wind_ray(&pts));
    }
    found.sort();
    assert!(found == vec![-1, 0, 1, 2]);
    println!("mistake, counting laps: twice, back once runs 3 laps, but its winding is 1");
    let fr: Vec<(i64, Vec<(f64, f64)>)> = (0..=10).map(|t| {
        let t = t as f64 / 10.0;
        wind_turns(&move |s| 4.0 * t * (1.0 - t) * phi(s))
    }).collect();
    assert!(fr.iter().all(|(w, p)| *w == 0 && wind_ray(p) == 0));
    let mut edge: Vec<(f64, f64)> = Vec::new();
    edge.extend(fr[0].1.iter().cloned());
    edge.extend(fr[10].1.iter().cloned());
    for (_, p) in &fr { edge.push(p[0]); edge.push(*p.last().unwrap()); }
    assert!(edge.iter().all(|&(x, y)| x == 1.0 && y == 0.0));
    let ws: Vec<String> = fr.iter().map(|(w, _)| w.to_string()).collect();
    println!("loop of loops: frame windings [{}]; every edge point of the square at (1, 0): yes", ws.join(", "));
    println!("ALL CHECKS PASS");
}
