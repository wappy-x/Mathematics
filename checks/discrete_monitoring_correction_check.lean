-- Daily monitoring: in the lognormal model, a down-and-out call checked only at m evenly spaced closes is worth strictly more than the same call watched every instant, and the shifted barrier H e^(-β σ √(T/m)), with β = -ζ(1/2)/√(2π) > 0, sits strictly below H and returns to H as the checks grow.
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.NumberTheory.LSeries.RiemannZeta
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Complex.LocallyUniformLimit

open MeasureTheory ProbabilityTheory Real Filter
open scoped NNReal

/-- Acme's price at time `t` in the pricing measure: today's price `S`, riskless rate `r`,
dividend yield `q`, steady volatility `σ`, driven by the Brownian motion `B`:
`S_t = S e^((r - q - σ²/2) t + σ B_t)`. A lognormal price with no jumps. -/
noncomputable def gbmPrice {Ω : Type*} (B : ℝ≥0 → Ω → ℝ) (S r q σ : ℝ) (t : ℝ≥0) (ω : Ω) : ℝ :=
  S * exp ((r - q - σ ^ 2 / 2) * t + σ * B t ω)

open scoped Classical in
/-- The down-and-out call with **continuous monitoring**, barrier `H`, strike `K`, life `T`:
the discounted average of the payoff `max(S_T - K, 0)` over the paths that stay above `H` at
every instant up to `T`. -/
noncomputable def downOutCallContinuous {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    (B : ℝ≥0 → Ω → ℝ) (S K r q σ H : ℝ) (T : ℝ≥0) : ℝ :=
  exp (-r * T) * ∫ ω, (if ∀ t : ℝ≥0, t ≤ T → H < gbmPrice B S r q σ t ω then
      max (gbmPrice B S r q σ T ω - K) 0 else 0) ∂P

open scoped Classical in
/-- The down-and-out call with **discrete monitoring**: the barrier is checked only at the `m`
evenly spaced closes `k T / m`, `k = 1, …, m`; a close at or below `H` kills the call. -/
noncomputable def downOutCallDiscrete {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    (B : ℝ≥0 → Ω → ℝ) (S K r q σ H : ℝ) (T : ℝ≥0) (m : ℕ) : ℝ :=
  exp (-r * T) * ∫ ω, (if ∀ k ∈ Finset.Icc 1 m,
        H < gbmPrice B S r q σ ((k : ℝ≥0) * T / (m : ℝ≥0)) ω then
      max (gbmPrice B S r q σ T ω - K) 0 else 0) ∂P

/-- Siegmund's constant, the walk's average overshoot in units of one step:
`β = -ζ(1/2)/√(2π)` (about 0.5826). -/
noncomputable def bgkBeta : ℝ := -(riemannZeta (1 / 2 : ℂ)).re / √(2 * π)

section DmcZeta
open Complex Topology

lemma dmc_cpow_sub_bound {x : ℝ} (hx : 0 < x) {s : ℂ} (hs : 0 < s.re) :
    ‖(x : ℂ) ^ (-s) - ((x + 1 : ℝ) : ℂ) ^ (-s)‖ ≤ ‖s‖ * x ^ (-s.re - 1) := by
  have hs0 : -s ≠ 0 := neg_ne_zero.mpr (by rintro rfl; simp at hs)
  have hd : ∀ y ∈ Set.Icc x (x + 1), HasDerivWithinAt (fun y : ℝ => (y : ℂ) ^ (-s))
      ((-s) * (y : ℂ) ^ (-s - 1)) (Set.Icc x (x + 1)) y := fun y hy =>
    (hasDerivAt_ofReal_cpow_const (by linarith [hy.1] : y ≠ 0) hs0).hasDerivWithinAt
  have hb : ∀ y ∈ Set.Icc x (x + 1), ‖(-s) * (y : ℂ) ^ (-s - 1)‖ ≤ ‖s‖ * x ^ (-s.re - 1) := by
    intro y hy
    rw [norm_mul, norm_neg, Complex.norm_cpow_eq_rpow_re_of_pos (by linarith [hy.1])]
    gcongr
    have : (-s - 1).re = -s.re - 1 := by simp
    rw [this]
    exact Real.rpow_le_rpow_of_nonpos hx hy.1 (by linarith)
  have := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le hd hb (convex_Icc _ _)
    (Set.left_mem_Icc.mpr (by linarith)) (Set.right_mem_Icc.mpr (by linarith))
  rw [norm_sub_rev]
  simpa using this

/-- The paired terms of the alternating series. -/
noncomputable def dmcA (j : ℕ) (s : ℂ) : ℂ :=
  ((2 * j + 1 : ℝ) : ℂ) ^ (-s) - ((2 * j + 2 : ℝ) : ℂ) ^ (-s)

/-- The region where the identity theorem is applied. -/
def dmcV : Set ℂ := {s | 1 / 4 < s.re ∧ s.re < 3 ∧ -1 < s.im ∧ s.im < 1 ∧ s.re - 1 < s.im}

lemma dmcV_isOpen : IsOpen dmcV := by
  simp only [dmcV, Set.ofPred_and]
  refine (isOpen_lt continuous_const continuous_re).inter ?_
  refine (isOpen_lt continuous_re continuous_const).inter ?_
  refine (isOpen_lt continuous_const continuous_im).inter ?_
  refine (isOpen_lt continuous_im continuous_const).inter ?_
  exact isOpen_lt (continuous_re.sub continuous_const) continuous_im

lemma dmc_conv_lt {a b p q c : ℝ} (ha : 0 ≤ a) (hb : 0 ≤ b) (hab : a + b = 1)
    (hp : c < p) (hq : c < q) : c < a * p + b * q := by
  rcases ha.eq_or_lt with rfl | ha'
  · simp at hab; subst hab; simpa using hq
  · have hc : c = (a + b) * c := by rw [hab, one_mul]
    nlinarith [mul_pos ha' (sub_pos.mpr hp), mul_nonneg hb (sub_pos.mpr hq).le]

lemma dmcV_convex : Convex ℝ dmcV := by
  intro x hx y hy a b ha hb hab
  simp only [dmcV, Set.mem_ofPred_eq, add_re, add_im, Complex.real_smul, re_ofReal_mul,
    im_ofReal_mul] at hx hy ⊢
  obtain ⟨h1, h2, h3, h4, h5⟩ := hx
  obtain ⟨k1, k2, k3, k4, k5⟩ := hy
  refine ⟨dmc_conv_lt ha hb hab h1 k1, ?_, dmc_conv_lt ha hb hab h3 k3, ?_, ?_⟩
  · have := dmc_conv_lt ha hb hab (neg_lt_neg h2) (neg_lt_neg k2); linarith
  · have := dmc_conv_lt ha hb hab (neg_lt_neg h4) (neg_lt_neg k4); linarith
  · have := dmc_conv_lt (c := -1) ha hb hab (by linarith : -1 < x.im - x.re)
      (by linarith : -1 < y.im - y.re)
    linarith

lemma dmcA_bound (j : ℕ) {s : ℂ} (hs : s ∈ dmcV) :
    ‖dmcA j s‖ ≤ 4 * ((j : ℝ) + 1) ^ (-(5 / 4 : ℝ)) := by
  obtain ⟨h1, h2, h3, h4, h5⟩ := hs
  have hx : (0 : ℝ) < 2 * j + 1 := by positivity
  have := dmc_cpow_sub_bound hx (s := s) (by linarith)
  have e : (2 * (j : ℝ) + 1 + 1) = 2 * j + 2 := by ring
  rw [e] at this
  unfold dmcA
  refine this.trans ?_
  have hn : ‖s‖ ≤ 4 := by
    refine (Complex.norm_le_abs_re_add_abs_im s).trans ?_
    have : |s.re| < 3 := abs_lt.mpr ⟨by linarith, h2⟩
    have : |s.im| < 1 := abs_lt.mpr ⟨h3, h4⟩
    linarith
  have hp : (2 * (j : ℝ) + 1) ^ (-s.re - 1) ≤ ((j : ℝ) + 1) ^ (-(5 / 4 : ℝ)) := by
    calc (2 * (j : ℝ) + 1) ^ (-s.re - 1) ≤ (2 * (j : ℝ) + 1) ^ (-(5 / 4 : ℝ)) :=
          Real.rpow_le_rpow_of_exponent_le (by linarith [(j.cast_nonneg : (0:ℝ) ≤ j)]) (by linarith)
      _ ≤ ((j : ℝ) + 1) ^ (-(5 / 4 : ℝ)) :=
          Real.rpow_le_rpow_of_nonpos (by positivity) (by linarith [(j.cast_nonneg : (0:ℝ) ≤ j)])
            (by norm_num)
  have h0 : 0 ≤ (2 * (j : ℝ) + 1) ^ (-s.re - 1) := by positivity
  calc ‖s‖ * (2 * (j : ℝ) + 1) ^ (-s.re - 1) ≤ 4 * (2 * (j : ℝ) + 1) ^ (-s.re - 1) := by gcongr
    _ ≤ _ := by gcongr

lemma dmc_summable_bound : Summable (fun j : ℕ => 4 * ((j : ℝ) + 1) ^ (-(5 / 4 : ℝ))) := by
  refine Summable.mul_left 4 ?_
  have := (Real.summable_nat_rpow (p := -(5 / 4 : ℝ))).mpr (by norm_num)
  have := (summable_nat_add_iff 1).mpr this
  simpa using this

lemma dmc_eta_diff : DifferentiableOn ℂ (fun s => ∑' j, dmcA j s) dmcV := by
  refine differentiableOn_tsum_of_summable_norm dmc_summable_bound (fun j => ?_) dmcV_isOpen
    (fun j s hs => dmcA_bound j hs)
  intro s hs
  unfold dmcA
  apply DifferentiableAt.differentiableWithinAt
  apply DifferentiableAt.sub
  · exact (differentiableAt_neg_iff.mpr differentiableAt_id).const_cpow
      (Or.inl (by norm_cast))
  · exact (differentiableAt_neg_iff.mpr differentiableAt_id).const_cpow
      (Or.inl (by norm_cast))

lemma dmc_eta_eq {s : ℂ} (hs : 1 < s.re) :
    ∑' j, dmcA j s = (1 - 2 ^ (1 - s)) * riemannZeta s := by
  set z : ℕ → ℂ := fun n => 1 / ((n : ℂ) + 1) ^ s with hzdef
  have hz : Summable z := by
    have := (summable_nat_add_iff 1).mpr (Complex.summable_one_div_nat_cpow.mpr hs)
    simpa [hzdef] using this
  have hζ : riemannZeta s = ∑' n, z n := zeta_eq_tsum_one_div_nat_add_one_cpow hs
  have he : Summable (fun k => z (2 * k)) :=
    hz.comp_injective (mul_right_injective₀ (two_ne_zero))
  have ho : Summable (fun k => z (2 * k + 1)) :=
    hz.comp_injective (fun a b h => by simpa using h)
  have hze : ∀ k : ℕ, z (2 * k) = ((2 * k + 1 : ℝ) : ℂ) ^ (-s) := by
    intro k; simp only [hzdef, Complex.cpow_neg, one_div]; push_cast; ring_nf
  have hzo : ∀ k : ℕ, z (2 * k + 1) = ((2 * k + 2 : ℝ) : ℂ) ^ (-s) := by
    intro k; simp only [hzdef, Complex.cpow_neg, one_div]; push_cast; ring_nf
  have hzo' : ∀ k : ℕ, z (2 * k + 1) = 2 ^ (-s) * z k := by
    intro k
    rw [hzo]
    have : ((2 * k + 2 : ℝ) : ℂ) = ((2 : ℝ) : ℂ) * (((k : ℝ) + 1 : ℝ) : ℂ) := by push_cast; ring
    rw [this, Complex.mul_cpow_ofReal_nonneg (by norm_num) (by positivity)]
    simp only [hzdef, Complex.cpow_neg, one_div]; push_cast; ring
  have hA : ∀ j, dmcA j s = z (2 * j) - z (2 * j + 1) := by
    intro j; rw [hze, hzo]; rfl
  simp_rw [hA]
  rw [he.tsum_sub ho]
  have hsplit := tsum_even_add_odd he ho
  have hodd : ∑' k, z (2 * k + 1) = 2 ^ (-s) * riemannZeta s := by
    simp_rw [hzo']; rw [tsum_mul_left, hζ]
  have h2 : (2 : ℂ) ^ (1 - s) = 2 * 2 ^ (-s) := by
    rw [sub_eq_add_neg, Complex.cpow_add _ _ two_ne_zero, Complex.cpow_one]
  rw [h2, ← hζ] at *
  rw [eq_sub_of_add_eq hsplit, hodd]
  ring

lemma dmc_eta_half : HasSum (fun j => dmcA j (1 / 2))
    ((1 - 2 ^ (1 - 1 / 2 : ℂ)) * riemannZeta (1 / 2)) := by
  have hsum : ∀ s ∈ dmcV, Summable (fun j => dmcA j s) := fun s hs =>
    Summable.of_norm_bounded dmc_summable_bound (fun j => dmcA_bound j hs)
  have hne : ∀ s ∈ dmcV, s ≠ 1 := by
    rintro s ⟨-, -, -, -, h5⟩ rfl; simp at h5
  have hR : DifferentiableOn ℂ (fun s => (1 - 2 ^ (1 - s)) * riemannZeta s) dmcV := by
    intro s hs
    apply DifferentiableAt.differentiableWithinAt
    apply DifferentiableAt.mul
    · apply DifferentiableAt.sub (differentiableAt_const _)
      exact (differentiableAt_const _ |>.sub differentiableAt_id).const_cpow (Or.inl two_ne_zero)
    · exact differentiableAt_riemannZeta (hne s hs)
  have hz0 : (3 / 2 + 3 / 4 * Complex.I : ℂ) ∈ dmcV := by
    simp [dmcV]; norm_num
  have hev : (fun s => ∑' j, dmcA j s) =ᶠ[𝓝 (3 / 2 + 3 / 4 * Complex.I)]
      (fun s => (1 - 2 ^ (1 - s)) * riemannZeta s) := by
    have : {s : ℂ | 1 < s.re} ∈ 𝓝 (3 / 2 + 3 / 4 * Complex.I : ℂ) :=
      (isOpen_lt continuous_const continuous_re).mem_nhds (by simp; norm_num)
    filter_upwards [this] with s hs using dmc_eta_eq hs
  have heq := (dmc_eta_diff.analyticOnNhd dmcV_isOpen).eqOn_of_preconnected_of_eventuallyEq
    (hR.analyticOnNhd dmcV_isOpen) dmcV_convex.isPreconnected hz0 hev
  have hh : (1 / 2 : ℂ) ∈ dmcV := by simp [dmcV]; norm_num
  have := (hsum _ hh).hasSum
  have e := heq hh
  simp only at e
  rwa [e] at this

lemma dmc_cpow_half {x : ℝ} (hx : 0 < x) : (x : ℂ) ^ (-(1 / 2 : ℂ)) = ((1 / √x : ℝ) : ℂ) := by
  rw [show (-(1 / 2 : ℂ)) = ((-(1 / 2) : ℝ) : ℂ) by push_cast; ring, ← Complex.ofReal_cpow hx.le,
    Real.rpow_neg hx.le, Real.sqrt_eq_rpow]
  simp

lemma dmc_eta_real : HasSum (fun j : ℕ => 1 / √(2 * (j : ℝ) + 1) - 1 / √(2 * (j : ℝ) + 2))
    ((1 - √2) * (riemannZeta (1 / 2 : ℂ)).re) := by
  have h := Complex.reCLM.hasSum dmc_eta_half
  have hA : ∀ j : ℕ, dmcA j (1 / 2) = ((1 / √(2 * (j : ℝ) + 1) - 1 / √(2 * (j : ℝ) + 2) : ℝ) : ℂ) := by
    intro j; unfold dmcA
    rw [dmc_cpow_half (by positivity), dmc_cpow_half (by positivity)]; push_cast; ring
  have h2 : (2 : ℂ) ^ (1 - 1 / 2 : ℂ) = ((√2 : ℝ) : ℂ) := by
    rw [Real.sqrt_eq_rpow, Complex.ofReal_cpow (by norm_num)]; norm_num
  simp_rw [hA, h2] at h
  have h3 : (1 - ((√2 : ℝ) : ℂ)) = ((1 - √2 : ℝ) : ℂ) := by push_cast; ring
  rw [h3] at h
  simpa [Complex.re_ofReal_mul] using h

end DmcZeta


lemma dmc_alt_even (n : ℕ) :
    ∑ k ∈ Finset.range (2 * n), (-1 : ℝ) ^ k / √((k : ℝ) + 1) =
      ∑ j ∈ Finset.range n, (1 / √(2 * (j : ℝ) + 1) - 1 / √(2 * (j : ℝ) + 2)) := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [show 2 * (n + 1) = 2 * n + 1 + 1 by ring, Finset.sum_range_succ, Finset.sum_range_succ, ih,
      Finset.sum_range_succ, pow_succ, pow_mul]
    push_cast
    ring_nf

/-- The sampling times used in the strictness argument: `0`, a half step, then the grid. -/
noncomputable def dmcTimes (T : ℝ≥0) (m : ℕ) : ℕ → ℝ≥0
  | 0 => 0
  | 1 => T / (2 * (m : ℝ≥0))
  | (j + 2) => ((j + 1 : ℕ) : ℝ≥0) * T / (m : ℝ≥0)

lemma dmcTimes_strictMono (T : ℝ≥0) (m : ℕ) (hT : 0 < T) (hm : 1 ≤ m) :
    StrictMono (dmcTimes T m) := by
  have hmR : (0 : ℝ) < m := by exact_mod_cast hm
  have hTR : (0 : ℝ) < T := by exact_mod_cast hT
  refine strictMono_nat_of_lt_succ fun n => ?_
  rw [← NNReal.coe_lt_coe]
  rcases n with _ | _ | j
  · simp only [dmcTimes]; push_cast; positivity
  · simp only [dmcTimes]; push_cast
    rw [div_lt_div_iff₀ (by positivity) hmR]; nlinarith
  · simp only [dmcTimes]; push_cast
    rw [div_lt_div_iff_of_pos_right hmR]; nlinarith

lemma dmc_price_gt {S X a σ M t b T : ℝ} (hS : 0 < S) (hX : 0 < X) (hσ : 0 < σ)
    (ht0 : 0 ≤ t) (htT : t ≤ T) (hM : |Real.log (X / S)| + |a| * T ≤ σ * M) (hb : M < b) :
    X < S * Real.exp (a * t + σ * b) := by
  have h1 : Real.log (X / S) < a * t + σ * b := by
    have : -(|a| * T) ≤ a * t := by
      have : |a * t| ≤ |a| * T := by
        rw [abs_mul, abs_of_nonneg ht0]; exact mul_le_mul_of_nonneg_left htT (abs_nonneg a)
      linarith [neg_abs_le (a * t)]
    nlinarith [le_abs_self (Real.log (X / S))]
  have := Real.exp_lt_exp.mpr h1
  rw [Real.exp_log (div_pos hX hS)] at this
  rw [div_lt_iff₀ hS] at this
  linarith

#print axioms dmc_cpow_sub_bound
#print axioms dmcA
#print axioms dmcV
#print axioms dmcV_isOpen
#print axioms dmc_conv_lt
#print axioms dmcV_convex
#print axioms dmcA_bound
#print axioms dmc_summable_bound
#print axioms dmc_eta_diff
#print axioms dmc_eta_eq
#print axioms dmc_eta_half
#print axioms dmc_cpow_half
#print axioms dmc_eta_real
#print axioms dmc_alt_even
#print axioms dmcTimes
#print axioms dmcTimes_strictMono
#print axioms dmc_price_gt

/-- **A barrier checked now and then is worth more.** In the lognormal model with steady
volatility `σ > 0` and no jumps, take a down-and-out call (spot `S`, strike `K`, barrier
`0 < H < S`, life `T > 0`). With any number `m ≥ 1` of evenly spaced checks, the discretely
monitored call is worth strictly more than the continuously monitored one: it misses the dips
between closes, so it dies less often. -/
theorem discrete_down_out_call_worth_more_than_continuous
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P)
    (S K r q σ H : ℝ) (T : ℝ≥0) (m : ℕ) (hS : 0 < S) (hK : 0 < K) (hH : 0 < H) (hHS : H < S)
    (hσ : 0 < σ) (hT : 0 < T) (hm : 1 ≤ m) :
    downOutCallContinuous P B S K r q σ H T < downOutCallDiscrete P B S K r q σ H T m := by
  classical
  unfold downOutCallContinuous downOutCallDiscrete
  refine mul_lt_mul_of_pos_left ?_ (Real.exp_pos _)
  set a := r - q - σ ^ 2 / 2 with ha
  set s := dmcTimes T m with hsdef
  have hmono := dmcTimes_strictMono T m hT hm
  have hmR : (0 : ℝ) < m := by exact_mod_cast hm
  have hTR : (0 : ℝ) < T := by exact_mod_cast hT
  have hm0 : (m : ℝ≥0) ≠ 0 := by exact_mod_cast (by omega : m ≠ 0)
  -- the functions under the integrals
  set fF : Ω → ℝ := fun ω => if ∀ t : ℝ≥0, t ≤ T → H < gbmPrice B S r q σ t ω then
      max (gbmPrice B S r q σ T ω - K) 0 else 0 with hfF
  set gF : Ω → ℝ := fun ω => if ∀ k ∈ Finset.Icc 1 m,
        H < gbmPrice B S r q σ ((k : ℝ≥0) * T / (m : ℝ≥0)) ω then
      max (gbmPrice B S r q σ T ω - K) 0 else 0 with hgF
  have hgrid : ∀ k ∈ Finset.Icc 1 m, (k : ℝ≥0) * T / (m : ℝ≥0) ≤ T := by
    intro k hk
    rw [Finset.mem_Icc] at hk
    rw [← NNReal.coe_le_coe]; push_cast
    rw [div_le_iff₀ hmR]
    have : (k : ℝ) ≤ m := by exact_mod_cast hk.2
    nlinarith
  have hg0 : ∀ ω, 0 ≤ gF ω := by
    intro ω; simp only [hgF]; split_ifs <;> simp
  have hfg : ∀ ω, fF ω ≤ gF ω := by
    intro ω
    simp only [hfF, hgF]
    split_ifs with h1 h2
    · exact le_rfl
    · exact absurd (fun k hk => h1 _ (hgrid k hk)) h2
    · simp
    · exact le_rfl
  -- integrability of the discrete payoff
  have hgm : AEStronglyMeasurable gF P := by
    let Φ : (ℕ → ℝ) × ℝ → ℝ := fun x => @ite ℝ (∀ k ∈ Finset.Icc 1 m,
        H < S * exp ((r - q - σ ^ 2 / 2) * (((k : ℝ≥0) * T / (m : ℝ≥0) : ℝ≥0) : ℝ) + σ * x.1 k))
        (Classical.propDecidable _)
      (max (S * exp ((r - q - σ ^ 2 / 2) * (T : ℝ) + σ * x.2) - K) 0) 0
    have hΦ : Measurable Φ := by
      refine Measurable.ite ?_ (by fun_prop) measurable_const
      have : {x : (ℕ → ℝ) × ℝ | ∀ k ∈ Finset.Icc 1 m,
          H < S * exp ((r - q - σ ^ 2 / 2) * (((k : ℝ≥0) * T / (m : ℝ≥0) : ℝ≥0) : ℝ) + σ * x.1 k)} =
          ⋂ k ∈ Finset.Icc 1 m, {x : (ℕ → ℝ) × ℝ |
            H < S * exp ((r - q - σ ^ 2 / 2) * (((k : ℝ≥0) * T / (m : ℝ≥0) : ℝ≥0) : ℝ) + σ * x.1 k)} := by
        ext x; simp
      rw [this]
      exact Finset.measurableSet_biInter _ fun k _ =>
        measurableSet_lt measurable_const (by fun_prop)
    have hV : AEMeasurable (fun ω => ((fun k : ℕ => B ((k : ℝ≥0) * T / (m : ℝ≥0)) ω), B T ω)) P :=
      (AEMeasurable.of_eval fun k => hB.aemeasurable _).prodMk (hB.aemeasurable T)
    have : gF = Φ ∘ fun ω => ((fun k : ℕ => B ((k : ℝ≥0) * T / (m : ℝ≥0)) ω), B T ω) := by
      funext ω; rfl
    rw [this]
    exact (hΦ.comp_aemeasurable hV).aestronglyMeasurable
  have hgi : Integrable gF P := by
    have hL := hB.hasLaw_eval T
    have hexp : Integrable (fun ω => exp (σ * B T ω)) P :=
      hL.integrable_comp (f := fun x => exp (σ * x)) (integrable_exp_mul_gaussianReal σ)
    refine (hexp.const_mul (S * exp (a * T))).mono' hgm (Filter.Eventually.of_forall fun ω => ?_)
    rw [Real.norm_of_nonneg (hg0 ω)]
    simp only [hgF]
    have hp : gbmPrice B S r q σ T ω = S * exp (a * T) * exp (σ * B T ω) := by
      simp only [gbmPrice, ← ha]; rw [mul_assoc, ← Real.exp_add]
    have hpos : 0 < gbmPrice B S r q σ T ω := by unfold gbmPrice; positivity
    split_ifs
    · rw [← hp]; exact max_le (by linarith) hpos.le
    · rw [← hp]; exact hpos.le
  -- the event of positive probability
  set X : ℕ → Ω → ℝ := fun i ω => B (s (i + 1)) ω - B (s i) ω with hXdef
  have hind : iIndepFun X P := hB.toIsPreBrownianReal.hasIndepIncrements.nat hmono.monotone
  set u : ℝ≥0 := s 1 with hu
  have huR : (u : ℝ) = T / (2 * m) := by simp [hu, hsdef, dmcTimes]
  set L : ℝ := (Real.log (H / S) - a * u) / σ with hL
  set M : ℝ := (|Real.log (H / S)| + |Real.log (K / S)| + |a| * T) / σ with hM
  set A : ℕ → Set ℝ := fun i => if i = 0 then Set.Ioo (L - 1) L
    else if i = 1 then Set.Ioi (M - L + 1) else Set.Ioi 0 with hA
  have hAm : ∀ i, MeasurableSet (A i) := by
    intro i; simp only [hA]; split_ifs <;> measurability
  have hAne : ∀ i, volume (A i) ≠ 0 := by
    intro i; simp only [hA]
    split_ifs
    · exact isOpen_Ioo.measure_ne_zero volume (Set.nonempty_Ioo.mpr (by linarith))
    · exact isOpen_Ioi.measure_ne_zero volume Set.nonempty_Ioi
    · exact isOpen_Ioi.measure_ne_zero volume Set.nonempty_Ioi
  set E : Set Ω := ⋂ i ∈ Finset.range (m + 1), X i ⁻¹' A i with hE
  have hEpos : P E ≠ 0 := by
    rw [hE, hind.meas_biInter (fun i _ => ⟨A i, hAm i, rfl⟩)]
    rw [Finset.prod_ne_zero_iff]
    intro i _
    have hlaw := hB.hasLaw_sub (s (i + 1)) (s i)
    have hv : nndist ((s (i + 1) : ℝ≥0) : ℝ) (s i : ℝ) ≠ 0 := by
      rw [ne_eq, nndist_eq_zero]
      exact_mod_cast (hmono (Nat.lt_succ_self i)).ne'
    have := hlaw.measure_eq (p := fun x => x ∈ A i) (hAm i)
    simp only [Set.ofPred_mem_eq] at this
    change P (X i ⁻¹' A i) ≠ 0
    have e : X i ⁻¹' A i = {ω | (B (s (i + 1)) - B (s i)) ω ∈ A i} := rfl
    rw [e, this]
    exact fun h => hAne i ((gaussianReal_absolutelyContinuous' 0 hv) h)
  set G : Set Ω := {ω | B 0 ω = 0} with hGdef
  have hG : P Gᶜ = 0 := by
    have := hB.eval_zero_ae_eq_zero
    rw [ae_iff] at this
    exact this
  have hEG : P (E ∩ G) ≠ 0 := by rw [measure_inter_conull hG]; exact hEpos
  have hMbound : ∀ Y : ℝ, 0 < Y → (Y = H ∨ Y = K) → |Real.log (Y / S)| + |a| * T ≤ σ * M := by
    intro Y _ hY
    rw [hM, mul_div_cancel₀ _ hσ.ne']
    rcases hY with h | h <;> rw [h] <;>
      linarith [abs_nonneg (Real.log (K / S)), abs_nonneg (Real.log (H / S))]
  have hkey : ∀ ω ∈ E ∩ G, fF ω = 0 ∧ 0 < gF ω := by
    rintro ω ⟨hωE, hω0⟩
    have hXi : ∀ i ≤ m, X i ω ∈ A i := by
      intro i hi
      exact Set.mem_iInter₂.mp hωE i (Finset.mem_range.mpr (by omega))
    have hB0 : B 0 ω = 0 := hω0
    have h0 := hXi 0 (Nat.zero_le _)
    have h1 := hXi 1 hm
    simp only [hA, ↓reduceIte, Set.mem_Ioo, hXdef] at h0
    simp only [hA, one_ne_zero, ↓reduceIte, Set.mem_Ioi, hXdef] at h1
    have hs0 : s 0 = 0 := by simp [hsdef, dmcTimes]
    rw [hs0, hB0, sub_zero] at h0
    have h0' : L - 1 < B u ω ∧ B u ω < L := h0
    have h1' : M - L + 1 < B (s 2) ω - B u ω := h1
    have hgridB : ∀ j, j < m → M < B (s (j + 2)) ω := by
      intro j
      induction j with
      | zero => intro _; show M < B (s 2) ω; linarith [h0'.1]
      | succ j ih =>
        intro hj
        have hx := hXi (j + 2) (by omega)
        simp only [hA, hXdef, show j + 2 ≠ 0 by omega, show j + 2 ≠ 1 by omega, if_false,
          Set.mem_Ioi] at hx
        have := ih (by omega)
        rw [show j + 1 + 2 = j + 2 + 1 by ring]
        linarith
    have hsk : ∀ k, 1 ≤ k → s (k - 1 + 2) = (k : ℝ≥0) * T / (m : ℝ≥0) := by
      intro k hk
      simp only [hsdef, dmcTimes]
      rw [show k - 1 + 1 = k by omega]
    have hsT : s (m - 1 + 2) = T := by
      rw [hsk m hm, mul_div_cancel_left₀ _ hm0]
    constructor
    · simp only [hfF]
      rw [if_neg]
      push_neg
      refine ⟨u, ?_, ?_⟩
      · rw [← NNReal.coe_le_coe, huR]
        rw [div_le_iff₀ (by positivity)]
        have : (1 : ℝ) ≤ m := by exact_mod_cast hm
        nlinarith
      · unfold gbmPrice
        rw [← ha]
        have hlt : a * u + σ * B u ω < Real.log (H / S) := by
          have : σ * B u ω < σ * L := mul_lt_mul_of_pos_left h0'.2 hσ
          rw [hL, mul_div_cancel₀ _ hσ.ne'] at this
          linarith
        have := Real.exp_lt_exp.mpr hlt
        rw [Real.exp_log (div_pos hH hS), lt_div_iff₀ hS] at this
        linarith
    · simp only [hgF]
      rw [if_pos]
      · apply lt_max_of_lt_left
        rw [sub_pos]
        have hb := hgridB (m - 1) (by omega)
        rw [hsT] at hb
        unfold gbmPrice; rw [← ha]
        exact dmc_price_gt hS hK hσ (by positivity) le_rfl (hMbound K hK (Or.inr rfl)) hb
      · intro k hk
        have hk' := Finset.mem_Icc.mp hk
        have hb := hgridB (k - 1) (by omega)
        rw [hsk k hk'.1] at hb
        unfold gbmPrice; rw [← ha]
        have ht := hgrid k hk
        exact dmc_price_gt hS hH hσ (by positivity) (by exact_mod_cast ht)
          (hMbound H hH (Or.inl rfl)) hb
  show ∫ ω, fF ω ∂P < ∫ ω, gF ω ∂P
  by_cases hfi : Integrable fF P
  · have hsub : 0 < ∫ ω, (gF ω - fF ω) ∂P := by
      rw [integral_pos_iff_support_of_nonneg_ae (f := fun ω => gF ω - fF ω)
        (Filter.Eventually.of_forall fun ω => by simpa [sub_nonneg] using hfg ω) (hgi.sub hfi)]
      refine lt_of_lt_of_le (pos_iff_ne_zero.mpr hEG) (measure_mono ?_)
      intro ω hω
      obtain ⟨h1, h2⟩ := hkey ω hω
      simp only [Function.mem_support, h1, sub_zero]
      exact h2.ne'
    rw [integral_sub hgi hfi] at hsub
    linarith
  · rw [integral_undef hfi]
    rw [integral_pos_iff_support_of_nonneg_ae (Filter.Eventually.of_forall hg0) hgi]
    refine lt_of_lt_of_le (pos_iff_ne_zero.mpr hEG) (measure_mono ?_)
    intro ω hω
    exact (hkey ω hω).2.ne'

/-- **The shift moves the barrier away from the spot, by less as checks grow.** The checks build
`ζ(1/2)` from the alternating sum: `(1 - 1/√2 + 1/√3 - …)/(1 - √2) → ζ(1/2)`. The constant
`β = -ζ(1/2)/√(2π)` is positive, so for every `m ≥ 1` the shifted down barrier
`H e^(-β σ √(T/m))` lies strictly below `H` and the shifted up barrier `H e^(β σ √(T/m))` strictly
above it, and the shifted barrier returns to `H` as the number of checks grows. -/
theorem shifted_barrier_moves_away_and_vanishes (H σ : ℝ) (T : ℝ≥0)
    (hH : 0 < H) (hσ : 0 < σ) (hT : 0 < T) :
    Tendsto (fun n : ℕ => (∑ k ∈ Finset.range n, (-1 : ℝ) ^ k / √((k : ℝ) + 1)) / (1 - √2))
        atTop (nhds (riemannZeta (1 / 2 : ℂ)).re) ∧
      0 < bgkBeta ∧
      (∀ m : ℕ, 1 ≤ m →
        H * exp (-bgkBeta * σ * √((T : ℝ) / m)) < H ∧
        H < H * exp (bgkBeta * σ * √((T : ℝ) / m))) ∧
      Tendsto (fun m : ℕ => H * exp (-bgkBeta * σ * √((T : ℝ) / m))) atTop (nhds H) := by
  have hs2 : (1 : ℝ) < √2 := by
    rw [show (1 : ℝ) = √1 by simp]; exact Real.sqrt_lt_sqrt (by norm_num) (by norm_num)
  have hden : (1 - √2 : ℝ) ≠ 0 := by linarith
  set η := (1 - √2) * (riemannZeta (1 / 2 : ℂ)).re with hη
  have hsum := dmc_eta_real
  have hηpos : 0 < η := by
    have h0 := sum_le_hasSum (Finset.range 1) (fun j _ => by
      have : √(2 * (j : ℝ) + 1) ≤ √(2 * (j : ℝ) + 2) := Real.sqrt_le_sqrt (by linarith)
      have : 0 < √(2 * (j : ℝ) + 1) := Real.sqrt_pos.mpr (by positivity)
      rw [sub_nonneg]; exact one_div_le_one_div_of_le this ‹_›) hsum
    simp at h0
    have : (√2)⁻¹ < 1 := inv_lt_one_of_one_lt₀ hs2
    linarith
  have hζ : (riemannZeta (1 / 2 : ℂ)).re < 0 := by
    have : (riemannZeta (1 / 2 : ℂ)).re = η / (1 - √2) := by rw [hη]; field_simp
    rw [this]; exact div_neg_of_pos_of_neg hηpos (by linarith)
  have hβ : 0 < bgkBeta := by
    unfold bgkBeta
    exact div_pos (by linarith) (Real.sqrt_pos.mpr (by positivity))
  refine ⟨?_, hβ, ?_, ?_⟩
  · have hanti : Antitone (fun i : ℕ => 1 / √((i : ℝ) + 1)) := by
      refine antitone_nat_of_succ_le fun n => ?_
      apply one_div_le_one_div_of_le (Real.sqrt_pos.mpr (by positivity))
      exact Real.sqrt_le_sqrt (by push_cast; linarith)
    have hzero : Tendsto (fun i : ℕ => 1 / √((i : ℝ) + 1)) atTop (nhds 0) := by
      have := (Real.continuous_sqrt.tendsto 0).comp tendsto_one_div_add_atTop_nhds_zero_nat
      simp only [Real.sqrt_zero] at this
      refine this.congr fun n => ?_
      simp [Function.comp, Real.sqrt_inv]
    obtain ⟨l, hl⟩ := Antitone.tendsto_alternating_series_of_tendsto_zero hanti hzero
    have hS : ∀ n : ℕ, ∑ i ∈ Finset.range n, (-1 : ℝ) ^ i * (1 / √((i : ℝ) + 1)) =
        ∑ k ∈ Finset.range n, (-1 : ℝ) ^ k / √((k : ℝ) + 1) := by
      intro n; simp [div_eq_mul_inv]
    have h2 : Tendsto (fun n : ℕ => ∑ k ∈ Finset.range (2 * n), (-1 : ℝ) ^ k / √((k : ℝ) + 1))
        atTop (nhds η) := by
      simp_rw [dmc_alt_even]; exact hsum.tendsto_sum_nat
    have hl2 : Tendsto (fun n : ℕ => ∑ k ∈ Finset.range (2 * n), (-1 : ℝ) ^ k / √((k : ℝ) + 1))
        atTop (nhds l) :=
      (hl.comp (tendsto_id.const_mul_atTop' two_pos)).congr fun n => hS (2 * n)
    have hle : l = η := tendsto_nhds_unique hl2 h2
    have := hl.div_const (1 - √2)
    rw [hle, hη, mul_div_cancel_left₀ _ hden] at this
    exact this.congr fun n => by rw [hS n]
  · intro m hm
    have hx : 0 < bgkBeta * σ * √((T : ℝ) / m) := by
      have : (0 : ℝ) < (T : ℝ) / m := div_pos (by exact_mod_cast hT) (by exact_mod_cast hm)
      have := Real.sqrt_pos.mpr this
      positivity
    constructor
    · apply mul_lt_of_lt_one_right hH
      rw [Real.exp_lt_one_iff]; nlinarith
    · apply lt_mul_of_one_lt_right hH
      rw [Real.one_lt_exp_iff]; exact hx
  · have h0 : Tendsto (fun m : ℕ => √((T : ℝ) / m)) atTop (nhds 0) := by
      have := (Real.continuous_sqrt.tendsto 0).comp (tendsto_const_div_atTop_nhds_zero_nat (T : ℝ))
      rw [Real.sqrt_zero] at this
      refine this.congr fun m => ?_
      simp only [Function.comp]
    have := ((Real.continuous_exp.tendsto _).comp (h0.const_mul (-bgkBeta * σ))).const_mul H
    simpa using this

-- House market: r = 5%, q = 2%, σ = 20%. Then 2λ = 2(r - q - σ²/2)/σ² = 1/2.
example : 2 * ((5 / 100 : ℚ) - 2 / 100 - (20 / 100) ^ 2 / 2) / (20 / 100) ^ 2 = 1 / 2 := by
  norm_num
-- 252 daily checks in a one-year life: Δt = 1/252, and one day's variance σ²Δt = 1/6300.
example : (1 : ℚ) / 252 * (20 / 100) ^ 2 = 1 / 6300 := by norm_num
-- The tree takes 13 steps a day: 13 × 252 = 3,276 steps.
example : 13 * 252 = 3276 := by decide
-- The simulation: 100,000 mirror-image pairs make 200,000 paths.
example : 2 * 100000 = 200000 := by norm_num

#print axioms discrete_down_out_call_worth_more_than_continuous
#print axioms shifted_barrier_moves_away_and_vanishes
