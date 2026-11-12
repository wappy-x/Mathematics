// Softmax and cross-entropy -- the same check as the Python file, in Rust.  std only.
// 20,000 synthetic orders (SplitMix64, seed 2026), one feature: weight in kg.
// Classes 0 letter, 1 parcel, 2 pallet.  Letter's score is pinned at 0.
fn splitmix(s: &mut u64) -> f64 {
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
}
fn softmax(z: &[f64]) -> Vec<f64> {   // subtract the largest score, exponentiate, divide by the total
    let m = z.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    let e: Vec<f64> = z.iter().map(|t| (t - m).exp()).collect();
    let s: f64 = e.iter().sum();
    e.iter().map(|t| t / s).collect()
}
fn naive_softmax(z: &[f64]) -> Option<Vec<f64>> { // no shift: fails once a score passes about 709
    let e: Vec<f64> = z.iter().map(|t| t.exp()).collect();
    if e.iter().any(|t| t.is_infinite()) { return None; }
    let s: f64 = e.iter().sum();
    Some(e.iter().map(|t| t / s).collect())
}
fn ce_bits(p: &[f64], q: &[f64]) -> f64 { // cross-entropy H(p, q) in bits; infinite if q misses a p outcome
    if p.iter().zip(q).any(|(a, b)| *a > 0.0 && *b == 0.0) { return f64::INFINITY; }
    -p.iter().zip(q).filter(|(a, _)| **a > 0.0).map(|(a, b)| a * b.log2()).sum::<f64>()
}
fn scores(th: &[f64], x: f64) -> Vec<f64> { vec![0.0, th[0] + th[1] * x, th[2] + th[3] * x] }
const TRUE: [f64; 4] = [-3.0, 2.0, -13.0, 2.5]; // the rule the synthetic orders were drawn from
fn out(label: &str, v: &[f64]) {
    let mut line = format!("{:<34}", label);
    for t in v { line += &format!("{:>10.4}", t); }
    println!("{}", line);
}
fn nll_bits(z: &[f64], c: usize) -> f64 { // -log2 of softmax(z)[c] in one step: -z_c + log-sum-exp, shifted
    let m = z.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    (m - z[c] + z.iter().map(|t| (t - m).exp()).sum::<f64>().ln()) / 2f64.ln()
}
fn risk(th: &[f64], x: &[f64], y: &[usize]) -> f64 { // average loss in bits over the orders
    x.iter().zip(y).map(|(xi, &c)| nll_bits(&scores(th, *xi), c)).sum::<f64>() / x.len() as f64
}
fn grad_hess(th: &[f64], x: &[f64], y: &[usize]) -> (Vec<f64>, Vec<Vec<f64>>) { // in nats
    let n = x.len() as f64;
    let (mut g, mut h) = (vec![0.0; 4], vec![vec![0.0; 4]; 4]);
    for (xi, &c) in x.iter().zip(y) {
        let q = softmax(&scores(th, *xi)); let f = [1.0, *xi];
        for a in 0..2 { for i in 0..2 {
            g[2*a+i] += (q[a+1] - if c == a + 1 { 1.0 } else { 0.0 }) * f[i] / n;
            for b in 0..2 { for j in 0..2 {
                h[2*a+i][2*b+j] += q[a+1] * (if a == b { 1.0 } else { 0.0 } - q[b+1]) * f[i] * f[j] / n;
            }}
        }}
    }
    (g, h)
}
fn solve(h: &[Vec<f64>], g: &[f64]) -> Vec<f64> { // Gaussian elimination, 4 by 4
    let mut a: Vec<Vec<f64>> = (0..4).map(|r| { let mut row = h[r].clone(); row.push(g[r]); row }).collect();
    for c in 0..4 { for r in c + 1..4 {
        let m = a[r][c] / a[c][c];
        for k in c..5 { a[r][k] -= m * a[c][k]; }
    }}
    let mut d = vec![0.0; 4];
    for r in (0..4).rev() {
        let s: f64 = (r + 1..4).map(|k| a[r][k] * d[k]).sum();
        d[r] = (a[r][4] - s) / a[r][r];
    }
    d
}
fn main() {
    let (mut s, mut x, mut y) = (2026u64, Vec::new(), Vec::new());
    for _ in 0..20000 {
        let xi = 0.1 * 500f64.powf(splitmix(&mut s)); // weights spread evenly in ratio, 0.1 to 50 kg
        let u = splitmix(&mut s); let p = softmax(&scores(&TRUE, xi));
        x.push(xi); y.push(if u < p[0] { 0 } else if u < p[0] + p[1] { 1 } else { 2 });
    }
    let n = x.len() as f64;
    let counts: Vec<f64> = (0..3).map(|k| y.iter().filter(|&&c| c == k).count() as f64).collect();
    let (mut th, mut trace) = (vec![0.0; 4], Vec::new());
    for _ in 0..30 { // road 1: Newton's method on the average cross-entropy
        trace.push(risk(&th, &x, &y)); let (g, h) = grad_hess(&th, &x, &y);
        if g.iter().map(|t| t.abs()).fold(0.0, f64::max) < 1e-10 { break; }
        let d = solve(&h, &g); th = th.iter().zip(&d).map(|(a, b)| a - b).collect();
    }
    let r = *trace.last().unwrap();
    println!("orders by class (letter, parcel, pallet): {} {} {}", counts[0], counts[1], counts[2]);
    out("fitted b_parcel w_parcel", &th[0..2]); out("fitted b_pallet w_pallet", &th[2..4]); out("true rule b1 w1 b2 w2", &TRUE);
    out("class boundaries, kg", &[-th[0] / th[1], (th[0] - th[2]) / (th[3] - th[1])]);
    println!("loss by Newton step, bits: {}", trace.iter().map(|t| format!("{:.4}", t)).collect::<Vec<_>>().join(" "));
    out("fitted loss R, bits; perplexity", &[r, 2f64.powf(r)]);
    out("blind guess log2 3; perplexity", &[3f64.log2(), 3.0]);
    // road 2: nudge every parameter both ways; the loss must rise each time
    let mut lowest = f64::INFINITY;
    for j in 0..4 { for h in [0.01, -0.01] {
        let mut t = th.clone(); t[j] += h; lowest = lowest.min(risk(&t, &x, &y));
    }}
    out("smallest nudge rise, micro-bits", &[(lowest - r) * 1e6]); assert!(lowest > r);
    // road 3: at the minimum the predicted counts equal the observed counts
    let pred: Vec<f64> = (0..3).map(|k| x.iter().map(|xi| softmax(&scores(&th, *xi))[k]).sum()).collect();
    out("predicted counts", &pred); assert!((0..3).all(|k| (pred[k] - counts[k]).abs() < 1e-6));
    // consistency check: class shares only; their loss is the entropy of the shares
    let sh: Vec<f64> = counts.iter().map(|c| c / n).collect();
    let th0 = [(sh[1] / sh[0]).ln(), 0.0, (sh[2] / sh[0]).ln(), 0.0];
    let r0 = risk(&th0, &x, &y);
    out("shares only: loss; entropy H", &[r0, ce_bits(&sh, &sh)]); assert!((r0 - ce_bits(&sh, &sh)).abs() < 1e-9);
    out("bits saved by knowing weight", &[r0 - r]);
    // road 4: truth against fit.  H(p, q) = H(p) + D(p || q), order by order, is a consistency check
    let (mut hp, mut hpq, mut dpq, mut sq) = (0.0, 0.0, 0.0, 0.0);
    for xi in &x {
        let (p, q) = (softmax(&scores(&TRUE, *xi)), softmax(&scores(&th, *xi)));
        hp += ce_bits(&p, &p) / n; hpq += ce_bits(&p, &q) / n;
        dpq += (0..3).map(|k| p[k] * (p[k] / q[k]).log2()).sum::<f64>() / n;
    }
    for (xi, &c) in x.iter().zip(&y) { sq += (nll_bits(&scores(&th, *xi), c) - r).powi(2) / n; }
    let se = (sq / n).sqrt();
    out("floor H(p); H(p,q); D(p||q)", &[hp, hpq, dpq]); out("true rule's loss on the orders", &[risk(&TRUE, &x, &y)]);
    assert!((hpq - (hp + dpq)).abs() < 1e-9 && dpq > 0.0);
    out("fitted loss vs H(p,q): gap, SE", &[r - hpq, se]); assert!((r - hpq).abs() < 4.0 * se);
    let w = 2.0 * n * 2f64.ln() * (risk(&TRUE, &x, &y) - r); // Wilks: twice the fit's log-likelihood gain over the rule, in nats
    let chance = (-w / 2.0).exp() * (1.0 + w / 2.0);          // chi-square, 4 degrees of freedom: the chance of a gain above w
    out("fit vs rule: 2 ln LR; chance", &[w, chance]); assert!(chance > 0.001);
    // the worked order: 2 kg, packed as a parcel
    let z = scores(&th, 2.0); let q = softmax(&z);
    let m = z.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    let e: Vec<f64> = z.iter().map(|t| (t - m).exp()).collect();
    out("2 kg: scores", &z); out("2 kg: shifted scores", &z.iter().map(|t| t - m).collect::<Vec<_>>());
    out("2 kg: exp", &e); out("2 kg: total; probabilities", &[e.iter().sum(), q[0], q[1], q[2]]);
    out("2 kg: odds parcel to letter", &[q[1] / q[0], (z[1] - z[0]).exp()]); assert!((q[1] / q[0] - (z[1] - z[0]).exp()).abs() < 1e-12);
    out("2 kg: loss bits if L, P, Pal", &q.iter().map(|t| -t.log2()).collect::<Vec<_>>());
    out("2 kg: loss in nats if parcel", &[-q[1].ln()]);
    let gz: Vec<f64> = (0..3).map(|k| q[k] - if k == 1 { 1.0 } else { 0.0 }).collect();
    out("2 kg: gradient q - y", &gz);
    let mut fd = Vec::new();
    for k in 0..3 { // road 5: the gradient by finite differences, in nats
        let (mut zp, mut zm) = (z.clone(), z.clone()); zp[k] += 1e-6; zm[k] -= 1e-6;
        fd.push((softmax(&zm)[1].ln() - softmax(&zp)[1].ln()) / 2e-6);
    }
    out("2 kg: gradient by nudging", &fd); assert!((0..3).all(|k| (gz[k] - fd[k]).abs() < 1e-6));
    let lam = 1.0 / (1.0 + (-(z[1] - z[0])).exp()); // road 6: two classes give the logistic curve
    let two = softmax(&z[..2])[1];
    out("two classes: softmax; logistic", &[two, lam]); assert!((two - lam).abs() < 1e-12);
    // what breaks
    let zs: f64 = z.iter().sum();
    out("wrong: scores / their sum", &z.iter().map(|t| t / zs + 0.0).collect::<Vec<_>>());
    let big = scores(&th, 400.0);
    println!("{:<34} {}", "wrong: no shift, 400 kg", if naive_softmax(&big).is_none() { "overflow" } else { "ok" });
    let sb = softmax(&big); out("400 kg pallet score; right answer", &[big[2], sb[0], sb[1], sb[2]]);
    out("wrong: ln as bits; nats per bit", &[-q[1].ln(), 2f64.ln()]); out("wrong: arguments swapped H(q, y)", &[ce_bits(&q, &[0.0, 1.0, 0.0])]);
    out("2 kg order labelled pallet, bits", &[-q[2].log2()]); out("  = this many average orders", &[-q[2].log2() / r]);
    out("loss at 0.51, 0.99; at 0.49, 0.01", &[0.51f64, 0.99, 0.49, 0.01].iter().map(|t| -t.log2()).collect::<Vec<_>>());
    // try changing
    out("try: 20 kg order", &softmax(&scores(&th, 20.0)));
    out("try: every score + 100", &softmax(&z.iter().map(|t| t + 100.0).collect::<Vec<_>>()));
    out("try: every score x 2", &softmax(&z.iter().map(|t| 2.0 * t).collect::<Vec<_>>()));
    println!("chart, kg {}", (0..37).step_by(2).map(|w| w.to_string()).collect::<Vec<_>>().join(" "));
    for (k, name) in ["letter", "parcel", "pallet"].iter().enumerate() {
        let v: Vec<String> = (0..37).step_by(2).map(|w| format!("{:.2}", softmax(&scores(&th, w as f64))[k])).collect();
        println!("chart, {} {}", name, v.join(" "));
    }
    println!("ALL CHECKS PASS");
}
