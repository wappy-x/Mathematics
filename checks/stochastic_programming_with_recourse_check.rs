// Two-stage stochastic programming with recourse -- the check behind the card.
// Rust std only.  Same reservoir, same three roads as the Python check:
// road 1 solves the scenario tree as ONE linear program by the dual simplex
// method in exact fractions (a small rational type below); road 2 checks its
// dual prices; road 3 scans every whole x with the recourse rule in words.
use std::fmt;
use std::ops::{Add, Div, Mul, Neg, Sub};

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
struct Fr { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i128, d: i128) -> Fr { let g = gcd(n, d) * d.signum(); Fr { n: n / g, d: d / g } }
fn int(n: i128) -> Fr { Fr { n, d: 1 } }
impl Add for Fr { type Output = Fr; fn add(self, o: Fr) -> Fr { fr(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Sub for Fr { type Output = Fr; fn sub(self, o: Fr) -> Fr { self + (-o) } }
impl Mul for Fr { type Output = Fr; fn mul(self, o: Fr) -> Fr { fr(self.n * o.n, self.d * o.d) } }
impl Div for Fr { type Output = Fr; fn div(self, o: Fr) -> Fr { fr(self.n * o.d, self.d * o.n) } }
impl Neg for Fr { type Output = Fr; fn neg(self) -> Fr { Fr { n: -self.n, d: self.d } } }
impl PartialOrd for Fr { fn partial_cmp(&self, o: &Fr) -> Option<std::cmp::Ordering> { Some(self.cmp(o)) } }
impl Ord for Fr { fn cmp(&self, o: &Fr) -> std::cmp::Ordering { (self.n * o.d).cmp(&(o.n * self.d)) } }
impl fmt::Display for Fr { fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
    if self.d == 1 { f.pad(&self.n.to_string()) } else { f.pad(&format!("{}/{}", self.n, self.d)) } } }
fn fmax(a: Fr, b: Fr) -> Fr { if a > b { a } else { b } }  fn fmin(a: Fr, b: Fr) -> Fr { if a < b { a } else { b } }

const NAMES: [&str; 3] = ["dry", "normal", "wet"];
const RAIN: [i128; 3] = [10, 30, 90];
fn probs() -> Vec<Fr> { vec![fr(3, 10), fr(1, 2), fr(1, 5)] }

// Extensive form: columns x, then (g_s, f_s, b_s) per scenario; rows A z >= h.
fn build(p: &[Fr], w: &[i128], gate: i128, flood: i128) -> (Vec<Fr>, Vec<Vec<Fr>>, Vec<Fr>, Vec<String>) {
    let n = 1 + 3 * p.len();
    let mut cost = vec![int(gate)];
    for &pi in p { for k in [10, flood, 30] { cost.push(pi * int(k)); } }
    let (mut a, mut h, mut rows) = (vec![], vec![], vec![]);
    let mut row = |coefs: &[(usize, i128)], rhs: i128, name: String| {
        let mut v = vec![int(0); n];
        for &(j, c) in coefs { v[j] = int(c); }
        a.push(v); h.push(int(rhs)); rows.push(name);
    };
    row(&[(0, -1)], -70, "gates: x <= 70".to_string());
    for (s, &ws) in w.iter().enumerate() {
        let (g, f, b, nm) = (1 + 3 * s, 2 + 3 * s, 3 + 3 * s, NAMES[s]);
        row(&[(0, 1), (g, -1), (f, 1)], ws - 50, format!("{} room: level <= 100", nm));
        row(&[(0, -1), (g, 1), (f, -1), (b, 1)], -ws, format!("{} reserve: level + b >= 50", nm));
        row(&[(g, -1)], -20, format!("{} turbine: g <= 20", nm));
        row(&[(0, -1), (g, 1), (f, -1)], -50 - ws, format!("{} level >= 0", nm));
    }
    (cost, a, h, rows)
}

// All costs >= 0: start from the all-zero plan, repair one broken row per pivot
// at the least extra cost per unit, keeping every reduced cost >= 0.
fn dual_simplex(cost: &[Fr], a: &[Vec<Fr>], h: &[Fr]) -> (Vec<Fr>, Vec<Fr>, usize) {
    let (m, n) = (a.len(), cost.len());
    let mut t: Vec<Vec<Fr>> = (0..m).map(|i| {
        let mut v: Vec<Fr> = a[i].iter().map(|&x| -x).collect();
        for k in 0..m { v.push(int((i == k) as i128)); }
        v.push(-h[i]); v
    }).collect();
    let mut d: Vec<Fr> = cost.to_vec(); d.extend(vec![int(0); m]);
    let (mut basis, mut pivots): (Vec<usize>, usize) = ((n..n + m).collect(), 0);
    while let Some(i) = (0..m).find(|&i| t[i][n + m] < int(0)) {     // Bland: lowest broken row
        let j = (0..n + m).filter(|&j| t[i][j] < int(0))
            .min_by(|&x, &y| (d[x] / -t[i][x], x).cmp(&(d[y] / -t[i][y], y))).expect("infeasible");
        let piv = t[i][j]; t[i] = t[i].iter().map(|&v| v / piv).collect();
        for k in 0..m { if k != i && t[k][j] != int(0) {
            let fct = t[k][j]; t[k] = t[k].iter().zip(t[i].iter()).map(|(&x, &y)| x - fct * y).collect(); } }
        let fct = d[j]; d = d.iter().zip(t[i].iter()).map(|(&x, &y)| x - fct * y).collect();
        basis[i] = j; pivots += 1;
    }
    let mut z = vec![int(0); n];
    for (i, &j) in basis.iter().enumerate() { if j < n { z[j] = t[i][n + m]; } }
    (z, d[n..].to_vec(), pivots)
}

// Recourse rule in words, for L on hand after the rain: run the turbine to 20
// unless that dips below the 50 reserve; spill what is over 100.
fn q(l: Fr, flood: i128) -> Fr {
    let run = fmax(int(0), fmin(int(20), l - int(50)));
    int(10) * (int(20) - run) + int(flood) * fmax(int(0), l - run - int(100)) + int(30) * fmax(int(0), int(50) - l)
}
fn expected(x: i128, p: &[Fr], w: &[i128], gate: i128, flood: i128) -> Fr {
    let mut e = int(gate * x);
    for (&pi, &wi) in p.iter().zip(w) { e = e + pi * q(int(70 + wi - x), flood); }
    e
}
fn scan(p: &[Fr], w: &[i128], gate: i128, flood: i128) -> (Fr, i128) {
    (0..71).map(|x| (expected(x, p, w, gate, flood), x)).min().unwrap()
}
fn show(label: &str, v: impl fmt::Display) { println!("{:<44}{:>12}", label, v); }

fn main() {
    let p = probs();
    let (cost, a, h, rows) = build(&p, &RAIN, 2, 50);
    let (z, lam, pivots) = dual_simplex(&cost, &a, &h);
    let pstar = cost.iter().zip(&z).fold(int(0), |s, (&c, &v)| s + c * v);
    println!("tree: 1 decision now, 3 leaves; one LP with {} columns, {} rows", cost.len(), a.len());
    show("road 1: dual simplex pivots", pivots);
    show("  x*, let out now (million m3)", z[0]);
    show("  p*, expected cost (GBP thousand)", pstar);
    show("  of which gates, and expected repair", format!("{}, {}", int(2) * z[0], pstar - int(2) * z[0]));
    for s in 0..3 {
        let (g, f, b) = (z[1 + 3 * s], z[2 + 3 * s], z[3 + 3 * s]);
        let l = int(70 + RAIN[s]) - z[0];
        println!("  {:<7}rain {:>2} p {:>4}: on hand {}, turbine {}, bought {}, overflow {}, short {}, cost {}",
                 NAMES[s], RAIN[s], p[s], l, int(20) - g, g, f, b, q(l, 50));
        assert!(q(l, 50) == int(10) * g + int(50) * f + int(30) * b, "LP recourse must match the rule in words");
    }
    println!("road 2: dual prices lambda on the binding rows");
    for (i, &v) in lam.iter().enumerate() { if v != int(0) { show(&format!("  {}", rows[i]), v); } }
    let reduced: Vec<Fr> = (0..cost.len()).map(|j| (0..a.len()).fold(cost[j], |s, i| s - a[i][j] * lam[i])).collect();
    let bound = h.iter().zip(&lam).fold(int(0), |s, (&hi, &li)| s + hi * li);
    show("  smallest reduced cost, must be >= 0", *reduced.iter().min().unwrap());
    show("  dual bound h^T lambda", bound);
    let (best_e, best_x) = scan(&p, &RAIN, 2, 50);
    show("road 3: scan x = 0..70, best x", best_x);
    show("  its expected cost", best_e);
    let xs: Vec<i128> = (0..13).map(|k| 5 * k).collect();
    println!("chart x  {}", xs.iter().map(|x| format!("{:>4}", x)).collect::<Vec<_>>().join(" "));
    println!("chart E  {}", xs.iter().map(|&x| format!("{:>4}", expected(x, &p, &RAIN, 2, 50))).collect::<Vec<_>>().join(" "));
    for x in [10, 20, 30, 40] { show(&format!("  expected cost at x = {}", x), expected(x, &p, &RAIN, 2, 50)); }

    let wbar = p.iter().zip(&RAIN).fold(int(0), |s, (&pi, &wi)| s + pi * int(wi));
    let (one, (fc, xbar)) = ([int(1)], scan(&[int(1)], &[wbar.n], 2, 50));   // wbar is a whole number
    let eev = expected(xbar, &p, &RAIN, 2, 50);
    let ws_each: Vec<Fr> = RAIN.iter().map(|&wi| scan(&one, &[wi], 2, 50).0).collect();
    let ws = p.iter().zip(&ws_each).fold(int(0), |s, (&pi, &v)| s + pi * v);
    show("average rain (million m3)", wbar);
    show("  its plan x, and the cost it forecasts", format!("{}, {}", xbar, fc));
    show("  EEV: that plan's real expected cost", eev);
    show("wait-and-see: dry, normal, wet", ws_each.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(", "));
    show("  WS, perfect-foresight average", ws);
    show("VSS = EEV - p*", eev - pstar);
    show("EVPI = p* - WS", pstar - ws);
    let x_wet = scan(&one, &[90], 2, 50).1;
    let x_avg = p.iter().zip(&RAIN).fold(int(0), |s, (&pi, &wi)| s + pi * int(scan(&one, &[wi], 2, 50).1));
    let mut fixed = (int(1_000_000), 0, 0);
    for x in 0..71 { for y in 0..21 {
        let c = p.iter().zip(&RAIN).fold(int(2 * x + 10 * (20 - y)), |c, (&pi, &wi)|
            c + pi * int(50 * (70 + wi - x - y - 100).max(0) + 30 * (50 - (70 + wi - x - y)).max(0)));
        if (c, x, y) < fixed { fixed = (c, x, y); } } }
    show("wrong: plan for the average rain", eev);
    show(&format!("wrong: plan for the wet year, x = {}", x_wet), expected(x_wet, &p, &RAIN, 2, 50));
    show(&format!("wrong: average the 3 foresight plans, x = {}", x_avg), expected(x_avg.n, &p, &RAIN, 2, 50));
    show(&format!("wrong: fix turbine {} now too, x = {}", fixed.2, fixed.1), fixed.0);
    show("  extra cost of fixing it, over p*", fixed.0 - pstar);
    show("size: leaves of a 12-month, 3-way tree", 3i64.pow(12));
    for (label, pp, gate, flood) in [("try: wet 40%, normal 30%", vec![fr(3, 10), fr(3, 10), fr(2, 5)], 2, 50),
                                     ("try: overflow costs 100", p.clone(), 2, 100), ("try: gates cost 12", p.clone(), 12, 50)] {
        let (e, x) = scan(&pp, &RAIN, gate, flood);
        let (c2, a2, r2, _) = build(&pp, &RAIN, gate, flood);
        assert!(dual_simplex(&c2, &a2, &r2).0[0] == int(x), "LP and scan agree");
        show(&format!("{}: x*, p*", label), format!("{}, {}", x, e));
    }
    let leaves: Vec<String> = (0..3).map(|s| format!("{} {} {} {} {} {} {}", NAMES[s], RAIN[s], p[s].n as f64 / p[s].d as f64,
        int(20) - z[1 + 3 * s], z[1 + 3 * s], z[2 + 3 * s], q(int(70 + RAIN[s]) - z[0], 50))).collect();
    println!("figure, root x {}; leaves (rain, chance, turbine, bought, overflow, cost): {}", z[0], leaves.join(" | "));

    assert!(z[0] == int(best_x) && pstar == best_e && best_e == int(220) && best_x == 30, "LP must match the scan");
    assert!(z.iter().all(|&v| v >= int(0)) && (0..a.len()).all(|i| (0..cost.len()).fold(int(0), |s, j| s + a[i][j] * z[j]) >= h[i]), "the plan must meet every row");
    assert!(*reduced.iter().min().unwrap() >= int(0) && *lam.iter().min().unwrap() >= int(0), "dual prices must be feasible");
    assert!(bound == pstar, "dual bound must meet the LP value: the certificate");
    assert!(ws <= pstar && pstar <= eev && fc < eev, "foresight <= recourse <= mean-value plan");
    assert!(wbar == int(36) && xbar == 0 && eev == int(400) && ws == int(16), "Step 5 by hand: average rain 36, its plan 0, EEV 400, WS 16");
    println!("ALL CHECKS PASS");
}
