// Graphical models -- the check behind the card.  Rust std only.
// Same network, same three roads, same printout as the Python check.
// A factor is (variables, table), read as table[x0 + 2*x1 + 4*x2 + ...].
type Fac = (Vec<usize>, Vec<f64>);
fn cpt(p1: &[f64]) -> Vec<f64> { p1.iter().map(|p| 1.0 - p).chain(p1.iter().cloned()).collect() }
fn val(f: &Fac, x: &[usize]) -> f64 { f.1[f.0.iter().enumerate().map(|(j, &v)| x[v] << j).sum::<usize>()] }
fn fac(v: &[usize], t: Vec<f64>) -> Fac { (v.to_vec(), t) }
fn f6(xs: &[f64]) -> String { xs.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(" ") }
fn commas(n: u64) -> String { let s = n.to_string(); let mut o = String::new();
    for (i, c) in s.chars().enumerate() { if i > 0 && (s.len() - i) % 3 == 0 { o.push(','); } o.push(c); } o }
fn brute(n: usize, f: &[Fac], ev: &[(usize, usize)]) -> (f64, Vec<f64>, u64) {
    let (mut tot, mut one, mut terms) = (0.0, vec![0.0; n], 0u64);
    for s in 0..(1usize << n) {
        let x: Vec<usize> = (0..n).map(|i| (s >> i) & 1).collect();
        if ev.iter().any(|&(v, e)| x[v] != e) { continue; }
        let mut w = 1.0;
        for g in f { w *= val(g, &x); }
        terms += 1; tot += w;
        for i in 0..n { one[i] += w * x[i] as f64; }
    }
    (tot, one.iter().map(|o| o / tot).collect(), terms * (f.len() as u64 - 1))
}
fn assign(vs: &[usize], k: usize, x: &mut [usize]) { for (j, &u) in vs.iter().enumerate() { x[u] = (k >> j) & 1; } }
fn restrict(f: &Fac, ev: &[(usize, usize)]) -> Fac {
    let keep: Vec<usize> = f.0.iter().cloned().filter(|v| !ev.iter().any(|e| e.0 == *v)).collect();
    let mut x = vec![0; 64]; for &(v, e) in ev { x[v] = e; }
    let out = (0..1usize << keep.len()).map(|k| { assign(&keep, k, &mut x); val(f, &x) }).collect();
    (keep, out)
}
fn ve(f: &[Fac], order: &[usize], ev: &[(usize, usize)]) -> (f64, f64, u64, usize) {
    let mut fs: Vec<Fac> = f.iter().map(|g| restrict(g, ev)).collect();
    let (mut mults, mut big, mut x) = (0u64, 0usize, vec![0; 64]);
    for &v in order {
        let (usef, rest): (Vec<Fac>, Vec<Fac>) = fs.into_iter().partition(|g| g.0.contains(&v));
        let mut vs: Vec<usize> = usef.iter().flat_map(|g| g.0.iter().cloned()).filter(|&u| u != v).collect();
        vs.sort(); vs.dedup();
        let mut t = Vec::new();
        for k in 0..(1usize << vs.len()) {
            assign(&vs, k, &mut x); let mut s = 0.0;
            for xv in 0..2 {
                x[v] = xv; let mut w = 1.0;
                for g in &usef { w *= val(g, &x); }
                s += w; mults += usef.len() as u64 - 1;
            }
            t.push(s);
        }
        big = big.max(t.len()); fs = rest; fs.push((vs, t));
    }
    let mut p = [1.0, 1.0];
    for (vs, t) in &fs { for xq in 0..2 { p[xq] *= if vs.is_empty() { t[0] } else { t[xq] }; } }
    (p[1] / (p[0] + p[1]), p[0] + p[1], mults + 2 * (fs.len() as u64 - 1), big)
}
fn bp(n: usize, f: &[Fac], rounds: usize) -> Vec<f64> {
    let nb: Vec<Vec<usize>> = (0..n).map(|v| (0..f.len()).filter(|&a| f[a].0.contains(&v)).collect()).collect();
    let edges: Vec<(usize, usize)> = (0..f.len()).flat_map(|a| f[a].0.iter().map(move |&v| (a, v))).collect();
    let id = |a: usize, v: usize| edges.iter().position(|&e| e == (a, v)).unwrap();
    let (mut fv, mut x) = (vec![[1.0f64, 1.0]; edges.len()], vec![0; 64]);
    let norm = |m: [f64; 2]| [m[0] / (m[0] + m[1]), m[1] / (m[0] + m[1])];
    for _ in 0..rounds {
        let mut vf = vec![[1.0f64, 1.0]; edges.len()];
        for (e, &(a, v)) in edges.iter().enumerate() {
            let mut m = [1.0, 1.0];
            for &b in &nb[v] { if b != a { let o = fv[id(b, v)]; m = [m[0] * o[0], m[1] * o[1]]; } }
            vf[e] = norm(m);
        }
        for (e, &(a, v)) in edges.iter().enumerate() {
            let (vs, t) = &f[a]; let mut m = [0.0, 0.0];
            for k in 0..(1usize << vs.len()) {
                assign(vs, k, &mut x); let mut w = t[k];
                for &u in vs { if u != v { w *= vf[id(a, u)][x[u]]; } }
                m[x[v]] += w;
            }
            fv[e] = norm(m);
        }
    }
    (0..n).map(|v| {
        let mut m = [1.0, 1.0];
        for &b in &nb[v] { let o = fv[id(b, v)]; m = [m[0] * o[0], m[1] * o[1]]; }
        m[1] / (m[0] + m[1])
    }).collect()
}
fn net(pt: f64, pb: f64, late: &[f64], alarm: &[f64]) -> Vec<Fac> {
    vec![fac(&[0], cpt(&[pt])), fac(&[1], cpt(&[pb])), fac(&[0, 1, 2], cpt(late)), fac(&[2, 3], cpt(alarm))]
}
const P: [[f64; 2]; 2] = [[0.99, 0.01], [0.49, 0.51]]; const NU: [f64; 2] = [0.98, 0.02];
fn chain(n: usize, ys: &[usize], em: &[f64; 2]) -> Vec<Fac> {
    let mut g = vec![fac(&[0], cpt(&[NU[1]]))];
    for k in 1..n { g.push(fac(&[k - 1, k], cpt(&[P[0][1], P[1][1]]))); }
    for k in 0..n { g.push(fac(&[k], if ys[k] == 0 { vec![1.0 - em[0], 1.0 - em[1]] } else { em.to_vec() })); }
    g
}
fn fwd_bwd(ys: &[usize], em: &[f64; 2]) -> (f64, Vec<f64>) {
    let e = |b: usize, y: usize| if y == 1 { em[b] } else { 1.0 - em[b] };
    let mut al = vec![[NU[0] * e(0, ys[0]), NU[1] * e(1, ys[0])]];
    for &y in &ys[1..] {
        let l = *al.last().unwrap();
        al.push([0, 1].map(|b| (0.0 + l[0] * P[0][b] + l[1] * P[1][b]) * e(b, y)));
    }
    let mut be = vec![[1.0, 1.0]];
    for &y in ys[1..].iter().rev() {
        let n = be[0];
        be.insert(0, [0, 1].map(|a| 0.0 + P[a][0] * e(0, y) * n[0] + P[a][1] * e(1, y) * n[1]));
    }
    let l = al[ys.len() - 1][0] + al[ys.len() - 1][1];
    (l, (0..ys.len()).map(|k| al[k][1] * be[k][1] / l).collect())
}
fn main() {
    let (late, alarm) = ([0.05, 0.40, 0.90, 0.95], [0.03, 0.90]);
    let f = net(0.10, 0.02, &late, &alarm);
    let (cl, ca) = (cpt(&late), cpt(&alarm));
    let g: Vec<f64> = (0..4).map(|k| { let (t, b) = (k % 2, k / 2); (0..2).map(|l| cl[t + 2 * b + 4 * l] * ca[l + 2]).fold(0.0, |s, w| s + w) }).collect();
    let h: Vec<f64> = (0..2).map(|b| 0.9 * g[2 * b] + 0.1 * g[2 * b + 1]).collect();
    println!("by hand: g(T,B) for (0,0) (1,0) (0,1) (1,1): {}; h(B): {}; P(B) h(B): {:.6} {:.6}", f6(&g), f6(&h), 0.98 * h[0], 0.02 * h[1]);
    let (z, mb, bm) = brute(4, &f, &[(3, 1)]);
    let (pv, zv, vm, _) = ve(&f, &[2, 0], &[(3, 1)]);
    let mut f2 = f.clone(); f2.push(fac(&[3], vec![0.0, 1.0]));
    let mbp = bp(4, &f2, 10);
    println!("P(alarm) = {:.6}; P(breakdown and alarm) = {:.6}; per 20,000 orders: {:.0} alarms, {:.0} of them breakdowns", z, z * mb[1], 20000.0 * z, 20000.0 * z * mb[1]);
    println!("P(breakdown | alarm): brute force {:.6}  elimination {:.6}  sum-product {:.6}", mb[1], pv, mbp[1]);
    println!("multiplications: brute force over 8 states {}, elimination {}\nall marginals given the alarm (T B L A): brute force {}", bm, vm, f6(&mb));
    println!("                                         sum-product {}", f6(&mbp));
    assert!((mb[1] - pv).abs() < 1e-12 && (z - zv).abs() < 1e-12 && (0.02 * h[1] - z * mb[1]).abs() < 1e-15);
    assert!(mb.iter().zip(&mbp).all(|(a, b)| (a - b).abs() < 1e-12));
    let (_, mt, _) = brute(4, &f, &[]); let ptb = brute(4, &f, &[(0, 1), (1, 1)]).0;
    let (et1, et0) = (brute(4, &f, &[(3, 1), (0, 1)]), brute(4, &f, &[(3, 1), (0, 0)]));
    println!("no evidence: P(T=1, B=1) = {:.6} = P(T=1) P(B=1) = {:.6}", ptb, mt[0] * mt[1]);
    println!("given the alarm: P(B=1 | A) = {:.6}; add traffic {:.6}; add no traffic {:.6}", mb[1], et1.1[1], et0.1[1]);
    println!("given the alarm: P(T=1, B=1 | A) = {:.6} against P(T|A) P(B|A) = {:.6}", brute(4, &f, &[(3, 1), (0, 1), (1, 1)]).0 / z, mb[0] * mb[1]);
    let gl: Vec<f64> = (0..4).map(|k| { let (t, b) = (k / 2, k % 2); brute(4, &f, &[(2, 1), (3, 1), (0, t), (1, b)]).0 / brute(4, &f, &[(2, 1), (0, t), (1, b)]).0 }).collect();
    println!("P(A=1 | L=1, T, B) for the four (T, B): {}", f6(&gl));
    assert!((ptb - mt[0] * mt[1]).abs() < 1e-15 && et1.1[1] < mb[1] && mb[1] < et0.1[1]);
    assert!(gl.iter().all(|g| (g - 0.9).abs() < 1e-12));
    let em = [ve(&f, &[2, 0], &[(1, 0)]).0, ve(&f, &[2, 0], &[(1, 1)]).0];
    let ys = [0, 1, 1, 0, 1];
    let (lw, fb) = fwd_bwd(&ys, &em); let (zw, bw, _) = brute(5, &chain(5, &ys, &em), &[]); let sw = bp(5, &chain(5, &ys, &em), 8);
    println!("alarm chance given the van: healthy {:.6}, faulty {:.6}", em[0], em[1]);
    println!("alarm week {:?}: chance of the week {:.8} (forward), {:.8} (all 32 weeks)", ys, lw, zw);
    println!("P(van faulty), Mon-Fri: forward-backward {}", f6(&fb));
    println!("                        sum-product      {}", f6(&sw));
    println!("                        all 32 weeks     {}", f6(&bw));
    assert!((lw - zw).abs() < 1e-15 && (0..5).all(|k| (fb[k] - sw[k]).abs() < 1e-12 && (fb[k] - bw[k]).abs() < 1e-12));
    for n in [5usize, 10, 20, 30] {
        let g = chain(n, &vec![1; n], &em); let order: Vec<usize> = (0..n - 1).collect(); let vn = ve(&g, &order, &[]).2;
        let bn = if n <= 10 { brute(n, &g, &[]).2 } else { (1u64 << n) * (2 * n as u64 - 1) };
        println!("chain of {:2} days: multiplications, brute force {}, elimination {}", n, commas(bn), vn);
        assert!((n > 10 || bn == (1u64 << n) * (2 * n as u64 - 1)) && vn == 8 * (n as u64 - 1) + 2);
    }
    let et = [ve(&f, &[3, 1], &[(0, 0)]).0, ve(&f, &[3, 1], &[(0, 1)]).0];   // P(late | traffic t)
    assert!((0..2).all(|t| (et[t] - brute(4, &f, &[(0, t), (2, 1)]).0 / brute(4, &f, &[(0, t)]).0).abs() < 1e-12));
    let mut hub = vec![fac(&[0], cpt(&[0.10]))];
    for i in 1..11 { hub.push(fac(&[0, i], cpt(&et))); }
    for i in 1..11 { hub.push(fac(&[i, 10 + i], cpt(&alarm))); }
    let ev: Vec<(usize, usize)> = (1..11).map(|i| (10 + i, (i <= 4) as usize)).collect();
    let (lo, hi): (Vec<usize>, Vec<usize>) = ((2..11).chain([0]).collect(), [0].into_iter().chain(2..11).collect());
    let (good, bad) = (ve(&hub, &lo, &ev), ve(&hub, &hi, &ev));
    println!("hub: P(order 1 late | its alarm and 3 of 9 others) = {:.6}; largest table: leaves first {}, hub first {}", good.0, good.3, bad.3);
    println!("hub: multiplications, leaves first {}, hub first {}", good.2, bad.2);
    assert!((good.0 - bad.0).abs() < 1e-12 && (good.0 - brute(21, &hub, &ev).1[1]).abs() < 1e-12 && bad.3 == 1024);
    let w = vec![fac(&[0], cpt(&[0.10])), fac(&[1], cpt(&[0.02])), fac(&[0, 1, 2], cpt(&late)), fac(&[0, 1, 3], cpt(&late)),
        fac(&[2, 4], cpt(&alarm)), fac(&[3, 5], cpt(&alarm)), fac(&[4], vec![0.0, 1.0]), fac(&[5], vec![0.0, 1.0])];
    let ex = brute(6, &w, &[(4, 1), (5, 1)]).1; let lp: Vec<f64> = [50, 51].iter().map(|&r| bp(6, &w, r)[1]).collect();
    println!("loop (two orders, same van): P(B=1 | both alarms) exact {:.6}, loopy sum-product {:.6}", ex[1], lp[0]);
    println!("wrong answers: unnormalised {:.6}; arrow read backwards P(A | B=1) {:.6}", z * mb[1], em[1]);
    assert!((lp[0] - lp[1]).abs() < 1e-12 && (lp[0] - ex[1]).abs() > 0.01);
    println!("try: false alarms 0.01: P(B | A) = {:.6}", ve(&net(0.10, 0.02, &late, &[0.01, 0.90]), &[2, 0], &[(3, 1)]).0);
    println!("try: traffic 0.30: P(B | A) = {:.6}", ve(&net(0.30, 0.02, &late, &alarm), &[2, 0], &[(3, 1)]).0);
    println!("try: alarm week [1, 1, 1, 1, 1]: P(faulty) {}", f6(&fwd_bwd(&[1, 1, 1, 1, 1], &em).1));
    println!("ALL CHECKS PASS");
}
