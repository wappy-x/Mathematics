-- Semimartingales: a martingale is a good integrator for bounded predictable holdings, grid gains obey discrete integration by parts, and each jump term of Ito's formula is at most a constant times the squared jump.
import Mathlib.Probability.Martingale.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.ContDiff.RCLike
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.MeanValue

open MeasureTheory Finset

/-- Orthogonality of a martingale increment: if `X` is known at grid time `k` and
`X * (M (k+1) - M k)` is integrable, its mean is zero. -/
theorem integral_mul_martingale_increment_eq_zero {Ω : Type*} {m0 : MeasurableSpace Ω}
    {μ : Measure Ω} [IsFiniteMeasure μ] {ℱ : Filtration ℕ m0} {M : ℕ → Ω → ℝ}
    (hM : Martingale M ℱ μ) {X : Ω → ℝ} {k : ℕ} (hX : StronglyMeasurable[ℱ k] X)
    (hXg : Integrable (fun ω => X ω * (M (k + 1) ω - M k ω)) μ) :
    ∫ ω, X ω * (M (k + 1) ω - M k ω) ∂μ = 0 := by
  have hm := ℱ.le k
  have hg : Integrable (M (k + 1) - M k) μ := (hM.integrable _).sub (hM.integrable _)
  have h1 : μ[M (k + 1) - M k | ℱ k] =ᵐ[μ] 0 := by
    filter_upwards [condExp_sub (hM.integrable (k + 1)) (hM.integrable k) (ℱ k),
      hM.condExp_ae_eq (Nat.le_succ k)] with ω h1 h2
    rw [h1, Pi.sub_apply, h2,
      condExp_of_stronglyMeasurable hm (hM.stronglyAdapted k) (hM.integrable k)]
    simp
  have hXg' : Integrable (X * (M (k + 1) - M k)) μ := hXg
  have h2 := condExp_mul_of_stronglyMeasurable_left hX hXg' hg
  calc ∫ ω, X ω * (M (k + 1) ω - M k ω) ∂μ
      = ∫ ω, (μ[X * (M (k + 1) - M k) | ℱ k]) ω ∂μ := (integral_condExp hm).symm
    _ = ∫ ω, (X * μ[M (k + 1) - M k | ℱ k]) ω ∂μ := integral_congr_ae h2
    _ = 0 := by
      have h3 : (X * μ[M (k + 1) - M k | ℱ k]) =ᵐ[μ] (0 : Ω → ℝ) := by
        filter_upwards [h1] with ω hω
        simp [hω]
      rw [integral_congr_ae h3]
      simp

#print axioms integral_mul_martingale_increment_eq_zero

/-- A martingale is a good integrator for simple holdings. Take a martingale `M` on grid times
`0, 1, ..., n` whose value at the end has a finite mean square, and holdings `h k` decided at grid
time `k` (known from the information at time `k`) with `|h k| ≤ b`. Then the gain
`I = ∑ h k * (M (k+1) - M k)` has mean square at most `b ^ 2 * E[(M n - M 0) ^ 2]`, and so, by
Chebyshev's inequality, `P(|I| > ε) ≤ b ^ 2 * E[(M n - M 0) ^ 2] / ε ^ 2` for every `ε > 0`.
Shrinking the bound `b` on the holdings shrinks the gain in probability. -/
theorem martingale_is_good_integrator {Ω : Type*} {m0 : MeasurableSpace Ω} {μ : Measure Ω}
    [IsProbabilityMeasure μ] {ℱ : Filtration ℕ m0} {M : ℕ → Ω → ℝ} {h : ℕ → Ω → ℝ}
    {b : ℝ} {n : ℕ}
    (hM : Martingale M ℱ μ) (hM2 : MemLp (M n) 2 μ)
    (hpred : Adapted ℱ h) (hb : ∀ k ω, |h k ω| ≤ b) :
    (∫ ω, (∑ k ∈ range n, h k ω * (M (k + 1) ω - M k ω)) ^ 2 ∂μ
        ≤ b ^ 2 * ∫ ω, (M n ω - M 0 ω) ^ 2 ∂μ) ∧
    ∀ ε : ℝ, 0 < ε →
      μ {ω | ε < |∑ k ∈ range n, h k ω * (M (k + 1) ω - M k ω)|}
        ≤ ENNReal.ofReal (b ^ 2 * (∫ ω, (M n ω - M 0 ω) ^ 2 ∂μ) / ε ^ 2) := by
  have hhs : ∀ k, StronglyMeasurable[ℱ k] (h k) := fun k => (hpred k).stronglyMeasurable
  have hMs : ∀ k, StronglyMeasurable[ℱ k] (M k) := hM.stronglyAdapted
  have hML : ∀ k ≤ n, MemLp (M k) 2 μ := fun k hk =>
    (hM2.condExp (m := ℱ k) (by norm_num)).ae_eq (hM.condExp_ae_eq hk)
  have hDL : ∀ k < n, MemLp (fun ω => M (k + 1) ω - M k ω) 2 μ := fun k hk =>
    (hML (k + 1) hk).sub (hML k hk.le)
  have hTL : ∀ k < n, MemLp (fun ω => h k ω * (M (k + 1) ω - M k ω)) 2 μ := by
    intro k hk
    refine (hDL k hk).of_le_mul (c := b)
      (((hhs k).mono (ℱ.le k)).aestronglyMeasurable.mul (hDL k hk).aestronglyMeasurable)
      (ae_of_all _ fun ω => ?_)
    rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_mul]
    exact mul_le_mul_of_nonneg_right (hb k ω) (abs_nonneg _)
  have hIL : ∀ m ≤ n, MemLp (fun ω => ∑ k ∈ range m, h k ω * (M (k + 1) ω - M k ω)) 2 μ :=
    fun m hm => memLp_finsetSum (ε' := ℝ) (μ := μ) (p := 2) (range m)
      (f := fun k ω => h k ω * (M (k + 1) ω - M k ω)) fun k hk =>
      hTL k (lt_of_lt_of_le (Finset.mem_range.1 hk) hm)
  have hIs : ∀ m, StronglyMeasurable[ℱ m]
      (fun ω => ∑ k ∈ range m, h k ω * (M (k + 1) ω - M k ω)) := by
    intro m
    refine Finset.stronglyMeasurable_fun_sum (f := fun k ω => h k ω * (M (k + 1) ω - M k ω))
      _ fun k hk => ?_
    rw [Finset.mem_range] at hk
    exact ((hhs k).mono (ℱ.mono hk.le)).mul
      (((hMs (k + 1)).mono (ℱ.mono (Nat.succ_le_of_lt hk))).sub ((hMs k).mono (ℱ.mono hk.le)))
  -- the main estimate, by induction on the number of grid steps
  have main : ∀ m ≤ n, ∫ ω, (∑ k ∈ range m, h k ω * (M (k + 1) ω - M k ω)) ^ 2 ∂μ
      ≤ b ^ 2 * ∫ ω, (M m ω - M 0 ω) ^ 2 ∂μ := by
    intro m
    induction m with
    | zero => intro _; simp
    | succ m ih =>
      intro hm
      have hmn : m < n := hm
      have ih' := ih hmn.le
      set I : Ω → ℝ := fun ω => ∑ k ∈ range m, h k ω * (M (k + 1) ω - M k ω) with hI
      set D : Ω → ℝ := fun ω => M (m + 1) ω - M m ω with hD
      have hIL' : MemLp I 2 μ := hIL m hmn.le
      have hDL' : MemLp D 2 μ := hDL m hmn
      have hTL' : MemLp (fun ω => h m ω * D ω) 2 μ := hTL m hmn
      have hYL : MemLp (fun ω => M m ω - M 0 ω) 2 μ := (hML m hmn.le).sub (hML 0 (Nat.zero_le _))
      have hIhL : MemLp (fun ω => I ω * h m ω) 2 μ := by
        refine hIL'.of_le_mul (c := b)
          (hIL'.aestronglyMeasurable.mul ((hhs m).mono (ℱ.le m)).aestronglyMeasurable)
          (ae_of_all _ fun ω => ?_)
        rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_mul, mul_comm b]
        exact mul_le_mul_of_nonneg_left (hb m ω) (abs_nonneg _)
      -- cross terms vanish
      have hc1 : ∫ ω, (I ω * h m ω) * D ω ∂μ = 0 :=
        integral_mul_martingale_increment_eq_zero hM ((hIs m).mul (hhs m))
          (hIhL.integrable_mul hDL')
      have hc2 : ∫ ω, (M m ω - M 0 ω) * D ω ∂μ = 0 :=
        integral_mul_martingale_increment_eq_zero hM
          ((hMs m).sub ((hMs 0).mono (ℱ.mono (Nat.zero_le _)))) (hYL.integrable_mul hDL')
      have e1 : ∫ ω, (∑ k ∈ range (m + 1), h k ω * (M (k + 1) ω - M k ω)) ^ 2 ∂μ
          = ∫ ω, I ω ^ 2 ∂μ + 2 * ∫ ω, (I ω * h m ω) * D ω ∂μ + ∫ ω, (h m ω * D ω) ^ 2 ∂μ := by
        have hA : Integrable (fun ω => I ω ^ 2) μ := hIL'.integrable_sq
        have hB : Integrable (fun ω => 2 * (I ω * h m ω * D ω)) μ :=
          (hIhL.integrable_mul hDL').const_mul 2
        have hC : Integrable (fun ω => (h m ω * D ω) ^ 2) μ := hTL'.integrable_sq
        have hE : ∫ ω, (∑ k ∈ range (m + 1), h k ω * (M (k + 1) ω - M k ω)) ^ 2 ∂μ
            = ∫ ω, (I ω ^ 2 + 2 * (I ω * h m ω * D ω) + (h m ω * D ω) ^ 2) ∂μ := by
          refine integral_congr_ae (ae_of_all _ fun ω => ?_)
          simp only [hI, hD, sum_range_succ]
          ring
        have hAB : Integrable (fun ω => I ω ^ 2 + 2 * (I ω * h m ω * D ω)) μ := hA.add hB
        rw [hE, integral_add hAB hC, integral_add hA hB, integral_const_mul]
      have e2 : ∫ ω, (M (m + 1) ω - M 0 ω) ^ 2 ∂μ
          = ∫ ω, (M m ω - M 0 ω) ^ 2 ∂μ + 2 * ∫ ω, (M m ω - M 0 ω) * D ω ∂μ
            + ∫ ω, D ω ^ 2 ∂μ := by
        have hA : Integrable (fun ω => (M m ω - M 0 ω) ^ 2) μ := hYL.integrable_sq
        have hB : Integrable (fun ω => 2 * ((M m ω - M 0 ω) * D ω)) μ :=
          (hYL.integrable_mul hDL').const_mul 2
        have hC : Integrable (fun ω => D ω ^ 2) μ := hDL'.integrable_sq
        have hE : ∫ ω, (M (m + 1) ω - M 0 ω) ^ 2 ∂μ
            = ∫ ω, ((M m ω - M 0 ω) ^ 2 + 2 * ((M m ω - M 0 ω) * D ω) + D ω ^ 2) ∂μ := by
          refine integral_congr_ae (ae_of_all _ fun ω => ?_)
          simp only [hD]
          ring
        have hAB : Integrable
            (fun ω => (M m ω - M 0 ω) ^ 2 + 2 * ((M m ω - M 0 ω) * D ω)) μ := hA.add hB
        rw [hE, integral_add hAB hC, integral_add hA hB, integral_const_mul]
      have e3 : ∫ ω, (h m ω * D ω) ^ 2 ∂μ ≤ b ^ 2 * ∫ ω, D ω ^ 2 ∂μ := by
        rw [← integral_const_mul]
        refine integral_mono hTL'.integrable_sq (hDL'.integrable_sq.const_mul _) fun ω => ?_
        have : h m ω ^ 2 ≤ b ^ 2 := by
          rw [← sq_abs]; exact pow_le_pow_left₀ (abs_nonneg _) (hb m ω) 2
        simp only
        rw [mul_pow]
        exact mul_le_mul_of_nonneg_right this (sq_nonneg _)
      rw [e1, e2, hc1, hc2]
      nlinarith [ih', e3]
  refine ⟨main n le_rfl, fun ε hε => ?_⟩
  set I : Ω → ℝ := fun ω => ∑ k ∈ range n, h k ω * (M (k + 1) ω - M k ω) with hI
  have hInt : Integrable (fun ω => I ω ^ 2) μ := (hIL n le_rfl).integrable_sq
  have hmk := mul_meas_ge_le_integral_of_nonneg (μ := μ)
    (ae_of_all _ fun ω => sq_nonneg (I ω)) hInt (ε ^ 2)
  have hsub : {ω | ε < |I ω|} ⊆ {ω | ε ^ 2 ≤ I ω ^ 2} := by
    intro ω hω
    simp only [Set.mem_ofPred_eq] at hω ⊢
    rw [← sq_abs (I ω)]
    exact pow_le_pow_left₀ hε.le hω.le 2
  have hε2 : 0 < ε ^ 2 := by positivity
  have hreal : μ.real {ω | ε ^ 2 ≤ I ω ^ 2}
      ≤ b ^ 2 * (∫ ω, (M n ω - M 0 ω) ^ 2 ∂μ) / ε ^ 2 := by
    rw [le_div_iff₀ hε2, mul_comm]
    exact hmk.trans (main n le_rfl)
  calc μ {ω | ε < |I ω|} ≤ μ {ω | ε ^ 2 ≤ I ω ^ 2} := measure_mono hsub
    _ = ENNReal.ofReal (μ.real {ω | ε ^ 2 ≤ I ω ^ 2}) := by
      rw [measureReal_def, ENNReal.ofReal_toReal (measure_ne_top _ _)]
    _ ≤ _ := ENNReal.ofReal_le_ofReal hreal

/-- Integration by parts on a grid. For any two paths sampled at grid times `0, 1, ..., n`, the
product at the end equals the product at the start, plus the left-point sum of `x` against `y`,
plus the left-point sum of `y` against `x`, plus the sum of matched products of changes (the grid
covariation). With `x = y` this is the card's exact grid identity
`S_1 ^ 2 - S_0 ^ 2 = 2 ∑ S_k ΔS_k + ∑ (ΔS_k) ^ 2`. -/
theorem grid_integration_by_parts (x y : ℕ → ℝ) (n : ℕ) :
    x n * y n = x 0 * y 0 + ∑ k ∈ range n, x k * (y (k + 1) - y k)
      + ∑ k ∈ range n, y k * (x (k + 1) - x k)
      + ∑ k ∈ range n, (x (k + 1) - x k) * (y (k + 1) - y k) := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [sum_range_succ, sum_range_succ, sum_range_succ]
    linear_combination ih

/-- The jump term of Ito's formula is at most a constant times the squared jump. For a function
`f` with two continuous derivatives and a path that stays within `[-K, K]`, there is one constant
`C` such that every jump from `x` to `y` has `|f y - f x - f' x * (y - x)| ≤ C * (y - x) ^ 2`.
This is why the jump sum converges whenever the squared jumps add to a finite total. -/
theorem ito_jump_term_le_const_mul_sq (f : ℝ → ℝ) (hf : ContDiff ℝ 2 f) (K : ℝ) :
    ∃ C : ℝ, ∀ x y : ℝ, |x| ≤ K → |y| ≤ K →
      |f y - f x - deriv f x * (y - x)| ≤ C * (y - x) ^ 2 := by
  have hd : ContDiff ℝ 1 (deriv f) := by
    have := (contDiff_succ_iff_deriv (n := 1) (f := f)).1 (by exact_mod_cast hf)
    exact this.2.2
  obtain ⟨L, hL⟩ := (hd.contDiffOn (s := Set.Icc (-K) K)).exists_lipschitzOnWith
    (by norm_num) (convex_Icc _ _) isCompact_Icc
  have hdiff : Differentiable ℝ f := hf.differentiable (by norm_num)
  refine ⟨L, fun x y hx hy => ?_⟩
  have hxI : x ∈ Set.Icc (-K) K := abs_le.1 hx
  have hyI : y ∈ Set.Icc (-K) K := abs_le.1 hy
  have hsub : Set.uIcc x y ⊆ Set.Icc (-K) K := Set.uIcc_subset_Icc hxI hyI
  set g : ℝ → ℝ := fun t => f t - deriv f x * (t - x) with hg
  have hgd : ∀ t, HasDerivAt g (deriv f t - deriv f x) t := by
    intro t
    have h1 := (hdiff t).hasDerivAt
    have h2 : HasDerivAt (fun t => deriv f x * (t - x)) (deriv f x * 1) t :=
      ((hasDerivAt_id t).sub_const x).const_mul _
    have h3 := h1.sub h2
    rw [mul_one] at h3
    exact h3
  have key := Convex.norm_image_sub_le_of_norm_deriv_le (f := g) (s := Set.uIcc x y)
    (C := L * |y - x|) (fun t _ => (hgd t).differentiableAt)
    (fun t ht => by
      rw [(hgd t).deriv]
      have h1 := hL.dist_le_mul t (hsub ht) x (hsub Set.left_mem_uIcc)
      rw [Real.dist_eq] at h1
      rw [Real.norm_eq_abs]
      calc |deriv f t - deriv f x| ≤ L * |t - x| := h1
        _ ≤ L * |y - x| := by
          have hL0 : (0:ℝ) ≤ L := L.2
          exact mul_le_mul_of_nonneg_left (Set.abs_sub_left_of_mem_uIcc ht) hL0)
    (convex_uIcc x y) Set.left_mem_uIcc Set.right_mem_uIcc
  simp only [hg, Real.norm_eq_abs] at key
  have : f y - deriv f x * (y - x) - (f x - deriv f x * (x - x)) = f y - f x - deriv f x * (y - x) := by ring
  rw [this] at key
  calc _ ≤ _ := key
    _ = (L : ℝ) * (y - x) ^ 2 := by rw [mul_assoc, ← sq, sq_abs]

-- The worked numbers: mu = 1/20, sigma = 1/5, lambda = 1, j = -1/5, all exact fractions.
-- Rate of [S] per unit S^2: sigma^2 + lambda * j^2 = 0.08.
example : ((1 : ℚ) / 5) ^ 2 + 1 * (-1 / 5) ^ 2 = 2 / 25 := by norm_num
-- The wobble and the crashes contribute equally: sigma^2 = lambda * j^2 = 0.04.
example : ((1 : ℚ) / 5) ^ 2 = 1 * (-1 / 5) ^ 2 := by norm_num
-- Growth rate of E[S_t^2]: c = 2 mu + sigma^2 + lambda * j^2 = 0.18.
example : 2 * ((1 : ℚ) / 20) + (1 / 5) ^ 2 + 1 * (-1 / 5) ^ 2 = 9 / 50 := by norm_num
-- Climb between crashes: mu - lambda * j = 0.25.
example : (1 : ℚ) / 20 - 1 * (-1 / 5) = 1 / 4 := by norm_num
-- Log-drift between crashes: G = mu - lambda * j - sigma^2 / 2 = 0.23.
example : (1 : ℚ) / 20 - 1 * (-1 / 5) - (1 / 5) ^ 2 / 2 = 23 / 100 := by norm_num
-- Try-changing: four crashes of 10% give the same lambda * j^2 as one crash of 20%.
example : (4 : ℚ) * (-1 / 10) ^ 2 = 1 * (-1 / 5) ^ 2 := by norm_num

#print axioms martingale_is_good_integrator
#print axioms grid_integration_by_parts
#print axioms ito_jump_term_le_const_mul_sq
