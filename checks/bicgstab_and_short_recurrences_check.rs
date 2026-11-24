// BiCGSTAB and short recurrences -- the check behind the card.  Rust std only.
// Card 03-10's road network by five Krylov methods; a rush hour; an 8-link ring.
use std::sync::atomic::{AtomicUsize, Ordering::Relaxed};
static FL: AtomicUsize = AtomicUsize::new(0); // counts flops as they happen
type Op<'a> = &'a dyn Fn(&[f64]) -> Vec<f64>;
type Pairs = Vec<(Vec<f64>, Vec<f64>, f64)>; type Steps = Vec<(f64, f64, f64)>;
fn nxt(st: &mut u64) -> u64 { // SplitMix64, written out
    *st = st.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*st ^ (*st >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB); z ^ (z >> 31)
}
fn unif(st: &mut u64) -> f64 { (nxt(st) >> 11) as f64 / 9007199254740992.0 }
fn sci(v: f64) -> String { format!("{:.3e}", v) }
fn commas(v: usize) -> String { let d = v.to_string(); d.chars().enumerate().map(|(i, c)| if i > 0 && (d.len() - i) % 3 == 0 { format!(",{}", c) } else { c.to_string() }).collect() }
fn dot(u: &[f64], v: &[f64]) -> f64 { FL.fetch_add(2 * u.len(), Relaxed); let mut acc = 0.0; for (a, b) in u.iter().zip(v) { acc += a * b; } acc }
fn axpy(a: f64, x: &[f64], y: &[f64]) -> Vec<f64> { FL.fetch_add(2 * x.len(), Relaxed); x.iter().zip(y).map(|(p, q)| a * p + q).collect() }
fn nrm(v: &[f64]) -> f64 { dot(v, v).sqrt() }
fn mul(a: &[f64], b: &[f64]) -> Vec<f64> { a.iter().zip(b).map(|(p, q)| p * q).collect() }
fn top(h: &[f64]) -> f64 { h.iter().cloned().fold(f64::MIN, f64::max) }
struct Net { n: usize, t: Vec<f64>, e: Vec<f64>, s: Vec<f64>, ptr: Vec<usize>, col: Vec<usize>, val: Vec<f64> }
impl Net {
    fn b(&self, v: &[f64]) -> Vec<f64> { // B = A M^-1: scale by t, then A
        FL.fetch_add(2 * self.val.len() + self.n, Relaxed); let x = mul(&self.t, v);
        (0..self.n).map(|i| { let mut acc = 0.0; for p in self.ptr[i]..self.ptr[i + 1] { acc += self.val[p] * x[self.col[p]]; } acc }).collect()
    }
    fn bt(&self, v: &[f64]) -> Vec<f64> { // B^T = M^-1 A^T: A^T first, then scale
        FL.fetch_add(2 * self.val.len() + self.n, Relaxed); let mut y = vec![0.0; self.n];
        for i in 0..self.n { for p in self.ptr[i]..self.ptr[i + 1] { y[self.col[p]] += self.val[p] * v[i]; } } mul(&self.t, &y)
    }
}
fn network(lo: f64, span: f64, st: &mut u64) -> Net { // card 03-10's network; exits lo..lo+span
    let (rr, cc) = (250i64, 200i64); let n = (rr * cc) as usize; *st = 20261111;
    let off = [(0i64, 1i64), (0, -1), (1, 0), (-1, 0), (1, -1), (-1, 1)]; // k ^ 1 reverses k
    let nb: Vec<[usize; 6]> = (0..n as i64).map(|i| { let mut a = [0usize; 6]; for (k, (dr, dc)) in off.iter().enumerate() {
            a[k] = (((i / cc + dr).rem_euclid(rr)) * cc + (i % cc + dc).rem_euclid(cc)) as usize; } a }).collect();
    let (mut t, mut e, mut w, mut s) = (vec![0.0; n], vec![0.0; n], vec![[0.0; 6]; n], vec![0.0; n]);
    for j in 0..n { // illustrative traffic numbers
        t[j] = [1.0, 2.0, 5.0, 10.0, 30.0][(nxt(st) % 5) as usize]; e[j] = lo + span * unif(st);
        let g: Vec<f64> = (0..6).map(|_| 0.5 + unif(st)).collect(); let tot = dot(&g, &[1.0; 6]); for k in 0..6 { w[j][k] = (1.0 - e[j]) * g[k] / tot; } s[j] = 0.5 + unif(st);
    }
    let (mut ptr, mut col, mut val) = (vec![0usize], vec![], vec![]); // compressed sparse rows of A
    for i in 0..n { col.push(i); val.push(1.0 / t[i]); for k in 0..6 { let j = nb[i][k]; col.push(j); val.push(-w[j][k ^ 1] / t[j]); } ptr.push(col.len()); }
    Net { n, t, e, s, ptr, col, val }
}
fn gmres(op: Op, b: &[f64], tol: f64, kmax: usize) -> (Vec<f64>, Vec<f64>, usize) { // card 03-10's GMRES
    let bn = nrm(b); FL.fetch_add(b.len(), Relaxed); let mut q: Vec<Vec<f64>> = vec![b.iter().map(|v| v / bn).collect()];
    let (mut hh, mut cs, mut sn, mut g, mut hist): (Vec<Vec<f64>>, Vec<f64>, Vec<f64>, Vec<f64>, Vec<f64>) = (vec![], vec![], vec![], vec![bn], vec![1.0]);
    for k in 0..kmax {
        let (mut w, mut h) = (op(&q[k]), vec![]);
        for qj in &q { let hj = dot(&w, qj); h.push(hj); w = axpy(-hj, qj, &w); } h.push(nrm(&w));
        for j in 0..k { let (a, c) = (h[j], h[j + 1]); h[j] = cs[j] * a + sn[j] * c; h[j + 1] = -sn[j] * a + cs[j] * c; }
        let r = (h[k] * h[k] + h[k + 1] * h[k + 1]).sqrt(); let hk = if h[k + 1] != 0.0 { h[k + 1] } else { 1.0 };
        cs.push(h[k] / r); sn.push(h[k + 1] / r); FL.fetch_add(b.len(), Relaxed); q.push(w.iter().map(|v| v / hk).collect());
        h[k] = r; g.push(-sn[k] * g[k]); g[k] = cs[k] * g[k]; hh.push(h); hist.push(g[k + 1].abs() / bn);
        if hist[k + 1] < tol { break; }
    }
    let (m, mut u) = (hh.len(), vec![0.0; b.len()]); let mut y = vec![0.0; m];
    for i in (0..m).rev() { let mut acc = g[i]; for j in i + 1..m { acc -= hh[j][i] * y[j]; } y[i] = acc / hh[i][i]; } // back-substitute
    for j in 0..m { u = axpy(y[j], &q[j], &u); } let k = hist.len() - 1; (u, hist, k)
}
fn restarted(op: Op, b: &[f64], m: usize, tol: f64, pmax: usize) -> (Vec<f64>, Vec<f64>, usize) { // GMRES(m)
    let (mut u, mut r, mut hist, mut prods, bn) = (vec![0.0; b.len()], b.to_vec(), vec![1.0], 0, nrm(b));
    while hist[hist.len() - 1] >= tol && prods < pmax {
        let (du, h, _) = gmres(op, &r, tol * bn / nrm(&r), m); u = axpy(1.0, &du, &u);
        r = axpy(-1.0, &op(&u), b); prods += h.len(); hist.push(nrm(&r) / bn);
    }
    (u, hist, prods)
}
fn bicg(op: Op, opt: Op, b: &[f64], rt0: &[f64], tol: f64, kmax: usize) -> (Vec<f64>, Vec<f64>, Pairs, String) { // two-sided Lanczos
    let (mut u, mut r, mut p, mut pt, mut rt) = (vec![0.0; b.len()], b.to_vec(), b.to_vec(), rt0.to_vec(), rt0.to_vec());
    let (mut h, bn, mut keep) = (vec![1.0], nrm(b), vec![(b.to_vec(), rt0.to_vec(), 0.0)]); let mut rho = dot(rt0, b);
    for k in 0..kmax {
        let v = op(&p); let d = dot(&pt, &v);
        if d == 0.0 { return (u, h, keep, format!("breakdown at step {}", k + 1)); }
        let al = rho / d; u = axpy(al, &p, &u); r = axpy(-al, &v, &r); rt = axpy(-al, &opt(&pt), &rt);
        let rn = dot(&rt, &r); let be = rn / rho; rho = rn; p = axpy(be, &p, &r); pt = axpy(be, &pt, &rt); h.push(nrm(&r) / bn);
        if k < 5 { keep.push((r.clone(), rt.clone(), al)); } // the first six pairs, for the check
        if h[h.len() - 1] < tol { break; }
    }
    (u, h, keep, "ok".to_string())
}
fn cgs(op: Op, b: &[f64], tol: f64, kmax: usize) -> (Vec<f64>, Vec<f64>) { // Sonneveld: BiCG squared
    let (mut u, mut r, mut w, mut p, mut h, bn) = (vec![0.0; b.len()], b.to_vec(), b.to_vec(), b.to_vec(), vec![1.0], nrm(b)); let mut rho = dot(b, b);
    for _ in 0..kmax {
        let v = op(&p); let al = rho / dot(b, &v); let q = axpy(-al, &v, &w); let w2 = axpy(1.0, &q, &w);
        u = axpy(al, &w2, &u); r = axpy(-al, &op(&w2), &r); let rn = dot(b, &r); let be = rn / rho; rho = rn;
        w = axpy(be, &q, &r); p = axpy(be, &axpy(be, &p, &q), &w); h.push(nrm(&r) / bn);
        if h[h.len() - 1] < tol { break; }
    }
    (u, h)
}
fn bicgstab(op: Op, b: &[f64], rt: &[f64], tol: f64, kmax: usize) -> (Vec<f64>, Vec<f64>, Steps, String) { // van der Vorst
    let (mut u, mut r, mut p, mut h, bn, mut steps) = (vec![0.0; b.len()], b.to_vec(), b.to_vec(), vec![1.0], nrm(b), vec![]); let mut rho = dot(rt, b);
    for k in 0..kmax {
        let v = op(&p); let d = dot(rt, &v);
        if d == 0.0 { return (u, h, steps, format!("breakdown at step {}", k + 1)); }
        let al = rho / d; let sv = axpy(-al, &v, &r); let tv = op(&sv); let om = dot(&tv, &sv) / dot(&tv, &tv);
        u = axpy(om, &sv, &axpy(al, &p, &u)); r = axpy(-om, &tv, &sv); let rn = dot(rt, &r);
        let be = rn / rho * al / om; rho = rn; p = axpy(be, &axpy(-om, &v, &p), &r); h.push(nrm(&r) / bn); steps.push((al, om, nrm(&sv) / bn));
        if h[h.len() - 1] < tol { break; }
    }
    (u, h, steps, "ok".to_string())
}
struct Out { h: Vec<Vec<f64>>, x: Vec<Vec<f64>>, steps: Steps, keep: Pairs }
fn run(net: &Net, label: &str) -> Out { // all five methods on one network
    let (n, s, bop, btop) = (net.n, &net.s, |v: &[f64]| net.b(v), |v: &[f64]| net.bt(v));
    let mut o = Out { h: vec![], x: vec![], steps: vec![], keep: vec![] };
    for nm in ["gmres", "gmres5", "bicg", "cgs", "bicgstab"] {
        FL.store(0, Relaxed);
        let (u, h, pr, vec) = match nm {
            "gmres" => { let (u, h, k) = gmres(&bop, s, 1e-10, 200); let v = h.len() + 2; (u, h, k, v) }
            "gmres5" => { let (u, h, p) = restarted(&bop, s, 5, 1e-10, 400); (u, h, p, 9) }
            "bicg" => { let (u, h, kp, _) = bicg(&bop, &btop, s, s, 1e-10, 200); o.keep = kp; let p = 2 * (h.len() - 1); (u, h, p, 8) }
            "cgs" => { let (u, h) = cgs(&bop, s, 1e-10, 200); let p = 2 * (h.len() - 1); (u, h, p, 9) }
            _ => { let (u, h, st, _) = bicgstab(&bop, s, s, 1e-10, 200); o.steps = st; let p = 2 * (h.len() - 1); (u, h, p, 8) }
        };
        let (fl, x) = (FL.load(Relaxed), mul(&net.t, &u)); let tr = nrm(&axpy(-1.0, &net.b(&u), s)) / nrm(s);
        println!("{},{},products={},residual={},true={},vectors={},bytes={},flops={}", label, nm, pr, sci(h[h.len() - 1]), sci(tr), vec, commas(8 * n * vec), commas(fl));
        assert!(tr < 3e-10 && h[h.len() - 1] < 1e-10);
        o.h.push(h); o.x.push(x);
    }
    let (hg, hb, hc, hs) = (&o.h[0], &o.h[2], &o.h[3], &o.h[4]);
    for j in 1..hg.len() { // GMRES is best at equal powers of B
        assert!(j >= hb.len() || hg[j] <= hb[j] * (1.0 + 1e-9));
        assert!(2 * j >= hg.len() || j >= hc.len() || hg[2 * j] <= hc[j] * (1.0 + 1e-9));
        assert!(2 * j >= hg.len() || j >= hs.len() || hg[2 * j] <= hs[j] * (1.0 + 1e-9));
    }
    let gap = top(&o.x[4].iter().zip(&o.x[0]).map(|(a, c)| (a - c).abs() / c).collect::<Vec<f64>>()); assert!(gap < 1e-8 && (0..o.steps.len()).all(|k| hs[k + 1] <= o.steps[k].2 * (1.0 + 1e-12))); // never above the half step
    println!("{},bicgstab_vs_gmres_max_rel_gap={},cars={:.1},links={},bytes_per_vector={},gmres_basis_bytes={}", label, sci(gap), dot(&o.x[4], &vec![1.0; n]), commas(n), commas(8 * n), commas(8 * n * hg.len()));
    o
}
fn main() {
    let mut st = 0u64;
    let net = network(0.3, 0.2, &mut st); let easy = run(&net, "easy");
    let (n, s, t, e, one) = (net.n, &net.s, &net.t, &net.e, vec![1.0; net.n]);
    let (stp, keep, bn2, bs) = (&easy.steps, &easy.keep, dot(s, s), net.b(s)); let sb = dot(s, &bs); let hv = axpy(-bn2 / sb, &bs, s); let bh = net.b(&hv); let r1 = axpy(-stp[0].1, &bh, &hv);
    assert!((stp[0].0 - bn2 / sb).abs() < 1e-12 && (stp[0].2 - nrm(&hv) / bn2.sqrt()).abs() < 1e-12 && dot(&bh, &r1).abs() < 1e-10 * nrm(&bh) * nrm(&hv)); // best omega: r1 at right angles to B h
    println!("step1,s.s={:.4},s.Bs={:.4},Bs.Bs={:.4},alpha={:.6},half_step={:.6},omega={:.6},full_step={:.6},gmres_2={:.6}", bn2, sb, dot(&bs, &bs), stp[0].0, stp[0].2, stp[0].1, easy.h[4][1], easy.h[0][2]);
    let x = &easy.x[4]; let xt: Vec<f64> = x.iter().zip(t).map(|(a, c)| a / c).collect(); let (cin, cout) = (dot(s, &one), dot(e, &xt));
    assert!((cin - cout).abs() < 1e-8 * cin && (dot(x, &one) - 1214445.5).abs() < 0.1); // card 03-10
    println!("balance,cars_in_per_min={:.4},cars_out_per_min={:.4}", cin, cout);
    let mut bio = f64::MIN; for i in 0..6 { for j in 0..6 { if i != j { bio = bio.max(dot(&keep[i].1, &keep[j].0).abs() / nrm(&keep[i].1) / nrm(&keep[j].0)); } } } let ag = top(&(0..5).map(|k| (keep[k + 1].2 - stp[k].0).abs() / stp[k].0.abs()).collect::<Vec<f64>>());
    let z: Vec<f64> = (0..n).map(|_| unif(&mut st)).collect(); let (a1, a2) = (net.b(&net.bt(&z)), net.bt(&net.b(&z)));
    let nn = nrm(&axpy(-1.0, &a2, &a1)) / nrm(&a1); assert!(bio < 1e-10 && nn > 0.01 && ag < 1e-8);
    println!("lanczos,max_cos_between_shadow_i_and_residual_j={},alpha_gap_bicg_vs_bicgstab={},non_normal_gap={:.4}", sci(bio), sci(ag), nn); println!("products,gmres,bicg,cgs,bicgstab");
    for p in (0..25).step_by(4) {
        let cells: Vec<String> = [(0, p), (2, p / 2), (3, p / 2), (4, p / 2)].iter()
            .map(|&(m, q)| if q < easy.h[m].len() { sci(easy.h[m][q]) } else { "-".to_string() }).collect();
        println!("{},{}", p, cells.join(","));
    }
    let rush = run(&network(0.02, 0.03, &mut st), "rush");
    for (nm, m) in [("bicg", 2), ("cgs", 3), ("bicgstab", 4)] { // count rises; find the worst
        let h = &rush.h[m]; println!("rush,{},rises={},largest={}", nm, (1..h.len()).filter(|&k| h[k] > h[k - 1]).count(), sci(top(&h[1..])));
    }
    assert!(top(&rush.h[3][1..]) > 10.0 && top(&rush.h[4][1..]) < 1.0);
    let ps: Vec<String> = (0..77).step_by(4).map(|p: usize| p.to_string()).collect(); println!("chart,products,{}", ps.join(","));
    for (nm, m, d) in [("gmres", 0, 1), ("cgs", 3, 2), ("bicgstab", 4, 2)] {
        let pts: Vec<String> = (0..77).step_by(4).map(|p: usize| format!("{:.2}", rush.h[m][p / d].log10())).collect();
        println!("chart,{},{}", nm, pts.join(","));
    }
    let nr = 8; let ring = |v: &[f64]| { let mut w = vec![v[nr - 1]]; w.extend_from_slice(&v[..nr - 1]); w };
    let ringt = |v: &[f64]| { let mut w = v[1..].to_vec(); w.push(v[0]); w }; let mut e1 = vec![0.0; nr]; e1[0] = 1.0; // the shift Z: entry i moves to i + 1
    let hf = gmres(&ring, &e1, 1e-12, nr).1; let (_, hr, pr) = restarted(&ring, &e1, 4, 1e-12, 40);
    let (why, why2) = (bicg(&ring, &ringt, &e1, &e1, 1e-12, nr).3, bicgstab(&ring, &e1, &e1, 1e-12, nr).3);
    assert!(top(&hf[1..nr]) == 1.0 && hf[nr] < 1e-15 && hr[hr.len() - 1] == 1.0 && why == "breakdown at step 1" && why2 == why);
    println!("ring,gmres_full_residual_after_7={:.6},after_8={},gmres4_after_{}_products={:.6}", hf[7], sci(hf[nr]), pr, hr[hr.len() - 1]);
    let normal = (0..nr).all(|i| { let mut v = vec![0.0; nr]; v[i] = 1.0; ring(&ringt(&v)) == ringt(&ring(&v)) });
    println!("ring,bicg={},bicgstab={},shadow.Bp={:.1},normal={}", why, why2, dot(&e1, &ring(&e1)), if normal { "True" } else { "False" });
    println!("ALL CHECKS PASS");
}
