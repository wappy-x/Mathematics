// Quasi-coherent and coherent sheaves -- the same check as the Python, in Rust.
// No crates; every number is an exact integer.  Part 1: the module M = Z/6
// over R = Z, spread over Spec Z as the sheaf M~.  Part 2: O(d) on the
// projective line P^1 over Q, built from the shifted graded module S(d),
// S = Q[x, y].  Part 3: the ideal sheaf of the point P = (1 : 2) is O(-1).
// Roads: fractions m/s sorted into classes by brute force, against a count of
// what the denominators kill and the Chinese remainder gluing; d + 1 monomials
// against the rank of the gluing map and a count of glued pairs over F_3; the
// ideal's dimensions against S(-1), and forms vanishing at P counted over F_3.
use std::collections::{BTreeMap, BTreeSet};

const N: i64 = 6;
const PRIMES: [i64; 6] = [2, 3, 5, 7, 11, 13];

fn name(c: i64) -> String { if c == 1 { "0".to_string() } else { format!("Z/{}", c) } }   // the stalks here are cyclic

fn classes(s_set: &[i64]) -> i64 {       // road one: sort pairs (m, s) by u (m t - m' s) = 0 in Z/6
    let mut reps: Vec<(i64, i64)> = Vec::new();
    for m in 0..N { for &s in s_set {
        if !reps.iter().any(|&(m2, t)| s_set.iter().any(|&u| (u * (m * t - m2 * s)).rem_euclid(N) == 0)) {
            reps.push((m, s));
        }
    } }
    reps.len() as i64
}

fn kept(s_set: &[i64]) -> i64 {          // road two: M_S = M / (what some s kills); count that kernel
    N / (0..N).filter(|&m| s_set.iter().any(|&s| s * m % N == 0)).count() as i64
}

fn p_part(p: i64) -> i64 {               // road three: p to the number of times p divides N
    let (mut n, mut out) = (N, 1);
    while n % p == 0 { n /= p; out *= p }
    out
}

fn uniq(v: impl Iterator<Item = i64>) -> Vec<i64> { v.collect::<BTreeSet<i64>>().into_iter().collect() }
fn away(p: i64) -> Vec<i64> { uniq((1..=N * p).filter(|n| n % p != 0).map(|n| n % N)) }
fn powers(f: i64) -> Vec<i64> { uniq((0..N as u32).map(|k| f.pow(k) % N)) }

fn laurent(f: &[i64], g: &[i64], d: i64) -> BTreeMap<i64, i64> {  // f(t) - t^d g(1/t)
    let mut out = BTreeMap::new();
    for (i, c) in f.iter().enumerate() { *out.entry(i as i64).or_insert(0) += c }
    for (j, c) in g.iter().enumerate() { *out.entry(d - j as i64).or_insert(0) -= c }
    out.retain(|_, v| *v != 0);
    out
}

fn rank(rows: &[Vec<i64>]) -> usize {    // exact elimination over Q, kept in whole numbers
    let mut rows = rows.to_vec();
    let mut r = 0;
    let width = if rows.is_empty() { 0 } else { rows[0].len() };
    for col in 0..width {
        let Some(piv) = (r..rows.len()).find(|&i| rows[i][col] != 0) else { continue };
        rows.swap(r, piv);
        for i in 0..rows.len() {
            if i != r && rows[i][col] != 0 {
                let (a, b) = (rows[r][col], rows[i][col]);
                rows[i] = rows[i].iter().zip(&rows[r]).map(|(x, y)| a * x - b * y).collect();
            }
        }
        r += 1;
    }
    r
}

fn glued_rank(d: i64) -> usize {         // road two: kernel of (f, g) -> f(t) - t^d g(1/t), degrees at most 6
    let deg = 6;
    let unit = |k: usize| (0..=deg).map(|i| (i == k) as i64).collect::<Vec<i64>>();
    let mut cols: Vec<BTreeMap<i64, i64>> = (0..=deg).map(|k| laurent(&unit(k), &[], d)).collect();
    cols.extend((0..=deg).map(|k| laurent(&[], &unit(k), d)));
    let rows: Vec<Vec<i64>> = (d - deg as i64..=deg as i64).map(|e| cols.iter().map(|c| *c.get(&e).unwrap_or(&0)).collect()).collect();
    2 * (deg + 1) - rank(&rows)
}

fn glued_f3(d: i64) -> usize {           // road three: every pair (f, g) over F_3 of degree at most 2
    let vecs: Vec<[i64; 3]> = (0..27).map(|i| [i % 3, i / 3 % 3, i / 9]).collect();
    vecs.iter().map(|f| vecs.iter().filter(|g| laurent(f.as_slice(), g.as_slice(), d).values().all(|v| v % 3 == 0)).count()).sum()
}

fn monomials(d: i64) -> usize { (0..=d).flat_map(|i| (0..=d).map(move |j| (i, j))).filter(|&(i, j)| i + j == d).count() }

fn join(v: &[i64]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ") }

fn main() {
    let everything = uniq((1..=N).map(|n| n % N));
    let stalk: Vec<(i64, i64, i64)> = PRIMES.iter().map(|&p| (classes(&away(p)), kept(&away(p)), p_part(p))).collect();
    let gen = (classes(&everything), kept(&everything));
    println!("R = Z, M = Z/{}; the stalk of M~ at a prime (p) is M_(p): fractions m/s with p not dividing s", N);
    for (p, &(c, k, q)) in PRIMES.iter().zip(&stalk) {
        println!("stalk at ({}): classes {}, M/kernel {}, p-part {}: {}", p, c, k, q, name(c));
    }
    println!("stalk at (0), the generic point: classes {}, M/kernel {}: 0, since {} is inverted there", gen.0, gen.1, N);
    let labelled = [("D(2)", powers(2)), ("D(3)", powers(3)), ("D(6)", powers(6)), ("(2)", away(2)), ("(3)", away(3)),
                    ("(5)", away(5)), ("(0)", everything.clone())];
    for (label, s_set) in &labelled {
        let killed: Vec<i64> = (0..N).filter(|&m| s_set.iter().any(|&s| s * m % N == 0)).collect();
        println!("{}: bottoms mod {} {:?}, killed {:?}", label, N, s_set, killed);
    }
    let sec: BTreeMap<i64, i64> = [1, 2, 3, 6].iter().map(|&f| (f, classes(&powers(f)))).collect();
    println!("sections over D(2), D(3), D(6), Spec Z: {}, {}, {}, {}", name(sec[&2]), name(sec[&3]), name(sec[&6]), name(sec[&1]));
    let (a, b): (i64, i64) = (-3..4).flat_map(|a| (-3..4).map(move |b| (a, b))).find(|&(a, b)| 2 * a + 3 * b == 1).unwrap();
    let glue: BTreeSet<(i64, i64)> = (0..N).map(|m| (m % 3, m % 2)).collect();
    println!("D(2) and D(3) cover Spec Z, since 1 = {}*2 + ({})*3; Z/6 -> Z/3 x Z/2 hits {} of 6 pairs", a, b, glue.len());
    let m5 = (2 * (a * 2) + b * 3).rem_euclid(N);
    println!("glue 2 in Z/3 with 1 in Z/2: m = 2*({}) + 1*{} = {} mod 6; {} mod 3 = {}, {} mod 2 = {}", a * 2, b * 3, m5, m5, m5 % 3, m5, m5 % 2);
    let fib: Vec<i64> = PRIMES.iter().map(|&p| N / uniq((0..N).map(|m| p * m % N)).len() as i64).collect();
    let dims: Vec<i64> = PRIMES.iter().zip(&fib).map(|(&p, &size)| (0..6).find(|&e| p.pow(e as u32) == size).unwrap()).collect();
    let gdim = 1 - rank(&[vec![N]]) as i64;   // at (0): M = Z/6 has one generator and one relation, 6; over Q that relation has rank 1
    println!("M/pM has {} elements, so the fibre dimension of M ⊗ k(p) at (2), (3), (5), (7), (11), (13) is {}; at (0): {}",
             join(&fib), join(&dims), gdim);
    println!("P^1 = Proj Q[x, y]; O(d) = S(d)~ with S(d)_n = S_(d+n); charts t = y/x and s = x/y");
    let counts: Vec<(i64, usize, usize, usize)> = (-2..3).map(|d| (d, monomials(d), glued_rank(d), glued_f3(d))).collect();
    for &(d, m, r, c) in &counts {
        println!("d = {}: monomials of degree d {}, kernel of the gluing map {}, glued pairs over F_3 (of 729) {}", d, m, r, c);
    }
    let (f, g) = ([1, 4, 1], [1, 4, 1]);   // x^2 + 4xy + y^2, read on each chart
    let diff = laurent(&f, &g, 2);
    println!("x^2 + 4xy + y^2 over x^2 is 1 + 4t + t^2, over y^2 is s^2 + 4s + 1; f - t^2 g(1/t) = {}",
             if diff.is_empty() { "0".to_string() } else { format!("{:?}", diff) });
    println!("wrong shift S(d)_n = S_(n-d): degree-0 part of S(-2) has {} monomials, not {}", monomials(-2), monomials(2));
    let (pt, l) = ((1i64, 2i64), [2i64, -1]);   // the point P = (1 : 2), and the line 2x - y through it: coefficients of x and y
    let at_p = |c: &[i64]| -> i64 { c.iter().enumerate().map(|(i, &a)| a * pt.0.pow((c.len() - 1 - i) as u32) * pt.1.pow(i as u32)).sum() };
    let mult = |n: usize| -> Vec<Vec<i64>> { (0..n).map(|i| (0..=n).map(|j| (0..2).filter(|&k| i + k == j).map(|k| l[k]).sum()).collect()).collect() };
    let ideal_dims: Vec<usize> = (0..6).map(|n| if n == 0 { 0 } else { rank(&mult(n)) }).collect();
    let vanish: Vec<usize> = (0..6usize).map(|n| n + 1 - rank(&[(0..=n).map(|i| pt.0.pow((n - i) as u32) * pt.1.pow(i as u32)).collect()])).collect();
    let on_p = (1..6).all(|n| mult(n).iter().all(|row| at_p(row) == 0));   // put P back into every multiple of the line
    println!("2x - y at P: {}; its multiples in degrees 1 to 5 vanish at P: {}", at_p(&l), if on_p { "yes" } else { "no" });
    let shifted: Vec<usize> = (0..6).map(|n| monomials(n - 1)).collect();
    println!("dimension of (2x - y) in degrees 0 to 5: {:?}; of S(-1): {:?}", ideal_dims, shifted);
    println!("degree-n forms vanishing at P, n = 0 to 5: {:?}", vanish);
    let f3: Vec<usize> = (0..4u32).map(|n| (0..3i64.pow(n + 1)).filter(|i| at_p(&(0..=n).map(|k| i / 3i64.pow(k) % 3).collect::<Vec<_>>()) % 3 == 0).count()).collect();
    println!("over F_3, forms of degree 0 to 3 vanishing at (1 : 2): {:?}", f3);
    let local = laurent(&l, &[l[1], l[0]], 1).is_empty();   // the line over x is 2 - t, over y is 2s - 1; they differ by the factor t
    println!("local generators: 2 - t on t-chart, 2s - 1 on s-chart; 2 - t = t * (2/t - 1): {}, so a(t) = t^-1 b(1/t), the rule for d = -1",
             if local { "yes" } else { "no" });
    println!("global sections: ideal sheaf {}, O(-1) {}, O(1) {}", vanish[0], counts[1].1, counts[3].1);
    println!("mistake, generic stalk read as M: {} elements, against {}", N, gen.0);
    let xs: Vec<i64> = (0..6).map(|i| 70 + 90 * i).collect();
    let sizes: Vec<i64> = stalk.iter().map(|s| s.0).collect();
    println!("figure, schematic Spec Z: dots at x = {}; stalk sizes {}; generic {}", join(&xs), join(&sizes), gen.0);
    assert!(stalk.iter().all(|&(c, k, q)| c == k && k == q) && gen == (1, 1));   // three roads to every stalk
    assert!((sec[&2], sec[&3], sec[&6], sec[&1]) == (3, 2, 1, 6) && glue.len() == 6 && sec[&2] * sec[&3] == N && (m5 % 3, m5 % 2) == (2, 1));
    assert!(dims == vec![1, 1, 0, 0, 0, 0] && gdim == 0);                        // fibre dimension jumps
    assert!(counts.iter().all(|&(_, m, r, c)| m == r && c == 3usize.pow(r as u32)));  // monomials = rank = F_3 count
    assert!(counts.iter().map(|c| c.1).collect::<Vec<_>>() == vec![0, 0, 1, 2, 3] && diff.is_empty());
    assert!(at_p(&l) == 0 && on_p && local);                                     // P lies on the line; its local generators glue
    assert!(ideal_dims == vanish && vanish == shifted && f3 == (0..4u32).map(|n| 3usize.pow(n)).collect::<Vec<_>>());
    println!("ALL CHECKS PASS");
}
