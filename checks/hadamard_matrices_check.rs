// Hadamard matrices -- the same check as the Python, in Rust.  No crates.  Sylvester's tables are
// Kronecker products of H2; the determinant is found by expansion, as a Gram-Schmidt volume and by
// brute force over every 4 by 4 table of +-1; the weighing plan is solved two ways; H8 becomes Fano.
type M = Vec<Vec<i64>>;
fn kron(a: &M, b: &M) -> M { a.iter().flat_map(|ra| b.iter().map(move |rb| ra.iter().flat_map(|x| rb.iter().map(move |y| x * y)).collect())).collect() }
fn dot(p: &[i64], q: &[i64]) -> i64 { p.iter().zip(q).map(|(x, y)| x * y).sum() }
fn gram(m: &M) -> M { m.iter().map(|p| m.iter().map(|q| dot(p, q)).collect()).collect() }
fn is_ni(m: &M) -> bool { let n = m.len() as i64; let g = gram(m); (0..m.len()).all(|i| (0..m.len()).all(|j| g[i][j] == n * (i == j) as i64)) }
fn yes(b: bool) -> &'static str { if b { "yes" } else { "NO" } }
fn f4(xs: &[f64]) -> String { xs.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(", ") }
fn det(m: &M) -> i64 {                           // Laplace expansion along the first row, exact
    if m.len() == 1 { return m[0][0]; }
    (0..m.len()).filter(|&j| m[0][j] != 0).map(|j| (1 - 2 * (j as i64 % 2)) * m[0][j]
        * det(&m[1..].iter().map(|r| [&r[..j], &r[j + 1..]].concat()).collect())).sum()
}
fn leftovers(m: &M) -> Vec<f64> {                // Gram-Schmidt: lengths of what is left of each row
    let (mut qs, mut out): (Vec<Vec<f64>>, Vec<f64>) = (vec![], vec![]);
    for row in m {
        let mut u: Vec<f64> = row.iter().map(|&x| x as f64).collect();
        for q in &qs { let d: f64 = u.iter().zip(q).map(|(a, b)| a * b).sum(); u = u.iter().zip(q).map(|(a, b)| a - d * b).collect(); }
        let l = u.iter().map(|a| a * a).sum::<f64>().sqrt(); out.push(l); qs.push(u.iter().map(|a| a / l).collect());
    }
    out
}
fn solve(m: &M, y: &[f64]) -> Vec<f64> {         // Gauss-Jordan elimination (H4 needs no row swaps)
    let n = m.len(); let mut a: Vec<Vec<f64>> = m.iter().zip(y).map(|(r, t)| r.iter().map(|&x| x as f64).chain([*t]).collect()).collect();
    for i in 0..n { for r in (0..n).filter(|&r| r != i) { let f = a[r][i] / a[i][i]; let ai = a[i].clone(); for c in 0..=n { a[r][c] -= f * ai[c]; } } }
    (0..n).map(|i| a[i][n] / a[i][i]).collect()
}
fn tables(n: usize) -> Vec<M> { (0..1u32 << (n * n)).map(|c| (0..n).map(|i| (0..n).map(|j| 1 - 2 * ((c >> (n * i + j)) & 1) as i64).collect()).collect()).collect() }
fn pairs(bl: &Vec<Vec<i64>>) -> Vec<i64> {
    let mut s: Vec<i64> = (1..8).flat_map(|x| (x + 1..8).map(move |y| (x, y))).map(|(x, y)| bl.iter().filter(|b| b.contains(&x) && b.contains(&y)).count() as i64).collect();
    s.sort(); s.dedup(); s
}
fn perms(xs: Vec<i64>) -> Vec<Vec<i64>> {                // every ordering, in dictionary order
    if xs.is_empty() { vec![vec![]] } else { (0..xs.len()).flat_map(|i| { let mut rest = xs.clone(); let x = rest.remove(i); perms(rest).into_iter().map(move |p| [vec![x], p].concat()) }).collect() }
}
fn tup(bl: &Vec<Vec<i64>>) -> String { bl.iter().map(|b| format!("({})", b.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "))).collect::<Vec<_>>().join(", ") }
fn main() {
    let h2: M = vec![vec![1, 1], vec![1, -1]]; let h4 = kron(&h2, &h2); let h8 = kron(&h2, &h4); let h16 = kron(&h2, &h8);
    println!("H4 = H2 (x) H2 = {:?}", h4);
    println!("H H^T = n I: {}", [&h2, &h4, &h8, &h16].iter().map(|h| format!("n = {} {}", h.len(), yes(is_ni(h)))).collect::<Vec<_>>().join(", "));
    let abcd: Vec<usize> = [(1, 1), (1, -1), (-1, 1), (-1, -1)].iter().map(|&(s, t)| (0..8).filter(|&c| h8[1][c] == s && h8[2][c] == t).count()).collect();
    println!("H8 rows 2, 3: columns (+,+) (+,-) (-,+) (-,-) = {:?}, each n/4 = {}", abcd, 8 / 4);
    let cand: Vec<Vec<i64>> = (0..32).map(|c| [vec![1], (0..5).map(|j| 1 - 2 * ((c >> j) & 1)).collect()].concat()).filter(|v: &Vec<i64>| v.iter().sum::<i64>() == 0).collect();
    let ok = |s: u32| (0..10).all(|i| (0..i).all(|j| (s >> i) & (s >> j) & 1 == 0 || dot(&cand[i], &cand[j]) == 0));
    let best = 1 + (0..1u32 << cand.len()).filter(|&s| ok(s)).map(|s| s.count_ones()).max().unwrap();
    println!("n = 6: {} balanced rows, at most {} mutually perpendicular rows, 6 needed", cand.len(), best);
    let all4: Vec<i64> = tables(4).iter().map(|t| det(t).abs()).collect(); let big = *all4.iter().max().unwrap();
    println!("det H4 = {}; det(H4 H4^T) = {} = 16^2; bound 4^(4/2) = {}", det(&h4), det(&gram(&h4)), 4i64.pow(2));
    println!("all {} 4 by 4 tables of +-1: largest |det| {}, reached by {}", all4.len(), big, all4.iter().filter(|&&d| d == big).count());
    let m: M = vec![vec![1, 1, 1, 1], vec![1, 1, 1, -1], vec![1, 1, -1, 1], vec![1, -1, 1, 1]]; let (lh, lm) = (leftovers(&h4), leftovers(&m));
    let pr = |xs: &Vec<f64>| xs[0] * xs[1] * xs[2] * xs[3];
    println!("Gram-Schmidt leftovers: H4 {}, product {:.4}; M {}, product {:.4}; |det M| = {}", f4(&lh), pr(&lh), f4(&lm), pr(&lm), det(&m).abs());
    let w = vec![120i64, 75, 210, 45]; let y: Vec<i64> = h4.iter().map(|r| dot(r, &w)).collect();
    let by_t: Vec<f64> = (0..4).map(|i| (0..4).map(|k| h4[k][i] * y[k]).sum::<i64>() as f64 / 4.0).collect();
    let by_g = solve(&h4, &y.iter().map(|&t| t as f64).collect::<Vec<_>>());
    println!("parcels {:?} g; readings H4 w = {:?} g\nrecovered: H4^T y / 4 = {}; elimination {}", w, y, f4(&by_t), f4(&by_g));
    let var: f64 = (0..4).map(|j| solve(&h4, &(0..4).map(|k| (k == j) as i64 as f64).collect::<Vec<_>>())[0].powi(2)).sum();
    println!("variance factor per parcel {:.4}: scale error 0.4 g becomes {:.4} g", var, 0.4 * var.sqrt());
    let core: M = h8[1..].iter().map(|r| r[1..].to_vec()).collect();
    let pick = |s: i64| -> Vec<Vec<i64>> { core.iter().map(|r| (0..7).filter(|&j| r[j] == s).map(|j| j as i64 + 1).collect()).collect() };
    let (blocks, minus) = (pick(1), pick(-1)); let (lam, lam2) = (pairs(&blocks), pairs(&minus));
    println!("H8 core, +1 places: blocks [{}]; every pair together {:?} times", tup(&blocks), lam);
    let fano: M = vec![vec![1, 2, 4], vec![2, 3, 5], vec![3, 4, 6], vec![4, 5, 7], vec![5, 6, 1], vec![6, 7, 2], vec![7, 1, 3]];
    let norm = |bl: &M| { let mut s: M = bl.iter().map(|b| { let mut b = b.clone(); b.sort(); b }).collect(); s.sort(); s };
    let pi = perms((1..8).collect()).into_iter().find(|p| norm(&blocks.iter().map(|b| b.iter().map(|&x| p[x as usize - 1]).collect()).collect()) == norm(&fano)).unwrap();
    println!("relabel {}: the blocks become the 7 Fano lines", (1..8).map(|x| format!("{}->{}", x, pi[x - 1])).collect::<Vec<_>>().join(" "));
    let back: M = [vec![vec![1; 8]], fano.iter().map(|l| [vec![1], (1..8).map(|x| if l.contains(&x) { 1 } else { -1 }).collect()].concat()).collect()].concat();
    println!("Fano lines -> +1 on the line, -1 off it, border of +1s: H H^T = 8I {}", yes(is_ni(&back)));
    let all3: Vec<i64> = tables(3).iter().map(|t| det(t).abs()).collect(); let jh = kron(&vec![vec![1, 1], vec![1, 1]], &h4);
    println!("mistake 1, n = 3: largest |det| of {} tables {}, bound 3^(3/2) = {:.4}", all3.len(), all3.iter().max().unwrap(), 3f64.powf(1.5));
    println!("mistake 2, [[H4, H4], [H4, H4]]: det {}, H H^T = 8I {}", det(&jh), yes(is_ni(&jh)));
    println!("mistake 3, -1 places: blocks of {}, every pair together {:?} times", minus[0].len(), lam2);
    assert!([&h2, &h4, &h8, &h16].iter().all(|h| is_ni(h)) && abcd == vec![2, 2, 2, 2] && best == 2);
    assert!(det(&h4).pow(2) == det(&gram(&h4)) && det(&gram(&h4)) == 256 && big == 16 && pr(&lh).round() == 16.0 && (pr(&lm) - det(&m).abs() as f64).abs() < 1e-9);
    assert!((0..4).all(|i| (by_t[i] - w[i] as f64).abs() < 1e-9 && (by_g[i] - w[i] as f64).abs() < 1e-9) && (var - 0.25).abs() < 1e-12);
    assert!(lam == vec![1] && is_ni(&back) && *all3.iter().max().unwrap() == 4 && det(&jh) == 0 && lam2 == vec![2]);
    println!("ALL CHECKS PASS");
}
