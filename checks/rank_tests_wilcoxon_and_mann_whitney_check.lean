-- Rank tests: with midranks, Mann-Whitney U = R_A − n(n+1)/2 counts the A-against-B pairs where A is larger (ties one half), over all equally likely rank sets U has centre nm/2 and variance nm(N+1)/12, and for normal data the efficiency 12σ²(∫f²)² equals 3/π.
import Mathlib.Data.Finset.Powerset
import Mathlib.Data.Fintype.Sum
import Mathlib.Data.Fintype.Prod
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open Finset MeasureTheory ProbabilityTheory Real

/-- The midrank of value `k` in a pooled list `z`: the number of values strictly below it,
plus the average of the places shared by the values tied with it (itself included).
With no ties this is the ordinary rank 1, 2, …, N; two values tied for places 3 and 4
both get 3.5. -/
noncomputable def midrank {ι : Type*} [Fintype ι] (z : ι → ℝ) (k : ι) : ℝ :=
  (#{l | z l < z k} : ℝ) + ((#{l | z l = z k} : ℝ) + 1) / 2

lemma half_pairs_within (n : ℕ) (x : Fin n → ℝ) :
    (∑ i, ∑ j, ((if x j < x i then (1:ℝ) else 0) + (1/2) * (if x j = x i then (1:ℝ) else 0)))
      = (n : ℝ) * n / 2 := by
  set f : Fin n → Fin n → ℝ := fun i j =>
    (if x j < x i then (1:ℝ) else 0) + (1/2) * (if x j = x i then (1:ℝ) else 0) with hf
  have hpair : ∀ i j, f i j + f j i = 1 := by
    intro i j
    simp only [hf]
    rcases lt_trichotomy (x i) (x j) with h | h | h
    · simp [h, h.ne, h.ne', not_lt.mpr h.le]
    · simp [h]; norm_num
    · simp [h, h.ne, h.ne', not_lt.mpr h.le]
  have hs : (∑ i, ∑ j, f i j) = ∑ i, ∑ j, f j i := Finset.sum_comm
  have h2 : (∑ i, ∑ j, f i j) + (∑ i, ∑ j, f j i) = (n : ℝ) * n := by
    rw [← Finset.sum_add_distrib]
    simp_rw [← Finset.sum_add_distrib, hpair]
    simp
  show (∑ i, ∑ j, f i j) = _
  linarith
#print axioms half_pairs_within

lemma card_filter_sum_type {α β : Type*} [Fintype α] [Fintype β] (p : α ⊕ β → Prop)
    [DecidablePred p] :
    (#{l | p l} : ℝ) = (#{a | p (Sum.inl a)} : ℝ) + (#{b | p (Sum.inr b)} : ℝ) := by
  simp only [natCast_card_filter, Fintype.sum_sum_type]

#print axioms card_filter_sum_type

/-- The rank sum minus a constant counts the pairs (the formula, and Step 1). Shop A has
`n` values `x` and shop B has `m` values `y`; pool all of them and give each its midrank.
Then U = R_A − n(n+1)/2, A's rank sum minus the smallest sum A could have, equals the
number of A-against-B pairs in which the A value is larger, with each tied pair counting
one half. -/
theorem rank_sum_minus_constant_counts_pairs (n m : ℕ) (x : Fin n → ℝ) (y : Fin m → ℝ) :
    (∑ i, midrank (Sum.elim x y) (Sum.inl i)) - (n : ℝ) * (n + 1) / 2 =
      (#{p : Fin n × Fin m | y p.2 < x p.1} : ℝ) +
        (1 / 2) * (#{p : Fin n × Fin m | y p.2 = x p.1} : ℝ) := by
  have hw := half_pairs_within n x
  have hi : ∀ i : Fin n, midrank (Sum.elim x y) (Sum.inl i) =
      ((#{j | x j < x i} : ℝ) + (#{k | y k < x i} : ℝ)) +
        (((#{j | x j = x i} : ℝ) + (#{k | y k = x i} : ℝ)) + 1) / 2 := by
    intro i
    unfold midrank
    rw [card_filter_sum_type, card_filter_sum_type]
    rfl
  simp_rw [hi]
  simp only [natCast_card_filter, Fintype.sum_prod_type]
  simp only [add_div, Finset.sum_add_distrib, ← Finset.sum_div, ← Finset.mul_sum, Finset.sum_const,
    Finset.card_univ, Fintype.card_fin, nsmul_eq_mul] at hw ⊢
  linear_combination hw

lemma powersetCard_range_split (n m : ℕ) (f : Finset ℕ → ℝ) :
    ∑ S ∈ (range (n + 1 + (m + 1))).powersetCard (n + 1), f S =
      ∑ S ∈ (range (n + 1 + m)).powersetCard (n + 1), f S +
        ∑ S ∈ (range (n + (m + 1))).powersetCard n, f (insert (n + m + 1) S) := by
  have e1 : n + 1 + (m + 1) = (n + m + 1) + 1 := by omega
  have e2 : n + 1 + m = n + m + 1 := by omega
  have e3 : n + (m + 1) = n + m + 1 := by omega
  rw [e1, e2, e3, range_add_one, powersetCard_succ_insert notMem_range_self]
  rw [sum_union, sum_image]
  · intro A hA B hB hAB
    simp only [mem_coe, mem_powersetCard] at hA hB
    have hA' : n + m + 1 ∉ A := fun h => notMem_range_self (hA.1 h)
    have hB' : n + m + 1 ∉ B := fun h => notMem_range_self (hB.1 h)
    rw [← erase_insert hA', ← erase_insert hB']
    exact congrArg (fun s => Finset.erase s (n + m + 1)) hAB
  · rw [disjoint_left]
    intro S hS hS'
    rw [mem_powersetCard] at hS
    obtain ⟨A, -, rfl⟩ := mem_image.mp hS'
    exact notMem_range_self (hS.1 (mem_insert_self _ _))
#print axioms powersetCard_range_split

lemma sum_range_add_one_real (k : ℕ) :
    ∑ i ∈ range k, ((i : ℝ) + 1) = (k : ℝ) * (k + 1) / 2 := by
  induction k with
  | zero => simp
  | succ k ih => rw [sum_range_succ, ih]; push_cast; ring
#print axioms sum_range_add_one_real

lemma rank_sum_moments (n m : ℕ) :
    (∑ S ∈ (range (n + m)).powersetCard n, ∑ i ∈ S, ((i : ℝ) + 1)) =
        ((n + m).choose n : ℝ) * ((n : ℝ) * (n + m + 1) / 2) ∧
      (∑ S ∈ (range (n + m)).powersetCard n, (∑ i ∈ S, ((i : ℝ) + 1)) ^ 2) =
        ((n + m).choose n : ℝ) *
          ((n : ℝ) * m * (n + m + 1) / 12 + ((n : ℝ) * (n + m + 1) / 2) ^ 2) := by
  induction n generalizing m with
  | zero => simp
  | succ n ihn =>
    induction m with
    | zero =>
      have h : (range (n + 1 + 0)).powersetCard (n + 1) = {range (n + 1)} := by
        have := powersetCard_self (range (n + 1))
        rwa [card_range] at this
      rw [h, sum_singleton, sum_singleton, sum_range_add_one_real]
      simp
    | succ m ihm =>
      obtain ⟨a1, a2⟩ := ihm
      obtain ⟨b1, b2⟩ := ihn (m + 1)
      have hins : ∀ S ∈ (range (n + (m + 1))).powersetCard n,
          ∑ i ∈ insert (n + m + 1) S, ((i : ℝ) + 1) =
            ∑ i ∈ S, ((i : ℝ) + 1) + ((n : ℝ) + m + 2) := by
        intro S hS
        rw [mem_powersetCard] at hS
        have : n + m + 1 ∉ S := fun h => by
          have := mem_range.mp (hS.1 h)
          omega
        rw [sum_insert this]
        push_cast
        ring
      have hcard : ((range (n + (m + 1))).powersetCard n).card = (n + (m + 1)).choose n := by
        rw [card_powersetCard, card_range]
      have pascal : (n + 1 + (m + 1)).choose (n + 1) =
          (n + (m + 1)).choose n + (n + 1 + m).choose (n + 1) := by
        have e1 : n + 1 + (m + 1) = (n + m + 1) + 1 := by omega
        have e2 : n + 1 + m = n + m + 1 := by omega
        have e3 : n + (m + 1) = n + m + 1 := by omega
        rw [e1, e2, e3, Nat.choose_succ_succ]
      have ratio : (n + 1 + m).choose (n + 1) * (n + 1) = (n + (m + 1)).choose n * (m + 1) := by
        have e2 : n + 1 + m = n + m + 1 := by omega
        have e3 : n + (m + 1) = n + m + 1 := by omega
        rw [e2, e3, Nat.choose_succ_right_eq]
        congr 1
        omega
      have ratioR : ((n + 1 + m).choose (n + 1) : ℝ) =
          ((n + (m + 1)).choose n : ℝ) * (m + 1) / (n + 1) := by
        rw [eq_div_iff (by positivity)]
        exact_mod_cast ratio
      constructor
      · rw [powersetCard_range_split, sum_congr rfl hins, sum_add_distrib, sum_const, hcard,
          nsmul_eq_mul, a1, b1, pascal]
        push_cast
        rw [ratioR]
        field_simp
        ring
      · have hins2 : ∀ S ∈ (range (n + (m + 1))).powersetCard n,
            (∑ i ∈ insert (n + m + 1) S, ((i : ℝ) + 1)) ^ 2 =
              (∑ i ∈ S, ((i : ℝ) + 1)) ^ 2 + (2 * ((n : ℝ) + m + 2)) * ∑ i ∈ S, ((i : ℝ) + 1)
                + ((n : ℝ) + m + 2) ^ 2 := by
          intro S hS
          rw [hins S hS]
          ring
        rw [powersetCard_range_split, sum_congr rfl hins2, sum_add_distrib, sum_add_distrib,
          ← mul_sum, sum_const, hcard, nsmul_eq_mul, a2, b1, b2, pascal]
        push_cast
        rw [ratioR]
        field_simp
        ring

#print axioms rank_sum_moments

/-- The centre and spread of U, without listing anything (Step 3). If the groups do not
differ, A's ranks are one of the C(N, n) equally likely sets of `n` places among the ranks
1 to N = n + m. Taken over all those rank sets, U = R_A − n(n+1)/2 averages nm/2 and has
variance nm(N + 1)/12: the sum of U over the sets is C(N, n) · nm/2, and the sum of its
squared distance from nm/2 is C(N, n) · nm(N + 1)/12. -/
theorem mann_whitney_null_mean_and_variance (n m : ℕ) :
    let U : Finset ℕ → ℝ := fun S => (∑ i ∈ S, ((i : ℝ) + 1)) - (n : ℝ) * (n + 1) / 2
    (∑ S ∈ (range (n + m)).powersetCard n, U S) =
        ((n + m).choose n : ℝ) * ((n : ℝ) * m / 2) ∧
      (∑ S ∈ (range (n + m)).powersetCard n, (U S - (n : ℝ) * m / 2) ^ 2) =
        ((n + m).choose n : ℝ) * ((n : ℝ) * m * ((n : ℝ) + m + 1) / 12) := by
  intro U
  obtain ⟨h1, h2⟩ := rank_sum_moments n m
  have hcard : ((range (n + m)).powersetCard n).card = (n + m).choose n := by
    rw [card_powersetCard, card_range]
  have hU : ∀ S, (U S - (n : ℝ) * m / 2) ^ 2 =
      (∑ i ∈ S, ((i : ℝ) + 1)) ^ 2 - 2 * ((n : ℝ) * (n + m + 1) / 2) * (∑ i ∈ S, ((i : ℝ) + 1))
        + ((n : ℝ) * (n + m + 1) / 2) ^ 2 := by
    intro S
    simp only [U]
    ring
  constructor
  · simp only [U]
    rw [sum_sub_distrib, sum_const, hcard, nsmul_eq_mul, h1]
    ring
  · simp_rw [hU]
    rw [sum_add_distrib, sum_sub_distrib, ← mul_sum, sum_const, hcard, nsmul_eq_mul, h1, h2]
    ring

/-- The efficiency against the t-test on bell-shaped data (Step 6). For the normal shape
f with centre μ and variance σ² > 0, the efficiency e = 12σ²(∫ f(x)² dx)² is exactly 3/π,
about 0.955. -/
theorem normal_efficiency_three_over_pi (μ : ℝ) (v : NNReal) (hv : v ≠ 0) :
    12 * (v : ℝ) * (∫ x, gaussianPDFReal μ v x ^ 2) ^ 2 = 3 / π := by
  have hv' : (0:ℝ) < v := NNReal.coe_pos.mpr (pos_iff_ne_zero.mpr hv)
  have hsq : ∀ x, gaussianPDFReal μ v x ^ 2 =
      (2 * π * v)⁻¹ * rexp (-(1 / (v:ℝ)) * (x - μ) ^ 2) := by
    intro x
    rw [gaussianPDFReal, mul_pow, inv_pow, sq_sqrt (by positivity), ← Real.exp_nat_mul]
    congr 2
    field_simp
    ring
  simp_rw [hsq]
  rw [integral_const_mul,
    integral_sub_right_eq_self (μ := volume) (fun a ↦ rexp (-(1 / (v:ℝ)) * a ^ 2)) μ,
    integral_gaussian]
  rw [mul_pow, inv_pow, sq_sqrt (by positivity)]
  field_simp
  ring

/-! The card's worked numbers. Ranks are whole numbers; in the signed-rank example each
midrank is doubled (3.5 becomes 7) so every number is a whole number. -/

-- Shop A's ranks 1, 2, 3, 5, 6, 8, 10, 13 add to 48; all 16 add to 136, so B's add to 88;
-- U = 48 − (1 + 2 + … + 8) = 48 − 36 = 12.
example : ∑ i ∈ ({1, 2, 3, 5, 6, 8, 10, 13} : Finset ℕ), i = 48 ∧
    ∑ i ∈ range 16, (i + 1) = 136 ∧ 136 - 48 = 88 ∧
    ∑ i ∈ range 8, (i + 1) = 36 ∧ 48 - 36 = 12 := by decide

-- Same U by pairs: of the 64 A-against-B pairs of ranks, A's rank is larger in 12.
example : (({1, 2, 3, 5, 6, 8, 10, 13} : Finset ℕ) ×ˢ
    ((Icc 1 16) \ {1, 2, 3, 5, 6, 8, 10, 13})).card = 64 ∧
    ((({1, 2, 3, 5, 6, 8, 10, 13} : Finset ℕ) ×ˢ
      ((Icc 1 16) \ {1, 2, 3, 5, 6, 8, 10, 13})).filter (fun p => p.2 < p.1)).card = 12 := by
  decide

-- C(16, 8) = 12,870 equally likely rank sets; U's centre 8 · 8 / 2 = 32 and variance
-- 8 · 8 · 17 / 12 = 272/3 (90.667).
example : Nat.choose 16 8 = 12870 ∧ (8 * 8 / 2 : ℚ) = 32 ∧ (8 * 8 * 17 / 12 : ℚ) = 272 / 3 := by
  refine ⟨by decide, by norm_num, by norm_num⟩

-- The exact count: 244 of the 12,870 rank sets have rank sum at most 48, that is U ≤ 12,
-- and the sets are symmetric about 32, so 244 more have U ≥ 52.
example : (((range 16).powersetCard 8).filter (fun S => ∑ i ∈ S, (i + 1) ≤ 48)).card = 244 ∧
    (((range 16).powersetCard 8).filter (fun S => 88 ≤ ∑ i ∈ S, (i + 1))).card = 244 := by
  decide +kernel

-- Two-sided exact p-value 2 × 244 / 12,870 = 488/12,870.
example : (2 * 244 / 12870 : ℚ) = 244 / 6435 := by norm_num

-- Signed-rank test: doubled midranks of the drops' sizes are 2, 7, 4, 10, 7, 12, 16, 14.
-- Regular 1 got slower: W⁻ = 1 (doubled, 2) and W⁺ = 35 (doubled, 70). Of the 2⁸ = 256
-- sign patterns, exactly 2 have W⁻ ≤ 1.
example : let r : Fin 8 → ℕ := ![2, 7, 4, 10, 7, 12, 16, 14]
    r 0 = 2 ∧ ∑ i ∈ ({1, 2, 3, 4, 5, 6, 7} : Finset (Fin 8)), r i = 70 ∧
      (univ : Finset (Finset (Fin 8))).card = 256 ∧
      ((univ : Finset (Finset (Fin 8))).filter (fun T => ∑ i ∈ T, r i ≤ 2)).card = 2 := by
  decide +kernel

-- Signed-rank centre 8 · 9 / 4 = 18, variance 8 · 9 · 17 / 24 = 51, and 51 − (2³ − 2)/48
-- = 50.875 with the tie; exact p-value 2 × 2 / 256 = 1/64.
example : (8 * 9 / 4 : ℚ) = 18 ∧ (8 * 9 * 17 / 24 : ℚ) = 51 ∧
    (51 - (2 ^ 3 - 2) / 48 : ℚ) = 407 / 8 ∧ (2 * 2 / 256 : ℚ) = 1 / 64 := by norm_num

#print axioms rank_sum_minus_constant_counts_pairs
#print axioms mann_whitney_null_mean_and_variance
#print axioms normal_efficiency_three_over_pi
