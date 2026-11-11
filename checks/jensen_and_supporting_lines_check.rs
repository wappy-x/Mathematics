// Jensen's inequality and supporting planes -- the same check as the Python, in Rust.
// No crates.  A blend is (x, y): the Brazil and Colombia shares, Ethiopia the rest.
// Cost in pounds a kilo = the beans + a taste penalty for missing strength 6, acidity 5.
type P = (f64, f64);
fn parts(x: f64, y: f64) -> (f64, f64, f64) {     // bean cost, strength, acidity
    let e = 1.0 - x - y;
    (7.0 * x + 9.0 * y + 12.0 * e, 8.0 * x + 6.0 * y + 4.0 * e, 2.0 * x + 6.0 * y + 8.0 * e)
}
fn cost(x: f64, y: f64) -> f64 {
    let (b, s, a) = parts(x, y);
    b + (s - 6.0).powi(2) + (a - 5.0).powi(2)
}
fn grad(x: f64, y: f64) -> P {                     // the gradient, by the chain rule
    let (_, s, a) = parts(x, y);
    (-5.0 + 8.0 * (s - 6.0) - 12.0 * (a - 5.0), -3.0 + 4.0 * (s - 6.0) - 4.0 * (a - 5.0))
}
const HESS: [[f64; 2]; 2] = [[104.0, 40.0], [40.0, 16.0]];   // 2(g g' + h h')
fn quad(dx: f64, dy: f64) -> f64 { HESS[0][0] * dx * dx + 2.0 * HESS[0][1] * dx * dy + HESS[1][1] * dy * dy }
fn plane(m: P, s: P, x: f64, y: f64) -> f64 { cost(m.0, m.1) + s.0 * (x - m.0) + s.1 * (y - m.1) }
fn grid(step: f64) -> Vec<P> {                      // every blend with shares on the grid
    let n = (1.0 / step).round() as i32;
    let mut v = vec![];
    for i in 0..=n { for j in 0..=(n - i) { v.push((i as f64 / n as f64, j as f64 / n as f64)); } }
    v
}
fn surcharge(x: f64, y: f64) -> f64 { cost(x, y) + 4.0 * (1.0 - x - y - 0.25).max(0.0) }
fn two_style(x: f64, y: f64) -> f64 {              // NOT convex: two strengths are paid for
    let (b, s, _) = parts(x, y);
    b + 4.0 * (s - 6.0).powi(2).min((s - 7.0).powi(2))
}
fn f2(v: f64) -> String { format!("{:.2}", v) }
fn f4(v: f64) -> String { format!("{:.4}", if v.abs() < 1e-12 { 0.0 } else { v }) }
fn minf(it: impl Iterator<Item = f64>) -> f64 { it.fold(f64::INFINITY, f64::min) }
fn main() {
    let (bold, bright): (P, P) = ((0.7, 0.1), (0.3, 0.4));
    let mix: P = ((bold.0 + bright.0) / 2.0, (bold.1 + bright.1) / 2.0);
    println!("beans in pounds a kilo: Brazil 7, Colombia 9, Ethiopia 12; targets: strength 6, acidity 5");
    println!("{:<14}{:>7}{:>7}{:>7}{:>7}{:>7}{:>7}{:>8}{:>7}", "blend", "Brazil", "Colomb", "Ethiop",
             "beans", "strgth", "acid", "penalty", "cost");
    for (name, z) in [("Bold", bold), ("Bright", bright), ("half and half", mix)] {
        let (b, s, a) = parts(z.0, z.1);
        let mut line = format!("{:<14}", name);
        for v in [z.0, z.1, 1.0 - z.0 - z.1, b, s, a] { line.push_str(&format!("{:>7.2}", v)); }
        println!("{}{:>8.2}{:>7.2}", line, cost(z.0, z.1) - b, cost(z.0, z.1));
    }
    let cm = cost(mix.0, mix.1);
    let avg2 = (cost(bold.0, bold.1) + cost(bright.0, bright.1)) / 2.0;   // road 1
    let d = (bold.0 - bright.0, bold.1 - bright.1);
    println!("average of the two costs {}; cost of the mix {}; gap {}; by the Hessian, d = ({}, {}), d'Hd = {}, /8 = {}",
             f2(avg2), f2(cm), f2(avg2 - cm), f2(d.0), f2(d.1), f2(quad(d.0, d.1)), f2(quad(d.0, d.1) / 8.0));
    let h = 1e-5;                                                           // road 2
    let gn = ((cost(mix.0 + h, mix.1) - cost(mix.0 - h, mix.1)) / (2.0 * h),
              (cost(mix.0, mix.1 + h) - cost(mix.0, mix.1 - h)) / (2.0 * h));
    let g = grad(mix.0, mix.1);
    println!("gradient at the mix, formula ({}, {}); central difference ({}, {})", f2(g.0), f2(g.1), f2(gn.0), f2(gn.1));
    let k = 1e-3;
    let at = |a: f64, b: f64| cost(mix.0 + a, mix.1 + b);
    let e = [(k, 0.0), (0.0, k)];
    let mut hn = [[0.0; 2]; 2];
    for i in 0..2 { for j in 0..2 {
        let (p, q) = (e[i], e[j]);
        hn[i][j] = (at(p.0 + q.0, p.1 + q.1) - at(p.0 - q.0, p.1 - q.1) - at(q.0 - p.0, q.1 - p.1)
                    + at(-p.0 - q.0, -p.1 - q.1)) / (4.0 * k * k);
    } }
    let det = HESS[0][0] * HESS[1][1] - HESS[0][1].powi(2);
    println!("Hessian, formula [[104, 40], [40, 16]]; second differences [[{:.2}, {:.2}], [{:.2}, {:.2}]]; determinant {}, trace {}",
             hn[0][0], hn[0][1], hn[1][0], hn[1][1], det, HESS[0][0] + HESS[1][1]);
    let (pb, pr) = (plane(mix, g, bold.0, bold.1), plane(mix, g, bright.0, bright.1));
    println!("plane at the mix: {} + {}(x - 0.50) + {}(y - 0.25); at Bold {}, at Bright {}, average {}",
             f2(cm), f2(g.0), f2(g.1), f2(pb), f2(pr), f2((pb + pr) / 2.0));
    let fine = grid(0.01);
    let gap = |z: &P| cost(z.0, z.1) - plane(mix, g, z.0, z.1);
    let mut low = fine[0];
    for z in &fine { if gap(z) < gap(&low) { low = *z; } }
    println!("cost minus plane over {} blends on a 0.01 grid: smallest {}, at ({}, {})", fine.len(), f4(gap(&low)), f2(low.0), f2(low.1));
    let coarse = grid(0.05);                                                // a plane at every blend
    let mut margin = f64::INFINITY;
    for p in &coarse { for z in &coarse { if p != z {
        margin = margin.min(cost(z.0, z.1) - plane(*p, grad(p.0, p.1), z.0, z.1));
    } } }
    println!("tangent plane at each of {} blends, against the other {}: smallest margin {}", coarse.len(), coarse.len() - 1, f4(margin));
    let week = [(5, -5), (-5, 0), (0, 5), (5, 5), (-5, -5)];                // road 3
    let costs: Vec<f64> = week.iter().map(|&(a, b)| cost(mix.0 + a as f64 / 100.0, mix.1 + b as f64 / 100.0)).collect();
    let list: Vec<String> = week.iter().zip(&costs).map(|(&(a, b), c)| format!("({:+}, {:+}) {}", a, b, f2(*c))).collect();
    println!("week, batch misses in points (Brazil, Colombia), cost: {}", list.join("; "));
    let wavg = costs.iter().sum::<f64>() / costs.len() as f64;
    let spread = week.iter().map(|&(a, b)| quad(a as f64 / 100.0, b as f64 / 100.0)).sum::<f64>() / week.len() as f64 / 2.0;
    println!("week average {}; floor from the recipe alone {}; gap {}; by half the average d'Hd {}", f2(wavg), f2(cm), f2(wavg - cm), f2(spread));
    let ts: Vec<f64> = (0..=10).map(|i| i as f64 / 10.0).collect();         // the chart
    let seg: Vec<P> = ts.iter().map(|t| (bright.0 + t * d.0, bright.1 + t * d.1)).collect();
    let join = |v: Vec<String>| v.join(", ");
    println!("chart, share of Bold {}", join(ts.iter().map(|t| format!("{:.1}", t)).collect()));
    println!("chart, cost          {}", join(seg.iter().map(|z| f2(cost(z.0, z.1))).collect()));
    let (cb, cr) = (cost(bold.0, bold.1), cost(bright.0, bright.1));
    println!("chart, chord         {}", join(ts.iter().map(|t| f2(cr + t * (cb - cr))).collect()));
    println!("chart, plane         {}", join(seg.iter().map(|z| f2(plane(mix, g, z.0, z.1))).collect()));
    let mut worst = vec![];                                                  // a crease at the mix
    for lam in [0.0, 0.5, 1.0, 1.25] {
        let s = (g.0 - 4.0 * lam, g.1 - 4.0 * lam);
        let w = minf(fine.iter().map(|z| surcharge(z.0, z.1) - plane(mix, s, z.0, z.1)));
        println!("crease, slopes ({}, {}): smallest cost minus plane {}", f2(s.0), f2(s.1), f4(w));
        worst.push(w);
    }
    let cav = (surcharge(bold.0, bold.1) + surcharge(bright.0, bright.1)) / 2.0;
    println!("crease, Jensen: Bold {}, Bright {}, mix {}, average {}", f2(surcharge(bold.0, bold.1)),
             f2(surcharge(bright.0, bright.1)), f2(surcharge(mix.0, mix.1)), f2(cav));
    let wm = (0.4 * (bold.0 + bright.0), 0.4 * (bold.1 + bright.1));          // weights 0.4 and 0.4: not shares
    println!("weights 0.4 and 0.4, adding to 0.8: blend ({}, {}) costs {}, against 0.4 x {} + 0.4 x {} = {}",
             f2(wm.0), f2(wm.1), f2(cost(wm.0, wm.1)), f2(cb), f2(cr), f2(0.4 * cb + 0.4 * cr));
    let (tb, tr, tm) = (two_style(bold.0, bold.1), two_style(bright.0, bright.1), two_style(mix.0, mix.1));
    println!("mistake 1, two-style cost: Bold {}, Bright {}, mix {}, average {}", f2(tb), f2(tr), f2(tm), f2((tb + tr) / 2.0));
    let (bb, br, bm) = (parts(bold.0, bold.1).0, parts(bright.0, bright.1).0, parts(mix.0, mix.1).0);
    println!("mistake 2, beans only: mix {}, average {}; true mix cost {}, true week average {}", f2(bm), f2((bb + br) / 2.0), f2(cm), f2(wavg));
    println!("mistake 3, recipe cost as a ceiling: {} against the week's {}", f2(cm), f2(wavg));
    assert!((avg2 - cm - quad(d.0, d.1) / 8.0).abs() < 1e-9 && (avg2 - cm - 1.06).abs() < 1e-9);
    let gv = [g.0, g.1]; let gnv = [gn.0, gn.1];
    for i in 0..2 { assert!((gv[i] - gnv[i]).abs() < 1e-6); for j in 0..2 { assert!((hn[i][j] - HESS[i][j]).abs() < 1e-3); } }
    assert!(pb < cb && pr < cr);
    assert!(gap(&low).abs() < 1e-12 && low == (0.5, 0.25) && margin > 0.0);
    assert!((wavg - cm - spread).abs() < 1e-9 && (wavg - 9.39).abs() < 1e-9);
    assert!(worst[0].min(worst[1]).min(worst[2]) > -1e-12 && worst[3] < -0.01 && cav > surcharge(mix.0, mix.1));
    assert!(cost(wm.0, wm.1) > 0.4 * cb + 0.4 * cr);
    assert!(tm > (tb + tr) / 2.0);
    println!("ALL CHECKS PASS");
}
