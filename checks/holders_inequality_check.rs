// Holder's inequality on a week of wind and prices: the check behind the card.
// Rust std only. Own Simpson integrator, own minimiser, own random numbers.
const W: [f64; 7] = [3.0, 5.0, 8.0, 2.0, 6.0, 4.0, 7.0]; // mean wind speed each day, m/s = MWh sold
const C: [f64; 7] = [60.0, 50.0, 30.0, 70.0, 40.0, 55.0, 35.0]; // price each day, $/MWh
const INF: f64 = f64::INFINITY;

fn norm(v: &[f64], p: f64, mu: &[f64]) -> f64 { // the p-size of v against the weights mu
    if p == INF {
        return v.iter().zip(mu).filter(|(_, m)| **m > 0.0).map(|(x, _)| x.abs()).fold(0.0, f64::max);
    }
    v.iter().zip(mu).map(|(x, m)| m * x.abs().powf(p)).sum::<f64>().powf(1.0 / p)
}
fn conj(p: f64) -> f64 { if p == 1.0 { INF } else if p == INF { 1.0 } else { p / (p - 1.0) } }
fn bound(u: &[f64], v: &[f64], p: f64, mu: &[f64]) -> f64 { norm(u, p, mu) * norm(v, conj(p), mu) }
fn dotp(u: &[f64], v: &[f64]) -> f64 { u.iter().zip(v).map(|(a, b)| a * b).sum() }
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    s * h / 3.0
}
struct Rng(u64);
impl Rng {
    fn next(&mut self) -> f64 { // SplitMix64
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
fn j(v: &[f64]) -> String { v.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let one = [1.0; 7];
    let dot = dotp(&W, &C);
    let days: Vec<String> = (0..7).map(|i| format!("{}", W[i] * C[i])).collect();
    println!("data,revenue by day $,{}", days.join(" "));
    println!("data,revenue sum w*c $,{}", dot);
    println!("norms,wind 1 2 3 inf,{}", j(&[1.0, 2.0, 3.0, INF].map(|p| norm(&W, p, &one))));
    println!("norms,price 1 3/2 2 inf,{}", j(&[1.0, 1.5, 2.0, INF].map(|p| norm(&C, p, &one))));
    println!("norms,sum w^2 sum c^2,{} {}", W.iter().map(|a| a * a).sum::<f64>(), C.iter().map(|b| b * b).sum::<f64>());

    // road 1: the bound for many conjugate pairs, and the best p by golden-section search
    let ps = [1.0, 1.25, 1.5, 1.75, 2.0, 3.0, 4.0, 6.0, 10.0, INF];
    let labs = ["1", "1.25", "1.5", "1.75", "2", "3", "4", "6", "10", "inf"];
    for (p, l) in ps.iter().zip(labs) {
        let b = bound(&W, &C, *p, &one);
        assert!(b >= dot);
        println!("sweep,p={} q={:.4},{:.2}", l, conj(*p), b);
    }
    let (mut lo, mut hi, g) = (1.01f64, 6.0f64, (5f64.powf(0.5) - 1.0) / 2.0);
    for _ in 0..80 {
        let (m1, m2) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if bound(&W, &C, m1, &one) < bound(&W, &C, m2, &one) { hi = m2 } else { lo = m1 }
    }
    let pb = (lo + hi) / 2.0;
    println!("best,p q bound,{}", j(&[pb, conj(pb), bound(&W, &C, pb, &one)]));

    // road 2: Cauchy-Schwarz slack in whole numbers, by Lagrange's identity
    let wi: Vec<i64> = W.iter().map(|x| *x as i64).collect();
    let ci: Vec<i64> = C.iter().map(|x| *x as i64).collect();
    let di: i64 = (0..7).map(|k| wi[k] * ci[k]).sum();
    let lhs = wi.iter().map(|a| a * a).sum::<i64>() * ci.iter().map(|b| b * b).sum::<i64>() - di * di;
    let mut rhs = 0i64;
    for a in 0..7 { for b in a + 1..7 { rhs += (wi[a] * ci[b] - wi[b] * ci[a]).pow(2); } }
    assert_eq!(lhs, rhs);
    let csi = ((di * di + rhs) as f64).sqrt();
    assert!((csi - bound(&W, &C, 2.0, &one)).abs() < 1e-9);
    println!("lagrange,norms route,{}", lhs);
    println!("lagrange,pairs route,{}", rhs);
    println!("lagrange,sqrt(1515^2 + pairs),{:.6}", csi);

    // road 3: the proof itself, day by day: Young on the rescaled values at p = 2 and p = 3
    for p in [2.0, 3.0] {
        let q = conj(p);
        let (nw, nc) = (norm(&W, p, &one), norm(&C, q, &one));
        let f: Vec<f64> = W.iter().map(|a| a / nw).collect();
        let h: Vec<f64> = C.iter().map(|b| b / nc).collect();
        let gaps: Vec<f64> = (0..7).map(|k| f[k].powf(p) / p + h[k].powf(q) / q - f[k] * h[k]).collect();
        let gs: f64 = gaps.iter().sum();
        assert!(gaps.iter().all(|x| *x >= 0.0));                            // Young at every day: the step that can fail
        assert!((gs - (1.0 - dot / bound(&W, &C, p, &one))).abs() < 1e-12); // consistency only: algebra once 1/p + 1/q = 1
        if p == 2.0 {
            for k in 0..7 {
                println!("young p=2,day {} F G FG gap,{:.4} {:.4} {:.4} {:.4}", k + 1, f[k], h[k], f[k] * h[k], gaps[k]);
            }
        }
        println!("young p={},sum FG sum gaps,{:.6} {:.6}", p, dotp(&f, &h), gs);
    }

    // the same week as an average: uniform probability 1/7 on each day
    let pr = [1.0 / 7.0; 7];
    let avg: f64 = (0..7).map(|k| pr[k] * W[k] * C[k]).sum();
    assert!((bound(&W, &C, 2.0, &pr) - bound(&W, &C, 2.0, &one) / 7.0).abs() < 1e-9 && avg <= bound(&W, &C, 2.0, &pr));
    println!("average,mean wind mean price,{:.6} {:.6}", W.iter().sum::<f64>() / 7.0, C.iter().sum::<f64>() / 7.0);
    println!("average,E[wc] and its p=2 bound,{:.6} {:.6}", avg, bound(&W, &C, 2.0, &pr));

    // correlation, two roads: centred vectors in floats, raw sums in whole numbers
    let (mw, mc) = (W.iter().sum::<f64>() / 7.0, C.iter().sum::<f64>() / 7.0);
    let dw: Vec<f64> = W.iter().map(|a| a - mw).collect();
    let dc: Vec<f64> = C.iter().map(|b| b - mc).collect();
    let r1 = dotp(&dw, &dc) / (norm(&dw, 2.0, &one) * norm(&dc, 2.0, &one));
    let (sw, sc) = (wi.iter().sum::<i64>(), ci.iter().sum::<i64>());
    let num = 7 * di - sw * sc;
    let den = (7 * wi.iter().map(|a| a * a).sum::<i64>() - sw * sw) * (7 * ci.iter().map(|b| b * b).sum::<i64>() - sc * sc);
    let r2 = num as f64 / (den as f64).powf(0.5);
    assert!((r1 - r2).abs() < 1e-12 && r1.abs() <= 1.0);
    println!("correlation,centred sums of squares,{:.6} {:.6}", norm(&dw, 2.0, &one).powf(2.0), norm(&dc, 2.0, &one).powf(2.0));
    println!("correlation,sum of centred products,{:.6}", num as f64 / 7.0);
    println!("correlation,centred route raw route,{:.6} {:.6}", r1, r2);
    println!("correlation,uncentred cosine,{:.6}", dot / bound(&W, &C, 2.0, &one));

    // equality: sizes in proportion
    let v10: Vec<f64> = W.iter().map(|a| 10.0 * a).collect();
    let vsq: Vec<f64> = W.iter().map(|a| a * a).collect();
    let vcu: Vec<f64> = W.iter().map(|a| a.powf(3.0)).collect();
    for (p, v, lab) in [(2.0, &v10, "p=2 price 10w"), (3.0, &vsq, "p=3 price w^2"), (4.0, &vcu, "p=4 price w^3")] {
        let s = dotp(&W, v);
        assert!((bound(&W, v, p, &one) - s).abs() < 1e-9 * s);
        println!("equality,{} sum bound,{} {:.6}", lab, s, bound(&W, v, p, &one));
    }

    let (mut ws, mut cs) = (W.to_vec(), C.to_vec()); // windiest day paired with the highest price
    ws.sort_by(|a, b| a.partial_cmp(b).unwrap());
    cs.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let srt = dotp(&ws, &cs);
    assert!(dot < srt && srt <= bound(&ws, &cs, 2.0, &one));
    println!("equality,sorted pairing revenue and its p=2 bound,{} {:.6}", srt, bound(&ws, &cs, 2.0, &one));

    // what breaks
    let fake33 = norm(&W, 3.0, &one) * norm(&C, 3.0, &one);
    let rev = W.iter().map(|a| a.powf(0.5)).sum::<f64>().powf(2.0) / C.iter().map(|b| 1.0 / b).sum::<f64>();
    assert!(fake33 < dot && rev < dot);
    println!("breaks,p=q=3 not conjugate,{:.6}", fake33);
    let sq = W.iter().map(|a| a.powf(0.5)).sum::<f64>().powf(2.0);
    println!("breaks,p=1/2 q=-1 pieces (sum sqrt w)^2 sum 1/c,{:.6} {:.6}", sq, C.iter().map(|b| 1.0 / b).sum::<f64>());
    println!("breaks,p=1/2 q=-1,{:.6}", rev);
    println!("breaks,sum w vs ||w||_2 counting,{}", j(&[norm(&W, 1.0, &one), norm(&W, 2.0, &one)]));
    println!("breaks,mean w vs ||w||_2 probability,{}", j(&[norm(&W, 1.0, &pr), norm(&W, 2.0, &pr)]));

    // Young's inequality as areas: a = 2, b = 3, p = 3, curve y = x^2
    let (a, b) = (2.0f64, 3.0f64);
    let area_a = simpson(&|x| x * x, 0.0, a, 2000);
    let area_b = simpson(&|x| b - x * x, 0.0, b.powf(0.5), 2000); // left of the curve
    let sliver = simpson(&|x| x * x - b, b.powf(0.5), a, 2000);
    assert!((area_a - a.powf(3.0) / 3.0).abs() < 1e-9 && (area_b - b.powf(1.5) / 1.5).abs() < 1e-6);
    assert!((area_a + area_b - a * b - sliver).abs() < 1e-6);
    println!("young area,A B ab sliver,{}", j(&[area_a, area_b, a * b, sliver]));
    println!("figure,origin 40 210 unit 45,a_x {:.2} b_y {:.2} top_y {:.2} cross_x {:.2} ctrl_x {:.2} {:.2}",
        40.0 + 45.0 * a, 210.0 - 45.0 * b, 210.0 - 45.0 * a * a, 40.0 + 45.0 * b.powf(0.5), 40.0 + 45.0 * a / 2.0, 40.0 + 45.0 * b.powf(0.5) / 2.0);

    // random pairs: SplitMix64, seed 20260929; no pair beats its bound
    let mut rng = Rng(20260929);
    let mut worst = 0.0f64;
    for _ in 0..20000 {
        let p = 1.1 + 6.9 * rng.next();
        let u: Vec<f64> = (0..7).map(|_| 2.0 * rng.next() - 1.0).collect();
        let v: Vec<f64> = (0..7).map(|_| 2.0 * rng.next() - 1.0).collect();
        let s: f64 = u.iter().zip(&v).map(|(x, y)| (x * y).abs()).sum();
        worst = worst.max(s / bound(&u, &v, p, &one));
    }
    assert!(worst <= 1.0 + 1e-12);
    println!("random,20000 pairs p in 1.1 to 8 largest sum/bound,{:.6}", worst);
    println!("All checks passed.");
}
