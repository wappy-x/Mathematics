-- Credit indices (CDX and iTraxx in outline): the index par spread is total protection over total annuity, equal to the annuity-weighted average of the quotes, it sits at or below the plain average when the annuity falls as the spread rises, and the index legs depend only on each name's own default law, not on correlation.
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Algebra.Order.BigOperators.Ring.Finset
import Mathlib.Order.Monotone.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

open Finset MeasureTheory

/-- The sum rule. An index on `n` names, name `i` with protection leg `P i`, risky annuity
`A i > 0` and quote `s i = P i / A i`, all per $1 and with equal weights `1/n`. The index is
worth `(1/n) * ∑ (P i - x * A i)` to the buyer at coupon `x`. Then:
the coupon that makes the index worth zero (its intrinsic spread) is exactly total protection
over total annuity; that number is the average of the quotes weighted by annuity,
`w i = A i / ∑ A`; and at any fixed coupon `c` the upfront is
`(1/n) ∑ (P i - c A i) = (s_I - c) * Ā`, with `Ā` the average annuity. -/
theorem index_par_spread_eq_total_protection_over_total_annuity
    {n : ℕ} (hn : 0 < n) (P A s : Fin n → ℝ)
    (hA : ∀ i, 0 < A i) (hquote : ∀ i, s i = P i / A i) (c : ℝ) :
    (∀ x : ℝ, (1 / (n : ℝ)) * ∑ i, (P i - x * A i) = 0 ↔
        x = (∑ i, P i) / (∑ i, A i)) ∧
    (∑ i, P i) / (∑ i, A i) = ∑ i, (A i / ∑ l, A l) * s i ∧
    (1 / (n : ℝ)) * ∑ i, (P i - c * A i) =
      ((∑ i, P i) / (∑ i, A i) - c) * ((1 / (n : ℝ)) * ∑ i, A i) := by
  have hne : (Finset.univ : Finset (Fin n)).Nonempty := ⟨⟨0, hn⟩, by simp⟩
  have hSA : 0 < ∑ i, A i := Finset.sum_pos (fun i _ => hA i) hne
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have key : ∀ x : ℝ, ∑ i, (P i - x * A i) = ∑ i, P i - x * ∑ i, A i := by
    intro x; rw [Finset.sum_sub_distrib, Finset.mul_sum]
  refine ⟨?_, ?_, ?_⟩
  · intro x
    rw [key]
    constructor
    · intro h
      have h2 : ∑ i, P i - x * ∑ i, A i = 0 := by
        rcases mul_eq_zero.mp h with h | h
        · exact absurd h (by positivity)
        · exact h
      rw [eq_div_iff hSA.ne']
      linarith
    · intro h
      rw [h, div_mul_cancel₀ _ hSA.ne']
      ring
  · rw [Finset.sum_div]
    refine Finset.sum_congr rfl (fun i _ => ?_)
    rw [hquote i]
    have := (hA i).ne'
    field_simp
  · rw [key]
    field_simp

/-- The intrinsic spread never exceeds the plain average of the quotes, and equals it exactly
when every quote is the same. All names share one recovery, so a name's annuity is one function
`Aof` of its (positive) spread, positive and strictly decreasing; each name's protection leg is
its quote times its annuity. Then `∑ P / ∑ A ≤ (∑ s) / n`, with equality if and only if all
quotes are equal. -/
theorem intrinsic_spread_le_plain_average
    {n : ℕ} (Aof : ℝ → ℝ) (hanti : StrictAntiOn Aof (Set.Ioi 0))
    (hApos : ∀ x, 0 < x → 0 < Aof x)
    (s P : Fin n → ℝ) (hs : ∀ i, 0 < s i) (hquote : ∀ i, s i = P i / Aof (s i)) :
    (∑ i, P i) / (∑ i, Aof (s i)) ≤ (∑ i, s i) / n ∧
    ((∑ i, P i) / (∑ i, Aof (s i)) = (∑ i, s i) / n ↔ ∀ i j, s i = s j) := by
  rcases Nat.eq_zero_or_pos n with hn | hn
  · subst hn
    simp
  have hne : (Finset.univ : Finset (Fin n)).Nonempty := ⟨⟨0, hn⟩, by simp⟩
  have hSA : 0 < ∑ i, Aof (s i) := Finset.sum_pos (fun i _ => hApos _ (hs i)) hne
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have hP : ∀ i, P i = s i * Aof (s i) := by
    intro i
    have h := hquote i
    rw [eq_div_iff (hApos _ (hs i)).ne'] at h
    linarith
  have hsumP : ∑ i, P i = ∑ i, s i * Aof (s i) := Finset.sum_congr rfl (fun i _ => hP i)
  have hpair : ∀ i j, (s i - s j) * (Aof (s i) - Aof (s j)) ≤ 0 := by
    intro i j
    rcases lt_trichotomy (s i) (s j) with h | h | h
    · have := hanti (hs i) (hs j) h
      nlinarith
    · rw [h]; simp
    · have := hanti (hs j) (hs i) h
      nlinarith
  have hpair_strict : ∀ i j, s i ≠ s j → (s i - s j) * (Aof (s i) - Aof (s j)) < 0 := by
    intro i j hij
    rcases lt_or_gt_of_ne hij with h | h
    · have := hanti (hs i) (hs j) h
      nlinarith
    · have := hanti (hs j) (hs i) h
      nlinarith
  set D := ∑ i, ∑ j, (s i - s j) * (Aof (s i) - Aof (s j)) with hD
  have hiden : D = 2 * ((n : ℝ) * ∑ i, s i * Aof (s i) - (∑ i, s i) * ∑ i, Aof (s i)) := by
    rw [hD]
    simp only [mul_sub, sub_mul, Finset.sum_sub_distrib, Finset.sum_const, Finset.card_univ,
      Fintype.card_fin, nsmul_eq_mul, ← Finset.mul_sum, ← Finset.sum_mul]
    ring
  have hDle : D ≤ 0 := Finset.sum_nonpos (fun i _ => Finset.sum_nonpos (fun j _ => hpair i j))
  rw [hsumP]
  constructor
  · rw [div_le_div_iff₀ hSA hn']
    nlinarith
  · rw [div_eq_div_iff hSA.ne' hn'.ne']
    constructor
    · intro heq i j
      by_contra hij
      have hD0 : D = 0 := by rw [hiden]; linarith
      have hinner : ∀ k ∈ (Finset.univ : Finset (Fin n)),
          ∑ l, (s k - s l) * (Aof (s k) - Aof (s l)) = 0 :=
        (Finset.sum_eq_zero_iff_of_nonpos
          (fun k _ => Finset.sum_nonpos (fun l _ => hpair k l))).mp hD0
      have hterm := (Finset.sum_eq_zero_iff_of_nonpos (fun l _ => hpair i l)).mp
        (hinner i (Finset.mem_univ i)) j (Finset.mem_univ j)
      have := hpair_strict i j hij
      linarith
    · intro hall
      have hD0 : D = 0 := by
        rw [hD]
        refine Finset.sum_eq_zero (fun i _ => Finset.sum_eq_zero (fun j _ => ?_))
        rw [hall i j]; ring
      rw [hiden] at hD0
      linarith

/-- Correlation does not enter the index price. Each name's leg is a random payoff `X i`
(its discounted payout, or its discounted fee stream). Take any two joint laws `μ` and `ν`
for the names (independent, correlated, anything) under which every single name has the same
law. Then the index leg, the expected value of the equal-weight average of the names' legs,
is the same under both. -/
theorem index_leg_depends_only_on_each_names_law
    {Ω : Type*} [MeasurableSpace Ω] {n : ℕ} (X : Fin n → Ω → ℝ)
    (hX : ∀ i, Measurable (X i)) (μ ν : Measure Ω)
    (hint : ∀ i, Integrable (X i) μ)
    (hsame : ∀ i, μ.map (X i) = ν.map (X i)) :
    ∫ ω, (1 / (n : ℝ)) * ∑ i, X i ω ∂μ = ∫ ω, (1 / (n : ℝ)) * ∑ i, X i ω ∂ν := by
  have hint' : ∀ i, Integrable (X i) ν := by
    intro i
    have h1 : Integrable id (μ.map (X i)) :=
      (integrable_map_measure aestronglyMeasurable_id (hX i).aemeasurable).mpr (hint i)
    rw [hsame i] at h1
    exact (integrable_map_measure aestronglyMeasurable_id (hX i).aemeasurable).mp h1
  have heach : ∀ i, ∫ ω, X i ω ∂μ = ∫ ω, X i ω ∂ν := by
    intro i
    have h1 := integral_map (μ := μ) (hX i).aemeasurable (f := id) aestronglyMeasurable_id
    have h2 := integral_map (μ := ν) (hX i).aemeasurable (f := id) aestronglyMeasurable_id
    simp only [id] at h1 h2
    rw [← h1, ← h2, hsame i]
  rw [integral_const_mul, integral_const_mul, integral_finsetSum _ (fun i _ => hint i),
    integral_finsetSum _ (fun i _ => hint' i)]
  simp only [heach]

-- $10 million over 125 names: $80,000 a name.
example : (10000000 : ℚ) / 125 = 80000 := by norm_num
-- One default at 40% recovery pays (1 - R)/125 = 0.48% of notional, $48,000 on $10 million.
example : (1 - (2 : ℚ) / 5) / 125 = 48 / 10000 := by norm_num
example : (1 - (2 : ℚ) / 5) / 125 * 10000000 = 48000 := by norm_num
-- Wrong payout with no recovery: 1/125 = 0.80%.
example : (1 : ℚ) / 125 = 80 / 10000 := by norm_num
-- Notional after one default: $9,920,000.
example : (10000000 : ℚ) * 124 / 125 = 9920000 := by norm_num
-- Quarterly coupon at 100 bp: $25,000 before the default, $24,800 after.
example : (1 : ℚ) / 100 * (1 / 4) * 10000000 = 25000 := by norm_num
example : (1 : ℚ) / 100 * (1 / 4) * 10000000 * 124 / 125 = 24800 := by norm_num
-- Plain average of the quotes: (100 × 80 + 25 × 300)/125 = 124 bp.
example : ((100 * 80 + 25 * 300 : ℚ)) / 125 = 124 := by norm_num
-- Wrong skew against the plain average: 117 - 124 = -7 bp.
example : (117 : ℚ) - 124 = -7 := by norm_num
-- Chart's plain-average line: (8000 + 25 w)/125 for w = 100, ..., 800.
example : ((8000 + 25 * 100 : ℚ)) / 125 = 84 ∧ ((8000 + 25 * 800 : ℚ)) / 125 = 224 := by norm_num

#print axioms index_par_spread_eq_total_protection_over_total_annuity
#print axioms intrinsic_spread_le_plain_average
#print axioms index_leg_depends_only_on_each_names_law
