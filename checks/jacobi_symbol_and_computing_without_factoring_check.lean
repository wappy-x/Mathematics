-- The Jacobi symbol: the Jacobi symbol on odd bottoms obeys the flip, the rule for 2 and reduction of the top, and Euler's criterion against it is a primality test that every odd composite fails for at least half of its coprime bases.
import Mathlib.NumberTheory.LegendreSymbol.JacobiSymbol
import Mathlib.Tactic.NormNum.LegendreSymbol
import Mathlib.Tactic.NormNum.PowMod
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Data.ZMod.Basic

open scoped NumberTheorySymbols

theorem chi8_eq_neg_one_pow (n : ℕ) (hn : Odd n) :
    (ZMod.χ₈ (n : ZMod 8) : ℤ) = (-1) ^ ((n ^ 2 - 1) / 8) := by
  obtain ⟨q, r, hr16, rfl⟩ : ∃ q r, r < 16 ∧ n = 16 * q + r :=
    ⟨n / 16, n % 16, Nat.mod_lt _ (by norm_num), (Nat.div_add_mod n 16).symm⟩
  have hodd : (16 * q + r) % 2 = 1 := Nat.odd_iff.mp hn
  have hr1 : 1 ≤ r ^ 2 := Nat.one_le_pow _ _ (by omega)
  have hsq : (16 * q + r) ^ 2 - 1 = 8 * (2 * (16 * q * q + 2 * q * r)) + (r ^ 2 - 1) := by
    have : (16 * q + r) ^ 2 = 8 * (2 * (16 * q * q + 2 * q * r)) + r ^ 2 := by ring
    rw [this, Nat.add_sub_assoc hr1]
  rw [hsq, Nat.mul_add_div (by norm_num), pow_add, pow_mul, neg_one_sq, one_pow, one_mul,
    ZMod.χ₈_nat_eq_if_mod_eight]
  have h2 : (16 * q + r) % 2 = r % 2 := by omega
  have h8 : (16 * q + r) % 8 = r % 8 := by omega
  rw [h2, h8]
  rw [h2] at hodd
  interval_cases r <;> simp_all

theorem one_add_pow_of_sq_zero {R : Type*} [CommRing R] (x : R) (hx : x * x = 0) (k : ℕ) :
    (1 + x) ^ k = 1 + (k : R) * x := by
  induction k with
  | zero => simp
  | succ k ih =>
    rw [pow_succ, ih]
    push_cast
    linear_combination (k : R) * hx

theorem exists_euler_witness (n : ℕ) (hn : Odd n) (h1 : 1 < n) (hc : ¬ n.Prime) :
    ∃ a : ℤ, Int.gcd a n = 1 ∧
      (a : ZMod n) ^ ((n - 1) / 2) ≠ ((J(a | n) : ℤ) : ZMod n) := by
  set p := n.minFac with hpdef
  have hp : p.Prime := Nat.minFac_prime (by omega)
  have hpn : p ∣ n := Nat.minFac_dvd n
  obtain ⟨j, hj⟩ := hn
  have hp2 : p ≠ 2 := by
    intro h
    rw [h] at hpn
    omega
  have hpe : ¬ p ∣ (n - 1) / 2 := by
    intro h
    have h' : p ∣ n - 1 := h.trans ⟨2, by omega⟩
    have h'' : p ∣ n - (n - 1) := Nat.dvd_sub hpn h'
    rw [show n - (n - 1) = 1 by omega] at h''
    exact hp.one_lt.ne' (Nat.dvd_one.mp h'')
  by_cases hsq : p ^ 2 ∣ n
  · obtain ⟨t, ht⟩ := hsq
    have ht0 : t ≠ 0 := by rintro rfl; simp at ht; omega
    refine ⟨1 + ((p * t : ℕ) : ℤ), ?_, ?_⟩
    · rw [← Int.isCoprime_iff_gcd_eq_one]
      refine ⟨1 - ((p * t : ℕ) : ℤ), t, ?_⟩
      rw [ht]; push_cast; ring
    · have hJ : J(1 + ((p * t : ℕ) : ℤ) | n) = 1 := by
        rw [ht, jacobiSym.mul_right' _ (pow_ne_zero _ hp.ne_zero) ht0, jacobiSym.pow_right]
        rw [jacobiSym.mod_left' (b := p) (a₂ := 1) (by push_cast; simp),
          jacobiSym.mod_left' (b := t) (a₂ := 1) (by push_cast; simp)]
        simp [jacobiSym.one_left]
      rw [hJ]
      have hx : ((p * t : ℕ) : ZMod n) * ((p * t : ℕ) : ZMod n) = 0 := by
        rw [← Nat.cast_mul, ZMod.natCast_eq_zero_iff]
        exact ⟨t, by rw [ht]; ring⟩
      intro h
      push_cast at h hx
      rw [one_add_pow_of_sq_zero _ hx] at h
      have h0 : ((((n - 1) / 2) * (p * t) : ℕ) : ZMod n) = 0 := by
        push_cast
        linear_combination h
      rw [ZMod.natCast_eq_zero_iff] at h0
      apply hpe
      apply Nat.dvd_of_mul_dvd_mul_right (Nat.pos_of_ne_zero (Nat.mul_ne_zero hp.ne_zero ht0))
      calc p * (p * t) = n := by rw [ht]; ring
        _ ∣ _ := h0
  · obtain ⟨m, hm⟩ := hpn
    have hcop : Nat.Coprime p m := by
      rw [Nat.Prime.coprime_iff_not_dvd hp]
      rintro ⟨u, hu⟩
      exact hsq ⟨u, by rw [hm, hu]; ring⟩
    have hm0 : m ≠ 0 := by rintro rfl; simp at hm; omega
    have hm1 : m ≠ 1 := by
      rintro rfl
      rw [mul_one] at hm
      exact hc (hm ▸ hp)
    have hm2 : ¬ 2 ∣ m := by
      rintro ⟨u, hu⟩
      have : 2 ∣ n := ⟨p * u, by rw [hm, hu]; ring⟩
      omega
    have := Fact.mk hp
    obtain ⟨x, hx⟩ := FiniteField.exists_nonsquare (F := ZMod p)
      (by rw [ZMod.ringChar_zmod_n]; exact hp2)
    obtain ⟨k, hk1, hk2⟩ := Nat.chineseRemainder hcop x.val 1
    have hJp : J((k : ℤ) | p) = -1 := by
      rw [ZMod.nonsquare_iff_jacobiSym_eq_neg_one]
      have : (((k : ℕ) : ℤ) : ZMod p) = x := by
        rw [Int.cast_natCast, (ZMod.natCast_eq_natCast_iff _ _ _).mpr hk1, ZMod.natCast_zmod_val]
      rw [this]
      exact hx
    have hJm : J((k : ℤ) | m) = 1 := by
      rw [jacobiSym.mod_left' (a₂ := 1) ?_, jacobiSym.one_left]
      have := congrArg (Nat.cast : ℕ → ℤ) hk2
      push_cast at this
      exact this
    have hJ : J((k : ℤ) | n) = -1 := by
      rw [hm, jacobiSym.mul_right' _ hp.ne_zero hm0, hJp, hJm]
      norm_num
    refine ⟨k, ?_, ?_⟩
    · by_contra hg
      have := (jacobiSym.eq_zero_iff (a := (k : ℤ)) (b := n)).mpr ⟨by omega, hg⟩
      rw [hJ] at this
      norm_num at this
    · rw [hJ]
      intro h
      have hdvd : m ∣ n := ⟨p, by rw [hm]; ring⟩
      have h2 := congrArg (ZMod.castHom hdvd (ZMod m)) h
      simp only [map_pow, map_natCast, map_neg, map_one, Int.cast_natCast, Int.cast_neg,
        Int.cast_one] at h2
      have hk1' : ((k : ℕ) : ZMod m) = 1 := by
        rw [(ZMod.natCast_eq_natCast_iff _ _ _).mpr hk2, Nat.cast_one]
      rw [hk1', one_pow] at h2
      have h22 : ((2 : ℕ) : ZMod m) = 0 := by
        push_cast
        linear_combination h2
      rw [ZMod.natCast_eq_zero_iff] at h22
      have := Nat.le_of_dvd (by norm_num) h22
      interval_cases m <;> simp_all

#print axioms chi8_eq_neg_one_pow
#print axioms one_add_pow_of_sq_zero
#print axioms exists_euler_witness

/-- For odd positive m and n with no common factor, the Jacobi symbol (Mathlib's `jacobiSym`,
the product of the Legendre symbols over the prime factors of the bottom) obeys three rules
that compute it without factoring: flipping top and bottom multiplies by
(-1)^((m-1)/2 * (n-1)/2); a 2 on top gives (2/n) = (-1)^((n^2-1)/8); and the top can be
replaced by its remainder mod n. -/
theorem jacobi_symbol_reciprocity_rules (m n : ℕ) (hm : Odd m) (hn : Odd n)
    (hmn : Nat.Coprime m n) :
    J((m : ℤ) | n) = (-1) ^ ((m - 1) / 2 * ((n - 1) / 2)) * J((n : ℤ) | m) ∧
    J(2 | n) = (-1) ^ ((n ^ 2 - 1) / 8) ∧
    ∀ a : ℤ, J(a | n) = J(a % (n : ℤ) | n) := by
  refine ⟨?_, ?_, fun a => jacobiSym.mod_left a n⟩
  · rw [jacobiSym.quadratic_reciprocity hm hn]
    obtain ⟨i, rfl⟩ := hm
    obtain ⟨j, rfl⟩ := hn
    congr 3 <;> omega
  · rw [jacobiSym.at_two hn, chi8_eq_neg_one_pow n hn]

/-- Solovay-Strassen: an odd number n above 1 is prime exactly when, for every base a with
no factor in common with n, Euler's power a^((n-1)/2) equals the Jacobi symbol (a/n) mod n. -/
theorem odd_prime_iff_euler_power_eq_jacobi (n : ℕ) (hn : Odd n) (h1 : 1 < n) :
    n.Prime ↔ ∀ a : ℤ, Int.gcd a n = 1 →
      (a : ZMod n) ^ ((n - 1) / 2) = ((J(a | n) : ℤ) : ZMod n) := by
  constructor
  · intro hp a _
    have := Fact.mk hp
    rw [← jacobiSym.legendreSym.to_jacobiSym, legendreSym.eq_pow]
    obtain ⟨j, rfl⟩ := hn
    congr 1
    omega
  · intro h
    by_contra hc
    obtain ⟨a, ha, hne⟩ := exists_euler_witness n hn h1 hc
    exact hne (h a ha)

/-- Every odd composite n has at most half of its φ(n) coprime bases below n as Euler liars:
bases a where a^((n-1)/2) agrees with (a/n) mod n. -/
theorem euler_liars_at_most_half (n : ℕ) (hn : Odd n) (h1 : 1 < n) (hc : ¬ n.Prime) :
    2 * ((Finset.range n).filter (fun a : ℕ => Nat.Coprime a n ∧
      ((a : ZMod n) ^ ((n - 1) / 2) = ((J((a : ℤ) | n) : ℤ) : ZMod n)))).card
      ≤ n.totient := by
  obtain ⟨a, ha, hne⟩ := exists_euler_witness n hn h1 hc
  have : NeZero n := ⟨by omega⟩
  set e := (n - 1) / 2 with he
  set b := (a : ZMod n).val with hbdef
  have hbn : b < n := ZMod.val_lt _
  have hbcast : ((b : ℕ) : ZMod n) = (a : ZMod n) := ZMod.natCast_zmod_val _
  have hbJ : J((b : ℤ) | n) = J(a | n) := by
    rw [jacobiSym.mod_left a, hbdef, ZMod.val_intCast]
  have hbcop : Nat.Coprime b n := by
    have hJ0 : J((b : ℤ) | n) ≠ 0 := by
      rw [hbJ]
      rcases jacobiSym.eq_one_or_neg_one ha with h | h <;> rw [h] <;> norm_num
    have := mt jacobiSym.eq_zero_iff_not_coprime.mpr hJ0
    rw [not_not, Int.gcd_natCast_natCast] at this
    exact this
  have hbu : IsUnit ((b : ℕ) : ZMod n) := (ZMod.isUnit_iff_coprime b n).mpr hbcop
  let Q : ℕ → Prop := fun x => (x : ZMod n) ^ e = ((J((x : ℤ) | n) : ℤ) : ZMod n)
  let U := (Finset.range n).filter (fun x : ℕ => Nat.Coprime x n)
  have hU : U.card = n.totient := by
    rw [Nat.totient_eq_card_coprime]
    congr 1
    apply Finset.filter_congr
    intro x _
    exact Nat.coprime_comm
  have hS : (Finset.range n).filter (fun x : ℕ => Nat.Coprime x n ∧ Q x) = U.filter Q := by
    rw [Finset.filter_filter]
  have hT : (Finset.range n).filter (fun x : ℕ => Nat.Coprime x n ∧ ¬ Q x) =
      U.filter (fun x => ¬ Q x) := by
    rw [Finset.filter_filter]
  have hsum := Finset.card_filter_add_card_filter_not (s := U) Q
  have hle : (U.filter Q).card ≤ (U.filter (fun x => ¬ Q x)).card := by
    apply Finset.card_le_card_of_injOn (fun x => (b * x) % n)
    · intro x hx
      simp only [Finset.mem_coe, Finset.mem_filter, Finset.mem_range, U] at hx ⊢
      obtain ⟨⟨_, hxc⟩, hxQ⟩ := hx
      have hxu : IsUnit ((x : ℕ) : ZMod n) := (ZMod.isUnit_iff_coprime x n).mpr hxc
      refine ⟨⟨Nat.mod_lt _ (by omega), ?_⟩, ?_⟩
      · rw [← ZMod.isUnit_iff_coprime, ZMod.natCast_mod, Nat.cast_mul]
        exact hbu.mul hxu
      · intro hQ
        apply hne
        simp only [Q] at hQ hxQ
        have hxg : Int.gcd (x : ℤ) n = 1 := by rw [Int.gcd_natCast_natCast]; exact hxc
        have hsq := jacobiSym.sq_one hxg
        rw [ZMod.natCast_mod, Int.natCast_mod, ← jacobiSym.mod_left, Nat.cast_mul,
          Nat.cast_mul, jacobiSym.mul_left, mul_pow, hxQ, Int.cast_mul] at hQ
        rw [← hbcast, ← hbJ]
        have h3 := congrArg (· * ((J((x : ℤ) | n) : ℤ) : ZMod n)) hQ
        have hsq' : ((J((x : ℤ) | n) : ℤ) : ZMod n) * ((J((x : ℤ) | n) : ℤ) : ZMod n) = 1 := by
          rw [← Int.cast_mul, ← sq, hsq, Int.cast_one]
        calc ((b : ℕ) : ZMod n) ^ e
            = ((b : ℕ) : ZMod n) ^ e * (((J((x : ℤ) | n) : ℤ) : ZMod n) *
                ((J((x : ℤ) | n) : ℤ) : ZMod n)) := by rw [hsq', mul_one]
          _ = ((J((b : ℤ) | n) : ℤ) : ZMod n) * (((J((x : ℤ) | n) : ℤ) : ZMod n) *
                ((J((x : ℤ) | n) : ℤ) : ZMod n)) := by linear_combination h3
          _ = ((J((b : ℤ) | n) : ℤ) : ZMod n) := by rw [hsq', mul_one]
    · intro x hx y hy hxy
      simp only [Finset.mem_coe, Finset.mem_filter, Finset.mem_range, U] at hx hy hxy
      have h2 := congrArg (fun z : ℕ => (z : ZMod n)) hxy
      simp only [ZMod.natCast_mod, Nat.cast_mul] at h2
      have h3 := hbu.mul_left_cancel h2
      rw [ZMod.natCast_eq_natCast_iff'] at h3
      rwa [Nat.mod_eq_of_lt hx.1.1, Nat.mod_eq_of_lt hy.1.1] at h3
  rw [hS]
  omega

-- The card's worked numbers.
-- (1001/9907) = -1, and 9907 is prime.
example : J(1001 | 9907) = -1 := by norm_num
example : Nat.Prime 9907 := by norm_num
-- Euler's power: 1001^4953 is 9906, that is -1, on the 9907 clock.
example : 1001 ^ 4953 % 9907 = 9906 := by decide +kernel
-- The factored route: (7/9907)(11/9907)(13/9907) = (-1)(+1)(+1).
example : 1001 = 7 * 11 * 13 := by norm_num
example : J(7 | 9907) = -1 ∧ J(11 | 9907) = 1 ∧ J(13 | 9907) = 1 := by norm_num
-- The rounds: (898/1001), (103/449), (37/103), (29/37), (8/29); (2/29) = -1.
example : J(898 | 1001) = -1 ∧ J(103 | 449) = -1 ∧ J(37 | 103) = -1 ∧ J(29 | 37) = -1 ∧
    J(8 | 29) = -1 ∧ J(2 | 29) = -1 := by norm_num
-- (2/15) = +1, yet 2 is not a square mod 15.
example : J(2 | 15) = 1 := by norm_num
example : ¬ IsSquare (2 : ZMod 15) := by decide
-- Flip without the sign rule fails: (3/7) = -1.
example : J(3 | 7) = -1 := by norm_num
-- Solovay-Strassen on 561, bases 2, 5, 13.
example : 2 ^ 280 % 561 = 1 ∧ J(2 | 561) = 1 := ⟨by decide +kernel, by norm_num⟩
example : 5 ^ 280 % 561 = 67 ∧ J(5 | 561) = 1 := ⟨by decide +kernel, by norm_num⟩
example : 13 ^ 280 % 561 = 1 ∧ J(13 | 561) = -1 := ⟨by decide +kernel, by norm_num⟩
example : 561 = 3 * 11 * 17 ∧ Nat.totient 561 = 320 := by
  refine ⟨by norm_num, by decide +kernel⟩
-- 561 has 80 Euler liars among its 320 coprime bases.
example : ((Finset.range 561).filter (fun a : ℕ => Nat.Coprime a 561 ∧
      ((a : ZMod 561) ^ ((561 - 1) / 2) = ((J((a : ℤ) | 561) : ℤ) : ZMod 561)))).card = 80 := by
  decide +kernel
-- 1729 has exactly half: 648 Euler liars among its 1296 coprime bases.
example : Nat.totient 1729 = 1296 := by decide +kernel
example : ((Finset.range 1729).filter (fun a : ℕ => Nat.Coprime a 1729 ∧
      ((a : ZMod 1729) ^ ((1729 - 1) / 2) = ((J((a : ℤ) | 1729) : ℤ) : ZMod 1729)))).card = 648 := by
  decide +kernel

#print axioms jacobi_symbol_reciprocity_rules
#print axioms odd_prime_iff_euler_power_eq_jacobi
#print axioms euler_liars_at_most_half
