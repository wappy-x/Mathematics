-- Which clocks have a primitive root: a primitive root on an odd prime clock that passes the p-squared test is a primitive root on every power of that prime, and an odd one on twice each power; one of g and g + p always passes; and a clock above 0 has a primitive root exactly when it is 1, 2, 4, an odd prime power, or twice one.
import Mathlib.RingTheory.ZMod.UnitsCyclic
import Mathlib.GroupTheory.OrderOfElement
import Mathlib.Data.Nat.Totient

lemma prpp_not_dvd (p g : ℕ) (hp : p.Prime) (hg : orderOf (g : ZMod p) = p - 1) :
    ¬ p ∣ g := by
  intro h
  have : Fact p.Prime := ⟨hp⟩
  rw [(ZMod.natCast_eq_zero_iff g p).mpr h, orderOf_zero] at hg
  have := hp.two_le
  omega

lemma prpp_lift (p g : ℕ) (hp : p.Prime) (hp2 : p ≠ 2) (hg : orderOf (g : ZMod p) = p - 1)
    (htest : (g : ZMod (p ^ 2)) ^ (p - 1) ≠ 1) (m : ℕ) :
    orderOf (g : ZMod (p ^ (m + 1))) = Nat.totient (p ^ (m + 1)) := by
  have hpg : ¬ p ∣ g := prpp_not_dvd p g hp hg
  have hg0 : g ≠ 0 := by rintro rfl; exact hpg (dvd_zero p)
  have h1 : (g : ZMod p) ^ (p - 1) = 1 := hg ▸ pow_orderOf_eq_one _
  have hmod : g ^ (p - 1) ≡ 1 [MOD p] := by
    rw [← ZMod.natCast_eq_natCast_iff]; push_cast; exact h1
  have hge : 1 ≤ g ^ (p - 1) := Nat.one_le_pow _ _ (Nat.pos_of_ne_zero hg0)
  obtain ⟨a, ha⟩ : p ∣ g ^ (p - 1) - 1 := (Nat.modEq_iff_dvd' hge).mp hmod.symm
  have hga : g ^ (p - 1) = 1 + p * a := by omega
  have hpa : ¬ p ∣ a := by
    rintro ⟨b, rfl⟩
    apply htest
    have hz : ((p ^ 2 : ℕ) : ZMod (p ^ 2)) = 0 := ZMod.natCast_self _
    have : ((g ^ (p - 1) : ℕ) : ZMod (p ^ 2)) = 1 := by
      rw [hga]; push_cast at hz ⊢
      linear_combination (b : ZMod (p ^ 2)) * hz
    exact_mod_cast this
  have hord : orderOf ((g : ZMod (p ^ (m + 1))) ^ (p - 1)) = p ^ m := by
    have := ZMod.orderOf_one_add_mul_prime hp hp2 (a : ℤ) (by exact_mod_cast hpa) m
    rw [← this]; congr 1
    rw [← Nat.cast_pow, hga]; push_cast; ring
  have hdvd : p - 1 ∣ orderOf (g : ZMod (p ^ (m + 1))) := by
    have h := orderOf_map_dvd
      (ZMod.castHom (dvd_pow_self p (Nat.succ_ne_zero m)) (ZMod p)).toMonoidHom
      (g : ZMod (p ^ (m + 1)))
    simpa [hg] using h
  have hp1 : p - 1 ≠ 0 := by have := hp.two_le; omega
  rw [orderOf_pow_of_dvd hp1 hdvd] at hord
  rw [Nat.totient_prime_pow_succ hp m, ← hord, Nat.div_mul_cancel hdvd]

lemma prpp_two_mul (q g : ℕ) (hq : Odd q) (hgodd : Odd g) :
    orderOf (g : ZMod (2 * q)) = orderOf (g : ZMod q) := by
  let e := ZMod.chineseRemainder (Nat.coprime_two_left.mpr hq)
  rw [← MulEquiv.orderOf_eq e.toMulEquiv, Prod.orderOf]
  simp only [RingEquiv.toMulEquiv_eq_coe, RingEquiv.coe_toMulEquiv, map_natCast, e]
  simp [ZMod.natCast_eq_one_iff_odd.mpr hgodd]

lemma prpp_totient_two_mul (q : ℕ) (hq : Odd q) :
    Nat.totient (2 * q) = Nat.totient q := by
  rw [Nat.totient_mul (Nat.coprime_two_left.mpr hq), Nat.totient_two, one_mul]

lemma prpp_exists_iff_cyclic (n : ℕ) (hn : 0 < n) :
    (∃ g : ZMod n, orderOf g = Nat.totient n) ↔ IsCyclic (ZMod n)ˣ := by
  have : NeZero n := ⟨hn.ne'⟩
  rw [isCyclic_iff_exists_orderOf_eq_natCard, Nat.card_eq_fintype_card,
    ZMod.card_units_eq_totient]
  constructor
  · rintro ⟨g, hg⟩
    have hpos : Nat.totient n ≠ 0 := (Nat.totient_pos.mpr hn).ne'
    have hu : IsUnit g := IsUnit.of_pow_eq_one (hg ▸ pow_orderOf_eq_one g) hpos
    exact ⟨hu.unit, by rw [← orderOf_units, IsUnit.unit_spec, hg]⟩
  · rintro ⟨u, hu⟩
    exact ⟨u, by rw [orderOf_units, hu]⟩

#print axioms prpp_not_dvd
#print axioms prpp_lift
#print axioms prpp_two_mul
#print axioms prpp_totient_two_mul
#print axioms prpp_exists_iff_cyclic

/-- The card's main claim. Let p be an odd prime and g a primitive root on the p-clock (its
order there is p - 1). If g to the p - 1 does not leave 1 on the p-squared clock (the test),
then g is a primitive root on every power of p: its order on the p^k clock equals phi(p^k).
If g is also odd, it is a primitive root on twice each power too: its order on the 2p^k clock
equals phi(2p^k). -/
theorem primitive_root_lifts_to_every_prime_power_and_twice_it (p g : ℕ) (hp : p.Prime)
    (hp2 : p ≠ 2) (hg : orderOf (g : ZMod p) = p - 1)
    (htest : (g : ZMod (p ^ 2)) ^ (p - 1) ≠ 1) :
    ∀ k : ℕ, orderOf (g : ZMod (p ^ k)) = Nat.totient (p ^ k) ∧
      (Odd g → orderOf (g : ZMod (2 * p ^ k)) = Nat.totient (2 * p ^ k)) := by
  intro k
  rcases k with _ | m
  · refine ⟨?_, fun hodd => ?_⟩
    · show orderOf (g : ZMod 1) = Nat.totient 1
      rw [Nat.totient_one]
      exact orderOf_eq_one_iff.mpr (Subsingleton.elim _ _)
    · show orderOf (g : ZMod 2) = Nat.totient 2
      rw [ZMod.natCast_eq_one_iff_odd.mpr hodd, orderOf_one, Nat.totient_two]
  have hodd_p : Odd (p ^ (m + 1)) := (hp.odd_of_ne_two hp2).pow
  refine ⟨prpp_lift p g hp hp2 hg htest m, fun hodd => ?_⟩
  rw [prpp_two_mul _ g hodd_p hodd, prpp_totient_two_mul _ hodd_p]
  exact prpp_lift p g hp hp2 hg htest m

/-- Step 1. If g is a primitive root on the odd prime p-clock, then g or g + p is a primitive
root on the p-squared clock: the two cannot both fail the test. -/
theorem primitive_root_or_add_prime_is_primitive_mod_prime_sq (p g : ℕ) (hp : p.Prime)
    (hp2 : p ≠ 2) (hg : orderOf (g : ZMod p) = p - 1) :
    orderOf (g : ZMod (p ^ 2)) = Nat.totient (p ^ 2) ∨
      orderOf ((g + p : ℕ) : ZMod (p ^ 2)) = Nat.totient (p ^ 2) := by
  by_cases htest : (g : ZMod (p ^ 2)) ^ (p - 1) = 1
  · right
    have hg' : orderOf ((g + p : ℕ) : ZMod p) = p - 1 := by
      simpa using hg
    refine prpp_lift p (g + p) hp hp2 hg' ?_ 1
    have hpg : ¬ p ∣ g := prpp_not_dvd p g hp hg
    obtain ⟨n, hn⟩ : ∃ n, p - 1 = n + 1 := ⟨p - 2, by have := hp.two_le; omega⟩
    have hz : ((p : ZMod (p ^ 2))) ^ 2 = 0 := by
      rw [← Nat.cast_pow, ZMod.natCast_self]
    have key : ∀ j : ℕ, ((g : ZMod (p ^ 2)) + p) ^ (j + 1) =
        (g : ZMod (p ^ 2)) ^ (j + 1) + (j + 1) * (g : ZMod (p ^ 2)) ^ j * p := by
      intro j
      induction j with
      | zero => simp
      | succ j ih =>
        rw [pow_succ ((g : ZMod (p ^ 2)) + p) (j + 1), ih]; push_cast
        linear_combination ((j + 1) * (g : ZMod (p ^ 2)) ^ j) * hz
    push_cast
    rw [hn, key n, ← hn, htest]
    intro h
    have h0 : (((n + 1) * g ^ n * p : ℕ) : ZMod (p ^ 2)) = 0 := by
      push_cast; linear_combination h
    rw [ZMod.natCast_eq_zero_iff, pow_two] at h0
    have h1 : p ∣ (n + 1) * g ^ n := Nat.dvd_of_mul_dvd_mul_right hp.pos h0
    rcases (Nat.Prime.dvd_mul hp).mp h1 with h2 | h2
    · have := Nat.le_of_dvd (by omega) h2
      omega
    · exact hpg (hp.dvd_of_dvd_pow h2)
  · left
    exact prpp_lift p g hp hp2 hg htest 1

/-- Gauss's list. A clock of size n (n at least 1) has a primitive root, a remainder whose
order equals phi(n), exactly when n is 1, 2, 4, a power p^k of an odd prime p, or twice one.
Every other clock, such as 8, 16, 32, ... or one that splits into two parts above 2 like 15,
has none. -/
theorem primitive_root_exists_iff_gauss_list (n : ℕ) (hn : 0 < n) :
    (∃ g : ZMod n, orderOf g = Nat.totient n) ↔
      n = 1 ∨ n = 2 ∨ n = 4 ∨
        ∃ p k : ℕ, p.Prime ∧ Odd p ∧ 1 ≤ k ∧ (n = p ^ k ∨ n = 2 * p ^ k) := by
  rw [prpp_exists_iff_cyclic n hn, ZMod.isCyclic_units_iff]
  have : n ≠ 0 := hn.ne'
  simp [this]

-- The 7-clock: the powers of 3 run 3, 2, 6, 4, 5, 1, so 3 has order 6 there.
example : (List.range 6).map (fun e => 3 ^ (e + 1) % 7) = [3, 2, 6, 4, 5, 1] := by decide
-- The test: 3^6 = 729 = 14 × 49 + 43 leaves 43, not 1, on the 49-clock, and 43 = 1 + 6 × 7.
example : 3 ^ 6 = 729 ∧ 729 = 14 * 49 + 43 ∧ 3 ^ 6 % 49 = 43 ∧ 43 = 1 + 6 * 7 := by decide
-- 3 has order 42 on the 49-clock: 42 multiplications reach 1, and no fewer.
example : 3 ^ 42 % 49 = 1 ∧ ∀ e ∈ Finset.Ioo 0 42, 3 ^ e % 49 ≠ 1 := by decide
-- The next power: 3^42 leaves 295 = 1 + 6 × 49 on the 343-clock.
example : 3 ^ 42 % 343 = 295 ∧ 295 = 1 + 6 * 49 := by decide
-- phi(49) = 42, phi(98) = 42, phi(343) = 294, phi(2401) = 2058.
example : Nat.totient 49 = 42 ∧ Nat.totient 98 = 42 := by decide
example : Nat.totient 343 = 294 ∧ Nat.totient 2401 = 2058 := by
  rw [show (343 : ℕ) = 7 ^ 3 by norm_num, show (2401 : ℕ) = 7 ^ 4 by norm_num,
    Nat.totient_prime_pow (by decide) (by norm_num),
    Nat.totient_prime_pow (by decide) (by norm_num)]
  norm_num
-- The 98-clock: 3 has order 42 there too.
example : 3 ^ 42 % 98 = 1 ∧ ∀ e ∈ Finset.Ioo 0 42, 3 ^ e % 98 ≠ 1 := by decide
-- Step 1: below 49, only 31 leaves 3 on the 7-clock and fails the test; 31 + 7 = 38 passes,
-- with order 42.
example : (List.range 49).filter (fun x => x % 7 = 3 ∧ x ^ 6 % 49 = 1) = [31] := by decide
example : 38 ^ 42 % 49 = 1 ∧ ∀ e ∈ Finset.Ioo 0 42, 38 ^ e % 49 ≠ 1 := by decide
-- 31 lifted without the test has order 6 on the 49-clock.
example : 31 ^ 6 % 49 = 1 ∧ ∀ e ∈ Finset.Ioo 0 6, 31 ^ e % 49 ≠ 1 := by decide
-- The even lift 52 never returns to 1 on the 98-clock: it shares 2 with 98.
example : Nat.gcd 52 98 = 2 ∧ ∀ e ∈ Finset.Ioo 0 98, 52 ^ e % 98 ≠ 1 := by decide
-- The 8-clock: the odd squares 1, 9, 25, 49 all leave 1, short of phi(8) = 4.
example : [1, 3, 5, 7].map (fun x => x * x % 8) = [1, 1, 1, 1] ∧ Nat.totient 8 = 4 := by decide
-- The 15-clock: every number sharing no factor with 15 has fourth power 1, short of phi(15) = 8.
example : (∀ x, x < 15 → Nat.gcd x 15 = 1 → x ^ 4 % 15 = 1) ∧ Nat.totient 15 = 8 := by decide

#print axioms primitive_root_lifts_to_every_prime_power_and_twice_it
#print axioms primitive_root_or_add_prime_is_primitive_mod_prime_sq
#print axioms primitive_root_exists_iff_gauss_list
