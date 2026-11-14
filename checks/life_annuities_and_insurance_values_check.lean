-- Life annuities and insurance: at any positive interest rate and on any life table, the whole-life insurance value plus the discount rate times the life annuity-due value is exactly one.
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Topology.Algebra.InfiniteSum.Real

/-! Notation, as on the card.

* `i` is the yearly interest rate, `v = 1 / (1 + i)` the one-year discount factor and
  `d = i / (1 + i)` the discount rate (interest paid in advance).
* `p k` is `ₖpₓ`, the chance a life aged `x` is alive `k` years later; `p 0 = 1`.
* `q k` is `q_{x+k}`, the chance that someone alive at age `x + k` dies within the year,
  so `p (k + 1) = p k * (1 - q k)`.
* The life annuity-due is `ä_x = ∑ₖ vᵏ ₖpₓ`.
* The whole-life insurance (paid at the end of the year of death) is
  `A_x = ∑ₖ vᵏ⁺¹ ₖpₓ q_{x+k}`.
-/

/-- The card's main claim: price each payment as its discounted amount times the chance it
is made and add them up. Then, for any life table and any positive interest rate `i`, the
whole-life insurance value `A_x` plus the discount rate `d = i/(1+i)` times the life
annuity-due value `ä_x` is exactly one: `A_x + d ä_x = 1`. -/
theorem insurance_add_discount_mul_annuity_due_eq_one
    (i : ℝ) (hi : 0 < i) (p q : ℕ → ℝ)
    (hp0 : p 0 = 1) (hq : ∀ k, 0 ≤ q k ∧ q k ≤ 1)
    (hpq : ∀ k, p (k + 1) = p k * (1 - q k)) :
    (∑' k : ℕ, (1 / (1 + i)) ^ (k + 1) * p k * q k)
      + i / (1 + i) * (∑' k : ℕ, (1 / (1 + i)) ^ k * p k) = 1 := by
  have hp : ∀ k, 0 ≤ p k ∧ p k ≤ 1 := by
    intro k
    induction k with
    | zero => simp [hp0]
    | succ n ih =>
      rw [hpq]
      obtain ⟨h1, h2⟩ := hq n
      constructor
      · exact mul_nonneg ih.1 (by linarith)
      · nlinarith [ih.1, ih.2]
  set v : ℝ := 1 / (1 + i) with hv
  have hv0 : 0 ≤ v := by positivity
  have hv1 : v < 1 := by rw [hv, div_lt_one (by linarith)]; linarith
  set f : ℕ → ℝ := fun k => v ^ k * p k with hf
  have hfs : Summable f := by
    refine Summable.of_nonneg_of_le (fun k => mul_nonneg (pow_nonneg hv0 k) (hp k).1)
      (fun k => ?_) (summable_geometric_of_lt_one hv0 hv1)
    exact mul_le_of_le_one_right (pow_nonneg hv0 k) (hp k).2
  have hterm : ∀ k, v ^ (k + 1) * p k * q k = v * f k - f (k + 1) := by
    intro k
    simp only [hf, hpq]
    ring
  have hfs1 : Summable (fun k => f (k + 1)) := (summable_nat_add_iff 1).mpr hfs
  have hA : (∑' k : ℕ, v ^ (k + 1) * p k * q k) = v * (∑' k, f k) - (∑' k, f (k + 1)) := by
    simp_rw [hterm]
    rw [(hfs.mul_left v).tsum_sub hfs1, tsum_mul_left]
  have hsplit : (∑' k, f k) = f 0 + ∑' k, f (k + 1) := hfs.tsum_eq_zero_add
  have hf0 : f 0 = 1 := by simp [hf, hp0]
  have hd : i / (1 + i) = 1 - v := by
    rw [hv]; field_simp; ring
  show (∑' k : ℕ, v ^ (k + 1) * p k * q k) + i / (1 + i) * (∑' k, f k) = 1
  rw [hA, hd, hsplit, hf0]
  ring

/-- One life, one dollar, split two ways: if the life lives `K` more whole years, its
annuity-due payments discounted to today are `Y = 1 + v + ⋯ + v^K`, its insurance payment
discounted to today is `Z = v^(K+1)`, and `d Y + Z = 1` for every `K`. -/
theorem discount_mul_annuity_payments_add_insurance_payment_eq_one
    (i : ℝ) (hi : 0 < i) (K : ℕ) :
    i / (1 + i) * (∑ j ∈ Finset.range (K + 1), (1 / (1 + i)) ^ j)
      + (1 / (1 + i)) ^ (K + 1) = 1 := by
  have hd : i / (1 + i) = 1 - 1 / (1 + i) := by
    field_simp; ring
  rw [hd]
  induction K with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_range_succ]
    rw [← sub_eq_zero] at ih ⊢
    rw [← ih]
    ring

/-- The card's toy basis, checked by hand: if 90 percent of the living survive every year
(`ₖpₓ = 0.9ᵏ`, `q = 0.1`) and interest is 5 percent, the life annuity-due is worth exactly 7
and the whole-life insurance exactly 2/3. -/
theorem toy_basis_annuity_due_eq_seven_and_insurance_eq_two_thirds :
    (∑' k : ℕ, (1 / (1 + 1 / 20 : ℝ)) ^ k * (9 / 10 : ℝ) ^ k = 7) ∧
    (∑' k : ℕ, (1 / (1 + 1 / 20 : ℝ)) ^ (k + 1) * (9 / 10 : ℝ) ^ k * (1 / 10) = 2 / 3) := by
  have hg : (∑' k : ℕ, (6 / 7 : ℝ) ^ k) = 7 := by
    rw [tsum_geometric_of_lt_one (by norm_num) (by norm_num)]; norm_num
  constructor
  · have : ∀ k : ℕ, (1 / (1 + 1 / 20 : ℝ)) ^ k * (9 / 10 : ℝ) ^ k = (6 / 7 : ℝ) ^ k := by
      intro k; rw [← mul_pow]; norm_num
    simp_rw [this]; exact hg
  · have : ∀ k : ℕ, (1 / (1 + 1 / 20 : ℝ)) ^ (k + 1) * (9 / 10 : ℝ) ^ k * (1 / 10)
        = (2 / 21 : ℝ) * (6 / 7 : ℝ) ^ k := by
      intro k; rw [pow_succ]
      have : (1 / (1 + 1 / 20 : ℝ)) ^ k * (9 / 10 : ℝ) ^ k = (6 / 7 : ℝ) ^ k := by
        rw [← mul_pow]; norm_num
      calc _ = ((1 / (1 + 1 / 20 : ℝ)) ^ k * (9 / 10 : ℝ) ^ k) * ((1 / (1 + 1 / 20 : ℝ)) * (1/10)) := by ring
        _ = _ := by rw [this]; norm_num; ring
    simp_rw [this]; rw [tsum_mul_left, hg]; norm_num

-- Toy basis, by hand: 0.9 v = 0.9 / 1.05 = 6/7.
example : (9 / 10 : ℚ) * (1 / (1 + 1 / 20)) = 6 / 7 := by norm_num
-- The discount rate at 5 percent: d = 0.05 / 1.05 = 1/21.
example : (1 / 20 : ℚ) / (1 + 1 / 20) = 1 / 21 := by norm_num
-- The annuity is the geometric series 1 / (1 - 6/7) = 7.
example : (1 : ℚ) / (1 - 6 / 7) = 7 := by norm_num
-- The insurance is 0.1 v × 7 = (2/21) × 7 = 2/3.
example : (1 / 10 : ℚ) * (1 / (1 + 1 / 20)) * 7 = 2 / 3 := by norm_num
-- And the identity: 2/3 + (1/21) × 7 = 1.
example : (2 / 3 : ℚ) + 1 / 21 * 7 = 1 := by norm_num
-- One life that lives 2 more whole years, at 5 percent: d (1 + v + v²) + v³ = 1.
example : (1 / 21 : ℚ) * (1 + 20 / 21 + (20 / 21) ^ 2) + (20 / 21) ^ 3 = 1 := by norm_num

#print axioms insurance_add_discount_mul_annuity_due_eq_one
#print axioms discount_mul_annuity_payments_add_insurance_payment_eq_one
#print axioms toy_basis_annuity_due_eq_seven_and_insurance_eq_two_thirds
