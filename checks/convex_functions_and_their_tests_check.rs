// Convex functions and their tests -- the same check as the Python, in Rust.  No crates.
// Bitterness B on a 0-10 tasting scale.  t = roast minutes past first crack (0 to 3),
// w = robusta share of the blend (0 to 0.5), k = how fast robusta's bitterness grows with
// roast time (1 in the model).  Three tests -- chord, tangent, curvature -- run on
// a grid of 42 recipes, for B and for two curves that fail; each has an independent road.
type P = (f64, f64);
type M = [[f64; 2]; 2];

fn bk(t: f64, w: f64, k: f64) -> f64 { 1.0 + (t / 2.0).exp() + k * t * w + 4.0 * w * w }
fn b(t: f64, w: f64) -> f64 { bk(t, w, 1.0) }
fn g4(t: f64, w: f64) -> f64 { bk(t, w, 4.0) }
fn grad(t: f64, w: f64, k: f64) -> P { ((t / 2.0).exp() / 2.0 + k * w, k * t + 8.0 * w) }   // slopes, by hand
fn hess(t: f64, k: f64) -> M { [[(t / 2.0).exp() / 4.0, k], [k, 8.0]] }                   // curvatures, by hand
fn s(t: f64) -> f64 { 8.0 / (1.0 + (2.0 - t).exp()) }                                    // levels off

fn num_grad(f: fn(f64, f64) -> f64, p: P) -> P {     // slopes again, by central differences
    let h = 1e-5;
    ((f(p.0 + h, p.1) - f(p.0 - h, p.1)) / (2.0 * h), (f(p.0, p.1 + h) - f(p.0, p.1 - h)) / (2.0 * h))
}
fn num_hess(f: fn(f64, f64) -> f64, p: P) -> M {     // curvatures again, by second differences
    let h = 1e-3;
    let at = |a: f64, c: f64| f(p.0 + a * h, p.1 + c * h);
    let hxy = (at(1.0, 1.0) - at(1.0, -1.0) - at(-1.0, 1.0) + at(-1.0, -1.0)) / (4.0 * h * h);
    [[(at(1.0, 0.0) - 2.0 * at(0.0, 0.0) + at(-1.0, 0.0)) / (h * h), hxy],
     [hxy, (at(0.0, 1.0) - 2.0 * at(0.0, 0.0) + at(0.0, -1.0)) / (h * h)]]
}
fn eig(m: M) -> P {                                   // eigenvalues of a symmetric 2 x 2, smaller first
    let (tr, gap) = (m[0][0] + m[1][1], ((m[0][0] - m[1][1]).powi(2) + 4.0 * m[0][1].powi(2)).sqrt());
    ((tr - gap) / 2.0, (tr + gap) / 2.0)
}
fn dot(u: P, v: P) -> f64 { u.0 * v.0 + u.1 * v.1 }
fn mix(th: f64, x: P, y: P) -> P { (th * x.0 + (1.0 - th) * y.0, th * x.1 + (1.0 - th) * y.1) }

fn three_tests(f: fn(f64, f64) -> f64, k: f64, grid: &[P], pairs: &[(P, P)]) -> (f64, f64, f64) {
    let mut chord = f64::INFINITY;                    // least slack of each test over the grid
    for &(x, y) in pairs { for th in [0.25, 0.5, 0.75] {
        let m = mix(th, x, y);
        chord = chord.min(th * f(x.0, x.1) + (1.0 - th) * f(y.0, y.1) - f(m.0, m.1));
    } }
    let mut tang = f64::INFINITY;
    for &x in grid { for &y in grid { if x != y {
        tang = tang.min(f(y.0, y.1) - f(x.0, x.1) - dot(grad(x.0, x.1, k), (y.0 - x.0, y.1 - x.1)));
    } } }
    let curv = grid.iter().map(|&p| eig(num_hess(f, p)).0).fold(f64::INFINITY, f64::min);
    (chord, tang, curv)
}
fn list(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let grid: Vec<P> = (0..7).flat_map(|i| (0..6).map(move |j| (0.5 * i as f64, 0.1 * j as f64))).collect();
    let mut pairs: Vec<(P, P)> = Vec::new();
    for n in 0..grid.len() { for m in n + 1..grid.len() { pairs.push((grid[n], grid[m])) } }
    let (a, c, m, f) = ((1.0, 0.4), (3.0, 0.1), (2.0, 0.25), (3.0, 0.4));
    let (ba, bc, bm) = (b(a.0, a.1), b(c.0, c.1), b(m.0, m.1));
    let (ga, gc, d) = (grad(a.0, a.1, 1.0), grad(c.0, c.1, 1.0), (c.0 - a.0, c.1 - a.1));
    let (tan_c, floor_f) = (ba + dot(ga, d), ba + dot(ga, (f.0 - a.0, f.1 - a.1)));
    let (ha, na) = (hess(a.0, 1.0), num_hess(b, a));
    let quot: Vec<f64> = [0.5, 0.1, 0.01, 0.001].iter().map(|&sv| { let p = mix(1.0 - sv, a, c); (b(p.0, p.1) - ba) / sv }).collect();
    let mono = dot((gc.0 - ga.0, gc.1 - ga.1), d);
    let (mu, l) = (eig(hess(0.0, 1.0)).0, eig(hess(3.0, 1.0)).1);   // Hessian rises with t only
    let eg: Vec<P> = grid.iter().map(|&p| eig(num_hess(b, p))).collect();
    let mu_g = eg.iter().map(|e| e.0).fold(f64::INFINITY, f64::min);
    let l_g = eg.iter().map(|e| e.1).fold(f64::NEG_INFINITY, f64::max);
    let (lo, hi) = (tan_c + mu / 2.0 * dot(d, d), tan_c + l / 2.0 * dot(d, d));
    let ok_b = three_tests(b, 1.0, &grid, &pairs);
    let bad_g = three_tests(g4, 4.0, &grid, &pairs);
    let axis: Vec<(P, P)> = pairs.iter().cloned().filter(|(x, y)| x.0 == y.0 || x.1 == y.1).collect();
    let axis_g = three_tests(g4, 4.0, &grid, &axis).0;
    let hg = hess(1.0, 4.0);
    let (s1, s3) = (s(1.0), s(3.0));
    let (d1, d3) = (s1 * (8.0 - s1) / 8.0, s3 * (8.0 - s3) / 8.0);             // S' = S(8 - S)/8
    let (c1, c3) = (d1 * (8.0 - 2.0 * s1) / 8.0, d3 * (8.0 - 2.0 * s3) / 8.0); // S'' = S'(8 - 2S)/8
    let n3 = (s(3.001) - 2.0 * s3 + s(2.999)) / 1e-6;
    let tan_s1 = s3 + d3 * (1.0 - 3.0);
    let th: Vec<f64> = (0..11).map(|i| 0.1 * i as f64).collect();
    let nga = num_grad(b, a);
    println!("model: B(t, w) = 1 + e^(t/2) + t*w + 4*w^2; t in [0, 3] min, w in [0, 0.5]");
    println!("prices: arabica 9.00, robusta 5.00 pounds/kg; e^(1/2) = {:.4}, e^1 = {:.4}, e^(3/2) = {:.4}", 0.5f64.exp(), 1f64.exp(), 1.5f64.exp());
    for (name, p, bv) in [("A", a, ba), ("C", c, bc), ("halfway", m, bm)] {
        println!("recipe {} ({:.0} min, {:.0}% robusta): B = {:.4}, cost {:.2} pounds/kg", name, p.0, 100.0 * p.1, bv, 9.0 - 4.0 * p.1);
    }
    println!("chord: average of A and C {:.4}, halfway {:.4}, gap {:.4}", (ba + bc) / 2.0, bm, (ba + bc) / 2.0 - bm);
    println!("slopes at A by formula ({:.4}, {:.4}); by central differences ({:.4}, {:.4})", ga.0, ga.1, nga.0, nga.1);
    println!("tangent at A predicts C: {:.4} + {:.4} + ({:.4}) = {:.4}; true {:.4}; gap {:.4}", ba, ga.0 * d.0, ga.1 * d.1, tan_c, bc, bc - tan_c);
    println!("tangent floor at (3 min, 40%): {:.4} > 6, out of spec untasted; true {:.4}", floor_f, b(f.0, f.1));
    println!("Hessian at A by formula [[{:.4}, {:.4}], [{:.4}, {:.4}]]; by second differences [[{:.4}, {:.4}], [{:.4}, {:.4}]]",
             ha[0][0], ha[0][1], ha[1][0], ha[1][1], na[0][0], na[0][1], na[1][0], na[1][1]);
    println!("at A: determinant {:.4}, trace {:.4}, eigenvalues {:.4} and {:.4}", ha[0][0] * ha[1][1] - 1.0, ha[0][0] + 8.0, eig(ha).0, eig(ha).1);
    println!("determinant 2e^(t/2) - 1 is at least {:.4} for t >= 0; turns negative below t = {:.4}", 2.0 * 0f64.exp() - 1.0, -2.0 * 2f64.ln());
    println!("step 1 quotients, s = 0.5, 0.1, 0.01, 0.001: {}; limit {:.4}; ceiling {:.4}", list(&quot, 4), dot(ga, d), bc - ba);
    println!("step 4 slopes at C ({:.4}, {:.4}); slope change along C - A: {:.4}", gc.0, gc.1, mono);
    println!("mu, least eigenvalue on the box (t = 0): formula {:.4}, grid {:.4}", mu, mu_g);
    println!("L, largest eigenvalue on the box (t = 3): formula {:.4}, grid {:.4}", l, l_g);
    println!("sandwich for C: {:.4} + {:.4} = {:.4} <= {:.4} <= {:.4}", tan_c, mu / 2.0 * dot(d, d), lo, bc, hi);
    println!("grid: {} recipes, {} pairs x 3 weights, {} ordered pairs", grid.len(), pairs.len(), grid.len() * (grid.len() - 1));
    println!("B, least slack: chord {:.6}, tangent {:.6}, least eigenvalue {:.4}", ok_b.0, ok_b.1, ok_b.2);
    println!("k = 4, least slack: chord {:.4}, tangent {:.4}, least eigenvalue {:.4}", bad_g.0, bad_g.1, bad_g.2);
    println!("k = 4, chords along the axes only: least slack {:.6}; diagonal at t = 1: {:.4} and {:.4}; determinant {:.4}", axis_g, hg[0][0], hg[1][1], hg[0][0] * 8.0 - 16.0);
    println!("k = 4 chord: (0 min, 50%) {:.4}, (2 min, 0%) {:.4}, average {:.4}; halfway (1 min, 25%) {:.4}", g4(0.0, 0.5), g4(2.0, 0.0), (g4(0.0, 0.5) + g4(2.0, 0.0)) / 2.0, g4(1.0, 0.25));
    println!("levelling curve: S(1) = {:.4}, S(3) = {:.4}, slope at 3 {:.4}; tangent at 3 claims S(1) >= {:.4}", s1, s3, d3, tan_s1);
    println!("levelling curve: S''(1) = {:.4}, S''(3) = {:.4}, by second differences {:.4}", c1, c3, n3);
    println!("try: k = 1.5, least eigenvalue at t = 0: {:.4}; switch-off k = {:.4}", eig(hess(0.0, 1.5)).0, 2f64.sqrt());
    println!("try: t = -2, determinant {:.4}, least eigenvalue {:.4}", 2.0 * (-1f64).exp() - 1.0, eig(hess(-2.0, 1.0)).0);
    println!("try: tangent at C predicts A: {:.4}; true {:.4}", bc + dot(gc, (-d.0, -d.1)), ba);
    println!("chart theta: {}", list(&th, 1));
    println!("chart B from A to C: {}", list(&th.iter().map(|&x| { let p = mix(1.0 - x, a, c); b(p.0, p.1) }).collect::<Vec<_>>(), 2));
    println!("chart chord: {}", list(&th.iter().map(|&x| (1.0 - x) * ba + x * bc).collect::<Vec<_>>(), 2));
    println!("chart tangent at A: {}", list(&th.iter().map(|&x| ba + x * dot(ga, d)).collect::<Vec<_>>(), 2));
    for &p in &grid {                                                           // slopes two ways
        let (u, v) = (grad(p.0, p.1, 1.0), num_grad(b, p));
        assert!((u.0 - v.0).abs() < 1e-6 && (u.1 - v.1).abs() < 1e-6);
        let (hf, hn) = (hess(p.0, 1.0), num_hess(b, p));                        // curvatures two ways
        assert!((0..2).all(|i| (0..2).all(|j| (hf[i][j] - hn[i][j]).abs() < 1e-4)));
    }
    assert!(ok_b.0.min(ok_b.1).min(ok_b.2) > 0.0 && bad_g.0.max(bad_g.1).max(bad_g.2) < 0.0 && axis_g > 0.0);
    assert!(tan_c < bc && (quot[3] - dot(ga, d)).abs() < 1e-2 && quot.iter().all(|&q| q <= bc - ba) && mono > 0.0);
    assert!((mu - mu_g).abs() < 1e-5 && (l - l_g).abs() < 1e-5 && lo <= bc && bc <= hi);   // mu and L two ways
    assert!(tan_s1 > s1 && c1 > 0.0 && 0.0 > c3 && (n3 - c3).abs() < 1e-5);              // the levelling curve fails
    assert!((tan_s1 - (s3 - (s(3.0 + 1e-5) - s(3.0 - 1e-5)) / 1e-5)).abs() < 1e-6);       // its tangent value two ways
    let along = |sv: f64| { let p = mix(sv, a, c); b(p.0, p.1) };
    assert!((tan_c - ba - (along(1.0 - 1e-5) - along(1.0 + 1e-5)) / 2e-5).abs() < 1e-6); // tangent at A two ways
    let mut mats: Vec<M> = vec![ha, hess(0.0, 1.0), hess(3.0, 1.0), hess(0.0, 1.5), hess(-2.0, 1.0)];
    for fun in [b, g4] { for &p in &grid { mats.push(num_hess(fun, p)); } }
    assert!(mats.iter().all(|h| { let (l1, l2) = eig(*h); l1 <= l2 && (l1 + l2 - h[0][0] - h[1][1]).abs() < 1e-9
        && (l1 * l2 - h[0][0] * h[1][1] + h[0][1] * h[1][0]).abs() < 1e-9 }));   // every eigenvalue pair: sum = trace, product = determinant
    println!("ALL CHECKS PASS");
}
