// The check behind the card, in Rust: twelve apples at 75 cents, a $10 bill,
// four friends, everything in whole cents.  No crates, nothing imported.
fn main() {
    const APPLES: i64 = 12;
    const PRICE: i64 = 75;
    const PAID: i64 = 1000;
    const QUARTER: i64 = 25;
    // First way: put one apple's price on the pile at a time, keeping the bill.
    let mut bill = 0i64;
    let mut running: Vec<i64> = Vec::new();
    for _ in 0..APPLES {
        bill = bill + PRICE;
        running.push(bill);
    }
    // Second way, the cross-check: the same total by piles -- twelve sevens in
    // the tens column and twelve fives in the ones, exactly as on the card.
    let (mut tens, mut ones) = (0i64, 0i64);
    for _ in 0..APPLES {
        tens = tens + 7;
        ones = ones + 5;
    }
    let piles = tens * 10 + ones;
    let change = PAID - bill;
    let share = PRICE + PRICE + PRICE;
    println!("one apple, cents           {:>5}", PRICE);
    println!("twelve apples, added up    {:>5}", bill);
    println!("twelve apples, by piles    {:>5}", piles);
    println!("   twelve sevens {} tens, twelve fives {} ones", tens, ones);
    println!("paid with, cents           {:>5}", PAID);
    println!("change, cents              {:>5}", change);
    println!("check: change + bill       {:>5}", change + bill);
    println!("one friend's three apples  {:>5}", share);
    println!("one friend's quarter       {:>5}", QUARTER);
    let cents: Vec<String> = running.iter().map(|v| v.to_string()).collect();
    println!("running bill, cents:  {}", cents.join(" "));
    assert!(bill == piles, "the two roads to the bill must agree");
    assert!(change + bill == PAID, "the change plus the bill must give back the note");
    assert!(share + share + share + share == bill, "four shares must be the whole basket");
    println!("ALL CHECKS PASS");
}
