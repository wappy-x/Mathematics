// The Langlands program: the check behind the card.  std only, no crates.
// Road A: primes in Q(sqrt 5), by roots mod p, by Euler's test and by p mod 5.
// Road B: points on y^2 + y = x^3 - x^2 mod p, against the coefficients of
//         q * prod (1 - q^n)^2 (1 - q^(11n))^2, multiplied out here.
// Road C: Langlands dual root systems by transposing Cartan matrices.
use std::collections::HashSet;

fn primes_below(n: usize) -> Vec<i64> {
    let mut s = vec![true; n];
    s[0] = false; s[1] = false;
    for i in 2..n {
        if s[i] {
            let mut j = i * i;
            while j < n { s[j] = false; j += i; }
        }
    }
    (0..n).filter(|&i| s[i]).map(|i| i as i64).collect()
}
fn roots_mod(f: impl Fn(i64) -> i64, p: i64) -> i64 { (0..p).filter(|&x| f(x).rem_euclid(p) == 0).count() as i64 }
fn powmod(mut b: i64, mut e: i64, m: i64) -> i64 {
    let mut r = 1 % m; b %= m;
    while e > 0 { if e & 1 == 1 { r = r * b % m; } b = b * b % m; e >>= 1; }
    r
}
type M = Vec<Vec<i64>>;
fn transpose(m: &M) -> M { (0..m.len()).map(|j| m.iter().map(|r| r[j]).collect()).collect() }
fn det(m: &M) -> i64 {
    if m.len() == 1 { return m[0][0]; }
    (0..m.len()).map(|j| {
        let minor: M = m[1..].iter().map(|r| r.iter().enumerate().filter(|&(c, _)| c != j).map(|(_, &v)| v).collect()).collect();
        (if j % 2 == 0 { 1 } else { -1 }) * m[0][j] * det(&minor)
    }).sum()
}
fn roots(m: &M) -> HashSet<Vec<i64>> {
    let k = m.len();
    let mut seen: HashSet<Vec<i64>> = (0..k).map(|i| (0..k).map(|j| (i == j) as i64).collect()).collect();
    let mut todo: Vec<Vec<i64>> = seen.iter().cloned().collect();
    while let Some(b) = todo.pop() {
        for i in 0..k {
            let c: i64 = (0..k).map(|j| b[j] * m[j][i]).sum();
            let nb: Vec<i64> = (0..k).map(|j| b[j] - if j == i { c } else { 0 }).collect();
            if seen.insert(nb.clone()) { todo.push(nb); }
        }
    }
    seen
}
fn short_long(m: &M) -> (usize, usize) {
    let k = m.len();
    let mut l = vec![0i64; k]; l[0] = 6;
    while l.contains(&0) {
        for i in 0..k { for j in 0..k {
            if l[i] != 0 && l[j] == 0 && m[i][j] != 0 { l[j] = m[j][i] * l[i] / m[i][j]; }
        } }
    }
    let sq: Vec<i64> = roots(m).iter().map(|b| {
        let mut t = 0;
        for i in 0..k { for j in 0..k { t += b[i] * b[j] * m[i][j] * l[j] / 2; } }
        t
    }).collect();
    let mn = *sq.iter().min().unwrap();
    (sq.iter().filter(|&&x| x == mn).count(), sq.iter().filter(|&&x| x > mn).count())
}
fn perms(k: usize) -> Vec<Vec<usize>> {
    if k == 0 { return vec![vec![]]; }
    let mut out = vec![];
    for p in perms(k - 1) { for pos in 0..k { let mut q = p.clone(); q.insert(pos, k - 1); out.push(q); } }
    out
}
fn same_up_to_order(a: &M, b: &M) -> bool {
    let k = a.len();
    k == b.len() && perms(k).iter().any(|s| (0..k).all(|i| (0..k).all(|j| a[s[i]][s[j]] == b[i][j])))
}

fn main() {
    println!("== Road A: which primes split in Q(sqrt 5) ==");
    let (mut splits, mut agree, mut total) = (0, 0, 0);
    for &p in primes_below(1000).iter() {
        if p == 5 { continue; }
        let r = roots_mod(|x| x * x - x - 1, p);
        let rule = if p % 5 == 1 || p % 5 == 4 { 2 } else { 0 };
        let e = if p == 2 { 1 } else { powmod(5, (p - 1) / 2, p) };
        let euler = if e == 1 { 2 } else { 0 };
        if [7, 11, 13, 19].contains(&p) {
            let rts: Vec<i64> = (0..p).filter(|&x| (x * x - x - 1).rem_euclid(p) == 0).collect();
            println!("p={}: p mod 5 = {}, roots of x^2 - x - 1 mod p: {:?}, 5^((p-1)/2) mod p = {}, {}",
                     p, p % 5, rts, if e == 1 { 1 } else { -1 }, if r == 2 { "splits" } else { "stays prime" });
        }
        total += 1;
        if r == 2 { splits += 1; }
        if r == rule && (p == 2 || euler == r) { agree += 1; }
    }
    assert!(agree == total && total == 167);
    println!("primes below 1000 except 5: {}; the tests agree at {} (three at the {} odd primes, two at p=2)", total, agree, total - 1);
    println!("split: {} of {}, stay prime: {}, share split {:.3} (Chebotarev predicts 1/2)", splits, total, total - splits, splits as f64 / total as f64);
    let bad7: Vec<i64> = primes_below(1000).into_iter().filter(|&p| p != 2 && p != 7
        && ((roots_mod(|x| x * x - 7, p) == 2) != [1, 2, 4].contains(&(p % 7)))).collect();
    assert!(bad7[0] == 3);
    println!("wrong rule 'p splits in Q(sqrt 7) iff p is a square mod 7': fails first at p={}, fails at {} of {} primes below 1000",
             bad7[0], bad7.len(), primes_below(1000).len() - 2);

    println!("== Road B: y^2 + y = x^3 - x^2 against a modular form of level 11 ==");
    const N: usize = 130;
    let mut form = vec![0i64; N]; form[1] = 1;
    for n in 1..N {
        for step in [n, 11 * n] {
            if step < N {
                for _ in 0..2 { for i in (step..N).rev() { form[i] -= form[i - step]; } }
            }
        }
    }
    let first: Vec<String> = (1..13).map(|n| form[n].to_string()).collect();
    println!("form coefficients a_1..a_12: {}", first.join(" "));
    let a_count = |p: i64| -> i64 {
        let mut c = 0;
        for x in 0..p { for y in 0..p { if (y * y + y - x * x * x + x * x).rem_euclid(p) == 0 { c += 1; } } }
        p - c
    };
    let ps = primes_below(100);
    let by_x: Vec<String> = (0..3i64).map(|x| (0..3i64).filter(|&y| (y * y + y - x * x * x + x * x).rem_euclid(3) == 0).count().to_string()).collect();
    println!("p=3 by hand: solutions with x = 0, 1, 2: {}", by_x.join(" "));
    for p in [2i64, 3, 5, 7, 11, 13] {
        println!("p={}: solutions mod p = {}, a_p = p - solutions = {}, coefficient of q^{} = {}",
                 p, p - a_count(p), a_count(p), p, form[p as usize]);
    }
    let matched = ps.iter().filter(|&&p| a_count(p) == form[p as usize]).count();
    assert!(matched == ps.len() && matched == 25);
    println!("primes below 100: {}; point count equals coefficient at {} (checked for p < 100)", ps.len(), matched);
    let ratio = ps.iter().map(|&p| form[p as usize].abs() as f64 / (2.0 * (p as f64).sqrt())).fold(0.0, f64::max);
    assert!(ratio <= 1.0);
    println!("Hasse bound: largest |a_p| / (2 sqrt p) for p < 100 = {:.6}", ratio);
    for p in [2usize, 3, 7] {
        assert!(form[p * p] == form[p] * form[p] - p as i64);
        println!("a_{} = {}, a_{}^2 - {} = {}", p * p, form[p * p], p, p, form[p] * form[p] - p as i64);
    }
    assert!(form[6] == form[2] * form[3] && form[10] == form[2] * form[5]);
    println!("a_6 = {} = a_2 a_3; a_10 = {} = a_2 a_5", form[6], form[10]);
    assert!(form[121] == form[11] * form[11] && form[121] == 1);
    println!("bad prime 11: a_121 = {}; the good-prime rule would give {}", form[121], form[11] * form[11] - 11);
    println!("forget the point at infinity at p=2: p + 1 - solutions = {}, not {}", 2 + 1 - (2 - a_count(2)), a_count(2));
    let mut s32 = 0;
    for x in 0..3i64 { for y in 0..3i64 { if (y * y - x * x * x + x).rem_euclid(3) == 0 { s32 += 1; } } }
    println!("wrong curve y^2 = x^3 - x (level 32): a_3 = {}, not {}", 3 - s32, form[3]);
    let j = |v: Vec<String>| v.join(" ");
    println!("chart, p: {}", j(ps.iter().map(|p| p.to_string()).collect()));
    println!("chart, a_p: {}", j(ps.iter().map(|&p| form[p as usize].to_string()).collect()));
    println!("chart, 2 sqrt p: {}", j(ps.iter().map(|&p| format!("{:.2}", 2.0 * (p as f64).sqrt())).collect()));
    println!("chart, -2 sqrt p: {}", j(ps.iter().map(|&p| format!("{:.2}", -2.0 * (p as f64).sqrt())).collect()));

    println!("== Road C: the Langlands dual swaps roots and coroots ==");
    let cartan: Vec<(&str, M)> = vec![
        ("A2", vec![vec![2, -1], vec![-1, 2]]), ("G2", vec![vec![2, -1], vec![-3, 2]]),
        ("B3", vec![vec![2, -1, 0], vec![-1, 2, -2], vec![0, -1, 2]]),
        ("C3", vec![vec![2, -1, 0], vec![-1, 2, -1], vec![0, -2, 2]])];
    for (name, m) in cartan.iter() {
        let t = transpose(m);
        let dual = cartan.iter().find(|(_, x)| same_up_to_order(x, &t)).unwrap().0;
        let ((s, lg), (ds, dl)) = (short_long(m), short_long(&t));
        println!("{}: Cartan {:?}, det {}, roots {} ({} short, {} long); dual {}: {} short, {} long",
                 name, m, det(m), roots(m).len(), s, lg, dual, ds, dl);
        assert!(roots(m).len() == roots(&t).len());
        assert!((s, lg) == if lg > 0 { (dl, ds) } else { (ds, dl) });
    }
    let (b3, c3) = (&cartan[2].1, &cartan[3].1);
    assert!(cartan.iter().find(|(_, x)| same_up_to_order(x, &transpose(b3))).unwrap().0 == "C3" && !same_up_to_order(b3, c3));
    assert!(roots(b3).len() == 18 && short_long(b3) == (6, 12));
    println!("B3 equals C3 in some node order: {}", if same_up_to_order(b3, c3) { "True" } else { "False" });
    println!("ALL CHECKS PASS");
}
