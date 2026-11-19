// Pell's equation from the continued fraction of a square root -- the same
// check as the Python, in Rust.  No crates; u128 and i128 with checked overflow.
// Road 1: the continued fraction of root d, run in whole numbers (m, c, a).
// Road 2: brute force, trying y = 1, 2, 3, ... until d*y*y + 1 is a square.
// Road 3: algebra, multiplying units of the form x + y*root(d).
type Pair = (u128, u128);

fn isqrt(n: u128) -> u128 {                     // whole square root, corrected after f64
    let mut r = (n as f64).sqrt() as u128;
    while r * r > n { r -= 1 }
    while (r + 1) * (r + 1) <= n { r += 1 }
    r
}

fn expand(d: u128, terms: usize) -> Vec<(u128, u128, u128)> {  // (m_k, c_k, a_k)
    let a0 = isqrt(d);
    let (mut m, mut c, mut a) = (0u128, 1u128, a0);
    let mut out = vec![(m, c, a)];
    for _ in 1..terms {
        m = c * a - m;
        c = (d - m * m) / c;                    // always exact: c_k divides d - m_(k+1)^2
        a = (a0 + m) / c;
        out.push((m, c, a));
    }
    out
}

fn ck(a: u128, b: u128) -> u128 { a.checked_mul(b).expect("overflow") }
fn ca(a: u128, b: u128) -> u128 { a.checked_add(b).expect("overflow") }

fn convergents(states: &[(u128, u128, u128)]) -> Vec<Pair> {  // p_k = a_k p_(k-1) + p_(k-2)
    let (mut p0, mut p1, mut q0, mut q1) = (0u128, 1u128, 1u128, 0u128);
    let mut out = Vec::new();
    for &(_, _, a) in states {
        let (p, q) = (ca(ck(a, p1), p0), ca(ck(a, q1), q0));
        p0 = p1; p1 = p; q0 = q1; q1 = q;
        out.push((p, q));
    }
    out
}

fn period(d: u128) -> usize {                   // first k >= 1 with c_k = 1
    let mut k = 1;
    while expand(d, k + 1)[k].1 != 1 { k += 1 }
    k
}

fn fundamental(d: u128) -> Pair {               // one period's end, or two if odd
    let l = period(d);
    let k = if l % 2 == 0 { l - 1 } else { 2 * l - 1 };
    convergents(&expand(d, k + 1))[k]
}

fn brute(d: u128, ymax: u128) -> Option<Pair> { // road 2: first y with d y^2 + 1 square
    for y in 1..=ymax {
        let n = d * y * y + 1;
        let r = isqrt(n);
        if r * r == n { return Some((r, y)) }
    }
    None
}

fn mul(u: Pair, v: Pair, d: u128) -> Pair {     // (x1 + y1 root d)(x2 + y2 root d)
    (ca(ck(u.0, v.0), ck(d, ck(u.1, v.1))), ca(ck(u.0, v.1), ck(u.1, v.0)))
}

fn norm(p: Pair, d: u128) -> i128 {
    let (x, y) = (p.0 as i128, p.1 as i128);
    x.checked_mul(x).unwrap() - (d as i128) * y.checked_mul(y).unwrap()
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn show(o: Option<Pair>) -> String { match o { Some(p) => format!("{:?}", p), None => "None".into() } }
fn list<T: std::fmt::Display>(v: &[T]) -> String {
    format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "))
}

fn main() {
    let d: u128 = 61;
    let st = expand(d, 67);
    let cv = convergents(&st);
    let nm: Vec<i128> = (0..44).map(|k| norm(cv[k], d)).collect();
    let l = period(d);
    println!("root {}: a0 = {}, period length {} ({})", d, st[0].2, l, if l % 2 == 1 { "odd" } else { "even" });
    println!(" k m_k c_k a_k    p_k   q_k  p_k^2 - 61 q_k^2");
    for k in 0..12 {
        println!("{:>2} {:>3} {:>3} {:>3} {:>6} {:>5} {:>5}", k, st[k].0, st[k].1, st[k].2, cv[k].0, cv[k].1, nm[k]);
    }
    let cf: Vec<u128> = st[..12].iter().map(|t| t.2).collect();
    println!("continued fraction: {}", list(&cf));
    let ident = (0..44).all(|k| nm[k] == if k % 2 == 0 { -1 } else { 1 } * st[k + 1].1 as i128);
    println!("p_k^2 - 61 q_k^2 = (-1)^(k+1) c_(k+1) for k = 0..43: {}", yn(ident));
    let ones: Vec<usize> = (0..67).filter(|&k| st[k].1 == 1).collect();
    println!("c_k = 1 at k = {}", list(&ones));
    let (x1, y1) = fundamental(d);
    println!("one period, k = 10: ({}, {}), norm {}", cv[10].0, cv[10].1, nm[10]);
    println!("two periods, k = 21: ({}, {}), norm {}; x has {} digits", x1, y1, norm((x1, y1), d), x1.to_string().len());
    let sq = mul(cv[10], cv[10], d);
    println!("(29718 + 3805 root 61)^2 = ({}, {})", sq.0, sq.1);
    let h: Pair = (39, 5);                      // (39 + 5 root 61) / 2, kept as its doubled pair
    let h3 = mul(mul(h, h, d), h, d);
    println!("(39 + 5 root 61)/2: norm {}; cubed = {} + {} root 61", (39 * 39 - 61 * 25) / 4, h3.0 / 8, h3.1 / 8);
    let (mut pw, mut same) = ((1u128, 0u128), true);
    for n in 1..=3usize {
        pw = mul(pw, (x1, y1), d);
        let c = cv[22 * n - 1];
        same &= c == pw;
        println!("solution {}: convergent k = {} is ({}, {}); equals power {}: {}", n, 22 * n - 1, c.0, c.1, n, yn(c == pw));
    }
    let plus: Vec<usize> = (0..44).filter(|&k| nm[k] == 1).collect();
    println!("convergents with norm +1, k = 0..43: {}", list(&plus));
    let ymax: u128 = 100000;
    let ds: Vec<u128> = (2..101).filter(|&e| isqrt(e) * isqrt(e) != e).collect();
    let fund: Vec<Pair> = ds.iter().map(|&e| fundamental(e)).collect();
    let bf: Vec<Option<Pair>> = ds.iter().map(|&e| brute(e, ymax)).collect();
    let agree: Vec<u128> = (0..ds.len()).filter(|&i| bf[i] == Some(fund[i])).map(|i| ds[i]).collect();
    let none: Vec<u128> = (0..ds.len()).filter(|&i| bf[i].is_none()).map(|i| ds[i]).collect();
    let beyond: Vec<u128> = (0..ds.len()).filter(|&i| fund[i].1 > ymax).map(|i| ds[i]).collect();
    println!("nonsquare d up to 100: {}; brute force to y = 100,000 agrees on {}", ds.len(), agree.len());
    let ny: Vec<u128> = (0..ds.len()).filter(|&i| bf[i].is_none()).map(|i| fund[i].1).collect();
    println!("brute force finds nothing for d = {}; their y = {}, all beyond 100,000: {}", list(&none), list(&ny), yn(none == beyond));
    let ri = (0..ds.len()).max_by_key(|&i| fund[i].0).unwrap();
    println!("largest smallest x below 100: d = {}, x = {}", ds[ri], fund[ri].0);
    println!("root 13: period {}, first +1 solution at k = 9: {:?}", period(13), fundamental(13));
    for e in 55..68u128 {
        if e != 64 {
            let (x, y) = fundamental(e);
            let n = x.to_string().len();
            println!("bar,{},{},{},x = {}, y = {}", e, n, "#".repeat(n), x, y);
        }
    }
    let sw: Vec<u128> = (2..1001).filter(|&e| isqrt(e) * isqrt(e) != e).collect();
    let (mut ends, mut pal, mut bounds, mut onlyends, mut odd) = (true, true, true, true, 0);
    for &e in &sw {
        let (a0, ll) = (isqrt(e), period(e));
        let s = expand(e, 3 * ll + 1);
        let a: Vec<u128> = s[1..=ll].iter().map(|t| t.2).collect();
        ends &= a[ll - 1] == 2 * a0;
        let mid: Vec<u128> = a[..ll - 1].to_vec();
        let mut rev = mid.clone();
        rev.reverse();
        pal &= mid == rev;
        bounds &= s[1..].iter().all(|t| 0 < t.0 && t.0 <= a0 && 0 < t.1 && t.1 <= 2 * a0);
        let o: Vec<usize> = (0..s.len()).filter(|&k| s[k].1 == 1).collect();
        onlyends &= o == vec![0, ll, 2 * ll, 3 * ll];
        odd += ll % 2;
    }
    println!("nonsquare d up to 1,000: {}; every period ends in 2 a0: {}; rest reads the same backwards: {}", sw.len(), yn(ends), yn(pal));
    println!("0 < m_k <= a0 and 0 < c_k <= 2 a0 throughout: {}; c_k = 1 only at period ends: {}; odd periods: {}", yn(bounds), yn(onlyends), odd);
    println!("mistake, one step too far (k = 11): ({}, {}), norm {}", cv[11].0, cv[11].1, nm[11]);
    println!("mistake, d = 64 a square: root 64 = [8], stops; brute force to y = 100,000: {}", show(brute(64, ymax)));
    println!("mistake, brute force on 61 to y = 1,000,000: {}", show(brute(d, 1000000)));
    assert!(l == 11 && cv[10] == (29718, 3805) && nm[10] == -1);              // one period gives -1
    assert!((x1, y1) == (1766319049, 226153980) && norm((x1, y1), d) == 1);
    assert!(sq == (x1, y1) && h3 == (8 * 29718, 8 * 3805));                  // algebra road
    assert!(ident && ones == vec![0, 11, 22, 33, 44, 55, 66] && plus == vec![21, 43] && same);
    let rest: Vec<u128> = ds.iter().copied().filter(|e| !beyond.contains(e)).collect();
    assert!(agree == rest && none == beyond);                                  // brute-force road
    assert!(ends && pal && bounds && onlyends && brute(64, ymax).is_none());
    println!("ALL CHECKS PASS");
}
