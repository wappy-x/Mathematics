// Area of the 7-8-9 m bed, std only.  Road one: Heron, from the sides.
// Road two: the bed on a grid, its height by Pythagoras, then thin strips.

fn root(v: f64) -> f64 {                   // square root by Newton's rule
    let mut r = v.max(1.0);
    for _ in 0..60 {
        r = (r + v / r) / 2.0;
    }
    r
}

fn product(a: f64, b: f64, c: f64) -> f64 { // Heron's product s(s-a)(s-b)(s-c)
    let s = (a + b + c) / 2.0;
    s * (s - a) * (s - b) * (s - c)
}

fn heron(a: f64, b: f64, c: f64) -> f64 {
    root(product(a, b, c))
}

fn corner(a: f64, b: f64, c: f64) -> (f64, f64) { // C above base AB, A at (0, 0)
    let x = (b * b + c * c - a * a) / (2.0 * c);
    (x, root(b * b - x * x))
}

fn strips(c: f64, x: f64, h: f64, n: usize) -> f64 { // n strips, read at the middle
    let w = c / n as f64;
    (0..n).map(|i| {
        let t = (i as f64 + 0.5) * w;
        w * if t < x { h * t / x } else { h * (c - t) / (c - x) }
    }).sum()
}

fn height_to(p: (f64, f64), q: (f64, f64), r: (f64, f64)) -> f64 {
    let (dx, dy) = (r.0 - q.0, r.1 - q.1);
    let k = ((p.0 - q.0) * dx + (p.1 - q.1) * dy) / (dx * dx + dy * dy);
    let (fx, fy) = (q.0 + k * dx, q.1 + k * dy); // the foot, by the dot product
    root((p.0 - fx).powi(2) + (p.1 - fy).powi(2))
}

fn main() {
    let (a, b, c) = (7.0_f64, 8.0_f64, 9.0_f64);
    let (k, (x, h)) = (heron(a, b, c), corner(a, b, c));
    let (pa, pb, pc) = ((0.0, 0.0), (c, 0.0), (x, h));
    let (ha, hb) = (height_to(pa, pb, pc), height_to(pb, pc, pa));
    let (ai, bi, ci) = (7i64, 8i64, 9i64);
    let f16 = (ai + bi + ci) * (-ai + bi + ci) * (ai - bi + ci) * (ai + bi - ci);
    let g16 = 2 * (ai * ai * bi * bi + bi * bi * ci * ci + ci * ci * ai * ai) - (ai.pow(4) + bi.pow(4) + ci.pow(4));
    let (trap, top) = ((c + c / 2.0) / 2.0 * (h / 2.0), (c / 2.0) * (h / 2.0) / 2.0);
    let (x2, h2) = corner(8.0, 5.0, 4.0);
    let st: Vec<String> = [10, 100, 1000].iter().map(|&n| format!("{:.6}", strips(c, x, h, n))).collect();
    println!("sides 7, 8, 9; s = {:.0}; s(s-a)(s-b)(s-c) = {:.0}", (a + b + c) / 2.0, product(a, b, c));
    println!("road one, Heron: area = {:.6}", k);
    println!("road two, grid: foot at x = {:.6}, height h = {:.6}, 9 x h / 2 = {:.6}", x, h, c * h / 2.0);
    println!("10, 100, 1000 strips: {}", st.join(", "));
    println!("heights to a, b, c: {:.6}, {:.6}, {:.6}", ha, hb, h);
    println!("base x height, three ways: {:.6}, {:.6}, {:.6}", a * ha, b * hb, c * h);
    println!("16 x area^2: factored {}, expanded {}", f16, g16);
    println!("two beds, parallelogram: {:.6}", c * h);
    println!("cut halfway up: trapezoid {:.6} + top {:.6} = {:.6}", trap, top, trap + top);
    println!("second case 4, 5, 8: Heron {:.6}; foot x = {:.6}, h = {:.6}, 4 x h / 2 = {:.6}", heron(4.0, 5.0, 8.0), x2, h2, 4.0 * h2 / 2.0);
    println!("mistake, slope as height: 9 x 8 / 2 = {:.6}", c * b / 2.0);
    println!("mistake, perimeter for s: {:.6}", root(24.0 * 17.0 * 16.0 * 15.0));
    println!("mistake, sum of bases for trapezoid: {:.6}", (c + c / 2.0) * (h / 2.0));
    println!("doubled sides 14, 16, 18: {:.6}, {:.6} x the bed", heron(14.0, 16.0, 18.0), heron(14.0, 16.0, 18.0) / k);
    println!("sides 2, 3, 6: s(s-a)(s-b)(s-c) = {:.4}, no triangle", product(2.0, 3.0, 6.0));
    println!("figure 1, 1 m = 30: A (45, 215), B (315, 215), C ({:.2}, {:.2})", 45.0 + 30.0 * x, 215.0 - 30.0 * h);
    println!("figure 2, 1 m = 20: A (40, 200), B (220, 200), D ({:.2}, {:.2}), C ({:.2}, {:.2})", 220.0 + 20.0 * x, 200.0 - 20.0 * h, 40.0 + 20.0 * x, 200.0 - 20.0 * h);
    assert!((strips(c, x, h, 1000) - k).abs() < 1e-4);          // strips against Heron
    assert!((16.0 * k * k - g16 as f64).abs() < 1e-6);          // Heron against the expanded form
    assert!([a * ha, b * hb, c * h].iter().all(|v| (v - 2.0 * k).abs() < 1e-9)); // any base
    assert!((4.0 * h2 / 2.0 - heron(4.0, 5.0, 8.0)).abs() < 1e-9); // obtuse case, two roads
    println!("ALL CHECKS PASS");
}
