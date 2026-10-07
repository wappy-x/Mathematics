// Independence -- the check behind the card. Rust std only.
// Roads: the product formula, a count over every outcome, a seeded simulation.
fn splitmix(s: &mut u64) -> u64 { // SplitMix64: advance the state, return a 64-bit draw
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn uniform(s: &mut u64) -> f64 { (splitmix(s) >> 11) as f64 / 9007199254740992.0 }
fn f4(x: f64) -> String { format!("{:.4}", x) }
// enumerated road: add the weights of outcomes in the event
fn prob<T>(out: &[(T, u32)], ev: &dyn Fn(&T) -> bool) -> f64 {
    let tot: u32 = out.iter().map(|x| x.1).sum();
    out.iter().filter(|x| ev(&x.0)).map(|x| x.1).sum::<u32>() as f64 / tot as f64
}
type Ev<'a, T> = &'a dyn Fn(&T) -> bool;
// every choice of two or more events: does the product rule hold?
fn equations<T>(out: &[(T, u32)], evs: &[Ev<T>]) -> (u32, u32) {
    let (mut held, mut total) = (0, 0);
    for m in 1u32..(1 << evs.len()) {
        if m.count_ones() < 2 { continue; }
        total += 1;
        let chosen: Vec<&Ev<T>> = (0..evs.len()).filter(|i| m >> i & 1 == 1).map(|i| &evs[i]).collect();
        let joint = prob(out, &|o: &T| chosen.iter().all(|e| e(o)));
        let prod: f64 = chosen.iter().map(|e| prob(out, **e)).product();
        if (joint - prod).abs() < 1e-12 { held += 1; }
    }
    (held, total)
}
fn main() {
    // ---- two fair coins, a quarter and a dime: 4 outcomes, weight 1 each ----
    let mut coins = vec![];
    for q in [1, 0] { for d in [1, 0] { coins.push(((q, d), 1u32)); } }
    let a = |o: &(i32, i32)| o.0 == 1; // quarter heads
    let b = |o: &(i32, i32)| o.1 == 1; // dime heads
    let c = |o: &(i32, i32)| o.0 == o.1; // the coins match
    let (pa, pb, pab) = (prob(&coins, &a), prob(&coins, &b), prob(&coins, &|o| a(o) && b(o)));
    assert!((pab - pa * pb).abs() < 1e-12); // counted overlap equals the product of the counted chances
    println!("two coins: P(A) = {}  P(B) = {}  P(A and B) = {}  product = {}", f4(pa), f4(pb), f4(pab), f4(pa * pb));
    println!("given the dime: P(A | B) = {}", f4(pab / pb));
    let p_a_not_b = prob(&coins, &|o| a(o) && !b(o));
    assert!((p_a_not_b - pa * (1.0 - pb)).abs() < 1e-12 && prob(&coins, &|o| a(o) && !a(o)) == 0.0 && pa * (1.0 - pa) > 0.0);
    println!("A with not-B: joint = {}  product = {}", f4(p_a_not_b), f4(pa * (1.0 - pb)));
    println!("A with itself: joint = {}  product = {}", f4(prob(&coins, &|o| a(o) && a(o))), f4(pa * pa));
    println!("A with not-A: joint = {}  product = {}", f4(prob(&coins, &|o| a(o) && !a(o))), f4(pa * (1.0 - pa)));
    // ---- pairwise versus mutual ----
    let (h3, t3) = equations(&coins, &[&a, &b, &c]);
    let pabc = prob(&coins, &|o| a(o) && b(o) && c(o));
    assert!((h3, t3) == (3, 4) && (pabc - 0.125).abs() > 0.1); // pairs pass, the triple fails
    println!("match event: P(C) = {}  P(A and C) = {}  P(B and C) = {}", f4(prob(&coins, &c)),
        f4(prob(&coins, &|o| a(o) && c(o))), f4(prob(&coins, &|o| b(o) && c(o))));
    println!("triple: P(A and B and C) = {}  product = {}  equations holding = {} of {}", f4(pabc), f4(0.5f64.powi(3)), h3, t3);
    let mut three = vec![];
    for q in [1, 0] { for d in [1, 0] { for k in [1, 0] { three.push(([q, d, k], 1u32)); } } }
    let (e0, e1, e2) = (|o: &[i32; 3]| o[0] == 1, |o: &[i32; 3]| o[1] == 1, |o: &[i32; 3]| o[2] == 1);
    let (h, t) = equations(&three, &[&e0, &e1, &e2]);
    assert!((h, t) == (4, 4)); // three separate coins pass every equation
    println!("three separate coins: equations holding = {} of {}", h, t);
    // ---- conditioning can break independence: learn 'at least one head' ----
    let pm = prob(&coins, &|o| a(o) || b(o));
    let pam = prob(&coins, &|o| a(o) && (a(o) || b(o))) / pm;
    let pbm = prob(&coins, &|o| b(o) && (a(o) || b(o))) / pm;
    assert!((pab / pm - pam * pbm).abs() > 0.1); // given M the product rule fails
    println!("given M: P(A | M) = {}  P(A and B | M) = {}  product = {}", f4(pam), f4(pab / pm), f4(pam * pbm));
    // ---- a bag: fair coin or bent coin (heads 0.9), chosen 50/50, tossed twice ----
    let qb = 0.9f64;
    let mut bag = vec![]; // weights out of 200
    for x in [1, 0] { for y in [1, 0] { bag.push(((0, x, y), 25u32)); } }
    for x in [1, 0] { for y in [1, 0] { bag.push(((1, x, y), (if x == 1 { 9 } else { 1 }) * (if y == 1 { 9 } else { 1 }))); } }
    let h1 = |o: &(i32, i32, i32)| o.1 == 1;
    let h2 = |o: &(i32, i32, i32)| o.2 == 1;
    let (eh1, ehh) = (prob(&bag, &h1), prob(&bag, &|o| h1(o) && h2(o)));
    let (fh1, fhh) = (0.5 * 0.5 + 0.5 * qb, 0.5 * 0.25 + 0.5 * qb * qb); // formula road: total probability
    assert!((eh1 - fh1).abs() < 1e-12 && (ehh - fhh).abs() < 1e-12 && ehh - eh1 * eh1 > 0.03); // dependent
    println!("bag: P(H1) = {}  P(H1 and H2) = {}  product = {}  P(H2 | H1) = {}", f4(eh1), f4(ehh), f4(eh1 * eh1), f4(ehh / eh1));
    for (ci, name) in [(0, "fair"), (1, "bent")] {
        let sub: Vec<_> = bag.iter().filter(|x| x.0 .0 == ci).cloned().collect();
        println!("given {}: P(H1 and H2) = {}  product = {}", name, f4(prob(&sub, &|o| h1(o) && h2(o))), f4(prob(&sub, &h1) * prob(&sub, &h2)));
    }
    println!("chart, all n tosses heads: n, true, if independent");
    for n in 1..9 {
        println!("chart, {}, {:.2}, {:.2}", n, 0.5 * 0.5f64.powi(n) + 0.5 * qb.powi(n), fh1.powi(n));
    }
    println!("eight heads: true {}  if independent {}", f4(0.5 * 0.5f64.powi(8) + 0.5 * qb.powi(8)), f4(fh1.powi(8)));
    // ---- simulation road, seed 20260928, 100000 trials each ----
    let (mut s, nn) = (20260928u64, 100000u32);
    println!("simulation: seed {}, {} trials", s, nn);
    let (mut kab, mut khh) = (0u32, 0u32);
    for _ in 0..nn {
        let (u1, u2) = (uniform(&mut s), uniform(&mut s));
        if u1 < 0.5 && u2 < 0.5 { kab += 1; }
        let p = if uniform(&mut s) < 0.5 { 0.5 } else { qb };
        let (u1, u2) = (uniform(&mut s), uniform(&mut s));
        if u1 < p && u2 < p { khh += 1; }
    }
    for (name, k, exact) in [("coins P(A and B)", kab, pab), ("bag P(H1 and H2)", khh, ehh)] {
        let est = k as f64 / nn as f64;
        let se = (est * (1.0 - est) / nn as f64).sqrt();
        assert!((est - exact).abs() < 4.0 * se); // simulation agrees within four standard errors
        println!("simulated {} = {}, standard error {}", name, f4(est), f4(se));
    }
    // ---- Simpson: two mints, quarters and dimes, accepted by a counting machine ----
    let mints = [("X", (90u32, 100u32), (250u32, 400u32)), ("Y", (340, 400), (60, 100))];
    let mut pool = [0.0f64; 2];
    let mut rate = [[0.0f64; 2]; 2];
    let mut share = [0.0f64; 2];
    for (i, &(m, (ia, iq), (ib, id))) in mints.iter().enumerate() {
        let (aq, nq, ad, nd) = (ia as f64, iq as f64, ib as f64, id as f64);
        let wq = nq / (nq + nd);
        pool[i] = wq * (aq / nq) + (1.0 - wq) * (ad / nd); // weighted road
        assert!((pool[i] - (aq + ad) / (nq + nd)).abs() < 1e-12); // direct count road
        rate[i] = [aq / nq, ad / nd];
        share[i] = wq;
        println!("mint {}: quarters {}/{} = {}, dimes {}/{} = {}, all {}/{}, quarter share {}, pooled {}",
            m, ia, iq, f4(aq / nq), ib, id, f4(ad / nd), ia + ib, iq + id, f4(wq), f4(pool[i]));
    }
    let ([xq, xd], [yq, yd], wx, wy) = (rate[0], rate[1], share[0], share[1]);
    let within = wx * (xq - yq) + (1.0 - wx) * (xd - yd);
    let mix = (wx - wy) * (yq - yd);
    assert!(xq > yq && xd > yd && pool[0] < pool[1] && (within + mix - (pool[0] - pool[1])).abs() < 1e-12);
    println!("gap X - Y: quarters {}  dimes {}", f4(xq - yq), f4(xd - yd));
    println!("gap X - Y: within types = {}  mix = {}  total = {}", f4(within), f4(mix), f4(within + mix));
    println!("same 50/50 mix: X = {}  Y = {}", f4((xq + xd) / 2.0), f4((yq + yd) / 2.0));
    // ---- a real misuse: one cot death in 8,543 squared for two ----
    println!("squared 1 in 8543: 1 in {}", 8543u64 * 8543);
    let (x0, y0, side) = (60.0, 20.0, 200.0); // the picture, drawn to scale
    println!("figure, square x {}-{}, A x {}-{}, B y {}-{}, overlap share {}", x0, x0 + side, x0, x0 + (side * pa).round(), y0, y0 + (side * pb).round(), f4(pab));
}
