-- Solving a x ≡ b (mod n): on a dial of n positions, a x ≡ b (mod n) has answers exactly when gcd(a, n) divides b, and then it has exactly gcd(a, n) answers from 0 to n - 1, spaced n ÷ gcd(a, n) apart, the same answers as the shrunk congruence with a, b and n all divided by the gcd.
import Mathlib.Data.Nat.ModEq
import Mathlib.Data.Nat.GCD.Basic
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Tactic.NormNum.GCD
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith


theorem shrink_pos_aux (a b n x : ℕ) (hn : 0 < n) (hg : Nat.gcd a n ∣ b) :
    a * x ≡ b [MOD n] ↔
      a / Nat.gcd a n * x ≡ b / Nat.gcd a n [MOD n / Nat.gcd a n] := by
  have hgpos : 0 < Nat.gcd a n := Nat.gcd_pos_of_pos_right a hn
  obtain ⟨a', ha⟩ := Nat.gcd_dvd_left a n
  obtain ⟨n', hn'⟩ := Nat.gcd_dvd_right a n
  obtain ⟨b', hb⟩ := hg
  obtain ⟨g, hgdef⟩ : ∃ g, g = Nat.gcd a n := ⟨_, rfl⟩
  rw [← hgdef] at hgpos ha hn' hb ⊢
  have h1 : a / g = a' := Nat.div_eq_of_eq_mul_right hgpos (by linarith)
  have h2 : n / g = n' := Nat.div_eq_of_eq_mul_right hgpos (by linarith)
  have h3 : b / g = b' := Nat.div_eq_of_eq_mul_right hgpos (by linarith)
  rw [h1, h2, h3, ha, hb, hn', mul_assoc]
  exact Nat.ModEq.mul_left_cancel_iff' hgpos.ne'

#print axioms shrink_pos_aux

theorem core_aux (a b n : ℕ) (hn : 0 < n) (hg : Nat.gcd a n ∣ b) :
    ∃ x₀ < n / Nat.gcd a n, ∀ x, (a * x ≡ b [MOD n] ↔ x ≡ x₀ [MOD n / Nat.gcd a n]) := by
  have hgpos : 0 < Nat.gcd a n := Nat.gcd_pos_of_pos_right a hn
  have hcop := Nat.coprime_div_gcd_div_gcd hgpos
  have hn'pos : 0 < n / Nat.gcd a n := Nat.div_pos (Nat.le_of_dvd hn (Nat.gcd_dvd_right a n)) hgpos
  obtain ⟨x₀, hx₀, h⟩ := Nat.exists_mul_mod_eq_of_coprime (b / Nat.gcd a n) hcop hn'pos.ne'
  refine ⟨x₀, hx₀, fun x => ?_⟩
  rw [shrink_pos_aux a b n x hn hg]
  have h' : a / Nat.gcd a n * x₀ ≡ b / Nat.gcd a n [MOD n / Nat.gcd a n] := h
  constructor
  · intro h1
    have h2 : a / Nat.gcd a n * x ≡ a / Nat.gcd a n * x₀ [MOD n / Nat.gcd a n] :=
      h1.trans h'.symm
    exact Nat.ModEq.cancel_left_of_coprime (by simpa [Nat.Coprime, Nat.gcd_comm] using hcop) h2
  · intro h1
    exact (h1.mul_left _).trans h'

#print axioms core_aux

theorem spaced_aux (a b n : ℕ) (hn : 0 < n)
    (hg : Nat.gcd a n ∣ b) :
    ∃ x₀ < n / Nat.gcd a n,
      (Finset.range n).filter (fun x => a * x ≡ b [MOD n]) =
        (Finset.range (Nat.gcd a n)).image (fun k => x₀ + k * (n / Nat.gcd a n)) := by
  obtain ⟨x₀, hx₀, hiff⟩ := core_aux a b n hn hg
  refine ⟨x₀, hx₀, ?_⟩
  have hgpos : 0 < Nat.gcd a n := Nat.gcd_pos_of_pos_right a hn
  have hn' : Nat.gcd a n * (n / Nat.gcd a n) = n := Nat.mul_div_cancel' (Nat.gcd_dvd_right a n)
  have hn'pos : 0 < n / Nat.gcd a n := by
    by_contra hh
    have : n / Nat.gcd a n = 0 := by omega
    rw [this] at hn'; omega
  ext x
  simp only [Finset.mem_filter, Finset.mem_range, Finset.mem_image]
  constructor
  · rintro ⟨hx, hmod⟩
    rw [hiff] at hmod
    have hmod' : x % (n / Nat.gcd a n) = x₀ := by
      have : x % (n / Nat.gcd a n) = x₀ % (n / Nat.gcd a n) := hmod
      rwa [Nat.mod_eq_of_lt hx₀] at this
    refine ⟨x / (n / Nat.gcd a n), ?_, ?_⟩
    · apply Nat.div_lt_of_lt_mul
      rw [mul_comm]; omega
    · have := Nat.mod_add_div x (n / Nat.gcd a n)
      rw [hmod'] at this
      rw [mul_comm]; exact this
  · rintro ⟨k, hk, rfl⟩
    refine ⟨?_, ?_⟩
    · have : (k + 1) * (n / Nat.gcd a n) ≤ Nat.gcd a n * (n / Nat.gcd a n) :=
        Nat.mul_le_mul_right _ hk
      nlinarith
    · rw [hiff]
      show (x₀ + k * (n / Nat.gcd a n)) % (n / Nat.gcd a n) = x₀ % (n / Nat.gcd a n)
      rw [Nat.add_mul_mod_self_right]

-- The card's dial: 10 positions, 6 places a click. It reads 0 6 2 8 4 0 6 2 8 4.
example : (List.range 10).map (fun x => 6 * x % 10) = [0, 6, 2, 8, 4, 0, 6, 2, 8, 4] := by decide
-- gcd(6, 10) = 2, and 2 divides the target 4.
example : Nat.gcd 6 10 = 2 ∧ 2 ∣ 4 := by norm_num
-- Aiming at 4: the answers are 4 and 9, two of them, five apart.
example : (Finset.range 10).filter (fun x => 6 * x ≡ 4 [MOD 10]) = {4, 9} := by decide
example : 6 * 4 = 2 * 10 + 4 ∧ 6 * 9 = 5 * 10 + 4 ∧ 10 / 2 = 5 := by norm_num
-- The shrunk clock: 3 x ≡ 2 (mod 5). The inverse of 3 is 2, and the one answer is 4.
example : 3 * 2 ≡ 1 [MOD 5] ∧ 2 * 2 ≡ 4 [MOD 5] := by decide
example : (Finset.range 5).filter (fun x => 3 * x ≡ 2 [MOD 5]) = {4} := by decide
-- 14 clicks leaves the 10-dial where 4 clicks does.
example : 14 ≡ 4 [MOD 10] := by decide
-- The Diophantine costume: 6 x + 10 y = 4 with x = 4, 9, 14, 19 and y = -2, -5, -8, -11.
example : (6 : ℤ) * 4 + 10 * (-2) = 4 ∧ (6 : ℤ) * 9 + 10 * (-5) = 4 ∧
    (6 : ℤ) * 14 + 10 * (-8) = 4 ∧ (6 : ℤ) * 19 + 10 * (-11) = 4 := by norm_num
-- Aiming at 3: 2 does not divide 3, and there are 0 answers.
example : ¬ (2 ∣ 3) ∧ (Finset.range 10).filter (fun x => 6 * x ≡ 3 [MOD 10]) = ∅ := by decide
-- The usual mistake: halving 6 and 4 but keeping the 10 gives only one answer, 4.
example : (Finset.range 10).filter (fun x => 3 * x ≡ 2 [MOD 10]) = {4} := by decide
-- Try changing: aim at 8 gives 3 and 8; step 7 gives the one answer 2; 8 x ≡ 4 (mod 12)
-- has gcd 4 and four answers 2, 5, 8 and 11.
example : (Finset.range 10).filter (fun x => 6 * x ≡ 8 [MOD 10]) = {3, 8} := by decide
example : Nat.gcd 7 10 = 1 ∧ (Finset.range 10).filter (fun x => 7 * x ≡ 4 [MOD 10]) = {2} := by
  decide
example : Nat.gcd 8 12 = 4 ∧
    (Finset.range 12).filter (fun x => 8 * x ≡ 4 [MOD 12]) = {2, 5, 8, 11} := by decide

#print axioms spaced_aux

/-- The gcd decides everything. On a dial of n positions (n at least 1), count the click numbers
x from 0 to n - 1 with a × x ≡ b (mod n). If gcd(a, n) does not divide the target b, there are
no answers at all; if it does, there are exactly gcd(a, n) answers. -/
theorem linear_congruence_answer_count_is_gcd_or_zero (a b n : ℕ) (hn : 0 < n) :
    ((Finset.range n).filter (fun x => a * x ≡ b [MOD n])).card =
      if Nat.gcd a n ∣ b then Nat.gcd a n else 0 := by
  by_cases hg : Nat.gcd a n ∣ b
  · rw [if_pos hg]
    obtain ⟨x₀, hx₀, h⟩ := spaced_aux a b n hn hg
    have hgpos : 0 < Nat.gcd a n := Nat.gcd_pos_of_pos_right a hn
    have hn'pos : 0 < n / Nat.gcd a n :=
      Nat.div_pos (Nat.le_of_dvd hn (Nat.gcd_dvd_right a n)) hgpos
    rw [h, Finset.card_image_of_injective, Finset.card_range]
    intro k1 k2 hk
    have : k1 * (n / Nat.gcd a n) = k2 * (n / Nat.gcd a n) := by
      simp only at hk; omega
    exact Nat.eq_of_mul_eq_mul_right hn'pos this
  · rw [if_neg hg, Finset.card_eq_zero, Finset.filter_eq_empty_iff]
    intro x _ h
    apply hg
    have h1 : Nat.gcd a n ∣ Nat.gcd (a * x) n :=
      Nat.gcd_dvd_gcd_of_dvd_left n (dvd_mul_right a x)
    rw [Nat.ModEq.gcd_eq h] at h1
    exact h1.trans (Nat.gcd_dvd_left b n)

/-- Shrink the clock. When the gcd g of a and n divides b, dividing all three (step, target and
dial) by g loses nothing: a × x ≡ b (mod n) has the same answers x as
(a ÷ g) × x ≡ b ÷ g (mod n ÷ g). -/
theorem linear_congruence_same_answers_after_shrinking (a b n x : ℕ) (hg : Nat.gcd a n ∣ b) :
    a * x ≡ b [MOD n] ↔
      a / Nat.gcd a n * x ≡ b / Nat.gcd a n [MOD n / Nat.gcd a n] := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · rcases Nat.eq_zero_or_pos a with rfl | ha
    · have : b = 0 := by simpa using hg
      subst this
      simp [Nat.ModEq]
    · obtain ⟨c, hc⟩ := hg
      simp only [Nat.gcd_zero_right] at hc ⊢
      subst hc
      simp [Nat.ModEq, Nat.div_self ha, Nat.mul_div_cancel_left c ha]
      omega
  · exact shrink_pos_aux a b n x hn hg

/-- Unfold. When gcd(a, n) divides b, the answers on the n-dial are one answer x₀ of the shrunk
clock (x₀ below n ÷ gcd) and then every step of n ÷ gcd after it, gcd(a, n) answers in all:
x₀, x₀ + n ÷ gcd, x₀ + 2 × (n ÷ gcd), and so on. -/
theorem linear_congruence_answers_are_spaced_n_over_gcd (a b n : ℕ) (hn : 0 < n)
    (hg : Nat.gcd a n ∣ b) :
    ∃ x₀ < n / Nat.gcd a n,
      (Finset.range n).filter (fun x => a * x ≡ b [MOD n]) =
        (Finset.range (Nat.gcd a n)).image (fun k => x₀ + k * (n / Nat.gcd a n)) := by
  exact spaced_aux a b n hn hg

#print axioms linear_congruence_answer_count_is_gcd_or_zero
#print axioms linear_congruence_same_answers_after_shrinking
#print axioms linear_congruence_answers_are_spaced_n_over_gcd
