-- Jump diffusions: along a path that drifts and jumps finitely often, a smooth function changes by the slope term between jumps plus its exact before-and-after difference at each jump.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.MeasureTheory.Integral.IntervalIntegral.AbsolutelyContinuousFun
import Mathlib.MeasureTheory.Integral.IntervalIntegral.LebesgueDifferentiationThm
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Asymptotics

open MeasureTheory ProbabilityTheory Filter Topology

/-! Mathlib has no Ito integral against Brownian motion, so the main theorem below is the
card's formula path by path with the wobble switched off (`β = 0`): the path is
`X t = x₀ + ∫₀ᵗ α + (sum of the jumps Δ i at the times τ i ≤ t)`,
as in the card's Detailed proof. The value just before jump `i` is `X (τ i) - Δ i`.
Drift `α` only needs `∫₀ᵀ |α| < ∞`, and `f` has a continuous curvature, as the card asks.
The averaged formulas and the simulation rest on a model and decimals and are not stated. -/

theorem chain_ac (f : ℝ → ℝ) (hf : ContDiff ℝ 1 f) (α : ℝ → ℝ) {a b : ℝ} (hab : a ≤ b)
    (hα : IntervalIntegrable α volume a b) (c : ℝ) (Y : ℝ → ℝ)
    (hY : ∀ s ∈ Set.Icc a b, Y s = c + ∫ u in a..s, α u) :
    IntervalIntegrable (fun s => deriv f (Y s) * α s) volume a b ∧
      f (Y b) = f (Y a) + ∫ s in a..b, deriv f (Y s) * α s := by
  set G : ℝ → ℝ := fun t => c + ∫ u in a..t, α u with hGdef
  have hYG : Set.EqOn Y G (Set.uIcc a b) := by
    intro s hs; rw [Set.uIcc_of_le hab] at hs; exact hY s hs
  have hI : AbsolutelyContinuousOnInterval (fun t => ∫ u in a..t, α u) a b :=
    hα.absolutelyContinuousOnInterval_intervalIntegral Set.left_mem_uIcc
  have hc : AbsolutelyContinuousOnInterval (fun _ : ℝ => c) a b :=
    (LipschitzWith.const c).lipschitzOnWith.absolutelyContinuousOnInterval
  have hGac : AbsolutelyContinuousOnInterval G a b := hc.add hI
  have hGcont : ContinuousOn G (Set.uIcc a b) := hGac.continuousOn
  have hK : IsCompact (G '' Set.uIcc a b) := isCompact_uIcc.image_of_continuousOn hGcont
  obtain ⟨M, hM⟩ := (Metric.isBounded_iff_subset_closedBall (0 : ℝ)).1 hK.isBounded
  obtain ⟨K, hKL⟩ := (hf.contDiffOn (s := Metric.closedBall (0 : ℝ) M)).exists_lipschitzOnWith
    (by decide) (convex_closedBall _ _) (isCompact_closedBall _ _)
  have hFG : AbsolutelyContinuousOnInterval (f ∘ G) a b :=
    hKL.comp_absolutelyContinuousOnInterval (fun x hx => hM ⟨x, hx, rfl⟩) hGac
  have hFTC := hFG.integral_deriv_eq_sub
  have hcd : Continuous (deriv f) := hf.continuous_deriv le_rfl
  have hint : IntervalIntegrable (fun s => deriv f (G s) * α s) volume a b :=
    hα.continuousOn_mul (hcd.comp_continuousOn hGcont)
  have hae : ∫ s in a..b, deriv (f ∘ G) s = ∫ s in a..b, deriv f (G s) * α s := by
    apply intervalIntegral.integral_congr_ae
    filter_upwards [hα.ae_hasDerivAt_integral] with x hx hxI
    have hxI' : x ∈ Set.uIcc a b := Set.uIoc_subset_uIcc hxI
    have hG : HasDerivAt G (α x) x := (hx hxI' a Set.left_mem_uIcc).const_add c
    exact ((hf.differentiable one_ne_zero (G x)).hasDerivAt.comp x hG).deriv
  have hYb := hYG (Set.right_mem_uIcc)
  have hYa := hYG (Set.left_mem_uIcc)
  have hcong : ∫ s in a..b, deriv f (Y s) * α s = ∫ s in a..b, deriv f (G s) * α s :=
    intervalIntegral.integral_congr (fun s hs => by simp only [hYG hs])
  refine ⟨hint.congr ?_, ?_⟩
  · intro s hs; simp only [hYG (Set.uIoc_subset_uIcc hs)]
  · rw [hcong, ← hae, hFTC, hYb, hYa]
    simp [G]

#print axioms chain_ac

theorem jumps_general (f : ℝ → ℝ) (hf : ContDiff ℝ 1 f) (x₀ a : ℝ) (α : ℝ → ℝ) :
    ∀ (n : ℕ) (b : ℝ) (τ : Fin n → ℝ), a ≤ b → IntervalIntegrable α volume a b →
      StrictMono τ → (∀ i, a < τ i) → (∀ i, τ i ≤ b) → ∀ (Δ : Fin n → ℝ) (X : ℝ → ℝ),
      (∀ t, X t = x₀ + (∫ s in a..t, α s) +
        ∑ i ∈ Finset.univ.filter (fun i => τ i ≤ t), Δ i) →
      IntervalIntegrable (fun s => deriv f (X s) * α s) volume a b ∧
      f (X b) = f (X a) + (∫ s in a..b, deriv f (X s) * α s) +
        ∑ i, (f (X (τ i)) - f (X (τ i) - Δ i)) := by
  intro n
  induction n with
  | zero =>
    intro b τ hab hα _ _ _ Δ X hX
    have hY : ∀ s, X s = x₀ + ∫ u in a..s, α u := by intro s; rw [hX]; simp
    obtain ⟨h1, h2⟩ := chain_ac f hf α hab hα x₀ X (fun s _ => hY s)
    exact ⟨h1, by simp [h2]⟩
  | succ n ih =>
    intro b τ hab hα hτ hτa hτb Δ X hX
    set L := τ (Fin.last n) with hLdef
    set τ' : Fin n → ℝ := fun i => τ i.castSucc with hτ'def
    set Δ' : Fin n → ℝ := fun i => Δ i.castSucc with hΔ'def
    set X' : ℝ → ℝ := fun t => x₀ + (∫ s in a..t, α s) +
        ∑ i ∈ Finset.univ.filter (fun i => τ' i ≤ t), Δ' i with hX'def
    have hXX' : ∀ t, X t = X' t + if L ≤ t then Δ (Fin.last n) else 0 := by
      intro t
      rw [hX]
      simp only [X', Finset.sum_filter, Fin.sum_univ_castSucc, τ', Δ', L]
      ring
    have haL : a < L := hτa _
    have hLb : L ≤ b := hτb _
    have hτ'L : ∀ i, τ' i < L := fun i => hτ (Fin.castSucc_lt_last i)
    have hτ'mono : StrictMono τ' := hτ.comp Fin.strictMono_castSucc
    have hαL : IntervalIntegrable α volume a L :=
      hα.mono_set (Set.uIcc_subset_uIcc Set.left_mem_uIcc (by
        rw [Set.uIcc_of_le hab]; exact ⟨haL.le, hLb⟩))
    obtain ⟨hI1, hE1⟩ := ih L τ' haL.le hαL hτ'mono (fun i => hτa _) (fun i => (hτ'L i).le)
      Δ' X' (fun t => rfl)
    have hXτ' : ∀ i, X (τ' i) = X' (τ' i) := by
      intro i; rw [hXX']; simp [not_le.2 (hτ'L i)]
    have hXL : X L = X' L + Δ (Fin.last n) := by rw [hXX']; simp
    have hXa : X a = X' a := by rw [hXX']; simp [not_le.2 haL]
    have hae : ∀ᵐ s ∂volume, s ∈ Set.uIoc a L →
        deriv f (X' s) * α s = deriv f (X s) * α s := by
      have hne : ∀ᵐ s ∂(volume : Measure ℝ), s ≠ L := by
        simp [ae_iff, measure_singleton]
      filter_upwards [hne] with s hs hsI
      rw [Set.uIoc_of_le haL.le] at hsI
      have : s < L := lt_of_le_of_ne hsI.2 hs
      rw [hXX' s]; simp [not_le.2 this]
    have hI1' : IntervalIntegrable (fun s => deriv f (X s) * α s) volume a L :=
      hI1.congr_ae ((ae_restrict_iff' measurableSet_uIoc).2 hae)
    have hint1 : ∫ s in a..L, deriv f (X' s) * α s = ∫ s in a..L, deriv f (X s) * α s :=
      intervalIntegral.integral_congr_ae hae
    have hαLb : IntervalIntegrable α volume L b :=
      hα.mono_set (Set.uIcc_subset_uIcc (by
        rw [Set.uIcc_of_le hab]; exact ⟨haL.le, hLb⟩) Set.right_mem_uIcc)
    have hY : ∀ s ∈ Set.Icc L b, X s = X L + ∫ u in L..s, α u := by
      intro s hs
      have hall : ∀ t, L ≤ t →
          Finset.univ.filter (fun i => τ i ≤ t) = Finset.univ := by
        intro t ht
        apply Finset.filter_true_of_mem
        intro i _
        exact le_trans (hτ.monotone (Fin.le_last i)) ht
      rw [hX s, hX L, hall s hs.1, hall L le_rfl]
      have hαs : IntervalIntegrable α volume a s :=
        hα.mono_set (Set.uIcc_subset_uIcc Set.left_mem_uIcc (by
          rw [Set.uIcc_of_le hab]; exact ⟨haL.le.trans hs.1, hs.2⟩))
      rw [← intervalIntegral.integral_interval_sub_left hαs hαL]
      ring
    obtain ⟨hI2, hE2⟩ := chain_ac f hf α hLb hαLb (X L) X hY
    refine ⟨hI1'.trans hI2, ?_⟩
    rw [← intervalIntegral.integral_add_adjacent_intervals hI1' hI2, Fin.sum_univ_castSucc]
    have hsum : ∑ i : Fin n, (f (X (τ i.castSucc)) - f (X (τ i.castSucc) - Δ i.castSucc)) =
        ∑ i : Fin n, (f (X' (τ' i)) - f (X' (τ' i) - Δ' i)) := by
      apply Finset.sum_congr rfl; intro i _; rw [← hXτ' i]
    rw [hsum, hE2]
    have hXL' : X L - Δ (Fin.last n) = X' L := by rw [hXL]; ring
    rw [hXL', hE1, hint1, ← hXa]
    ring

#print axioms jumps_general

/-- Ito's formula with jumps, path by path, for finitely many jumps: if the path drifts at
rate `α` (integrable on `[0, T]`) and jumps by `Δ i` at distinct times `0 < τ i ≤ T`, and `f`
has a continuous curvature, then `f (X T)` is `f (X 0)` plus the slope term
`∫₀ᵀ f'(X s) α s ds` plus, at each jump, the exact difference `f(after) - f(before)`. -/
theorem ito_formula_with_jumps (f : ℝ → ℝ) (hf : ContDiff ℝ 2 f)
    (x₀ T : ℝ) (hT : 0 ≤ T) (α : ℝ → ℝ) (hα : IntervalIntegrable α volume 0 T)
    {n : ℕ} (τ : Fin n → ℝ) (hτ : StrictMono τ) (hτpos : ∀ i, 0 < τ i) (hτT : ∀ i, τ i ≤ T)
    (Δ : Fin n → ℝ) (X : ℝ → ℝ)
    (hX : ∀ t, X t = x₀ + (∫ s in (0 : ℝ)..t, α s) +
      ∑ i ∈ Finset.univ.filter (fun i => τ i ≤ t), Δ i) :
    f (X T) = f (X 0) + (∫ s in (0 : ℝ)..T, deriv f (X s) * α s) +
      ∑ i, (f (X (τ i)) - f (X (τ i) - Δ i)) := by
  exact (jumps_general f (hf.of_le (by norm_num)) x₀ 0 α n T τ hT hα hτ hτpos hτT Δ X hX).2

/-- The spike factor `Y = e^J`, with `J` normal of mean `μJ` and standard deviation `δ`:
its average is `e^(μJ + δ²/2)`, so `k = E[Y] - 1 = e^(μJ + δ²/2) - 1`, and the average of
`Y²` is `e^(2 μJ + 2 δ²)`. -/
theorem lognormal_spike_moments (μJ δ : ℝ) :
    (∫ j, Real.exp j ∂(gaussianReal μJ ⟨δ ^ 2, sq_nonneg δ⟩)) = Real.exp (μJ + δ ^ 2 / 2) ∧
    (∫ j, Real.exp j ^ 2 ∂(gaussianReal μJ ⟨δ ^ 2, sq_nonneg δ⟩)) =
      Real.exp (2 * μJ + 2 * δ ^ 2) := by
  have h := fun t => congrFun (mgf_fun_id_gaussianReal (μ := μJ) (v := ⟨δ ^ 2, sq_nonneg δ⟩)) t
  simp only [mgf] at h
  constructor
  · have := h 1
    simp only [one_mul] at this
    rw [this]; show Real.exp (μJ * 1 + δ ^ 2 * 1 ^ 2 / 2) = _; congr 1; ring
  · have := h 2
    have e : ∀ j : ℝ, Real.exp j ^ 2 = Real.exp (2 * j) := by
      intro j; rw [← Real.exp_nat_mul]; norm_num
    simp_rw [e]
    rw [this]; show Real.exp (μJ * 2 + δ ^ 2 * 2 ^ 2 / 2) = _; congr 1; ring

/-- Drop "finitely many jumps": for the Lévy measure `x^(-2.5) dx` on jump sizes `(0, 1)`,
the average jump sum per day counting sizes from `ε` to `1` is `2 (ε^(-1/2) - 1)`,
and it grows without bound as the smallest size `ε` falls to `0`, so it has no limit. -/
theorem uncompensated_small_jumps_diverge :
    (∀ ε : ℝ, 0 < ε → ε ≤ 1 →
      ∫ x in ε..1, x * x ^ (-(5 / 2 : ℝ)) = 2 * (ε ^ (-(1 / 2 : ℝ)) - 1)) ∧
    Tendsto (fun ε : ℝ => ∫ x in ε..1, x * x ^ (-(5 / 2 : ℝ))) (𝓝[>] 0) atTop := by
  have key : ∀ ε : ℝ, 0 < ε → ε ≤ 1 →
      ∫ x in ε..1, x * x ^ (-(5 / 2 : ℝ)) = 2 * (ε ^ (-(1 / 2 : ℝ)) - 1) := by
    intro ε hε hε1
    have hcong : ∫ x in ε..1, x * x ^ (-(5 / 2 : ℝ)) = ∫ x in ε..1, x ^ (-(3 / 2 : ℝ)) := by
      apply intervalIntegral.integral_congr
      intro x hx
      rw [Set.uIcc_of_le hε1] at hx
      have hx0 : 0 < x := hε.trans_le hx.1
      simp only
      rw [show (-(3 / 2 : ℝ)) = 1 + (-(5 / 2 : ℝ)) by norm_num, Real.rpow_add hx0,
        Real.rpow_one]
    rw [hcong, integral_rpow (Or.inr ⟨by norm_num, by
      rw [Set.uIcc_of_le hε1]; exact fun h => (not_le.2 hε) h.1⟩)]
    rw [show (-(3 / 2 : ℝ)) + 1 = -(1 / 2) by norm_num, Real.one_rpow]
    ring
  refine ⟨key, ?_⟩
  have hlim : Tendsto (fun ε : ℝ => 2 * (ε ^ (-(1 / 2 : ℝ)) - 1)) (𝓝[>] 0) atTop := by
    have := tendsto_rpow_neg_nhdsGT_zero (y := -(1 / 2 : ℝ)) (by norm_num)
    exact Tendsto.const_mul_atTop (by norm_num) (tendsto_atTop_add_const_right _ (-1) this)
  refine hlim.congr' ?_
  have h1 : ∀ᶠ ε in 𝓝[>] (0 : ℝ), ε < 1 := nhdsWithin_le_nhds (gt_mem_nhds one_pos)
  filter_upwards [h1, self_mem_nhdsWithin] with ε hε1 hε0
  exact (key ε hε0 hε1.le).symm

/-! The card's exact worked numbers. Rates written as fractions: λ = 1/10 a day,
T = 30 days, μJ = 3/10, δ = 1/10, σ = 3/100. -/

-- Expected spikes in a month: λ T = 3.
example : (1 / 10 : ℚ) * 30 = 3 := by norm_num
-- The spikes' share of the average log: λ T μJ = 0.9.
example : (1 / 10 : ℚ) * 30 * (3 / 10) = 9 / 10 := by norm_num
-- Variance of the log: σ² T + λ T (μJ² + δ²) = 0.027 + 3 × 0.1 = 0.327.
example : (3 / 100 : ℚ) ^ 2 * 30 + 3 * ((3 / 10) ^ 2 + (1 / 10) ^ 2) = 327 / 1000 := by norm_num
-- Uncompensated jump sum a day, 2 (ε^(-1/2) - 1), at ε = 1e-2, 1e-4, 1e-6, 1e-8:
-- ε^(-1/2) = 10, 100, 1000, 10000, giving 18, 198, 1998, 19998.
example : (10 : ℚ) ^ 2 = 100 ∧ 2 * ((10 : ℚ) - 1) = 18 := by norm_num
example : (100 : ℚ) ^ 2 = 10 ^ 4 ∧ 2 * ((100 : ℚ) - 1) = 198 := by norm_num
example : (1000 : ℚ) ^ 2 = 10 ^ 6 ∧ 2 * ((1000 : ℚ) - 1) = 1998 := by norm_num
example : (10000 : ℚ) ^ 2 = 10 ^ 8 ∧ 2 * ((10000 : ℚ) - 1) = 19998 := by norm_num

#print axioms ito_formula_with_jumps
#print axioms lognormal_spike_moments
#print axioms uncompensated_small_jumps_diverge
