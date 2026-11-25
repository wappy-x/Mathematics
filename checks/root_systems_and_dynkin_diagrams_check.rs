// Root systems and Dynkin diagrams -- the same check as the Python, in Rust.  No crates.
// Roots are integer vectors (F4 and E8 doubled), so every axiom is tested exactly.  Roads:
// simple roots against the roots grown back from them, the Weyl group by closure against
// its Coxeter count, counts against formulas, the diagram list against a brute-force search.
use std::collections::{BTreeMap, BTreeSet};
type V = Vec<i64>;
fn dot(a: &[i64], b: &[i64]) -> i64 { a.iter().zip(b).map(|(x, y)| x * y).sum() }
fn add(a: &[i64], b: &[i64], k: i64) -> V { a.iter().zip(b).map(|(x, y)| x + k * y).collect() }
fn reflect(b: &[i64], a: &[i64]) -> V { add(b, a, -(2 * dot(b, a) / dot(a, a))) } // s_a(b)
fn e(i: usize, n: usize, s: i64) -> V { (0..n).map(|k| if k == i { s } else { 0 }).collect() }
fn signs(k: usize) -> Vec<V> { (0..1usize << k).map(|m| (0..k).map(|j| if m >> (k - 1 - j) & 1 == 1 { -1 } else { 1 }).collect()).collect() }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn tup(a: &[i64]) -> String { format!("({})", a.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }

fn det(m: &[V]) -> i64 {          // Bareiss elimination, exact; each pivot is a leading minor, never 0 here
    let (mut m, mut prev, n) = (m.to_vec(), 1, m.len());
    for k in 0..n - 1 { for i in k + 1..n { for j in k + 1..n { m[i][j] = (m[i][j] * m[k][k] - m[i][k] * m[k][j]) / prev; } }
        prev = m[k][k]; }
    m[n - 1][n - 1]
}
struct Info { ok: [bool; 4], grown: bool, pos: usize, simple: Vec<V>, c: Vec<V>, short: usize, w: usize }
fn analyse(roots: &[V]) -> Info {    // axioms, positive and simple roots, Cartan matrix
    let (r, n) = (roots.iter().cloned().collect::<BTreeSet<V>>(), roots[0].len());
    let all2 = |f: &dyn Fn(&V, &V) -> bool| roots.iter().all(|a| roots.iter().all(|b| f(a, b)));
    let r2 = all2(&|a, b| dot(a, b).pow(2) != dot(a, a) * dot(b, b) || *b == *a || *b == add(a, a, -2));
    let r4 = all2(&|a, b| 2 * dot(b, a) % dot(a, a) == 0);
    let r3 = r4 && all2(&|a, b| r.contains(&reflect(b, a)));
    let t: V = (0..n).map(|k| 1i64 << (n - 1 - k)).collect();     // a direction square to no root
    let pos: BTreeSet<V> = roots.iter().filter(|a| dot(a, &t) > 0).cloned().collect();
    let mut simple: Vec<V> = pos.iter().filter(|a| !pos.iter().any(|b| pos.contains(&add(a, b, -1)))).cloned().collect();
    simple.sort_by_key(|a| (dot(a, a), a.iter().map(|x| -x).collect::<V>()));
    let (mut grown, mut front): (BTreeSet<V>, BTreeSet<V>) = (simple.iter().cloned().collect(), simple.iter().cloned().collect());
    while !front.is_empty() {                                    // add simple roots while still a root
        front = front.iter().flat_map(|b| simple.iter().map(move |s| add(b, s, 1)))
            .filter(|v| r.contains(v) && !grown.contains(v)).collect();
        grown.extend(front.iter().cloned());
    }
    let c: Vec<V> = simple.iter().map(|a| simple.iter().map(|b| 2 * dot(a, b) / dot(b, b)).collect()).collect();
    let r1 = !r.contains(&e(0, n, 0)) && det(&c) != 0 && grown == pos;
    let mn = roots.iter().map(|b| dot(b, b)).min().unwrap();
    let short = roots.iter().filter(|a| dot(a, a) == mn).count();
    Info { ok: [r1, r2, r3, r4], grown: grown == pos, pos: pos.len(), simple, c, short, w: 0 }
}
fn shape(c: &[V]) -> (Vec<i64>, Vec<usize>) {    // bonds, and arm lengths at a branch dot
    let n = c.len();
    let nb = |i: usize| (0..n).filter(|&j| j != i && c[i][j] != 0).collect::<Vec<usize>>();
    let mut bonds: Vec<i64> = (0..n).flat_map(|i| (i + 1..n).filter(move |&j| c[i][j] != 0).map(move |j| c[i][j] * c[j][i])).collect();
    bonds.sort(); let mut arms = vec![];
    for b in (0..n).filter(|&i| nb(i).len() == 3) {
        for s in nb(b) {
            let (mut prev, mut cur, mut k) = (b, s, 1);
            while nb(cur).len() == 2 { let nx = nb(cur).into_iter().find(|&j| j != prev).unwrap(); prev = cur; cur = nx; k += 1; }
            arms.push(k);
        }
    }
    arms.sort(); (bonds, arms)
}
fn weyl(roots: &[V], simple: &[V]) -> BTreeSet<Vec<usize>> {   // closure of the simple reflections
    let ix: BTreeMap<V, usize> = roots.iter().cloned().zip(0..).collect();
    let gens: Vec<Vec<usize>> = simple.iter().map(|s| roots.iter().map(|b| ix[&reflect(b, s)]).collect()).collect();
    let mut front: BTreeSet<Vec<usize>> = [(0..roots.len()).collect()].into_iter().collect(); let mut seen = front.clone();
    while !front.is_empty() {
        front = front.iter().flat_map(|p| gens.iter().map(move |g| p.iter().map(|&i| g[i]).collect::<Vec<usize>>()))
            .filter(|p| !seen.contains(p)).collect();
        seen.extend(front.iter().cloned());
    }
    seen
}
fn perms(n: usize) -> Vec<Vec<usize>> {          // every ordering of 0..n
    if n == 0 { return vec![vec![]]; }
    perms(n - 1).into_iter().flat_map(|p| (0..n).map(move |k| { let mut q = p.clone(); q.insert(k, n - 1); q })).collect()
}
fn posdef(m: &[Vec<usize>]) -> bool {           // Cholesky on the form with -cos(pi/m) off the diagonal
    let (n, c) = (m.len(), [0.0, 0.5, 2f64.sqrt() / 2.0, 3f64.sqrt() / 2.0]);
    let mut l = vec![vec![0.0f64; n]; n];
    for i in 0..n {
        for j in 0..=i {
            let s = (if i == j { 1.0 } else { -c[m[i][j]] }) - (0..j).map(|k| l[i][k] * l[j][k]).fold(0.0, |x, y| x + y);
            if i == j && s < 1e-9 { return false; }
            l[i][j] = if i == j { s.sqrt() } else { s / l[j][j] };
        }
    }
    true
}

fn main() {
    let a2: Vec<V> = (0..3).flat_map(|i| (0..3).filter(move |&j| j != i).map(move |j| add(&e(i, 3, 1), &e(j, 3, 1), -1))).collect();
    let mut g2 = a2.clone(); for i in 0..3 { for s in [1, -1] { g2.push(e(i, 3, 1).iter().map(|x| s * (3 * x - 1)).collect()); } }
    let pairs = |n: usize, c: i64| -> Vec<V> { let mut o = vec![];
        for i in 0..n { for j in i + 1..n { for su in signs(2) { o.push(add(&e(i, n, c * su[0]), &e(j, n, c * su[1]), 1)); } } } o };
    let axes = |n: usize, c: i64| -> Vec<V> { (0..n).flat_map(|i| [1, -1].into_iter().map(move |s| e(i, n, c * s))).collect() };
    let (b3, c3) = ([pairs(3, 1), axes(3, 1)].concat(), [pairs(3, 1), axes(3, 2)].concat());
    let e8 = [pairs(8, 2), signs(8).into_iter().filter(|v| v.iter().filter(|&&x| x == -1).count() % 2 == 0).collect()].concat();
    let e7: Vec<V> = e8.iter().filter(|a| dot(a, &[1; 8]) == 0).cloned().collect();
    let e6: Vec<V> = e7.iter().filter(|a| dot(a, &[-2, -2, 0, 0, 0, 0, 0, 0]) == 0).cloned().collect();
    let systems = [("A2", a2.clone()), ("G2", g2.clone()), ("B3", b3.clone()), ("C3", c3.clone()), ("D4", pairs(4, 1)),
                   ("F4", [pairs(4, 2), axes(4, 2), signs(4)].concat()), ("E6", e6), ("E7", e7), ("E8", e8.clone())];
    let mut info: Vec<Info> = systems.iter().map(|(_, r)| analyse(r)).collect();
    for (k, (name, roots)) in systems[..2].iter().enumerate() {
        let d = &info[k]; let w = weyl(roots, &d.simple); let i = roots.iter().position(|a| *a == d.simple[0]).unwrap();
        let mut ang = BTreeSet::new(); let mut four = BTreeSet::new();
        for a in roots { for b in roots {
            let n2 = dot(a, a) * dot(b, b);
            if a != b { ang.insert((dot(a, b) as f64 / (n2 as f64).sqrt()).acos().to_degrees().round() as i64); }
            four.insert(4 * dot(a, b).pow(2) / n2);
        } }
        let m = match d.c[0][1] * d.c[1][0] { 0 => 2, 1 => 3, 2 => 4, _ => 6 };
        let (orbit, stab) = (w.iter().map(|p| p[i]).collect::<BTreeSet<usize>>().len(), w.iter().filter(|p| p[i] == i).count());
        println!("{}: {} roots, {} positive, simple roots {} and {}", name, roots.len(), d.pos, tup(&d.simple[0]), tup(&d.simple[1]));
        println!("{} axioms R1 R2 R3 R4: {}; positive roots grown from the simple two: {}", name, d.ok.iter().map(|&x| yn(x)).collect::<Vec<_>>().join(" "), yn(d.grown));
        println!("{} angles between roots (degrees): {:?}; 4cos^2 values: {:?}", name, ang.iter().collect::<Vec<_>>(), four.iter().collect::<Vec<_>>());
        println!("{} Cartan matrix {:?}, determinant {}, bonds {:?}", name, d.c, det(&d.c), shape(&d.c).0);
        println!("{} Weyl group by closure: {}; Coxeter count 2m with m = {}: {}; orbit of alpha1 {} x stabiliser {} = {}", name, w.len(), m, 2 * m, orbit, stab, orbit * stab);
        assert!(w.len() == 2 * m && 2 * m == orbit * stab && d.ok.iter().all(|&x| x) && d.grown);
    }
    println!("A2 dimension: {} roots + rank 2 = {}; n(n + 2) at n = 2: {}; 3! = {}", a2.len(), a2.len() + 2, 2 * 4, 3 * 2 * 1);
    println!("type rank roots positive short dimension det bonds arms Weyl");
    for (k, (name, roots)) in systems.iter().enumerate() {
        let d = &mut info[k]; let r = d.simple.len(); let (b, a) = shape(&d.c);
        d.w = if roots.len() <= 48 { weyl(roots, &d.simple).len() } else { 0 };
        println!("{} {} {} {} {} {} {} {:?} {:?} {}", name, r, roots.len(), d.pos, d.short, roots.len() + r, det(&d.c), b, a, if d.w > 0 { d.w.to_string() } else { "-".to_string() });
        assert!(d.ok.iter().all(|&x| x) && d.grown && b.len() == r - 1);   // axioms hold; the diagram is a tree
    }
    assert!(info[0].c == vec![vec![2, -1], vec![-1, 2]] && info[1].c == vec![vec![2, -1], vec![-3, 2]]);
    assert!(a2.len() + 2 == 2 * (2 + 2) && info[0].w == 3 * 2 * 1);
    assert!([b3.len() + 3, c3.len() + 3, pairs(4, 1).len() + 4] == [3 * 7, 3 * 7, 4 * 7]); // n(2n+1), n(2n+1), n(2n-1)
    assert!(info[2].w == 8 * 6 && info[4].w == 8 * 24);                                     // signed shuffles
    println!("E8 roots by counting: 4 x C(8,2) + 2^7 = {} + {} = {}; dimension {}", 4 * 28, 1 << 7, 4 * 28 + (1 << 7), e8.len() + 8);
    assert!(e8.len() == 4 * (8 * 7 / 2) + (1 << 7) && shape(&info[8].c).1 == vec![1, 2, 4]);
    let (mut reps, mut brute): (Vec<Vec<Vec<usize>>>, Vec<usize>) = (vec![vec![vec![0]]], vec![1]);
    for n in 2..10usize {                         // grow every connected diagram one dot at a time
        let ps = perms(n);
        let mut found: BTreeMap<Vec<usize>, Vec<Vec<usize>>> = BTreeMap::new();
        for m in &reps {
            for code in 1..1usize << (2 * (n - 1)) {
                let ext: Vec<usize> = (0..n - 1).map(|i| code >> (2 * (n - 2 - i)) & 3).collect();
                let mut nm: Vec<Vec<usize>> = m.iter().zip(&ext).map(|(row, &x)| [row.clone(), vec![x]].concat()).collect(); nm.push([ext.clone(), vec![0]].concat());
                if posdef(&nm) {
                    let key = ps.iter().map(|p| (0..n).flat_map(|j| (0..j).map(move |i| (i, j))).map(|(i, j)| nm[p[i]][p[j]]).collect::<Vec<usize>>()).min().unwrap();
                    found.entry(key).or_insert(nm);
                }
            }
        }
        reps = found.into_values().collect(); brute.push(reps.len());
    }
    let listed: Vec<usize> = (1..10usize).map(|n| 1 + (n >= 2) as usize + (n >= 4) as usize + [6, 7, 8].contains(&n) as usize + (n == 4) as usize + (n == 2) as usize).collect();
    println!("connected positive-definite diagrams, ranks 1 to 9, brute force: {:?}", brute);
    println!("the same ranks, counted from the list A, B = C, D, E, F4, G2:   {:?}", listed);
    assert!(brute == listed);
    let pi = std::f64::consts::PI; let ten: Vec<[f64; 2]> = (0..10).map(|k| [(k as f64 * pi / 5.0).cos(), (k as f64 * pi / 5.0).sin()]).collect();
    let fd = |a: &[f64; 2], b: &[f64; 2]| a[0] * b[0] + a[1] * b[1];
    let close = ten.iter().all(|a| ten.iter().all(|v| ten.iter().any(|r|
        (r[0] - v[0] + 2.0 * fd(v, a) * a[0]).abs() + (r[1] - v[1] + 2.0 * fd(v, a) * a[1]).abs() < 1e-9)));
    let gold = 2.0 * fd(&ten[1], &ten[0]);
    println!("mistake 1, ten roots 36 degrees apart: reflections close up {}, but 2cos(36 deg) = {:.12}, not whole", yn(close), gold);
    assert!(close && (gold - (1.0 + 5f64.sqrt()) / 2.0).abs() < 1e-12 && (gold - gold.round()).abs() > 0.1);
    let tri: Vec<V> = vec![vec![2, -1, -1], vec![-1, 2, -1], vec![-1, -1, 2]];
    let e9: Vec<V> = (0..9i64).map(|i| (0..9i64).map(|j| if i == j { 2 } else if ((i - j).abs() == 1 && i.max(j) < 8) || (i.min(j), i.max(j)) == (2, 8) { -1 } else { 0 }).collect()).collect();
    println!("mistake 2, three dots in a triangle: Cartan determinant {}; E8's long arm made one dot longer: {}", det(&tri), det(&e9));
    assert!(det(&tri) == 0 && det(&e9) == 0 && !posdef(&[vec![0, 1, 1], vec![1, 0, 1], vec![1, 1, 0]]));
    let gram = |p: &[usize]| -> Vec<V> { (0..6).map(|i| (0..6).map(|j| dot(&a2[p[i]], &a2[p[j]])).collect()).collect() };
    let sym = perms(6).iter().filter(|p| gram(p) == gram(&[0, 1, 2, 3, 4, 5])).count();
    println!("mistake 3, every symmetry of the hexagon: {}, but the Weyl group has {}", sym, info[0].w);
    println!("mistake 4, dimension of sl(3) as roots only: {}, not {}", a2.len(), a2.len() + 2);
    assert!(sym == 2 * info[0].w);
    let xy = |a: &V| format!("({:.3}, {:.3})", (a[0] - a[1]) as f64 / 2f64.sqrt(), (a[0] + a[1] - 2 * a[2]) as f64 / 6f64.sqrt());
    println!("figure, A2 roots: {}", a2.iter().map(xy).collect::<Vec<_>>().join(" "));
    println!("figure, G2 long roots: {}", g2[6..].iter().map(xy).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
