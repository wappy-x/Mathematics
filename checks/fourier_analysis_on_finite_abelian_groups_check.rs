// Fourier analysis on a finite abelian group -- the same check as the Python,
// in Rust.  No crates.  A complex number is a small struct; every character,
// transform, convolution and count is written out here.  Two groups: the
// 12-hour clock Z/12, and three votes in {-1, 1}^3.
use std::collections::{BTreeMap, BTreeSet};
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn conj(self) -> C { C { re: self.re, im: -self.im } }
    fn scale(self, s: f64) -> C { C { re: self.re * s, im: self.im * s } }
    fn abs(self) -> f64 { (self.re * self.re + self.im * self.im).sqrt() }
}
const ZERO: C = C { re: 0.0, im: 0.0 };
const N: usize = 12;
fn cis(t: f64) -> C { C { re: t.cos(), im: t.sin() } }            // the point at angle t on the unit circle
fn re(x: f64) -> C { C { re: x, im: 0.0 } }
fn close(a: C, b: C) -> bool { a.sub(b).abs() < 1e-9 }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn fmt(z: C) -> String {                                          // a+bi, 6 decimals, rounding dust dropped
    let r = if z.re.abs() < 1e-9 { 0.0 } else { z.re };
    let i = if z.im.abs() < 1e-9 { 0.0 } else { z.im };
    format!("{:.6}{}{:.6}i", r, if i >= 0.0 { "+" } else { "-" }, i.abs())
}
fn fl(v: &[f64]) -> String { format!("[{}]", v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ")) }
fn gcd(a: usize, b: usize) -> usize { if b == 0 { a } else { gcd(b, a % b) } }
fn ones(s: usize) -> usize { s.count_ones() as usize }

fn hat(f: &[C], ch: &[Vec<C>], count: &mut usize) -> Vec<C> {    // f^(j) = (1/12) sum_k f(k) conj chi_j(k)
    *count += N * N;
    (0..N).map(|j| (0..N).fold(ZERO, |s, k| s.add(f[k].mul(ch[j][k].conj()))).scale(1.0 / N as f64)).collect()
}
fn hat_crt(f: &[C], back: &BTreeMap<(usize, usize), usize>, count: &mut usize) -> Vec<C> {
    *count += 4 * 3 * 3 + 4 * 3 * 4;                              // through Z/4 x Z/3, 3 then 4 at a time
    let mut inner = BTreeMap::new();
    for k1 in 0..4 { for b in 0..3 {
        inner.insert((k1, b), (0..3).fold(ZERO, |s, k2| s.add(f[back[&(k1, k2)]].mul(cis(-2.0 * PI * (b * k2) as f64 / 3.0)))));
    } }
    let mut out = vec![ZERO; N];
    for a in 0..4 { for b in 0..3 {
        out[(3 * a + 4 * b) % N] = (0..4).fold(ZERO, |s, k1| s.add(inner[&(k1, b)].mul(cis(-2.0 * PI * (a * k1) as f64 / 4.0)))).scale(1.0 / N as f64);
    } }
    out
}
fn supp(v: &[C]) -> usize { v.iter().filter(|z| z.abs() > 1e-9).count() }
fn main() {
    let ch: Vec<Vec<C>> = (0..N).map(|j| (0..N).map(|k| cis(2.0 * PI * (j * k) as f64 / N as f64)).collect()).collect();
    let hom = ch.iter().all(|c| (0..N).all(|a| (0..N).all(|b| close(c[(a + b) % N], c[a].mul(c[b])))));
    let gram = (0..N).all(|j| (0..N).all(|l| close((0..N).fold(ZERO, |s, k| s.add(ch[j][k].mul(ch[l][k].conj()))).scale(1.0 / N as f64), re(if j == l { 1.0 } else { 0.0 }))));
    let order: Vec<usize> = (0..N).map(|j| (1..=N).find(|&m| { let mut p = re(1.0); for _ in 0..m { p = p.mul(ch[j][1]) } close(p, re(1.0)) }).unwrap()).collect();
    let o12 = order.iter().filter(|&&o| o == 12).count();
    println!("Z/12: 12 characters, each turns sums into products on all 144 pairs: {}", yn(hom));
    println!("the 144 averages <chi_j, chi_l> are 1 when j = l and 0 otherwise: {}", yn(gram));
    println!("orders of chi_0..chi_11: {:?}; of order 12: {}, so {} ways to match Z/12 with its dual", order, o12, o12);
    assert!(hom && gram && o12 == (0..N).filter(|&j| gcd(j, N) == 1).count());

    let pairs: Vec<(usize, usize)> = (0..N).map(|k| (k % 4, k % 3)).collect();          // Chinese remainder split
    let back: BTreeMap<(usize, usize), usize> = pairs.iter().enumerate().map(|(k, &p)| (p, k)).collect();
    let mut mat: BTreeMap<usize, (usize, usize)> = BTreeMap::new();
    for j in 0..N { for a in 0..4 { for b in 0..3 {                                     // search for (a, b) per character
        if (0..N).all(|k| close(ch[j][k], cis(2.0 * PI * (a * (k % 4)) as f64 / 4.0).mul(cis(2.0 * PI * (b * (k % 3)) as f64 / 3.0)))) { mat.insert(j, (a, b)); }
    } } }
    println!("k -> (k mod 4, k mod 3) hits all 12 pairs: {}; back again: k = (9 k1 + 4 k2) mod 12: {}", yn(back.len() == 12), yn(pairs.iter().all(|&(x, y)| back[&(x, y)] == (9 * x + 4 * y) % N)));
    println!("character j as (a on Z/4, b on Z/3): {}", mat.iter().map(|(j, (a, b))| format!("{}:({},{})", j, a, b)).collect::<Vec<_>>().join(", "));
    let crt_rule = mat.iter().all(|(&j, &(a, b))| (3 * a + 4 * b) % N == j);
    println!("j = (3a + 4b) mod 12 for all twelve: {}", yn(crt_rule));
    assert!(mat.len() == 12 && crt_rule);

    let f: Vec<C> = (0..N).map(|k| re(if k % 3 == 0 { 1.0 } else { 0.0 })).collect();   // the quarter marks
    let g: Vec<C> = (0..N).map(|k| re(if k < 2 { 1.0 } else { 0.0 })).collect();        // a two-hour window
    let mut count = [0usize, 0usize];
    let (fh, gh) = (hat(&f, &ch, &mut count[0]), hat(&g, &ch, &mut count[0]));
    let nz: Vec<usize> = (0..N).filter(|&j| fh[j].abs() > 1e-9).collect();
    println!("f = quarter marks: f^ nonzero at j = {:?}, each {}", nz, fmt(fh[0]));
    println!("g = window 0, 1: g^(1) = {}, g^(4) = {}, g^(6) = {}", fmt(gh[1]), fmt(gh[4]), fmt(gh[6]));
    let (cf, cg) = (hat_crt(&f, &back, &mut count[1]), hat_crt(&g, &back, &mut count[1]));
    let crt_ok = (0..N).all(|j| close(cf[j], fh[j]) && close(cg[j], gh[j]));
    println!("transform through Z/4 x Z/3 equals the direct sum: {}; products {} against {}", yn(crt_ok), count[1] / 2, count[0] / 2);
    let inv_ok = [(&f, &fh), (&g, &gh)].iter().all(|(v, h)| (0..N).all(|k| close((0..N).fold(ZERO, |s, j| s.add(h[j].mul(ch[j][k]))), v[k])));
    println!("sum of f^(j) chi_j rebuilds f and g at all 12 hours: {}", yn(inv_ok));
    for (name, v, h) in [("f", &f, &fh), ("g", &g, &gh)] { println!("Plancherel for {}: mean |{}|^2 = {:.6}, sum |{}^|^2 = {:.6}", name, name,
        v.iter().map(|x| x.abs().powi(2)).sum::<f64>() / N as f64, name, h.iter().map(|z| z.abs().powi(2)).sum::<f64>()) }
    let conv: Vec<C> = (0..N).map(|x| (0..N).fold(ZERO, |s, y| s.add(f[y].mul(g[(x + N - y) % N]))).scale(1.0 / N as f64)).collect();
    let chh = hat(&conv, &ch, &mut count[0]);
    let conv_ok = (0..N).all(|j| close(chh[j], fh[j].mul(gh[j])));
    println!("(f*g)(x) times 12, x = 0..11: {:?}", conv.iter().map(|c| (12.0 * c.re).round() as i64).collect::<Vec<_>>());
    println!("(f*g)^(4) = {}; f^(4) g^(4) = {}; all 12 agree: {}", fmt(chh[4]), fmt(fh[4].mul(gh[4])), yn(conv_ok));
    assert!(crt_ok && inv_ok && conv_ok);
    let delta: Vec<C> = (0..N).map(|k| re(if k == 0 { 1.0 } else { 0.0 })).collect();   // one hour
    let dh = supp(&hat(&delta, &ch, &mut count[0]));
    println!("support sizes: f {} x {} = {}; g {} x {} = {}; one hour {} x {} = {}", supp(&f), supp(&fh), supp(&f) * supp(&fh),
             supp(&g), supp(&gh), supp(&g) * supp(&gh), supp(&delta), dh, dh);
    let prods: Vec<(usize, usize)> = (1..1usize << N).map(|s| {
        let v: Vec<C> = (0..N).map(|k| re(((s >> k) & 1) as f64)).collect();
        (s, ones(s) * supp(&hat(&v, &ch, &mut count[0])))
    }).collect();
    let best = prods.iter().map(|p| p.1).min().unwrap();
    let reach: BTreeSet<usize> = prods.iter().filter(|p| p.1 == best).map(|p| p.0).collect();
    let mut cosets = BTreeSet::new();
    for d in (1..=N).filter(|d| N % d == 0) { for c in 0..N { cosets.insert((0..N / d).map(|h| 1usize << ((c + h * d) % N)).sum::<usize>()); } }
    println!("all 4095 nonempty sets of hours: smallest product {}, reached by {} sets; cosets of the 6 subgroups: {}, the same sets: {}",
             best, reach.len(), cosets.len(), yn(reach == cosets));
    assert!(best == N && reach == cosets);

    let n = 3;
    let xs: Vec<Vec<i64>> = (0..8).map(|b| (0..n).map(|i| 1 - 2 * ((b >> (n - 1 - i)) & 1) as i64).collect()).collect();
    let maj: Vec<i64> = xs.iter().map(|x| if x.iter().sum::<i64>() > 0 { 1 } else { -1 }).collect();
    let chi_s = |s: usize, x: &Vec<i64>| -> i64 { (0..n).filter(|i| (s >> (n - 1 - i)) & 1 == 1).map(|i| x[i]).product() };
    let idx = |x: &Vec<i64>| xs.iter().position(|y| y == x).unwrap();
    let brute: Vec<f64> = (0..8).map(|s| (0..8).map(|t| maj[t] * chi_s(s, &xs[t])).sum::<i64>() as f64 / 8.0).collect();
    let (mut v, mut h, mut ops) = (maj.clone(), 1, 0);                                   // fast Walsh-Hadamard butterflies
    while h < 8 {
        for i in (0..8).step_by(2 * h) { for j in i..i + h { let (a, b) = (v[j], v[j + h]); v[j] = a + b; v[j + h] = a - b; ops += 2; } } h *= 2;
    }
    let fast: Vec<f64> = v.iter().map(|&x| x as f64 / 8.0).collect();
    let name = |s: usize| (0..n).filter(|i| (s >> (n - 1 - i)) & 1 == 1).map(|i| format!("x{}", i + 1)).collect::<String>();
    println!("Maj on the 8 inputs from (1,1,1) to (-1,-1,-1): {:?}", maj);
    println!("coefficients by averaging equal the butterflies: {}; operations {} against {}", yn(brute == fast), ops, 8 * 8);
    let mut terms: Vec<(usize, String, f64)> = (0..8).filter(|&s| brute[s] != 0.0).map(|s| (ones(s), name(s), brute[s])).collect();
    terms.sort_by(|a, b| (a.0, &a.1).cmp(&(b.0, &b.1)));
    let line = terms.iter().map(|(_, nm, c)| format!("{} {:.1} {}", if *c > 0.0 { "+" } else { "-" }, c.abs(), nm)).collect::<Vec<_>>().join(" ");
    println!("Maj = {}", line.trim_start_matches(|c| c == '+' || c == ' '));
    let rebuild = xs.iter().zip(&maj).all(|(x, &m)| (0..8).map(|s| brute[s] * chi_s(s, x) as f64).sum::<f64>() == m as f64);
    println!("sum of Maj^(S) chi_S rebuilds Maj on all 8 inputs: {}", yn(rebuild));
    let deg: Vec<f64> = (0..=n).map(|d| (0..8).filter(|&s| ones(s) == d).map(|s| brute[s].powi(2)).sum()).collect();
    println!("Fourier weight at degree 0..3: {}; total {:.2}; mean Maj^2 {:.2}", fl(&deg), deg.iter().sum::<f64>(), maj.iter().map(|m| m * m).sum::<i64>() as f64 / 8.0);
    let infl: Vec<f64> = (0..n).map(|i| (0..8).filter(|&t| { let mut y = xs[t].clone(); y[i] = -y[i]; maj[idx(&y)] != maj[t] }).count() as f64 / 8.0).collect();
    let infl_w: Vec<f64> = (0..n).map(|i| (0..8).filter(|&s| (s >> (n - 1 - i)) & 1 == 1).map(|s| brute[s].powi(2)).sum()).collect();
    println!("influence of each voter: by flipping {}; from weights {}", fl(&infl), fl(&infl_w));
    let (p, mut noisy) = (0.1f64, 0.0);
    for t in 0..8 { for b in 0..8usize {
        let (e, k) = ([(b >> 2) & 1, (b >> 1) & 1, b & 1], b.count_ones() as i32);
        let y: Vec<i64> = (0..n).map(|i| xs[t][i] * (1 - 2 * e[i] as i64)).collect();
        noisy += p.powi(k) * (1.0 - p).powi(n as i32 - k) / 8.0 * if maj[t] != maj[idx(&y)] { 1.0 } else { 0.0 };
    } }
    let stab = 0.5 - 0.5 * (0..8).map(|s| (1.0 - 2.0 * p).powi(ones(s) as i32) * brute[s].powi(2)).sum::<f64>();
    println!("each vote misread with chance {}: winner changes, counted {:.6}, from weights {:.6}; one voter alone {:.6}", p, noisy, stab, p);
    let mut pass = 0;
    for x in &xs { for y in &xs { let xy: Vec<i64> = (0..n).map(|i| x[i] * y[i]).collect(); if maj[idx(x)] * maj[idx(y)] == maj[idx(&xy)] { pass += 1 } } }
    let (blr, blr_w) = (pass as f64 / 64.0, 0.5 + 0.5 * brute.iter().map(|c| c.powi(3)).sum::<f64>());
    println!("linearity test f(x)f(y) = f(xy) passes: counted {:.6}, from weights {:.6}", blr, blr_w);
    let cube = (1..256usize).map(|s| ones(s) * (0..8).filter(|&q| (0..8).map(|t| ((s >> t) & 1) as i64 * chi_s(q, &xs[t])).sum::<i64>() != 0).count()).min().unwrap();
    let nzm = brute.iter().filter(|&&c| c != 0.0).count();
    println!("uncertainty on the cube: Maj {} x {} = {}; smallest over 255 sets of inputs: {}", maj.len(), nzm, 8 * nzm, cube);
    assert!(brute == fast && deg == vec![0.0, 0.75, 0.0, 0.25] && infl == vec![0.5; 3] && infl == infl_w && cube == 8);
    assert!((noisy - stab).abs() < 1e-9 && (blr - blr_w).abs() < 1e-9);

    let s3: [[usize; 3]; 6] = [[0, 1, 2], [1, 0, 2], [0, 2, 1], [2, 1, 0], [1, 2, 0], [2, 0, 1]];   // shuffles of 3 things
    let (pos, mut homs) = (|p: [usize; 3]| s3.iter().position(|q| *q == p).unwrap(), Vec::new());
    for c in 0..6usize.pow(6) {                                                         // every map to sixth roots of 1
        let e: Vec<usize> = (0..6).map(|i| (c / 6usize.pow(i)) % 6).collect();
        if s3.iter().all(|a| s3.iter().all(|b| e[pos([a[b[0]], a[b[1]], a[b[2]]])] == (e[pos(*a)] + e[pos(*b)]) % 6)) { homs.push(e) }
    }
    let swap: Vec<f64> = s3.iter().map(|s| if *s == [1, 0, 2] { 1.0 } else { 0.0 }).collect();   // one swap
    let kept: f64 = homs.iter().map(|e| (0..6).fold(ZERO, |s, t| s.add(cis(-2.0 * PI * e[t] as f64 / 6.0).scale(swap[t]))).scale(1.0 / 6.0).abs().powi(2)).sum();
    println!("break 1, S3 is not abelian: {} characters for 6 members; they keep {:.6} of a swap's energy", homs.len(), kept / (1.0 / 6.0));
    let o62 = (0..6).flat_map(|a| (0..2).map(move |b| (a, b))).map(|(a, b)| (1..13).find(|&m| (0..6).all(|x| (0..2).all(|y|
        close(cis(2.0 * PI * m as f64 * ((a * x) as f64 / 6.0 + (b * y) as f64 / 2.0)), re(1.0))))).unwrap()).max().unwrap();
    println!("break 2, Z/6 x Z/2 (6 and 2 share a factor): highest character order {}, not 12", o62);
    println!("break 3, Maj coefficients added unsquared: {:.2}, not 1", brute.iter().map(|c| c.abs()).sum::<f64>());
    println!("break 4, sums on both sides for f: sum |f|^2 = {}, sum |12 f^|^2 = {:.6}", f.iter().map(|z| z.re).sum::<f64>() as i64,
             fh.iter().map(|z| z.scale(12.0).abs().powi(2)).sum::<f64>());
    assert!(homs.len() == 2 && (kept * 6.0 - 1.0 / 3.0).abs() < 1e-9 && o62 == 6);
    println!("ALL CHECKS PASS");
}
