-- Option-adjusted spread: a price that is a sum of positive yearly weights times e^(-s t) falls strictly as the spread s rises and meets each positive price at exactly one spread, and the card's scheduled principal gives a level yearly payment.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Analysis.SpecialFunctions.Exp

open Finset


/-- Helper: the model price falls strictly as the spread rises. -/
theorem oas_price_strictAnti_aux (n : ℕ) (hn : 1 ≤ n) (w : ℕ → ℝ)
    (hw : ∀ t ∈ Icc 1 n, 0 < w t) :
    StrictAnti (fun s : ℝ => ∑ t ∈ Icc 1 n, w t * Real.exp (-s * t)) := by
  intro a b hab
  have hne : (Icc 1 n).Nonempty := ⟨1, by simp [hn]⟩
  refine Finset.sum_lt_sum_of_nonempty hne ?_
  intro t ht
  have ht1 : (1 : ℝ) ≤ t := by
    have := (Finset.mem_Icc.mp ht).1
    exact_mod_cast this
  apply mul_lt_mul_of_pos_left _ (hw t ht)
  apply Real.exp_lt_exp.mpr
  nlinarith

/-- Helper: closed form of the remaining balance after `i` scheduled years. -/
theorem oas_balance_closed_form (c : ℝ) (hc : 0 < c) (n : ℕ) (hn : 1 ≤ n) :
    ∀ i, i ≤ n → ∏ k ∈ range i, (1 - c / ((1 + c) ^ (n - k) - 1))
      = (1 + c) ^ i * ((1 + c) ^ (n - i) - 1) / ((1 + c) ^ n - 1) := by
  have hq : (1 : ℝ) < 1 + c := by linarith
  have h2 : (1 + c) ^ n - 1 ≠ 0 := by
    have := one_lt_pow₀ hq (by omega : n ≠ 0)
    linarith
  intro i hi
  induction i with
  | zero => simp; field_simp
  | succ i ih =>
    rw [prod_range_succ, ih (by omega)]
    obtain ⟨m, hm⟩ : ∃ m, n - i = m + 1 := ⟨n - i - 1, by omega⟩
    have hm2 : n - (i + 1) = m := by omega
    rw [hm, hm2]
    have h1 : (1 + c) ^ (m + 1) - 1 ≠ 0 := by
      have := one_lt_pow₀ hq (by omega : m + 1 ≠ 0)
      linarith
    field_simp
    ring

/-- Step 4 of the card: once the spread only shifts the discounting, the model price is
`price(s) = ∑_{t=1}^{n} w_t e^{-s t}` with every yearly weight `w_t > 0`. A market price `P`
is met by exactly one spread `s` (the OAS) precisely when `P` is positive; a price of zero or
less has no spread at all. -/
theorem oas_exists_unique_iff_price_pos (n : ℕ) (hn : 1 ≤ n) (w : ℕ → ℝ)
    (hw : ∀ t ∈ Icc 1 n, 0 < w t) (P : ℝ) :
    (∃! s : ℝ, ∑ t ∈ Icc 1 n, w t * Real.exp (-s * t) = P) ↔ 0 < P := by
  set f : ℝ → ℝ := fun s => ∑ t ∈ Icc 1 n, w t * Real.exp (-s * t) with hf
  have hne : (Icc 1 n).Nonempty := ⟨1, by simp [hn]⟩
  have hpos : ∀ s, 0 < f s := fun s =>
    Finset.sum_pos (fun t ht => mul_pos (hw t ht) (Real.exp_pos _)) hne
  constructor
  · rintro ⟨s, hs, -⟩
    have := hpos s
    simp only [hf] at this
    linarith
  · intro hP
    have hanti := oas_price_strictAnti_aux n hn w hw
    refine existsUnique_of_exists_of_unique ?_ ?_
    · set W := ∑ t ∈ Icc 1 n, w t with hW
      have hWpos : 0 < W := Finset.sum_pos (fun t ht => hw t ht) hne
      have h1mem : 1 ∈ Icc 1 n := by simp [hn]
      have hw1 : 0 < w 1 := hw 1 h1mem
      -- upper spread
      set b := W / P with hb
      have hb0 : 0 ≤ b := div_nonneg hWpos.le hP.le
      have hfb : f b ≤ P := by
        have hle : f b ≤ W * Real.exp (-b) := by
          simp only [hf, hW, Finset.sum_mul]
          apply Finset.sum_le_sum
          intro t ht
          have ht1 : (1 : ℝ) ≤ t := by
            have := (Finset.mem_Icc.mp ht).1
            exact_mod_cast this
          apply mul_le_mul_of_nonneg_left _ (hw t ht).le
          apply Real.exp_le_exp.mpr
          nlinarith
        have he : Real.exp (-b) * Real.exp b = 1 := by
          rw [← Real.exp_add]; simp
        have hexp : b + 1 ≤ Real.exp b := Real.add_one_le_exp b
        have hPb : P * b = W := by rw [hb]; field_simp
        have hk : W ≤ P * Real.exp b := by nlinarith
        have hk2 : W * Real.exp (-b) ≤ P * Real.exp b * Real.exp (-b) :=
          mul_le_mul_of_nonneg_right hk (Real.exp_pos _).le
        have : P * Real.exp b * Real.exp (-b) = P := by
          rw [mul_assoc, mul_comm (Real.exp b), he, mul_one]
        linarith
      -- lower spread
      set a := -(P / w 1) with ha
      have ha0 : a ≤ 0 := by
        rw [ha]; have := div_pos hP hw1; linarith
      have hfa : P ≤ f a := by
        have hge : w 1 * Real.exp (-a * (1 : ℕ)) ≤ f a := by
          simp only [hf]
          exact Finset.single_le_sum (f := fun t => w t * Real.exp (-a * t))
            (fun t ht => (mul_pos (hw t ht) (Real.exp_pos _)).le) h1mem
        have hexp : -a + 1 ≤ Real.exp (-a) := Real.add_one_le_exp (-a)
        have hwa : w 1 * (-a) = P := by rw [ha]; field_simp
        simp only [Nat.cast_one, mul_one] at hge
        nlinarith
      have hab : a ≤ b := le_trans ha0 hb0
      have hcont : ContinuousOn f (Set.Icc a b) := by
        apply Continuous.continuousOn
        simp only [hf]
        fun_prop
      obtain ⟨s, -, hs⟩ := intermediate_value_Icc' hab hcont ⟨hfb, hfa⟩
      exact ⟨s, hs⟩
    · intro x y hx hy
      exact hanti.injective (hx.trans hy.symm)

/-- Step 4 of the card: each term shrinks as the spread rises, so the model price falls
strictly in the spread; no two spreads give the same price. -/
theorem oas_price_strictAnti (n : ℕ) (hn : 1 ≤ n) (w : ℕ → ℝ)
    (hw : ∀ t ∈ Icc 1 n, 0 < w t) :
    StrictAnti (fun s : ℝ => ∑ t ∈ Icc 1 n, w t * Real.exp (-s * t)) := by
  exact oas_price_strictAnti_aux n hn w hw

/-- The card's scheduled principal: with coupon `c > 0` and `n - i` years left, a dollar of
balance repays `g_i = c / ((1+c)^(n-i) - 1)` on schedule in year `i+1`. With no prepayment the
balance still owed after `i` years is `∏_{k<i} (1 - g_k)`, and the year's payment
(interest plus scheduled principal) is the same level annuity payment `c / (1 - (1+c)^(-n))`
in every year `i < n`. -/
theorem scheduled_principal_level_payment (c : ℝ) (hc : 0 < c) (n i : ℕ) (hi : i < n) :
    (∏ k ∈ range i, (1 - c / ((1 + c) ^ (n - k) - 1))) * (c + c / ((1 + c) ^ (n - i) - 1))
      = c / (1 - ((1 + c) ^ n)⁻¹) := by
  rw [oas_balance_closed_form c hc n (by omega) i hi.le]
  obtain ⟨m, rfl⟩ : ∃ m, n = i + (m + 1) := ⟨n - i - 1, by omega⟩
  have hnm : i + (m + 1) - i = m + 1 := by omega
  rw [hnm]
  have hq : (1 : ℝ) < 1 + c := by linarith
  have h1 : (1 + c) ^ (m + 1) - 1 ≠ 0 := by
    have := one_lt_pow₀ hq (by omega : m + 1 ≠ 0)
    linarith
  have h2 : (1 + c) ^ (i + (m + 1)) - 1 ≠ 0 := by
    have := one_lt_pow₀ hq (by omega : i + (m + 1) ≠ 0)
    linarith
  have hp : (1 + c) ^ (i + (m + 1)) ≠ 0 := by positivity
  rw [show 1 - ((1 + c) ^ (i + (m + 1)))⁻¹
      = ((1 + c) ^ (i + (m + 1)) - 1) / (1 + c) ^ (i + (m + 1)) by field_simp]
  rw [pow_add (1 + c) i (m + 1)] at h2 hp ⊢
  have hX : (1 + c) ^ i ≠ 0 := by positivity
  generalize (1 + c) ^ i = X at h2 hp hX ⊢
  generalize (1 + c) ^ (m + 1) = Y at h1 h2 hp ⊢
  field_simp
  ring

-- The card's exact arithmetic, as fractions.
-- Zero curve: zero(t) = 3.5% + 0.05% t, so 3.55% at one year, 4.00% at ten, 5.00% at thirty.
example : (35 : ℚ) / 1000 + 5 / 10000 * 1 = 355 / 10000 := by norm_num
example : (35 : ℚ) / 1000 + 5 / 10000 * 10 = 4 / 100 := by norm_num
example : (35 : ℚ) / 1000 + 5 / 10000 * 30 = 5 / 100 := by norm_num
-- Year-16 forward rate: 16 zero(16) - 15 zero(15) = 5.05%.
example : (16 : ℚ) * (35 / 1000 + 5 / 10000 * 16) - 15 * (35 / 1000 + 5 / 10000 * 15)
    = 505 / 10000 := by norm_num
-- Prepayment rule p(r) = 8% + 14 max(0, 5% - r): 28.30% at 3.55%, and 8.00% at 5.05%.
example : (8 : ℚ) / 100 + 14 * max 0 (5 / 100 - 355 / 10000) = 283 / 1000 := by norm_num
example : (8 : ℚ) / 100 + 14 * max 0 (5 / 100 - 505 / 10000) = 8 / 100 := by norm_num
-- Year-1 interest on $100 at 6%, and the year-1 cash flow 6 + 1.2649 + 27.9420.
example : (100 : ℚ) * (6 / 100) = 6 := by norm_num
example : (6 : ℚ) + 12649 / 10000 + 279420 / 10000 = 352069 / 10000 := by norm_num
-- Option cost as a spread, in ten-thousandths of a basis point: 110.1237 - 59.9366 = 50.1871.
example : (1101237 : ℤ) - 599366 = 501871 := by norm_num

#print axioms oas_price_strictAnti_aux
#print axioms oas_balance_closed_form
#print axioms oas_exists_unique_iff_price_pos
#print axioms oas_price_strictAnti
#print axioms scheduled_principal_level_payment
