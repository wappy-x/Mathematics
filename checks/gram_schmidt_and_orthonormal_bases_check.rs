// Gram-Schmidt -- the same check as the Python, in Rust.  No crates.  Two survey
// lines on a building site, (3, 1) and (2, 2), are straightened into
// perpendicular unit directions, and a stake at (4, 2) is then read off by dot
// products.  A second case adds a mast, (1, 1, 1), to make a third direction.
fn dot(u: &[f64], v: &[f64]) -> f64 { u.iter().zip(v).map(|(a, b)| a * b).sum() }
fn length(u: &[f64]) -> f64 { dot(u, u).powf(0.5) }
fn scale(k: f64, u: &[f64]) -> Vec<f64> { u.iter().map(|a| k * a).collect() }
fn minus(u: &[f64], v: &[f64]) -> Vec<f64> { u.iter().zip(v).map(|(a, b)| a - b).collect() }
fn plus(u: &[f64], v: &[f64]) -> Vec<f64> { u.iter().zip(v).map(|(a, b)| a + b).collect() }
fn gram_schmidt(vs: &[Vec<f64>]) -> Vec<Vec<f64>> {   // peel shadows, scale to 1
    let mut qs: Vec<Vec<f64>> = Vec::new();
    for v0 in vs {
        let mut v = v0.clone();
        for q in &qs { v = minus(&v, &scale(dot(&v, q), q)); }
        let l = length(&v);
        qs.push(scale(1.0 / l, &v));
    }
    qs
}
fn num(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-7 { 0.0 } else { x }) }
fn vec_s(u: &[f64]) -> String {
    format!("({})", u.iter().map(|x| num(*x)).collect::<Vec<String>>().join(", "))
}
fn row(name: &str, cells: &[String]) { println!("{:<44}{}", name, cells.join("  ")); }
fn main() {
    let (a1, a2, b) = (vec![3.0, 1.0], vec![2.0, 2.0], vec![4.0, 2.0]);
    let qs = gram_schmidt(&[a1.clone(), a2.clone()]);
    let (q1, q2) = (qs[0].clone(), qs[1].clone());
    let shadow = scale(dot(&a2, &q1), &q1);
    let left = minus(&a2, &shadow);
    let (c1, c2) = (dot(&b, &q1), dot(&b, &q2));       // one road: coordinates are dots
    let rebuilt = plus(&scale(c1, &q1), &scale(c2, &q2));
    let det = q1[0] * q2[1] - q2[0] * q1[1];           // second road: solve for the two
    let e1 = (b[0] * q2[1] - q2[0] * b[1]) / det;      // coordinates by elimination, with
    let e2 = (q1[0] * b[1] - b[0] * q1[1]) / det;      // no dot product anywhere in it
    let skew = a1[0] * a2[1] - a2[0] * a1[1];          // the same solve on the raw lines
    let s1 = (b[0] * a2[1] - a2[0] * b[1]) / skew;
    let s2 = (a1[0] * b[1] - b[0] * a1[1]) / skew;
    row("survey lines (3, 1), (2, 2), lengths", &[num(length(&a1)), num(length(&a2))]);
    row("q1 = first line / its length", &[vec_s(&q1)]);
    row("a2 . q1, and the shadow it casts", &[num(dot(&a2, &q1)), vec_s(&shadow)]);
    row("leftover a2 - shadow, and its length", &[vec_s(&left), num(length(&left))]);
    row("q2 = leftover / length, (-1, 3)/3.162278", &[vec_s(&q2)]);
    row("q1 . q1, q2 . q2, q1 . q2",
        &[num(dot(&q1, &q1)), num(dot(&q2, &q2)), num(dot(&q1, &q2))]);
    row("stake b = (4, 2), coordinates by dots", &[num(c1), num(c2)]);
    row("the same two by elimination", &[num(e1), num(e2)]);
    row("b rebuilt from its coordinates", &[vec_s(&rebuilt)]);
    row("b . b, and c1^2 + c2^2", &[num(dot(&b, &b)), num(c1 * c1 + c2 * c2)]);
    row("b on the raw skewed lines, solved", &[num(s1), num(s2)]);
    row("Q^T Q rows, and det Q", &[vec_s(&[dot(&q1, &q1), dot(&q1, &q2)]),
        vec_s(&[dot(&q2, &q1), dot(&q2, &q2)]), num(det)]);
    row("quarter turn (0, 1) and (-1, 0), det", &[num(0.0 * 0.0 - (-1.0) * 1.0)]);
    row("flip (1, 0) and (0, -1), det", &[num(1.0 * -1.0 - 0.0 * 0.0)]);
    row("mistake: no divide by a1 . a1", &[vec_s(&minus(&a2, &scale(dot(&a2, &a1), &a1)))]);
    row("mistake: leftover never scaled",
        &[vec_s(&plus(&scale(dot(&b, &a1), &a1), &scale(dot(&b, &left), &left)))]);
    let dep = vec![6.0, 2.0];
    row("mistake: a2 = (6, 2), leftover", &[vec_s(&minus(&dep, &scale(dot(&dep, &q1), &q1)))]);
    let m = gram_schmidt(&[vec![3.0, 1.0, 0.0], vec![2.0, 2.0, 0.0], vec![1.0, 1.0, 1.0]]);
    row("mast (1, 1, 1) added, q3", &[vec_s(&m[2])]);
    let mut off: f64 = 0.0;
    for i in 0..3 { for j in 0..3 { if i != j && dot(&m[i], &m[j]).abs() > off { off = dot(&m[i], &m[j]).abs(); } } }
    row("mast Q^T Q, largest off-diagonal", &[num(off)]);
    assert!((dot(&q1, &q1) - 1.0).abs() < 1e-12 && (dot(&q2, &q2) - 1.0).abs() < 1e-12 && dot(&q1, &q2).abs() < 1e-12);
    assert!((c1 - 14.0 / 10.0f64.powf(0.5)).abs() < 1e-12 && (c2 - 2.0 / 10.0f64.powf(0.5)).abs() < 1e-12);
    assert!((e1 - c1).abs() < 1e-12 && (e2 - c2).abs() < 1e-12 && (rebuilt[0] - 4.0).abs() < 1e-12 && (rebuilt[1] - 2.0).abs() < 1e-12);
    assert!((dot(&b, &b) - 20.0).abs() < 1e-12 && (c1 * c1 + c2 * c2 - 20.0).abs() < 1e-12 && (m[2][2] - 1.0).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
