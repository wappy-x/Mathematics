// Pigeonhole -- the same check as the Python, in Rust.  No crates.  Thirteen guests
// at a dinner and the twelve months, then a sentence of 27 words and the 26 letters.
// Route 1 walks the list and catches the repeat; route 2 counts what each hole holds.
fn first_repeat(labels: &[String]) -> Option<(usize, usize, String)> {   // route 1: the first hole used twice
    for j in 0..labels.len() {
        for i in 0..j { if labels[i] == labels[j] { return Some((i + 1, j + 1, labels[j].clone())); } }
    }
    None
}
fn loads(labels: &[String], holes: &[String]) -> Vec<usize> {            // route 2: how many landed in each hole
    holes.iter().map(|h| labels.iter().filter(|l| l == &h).count()).collect()
}
fn show(what: &str, labels: &[String], holes: &[String], one: &str, many: &str, holes_name: &str) -> (Option<(usize, usize, String)>, Vec<usize>) {
    let (rep, n) = (first_repeat(labels), loads(labels, holes));
    assert_eq!(rep.is_none(), *n.iter().max().unwrap() <= 1);            // the two routes agree, every time
    println!("{}: {} {} into {} {} -- {} more than there are {}", what, labels.len(), many, holes.len(), holes_name, labels.len() - holes.len(), holes_name);
    match &rep { Some(r) => println!("  the forced repeat: {} {} and {} {}, both {}", one, r.0, one, r.1, r.2),
                 None => println!("  no repeat forced, the fullest hole holds {}", n.iter().max().unwrap()) }
    println!("  {} holding two or more: {}, holding one: {}, holding none: {}", holes_name,
             n.iter().filter(|&&x| x > 1).count(), n.iter().filter(|&&x| x == 1).count(), n.iter().filter(|&&x| x == 0).count());
    println!("  with no sharing: {} {} hold {} {} at most, and {} {} do not fit", holes.len(), holes_name, holes.len(), many, labels.len(), many);
    (rep, n)
}
fn main() {
    let months: Vec<String> = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"].iter().map(|s| s.to_string()).collect();
    let letters: Vec<String> = "abcdefghijklmnopqrstuvwxyz".chars().map(|c| c.to_string()).collect();
    let born: Vec<String> = ["March", "November", "July", "January", "September", "December", "April", "June", "February", "August", "May", "October", "July"].iter().map(|s| s.to_string()).collect();
    let sentence = "Every guest brought a dish, and dinner ran late, so nobody counted the months until Priya asked, quietly, whether any two of us shared a birthday month";
    let initials: Vec<String> = sentence.split_whitespace().map(|w| w[..1].to_lowercase()).collect();
    let later: Vec<String> = born.iter().map(|m| months[(months.iter().position(|x| x == m).unwrap() + 1) % 12].clone()).collect();
    let first12: Vec<String> = born[..12].to_vec();
    let (rep_m, n_m) = show("the dinner", &born, &months, "guest", "guests", "months");
    let (rep_w, n_w) = show("the sentence", &initials, &letters, "word", "words", "letters");
    assert!(rep_m == Some((3, 13, "July".to_string())) && n_m.iter().filter(|&&x| x == 1).count() == 11 && n_m.iter().filter(|&&x| x == 0).count() == 0);
    assert!(rep_w == Some((4, 6, "a".to_string())) && *n_w.iter().max().unwrap() == 5 && initials.len() == 27);
    println!("breaks: the first 12 guests into 12 months -- no repeat forced, fullest month holds {}", loads(&first12, &months).iter().max().unwrap());
    println!("breaks: every guest born a month later -- the repeat moves to {}, still {} guests", first_repeat(&later).unwrap().2, loads(&later, &months).iter().max().unwrap());
    assert!(first_repeat(&first12).is_none() && *loads(&first12, &months).iter().max().unwrap() == 1 && first_repeat(&later).unwrap().2 == "August");
    println!("ALL CHECKS PASS");
}
