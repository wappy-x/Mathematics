// Sequence spaces: the check behind the card.  Rust std only, no crates.
// A fading guitar note, one peak per cycle, x_n = 0.98^(n-1), and five test
// lists are sized in l1, l2 and the sup norm.  Nothing imported knows a norm:
// every sum is a plain loop and every power of 0.98 a repeated multiply.
// Roads: closed forms (geometric series, pi^2/6, ln 2 by its own series)
// against long partial sums; integral bounds for the sums that never settle;
// brute force over on/off patterns for separability.  Same output as Python.
const R: f64 = 0.98; // 2% peak loss per cycle
const HZ: f64 = 110.0; // A string at 110 Hz (illustrative)
const NS: [usize; 3] = [100, 10000, 1000000]; // where the partial sums are read

fn norms(xs: &[f64]) -> (f64, f64, f64) {
    let (mut s1, mut s2, mut top) = (0.0f64, 0.0f64, 0.0f64);
    for &v in xs {
        (s1, s2, top) = (s1 + v.abs(), s2 + v * v, top.max(v.abs()));
    }
    (s1, s2.sqrt(), top)
}

fn partial(mut term: impl FnMut(usize) -> f64) -> Vec<(f64, f64, f64)> {
    let (mut s, mut s1, mut s2) = (0.0f64, 0.0f64, 0.0f64);
    let mut out = vec![];
    for n in 1..=NS[2] {
        let v = term(n);
        (s, s1, s2) = (s + v, s1 + v.abs(), s2 + v * v);
        if NS.contains(&n) { out.push((s, s1, s2)); }
    }
    out
}

fn row(label: &str, vals: &[f64]) {
    let body: String = vals.iter().map(|v| format!("{:13.4}", v)).collect();
    println!("   {:<20}{}", label, body);
}

fn sup_dist(a: &[u8], b: &[u8]) -> u8 {
    a.iter().zip(b).map(|(u, v)| if u > v { u - v } else { v - u }).max().unwrap()
}

fn bits(p: &[u8]) -> String {
    p.iter().map(|b| b.to_string()).collect()
}

fn main() {
    println!("1. the note: x_n = 0.98^(n-1), one peak per cycle");
    let mut five = vec![1.0f64];
    for _ in 0..4 { five.push(five[five.len() - 1] * R); }
    let f: Vec<String> = five.iter().map(|v| format!("{:.8}", v)).collect();
    println!("   first five peaks {}", f.join(" "));
    let (a1, a2, a3) = norms(&five);
    println!("   first five: l1 {:.4}  l2 {:.4}  sup {:.4}", a1, a2, a3);
    let (l1, e, l2) = (1.0 / (1.0 - R), 1.0 / (1.0 - R * R), 1.0 / (1.0 - R * R).sqrt());
    println!("   whole note, closed form: l1 {:.4}  sum of squares {:.4}  l2 {:.4}  sup 1", l1, e, l2);

    println!("2. partial sums after N = 100, 10000, 1000000 entries");
    let mut st = 1.0 / R;
    let note = partial(|_| { st *= R; st });
    let h = partial(|n| 1.0 / n as f64);
    let alt = partial(|n| (if n % 2 == 1 { 1.0 } else { -1.0 }) / n as f64);
    let rt = partial(|n| 1.0 / (n as f64).sqrt());
    let held = partial(|_| 1.0);
    for (name, p) in [("note", &note), ("1/n", &h), ("signed", &alt), ("1/sqrt(n)", &rt), ("held", &held)] {
        if name == "signed" {
            row("(-1)^(n+1)/n  sum x", &p.iter().map(|q| q.0).collect::<Vec<_>>());
            continue;
        }
        row(&format!("{}  sum|x|", name), &p.iter().map(|q| q.1).collect::<Vec<_>>());
        row(&format!("{}  sum x^2", name), &p.iter().map(|q| q.2).collect::<Vec<_>>());
    }
    println!("   ramp x_n = n: largest entry 100, 10000, 1000000: no ceiling");

    println!("3. second roads");
    assert!((note[2].1 - l1).abs() < 1e-9 && (note[2].2 - e).abs() < 1e-9); // geometric series
    let basel = std::f64::consts::PI.powi(2) / 6.0;
    let n = NS[1] as f64;
    let em = h[1].2 + 1.0 / n - 1.0 / (2.0 * n * n) + 1.0 / (6.0 * n * n * n); // Euler-Maclaurin tail
    println!("   sum 1/n^2: to 10000 plus tail {:.9}; pi^2/6 {:.9}; l2 norm of 1/n {:.6}", em, basel, basel.sqrt());
    assert!((em - basel).abs() < 1e-10);
    for (k, &nk) in NS.iter().enumerate() {
        let x = nk as f64;
        assert!((x + 1.0).ln() <= h[k].1 && h[k].1 <= 1.0 + x.ln()); // harmonic squeeze
        assert!(2.0 * (x + 1.0).sqrt() - 2.0 <= rt[k].1 && rt[k].1 <= 2.0 * x.sqrt() - 1.0);
        assert!((rt[k].2 - h[k].1).abs() < 1e-9 && held[k].1 == x); // squares of 1/sqrt(n) are 1/n
    }
    println!("   harmonic minus ln N at 10^6: {:.6} (Euler's constant plus 1/(2N))", h[2].1 - (NS[2] as f64).ln());
    println!("   gain from 10^4 to 10^6: {:.6}; 2 ln 10 = {:.6}", h[2].1 - h[1].1, 2.0 * 10f64.ln());
    assert!((h[2].1 - h[1].1 - 2.0 * 10f64.ln()).abs() < 1e-4);
    let mut ln2 = 0.0f64;
    for k in 1..=60 {
        ln2 += 1.0 / (k as f64 * 2f64.powi(k)); // ln 2 = sum 1/(k 2^k)
    }
    println!("   signed sum at 10^6 {:.6}; ln 2 by its own series {:.6}", alt[2].0, ln2);
    assert!((alt[2].0 - ln2).abs() <= 1.0 / (NS[2] as f64 + 1.0) && (ln2 - 2f64.ln()).abs() < 1e-15);
    assert!((alt[2].1 - h[2].1).abs() < 1e-9); // signed list: sizes are 1/n

    println!("4. sup distance from each list to its cut after N entries");
    let cuts: Vec<usize> = (0..=200).step_by(25).collect();
    let (mut a, mut tails) = (1.0f64, vec![]);
    for n in 0..=200 {
        if cuts.contains(&n) { tails.push(a); }
        a *= R;
    }
    for (n, t) in cuts.iter().zip(&tails) {
        assert!((t - (*n as f64 * R.ln()).exp()).abs() < 1e-12); // two roads to R^N
    }
    let line = |v: Vec<String>| v.join(" ");
    println!("   N      {}", line(cuts.iter().map(|n| format!("{:6}", n)).collect()));
    println!("   note   {}", line(tails.iter().map(|t| format!("{:6.4}", t)).collect()));
    println!("   1/sqrt {}", line(cuts.iter().map(|n| format!("{:6.4}", 1.0 / ((n + 1) as f64).sqrt())).collect()));
    println!("   held   {}", line(cuts.iter().map(|_| format!("{:6.4}", 1.0)).collect()));
    let mut x = vec![1.0f64];
    while x.len() < 3000 { x.push(x[x.len() - 1] * R); }
    let db60 = (0..x.len()).find(|&n| x[n] <= 0.001).unwrap();
    assert!(db60 as f64 == (0.001f64.ln() / R.ln()).ceil());
    println!("   -60 dB after {} cycles = {:.2} s", db60, db60 as f64 / HZ);
    let (t1, t2, _) = norms(&x[100..]);
    assert!((t1 - l1 * R.powf(100.0)).abs() < 1e-9 && (t2 - l2 * R.powf(100.0)).abs() < 1e-9);
    println!("   cut at 100: l1 gap {:.4}  l2 gap {:.4}  sup gap {:.4}", t1, t2, x[100]);
    let mut gap = 0.0f64;
    for (i, &v) in x.iter().enumerate() {
        let q = if i < db60 { (v * 10000.0).round() / 10000.0 } else { 0.0 };
        gap = gap.max((v - q).abs());
    }
    println!("   {} peaks rounded to 4 decimals, rest 0: sup distance {:.7}", db60, gap);
    assert!(gap <= 0.001);

    println!("5. unit lists and on/off patterns");
    let d: Vec<f64> = (1..=8).map(|n| if n == 3 { 1.0 } else if n == 7 { -1.0 } else { 0.0 }).collect();
    let (d1, d2, d3) = norms(&d);
    println!("   e_3 - e_7: l1 {:.4}  l2 {:.4}  sup {:.4}", d1, d2, d3);
    assert!((d1 - 2.0).abs() < 1e-15 && (d2 - 2f64.sqrt()).abs() < 1e-15 && d3 == 1.0);
    let s = 8usize;
    let pats: Vec<Vec<u8>> = (0..1usize << s).map(|k| (0..s).map(|j| ((k >> (s - 1 - j)) & 1) as u8).collect()).collect();
    let mut far = 0usize;
    for i in 0..pats.len() {
        for j in 0..i {
            if sup_dist(&pats[i], &pats[j]) == 1 { far += 1; }
        }
    }
    println!("   {} slots: {} patterns, {} pairs, all at sup distance 1", s, pats.len(), far);
    assert!(far == pats.len() * (pats.len() - 1) / 2);
    let listed: Vec<Vec<u8>> = (0..s).map(|k| pats[(37 * k + 11) % 256].clone()).collect();
    let diag: Vec<u8> = (0..s).map(|k| 1 - listed[k][k]).collect();
    let ls: Vec<String> = listed.iter().map(|p| bits(p)).collect();
    println!("   listed {}  diagonal {}", ls.join(" "), bits(&diag));
    assert!(!listed.contains(&diag) && pats.iter().filter(|p| (0..s).all(|k| p[k] != listed[k][k])).collect::<Vec<_>>() == vec![&diag]); // brute force

    println!("6. try changing");
    let r2 = 0.99f64;
    let c2 = (0.001f64.ln() / r2.ln()).ceil();
    println!("   R = 0.99: l1 {:.4}  l2 {:.4}  -60 dB after {} cycles = {:.2} s", 1.0 / (1.0 - r2), 1.0 / (1.0 - r2 * r2).sqrt(), c2, c2 / HZ);
    let (mut s1, mut s2, mut got) = (0.0f64, 0.0f64, vec![]);
    for n in 1..=NS[2] {
        let q = (n as f64).sqrt();
        let v = 1.0 / (q * q.sqrt());
        (s1, s2) = (s1 + v, s2 + v * v);
        if n == NS[1] || n == NS[2] { got.push((s1, s2)); }
    }
    println!("   fade n^(-3/4): sum|x| {:.4} -> {:.4}; sum x^2 {:.4} -> {:.4}", got[0].0, got[1].0, got[0].1, got[1].1);
    println!("   10 slots: {} patterns, {} pairs", 1u64 << 10, (1u64 << 10) * ((1u64 << 10) - 1) / 2);
    let (p1, p2, p3) = norms(&[0.6, 0.6]);
    println!("figure, unit balls: diamond (+-1,0),(0,+-1); circle r 1; square (+-1,+-1); point (0.6, 0.6) l1 {:.4} l2 {:.4} sup {:.4}; svg centre (210, 200), 150 px per unit", p1, p2, p3);
    println!("ALL CHECKS PASS");
}
