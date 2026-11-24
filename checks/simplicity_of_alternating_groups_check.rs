// A_n is simple for n at least 5 -- the same check as the Python, in Rust.  No
// crates.  A shuffle of n places is a list p: place i+1 goes to place p[i]+1.
// Road one adds up class sizes; road two builds each normal subgroup by brute force.
use std::collections::BTreeSet;
type P = Vec<usize>; type S = BTreeSet<P>;
fn mul(p: &P, q: &P) -> P { q.iter().map(|&i| p[i]).collect() }   // q first, then p
fn inv(p: &P) -> P { let mut o = vec![0; p.len()]; for (i, &x) in p.iter().enumerate() { o[x] = i } o }
fn conj(g: &P, x: &P) -> P { mul(&mul(g, x), &inv(g)) }          // undo g, do x, redo g
fn comm(t: &P, x: &P) -> P { mul(&conj(t, x), &inv(x)) }         // Step 3: t x t^-1 x^-1
fn moved(p: &P) -> usize { (0..p.len()).filter(|&i| p[i] != i).count() }
fn cyc(n: usize, c: &[usize]) -> P { let mut p: P = (0..n).collect(); for k in 0..c.len() { p[c[k] - 1] = c[(k + 1) % c.len()] - 1 } p }
fn orbit(p: &P, i: usize) -> Vec<usize> { let mut c = vec![i]; while p[c[c.len() - 1]] != i { c.push(p[c[c.len() - 1]]) } c }
fn show(p: &P) -> String {                                        // cycle notation from 1
    let out: String = (0..p.len()).filter(|&i| p[i] != i && orbit(p, i).iter().min() == Some(&i))
        .map(|i| format!("({})", orbit(p, i).iter().map(|x| (x + 1).to_string()).collect::<Vec<_>>().join(" "))).collect();
    if out.is_empty() { "e".to_string() } else { out }
}
fn shuffles(n: usize) -> Vec<P> {                                 // all n! shuffles
    if n == 0 { return vec![vec![]] }
    shuffles(n - 1).into_iter().flat_map(|s| (0..n).map(move |j| { let mut t = s.clone(); t.insert(j, n - 1); t })).collect()
}
fn even(p: &P) -> bool { (0..p.len()).map(|i| (0..i).filter(|&j| p[j] > p[i]).count()).sum::<usize>() % 2 == 0 }
fn class_of(x: &P, g: &[P]) -> S { g.iter().map(|h| conj(h, x)).collect() }
fn classes(g: &[P]) -> Vec<S> {                                   // look-alike classes
    let (mut out, mut seen): (Vec<S>, S) = (vec![], S::new());
    for x in g { if !seen.contains(x) { let c = class_of(x, g); seen.extend(c.iter().cloned()); out.push(c) } }
    out.sort_by_key(|c| c.len()); out
}
fn build(gens: &[P], n: usize) -> S {                             // every product of gens
    let (mut grp, mut todo): (S, Vec<P>) = ([(0..n).collect()].into(), vec![(0..n).collect()]);
    while let Some(x) = todo.pop() { for g in gens { let y = mul(g, &x); if grp.insert(y.clone()) { todo.push(y) } } }
    grp
}
fn unions(sizes: &[usize], order: usize) -> (Vec<usize>, Vec<usize>) { // sums; those dividing
    let tot: BTreeSet<usize> = (0..1usize << (sizes.len() - 1)).map(|m| sizes[0] + (1..sizes.len()).filter(|i| m >> (i - 1) & 1 == 1).map(|i| sizes[i]).sum::<usize>()).collect();
    (tot.iter().cloned().filter(|&t| t > 0).collect(), tot.iter().cloned().filter(|&t| t > 0 && order % t == 0).collect())
}
fn main() {
    let (pairs, mut res): ([(&[usize], &[usize]); 2], Vec<_>) = ([(&[1, 2, 3, 4, 5], &[1, 2, 4]), (&[1, 2, 3, 4, 5, 6, 7], &[1, 2, 4])], vec![]);
    for n in [4usize, 5, 6] {
        let g: Vec<P> = shuffles(n).into_iter().filter(|p| even(p)).collect(); let cl = classes(&g); let sz: Vec<usize> = cl.iter().map(|c| c.len()).collect();
        let (normal, div): (Vec<usize>, _) = (cl.iter().map(|c| build(&c.iter().cloned().collect::<Vec<P>>(), n).len()).collect(), unions(&sz, g.len()).1);
        println!("A_{}: {} members; class sizes {:?}; unions of classes dividing {}: {:?}", n, g.len(), sz, g.len(), div);
        println!("A_{}: normal subgroup built from one class at a time, sizes {:?}", n, normal); res.push((g, sz, div, normal));
    }
    let (a4, a5, s5, s) = (&res[0].0, &res[1].0, shuffles(5), |c: &[usize]| cyc(5, c));
    println!("A_5 unions that hold do-nothing: {:?}", unions(&res[1].1, 60).0);
    let no_e: Vec<usize> = [0].into_iter().chain(res[1].1[1..].iter().cloned()).collect();
    println!("mistake 1, do-nothing left out: unions dividing 60 are {:?}", unions(&no_e, 60).1);
    let threes: Vec<P> = a5.iter().filter(|p| moved(p) == 3).cloned().collect(); let built = build(&threes, 5);
    println!("A_5 has {} 3-cycles; the subgroup they build has {} members", threes.len(), built.len());
    let swaps = mul(&s(&[1, 2]), &s(&[1, 3])) == s(&[1, 3, 2]) && mul(&s(&[1, 2]), &s(&[3, 4])) == mul(&s(&[1, 3, 2]), &s(&[1, 3, 4]));
    println!("(1 2)(1 3) = (1 3 2) and (1 2)(3 4) = (1 3 2)(1 3 4): {}", if swaps { "yes" } else { "no" });
    let (k5, k4) = (class_of(&s(&[1, 2, 3]), a5).len(), class_of(&cyc(4, &[1, 2, 3]), a4).len());
    println!("class of (1 2 3): {} members in A_5; {} of the 8 3-cycles in A_4", k5, k4);
    let look: Vec<[usize; 3]> = [s(&[1, 2, 3]), mul(&s(&[1, 2]), &s(&[3, 4])), s(&[1, 2, 3, 4, 5])].iter().map(|x| { let c: Vec<&P> = s5.iter()
        .filter(|g| mul(g, x) == mul(x, g)).collect(); [class_of(x, &s5).len(), c.len(), c.iter().filter(|g| !even(g)).count()] }).collect();
    let col = |i: usize| look.iter().map(|l| l[i]).collect::<Vec<usize>>(); let (shape, cent, odds) = (col(0), col(1), col(2));
    println!("in all {} shuffles: (1 2 3), (1 2)(3 4), (1 2 3 4 5) have {:?} look-alikes; {:?} commute with each, {:?} of them odd", s5.len(), shape, cent, odds);
    for (sig, tau) in pairs {
        let (n, sg, t) = (sig.len(), cyc(sig.len(), sig), cyc(sig.len(), tau)); let rho = comm(&t, &sg);
        println!("sigma {}, tau {}: rho = {}, moving {} of {} places", show(&sg), show(&t), show(&rho), moved(&rho), n);
        assert!(show(&rho) == "(1 2 5 3 4)");                         // traced by hand
    }
    let rhos: Vec<usize> = res[2].0.iter().flat_map(|g| (0..6).filter(move |&a| g[a] != a).flat_map(move |a| (0..6)
        .filter(move |&c| c != a && c != g[a] && c != g[g[a]]).map(move |c| moved(&comm(&cyc(6, &[a + 1, g[a] + 1, c + 1]), g))))).collect();
    let (lo, hi) = (*rhos.iter().min().unwrap(), *rhos.iter().max().unwrap());
    println!("Step 3 on all of A_6, every allowed a and c: {} commutators, each moving {} to {} places", rhos.len(), lo, hi);
    let v = mul(&cyc(4, &[1, 2]), &cyc(4, &[3, 4])); let (r4, vv) = (comm(&cyc(4, &[1, 2, 3]), &v), build(&class_of(&v, a4).into_iter().collect::<Vec<P>>(), 4));
    println!("A_4: sigma {}, tau (1 2 3): rho = {}; the class of sigma builds {} members, {} of them 3-cycles", show(&v), show(&r4), vv.len(), vv.iter().filter(|p| moved(p) == 3).count());
    let h: Vec<P> = a5.iter().filter(|p| p[4] == 4).cloned().collect(); let copies: BTreeSet<S> = a5.iter().map(|g| h.iter().map(|x| conj(g, x)).collect()).collect();
    println!("even shuffles fixing place 5: {}, a subgroup with {} different conjugates", h.len(), copies.len());
    assert!(res[1].1 == vec![1, 12, 12, 15, 20] && res[1].2 == vec![1, 60] && res[2].2 == vec![1, 360] && show(&r4) == "(1 3)(2 4)");
    assert!(res[1].3[1..] == [60; 4] && res[2].3[1..] == [360; 6] && lo > 0 && hi <= 5);   // road two agrees: simple
    assert!(res[0].2 == vec![1, 4, 12] && res[0].3 == vec![1, 4, 12, 12] && vv.len() == 4 && vv.contains(&r4)); // A_4 has its normal 4
    let mut split: Vec<usize> = vec![1]; for (&k, &o) in shape.iter().zip(&odds) { if o == 0 { split.extend([k / 2, k / 2]) } else { split.push(k) } }
    split.sort(); assert!(split == res[1].1 && shape.iter().zip(&cent).all(|(k, c)| k * c == s5.len()));   // halving rule
    assert!(built == a5.iter().cloned().collect::<S>() && k5 == 20 && threes.len() == 20 && k4 == 4 && swaps && copies.len() == 5);
    println!("ALL CHECKS PASS");
}
