// Lagrangian relaxation of a festival's shared sound crew.  std only, exact fractions where it matters.
// Maximise profit (£k).  Each stage has a 6-hour evening; all acts share 16 crew-hours of rigging.
use std::cmp::Ordering;
#[derive(Clone, Copy, Debug)]
struct Q(i64, i64); // numerator, denominator > 0, in lowest terms
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn r(n: i64, d: i64) -> Q { let g = gcd(n, d) * d.signum(); Q(n / g, d / g) }
fn z(n: i64) -> Q { Q(n, 1) } fn fl(x: Q) -> f64 { x.0 as f64 / x.1 as f64 }
impl std::ops::Add for Q { type Output = Q; fn add(self, o: Q) -> Q { r(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl std::ops::Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { r(self.0 * o.1 - o.0 * self.1, self.1 * o.1) } }
impl std::ops::Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { r(self.0 * o.0, self.1 * o.1) } }
impl std::ops::Div for Q { type Output = Q; fn div(self, o: Q) -> Q { r(self.0 * o.1, self.1 * o.0) } }
impl PartialEq for Q { fn eq(&self, o: &Q) -> bool { self.cmp(o) == Ordering::Equal } } impl Eq for Q {}
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<Ordering> { Some(self.cmp(o)) } }
impl Ord for Q { fn cmp(&self, o: &Q) -> Ordering { (self.0 as i128 * o.1 as i128).cmp(&(o.0 as i128 * self.1 as i128)) } }
impl std::fmt::Display for Q { fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
    if self.1 == 1 { write!(f, "{}", self.0) } else { write!(f, "{}/{}", self.0, self.1) } } }

const C: i64 = 16;
type Act = (&'static str, i64, i64, i64); // (act, stage hours, crew-hours, profit in £k)
const STAGES: [[Act; 3]; 3] = [
    [("M1", 3, 2, 12), ("M2", 2, 6, 12), ("M3", 4, 6, 5)],
    [("T1", 4, 5, 8), ("T2", 3, 3, 7), ("T3", 3, 2, 9)],
    [("A1", 2, 6, 10), ("A2", 3, 4, 12), ("A3", 4, 2, 8)]];
type Plan = (String, i64, i64); // name, profit, crew
fn size(a: &Act, bc: bool) -> i64 { if bc { 1 } else { a.1 } }
fn cap(bc: bool) -> i64 { if bc { 2 } else { 6 } } // variant: "at most two acts a stage"

fn plans(acts: &[Act; 3], bc: bool) -> Vec<Plan> { // every booking of one stage that fits its evening
    (0..8).map(|m: usize| (0..3).filter(|i| m >> i & 1 == 1).map(|i| &acts[i]).collect::<Vec<&Act>>())
        .filter(|pick| pick.iter().map(|a| size(a, bc)).sum::<i64>() <= cap(bc))
        .map(|pick| { let n = pick.iter().map(|a| a.0).collect::<Vec<_>>().join("+");
            (if n.is_empty() { "none".to_string() } else { n }, pick.iter().map(|a| a.3).sum(), pick.iter().map(|a| a.2).sum()) }).collect()
}
fn choice(ps: &[Plan], lam: Q, low: bool) -> Plan { // a stage's best plan at crew price lam; ties go to less crew
    ps.iter().fold(ps[0].clone(), |b, p| { let (v, w) = (z(p.1) - lam * z(p.2), z(b.1) - lam * z(b.2));
        if v > w || (v == w && (if low { p.2 < b.2 } else { p.2 > b.2 })) { p.clone() } else { b } })
}
fn choice_f(ps: &[Plan], lam: f64) -> Plan {
    ps.iter().fold(ps[0].clone(), |b, p| { let (v, w) = (p.1 as f64 - lam * p.2 as f64, b.1 as f64 - lam * b.2 as f64);
        if v > w || (v == w && p.2 < b.2) { p.clone() } else { b } })
}
fn q(pp: &[Vec<Plan>], lam: Q) -> Q { // the dual function: an upper bound for every lam >= 0
    pp.iter().fold(lam * z(C), |s, ps| { let c = choice(ps, lam, true); s + z(c.1) - lam * z(c.2) })
}
fn q_lp(st: &[[Act; 3]; 3], bc: bool, lam: Q) -> Q { // the same price on the LP relaxation: fractional knapsacks
    let mut v = lam * z(C);
    for s in st.iter() {
        let mut room = z(cap(bc));
        let mut order: Vec<&Act> = s.iter().collect();
        order.sort_by(|a, b| ((z(b.3) - lam * z(b.2)) / z(size(b, bc))).cmp(&((z(a.3) - lam * z(a.2)) / z(size(a, bc)))));
        for a in order {
            let w = z(a.3) - lam * z(a.2);
            if w > z(0) && room > z(0) { let t = std::cmp::min(z(1), room / z(size(a, bc))); v = v + t * w; room = room - t * z(size(a, bc)); }
        }
    }
    v
}
fn stage_corners(s: &[Act; 3], lam: Q) -> Q { // check road: the best corner of one stage's LP region (hours rule)
    let hrs = |p: &[Q; 3]| (0..3).fold(z(0), |h, i| h + p[i] * z(s[i].1));
    let mut pts: Vec<[Q; 3]> = (0..8).map(|m: i64| [0i64, 1, 2].map(|i| z(m >> i & 1))).collect();
    for m in 0..8 { for j in 0..3 { let mut p = pts[m]; p[j] = z(0); p[j] = (z(6) - hrs(&p)) / z(s[j].1); pts.push(p); } }
    pts.iter().filter(|p| p.iter().all(|x| *x >= z(0) && *x <= z(1)) && hrs(p) <= z(6))
        .map(|p| (0..3).fold(z(0), |w, i| w + p[i] * (z(s[i].3) - lam * z(s[i].2)))).max().unwrap()
}
fn kinks(st: &[[Act; 3]; 3], pp: &[Vec<Plan>], bc: bool) -> Vec<Q> { // every price where a ranking or a sign can change
    let mut out = vec![z(0)];
    for ps in pp { for a in ps { for b in ps { if a.2 != b.2 { out.push(r(a.1 - b.1, a.2 - b.2)); } } } }
    let all: Vec<&Act> = st.iter().flatten().collect();
    for a in &all { for b in &all {
        out.push(r(a.3, a.2));
        let d = a.2 * size(b, bc) - b.2 * size(a, bc);
        if d != 0 { out.push(r(a.3 * size(b, bc) - b.3 * size(a, bc), d)); }
    } }
    out.retain(|l| *l >= z(0)); out.sort(); out.dedup(); out
}
fn argmin(ks: &[Q], f: impl Fn(Q) -> Q) -> Q { *ks.iter().min_by(|a, b| f(**a).cmp(&f(**b)).then(a.cmp(b))).unwrap() }
fn triples(pp: &[Vec<Plan>]) -> Vec<[Plan; 3]> {
    pp[0].iter().flat_map(|a| pp[1].iter().flat_map(move |b| pp[2].iter().map(move |c| [a.clone(), b.clone(), c.clone()]))).collect()
}
fn tot(t: &[Plan], i: usize) -> i64 { t.iter().map(|p| if i == 1 { p.1 } else { p.2 }).sum() }
fn names(t: &[Plan]) -> String { format!("[{}]", t.iter().map(|p| format!("'{}'", p.0)).collect::<Vec<_>>().join(", ")) }
fn bounds(st: &[[Act; 3]; 3], bc: bool) -> (Vec<Vec<Plan>>, Vec<[Plan; 3]>, i64, Q, Q, Q, Q) {
    let pp: Vec<Vec<Plan>> = st.iter().map(|s| plans(s, bc)).collect();
    let feas: Vec<[Plan; 3]> = triples(&pp).into_iter().filter(|t| tot(t, 2) <= C).collect();
    let zip = feas.iter().map(|t| tot(t, 1)).max().unwrap();
    let ks = kinks(st, &pp, bc);
    let (ld, ll) = (argmin(&ks, |l| q(&pp, l)), argmin(&ks, |l| q_lp(st, bc, l)));
    let qd = q(&pp, ld);
    (pp, feas, zip, ld, qd, ll, q_lp(st, bc, ll))
}
fn subgradient(pp: &[Vec<Plan>], step: impl Fn(usize) -> f64) -> Vec<(usize, f64, i64, f64, f64)> { // road 4
    let (mut lam, mut top, mut rows) = (0.0f64, f64::INFINITY, vec![]);
    for k in 0..30 {
        let x: Vec<Plan> = pp.iter().map(|ps| choice_f(ps, lam)).collect();
        let crew = tot(&x, 2);
        let val = x.iter().fold(lam * C as f64, |s, p| s + (p.1 as f64 - lam * p.2 as f64));
        top = top.min(val); rows.push((k, lam, crew, val, top));
        lam = (lam - step(k) * (C - crew) as f64).max(0.0);
    }
    rows
}
fn main() {
    let (pp, feas, z_ip, lam_d, z_ld, lam_lp, z_lp) = bounds(&STAGES, false);
    println!("plans per stage [{}, {}, {}] ; whole bookings within crew {}", pp[0].len(), pp[1].len(), pp[2].len(), feas.len());
    for ps in &pp { println!("   {}", ps.iter().map(|p| format!("{}:{}/{}", p.0, p.1, p.2)).collect::<Vec<_>>().join(" ")); }
    let best = feas.iter().max_by_key(|t| tot(*t, 1)).unwrap();
    println!("road 1, enumeration: best {} profit {} crew {}", names(best), z_ip, tot(best, 2));
    println!("road 2, kinks of q: price {} bound {}", lam_d, z_ld);
    let (mut dw, mut mix) = (z(z_ip), String::new()); // road 3: master LP over whole plans, corner by corner
    for t in triples(&pp) { for s in 0..3 { for alt in &pp[s] { if alt.2 != t[s].2 {
        let th = r(C - tot(&t, 2), alt.2 - t[s].2); // weight on alt using crew exactly
        let v = z(tot(&t, 1)) + th * z(alt.1 - t[s].1); // ties: the last one found is kept
        if th > z(0) && th < z(1) && v >= dw { dw = v; mix = format!("{} with {} of {} swapped for {}", names(&t), th, t[s].0, alt.0); }
    } } } }
    println!("road 3, master LP over whole plans: {} ; one best blend {}", dw, mix);
    let rows = subgradient(&pp, |k| 0.5 / (k + 1) as f64);
    for &(k, lam, crew, val, top) in rows[..7].iter().chain(rows[29..].iter()) {
        println!("road 4, k={:2} price {:.4} crew {:2} q {:.4} best bound {:.4}", k, lam, crew, val, top);
    }
    println!("LP bound: price {} bound {}", lam_lp, z_lp);
    let qs: Vec<Q> = pp.iter().map(|ps| { let c = choice(ps, lam_d, true); z(c.1) - lam_d * z(c.2) }).collect();
    let ls: Vec<Q> = STAGES.iter().map(|s| stage_corners(s, lam_d)).collect();
    let jq = |v: &[Q]| format!("{} + {} = {}", lam_d * z(C), v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" + "), v.iter().fold(lam_d * z(C), |a, &b| a + b));
    println!("at price {}, stage by stage: q {}; LP corners {}", lam_d, jq(&qs), jq(&ls));
    let x_lp = [("M1", z(1)), ("M2", r(7, 12)), ("T2", z(1)), ("T3", z(1)), ("A2", z(1)), ("A3", r(3, 4))]; // a fractional booking
    let act = |n: &str| *STAGES.iter().flatten().find(|a| a.0 == n).unwrap();
    let lp_val = x_lp.iter().fold(z(0), |s, (n, t)| s + *t * z(act(n).3));
    let lp_crew = x_lp.iter().fold(z(0), |s, (n, t)| s + *t * z(act(n).2));
    let lp_hours: Vec<Q> = STAGES.iter().map(|s| x_lp.iter().filter(|(n, _)| n.as_bytes()[0] == s[0].0.as_bytes()[0])
        .fold(z(0), |a, (n, t)| a + *t * z(act(n).1))).collect();
    println!("LP certificate: profit {} crew {} stage hours {} {} {}", lp_val, lp_crew, lp_hours[0], lp_hours[1], lp_hours[2]);
    let (hi, lo): (Vec<Plan>, Vec<Plan>) = (pp.iter().map(|ps| choice(ps, lam_d, false)).collect(), pp.iter().map(|ps| choice(ps, lam_d, true)).collect());
    println!("priced choice at {} : high-crew ties {} {} crew {} ; low-crew ties {} crew {}", lam_d, names(&hi), tot(&hi, 1), tot(&hi, 2), tot(&lo, 1), tot(&lo, 2));
    let mut fix: Vec<Plan> = vec![];
    for s in 0..3 { for p in &pp[s] {
        let mut t = hi.clone(); t[s] = p.clone();
        if tot(&t, 2) <= C && (fix.is_empty() || tot(&t, 1) > tot(&fix, 1)) { fix = t; }
    } }
    println!("repair, change one stage: {} profit {} crew {}", names(&fix), tot(&fix, 1), tot(&fix, 2));
    println!("gaps over {}: Lagrangian {} = {:.1}%, LP {} = {:.1}%", z_ip, z_ld - z(z_ip), 100.0 * fl(z_ld - z(z_ip)) / z_ip as f64,
        z_lp - z(z_ip), 100.0 * fl(z_lp - z(z_ip)) / z_ip as f64);
    println!("drop the lam*C term: {} ; constant step 0.5, bound after 30: {:.4}", z_ld - lam_d * z(C), subgradient(&pp, |_| 0.5)[29].4);
    let (_, _, ip1, l1, ld1, ll1, lp1) = bounds(&STAGES, true);
    println!("variant, at most two acts a stage: best {} Lagrangian {} at {} LP {} at {}", ip1, ld1, l1, lp1, ll1);
    for i in 0..9 { println!("chart, price {:.1}: q {:.2} LP {:.2}", i as f64 / 2.0, fl(q(&pp, r(i, 2))), fl(q_lp(&STAGES, false, r(i, 2)))); }
    let mut brute = (0, 0); // 512 raw bit patterns
    for m in 0..512usize {
        let on = |s: usize, i: usize| m >> (3 * s + i) & 1 == 1;
        let sum = |f: &dyn Fn(&Act) -> i64| -> i64 { (0..9).filter(|j| on(j / 3, j % 3)).map(|j| f(&STAGES[j / 3][j % 3])).sum() };
        let ok = (0..3).all(|s| (0..3).filter(|&i| on(s, i)).map(|i| STAGES[s][i].1).sum::<i64>() <= 6);
        if ok && sum(&|a| a.2) <= C { brute = (std::cmp::max(brute.0, sum(&|a| a.3)), brute.1 + 1); }
    }
    assert!(brute.0 == z_ip && brute.1 == feas.len());
    assert!(dw == z_ld); // the dual meets the master LP over whole plans
    assert!(lp_val == z_lp && lp_crew <= z(C) && lp_hours.iter().all(|h| *h <= z(6))); // LP bound met by a feasible point
    assert!(fl(z_ld) <= rows[29].4 && rows[29].4 < fl(z_ld) + 0.01);
    assert!(z(z_ip) < z_ld && z_ld < z_lp && ld1 == lp1 && tot(&fix, 1) == z_ip);
    assert!((0..50).all(|k| q(&pp, r(k, 7)) >= z_ld));
    assert!((0..9).all(|i| q_lp(&STAGES, false, r(i, 2)) == STAGES.iter().fold(r(i, 2) * z(C), |v, s| v + stage_corners(s, r(i, 2)))));
    println!("try step 1/(k+1): best bound after 30 {:.4}", subgradient(&pp, |k| 1.0 / (k + 1) as f64)[29].4);
    let r3 = subgradient(&pp, |_| 0.3); let seen: std::collections::BTreeSet<String> = r3.iter().map(|x| format!("{:.4}", x.1)).collect();
    println!("try constant step 0.3: prices visited {}; best bound {:.4}", seen.into_iter().collect::<Vec<_>>().join(" "), r3[29].4);
    let rf = subgradient(&pp, |k| -0.5 / (k + 1) as f64); // the sign flipped: lam + step * (C - crew)
    println!("try flipped sign: highest price in 30 steps {:.4}; best bound {:.4}", rf.iter().map(|x| x.1).fold(0.0, f64::max), rf[29].4);
    let mut a9 = STAGES; a9[2][2].3 = 9; // A3 pays 9
    let (_, _, ip2, l2, ld2, _, lp2) = bounds(&a9, false);
    println!("try A3 pays 9: best {}, price {}, Lagrangian {} = {:.2}, LP {} = {:.2}", ip2, l2, ld2, fl(ld2), lp2, fl(lp2));
    println!("ALL CHECKS PASS");
}
