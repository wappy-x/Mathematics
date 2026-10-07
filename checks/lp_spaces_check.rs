// Lp spaces -- the same check as the Python, in Rust.  No crates.  The week's
// wind (3, 5, 8, 2, 6, 4, 7) m/s is sized under counting measure and under the
// uniform probability 1/7, each size by two roads; a one-hour gust is sized by
// an exact formula and by a midpoint sum; a three-point space is listed in full
// to show the a.e. classes.  Fractions are kept by hand as (numerator, denominator).
const V: [i64; 7] = [3, 5, 8, 2, 6, 4, 7];

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn frac(n: i64, d: i64) -> String {                // a fraction in lowest terms, as text
    let g = gcd(n, d);
    if d / g == 1 { format!("{}", n / g) } else { format!("{}/{}", n / g, d / g) }
}
fn power_sum(f: &[i64], p: u32) -> i64 { f.iter().map(|x| x.abs().pow(p)).sum() }
fn layer_cake(f: &[i64], p: u32) -> i64 {          // road two: slice by height
    let mut levels: Vec<i64> = f.iter().map(|x| x.abs()).collect();
    levels.sort();
    levels.dedup();
    let (mut total, mut below) = (0, 0i64);
    for &t in &levels {
        total += (t.pow(p) - below.pow(p)) * f.iter().filter(|x| x.abs() >= t).count() as i64;
        below = t;
    }
    total
}
fn norm(f: &[f64], p: f64, w: f64) -> f64 {        // p-norm with every point weighing w
    (w * f.iter().map(|x| x.abs().powf(p)).sum::<f64>()).powf(1.0 / p)
}
fn midpoint(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    h * (0..n).map(|k| g(a + (k as f64 + 0.5) * h)).sum::<f64>()
}
fn fl(f: &[i64]) -> Vec<f64> { f.iter().map(|&x| x as f64).collect() }
fn half(f: &[i64]) -> f64 { f.iter().map(|&x| (x.abs() as f64).powf(0.5)).sum::<f64>().powi(2) }

fn main() {
    let vf = fl(&V);
    println!("1. the week under counting measure (each day weighs 1)");
    for p in 1..=3u32 {
        println!("   p = {}: sum of |v|^p = {}, by layers {}, norm {:.4}", p, power_sum(&V, p), layer_cake(&V, p), norm(&vf, p as f64, 1.0));
    }
    println!("   sup-norm = {}: every day weighs 1, so no day can be ignored", V.iter().max().unwrap());
    println!("2. the week under the uniform probability (each day weighs 1/7)");
    for p in 1..=3u32 {
        let pf = p as f64;
        println!("   p = {}: mean of |v|^p = {}, norm {:.4}, = 7^(-1/{}) x counting norm {:.4}", p, frac(power_sum(&V, p), 7),
                 norm(&vf, pf, 1.0 / 7.0), p, 7f64.powf(-1.0 / pf) * norm(&vf, pf, 1.0));
    }
    let dev: Vec<i64> = V.iter().map(|x| x - 5).collect();
    println!("   deviation from the mean {:?}: squares sum to {}, 2-norm {:.4} m/s, and {} = 5^2 + {}", dev, power_sum(&dev, 2),
             norm(&fl(&dev), 2.0, 1.0 / 7.0), frac(power_sum(&V, 2), 7), frac(power_sum(&dev, 2), 7));
    println!("3. the p-norm as p grows (chart)");
    let ps = [1, 2, 3, 4, 6, 8, 12, 16, 24, 32];
    let cnt: Vec<f64> = ps.iter().map(|&p| norm(&vf, p as f64, 1.0)).collect();
    let uni: Vec<f64> = ps.iter().map(|&p| norm(&vf, p as f64, 1.0 / 7.0)).collect();
    println!("   p        {}", ps.iter().map(|p| format!("{:>5}", p)).collect::<Vec<_>>().join(" "));
    println!("   counting {}", cnt.iter().map(|x| format!("{:5.2}", x)).collect::<Vec<_>>().join(" "));
    println!("   uniform  {}", uni.iter().map(|x| format!("{:5.2}", x)).collect::<Vec<_>>().join(" "));
    println!("   squeeze at p = 32: {:.4} <= uniform <= 8 <= counting <= {:.4}", 8.0 * 7f64.powf(-1.0 / 32.0), 8.0 * 7f64.powf(1.0 / 32.0));
    println!("4. a one-hour gust u(t) = 8t on [0, 1], length as the measure");
    let gust = |p: f64| midpoint(&|t: f64| (8.0 * t).powf(p), 0.0, 1.0, 100000).powf(1.0 / p);
    for p in 1..=3 {
        let pf = p as f64;
        println!("   p = {}: exact 8/(p+1)^(1/p) = {:.4}, midpoint sum {:.4}", p, 8.0 / (pf + 1.0).powf(1.0 / pf), gust(pf));
    }
    // the logger's glitch: 40 m/s at the single instant t = 0.5.  The glitched record as pieces
    // (a, b, c0, c1), speed c0 + c1 t from a to b; the glitch is the piece of length 0
    let rec: [(f64, f64, f64, f64); 3] = [(0.0, 0.5, 0.0, 8.0), (0.5, 0.5, 40.0, 0.0), (0.5, 1.0, 0.0, 8.0)];
    let plain = rec.iter().map(|&(a, b, c0, c1)| f64::max(c0 + c1 * a, c0 + c1 * b)).fold(f64::MIN, f64::max); // a straight piece peaks at an end
    let above = |m: f64| rec.iter().map(|&(a, b, c0, c1)| midpoint(&|t: f64| if c0 + c1 * t > m { 1.0 } else { 0.0 }, a, b, 1000)).sum::<f64>();
    let ess = (0..41).find(|&m| above(m as f64) == 0.0).unwrap();      // least ceiling broken only on length 0
    println!("   with a 40 m/s glitch at t = 0.5: plain sup {:.0}, ess sup {} (length above 7 is {:.4}, above 8 is {:.4})", plain, ess, above(7.0), above(8.0));
    println!("   p-norms climb to the ess sup, not the glitch: p = 100 gives {:.4}, p = 1000 gives {:.4}",
             8.0 / 101f64.powf(1.0 / 100.0), 8.0 / 1001f64.powf(1.0 / 1000.0));
    println!("5. the spike s(t) = 1/sqrt(t) on (0, 1]: in L^1, not in L^2");
    let one: f64 = (0..60).map(|j| midpoint(&|t: f64| t.powf(-0.5), 2f64.powf(-(j as f64 + 1.0)), 2f64.powf(-(j as f64)), 2000)).sum();
    let piece = midpoint(&|t: f64| 1.0 / t, 0.5, 1.0, 2000);
    println!("   1-norm by 60 halvings {:.4}; exact 2", one);
    println!("   integral of s^2 = 1/t over each halving [2^-(j+1), 2^-j]: {:.4} every time", piece);
    println!("   down to 2^-10, 2^-20, 2^-40: {:.2}, {:.2}, {:.2}: no finite 2-norm", 10.0 * piece, 20.0 * piece, 40.0 * piece);
    println!("6. a.e. classes, listed in full: Mon and Tue weigh 1, the glitch instant weighs 0");
    type F3 = (i64, i64, i64);
    let w3 = [1, 1, 0];
    let arr = |f: F3| [f.0, f.1, f.2];
    let same = |f: F3, g: F3| (0..3).filter(|&i| arr(f)[i] != arr(g)[i]).map(|i| w3[i]).sum::<i64>() == 0;
    let n2 = |f: F3| (0..3).map(|i| w3[i] * arr(f)[i] * arr(f)[i]).sum::<i64>();   // squared 2-norm, exact
    let mut funcs: Vec<F3> = Vec::new();
    for a in 0..2 { for b in 0..2 { for c in 0..2 { funcs.push((a, b, c)) } } }
    let mut classes: Vec<Vec<F3>> = Vec::new();
    for &f in &funcs {
        match classes.iter_mut().find(|cl| same(f, cl[0])) { Some(cl) => cl.push(f), None => classes.push(vec![f]) }
    }
    for cl in &classes {
        let mut sq: Vec<i64> = cl.iter().map(|&f| n2(f)).collect();
        sq.sort();
        sq.dedup();
        println!("   class {:?}: squared 2-norm {:?}", cl, sq);
    }
    let zero: Vec<F3> = funcs.iter().copied().filter(|&f| n2(f) == 0).collect();
    let add = |f: F3, g: F3| (f.0 + g.0, f.1 + g.1, f.2 + g.2);
    let (mut good, mut total) = (0, 0);
    for c1 in &classes { for c2 in &classes { for &f1 in c1 { for &f2 in c1 { for &g1 in c2 { for &g2 in c2 {
        total += 1;
        if same(add(f1, g1), add(f2, g2)) { good += 1 }
    } } } } } }
    println!("   {} functions, {} classes; norm zero on {:?}", funcs.len(), classes.len(), zero);
    println!("   sums of representatives landing in one class: {} of {}", good, total);
    println!("7. conjugate exponents and why 1/p + 1/q = 1");
    println!("   p = 1: q = infinity");
    for &(pn, pd) in &[(3i64, 2i64), (2, 1), (3, 1)] {
        let (qn, qd) = (pn, pn - pd);                  // q = p/(p - 1)
        println!("   p = {}: q = {}, 1/p + 1/q = {}", frac(pn, pd), frac(qn, qd), frac(pd * qn + qd * pn, pn * qn));
    }
    let ratio = |p: f64, q: f64, c: f64| c * 35.0 / (norm(&vf, p, c) * norm(&[1.0; 7], q, c));
    for &(p, q, lab) in &[(2.0, 2.0, "p = 2, q = 2"), (3.0, 1.5, "p = 3, q = 1.5"), (2.0, 3.0, "p = 2, q = 3")] {
        println!("   {}: ratio at weight 1/7, 1, 7, 49 = {}", lab,
                 [1.0 / 7.0, 1.0, 7.0, 49.0].iter().map(|&c| format!("{:.4}", ratio(p, q, c))).collect::<Vec<_>>().join(", "));
    }
    println!("8. what breaks");
    let (a, b) = ([1i64, 0, 0, 0, 0, 0, 0], [0i64, 1, 0, 0, 0, 0, 0]);
    let ab: Vec<i64> = (0..7).map(|i| a[i] + b[i]).collect();
    println!("   p = 1/2 on Mon and Tue alone: size of the sum {:.0} > {:.0}", half(&ab), half(&a) + half(&b));
    let v2: Vec<i64> = V.iter().map(|x| 2 * x).collect();
    println!("   no root: sum of |2v|^2 = {} = 4 x 203; with the root {:.4} = 2 x {:.4}", power_sum(&v2, 2), norm(&fl(&v2), 2.0, 1.0), norm(&vf, 2.0, 1.0));
    println!("figure, bars 3 5 8 2 6 4 7; levels 5.00 5.70 8.00");

    for p in 1..=4 { assert_eq!(power_sum(&V, p), layer_cake(&V, p)) }      // two roads to each power sum
    assert_eq!(power_sum(&V, 2) * 7, 35 * 35 + 7 * power_sum(&dev, 2));     // 29 = 25 + 4, times 49
    for p in 1..=3 { let pf = p as f64; assert!((8.0 / (pf + 1.0).powf(1.0 / pf) - gust(pf)).abs() < 1e-6) }
    assert!((one - 2.0).abs() < 1e-4 && (piece - 0.6931471805599453).abs() < 1e-6);
    assert!(classes.len() == 4 && classes.iter().all(|c| c.len() == 2) && good == total);
    for i in 0..ps.len() {
        let p = ps[i] as f64;
        assert!(8.0 * 7f64.powf(-1.0 / p) <= uni[i] && uni[i] <= 8.0 && 8.0 <= cnt[i] && cnt[i] <= 8.0 * 7f64.powf(1.0 / p));
    }
    for p in 1..=3 { let pf = p as f64; assert!((norm(&vf, pf, 1.0 / 7.0) - 7f64.powf(-1.0 / pf) * norm(&vf, pf, 1.0)).abs() < 1e-12) }
    assert!(plain == 40.0 && ess == 8 && classes.contains(&zero) && half(&ab) > half(&a) + half(&b));
    for &(p, q) in &[(2.0, 2.0), (3.0, 1.5)] { for &c in &[1.0 / 7.0, 7.0, 49.0] { assert!((ratio(p, q, c) - ratio(p, q, 1.0)).abs() < 1e-12) } }
    assert!((ratio(2.0, 3.0, 49.0) / ratio(2.0, 3.0, 1.0) - 49f64.powf(1.0 - 0.5 - 1.0 / 3.0)).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
