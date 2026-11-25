// Boolean functions: decision trees, Fourier coefficients and Huang's sensitivity theorem -- the same
// check as boolean_functions_fourier_and_sensitivity_check.py, in Rust.  Standard library only, no crates.
// An input is a bit mask: bit i set means voter i+1 says yes (+1), clear means no (-1).
type F = Vec<i64>;
fn pc(x: usize) -> u32 { x.count_ones() }
fn show(x: usize, n: usize) -> String { (0..n).map(|i| if x >> i & 1 == 1 { '+' } else { '-' }).collect() }
fn table(n: usize, rule: &dyn Fn(&[i64]) -> i64) -> F {
    (0..1usize << n).map(|x| rule(&(0..n).map(|i| if x >> i & 1 == 1 { 1 } else { -1 }).collect::<Vec<_>>())).collect()
}
fn fourier(f: &F) -> F { // 2^n times each coefficient, by fast butterflies
    let (mut v, mut h) = (f.clone(), 1);
    while h < v.len() {
        for x in (0..v.len()).filter(|x| x & h == 0) { let (a, b) = (v[x], v[x | h]); v[x] = a + b; v[x | h] = b - a; }
        h *= 2;
    }
    v
}
fn fourier_slow(f: &F, n: usize) -> F { // averaging f against chi_S directly
    (0..1usize << n).map(|s| (0..1usize << n).map(|x| f[x] * if pc(s & !x) % 2 == 1 { -1 } else { 1 }).sum()).collect()
}
fn degree(f: &F) -> u32 { fourier(f).iter().enumerate().filter(|(_, c)| **c != 0).map(|(s, _)| pc(s)).max().unwrap() }
fn sens(f: &F, n: usize, x: usize) -> usize { (0..n).filter(|i| f[x] != f[x ^ 1 << i]).count() }
fn bsens(f: &F, n: usize, x: usize, used: usize, last: usize) -> usize { // most disjoint flipping blocks
    (last + 1..1 << n).filter(|b| b & used == 0 && f[x ^ b] != f[x]).map(|b| 1 + bsens(f, n, x, used | b, b)).max().unwrap_or(0)
}
fn cert_set(f: &F, n: usize, x: usize) -> usize { // lowest set of fewest votes that fixes the answer
    (0..1usize << n).filter(|s| (0..1usize << n).all(|y| (y ^ x) & s != 0 || f[y] == f[x])).min_by_key(|s| (pc(*s), *s)).unwrap()
}
fn depth(f: &F, n: usize, mask: usize, val: usize) -> usize { // fewest questions, worst case, best tree
    let pts: Vec<i64> = (0..1usize << n).filter(|y| y & mask == val).map(|y| f[y]).collect();
    if pts.iter().min() == pts.iter().max() { return 0; }
    (0..n).filter(|i| mask >> i & 1 == 0).map(|i| 1 + depth(f, n, mask | 1 << i, val).max(depth(f, n, mask | 1 << i, val | 1 << i))).min().unwrap()
}
fn measures(f: &F, n: usize) -> Vec<usize> {
    let all = |m: &dyn Fn(usize) -> usize| (0..1usize << n).map(m).max().unwrap();
    vec![all(&|x| sens(f, n, x)), all(&|x| bsens(f, n, x, 0, 0)), all(&|x| pc(cert_set(f, n, x)) as usize), depth(f, n, 0, 0), degree(f) as usize]
}
fn infl(f: &F, n: usize) -> (Vec<f64>, Vec<f64>) { // flipping, and from the coefficients
    let c = fourier(f);
    ((0..n).map(|i| (0..1usize << n).filter(|x| f[*x] != f[x ^ 1 << i]).count() as f64 / (1 << n) as f64).collect(),
     (0..n).map(|i| (0..1usize << n).filter(|s| s >> i & 1 == 1).map(|s| c[s] * c[s]).sum::<i64>() as f64 / (1 << 2 * n) as f64).collect())
}
fn fl(xs: &[f64]) -> String { format!("[{}]", xs.iter().map(|v| format!("{:.4}", v)).collect::<Vec<_>>().join(", ")) }
fn ilist<T: std::fmt::Display>(xs: &[T]) -> String { format!("[{}]", xs.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(", ")) }
fn slist(xs: &[usize]) -> String { format!("[{}]", xs.iter().map(|x| format!("'{}'", show(*x, 3))).collect::<Vec<_>>().join(", ")) }
fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn huang(n: usize) -> Vec<Vec<i64>> { // A_1 = [[0,1],[1,0]];  A_n = [[A, I], [I, -A]]
    if n == 0 { return vec![vec![0]]; }
    let a = huang(n - 1); let m = a.len();
    let id = |r: usize| (0..m).map(move |c| (r == c) as i64);
    (0..m).map(|r| a[r].iter().cloned().chain(id(r)).collect())
        .chain((0..m).map(|r| id(r).chain(a[r].iter().map(|v| -v)).collect())).collect()
}
fn by_formula(n: usize) -> Vec<Vec<i64>> { // edge x -- x with vote i changed: -1 per yes vote above i
    (0..1usize << n).map(|x| (0..1usize << n).map(|y| if pc(x ^ y) != 1 { 0 } else if pc(x >> (64 - (x ^ y).leading_zeros())) % 2 == 1 { -1 } else { 1 }).collect()).collect()
}
fn mul(a: &[Vec<i64>], b: &[Vec<i64>]) -> Vec<Vec<i64>> { (0..a.len()).map(|r| (0..b.len()).map(|c| (0..b.len()).map(|k| a[r][k] * b[k][c]).sum()).collect()).collect() }
fn md(h: &[usize], n: usize) -> usize { h.iter().map(|x| (0..n).filter(|i| h.contains(&(x ^ 1 << i))).count()).max().unwrap() }
fn subsets(m: usize, k: u32) -> Vec<Vec<usize>> { // all k-element subsets of 0..m
    (0..1usize << m).filter(|s| pc(*s) == k).map(|s| (0..m).filter(|i| s >> i & 1 == 1).collect()).collect()
}
fn null_vector(mut m: Vec<Vec<f64>>) -> Vec<f64> { // one nonzero solution of M c = 0, by elimination
    let (mut piv, mut r, w) = (vec![], 0, m[0].len());
    for col in 0..w {
        let mut p = r; for i in r..m.len() { if m[i][col].abs() > m[p][col].abs() { p = i; } }
        if m[p][col].abs() < 1e-9 { continue; }
        m.swap(r, p);
        let pv = m[r][col]; m[r] = m[r].iter().map(|v| v / pv).collect();
        for i in 0..m.len() { if i != r { let f = m[i][col]; m[i] = (0..w).map(|k| m[i][k] - f * m[r][k]).collect(); } }
        piv.push(col); r += 1;
        if r == m.len() { break; }
    }
    let free = (0..w).find(|c| !piv.contains(c)).unwrap();
    let mut c = vec![0.0; w]; c[free] = 1.0;
    for (i, col) in piv.iter().enumerate() { c[*col] = -m[i][free]; }
    c
}
fn sci(x: f64) -> String { let s = format!("{:.1e}", x); let (a, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap(); format!("{}e{}{:02}", a, if e < 0 { '-' } else { '+' }, e.abs()) }
fn main() {
    let maj = table(3, &|v| if v.iter().sum::<i64>() > 0 { 1 } else { -1 });
    println!("Majority of 3 supervisors (+ yes, - no); voter 1 first");
    for x in 0..8 {
        let s = cert_set(&maj, 3, x);
        println!("  {} -> {}  sensitive votes {}  certificate: voters {}", show(x, 3), if maj[x] > 0 { '+' } else { '-' },
                 sens(&maj, 3, x), ilist(&(0..3).filter(|i| s >> i & 1 == 1).map(|i| i + 1).collect::<Vec<_>>()));
    }
    let (c, cs) = (fourier(&maj), fourier_slow(&maj, 3));
    println!("  coefficients x 8, sets {{}} {{1}} {{2}} {{1,2}} {{3}} {{1,3}} {{2,3}} {{1,2,3}}: {}", ilist(&c));
    let m = measures(&maj, 3);
    println!("  s {}  bs {}  C {}  D {}  deg {}", m[0], m[1], m[2], m[3], m[4]);
    let reads: Vec<usize> = (0..8).map(|x| if x & 1 == x >> 1 & 1 { 2 } else { 3 }).collect();
    println!("  tree 'ask 1, ask 2, ask 3 only on a split': worst {} questions, average {:.4}",
             reads.iter().max().unwrap(), reads.iter().sum::<usize>() as f64 / 8.0);
    let (a, b) = infl(&maj, 3);
    println!("  influence by flipping {}; from coefficients {}; total {:.4}", fl(&a), fl(&b), a.iter().sum::<f64>());
    let w: Vec<f64> = (0..4).map(|d| (0..8).filter(|s| pc(*s) == d).map(|s| c[s] * c[s]).sum::<i64>() as f64 / 64.0).collect();
    println!("  weights by degree {}; total influence = 1 x {:.4} + 3 x {:.4} = {:.4}", fl(&w), w[1], w[3], w[1] + 3.0 * w[3]);
    let orf = table(4, &|v| if v.iter().max().unwrap() > &0 { 1 } else { -1 });
    let (mo, (ao, bo), co) = (measures(&orf, 4), infl(&orf, 4), fourier(&orf));
    println!("OR of 4 relief staff: the gap is covered if anyone says yes");
    let at = (0..16).fold(0, |best, x| if sens(&orf, 4, x) > sens(&orf, 4, best) { x } else { best });
    println!("  s {} (at {})  bs {}  C {}  D {}  deg {}", mo[0], show(at, 4), mo[1], mo[2], mo[3], mo[4]);
    println!("  coefficients: empty set {:.4}, all four {:.4}; influence each {:.4} ({:.4} from coefficients); average sensitivity {:.4}",
             co[0] as f64 / 16.0, co[15] as f64 / 16.0, ao[0], bo[0], (0..16).map(|x| sens(&orf, 4, x)).sum::<usize>() as f64 / 16.0);
    let (mut ok3, mut gap) = (true, [0, 0]);
    for k in 0..256usize { // every Boolean function of 3 votes
        let f: F = (0..8).map(|x| 1 - 2 * (k >> x & 1) as i64).collect();
        if f.iter().min() == f.iter().max() { continue; }
        let v = measures(&f, 3); let (s, bs, cc, d, dg) = (v[0], v[1], v[2], v[3], v[4]);
        ok3 &= s <= bs && bs <= cc && cc <= d && dg <= d && dg <= s * s && bs <= 2 * dg * dg;
        gap[0] += (s < bs) as usize; gap[1] += (cc < d) as usize;
    }
    println!("all 254 non-constant functions of 3 votes: s <= bs <= C <= D, deg <= D, deg <= s^2, bs <= 2 deg^2: {}", py(ok3));
    println!("  functions with s < bs: {}; with C < D: {}", gap[0], gap[1]);
    let (mut ok4, mut tight) = (true, 0);
    for k in 1..65535usize { // every non-constant function of 4 votes
        let f: F = (0..16).map(|x| 1 - 2 * (k >> x & 1) as i64).collect();
        let (s, d) = ((0..16).map(|x| sens(&f, 4, x)).max().unwrap() as u32, degree(&f));
        ok4 &= d <= s * s; tight += (d == 4 && s == 2) as usize;
    }
    println!("all 65534 non-constant functions of 4 votes: deg <= s^2 (Huang): {}; degree 4 with s only 2: {}", py(ok4), tight);
    let am = huang(3);
    println!("Huang's signed matrix for 3 votes, rows and columns in mask order 0..7:");
    for r in &am { println!("  {}", r.iter().map(|v| format!("{:>2}", v)).collect::<Vec<_>>().join(" ")); }
    let sq = (1..7).all(|n| mul(&huang(n), &huang(n)) == (0..1 << n).map(|r| (0..1 << n).map(|c| n as i64 * (r == c) as i64).collect()).collect::<Vec<Vec<i64>>>());
    let same = (1..7).all(|n| huang(n) == by_formula(n));
    println!("  A^2 = nI for n = 1..6: {}; recursion = sign formula: {}; trace {}", py(sq), py(same), (0..8).map(|i| am[i][i]).sum::<i64>());
    let mins: Vec<usize> = [4, 5].iter().map(|k| subsets(8, *k).iter().map(|h| md(h, 3)).min().unwrap()).collect();
    let min9 = subsets(16, 9).iter().map(|h| md(h, 4)).min().unwrap();
    let r3 = 3f64.sqrt();
    println!("any 5 of 8 corners: fewest chosen neighbours at the busiest corner {} (sqrt 3 = {:.4}); 4 corners: {}; any 9 of 16: {}", mins[1], r3, mins[0], min9);
    let hs = [1usize, 2, 3, 4, 5];
    let bm: Vec<Vec<f64>> = (0..8).map(|r| (0..8).map(|c| am[r][c] as f64 + if r == c { r3 } else { 0.0 }).collect()).collect();
    let cv = null_vector((0..8).filter(|k| !hs.contains(k)).map(|k| (0..4).map(|j| bm[k][j]).collect()).collect());
    let v0: Vec<f64> = (0..8).map(|k| (0..4).fold(0.0, |s, j| s + cv[j] * bm[k][j])).collect();
    let top = (0..8).fold(0, |t, k| if v0[k].abs() > v0[t].abs() { k } else { t });
    let v: Vec<f64> = v0.iter().map(|x| if x.abs() > 1e-9 { x / v0[top] + 0.0 } else { 0.0 }).collect();
    let res = (0..8).map(|k| ((0..8).fold(0.0, |s, j| s + am[k][j] as f64 * v[j]) - r3 * v[k]).abs()).fold(0.0, f64::max);
    let nb: Vec<usize> = hs.iter().cloned().filter(|x| pc(x ^ top) == 1).collect();
    println!("chosen 5 corners {}; vector with A v = sqrt3 v, zero off them:", slist(&hs));
    println!("  v = {}  (largest error {})", (0..8).map(|k| format!("{}:{:.4}", show(k, 3), v[k])).collect::<Vec<_>>().join(" "), sci(res));
    println!("  biggest entry at {}: sqrt3 x 1 = |{}| <= {} chosen neighbours", show(top, 3),
             nb.iter().map(|y| format!("({})({:.4})", am[top][*y], v[*y])).collect::<Vec<_>>().join(" + "), nb.len());
    let g: Vec<i64> = (0..8).map(|x| maj[x] * if pc(7 & !x) % 2 == 1 { -1 } else { 1 }).collect();
    let hg: Vec<usize> = (0..8).filter(|x| g[*x] == -1).collect();
    println!("Majority times the triple product: average {:.4}; it is -1 on {} corners {}", g.iter().sum::<i64>() as f64 / 8.0, hg.len(), slist(&hg));
    println!("  each has {} neighbours inside, where Majority differs: sensitivity {}", md(&hg, 3), hg.iter().map(|x| sens(&maj, 3, *x)).min().unwrap());
    let u: Vec<Vec<i64>> = (0..8).map(|x| (0..8).map(|y| (pc(x ^ y) == 1) as i64).collect()).collect();
    let eig: Vec<i64> = (0..8).map(|s| 3 - 2 * pc(s) as i64).collect();
    let chi = |s: usize, x: usize| if pc(s & x) % 2 == 1 { -1 } else { 1 };
    let ok_u = (0..8).all(|s| (0..8).all(|x| (0..8).map(|y| u[x][y] * chi(s, y)).sum::<i64>() == eig[s] * chi(s, x)));
    let (mut ent, mut es) = (mul(&u, &u).concat(), eig.clone()); ent.sort(); ent.dedup(); es.sort(); es.reverse();
    println!("what breaks:\n  unsigned cube matrix: A^2 entries {}; stretch factors {} (checked on all 8 products: {}); only {} is >= sqrt3",
             ilist(&ent), ilist(&es), py(ok_u), eig.iter().filter(|e| **e as f64 > 1.5).count());
    println!("  exactly half, the 4 corners with an even count of yes votes: busiest has {} neighbours inside", md(&[0, 3, 5, 6], 3));
    println!("  Majority: s {} < deg {}, so s >= deg fails; s >= sqrt(deg) = {:.4} holds", m[0], m[4], r3);
    println!("  Majority: certificate {} < depth {}: two agreeing votes prove the answer, but finding them can take 3", m[2], m[3]);
    let p = |x: usize| (80 + 200 * (x & 1) + 90 * (x >> 2 & 1), 330 - 200 * (x >> 1 & 1) - 70 * (x >> 2 & 1));
    let neg: Vec<String> = (0..8).flat_map(|x| (0..3).map(move |i| (x, i))).filter(|&(x, i)| x >> i & 1 == 0 && am[x][x ^ 1 << i] < 0)
        .map(|(x, i)| format!("{}/{}", show(x, 3), show(x ^ 1 << i, 3))).collect();
    println!("figure, corners {} minus edges {}", (0..8).map(|x| format!("{}=({},{})", show(x, 3), p(x).0, p(x).1)).collect::<Vec<_>>().join(" "), neg.join(" "));
    assert!(c == cs && c == vec![0, 4, 4, 0, 4, 0, 0, -4]);                      // fast = slow = (1/2, 1/2, 1/2, -1/2)
    assert!(m == vec![2, 2, 2, 3, 3] && mo == vec![4, 4, 4, 4, 4] && *reads.iter().max().unwrap() == m[3]); // brute force
    assert!(a == b && a == vec![0.5; 3] && ao == bo && ao == vec![0.125; 4] && a.iter().sum::<f64>() == w[1] + 3.0 * w[3]);
    assert!(ok3 && ok4 && sq && same && ok_u);                                    // chains, Huang, matrix two roads
    assert!(mins == vec![0, 2] && min9 == 2 && res < 1e-9 && nb.len() as f64 >= r3 && v[top] == 1.0);
    assert!((0..8).filter(|k| !hs.contains(k)).all(|k| v[k] == 0.0) && g.iter().sum::<i64>() == c[7]);
    println!("ALL CHECKS PASS");
}
