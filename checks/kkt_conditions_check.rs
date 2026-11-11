// KKT conditions -- the check behind the card, in Rust with std only.
// Two pumps feed a water network; x1, x2 are their powers in kW.  Minimise the
// running cost f0 = 0.3 x1^2 + 0.2 x2^2 pounds an hour, subject to
//   demand       h  = x1 + x2 - 10 = 0          (10 kW delivered in all)
//   node 1 cap   f1 = 10 + x1 + 4 x2 - 35 <= 0   (pressure head in metres)
//   node 2 cap   f2 = 10 + 3 x1 + x2 - 35 <= 0
// Road 1: every active set, its linear KKT system solved by elimination.
// Road 2: the dual bound, the Lagrangian minimised over every x, feasible or not.
// Road 3: a scan of the demand line in steps of 0.0001 kW.
const C: [f64; 2] = [0.3, 0.2];
const D: f64 = 10.0;
const BASE: f64 = 10.0;
const CAPS: [f64; 2] = [35.0, 35.0];
const A: [[f64; 2]; 2] = [[1.0, 4.0], [3.0, 1.0]]; // metres of head per kW, nodes 1 and 2
type Sol = ([f64; 2], [f64; 2], f64);

fn cost(x: [f64; 2]) -> f64 { C[0] * x[0].powi(2) + C[1] * x[1].powi(2) }
fn fi(i: usize, x: [f64; 2], caps: [f64; 2]) -> f64 { BASE + A[i][0] * x[0] + A[i][1] * x[1] - caps[i] }
fn v(x: [f64; 2]) -> String { format!("({:.4}, {:.4})", x[0], x[1]) }

fn solve(m: Vec<Vec<f64>>, b: Vec<f64>) -> Option<Vec<f64>> { // Gauss-Jordan, partial pivoting
    let n = b.len();
    let mut m: Vec<Vec<f64>> = m.into_iter().zip(b).map(|(mut r, bi)| { r.push(bi); r }).collect();
    for c in 0..n {
        let mut p = c;
        for r in c..n { if m[r][c].abs() > m[p][c].abs() { p = r; } }
        if m[p][c].abs() < 1e-12 { return None; }
        m.swap(c, p);
        for r in 0..n {
            if r != c {
                let f = m[r][c] / m[c][c];
                let pivot = m[c].clone();
                for (a, e) in m[r].iter_mut().zip(pivot) { *a -= f * e; }
            }
        }
    }
    Some((0..n).map(|r| m[r][n] / m[r][r]).collect())
}

fn kkt(active: &[usize], caps: [f64; 2], d: f64) -> Option<Sol> {
    let n = 3 + active.len();
    let (mut m, mut b) = (vec![vec![0.0; n]; n], vec![0.0; n]);
    for j in 0..2 { // stationarity: 2 C_j x_j + sum lam_i A_ij + nu = 0
        m[j][j] = 2.0 * C[j]; m[j][n - 1] = 1.0;
        for (t, &i) in active.iter().enumerate() { m[j][2 + t] = A[i][j]; }
    }
    m[2][0] = 1.0; m[2][1] = 1.0; b[2] = d; // demand met exactly
    for (t, &i) in active.iter().enumerate() { // active caps hold with equality
        m[3 + t][0] = A[i][0]; m[3 + t][1] = A[i][1]; b[3 + t] = caps[i] - BASE;
    }
    let s = solve(m, b)?;
    let mut lam = [0.0, 0.0];
    for (t, &i) in active.iter().enumerate() { lam[i] = s[2 + t]; }
    Some(([s[0], s[1]], lam, s[n - 1]))
}

const SETS: [&[usize]; 4] = [&[], &[0], &[1], &[0, 1]];
fn best(caps: [f64; 2], d: f64) -> Vec<Sol> { // road 1: active sets passing all four conditions
    SETS.iter().filter_map(|act| kkt(act, caps, d))
        .filter(|r| fi(0, r.0, caps).max(fi(1, r.0, caps)) <= 1e-9 && r.1[0].min(r.1[1]) >= -1e-9).collect()
}

fn main() {
    println!("active caps   x1 kW   x2 kW     lam1     lam2       nu  cost £/h  verdict");
    for (act, name) in SETS.iter().zip(["none", "node 1", "node 2", "both"]) {
        let Some((x, lam, nu)) = kkt(act, CAPS, D) else {
            println!("{:<11} no point meets the demand and both caps", name); continue;
        };
        let mut why: Vec<String> = (0..2).filter(|&i| fi(i, x, CAPS) > 1e-9)
            .map(|i| format!("node {} at {:.1} m, over {:.0}", i + 1, fi(i, x, CAPS) + CAPS[i], CAPS[i])).collect();
        why.extend((0..2).filter(|&i| lam[i] < -1e-9).map(|i| format!("lam{} < 0", i + 1)));
        println!("{:<11}{:8.4}{:8.4}{:9.4}{:9.4}{:9.4}{:10.4}  {}", name, x[0], x[1], lam[0], lam[1], nu, cost(x),
                 if why.is_empty() { "passes all four".to_string() } else { why.join("; ") });
    }
    let sols = best(CAPS, D);
    assert!(sols.len() == 1, "exactly one active set passes");
    let (xs, lam, nu) = sols[0];
    let fs = cost(xs);
    let gf = [2.0 * C[0] * xs[0], 2.0 * C[1] * xs[1]];
    let st: Vec<f64> = (0..2).map(|j| gf[j] + lam[0] * A[0][j] + lam[1] * A[1][j] + nu).collect();
    println!("x* = {} kW, cost {:.4} £/h, lam = ({:.4}, {:.4}), nu = {:.4}", v(xs), fs, lam[0], lam[1], nu);
    println!("1 primal:      f1 = {:.4}, f2 = {:.4}, h = {:.4}", fi(0, xs, CAPS), fi(1, xs, CAPS), xs[0] + xs[1] - D);
    println!("2 dual:        lam1 = {:.4} >= 0, lam2 = {:.4} >= 0", lam[0], lam[1]);
    println!("3 slackness:   lam1*f1 = {:.4}, lam2*f2 = {:.4}", (lam[0] * fi(0, xs, CAPS)).abs(), (lam[1] * fi(1, xs, CAPS)).abs());
    println!("4 stationary:  grad f0 {} + lam1 (1, 4) + nu (1, 1) = {}", v(gf), v([st[0].abs(), st[1].abs()]));
    let det = A[0][0] * 1.0 - A[0][1] * 1.0;
    println!("LICQ: active gradients (1, 4) and (1, 1), determinant {:.4}, so independent", det);
    let e = 1e-5;
    let fd: Vec<f64> = (0..2).map(|j| { let (a, b) = (if j == 0 { e } else { 0.0 }, if j == 1 { e } else { 0.0 });
        (cost([xs[0] + a, xs[1] + b]) - cost([xs[0] - a, xs[1] - b])) / (2.0 * e) }).collect();
    println!("grad f0 by central difference {}", v([fd[0], fd[1]]));
    // road 2: q(lam, nu) = min over all x of f0 + lam1 f1 + lam2 f2 + nu h, separable in x1, x2
    let bj: Vec<f64> = (0..2).map(|j| lam[0] * A[0][j] + lam[1] * A[1][j] + nu).collect();
    let q = (0..2).map(|j| -bj[j].powi(2) / (4.0 * C[j])).sum::<f64>()
        + (0..2).map(|i| lam[i] * (BASE - CAPS[i])).sum::<f64>() - nu * D;
    println!("dual bound q(lam, nu) = {:.4} £/h, gap to the cost {:.4}", q, (fs - q).abs());
    // road 3: scan the demand line
    let line = |k: usize, s: f64| [k as f64 / s, D - k as f64 / s];
    let feas: Vec<(f64, f64)> = (0..100001).map(|k| line(k, 10000.0))
        .filter(|x| fi(0, *x, CAPS).max(fi(1, *x, CAPS)) <= 0.0).map(|x| (cost(x), x[0])).collect();
    let sc = feas.iter().cloned().fold((f64::INFINITY, 0.0), |a, b| if b.0 < a.0 { b } else { a });
    println!("scan: {} of 100001 points feasible, x1 from {:.4} to {:.4}; best x1 = {:.4} at {:.4} £/h",
             feas.len(), feas[0].1, feas[feas.len() - 1].1, sc.1, sc.0);
    // what each multiplier is worth: re-solve with the limit nudged
    let (up, dn) = (cost(best([CAPS[0] + 0.1, CAPS[1]], D)[0].0), cost(best([CAPS[0] - 0.1, CAPS[1]], D)[0].0));
    let (d_up, d_dn) = (cost(best(CAPS, D + 0.1)[0].0), cost(best(CAPS, D - 0.1)[0].0));
    println!("cap 1 at {:.1} / {:.1} m: {:.4} / {:.4} £/h, saving {:.4} per metre", CAPS[0] - 0.1, CAPS[0] + 0.1, dn, up, (dn - up) / 0.2);
    println!("demand {:.1} / {:.1} kW: {:.4} / {:.4} £/h, {:.4} per kW", D - 0.1, D + 0.1, d_dn, d_up, (d_up - d_dn) / 0.2);
    // how it moves: the node 1 cap swept from 28 to 40 m, each answer checked by a 0.001 kW scan
    let caps: Vec<i32> = (28..41).collect();
    let mut row = vec![];
    for &c in &caps {
        let (x, lm, _) = best([c as f64, 35.0], D)[0];
        let grid = (0..10001).map(|k| line(k, 1000.0))
            .filter(|y| fi(0, *y, [c as f64, 35.0]).max(fi(1, *y, [c as f64, 35.0])) <= 0.0)
            .map(cost).fold(f64::INFINITY, f64::min);
        assert!(grid - cost(x) >= 0.0 && grid - cost(x) < 0.004, "sweep: KKT answer vs scan");
        row.push([x[0], lm[0], cost(x)]);
    }
    println!("sweep, {:<9}{}", "cap m", caps.iter().map(|c| format!("{:6}", c)).collect::<Vec<_>>().join(" "));
    for (k, name) in ["x1 kW", "lam1", "cost £/h"].iter().enumerate() {
        println!("sweep, {:<9}{}", name, row.iter().map(|r| format!("{:6.3}", r[k])).collect::<Vec<_>>().join(" "));
    }
    // what breaks
    let x0 = kkt(&[], CAPS, D).unwrap().0;
    println!("mistake, no caps: x = {}, cost {:.4}, node 1 at {:.4} m", v(x0), cost(x0), fi(0, x0, CAPS) + CAPS[0]);
    let (x2, l2, _) = kkt(&[1], CAPS, D).unwrap();
    println!("mistake, no sign rule: x = {}, cost {:.4}, lam2 = {:.4}", v(x2), cost(x2), l2[1]);
    let xc = [6.0, 4.0];
    let sl = solve(vec![vec![A[0][0], 1.0], vec![A[0][1], 1.0]], vec![-2.0 * C[0] * xc[0], -2.0 * C[1] * xc[1]]).unwrap();
    println!("mistake, no slackness: x = {}, cost {:.4}, lam1 = {:.4}, f1 = {:.4}, lam1*f1 = {:.4}",
             v(xc), cost(xc), sl[0], fi(0, xc, CAPS), sl[0] * fi(0, xc, CAPS));
    let ns: Vec<f64> = feas.iter().map(|f| solve(vec![vec![A[0][0], 1.0], vec![A[0][1], 1.0]], vec![-2.0 * C[0] * f.1, -2.0 * C[1] * (D - f.1)]).unwrap()[0]).collect(); // lam1 at every allowed split
    let (nlo, nhi) = (ns.iter().cloned().fold(f64::INFINITY, f64::min), ns.iter().cloned().fold(f64::NEG_INFINITY, f64::max));
    println!("mistake, no slackness: {} of {} allowed splits pass checks 1, 2 and 4, lam1 from {:.4} to {:.4}", ns.iter().filter(|&&l| l >= 0.0).count(), feas.len(), nlo, nhi);
    let xx = solve(vec![A[0].to_vec(), A[1].to_vec()], vec![CAPS[0] - BASE, CAPS[1] - BASE]).unwrap();
    println!("mistake, both caps as equalities: caps cross at {}, total {:.4} kW, not 10", v([xx[0], xx[1]]), xx[0] + xx[1]);
    // a constraint qualification fails: the node 1 cap written as (f1)^2 <= 0
    let nsq = (0..100001).filter(|&k| fi(0, line(k, 10000.0), CAPS).powi(2) <= 0.0).count();
    let xq = kkt(&[0], CAPS, D).unwrap().0; // the one point with f1 = 0 and h = 0
    let gq = [2.0 * C[0] * xq[0], 2.0 * C[1] * xq[1]];
    let nu_ls = -(gq[0] + gq[1]) / 2.0;
    let res = ((gq[0] + nu_ls).powi(2) + (gq[1] + nu_ls).powi(2)).sqrt();
    let gsq = [(2.0 * fi(0, xq, CAPS) * A[0][0]).abs(), (2.0 * fi(0, xq, CAPS) * A[0][1]).abs()];
    println!("squared cap: {} feasible point, x = {}; grad (f1)^2 = {}", nsq, v(xq), v(gsq));
    println!("squared cap: best nu = {:.4} leaves stationarity residual {:.4}, so no multipliers", nu_ls, res);
    let cu: [fn([f64; 2]) -> f64; 3] = [|x| x[1] - (1.0 - x[0]).powi(3), |x| -x[1], |x| x[0]]; // Kuhn-Tucker cusp: the two caps, and x1 = -f0
    let cg: Vec<[f64; 2]> = cu.iter().map(|u| [(u([1.0 + e, 0.0]) - u([1.0 - e, 0.0])) / (2.0 * e), (u([1.0, e]) - u([1.0, -e])) / (2.0 * e)]).collect(); // gradients at (1, 0)
    let kt = (0..=100).flat_map(|a| (0..=100).map(move |b| (a as f64 / 10.0, b as f64 / 10.0)))
        .map(|(a, b)| ((cg[2][0] - a * cg[0][0] - b * cg[1][0]).powi(2) + (cg[2][1] - a * cg[0][1] - b * cg[1][1]).powi(2)).sqrt()).fold(f64::INFINITY, f64::min);
    println!("cusp, max x1 with x2 <= (1-x1)^3, x2 >= 0: at (1, 0) gradients {}, {}; -grad f = {}; best residual over lam in [0, 10] {:.4}", v(cg[0]), v(cg[1]), v(cg[2]), kt);
    let s = 28.0;
    println!("figure, x* ({:.1} {:.1}) no-cap ({:.1} {:.1}) demand ({:.1} {:.1}) ({:.1} {:.1}) cap1 ({:.1} {:.1}) ({:.1} {:.1}) cap2 ({:.1} {:.1}) ({:.1} {:.1}) end ({:.1} {:.1}) radii {:.1} {:.1}",
             40.0 + s * xs[0], 300.0 - s * xs[1], 40.0 + s * x0[0], 300.0 - s * x0[1], 40.0, 300.0 - s * D, 40.0 + s * D, 300.0, 40.0, 300.0 - s * 6.25,
             40.0 + s * 10.0, 300.0 - s * 3.75, 40.0 + s * 5.0, 20.0, 40.0 + s * 25.0 / 3.0, 300.0,
             40.0 + s * 7.5, 300.0 - s * 2.5, s * (fs / C[0]).sqrt(), s * (fs / C[1]).sqrt());
    assert!((sc.1 - xs[0]).abs() < 1e-4 && (sc.0 - fs).abs() < 1e-9, "road 1 vs road 3: KKT point vs scan");
    assert!((q - fs).abs() < 1e-9 && feas.iter().all(|f| f.0 >= q - 1e-12), "road 2: dual bound meets the cost");
    assert!(((dn - up) / 0.2 - lam[0]).abs() < 1e-6, "lam1 is the saving per metre of cap");
    assert!(((d_up - d_dn) / 0.2 + nu).abs() < 1e-6, "-nu is the cost per kW of demand");
    assert!((0..2).all(|j| (fd[j] - gf[j]).abs() < 1e-6), "gradient vs central difference");
    assert!(st.iter().all(|s| s.abs() < 1e-9) && res > 1e-6, "stationarity holds; the squared cap breaks it");
    assert!(nlo >= 0.0 && kt > 0.99, "without slackness every allowed split passes; the cusp has no multipliers");
    println!("ALL CHECKS PASS");
}
