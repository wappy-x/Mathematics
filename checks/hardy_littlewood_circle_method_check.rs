// The circle method for five squares -- the check behind the card.  std only.
// Road 1 counts r_5(n) directly.  Road 2 is the circle integral, done exactly with 5,000
// sample points, then split into major and minor arcs.  Road 3 is the prediction: the
// singular series from Gauss sums, times the singular integral.  Road 4 rebuilds the
// series from local solution counts mod p^k.
use std::collections::{HashMap, HashSet};
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct Cx(f64, f64);
impl Cx {
    fn mul(self, o: Cx) -> Cx { Cx(self.0 * o.0 - self.1 * o.1, self.0 * o.1 + self.1 * o.0) }
    fn abs(self) -> f64 { self.0.hypot(self.1) }
    fn pow(self, n: u32) -> Cx { // binary powering, in the same order as Python's
        let (mut r, mut a, mut m) = (Cx(1.0, 0.0), self, 1);
        while m <= n { if n & m != 0 { r = r.mul(a); } m <<= 1; if m <= n { a = a.mul(a); } } r }
}
fn e(x: f64) -> Cx { Cx((2.0 * PI * x).cos(), (2.0 * PI * x).sin()) }
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn commas(x: f64, d: usize) -> String {
    let s = format!("{:.*}", d, x.abs());
    let (int, frac) = match s.find('.') { Some(i) => (&s[..i], &s[i..]), None => (&s[..], "") };
    let mut out = String::new();
    for (i, ch) in int.chars().enumerate() { if i > 0 && (int.len() - i) % 3 == 0 { out.push(','); } out.push(ch); }
    format!("{}{}{}", if x < 0.0 && s.chars().any(|c| c != '0' && c != '.') { "-" } else { "" }, out, frac)
}
fn reps(s: usize, n: usize) -> Vec<u64> { // r_s(m) for m <= n: signs and order counted
    let mut sq = vec![0u64; n + 1];
    let r0 = (n as f64).sqrt() as i64;
    for x in -r0..=r0 { if ((x * x) as usize) <= n { sq[(x * x) as usize] += 1; } }
    let mut r = vec![0u64; n + 1]; r[0] = 1;
    for _ in 0..s {
        r = (0..=n).map(|m| (0..=m).filter(|&k| sq[k] > 0).map(|k| r[m - k] * sq[k]).sum()).collect();
    }
    r
}
fn a_term(q: i64, n: i64, s: u32) -> f64 {
    let mut t = Cx(0.0, 0.0);
    for a in 1..=q {
        if gcd(a, q) != 1 { continue; }
        let mut g = Cx(0.0, 0.0);
        for x in 0..q { let z = e((a * x * x) as f64 / q as f64); g = Cx(g.0 + z.0, g.1 + z.1); }
        let z = g.pow(s).mul(e((-a * n) as f64 / q as f64));
        t = Cx(t.0 + z.0, t.1 + z.1);
    }
    t.0 / (q as f64).powi(s as i32)
}
fn density(p: usize, k: u32, n: usize, s: usize) -> f64 {
    let m = p.pow(k); let mut c = vec![0u64; m];
    for x in 0..m { c[x * x % m] += 1; }
    let mut cur = c.clone();
    for _ in 0..s - 1 {
        let mut nw = vec![0u64; m];
        for i in 0..m { if cur[i] > 0 { for t in 0..m { if c[t] > 0 { nw[(i + t) % m] += cur[i] * c[t]; } } } }
        cur = nw;
    }
    cur[n % m] as f64 / (m as f64).powi(s as i32 - 1)
}
fn jint(n: f64, s: f64, g: f64) -> f64 { PI.powf(s / 2.0) * n.powf(s / 2.0 - 1.0) / g }
fn main() {
    let (r5, r3, r4) = (reps(5, 1001), reps(3, 1007), reps(4, 1024));
    println!("count, r_5(1000) = {}, r_5(1001) = {}", commas(r5[1000] as f64, 0), commas(r5[1001] as f64, 0));
    // ---- road 2: the circle integral, sampled at alpha = j/M ----
    let (m, p) = (5000i64, 31i64); // 5 x 31^2 = 4,805 < 5,000, so the samples are exact
    let cs: Vec<f64> = (0..m).map(|k| (2.0 * PI * k as f64 / m as f64).cos()).collect();
    let sn: Vec<f64> = (0..m).map(|k| (2.0 * PI * k as f64 / m as f64).sin()).collect();
    let f: Vec<Cx> = (0..m).map(|j| {
        let (mut re, mut im) = (0.0, 0.0);
        for x in -p..=p { let k = ((j * x * x) % m) as usize; re += cs[k]; im += sn[k]; }
        Cx(re, im)
    }).collect();
    let piece = |js: &Vec<i64>, n: i64| -> f64 {
        let mut t = 0.0;
        for &j in js { let k = (-j * n).rem_euclid(m) as usize; t += f[j as usize].pow(5).mul(Cx(cs[k], sn[k])).0; }
        t / m as f64
    };
    let all: Vec<i64> = (0..m).collect(); let (i0, i1) = (piece(&all, 1000), piece(&all, 1001));
    println!("integral, n = 1000: {}; n = 1001: {}", commas(i0, 1), commas(i1, 1));
    assert!(i0.round() as u64 == r5[1000] && i1.round() as u64 == r5[1001]);
    let mut c = vec![0u64; 4806]; c[0] = 1;  // c[m]: ways to make m from five squares of -31..31, every m to 4,805
    for _ in 0..5 { c = (0..4806usize).map(|k| (0..=p as usize).filter(|x| x * x <= k).map(|x| c[k - x * x] * if x == 0 { 1 } else { 2 }).sum::<u64>()).collect(); }
    let arc = |q: i64, n: i64, w: f64| -> f64 { let mut t = 0.0; // exact integral of f^5 e(-n alpha) = sum c[m] e((m-n) alpha) over the arcs
        for a in (0..q).filter(|&a| gcd(a, q) == 1) { for (k, &cm) in c.iter().enumerate() { if cm == 0 { continue; } let d = (k as i64 - n) as f64;
            t += cm as f64 * if k as i64 == n { 2.0 * w } else { (2.0 * PI * d * a as f64 / q as f64).cos() * (2.0 * PI * d * w).sin() / (PI * d) }; } }
        t };
    assert!(c[1000] == r5[1000] && ([1i64, 2, 5, 10].iter().map(|&d| arc(d, 1000, 0.05)).sum::<f64>() - r5[1000] as f64).abs() < 1e-6); // arcs round each a/10 tile the circle
    let mut minor: Vec<i64> = vec![];
    for qq in [10i64, 5] {
        let mut mj = HashSet::new();
        for q in 1..=qq { for a in 0..=q { if gcd(a, q) == 1 { for j in 0..m { if (j * q - a * m).abs() <= 25 { mj.insert(j); } } } } }
        let mn: Vec<i64> = (0..m).filter(|j| !mj.contains(j)).collect();
        let maj = (1..=qq).fold(0.0, |s, q| s + arc(q, 1000, 25.0 / (q * m) as f64));
        let sh = (1..=qq).flat_map(|q| (0..q).filter(move |&a| gcd(a, q) == 1).map(move |_| 2.0 * 25.0 / (q * m) as f64)).fold(0.0, |s, x| s + x);
        let mx = mn.iter().map(|&j| f[j as usize].abs()).fold(0.0, f64::max);
        println!("arcs q <= {}, integrated exactly: share of circle {:.4}, of count {:.4}; major {}, minor {}; largest |f| at the minor-arc samples {:.2}",
            qq, sh, maj / r5[1000] as f64, commas(maj, 1), commas(r5[1000] as f64 - maj, 1), mx);
        if qq == 10 { minor = mn; }
    }
    let rms = (f.iter().map(|z| z.abs().powi(2)).sum::<f64>() / m as f64).sqrt();
    println!("|f| at 0, 1/4, 1/5, 1/2: {:.2}, {:.2}, {:.2}, {:.2}; root mean square {:.2}",
        f[0].abs(), f[1250].abs(), f[1000].abs(), f[2500].abs(), rms);
    let mean4 = f.iter().map(|z| z.abs().powi(4)).sum::<f64>() / m as f64; let mxm = minor.iter().map(|&j| f[j as usize].abs()).fold(0.0, f64::max);
    println!("mean of |f|^4 = {}; minor-arc bound max|f| x mean|f|^4 at least {}, from the sampled max", commas(mean4, 1), commas(mxm * mean4, 0));
    // ---- Weyl's inequality: |f|^2 <= sum over |h| <= 2P of min(2P+1, 1/(2||2h alpha||)) ----
    let weyl = |j: i64| -> f64 { let mut t = 0.0;
        for h in -2 * p..=2 * p {
            let d = (2 * h * j).rem_euclid(m); let d = d.min(m - d) as f64 / m as f64;
            t += if d == 0.0 { (2 * p + 1) as f64 } else { ((2 * p + 1) as f64).min(1.0 / (2.0 * d)) };
        }
        t
    };
    let wr = minor.iter().map(|&j| f[j as usize].abs().powi(2) / weyl(j)).fold(0.0, f64::max); let wb = minor.iter().map(|&j| weyl(j)).fold(0.0, f64::max).sqrt();
    println!("Weyl at the minor-arc samples: worst |f|^2 / bound = {:.4}, bound on |f| <= {:.2}", wr, wb);
    assert!(wr <= 1.0);
    // ---- road 3: singular series from Gauss sums, singular integral from the ball ----
    let g52 = 3.0 * PI.sqrt() / 4.0; // Gamma(5/2) = (3/2)(1/2)Gamma(1/2)
    let h = 60.0 / 60000.0; // Simpson's rule for the integral of t^(3/2) e^(-t) on [0, 60]
    let simp = (0..=60000).map(|k| { let t = k as f64 * h;
        (if k == 0 || k == 60000 { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 }) * t.powf(1.5) * (-t).exp() }).sum::<f64>() * h / 3.0;
    println!("Gamma(5/2) = {:.8}; by Simpson's rule {:.8}", g52, simp);
    assert!((simp - g52).abs() < 1e-6);
    println!("J(1000) = (4 pi^2 / 3) x 1000^(3/2) = {:.4} x {}", 4.0 * PI * PI / 3.0, commas(1000f64.powf(1.5), 2));
    let ball = 8.0 * PI * PI / 15.0 * 1000f64.powf(2.5);
    println!("lattice points in the ball of radius sqrt(1000): {}; volume {}", commas(r5[..1001].iter().sum::<u64>() as f64, 0), commas(ball, 0));
    let mut series: HashMap<i64, Vec<f64>> = HashMap::new();
    for n in [1000i64, 1001] {
        let (mut part, mut cut) = (0.0, vec![0.0; 121]);
        for q in 1..=120 { part += a_term(q, n, 5); cut[q as usize] = part; }
        let jn = jint(n as f64, 5.0, g52);
        println!("n = {}: J = {}, series to 120 = {:.4}, prediction {}, off by {:.3}%", n, commas(jn, 1), part,
            commas(part * jn, 1), 100.0 * (part * jn / r5[n as usize] as f64 - 1.0));
        series.insert(n, cut);
    }
    let j1000 = jint(1000.0, 5.0, g52); let pts = [1, 2, 3, 4, 5, 6, 8, 10, 12, 15, 20, 30, 40, 60, 80, 100, 120];
    let ch: Vec<String> = pts.iter().map(|&q| format!("{:.0}", series[&1000][q] * j1000)).collect();
    println!("chart, prediction with series cut at q: {}", ch.join(", "));
    assert!((series[&1000][120] * j1000 / r5[1000] as f64 - 1.0).abs() < 0.002);
    // ---- road 4: local factors, by counting solutions mod p^k and by Gauss sums ----
    let mut local: HashMap<(usize, usize), f64> = HashMap::new();
    for (n, ps) in [(1000usize, [(2usize, 6u32), (3, 2), (5, 4), (7, 2)]), (1001, [(2, 6), (7, 2), (11, 2), (13, 2)])] {
        for (pp, k) in ps {
            let g = 1.0 + (1..=k).map(|i| a_term(pp.pow(i) as i64, n as i64, 5)).sum::<f64>();
            let d = density(pp, k, n, 5); local.insert((n, pp), d);
            println!("local factor n = {}, p = {}: count {:.7}, Gauss sums {:.7}", n, pp, d, g);
            assert!((g - d).abs() < 1e-9);
        }
    }
    let lim = 200000usize; let mut sv = vec![true; lim + 1]; sv[0] = false; sv[1] = false;
    for i in 2..448 { if sv[i] { let mut k = i * i; while k <= lim { sv[k] = false; k += i; } } }
    for n in [1000usize, 1001] {
        let mut prod = 1.0;
        for pp in 2..=lim {
            if !sv[pp] { continue; }
            let (mut b, mut ex, mut lg) = ((n % pp) as u64, ((pp - 1) / 2) as u64, 1u64);
            while ex > 0 { if ex & 1 == 1 { lg = lg * b % pp as u64; } b = b * b % pp as u64; ex >>= 1; }
            prod *= match local.get(&(n, pp)) { Some(&d) => d, None => 1.0 + (if lg == 1 { 1.0 } else { -1.0 }) / (pp as f64).powi(2) };
        }
        let jn = jint(n as f64, 5.0, g52);
        println!("full product to 200,000, n = {}: series {:.7}, times J = {}", n, prod, commas(prod * jn, 1));
        assert!((prod * jn - r5[n] as f64).abs() < 1.0);
    }
    // ---- what breaks ----
    println!("drop the series: J = {} against {}, {:.1}% high", commas(j1000, 1), commas(r5[1000] as f64, 0), 100.0 * (j1000 / r5[1000] as f64 - 1.0));
    let d3 = density(2, 5, 1007, 3);
    println!("three squares at 1007: J = {}, r_3 = {}, 2-adic factor {:.4}", commas(jint(1007.0, 3.0, PI.sqrt() / 2.0), 1), r3[1007], d3);
    let j4 = jint(1024.0, 4.0, 1.0);
    println!("four squares at 1024: J = {}, r_4 = {}, r_4 / J {:.4}; r_4(1000) = {}", commas(j4, 1), r4[1024], r4[1024] as f64 / j4, commas(r4[1000] as f64, 0));
    assert!(r3[1007] == 0 && d3 == 0.0 && r4[1024] == 24);
    println!("ALL CHECKS PASS");
}
