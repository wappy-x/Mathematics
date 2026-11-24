// Polar decomposition and partial isometries: the check behind the card.
// Standard library only. Real scalars. Square roots, eigenvectors and U are built by hand:
// a Jacobi eigen solver, a 2x2 closed form and the iteration X <- X + (A - X^2)/2.
use std::f64::consts::PI;
type M = Vec<Vec<f64>>;

fn mul(a: &M, b: &M) -> M {
    (0..a.len()).map(|i| (0..b[0].len()).map(|j| (0..b.len()).map(|k| a[i][k] * b[k][j]).sum()).collect()).collect()
}
fn tp(a: &M) -> M { (0..a[0].len()).map(|j| (0..a.len()).map(|i| a[i][j]).collect()).collect() }
fn gap(a: &M, b: &M) -> f64 { a.iter().zip(b).flat_map(|(r, s)| r.iter().zip(s).map(|(x, y)| (x - y).abs())).fold(0.0, f64::max) }
fn eye(n: usize) -> M { (0..n).map(|i| (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect() }
fn f6(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-7 { 0.0 } else { x }) }
fn fm(a: &M) -> String {
    let rows: Vec<String> = a.iter().map(|r| format!("[{}]", r.iter().map(|&x| f6(x)).collect::<Vec<_>>().join(", "))).collect();
    format!("[{}]", rows.join(", "))
}
fn apply(a: &M, x: &[f64]) -> Vec<f64> { a.iter().map(|r| r.iter().zip(x).map(|(p, q)| p * q).sum()).collect() }
fn sci(x: f64) -> String {
    let s = format!("{:.3e}", x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

fn jacobi(a0: &M) -> (Vec<f64>, M) { // eigenvalues and eigenvector columns of a symmetric matrix
    let n = a0.len();
    let (mut a, mut v) = (a0.clone(), eye(n));
    for _ in 0..60 {
        let mut off = 0.0;
        for i in 0..n { for j in 0..n { if i != j { off += a[i][j] * a[i][j]; } } }
        if off < 1e-26 { break; }
        for p in 0..n - 1 {
            for q in p + 1..n {
                if a[p][q] == 0.0 { continue; }
                let th = (a[q][q] - a[p][p]) / (2.0 * a[p][q]);
                let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (th * th + 1.0).sqrt());
                let c = 1.0 / (t * t + 1.0).sqrt(); let s = t * c;
                for m in [&mut a, &mut v] {
                    for k in 0..n { let (x, y) = (m[k][p], m[k][q]); m[k][p] = c * x - s * y; m[k][q] = s * x + c * y; }
                }
                for k in 0..n { let (x, y) = (a[p][k], a[q][k]); a[p][k] = c * x - s * y; a[q][k] = s * x + c * y; }
            }
        }
    }
    ((0..n).map(|i| a[i][i]).collect(), v)
}

// |T| = sqrt(T*T) and U: |T|v -> Tv on the eigenvectors with stretch > 0, zero on the rest
fn polar(t: &M) -> (M, M, Vec<f64>, M) {
    let n = t.len();
    let (w, v) = jacobi(&mul(&tp(t), t));
    let sig: Vec<f64> = w.iter().map(|&x| x.max(0.0).sqrt()).collect();
    let p: M = (0..n).map(|i| (0..n).map(|j| (0..n).map(|k| v[i][k] * sig[k] * v[j][k]).sum()).collect()).collect();
    let mut u = vec![vec![0.0; n]; n];
    for k in (0..n).filter(|&k| sig[k] > 1e-9) {
        let uk: Vec<f64> = (0..n).map(|i| (0..n).map(|m| t[i][m] * v[m][k]).sum::<f64>() / sig[k]).collect();
        for i in 0..n { for j in 0..n { u[i][j] += uk[i] * v[j][k]; } }
    }
    (p, u, sig, v)
}

fn zeros(a: &M) -> usize { jacobi(a).0.iter().filter(|x| x.abs() < 1e-9).count() } // kernel dimension of a symmetric A

fn main() {
    println!("1. the two-sample effect T = [[0, 2], [0, 0]]: read sample 2, double it, write it in slot 1");
    let t: M = vec![vec![0.0, 2.0], vec![0.0, 0.0]];
    let a = mul(&tp(&t), &t);
    let (p, u, _, _) = polar(&t);
    let s = (a[0][0] * a[1][1] - a[0][1] * a[1][0]).sqrt();
    let r = (a[0][0] + a[1][1] + 2.0 * s).sqrt();
    let p2: M = (0..2).map(|i| (0..2).map(|j| (a[i][j] + if i == j { s } else { 0.0 }) / r).collect()).collect(); // road 2
    let c = 4.0; // road 3: X <- X + (A/c - X^2)/2, c at least the top of A
    let (mut x, mut its) = (vec![vec![0.0; 2]; 2], vec![]);
    for _ in 0..7 {
        its.push(f64::sqrt(c) * x[1][1]);
        let x2 = mul(&x, &x);
        x = (0..2).map(|i| (0..2).map(|j| x[i][j] + (a[i][j] / c - x2[i][j]) / 2.0).collect()).collect();
    }
    let p3: M = x.iter().map(|row| row.iter().map(|v| f64::sqrt(c) * v).collect()).collect();
    println!("T*T = {}", fm(&a)); println!("|T| by Jacobi    = {}", fm(&p));
    println!("|T| by 2x2 rule  = {}", fm(&p2)); println!("|T| by iteration = {}", fm(&p3));
    println!("iteration on the stretch 2, steps 0 to 6: {}", its.iter().map(|&v| f6(v)).collect::<Vec<_>>().join(", "));
    assert!(gap(&p, &vec![vec![0.0, 0.0], vec![0.0, 2.0]]) < 1e-12 && gap(&p2, &p) < 1e-12 && gap(&p3, &p) < 1e-9);
    println!("U = {}   U|T| - T, largest entry: {}", fm(&u), f6(gap(&mul(&u, &p), &t)));
    assert!(gap(&mul(&u, &p), &t) < 1e-12 && gap(&u, &vec![vec![0.0, 1.0], vec![0.0, 0.0]]) < 1e-12);
    let (uu, uut) = (mul(&tp(&u), &u), mul(&u, &tp(&u)));
    println!("U*U = {} keeps span(e2);  UU* = {} keeps span(e1)", fm(&uu), fm(&uut));
    assert!(gap(&uu, &vec![vec![0.0, 0.0], vec![0.0, 1.0]]) < 1e-12 && gap(&uut, &vec![vec![1.0, 0.0], vec![0.0, 0.0]]) < 1e-12);
    let xv = vec![3.0, 5.0];
    let (tx, px) = (apply(&t, &xv), apply(&p, &xv));
    let (lt, lp) = (tx[0].hypot(tx[1]), px[0].hypot(px[1]));
    println!("x = (3, 5): Tx = {}  |T|x = {}  lengths {} and {}", fm(&vec![tx.clone()]), fm(&vec![px.clone()]), f6(lt), f6(lp));
    assert!((lt - lp).abs() < 1e-12 && (lt - 10.0).abs() < 1e-12);
    let w: M = vec![vec![0.0, 1.0], vec![1.0, 0.0]];
    println!("the swap W = {}  W|T| - T: {}  W*W - I: {}", fm(&w), f6(gap(&mul(&w, &p), &t)), f6(gap(&mul(&tp(&w), &w), &eye(2))));
    assert!(gap(&mul(&w, &p), &t) < 1e-12 && gap(&mul(&tp(&w), &w), &eye(2)) < 1e-12);
    let (zk, zm) = (zeros(&a), zeros(&mul(&t, &tp(&t))));
    println!("kernel of T: dimension {}   directions T misses: dimension {}", zk, zm);
    assert!(zk == 1 && zm == 1);
    let te: M = vec![vec![0.0, 2.0], vec![0.5, 0.0]]; // an invertible neighbour: e1 now goes to 0.5 e2
    let (pe, ue, _, _) = polar(&te);
    println!("T = {}  |T| = {}  U = {}  U*U - I: {}", fm(&te), fm(&pe), fm(&ue), f6(gap(&mul(&tp(&ue), &ue), &eye(2))));
    assert!(gap(&ue, &w) < 1e-12 && gap(&mul(&ue, &pe), &te) < 1e-12);

    println!("2. the delay S, cut to N samples; x = (1, 1/2, 1/4, ...)");
    for n in [4usize, 8, 16, 32] {
        let sm: M = (0..n).map(|i| (0..n).map(|j| if i == j + 1 { 1.0 } else { 0.0 }).collect()).collect();
        let (p, u, sig, v) = polar(&sm);
        let kv: Vec<f64> = (0..n).filter(|&k| sig[k] < 1e-9).flat_map(|k| (0..n).map(move |i| (k, i))).map(|(k, i)| v[i][k]).collect();
        let (wv, q) = jacobi(&mul(&sm, &tp(&sm)));
        let mv: Vec<f64> = (0..n).filter(|&k| wv[k].abs() < 1e-9).flat_map(|k| (0..n).map(move |i| (k, i))).map(|(k, i)| q[i][k]).collect();
        let xs: Vec<f64> = (0..n).map(|i| 0.5f64.powi(i as i32)).collect();
        let ok = kv.iter().zip(&xs).map(|(a, b)| a * b).sum::<f64>().abs();
        let om = mv.iter().zip(&xs).map(|(a, b)| a * b).sum::<f64>().abs();
        let d: M = (0..n).map(|i| (0..n).map(|j| if i == j && i < n - 1 { 1.0 } else { 0.0 }).collect()).collect();
        println!("N = {:2}: |S_N| - diag(1, ..., 1, 0): {}, U_N - S_N: {}, kernel {}, missed {}; x along the kernel {}, along the missed direction {}",
            n, f6(gap(&p, &d)), f6(gap(&u, &sm)), zeros(&mul(&tp(&sm), &sm)), zeros(&mul(&sm, &tp(&sm))), sci(ok), f6(om));
        assert!(gap(&u, &sm) < 1e-12 && gap(&p, &d) < 1e-12 && (ok - 0.5f64.powi(n as i32 - 1)).abs() < 1e-15 && (om - 1.0).abs() < 1e-12);
    }
    let y = vec![3, 1, 4, 1, 5];
    let mut z = y.clone(); z[0] = 0; // advance (drop the first sample), then delay: S S* y
    let (ey, ez): (i32, i32) = (y.iter().map(|v| v * v).sum(), z.iter().map(|v| v * v).sum());
    println!("delay after advance on (3, 1, 4, 1, 5): {:?}  energy {} -> {}", z, ey, ez);
    assert!(ez == 43);

    println!("3. the running total V on an N-point midpoint grid of [0, 1]");
    let ex = [2.0 / PI, 2.0 / (3.0 * PI)];
    println!("   N  sigma_1   error       sigma_2   error");
    let mut errs = vec![];
    for n in [8usize, 16, 32, 64] {
        let h = 1.0 / n as f64;
        let vn: M = (0..n).map(|i| (0..n).map(|j| if j < i { h } else if j == i { h / 2.0 } else { 0.0 }).collect()).collect();
        let (p, u, sig, v) = polar(&vn);
        let mut o: Vec<usize> = (0..n).collect();
        o.sort_by(|&i, &j| sig[j].partial_cmp(&sig[i]).unwrap());
        let (s1, s2) = (sig[o[0]], sig[o[1]]);
        let mut v1: Vec<f64> = (0..n).map(|i| v[i][o[0]]).collect();
        if v1.iter().sum::<f64>() < 0.0 { v1 = v1.iter().map(|a| -a).collect(); }
        let u1: Vec<f64> = apply(&vn, &v1).iter().map(|a| a / s1 / h.sqrt()).collect();
        let du = (0..n).map(|i| (u1[i] - 2f64.sqrt() * (PI * (i as f64 + 0.5) * h / 2.0).sin()).abs()).fold(0.0, f64::max);
        let (e1, e2, eu, er) = (s1 - ex[0], s2 - ex[1], gap(&mul(&tp(&u), &u), &eye(n)), gap(&mul(&u, &p), &vn));
        println!("{:4}  {}  {}  {}  {}", n, f6(s1), sci(e1), f6(s2), sci(e2));
        errs.push(e1.abs());
        assert!(eu < 1e-9 && er < 1e-9 && du < 1e-9);
    }
    assert!((0..3).all(|k| 3.5 < errs[k] / errs[k + 1] && errs[k] / errs[k + 1] < 4.5)); // error falls like 1/N^2
    println!("exact: sigma_1 = 2/pi = {}  sigma_2 = 2/(3 pi) = {}  error ratios {}", f6(ex[0]), f6(ex[1]),
        (0..3).map(|k| format!("{:.3}", errs[k] / errs[k + 1])).collect::<Vec<_>>().join(", "));
    println!("at every N: U*U - I, U|V| - V and u_1 - sqrt2 sin(pi x/2) on the grid all below 1e-9");

    println!("what breaks");
    let pl = polar(&tp(&t)).0; // |T*| = sqrt(T T*), the stretch for the left form
    println!("U|T*| in place of U|T|: {}  largest error {}", fm(&mul(&u, &pl)), f6(gap(&mul(&u, &pl), &t)));
    assert!(gap(&mul(&u, &pl), &t) > 1.9 && gap(&pl, &vec![vec![2.0, 0.0], vec![0.0, 0.0]]) < 1e-12);
    let ux = vec![apply(&uu, &xv)];
    println!("U*U x for x = (3, 5), as if U were unitary: {}", fm(&ux));
    assert!(gap(&ux, &vec![vec![0.0, 5.0]]) < 1e-12);
    for n in [4usize, 8, 16, 32] { // the cyclic delay C_N is unitary; the input it sends to e1 is e_N
        let c: M = (0..n).map(|i| (0..n).map(|j| if i == (j + 1) % n { 1.0 } else { 0.0 }).collect()).collect();
        let e1: Vec<f64> = (0..n).map(|i| if i == 0 { 1.0 } else { 0.0 }).collect();
        let pre = apply(&tp(&c), &e1);
        let ov: f64 = pre.iter().enumerate().map(|(i, a)| a * 0.5f64.powi(i as i32)).sum();
        let g = gap(&mul(&tp(&c), &c), &eye(n));
        println!("cyclic delay C_N, N = {:2}: C_N*C_N - I {}; the input sent to e1 overlaps x by {}", n, f6(g), sci(ov));
        assert!(g < 1e-12 && (ov - 2f64.powi(1 - n as i32)).abs() < 1e-15);
    }
    println!("ALL CHECKS PASS");
}
