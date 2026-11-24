// Incomplete factorisations -- the same check as the Python, in Rust.  No
// crates.  The heated plate's 5-point matrix: ILU(0), modified ILU(0), ILU(1),
// threshold dropping and diagonal shifts, used inside CG and BiCGSTAB.
use std::collections::HashMap;
type Row = Vec<(usize, f64)>; // a sparse row, kept in insertion order
struct Fac { l: Vec<Row>, u: Vec<Row>, d: Vec<f64> }
fn get(row: &Row, j: usize) -> f64 { row.iter().find(|e| e.0 == j).map_or(0.0, |e| e.1) }
fn grid(m: usize, red_black: bool, p: f64) -> (Vec<Row>, Vec<f64>, Vec<usize>) {
    let mut cells: Vec<(usize, usize)> = (0..m * m).map(|k| (k % m, k / m)).collect();
    if red_black { cells.sort_by_key(|c| (c.0 + c.1) % 2); }
    let mut idx = vec![0; m * m]; for (k, c) in cells.iter().enumerate() { idx[c.1 * m + c.0] = k; }
    let (h, mut a, mut b) = (1.0 / (m + 1) as f64, Vec::new(), vec![0.0; m * m]);
    for &(i, j) in &cells {
        let mut row = vec![(idx[j * m + i], 4.0)];
        for (di, dj, v) in [(-1i64, 0i64, -1.0 - p), (1, 0, -1.0 + p), (0, -1, -1.0), (0, 1, -1.0)] {
            let (x, y) = (i as i64 + di, j as i64 + dj);
            if x >= 0 && y >= 0 && x < m as i64 && y < m as i64 { row.push((idx[y as usize * m + x as usize], v)); }
        }
        a.push(row);
        let (x, y) = ((i + 1) as f64 * h, (j + 1) as f64 * h);
        if (x - 0.5).abs() <= 0.125 && (y - 0.5).abs() <= 0.125 { b[idx[j * m + i]] = h * h * 1000.0; }
    }
    (a, b, idx)
}
// Row-by-row LU keeping fill of level <= lev; returns the factor or the breakdown, dropped fill, flops.
fn ilu(a: &[Row], lev: usize, tau: f64, modified: bool, shift: f64)
    -> (Result<Fac, (usize, f64)>, HashMap<(usize, usize), f64>, u64) {
    let (mut f, mut ul, mut drop, mut fl) = (Fac { l: vec![], u: vec![], d: vec![] }, Vec::<Vec<usize>>::new(), HashMap::new(), 0u64);
    for i in 0..a.len() {
        let (mut w, mut lv): (Row, Vec<usize>) = (a[i].clone(), vec![0; a[i].len()]);
        let mut pos: HashMap<usize, usize> = w.iter().enumerate().map(|(q, e)| (e.0, q)).collect();
        w[pos[&i]].1 *= 1.0 + shift; let mut k: i64 = -1;
        loop {
            let Some(kk) = w.iter().map(|e| e.0).filter(|&j| (j as i64) > k && j < i).min() else { break };
            k = kk as i64; let qk = pos[&kk]; w[qk].1 /= f.d[kk]; fl += 1; let wk = w[qk].1;
            for (t, &(j, u)) in f.u[kk].iter().enumerate() {
                if j <= kk { continue; }
                fl += 2; let new = lv[qk] + ul[kk][t] + 1;
                if let Some(&q) = pos.get(&j) { w[q].1 = w[q].1 - wk * u; lv[q] = lv[q].min(new); }
                else if new <= lev { pos.insert(j, w.len()); w.push((j, 0.0 - wk * u)); lv.push(new); }
                else {  // fill outside the kept pattern: drop it
                    let e = drop.entry((i, j)).or_insert(0.0); *e = *e - wk * u;
                    if modified { let qi = pos[&i]; w[qi].1 -= wk * u; fl += 1; }
                }
            }
        }
        let size = a[i].iter().fold(0.0, |s, e| s + e.1 * e.1).sqrt();
        let keep: Vec<bool> = w.iter().map(|e| e.0 == i || a[i].iter().any(|x| x.0 == e.0) || e.1.abs() >= tau * size).collect();
        let lvk: Vec<usize> = lv.iter().zip(&keep).filter(|p| *p.1).map(|p| *p.0).collect();
        let w: Row = w.iter().zip(&keep).filter(|p| *p.1).map(|p| *p.0).collect();
        let di = get(&w, i); if di <= 0.0 { return (Err((i, di)), drop, fl); } // breakdown: a pivot <= 0
        f.l.push(w.iter().filter(|e| e.0 < i).cloned().collect()); f.u.push(w.iter().filter(|e| e.0 >= i).cloned().collect());
        ul.push(w.iter().zip(&lvk).filter(|p| p.0 .0 >= i).map(|p| *p.1).collect());
        f.d.push(di);
    }
    (Ok(f), drop, fl)
}
fn acc<I: Iterator<Item = (f64, f64)>>(pairs: I) -> f64 { let mut s = 0.0; for (a, c) in pairs { s += a * c; } s }
fn solve(f: &Fac, r: &[f64]) -> Vec<f64> { // M z = r: forward with L, back with U
    let n = r.len(); let (mut y, mut z) = (vec![0.0; n], vec![0.0; n]);
    for i in 0..n { y[i] = r[i] - acc(f.l[i].iter().map(|&(j, v)| (v, y[j]))); }
    for i in (0..n).rev() { z[i] = (y[i] - acc(f.u[i].iter().filter(|e| e.0 > i).map(|&(j, v)| (v, z[j])))) / f.d[i]; }
    z
}
fn mv(a: &[Row], x: &[f64]) -> Vec<f64> { a.iter().map(|row| acc(row.iter().map(|&(j, v)| (v, x[j])))).collect() }
fn dot(a: &[f64], c: &[f64]) -> f64 { acc(a.iter().zip(c).map(|(&s, &t)| (s, t))) }
fn rel(a: &[Row], b: &[f64], x: &[f64]) -> f64 { let r: Vec<f64> = b.iter().zip(mv(a, x)).map(|(s, t)| s - t).collect(); (dot(&r, &r) / dot(b, b)).sqrt() }
fn nnz(f: &Fac) -> usize { f.l.iter().zip(&f.u).map(|(l, u)| l.len() + u.len()).sum() }
fn prec(f: Option<&Fac>, r: &[f64]) -> Vec<f64> { match f { Some(f) => solve(f, r), None => r.to_vec() } }
fn pcg(a: &[Row], b: &[f64], f: Option<&Fac>, steps: usize) -> (Option<usize>, Vec<f64>, Vec<f64>) {
    let (mut x, mut r, mut count, mut xs, mut hist) = (vec![0.0; b.len()], b.to_vec(), None, vec![], vec![0.0]);
    let mut z = prec(f, &r); let mut p = z.clone(); let mut rz = dot(&r, &z);
    for k in 1..=steps {
        let q = mv(a, &p); let al = rz / dot(&p, &q);
        x = x.iter().zip(&p).map(|(s, t)| s + al * t).collect(); r = r.iter().zip(&q).map(|(s, t)| s - al * t).collect();
        if count.is_none() && dot(&r, &r) <= 1e-16 * dot(b, b) { count = Some(k); xs = x.clone(); }
        if k % 10 == 0 { hist.push(rel(a, b, &x).log10()); }
        z = prec(f, &r); let old = rz; rz = dot(&r, &z);
        p = z.iter().zip(&p).map(|(s, t)| s + rz / old * t).collect();
    }
    (count, xs, hist)
}
fn bicgstab(a: &[Row], b: &[f64], f: Option<&Fac>) -> Option<usize> {
    let n = b.len(); let (mut x, mut r, rh) = (vec![0.0; n], b.to_vec(), b.to_vec());
    let (mut rho, mut al, mut om, mut v, mut p) = (1.0, 1.0, 1.0, vec![0.0; n], vec![0.0; n]);
    for k in 1..300 {
        let old = rho; rho = dot(&rh, &r); let be = rho / old * al / om;
        p = (0..n).map(|i| r[i] + be * (p[i] - om * v[i])).collect(); let ph = prec(f, &p); v = mv(a, &ph);
        al = rho / dot(&rh, &v); let s: Vec<f64> = (0..n).map(|i| r[i] - al * v[i]).collect();
        let sh = prec(f, &s); let t = mv(a, &sh); om = dot(&t, &s) / dot(&t, &t);
        x = (0..n).map(|i| x[i] + al * ph[i] + om * sh[i]).collect(); r = (0..n).map(|i| s[i] - om * t[i]).collect();
        if dot(&r, &r) <= 1e-16 * dot(b, b) { return Some(k); }
    }
    None
}
fn fmt(xs: &[f64]) -> String { xs.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(" ") }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn fac(r: (Result<Fac, (usize, f64)>, HashMap<(usize, usize), f64>, u64)) -> Fac { r.0.ok().unwrap() }
fn main() {
    let (a4, _, _) = grid(4, false, 0.0); let (f4r, drop4, _) = ilu(&a4, 0, 0.0, false, 0.0);
    let (f4, e4) = (f4r.ok().unwrap(), fac(ilu(&a4, 99, 0.0, false, 0.0)));
    println!("4 by 4 grid: 16 unknowns, {} nonzeros in A", a4.iter().map(|r| r.len()).sum::<usize>());
    println!("first fill: row 2, column 5 gets 0 - (-1)(-1)/4 = {:.4}, dropped by IC(0)", drop4[&(1, 4)]);
    println!("IC(0) pivots: {}", fmt(&f4.d)); println!("exact pivots: {}", fmt(&e4.d));
    let mut offs: Vec<usize> = drop4.keys().map(|&(i, j)| i.abs_diff(j)).collect(); offs.sort(); offs.dedup();
    let sizes: Vec<f64> = drop4.values().map(|v| v.abs()).collect();
    println!("dropped fill: {} entries, all {} places off the diagonal, sizes {:.4} to {:.4}", drop4.len(), offs[0],
             sizes.iter().cloned().fold(f64::MAX, f64::min), sizes.iter().cloned().fold(0.0, f64::max));
    let r4 = |i: usize, j: usize| get(&a4[i], j) - get(&f4.u[i], j) - acc(f4.l[i].iter().map(|&(k, v)| (v, get(&f4.u[k], j))));
    let on = (0..16).flat_map(|i| a4[i].iter().map(move |e| (i, e.0))).map(|(i, j)| r4(i, j).abs()).fold(0.0, f64::max);
    let off = (0..256).map(|q| (r4(q / 16, q % 16) - drop4.get(&(q / 16, q % 16)).unwrap_or(&0.0)).abs()).fold(0.0, f64::max);
    println!("A - LU below 1e-14 on the pattern: {}; equal to the dropped fill off it: {}", yn(on < 1e-14), yn(off < 1e-14));
    let mut fig: Vec<&(usize, usize)> = drop4.keys().filter(|p| p.0 < p.1).collect(); fig.sort();
    println!("figure, 16 by 16 pattern, dropped fill at {}", fig.iter().map(|p| format!("{}:{}", p.0 + 1, p.1 + 1)).collect::<Vec<_>>().join(" "));
    println!("grid   unknowns   CG  IC(0)  MIC(0)  IC(1)  IC(0) red-black");
    let (mut a, mut b, mut idx, mut runs) = (vec![], vec![], vec![], vec![]);
    let (mut ff, mut mm, mut ffl, mut mfl) = (None, None, 0, 0);
    for m in [15, 31, 63] {
        (a, b, idx) = grid(m, false, 0.0); let (ar, br, _) = grid(m, true, 0.0);
        let (f, _, fl1) = ilu(&a, 0, 0.0, false, 0.0); let (mo, _, fl2) = ilu(&a, 0, 0.0, true, 0.0);
        let (f, mo, f1, fr) = (f.ok().unwrap(), mo.ok().unwrap(), fac(ilu(&a, 1, 0.0, false, 0.0)), fac(ilu(&ar, 0, 0.0, false, 0.0)));
        runs = vec![pcg(&a, &b, None, 130), pcg(&a, &b, Some(&f), 130), pcg(&a, &b, Some(&mo), 130),
                    pcg(&a, &b, Some(&f1), 130), pcg(&ar, &br, Some(&fr), 130)];
        println!("{:>4} {:>10} {}", m, m * m, runs.iter().map(|r| format!("{:>5}", r.0.unwrap())).collect::<Vec<_>>().join(" "));
        (ff, mm, ffl, mfl) = (Some(f), Some(mo), fl1, fl2);
    }
    let (f, mo, c) = (ff.unwrap(), mm.unwrap(), |q: usize| runs[q].0.unwrap());
    let mut d = vec![0.0; 63 * 63]; // second road to the IC(0) pivots: the grid recurrence
    for q in 0..63 * 63 { d[q] = 4.0 - if q % 63 > 0 { 1.0 / d[q - 1] } else { 0.0 } - if q >= 63 { 1.0 / d[q - 63] } else { 0.0 }; }
    let gap = (0..63 * 63).map(|q| (d[q] - f.d[idx[q]]).abs()).fold(0.0, f64::max);
    println!("IC(0) pivots by the grid recurrence d = 4 - 1/d(west) - 1/d(south): agree to 1e-12: {}", yn(gap < 1e-12));
    let (n, nz) = (63 * 63, a.iter().map(|r| r.len()).sum::<usize>()); let (cg_step, pc_step) = (2 * nz + 10 * n, 4 * nz + 9 * n);
    println!("63 by 63: n = {}, nonzeros {}; IC(1) factor {}; IC(0) factor costs {} flops, MIC(0) {}", n, nz, nnz(&fac(ilu(&a, 1, 0.0, false, 0.0))), ffl, mfl);
    println!("flops per step: CG {}, preconditioned CG {}", cg_step, pc_step);
    let tot = [c(0) * cg_step, c(1) * pc_step + ffl as usize, c(2) * pc_step + mfl as usize];
    println!("flops to 1e-8: CG {}, IC(0) {}, MIC(0) {}", tot[0], tot[1], tot[2]);
    for (name, r) in ["CG", "IC(0)", "MIC(0)"].iter().zip(&runs) {
        println!("chart, {:<6} log10 relative residual, steps 0 to 120 by 10: {}", name, r.2[..13].iter().map(|v| format!("{:.2}", v)).collect::<Vec<_>>().join(" "));
    }
    let (mid, xc, xi) = (idx[31 * 63 + 31], &runs[0].1, &runs[1].1);
    let kap = ((63.0 * std::f64::consts::PI / 128.0).sin() / (std::f64::consts::PI / 128.0).sin()).powi(2);
    let (diff, top) = (xc.iter().zip(xi).map(|(s, t)| (s - t).abs()).fold(0.0, f64::max), xc.iter().map(|v| v.abs()).fold(0.0, f64::max));
    println!("centre temperature: CG {:.4} C, IC(0) {:.4} C; largest gap {:.2e} of the peak {:.4} C", xc[mid], xi[mid], diff / top, top);
    println!("condition number of A: {:.1}; bound on each answer's relative error {:.8}", kap, kap * 1e-8);
    let (a15, b15, _) = grid(15, false, 0.0); let c15 = pcg(&a15, &b15, Some(&fac(ilu(&a15, 99, 0.0, false, 0.0))), 1).0;
    println!("15 by 15 with the full factor (no dropping): {} step", c15.unwrap());
    println!("estimate, 1023 by 1023: CG {}, IC(0) {}, MIC(0) {} steps", c(0) * 16, c(1) * 16, c(2) * 4);
    let k: Vec<Row> = vec![vec![(0, 3.0), (1, -2.0), (3, 2.0)], vec![(0, -2.0), (1, 3.0), (2, -2.0)],
                           vec![(1, -2.0), (2, 3.0), (3, -2.0)], vec![(0, 2.0), (2, -2.0), (3, 3.0)]];
    let fails = ilu(&k, 0, 0.0, false, 0.0).0.err().unwrap(); let (s1, s2) = (ilu(&k, 0, 0.0, false, 0.1).0, fac(ilu(&k, 0, 0.0, false, 0.2)));
    println!("Kershaw: IC(0) pivot {} comes out {:.4}; exact pivots {}", fails.0 + 1, fails.1, fmt(&fac(ilu(&k, 99, 0.0, false, 0.0)).d));
    println!("Kershaw shifted 10%: {}; 20%: pivots {}", if s1.is_err() { "breaks" } else { "works" }, fmt(&s2.d));
    let g = fac(ilu(&a, 99, 0.01, false, 0.0)); let ct = pcg(&a, &b, Some(&g), 130);
    println!("CG with a threshold factor (tau 0.01, not symmetric): no pass in 130 steps, log10 residual {:.2}", ct.2[ct.2.len() - 1]);
    let mic_gap = solve(&mo, &a.iter().map(|r| r.iter().map(|e| e.1).sum()).collect::<Vec<f64>>()).iter().map(|v| (v - 1.0).abs()).fold(0.0, f64::max);
    println!("MIC(0) keeps row sums: M^-1 (A times ones) = ones to 1e-12: {}", yn(mic_gap < 1e-12));
    let (aw, bw, _) = grid(63, false, 0.5); let mut out = vec![(bicgstab(&aw, &bw, None).unwrap(), nz)];
    for (lev, tau) in [(0, 0.0), (1, 0.0), (99, 1e-2), (99, 1e-3)] {
        let fw = fac(ilu(&aw, lev, tau, false, 0.0)); out.push((bicgstab(&aw, &bw, Some(&fw)).unwrap(), nnz(&fw)));
    }
    println!("plate with flow, BiCGSTAB steps (factor nonzeros): none, ILU(0), ILU(1), tau 1e-2, tau 1e-3: {}",
             out.iter().map(|o| format!("{} ({})", o.0, o.1)).collect::<Vec<_>>().join(", "));
    assert!(drop4[&(1, 4)] == -0.25 && offs == vec![3] && drop4.len() == 18 && on < 1e-14 && off < 1e-14);
    assert!(f4.d.iter().zip(&e4.d).all(|(s, t)| *s >= t - 1e-12) && gap < 1e-12);
    assert!(c(0) > 2 * c(1) && 2 * c(1) > 2 * c(2) && c(4) > c(1) && c15 == Some(1));
    assert!(diff < 2.0 * kap * 1e-8 * top && mic_gap < 1e-12 && tot[2] < tot[1] && tot[1] < tot[0]);
    assert!(fails.0 == 3 && fails.1 < 0.0 && s1.is_err() && s2.d.iter().cloned().fold(f64::MAX, f64::min) > 0.0);
    assert!(ct.0.is_none() && out[1].1 == nz && out[0].0 > out[1].0 && out[1].0 > out[2].0 && out[2].0 > out[3].0);
    println!("ALL CHECKS PASS");
}
