// Subsets and the power set -- the same check as subsets_and_power_set_check.py,
// in Rust.  No crates.  Three toppings are on offer, so every pizza is a subset
// of that list.  Build the eight pizzas one topping at a time, then count again.
const TOPPINGS: &[&str] = &["mushroom", "olive", "chilli"];
fn build(toppings: &[&str]) -> Vec<Vec<String>> {    // every subset, one topping at a time
    let mut out: Vec<Vec<String>> = vec![vec![]];    // start with the plain pizza
    for t in toppings {                              // each new topping doubles the menu
        let grown: Vec<Vec<String>> = out.iter().map(|p| {
            let mut q = p.clone(); q.push(t.to_string()); q }).collect();
        out.extend(grown);
    }
    out
}
fn name(p: &[String]) -> String { if p.is_empty() { "plain".into() } else { p.join(", ") } }
fn row(label: &str, value: usize) { println!("{:<34}{:>5}", label, value); }
fn main() {
    let mut four: Vec<&str> = TOPPINGS.to_vec(); four.push("anchovy");
    let pizzas = build(TOPPINGS);
    let sizes: Vec<usize> =                          // k toppings up, never past the board
        (0..5).map(|k| build(&four[..k.min(four.len())]).len()).collect();
    let free: Vec<Vec<String>> =
        pizzas.iter().filter(|p| !p.iter().any(|x| x == "chilli")).cloned().collect();
    let nonempty = pizzas.iter().filter(|p| !p.is_empty()).count();
    row("toppings on offer", TOPPINGS.len());
    row("pizzas possible, 2 x 2 x 2", pizzas.len());
    let names: Vec<String> = pizzas.iter().map(|p| name(p)).collect();
    println!("the eight pizzas: {}", names.join(" | "));
    let mut menu = format!("{:<29}", "menu size after each topping");
    for v in &sizes { menu.push_str(&format!("{:>5}", v)); }
    println!("{}", menu);
    row("chilli-free pizzas", free.len());
    row("pizzas with at least one topping", nonempty);
    println!("the three mistakes come out at {}, {} and {}", nonempty, TOPPINGS.len(), 2 + 2 + 2);
    let mut a: Vec<String> = free.iter().map(|p| name(p)).collect();
    a.sort();                                        // the four subsets, written out by hand
    assert!(a == ["mushroom", "mushroom, olive", "olive", "plain"]);
    assert!(pizzas.len() == 2 * 2 * 2 && free.len() == 2 * 2 && nonempty == 7);
    assert!(sizes == vec![1, 2, 4, 8, 16]);
    println!("ALL CHECKS PASS");
}
