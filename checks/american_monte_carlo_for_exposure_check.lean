-- American Monte Carlo for exposure: when the discounted payoff Y averages to the value v(S) given the state S, the noise Y - v(S) is orthogonal to every function of the state, so the least-squares fit of Y over any family of functions of the state is the least-squares fit of the value itself, and a sample fit with a constant term keeps the sample average.
import Mathlib.MeasureTheory.Function.ConditionalExpectation.Real
import Mathlib.MeasureTheory.Function.ConditionalExpectation.PullOut
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.Algebra.BigOperators.Fin

open MeasureTheory ProbabilityTheory

lemma amc_noise_orthogonal {Ω : Type*} {m₀ : MeasurableSpace Ω}
    {μ : Measure Ω} [IsProbabilityMeasure μ] {m : MeasurableSpace Ω} (hm : m ≤ m₀)
    {Y F : Ω → ℝ} (hY : MemLp Y 2 μ) (hF : StronglyMeasurable[m] F) (hF2 : MemLp F 2 μ) :
    ∫ ω, (Y ω - μ[Y | m] ω) * F ω ∂μ = 0 := by
  have hc : MemLp (μ[Y | m]) 2 μ := hY.condExp (by norm_num)
  have i1 : Integrable (F * Y) μ := hF2.integrable_mul hY
  have i2 : Integrable (F * μ[Y | m]) μ := hF2.integrable_mul hc
  have key : ∫ ω, (F * Y) ω ∂μ = ∫ ω, (F * μ[Y | m]) ω ∂μ := by
    rw [← integral_condExp hm (f := F * Y)]
    exact integral_congr_ae
      (condExp_mul_of_stronglyMeasurable_left hF i1 (hY.integrable (by norm_num)))
  have e : (fun ω => (Y ω - μ[Y | m] ω) * F ω) = fun ω => (F * Y) ω - (F * μ[Y | m]) ω := by
    funext ω; simp only [Pi.mul_apply]; ring
  rw [e, integral_sub i1 i2, key, sub_self]

#print axioms amc_noise_orthogonal

lemma amc_miss_splits {Ω : Type*} [MeasurableSpace Ω]
    {μ : Measure Ω} [IsProbabilityMeasure μ] {S Y : Ω → ℝ} {v g : ℝ → ℝ}
    (hS : Measurable S) (hY : MemLp Y 2 μ)
    (hV : (fun ω => v (S ω)) =ᵐ[μ] μ[Y | MeasurableSpace.comap S inferInstance])
    (hg : Measurable g) (hgS : MemLp (fun ω => g (S ω)) 2 μ) :
    ∫ ω, (Y ω - v (S ω)) * g (S ω) ∂μ = 0 ∧
    ∫ ω, (Y ω - g (S ω)) ^ 2 ∂μ =
      ∫ ω, (Y ω - v (S ω)) ^ 2 ∂μ + ∫ ω, (v (S ω) - g (S ω)) ^ 2 ∂μ := by
  have hm : MeasurableSpace.comap S inferInstance ≤ ‹MeasurableSpace Ω› := hS.comap_le
  have hgm : StronglyMeasurable[MeasurableSpace.comap S inferInstance] (fun ω => g (S ω)) :=
    (hg.comp (comap_measurable S)).stronglyMeasurable
  have hc2 : MemLp (μ[Y | MeasurableSpace.comap S inferInstance]) 2 μ :=
    hY.condExp (by norm_num)
  have hvS : MemLp (fun ω => v (S ω)) 2 μ := hc2.ae_eq hV.symm
  have hYv : MemLp (fun ω => Y ω - v (S ω)) 2 μ := hY.sub hvS
  have hvg : MemLp (fun ω => v (S ω) - g (S ω)) 2 μ := hvS.sub hgS
  constructor
  · have e : ∫ ω, (Y ω - v (S ω)) * g (S ω) ∂μ =
        ∫ ω, (Y ω - μ[Y | MeasurableSpace.comap S inferInstance] ω) * g (S ω) ∂μ :=
      integral_congr_ae (hV.mono fun ω hω => by simp only [hω])
    rw [e]
    exact amc_noise_orthogonal hm hY hgm hgS
  · have hF : StronglyMeasurable[MeasurableSpace.comap S inferInstance]
        (fun ω => μ[Y | MeasurableSpace.comap S inferInstance] ω - g (S ω)) :=
      stronglyMeasurable_condExp.sub hgm
    have hF2 : MemLp (fun ω => μ[Y | MeasurableSpace.comap S inferInstance] ω - g (S ω)) 2 μ :=
      hc2.sub hgS
    have h0 : ∫ ω, (Y ω - v (S ω)) * (v (S ω) - g (S ω)) ∂μ = 0 := by
      have e : ∫ ω, (Y ω - v (S ω)) * (v (S ω) - g (S ω)) ∂μ =
          ∫ ω, (Y ω - μ[Y | MeasurableSpace.comap S inferInstance] ω) *
            (μ[Y | MeasurableSpace.comap S inferInstance] ω - g (S ω)) ∂μ :=
        integral_congr_ae (hV.mono fun ω hω => by simp only [hω])
      rw [e]
      exact amc_noise_orthogonal hm hY hF hF2
    have i1 : Integrable (fun ω => (Y ω - v (S ω)) ^ 2) μ := hYv.integrable_sq
    have i2 : Integrable (fun ω => (v (S ω) - g (S ω)) ^ 2) μ := hvg.integrable_sq
    have i3 : Integrable (fun ω => (Y ω - v (S ω)) * (v (S ω) - g (S ω))) μ :=
      hYv.integrable_mul hvg
    have hpt : (fun ω => (Y ω - g (S ω)) ^ 2) = fun ω =>
        ((Y ω - v (S ω)) ^ 2 + (v (S ω) - g (S ω)) ^ 2) +
          2 * ((Y ω - v (S ω)) * (v (S ω) - g (S ω))) := by
      funext ω; ring
    have e1 : ∫ ω, (((Y ω - v (S ω)) ^ 2 + (v (S ω) - g (S ω)) ^ 2) +
          2 * ((Y ω - v (S ω)) * (v (S ω) - g (S ω)))) ∂μ =
        ∫ ω, ((Y ω - v (S ω)) ^ 2 + (v (S ω) - g (S ω)) ^ 2) ∂μ +
          ∫ ω, 2 * ((Y ω - v (S ω)) * (v (S ω) - g (S ω))) ∂μ :=
      integral_add (i1.add i2) (i3.const_mul 2)
    have e2 : ∫ ω, ((Y ω - v (S ω)) ^ 2 + (v (S ω) - g (S ω)) ^ 2) ∂μ =
        ∫ ω, (Y ω - v (S ω)) ^ 2 ∂μ + ∫ ω, (v (S ω) - g (S ω)) ^ 2 ∂μ :=
      integral_add i1 i2
    rw [hpt, e1, e2, integral_const_mul, h0, mul_zero, add_zero]

#print axioms amc_miss_splits

/-- The card's main claim (Why it works, Step 2 and the detailed proof). In the pricing world,
let `Y` be the discounted payoff with finite mean square and `S` the simulated state on the date.
If the value is a function `v` of the state with `E[Y | S] = v(S)`, then over any family of
functions `g` of the state (each with `g(S)` of finite mean square, for instance all parabolas
`b₀ + b₁ x + b₂ x²`), a curve `g₀` makes the mean squared miss to the payoff `Y` smallest exactly
when it makes the mean squared miss to the value `v(S)` smallest: the least-squares fit of the
payoff aims at the closest such curve to the true value, and the payoff's noise does not bias it. -/
theorem least_squares_fit_of_payoff_is_fit_of_value {Ω : Type*} [MeasurableSpace Ω]
    {μ : Measure Ω} [IsProbabilityMeasure μ] {S Y : Ω → ℝ} {v : ℝ → ℝ}
    (hS : Measurable S) (hY : MemLp Y 2 μ)
    (hV : (fun ω => v (S ω)) =ᵐ[μ] μ[Y | MeasurableSpace.comap S inferInstance])
    (𝓕 : Set (ℝ → ℝ)) (h𝓕 : ∀ g ∈ 𝓕, Measurable g ∧ MemLp (fun ω => g (S ω)) 2 μ)
    {g₀ : ℝ → ℝ} (hg₀ : g₀ ∈ 𝓕) :
    (∀ g ∈ 𝓕, ∫ ω, (Y ω - g₀ (S ω)) ^ 2 ∂μ ≤ ∫ ω, (Y ω - g (S ω)) ^ 2 ∂μ) ↔
      (∀ g ∈ 𝓕, ∫ ω, (v (S ω) - g₀ (S ω)) ^ 2 ∂μ ≤ ∫ ω, (v (S ω) - g (S ω)) ^ 2 ∂μ) := by
  have key : ∀ g ∈ 𝓕, ∫ ω, (Y ω - g (S ω)) ^ 2 ∂μ =
      ∫ ω, (Y ω - v (S ω)) ^ 2 ∂μ + ∫ ω, (v (S ω) - g (S ω)) ^ 2 ∂μ :=
    fun g hg => (amc_miss_splits hS hY hV (h𝓕 g hg).1 (h𝓕 g hg).2).2
  constructor
  · intro h g hg
    have := h g hg
    rw [key g hg, key g₀ hg₀] at this
    linarith
  · intro h g hg
    have := h g hg
    rw [key g hg, key g₀ hg₀]
    linarith

/-- The two lines of the detailed proof. With `E[Y | S] = v(S)`, the miss `D = Y - v(S)` times
any function `g(S)` of the state with finite mean square averages to zero, and the mean squared
miss of `g(S)` to the payoff splits as the payoff's own noise `E[D²]` plus the mean squared miss
of `g(S)` to the value. -/
theorem payoff_noise_orthogonal_and_miss_splits {Ω : Type*} [MeasurableSpace Ω]
    {μ : Measure Ω} [IsProbabilityMeasure μ] {S Y : Ω → ℝ} {v g : ℝ → ℝ}
    (hS : Measurable S) (hY : MemLp Y 2 μ)
    (hV : (fun ω => v (S ω)) =ᵐ[μ] μ[Y | MeasurableSpace.comap S inferInstance])
    (hg : Measurable g) (hgS : MemLp (fun ω => g (S ω)) 2 μ) :
    ∫ ω, (Y ω - v (S ω)) * g (S ω) ∂μ = 0 ∧
    ∫ ω, (Y ω - g (S ω)) ^ 2 ∂μ =
      ∫ ω, (Y ω - v (S ω)) ^ 2 ∂μ + ∫ ω, (v (S ω) - g (S ω)) ^ 2 ∂μ := by
  exact amc_miss_splits hS hY hV hg hgS

/-- Step 3: a least-squares fit with a constant term keeps the average. On `n` fitting paths with
states `x i` and discounted payoffs `y i`, if the weights `b` of the curve
`h(x) = b₀ + b₁ x + ... + b_k x^k` make the summed squared miss smallest among all such curves,
then the fitted values sum to the payoffs' sum (the residuals sum to zero). -/
theorem least_squares_fit_with_constant_keeps_the_mean {n k : ℕ} (x y : Fin n → ℝ)
    (b : Fin (k + 1) → ℝ)
    (hb : ∀ a : Fin (k + 1) → ℝ,
      ∑ i, (y i - ∑ j, b j * x i ^ (j : ℕ)) ^ 2 ≤ ∑ i, (y i - ∑ j, a j * x i ^ (j : ℕ)) ^ 2) :
    ∑ i, (∑ j, b j * x i ^ (j : ℕ)) = ∑ i, y i := by
  set r : Fin n → ℝ := fun i => y i - ∑ j, b j * x i ^ (j : ℕ) with hr
  set R : ℝ := ∑ i, r i with hR
  have shift : ∀ t : ℝ, ∀ i, (y i - ∑ j, (Fin.cons (b 0 + t) (Fin.tail b) : Fin (k + 1) → ℝ) j
      * x i ^ (j : ℕ)) = r i - t := by
    intro t i
    simp only [hr, Fin.sum_univ_succ, Fin.cons_zero, Fin.cons_succ, Fin.tail, Fin.val_zero,
      pow_zero, mul_one]
    ring
  have hineq : ∀ t : ℝ, 0 ≤ (n : ℝ) * t ^ 2 - 2 * t * R := by
    intro t
    have h := hb (Fin.cons (b 0 + t) (Fin.tail b))
    simp only [shift] at h
    have expand : ∑ i, (r i - t) ^ 2 = ∑ i, r i ^ 2 + ((n : ℝ) * t ^ 2 - 2 * t * R) := by
      have hn : (n : ℝ) * t ^ 2 = ∑ _i : Fin n, t ^ 2 := by simp
      rw [hR, Finset.mul_sum, hn, ← Finset.sum_sub_distrib, ← Finset.sum_add_distrib]
      apply Finset.sum_congr rfl; intro i _; ring
    have : ∑ i, r i ^ 2 ≤ ∑ i, (r i - t) ^ 2 := h
    linarith
  have hR0 : R = 0 := by
    rcases Nat.eq_zero_or_pos n with hn | hn
    · subst hn; simp [hR]
    · have hnpos : (0 : ℝ) < n := by exact_mod_cast hn
      have h := hineq (R / n)
      have : (n : ℝ) * (R / n) ^ 2 - 2 * (R / n) * R = -(R ^ 2 / n) := by
        field_simp; ring
      rw [this] at h
      have : R ^ 2 / n ≤ 0 := by linarith
      have h2 : R ^ 2 ≤ 0 := by
        have := (div_le_iff₀ hnpos).1 this; linarith
      nlinarith [sq_nonneg R]
  have : ∑ i, y i - ∑ i, (∑ j, b j * x i ^ (j : ℕ)) = 0 := by
    rw [← Finset.sum_sub_distrib]; exact hR0
  linarith

-- the nested simulation the method avoids: 50,000 paths, 11 dates to fit, 1,000 inner paths each
example : 50000 * 11 * 1000 = 550000000 := by norm_num

-- PFE is the ceil(0.95 n)-th smallest of n = 50,000 sorted values: the 47,500th
example : (95 * 50000 + 99) / 100 = 47500 := by norm_num

#print axioms least_squares_fit_of_payoff_is_fit_of_value
#print axioms payoff_noise_orthogonal_and_miss_splits
#print axioms least_squares_fit_with_constant_keeps_the_mean
