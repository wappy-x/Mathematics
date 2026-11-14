-- Liquidity: in Roll's bid-ask bounce model consecutive price changes have covariance minus the squared half-spread, a book walk of n levels costs h + (n-1)/2 cents a share on average, and a book refilling at rate κ is half refilled after ln 2 / κ minutes.
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Independence.Integration
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Algebra.BigOperators.Intervals

open MeasureTheory ProbabilityTheory Finset

lemma roll_aux_sign_integrable {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (s : Ω → ℝ) (hs : Measurable s)
    (hsign : ∀ ω, s ω = 1 ∨ s ω = -1) : Integrable s P := by
  refine Integrable.of_bound hs.aestronglyMeasurable 1 (Filter.Eventually.of_forall fun ω => ?_)
  rcases hsign ω with h | h <;> simp [h]

lemma roll_aux_sign_mean {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (s : Ω → ℝ) (hs : Measurable s)
    (hsign : ∀ ω, s ω = 1 ∨ s ω = -1) (hhalf : P (s ⁻¹' {1}) = 1 / 2) :
    ∫ ω, s ω ∂P = 0 := by
  have hS : MeasurableSet (s ⁻¹' {1}) := hs (measurableSet_singleton 1)
  have hpt : ∀ ω, s ω = (s ⁻¹' {1}).indicator (fun _ => (2 : ℝ)) ω - 1 := by
    intro ω
    rcases hsign ω with h | h
    · rw [Set.indicator_of_mem (by simp [h])]; rw [h]; norm_num
    · rw [Set.indicator_of_notMem (by simp [h]; norm_num)]; rw [h]; norm_num
  simp_rw [hpt]
  rw [integral_sub ((integrable_const (2 : ℝ)).indicator hS) (integrable_const 1),
    integral_indicator_const _ hS]
  simp [measureReal_def, hhalf]

lemma roll_aux_pair {Ω ι : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    (F : ι → Ω → ℝ) (hindep : iIndepFun F P) (hint : ∀ i, Integrable (F i) P)
    (hmean : ∀ i, ∫ ω, F i ω ∂P = 0) {i j : ι} (hij : i ≠ j) :
    Integrable (fun ω => F i ω * F j ω) P ∧ ∫ ω, F i ω * F j ω ∂P = 0 := by
  have hI := hindep.indepFun hij
  refine ⟨hI.integrable_mul (hint i) (hint j), ?_⟩
  rw [hI.integral_fun_mul_eq_mul_integral (hint i).1 (hint j).1, hmean i, zero_mul]

#print axioms roll_aux_sign_integrable
#print axioms roll_aux_sign_mean
#print axioms roll_aux_pair

/-- Roll's spread estimate. The fair price is a random walk `m (k+1) = m k + u (k+1)` with
independent steps of average zero; each trade is a buy or a sale (`s k = 1` or `-1`) with equal
chance, independent of the steps and of the other signs; the trade price is `p k = m k + h * s k`.
Then each price change has covariance `-h^2` with the one before it, so for a half-spread
`h ≥ 0` the spread is `2h = 2 √(-Cov)`. -/
theorem roll_covariance_eq_neg_sq
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (u s m p : ℕ → Ω → ℝ) (h : ℝ)
    (hindep : iIndepFun (Sum.elim u s) P)
    (hu_int : ∀ k, Integrable (u k) P) (hu_mean : ∀ k, ∫ ω, u k ω ∂P = 0)
    (hs_meas : ∀ k, Measurable (s k))
    (hs_sign : ∀ k ω, s k ω = 1 ∨ s k ω = -1)
    (hs_half : ∀ k, P (s k ⁻¹' {1}) = 1 / 2)
    (hm : ∀ k ω, m (k + 1) ω = m k ω + u (k + 1) ω)
    (hp : ∀ k ω, p k ω = m k ω + h * s k ω) (k : ℕ) :
    cov[fun ω => p (k + 2) ω - p (k + 1) ω, fun ω => p (k + 1) ω - p k ω; P] = -h ^ 2 ∧
      (0 ≤ h → 2 * h =
        2 * Real.sqrt (-cov[fun ω => p (k + 2) ω - p (k + 1) ω, fun ω => p (k + 1) ω - p k ω; P])) := by
  have hs_int : ∀ k, Integrable (s k) P := fun k =>
    roll_aux_sign_integrable (s k) (hs_meas k) (hs_sign k)
  have hs_mean : ∀ k, ∫ ω, s k ω ∂P = 0 := fun k =>
    roll_aux_sign_mean (s k) (hs_meas k) (hs_sign k) (hs_half k)
  have hF_int : ∀ i, Integrable (Sum.elim u s i) P := by
    rintro (i | i)
    · exact hu_int i
    · exact hs_int i
  have hF_mean : ∀ i, ∫ ω, Sum.elim u s i ω ∂P = 0 := by
    rintro (i | i)
    · exact hu_mean i
    · exact hs_mean i
  have key := fun i j (hij : i ≠ j) => roll_aux_pair (Sum.elim u s) hindep hF_int hF_mean hij
  obtain ⟨i1, e1⟩ := key (Sum.inl (k + 2)) (Sum.inl (k + 1)) (by simp)
  obtain ⟨i2, e2⟩ := key (Sum.inl (k + 2)) (Sum.inr (k + 1)) (by simp)
  obtain ⟨i3, e3⟩ := key (Sum.inl (k + 2)) (Sum.inr k) (by simp)
  obtain ⟨i4, e4⟩ := key (Sum.inr (k + 2)) (Sum.inl (k + 1)) (by simp)
  obtain ⟨i5, e5⟩ := key (Sum.inr (k + 2)) (Sum.inr (k + 1)) (by simp)
  obtain ⟨i6, e6⟩ := key (Sum.inr (k + 2)) (Sum.inr k) (by simp)
  obtain ⟨i7, e7⟩ := key (Sum.inr (k + 1)) (Sum.inl (k + 1)) (by simp)
  obtain ⟨i8, e8⟩ := key (Sum.inr (k + 1)) (Sum.inr k) (by simp)
  simp only [Sum.elim_inl, Sum.elim_inr] at i1 e1 i2 e2 i3 e3 i4 e4 i5 e5 i6 e6 i7 e7 i8 e8
  have hX : (fun ω => p (k + 2) ω - p (k + 1) ω) =
      fun ω => u (k + 2) ω + h * s (k + 2) ω - h * s (k + 1) ω := by
    funext ω; rw [hp, hp, hm]; ring
  have hY : (fun ω => p (k + 1) ω - p k ω) =
      fun ω => u (k + 1) ω + h * s (k + 1) ω - h * s k ω := by
    funext ω; rw [hp, hp, hm]; ring
  have hXm : ∫ ω, (u (k + 2) ω + h * s (k + 2) ω - h * s (k + 1) ω) ∂P = 0 := by
    rw [integral_sub (by fun_prop) (by fun_prop), integral_add (by fun_prop) (by fun_prop),
      integral_const_mul, integral_const_mul, hu_mean, hs_mean, hs_mean]
    ring
  have hYm : ∫ ω, (u (k + 1) ω + h * s (k + 1) ω - h * s k ω) ∂P = 0 := by
    rw [integral_sub (by fun_prop) (by fun_prop), integral_add (by fun_prop) (by fun_prop),
      integral_const_mul, integral_const_mul, hu_mean, hs_mean, hs_mean]
    ring
  have hpt : ∀ ω, (u (k + 2) ω + h * s (k + 2) ω - h * s (k + 1) ω - 0) *
      (u (k + 1) ω + h * s (k + 1) ω - h * s k ω - 0) =
      ((((((((u (k + 2) ω * u (k + 1) ω + h * (u (k + 2) ω * s (k + 1) ω))
        - h * (u (k + 2) ω * s k ω)) + h * (s (k + 2) ω * u (k + 1) ω))
        + h ^ 2 * (s (k + 2) ω * s (k + 1) ω)) - h ^ 2 * (s (k + 2) ω * s k ω))
        - h * (s (k + 1) ω * u (k + 1) ω)) + h ^ 2 * (s (k + 1) ω * s k ω)) - h ^ 2) := by
    intro ω
    have hsq : s (k + 1) ω * s (k + 1) ω = 1 := by
      rcases hs_sign (k + 1) ω with e | e <;> rw [e] <;> norm_num
    linear_combination (-h ^ 2) * hsq
  have hcov : cov[fun ω => p (k + 2) ω - p (k + 1) ω, fun ω => p (k + 1) ω - p k ω; P]
      = -h ^ 2 := by
    rw [hX, hY, covariance, hXm, hYm]
    simp_rw [hpt]
    rw [integral_sub (by fun_prop) (by fun_prop), integral_add (by fun_prop) (by fun_prop),
      integral_sub (by fun_prop) (by fun_prop), integral_sub (by fun_prop) (by fun_prop),
      integral_add (by fun_prop) (by fun_prop), integral_add (by fun_prop) (by fun_prop),
      integral_sub (by fun_prop) (by fun_prop), integral_add (by fun_prop) (by fun_prop),
      integral_const_mul, integral_const_mul, integral_const_mul, integral_const_mul,
      integral_const_mul, integral_const_mul, integral_const_mul,
      e1, e2, e3, e4, e5, e6, e7, e8, integral_const]
    simp
  refine ⟨hcov, fun hh => ?_⟩
  rw [hcov, neg_neg, Real.sqrt_sq hh]

/-- Walking the book. Selling `n` full levels of `δ` shares, level `k` sitting `h + k` cents below
the midpoint, collects `δ (n h + n (n-1)/2)` cents below the midpoint in total; when at least one
share is sold the average is `h + (n-1)/2` cents a share. -/
theorem book_walk_average_cost (δ n : ℕ) (h : ℝ) :
    (∑ k ∈ range n, (δ : ℝ) * (h + k)) = δ * (n * h + n * (n - 1) / 2) ∧
      (0 < n → 0 < δ → (∑ k ∈ range n, (δ : ℝ) * (h + k)) / (n * δ) = h + (n - 1) / 2) := by
  have hsum : ∀ n : ℕ, (∑ k ∈ range n, (δ : ℝ) * (h + k)) = δ * (n * h + n * (n - 1) / 2) := by
    intro n
    induction n with
    | zero => simp
    | succ n ih => rw [sum_range_succ, ih]; push_cast; ring
  refine ⟨hsum n, fun hn hδ => ?_⟩
  rw [hsum n]
  have hn' : (n : ℝ) ≠ 0 := by positivity
  have hδ' : (δ : ℝ) ≠ 0 := by positivity
  field_simp

/-- The half-life of the book. When the missing depth shrinks to `e^{-κ t}` of what was taken
after `t` minutes, with refill rate `κ > 0`, it is halved exactly at `t = ln 2 / κ`. -/
theorem half_life_eq_log_two_div (κ : ℝ) (hκ : 0 < κ) (t : ℝ) :
    Real.exp (-κ * t) = 1 / 2 ↔ t = Real.log 2 / κ := by
  have hκ' : κ ≠ 0 := hκ.ne'
  constructor
  · intro he
    have := congrArg Real.log he
    rw [Real.log_exp, one_div, Real.log_inv] at this
    field_simp
    linarith
  · intro ht
    rw [ht, show -κ * (Real.log 2 / κ) = -Real.log 2 by field_simp, Real.exp_neg,
      Real.exp_log (by norm_num), one_div]

-- Effective spread on each three-trade tape (prices in cents: a 500-share buy at the ask,
-- a 300-share sale at the bid, a 200-share buy at the midpoint), share-weighted, in bp.
-- Acme: 1.6 bp.
example : ((500 : ℚ) * (2 * 1 * (10001 - 10000) / 10000 * 10000)
    + 300 * (2 * (-1) * (9999 - 10000) / 10000 * 10000)
    + 200 * (2 * 1 * (10000 - 10000) / 10000 * 10000)) / 1000 = 8 / 5 := by norm_num
-- Beacon: 8 bp.
example : ((500 : ℚ) * (2 * 1 * (4002 - 4000) / 4000 * 10000)
    + 300 * (2 * (-1) * (3998 - 4000) / 4000 * 10000)
    + 200 * (2 * 1 * (4000 - 4000) / 4000 * 10000)) / 1000 = 8 := by norm_num
-- Cobble: 16 bp.
example : ((500 : ℚ) * (2 * 1 * (1001 - 1000) / 1000 * 10000)
    + 300 * (2 * (-1) * (999 - 1000) / 1000 * 10000)
    + 200 * (2 * 1 * (1000 - 1000) / 1000 * 10000)) / 1000 = 16 := by norm_num

-- Amihud's ratio, bp per $1 million: Acme 1.0, Beacon 4.0, Cobble 10.0.
example : (|(80 : ℚ)| / 100 + |(-150 : ℚ)| / 120 + |(60 : ℚ)| / 100 + |(-100 : ℚ)| / 100
    + |(135 : ℚ)| / 100) / 5 = 1 := by norm_num
example : (|(100 : ℚ)| / 25 + |(-160 : ℚ)| / 20 + |(60 : ℚ)| / 20 + |(-50 : ℚ)| / 25
    + |(45 : ℚ)| / 15) / 5 = 4 := by norm_num
example : (|(120 : ℚ)| / 10 + |(-200 : ℚ)| / 16 + |(70 : ℚ)| / 10 + |(-90 : ℚ)| / 12
    + |(110 : ℚ)| / 10) / 5 = 10 := by norm_num
-- The mistake: signed returns make Beacon read 0.
example : ((100 : ℚ) / 25 + (-160) / 20 + 60 / 20 + (-50) / 25 + 45 / 15) / 5 = 0 := by norm_num

-- A $1 million sale walked through the book, average cost in bp of the midpoint.
-- Acme: 10,000 shares = 5 levels of 2,000, best bid 1 cent below a 10,000-cent midpoint: 3 bp.
example : (∑ k ∈ range 5, (2000 : ℚ) * (1 + k)) / 10000 / 10000 * 10000 = 3 := by
  norm_num [Finset.sum_range_succ]
-- Beacon: 25,000 shares = 10 levels of 2,500, best bid 2 cents below 4,000: 16.25 bp.
example : (∑ k ∈ range 10, (2500 : ℚ) * (2 + k)) / 25000 / 4000 * 10000 = 65 / 4 := by
  norm_num [Finset.sum_range_succ]
-- Cobble: 100,000 shares = 20 levels of 5,000, best bid 1 cent below 1,000: 105 bp.
example : (∑ k ∈ range 20, (5000 : ℚ) * (1 + k)) / 100000 / 1000 * 10000 = 105 := by
  norm_num [Finset.sum_range_succ]
-- The house order: 100,000 Acme shares walk 50 levels and give up 2,550,000 cents = $25,500.
example : (∑ k ∈ range 50, 2000 * (1 + k)) = 2550000 := by decide

#print axioms roll_covariance_eq_neg_sq
#print axioms book_walk_average_cost
#print axioms half_life_eq_log_two_div
