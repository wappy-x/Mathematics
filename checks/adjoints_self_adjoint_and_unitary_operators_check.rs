// Adjoints -- the check behind the card.  Rust std only, no crates.
// An 8-speaker ring: turn R, causal blur A, binomial blur B, box blur C.
// Each adjoint is built from the swapped-kernel formula, never by transposing,
// then tested against <Tf, g> = <f, T*g>.  Eigenvalues come from a closed form
// and are checked by residuals and by the trace and size sums.
use std::f64::consts::PI;
type M = Vec<Vec<f64>>;
#[derive(Clone, Copy)]
struct Cx { re: f64, im: f64 }
impl Cx {
    fn abs(self) -> f64 { (self.re * self.re + self.im * self.im).sqrt() }
}

fn clean(x: f64) -> f64 { if x.abs() < 5e-13 { 0.0 } else { x } }
fn ring(n: usize, taps: &[(usize, f64)]) -> M {      // kernel k(j, l) = taps[(j - l) mod n]
    let mut t = vec![vec![0.0; n]; n];
    for j in 0..n { for &(d, v) in taps { t[j][(j + n - d) % n] += v; } }
    t
}
fn adj_taps(n: usize, taps: &[(usize, f64)]) -> Vec<(usize, f64)> {   // swapped kernel
    taps.iter().map(|&(d, v)| ((n - d) % n, v)).collect()
}
fn apply(t: &M, f: &[f64]) -> Vec<f64> { t.iter().map(|r| r.iter().zip(f).map(|(a, b)| a * b).sum()).collect() }
fn ip(f: &[f64], g: &[f64]) -> f64 { f.iter().zip(g).map(|(a, b)| a * b).sum() }
fn mul(s: &M, t: &M) -> M {
    let n = t.len();
    (0..n).map(|j| (0..n).map(|l| (0..n).map(|k| s[j][k] * t[k][l]).sum()).collect()).collect()
}
fn tr(t: &M) -> M { let n = t.len(); (0..n).map(|j| (0..n).map(|l| t[l][j]).collect()).collect() }
fn same(s: &M, t: &M) -> bool {
    let n = s.len();
    (0..n).all(|j| (0..n).all(|l| (s[j][l] - t[j][l]).abs() < 1e-12))
}
fn eig(n: usize, taps: &[(usize, f64)], m: usize) -> Cx {   // closed form on Fourier mode m
    let (mut re, mut im) = (0.0, 0.0);
    for &(d, v) in taps {
        let a = 2.0 * PI * (m * d) as f64 / n as f64;
        re += v * a.cos(); im -= v * a.sin();
    }
    Cx { re, im }
}
fn g6(x: f64) -> String {   // like Python's :g for these short numbers
    let s = format!("{:.6}", x);
    s.trim_end_matches('0').trim_end_matches('.').to_string()
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no " } }

fn main() {
    let n = 8usize;
    let id = ring(n, &[(0, 1.0)]);
    let ops: Vec<(&str, Vec<(usize, f64)>)> = vec![
        ("turn R", vec![(1, 1.0)]), ("causal blur A", vec![(0, 0.5), (1, 0.5)]),
        ("binomial blur B", vec![(0, 0.5), (1, 0.25), (n - 1, 0.25)]),
        ("box blur C", vec![(0, 1.0 / 3.0), (1, 1.0 / 3.0), (n - 1, 1.0 / 3.0)])];
    let f = vec![4.0, 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0];
    let g = vec![0.0, 1.0, 3.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    println!("ring N = {}; f = 4 2 0 0 0 0 0 1; g = 0 1 3 0 0 0 0 0", n);
    println!("operator            <Tf,g>   <f,T*g>    <f,Tg>  T*=T  unitary  normal    min eig  max |eig|");
    for (name, t) in &ops {
        let (tm, ts) = (ring(n, t), ring(n, &adj_taps(n, t)));
        for j in 0..n { for l in 0..n {     // the defining identity on every pair of basis vectors
            let e: Vec<f64> = (0..n).map(|k| if k == j { 1.0 } else { 0.0 }).collect();
            let h: Vec<f64> = (0..n).map(|k| if k == l { 1.0 } else { 0.0 }).collect();
            assert!((ip(&apply(&tm, &e), &h) - ip(&e, &apply(&ts, &h))).abs() < 1e-15);
        } }
        assert!(same(&ts, &tr(&tm)));      // road 2: the swapped kernel is the transpose
        let lam: Vec<Cx> = (0..n).map(|m| eig(n, t, m)).collect();
        for m in 0..n {                     // road 3: residual |T v - lam v| for each Fourier mode
            let a: Vec<f64> = (0..n).map(|k| 2.0 * PI * (m * k) as f64 / n as f64).collect();
            let (vr, vi): (Vec<f64>, Vec<f64>) = (a.iter().map(|x| x.cos()).collect(), a.iter().map(|x| x.sin()).collect());
            let (tr_, ti_) = (apply(&tm, &vr), apply(&tm, &vi));
            for k in 0..n {
                let (er, ei) = (tr_[k] - (lam[m].re * vr[k] - lam[m].im * vi[k]), ti_[k] - (lam[m].re * vi[k] + lam[m].im * vr[k]));
                assert!((er * er + ei * ei).sqrt() < 1e-12);
            }
        }
        let trace: f64 = (0..n).map(|k| tm[k][k]).sum();
        assert!((lam.iter().map(|z| z.re).sum::<f64>() - trace).abs() < 1e-12);
        let fro: f64 = tm.iter().flatten().map(|x| x * x).sum();
        assert!((lam.iter().map(|z| z.abs().powi(2)).sum::<f64>() - fro).abs() < 1e-12);
        let sa = same(&ts, &tm);
        let un = same(&mul(&ts, &tm), &id) && same(&mul(&tm, &ts), &id);
        let nm = same(&mul(&ts, &tm), &mul(&tm, &ts));
        let mn = if sa { format!("{:9.6}", clean(lam.iter().map(|z| z.re).fold(f64::MAX, f64::min))) } else { "    -    ".to_string() };
        let mx = lam.iter().map(|z| z.abs()).fold(0.0, f64::max);
        println!("{:<16}{:10.6}{:10.6}{:10.6}  {}   {}      {} {}  {:8.6}", name, ip(&apply(&tm, &f), &g),
            ip(&f, &apply(&ts, &g)), ip(&f, &apply(&tm, &g)), yn(sa), yn(un), yn(nm), mn, mx);
        let last = name.chars().last().unwrap();
        assert!(nm && sa == (last == 'B' || last == 'C') && un == (last == 'R'));
    }
    let (r, a, b, c) = (ring(n, &ops[0].1), ring(n, &ops[1].1), ring(n, &ops[2].1), ring(n, &ops[3].1));
    let a_s = ring(n, &adj_taps(n, &ops[1].1));
    assert!(same(&mul(&a_s, &a), &b));     // B = A*A, so <f, Bf> = |Af|^2 >= 0
    let (bf, af, rf) = (apply(&b, &f), apply(&a, &f), apply(&r, &f));
    let js = |v: &[f64]| v.iter().map(|x| g6(*x)).collect::<Vec<_>>().join(" ");
    println!("Bf = {} ; Af = {}", js(&bf), js(&af));
    println!("Rf = {} ; R*g = {} ; A*g = {}", js(&rf), js(&apply(&tr(&r), &g)), js(&apply(&a_s, &g)));
    println!("<f,Bf> = {:.6}; |Af|^2 = {:.6}; |f|^2 = {:.6}; |Rf|^2 = {:.6}", ip(&f, &bf), ip(&af, &af), ip(&f, &f), ip(&rf, &rf));
    assert!((ip(&f, &bf) - ip(&af, &af)).abs() < 1e-12 && (ip(&rf, &rf) - ip(&f, &f)).abs() < 1e-12);
    let alt: Vec<f64> = (0..n).map(|k| if k % 2 == 0 { 1.0 } else { -1.0 }).collect();
    println!("alternating h: <h,Ch> = {:.6}; <h,Bh> = {:.6}; |h|^2 = {:.6}", ip(&alt, &apply(&c, &alt)), clean(ip(&alt, &apply(&b, &alt))), ip(&alt, &alt));
    assert!((ip(&alt, &apply(&c, &alt)) + 8.0 / 3.0).abs() < 1e-12);

    // the positive square root of B: keep B's Fourier modes, take square roots of its eigenvalues
    let p: Vec<(usize, f64)> = (0..n).map(|k| (k, (0..n).map(|m| (PI * m as f64 / n as f64).cos().abs()
        * (2.0 * PI * (m * k) as f64 / n as f64).cos()).sum::<f64>() / n as f64)).collect();
    let pm = ring(n, &p);
    assert!(same(&mul(&pm, &pm), &b) && same(&pm, &tr(&pm)) && (0..n).all(|m| eig(n, &p, m).re > -1e-12));
    assert!(!same(&pm, &a));               // A*A = B too, but A is not self-adjoint
    println!("square root P of B, taps k = 0..4: {}", (0..5).map(|k| format!("{:.6}", clean(p[k].1))).collect::<Vec<_>>().join(" "));

    // infinite dimensions: the delay S on an endless signal, cut to its first N samples
    println!("N    |S*Sf - f|   |SS*f - f|   sum|eig|^2   sum|entry|^2   (f = 1, 1/2, 1/4, ...)");
    for &nn in &[4usize, 8, 16, 32, 64] {
        let s: M = (0..nn).map(|j| (0..nn).map(|l| if j == l + 1 { 1.0 } else { 0.0 }).collect()).collect();
        let fv: Vec<f64> = (0..nn).map(|k| 0.5f64.powi(k as i32)).collect();
        let diff = |u: Vec<f64>| u.iter().zip(&fv).map(|(a, b)| (a - b) * (a - b)).sum::<f64>().sqrt();
        let d1 = diff(apply(&tr(&s), &apply(&s, &fv)));
        let d2 = diff(apply(&s, &apply(&tr(&s), &fv)));
        let fro: f64 = s.iter().flatten().map(|x| x * x).sum();
        let eigs: f64 = (0..nn).map(|k| s[k][k] * s[k][k]).sum();   // triangular: eigs on diagonal
        println!("{:<4} 2^-{:<9} {:10.6}   {:10.6}   {:12.6}", nn, nn - 1, d2, eigs, fro);
        assert!(d1 == 0.5f64.powi(nn as i32 - 1) && (d2 - 1.0).abs() < 1e-15 && fro == (nn - 1) as f64);
    }

    // what breaks, and the try-changing box
    println!("wrong: R* = R gives <f,Rg> = {:.6}; wrong: A* = A gives <f,Ag> = {:.6}", ip(&f, &apply(&r, &g)), ip(&f, &apply(&a, &g)));
    for &nn in &[8usize, 9] {
        let cmin = (0..nn).map(|m| (1.0 + 2.0 * (2.0 * PI * m as f64 / nn as f64).cos()) / 3.0).fold(f64::MAX, f64::min);
        let bmin = (0..nn).map(|m| (PI * m as f64 / nn as f64).cos().powi(2)).fold(f64::MAX, f64::min);
        println!("N = {}: min eig box C = {:.6}; binomial B = {:.6}", nn, cmin, clean(bmin));
    }
    let w = [(0usize, 0.4), (1, 0.3), (n - 1, 0.3)];
    println!("weights 0.3 0.4 0.3: min eig = {:.6}", (0..n).map(|m| eig(n, &w, m).re).fold(f64::MAX, f64::min));
    println!("turn by 2 speakers: eigenvalues of R^2 have |eig| = {:.6}", (0..n).map(|m| eig(n, &[(2, 1.0)], m).abs()).fold(0.0, f64::max));
    let lam_a: Vec<Cx> = (0..n).map(|m| eig(n, &ops[1].1, m)).collect();
    assert!(lam_a.iter().all(|z| ((Cx { re: z.re - 0.5, im: z.im }).abs() - 0.5).abs() < 1e-12));
    println!("figure, R on |z| = 1; A on |z - 0.5| = 0.5; B in [0, 1]; C in [-0.333333, 1]; A at m = 2: {:.6} {:.6}", lam_a[2].re, lam_a[2].im);
    println!("ALL CHECKS PASS");
}
