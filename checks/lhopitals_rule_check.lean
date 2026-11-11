-- L'Hopital's rule: if top and bottom both head for 0, or the bottom blows up, as x heads for a number a (from both sides) or for plus or minus infinity, both have rates there, the bottom's rate is never 0, and the rate ratio heads for a number L or for plus or minus infinity, then the ratio heads for the same place; so sin x / x heads for 1 at 0 and x e^(-x) heads for 0 as x grows.
import Mathlib.Analysis.Calculus.LHopital
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Tactic.NormNum

open Real Filter Topology

/-- Core step: on a region where the rate ratio stays above M, the ratio f/g eventually stays
above any M' below M, provided |g| blows up and every x near the destination sees the whole
segment between it and a fixed point y inside the region. -/
theorem lhopital_core_lower (f g : ℝ → ℝ) (F : Filter ℝ) (M M' : ℝ) (hMM : M' < M)
    (S : Set ℝ) (y : ℝ)
    (hS : ∀ x ∈ S, DifferentiableAt ℝ f x ∧ DifferentiableAt ℝ g x ∧ deriv g x ≠ 0 ∧
      M < deriv f x / deriv g x)
    (hy : ∀ᶠ x in F, x ≠ y ∧ Set.uIcc x y ⊆ S)
    (hginf : Tendsto (fun x => |g x|) F atTop) :
    ∀ᶠ x in F, M' < f x / g x := by
  have hinv : Tendsto (fun x => (g x)⁻¹) F (𝓝 0) := by
    rw [tendsto_zero_iff_norm_tendsto_zero]
    have h := tendsto_inv_atTop_zero.comp hginf
    simp only [Function.comp_def] at h
    simpa [Real.norm_eq_abs, abs_inv] using h
  have hT : Tendsto (fun x => M * (1 - g y * (g x)⁻¹) + f y * (g x)⁻¹) F (𝓝 M) := by
    have := ((tendsto_const_nhds (x := M)).mul
      ((tendsto_const_nhds (x := (1:ℝ))).sub ((tendsto_const_nhds (x := g y)).mul hinv))).add
      ((tendsto_const_nhds (x := f y)).mul hinv)
    simpa using this
  have hT2 : Tendsto (fun x => 1 - g y * (g x)⁻¹) F (𝓝 1) := by
    simpa using (tendsto_const_nhds (x := (1:ℝ))).sub ((tendsto_const_nhds (x := g y)).mul hinv)
  filter_upwards [hy, hT.eventually (lt_mem_nhds hMM), hT2.eventually (lt_mem_nhds one_pos),
    hginf.eventually_gt_atTop 0] with x hxy hxM hx1 hgx
  obtain ⟨hne, hsub⟩ := hxy
  have hgx0 : g x ≠ 0 := by
    intro h; rw [h, abs_zero] at hgx; exact lt_irrefl _ hgx
  -- mean value theorems on the segment between x and y
  have key : ∀ u v : ℝ, u < v → Set.Icc u v ⊆ S →
      g v ≠ g u ∧ ∃ c ∈ S, (f v - f u) / (g v - g u) = deriv f c / deriv g c := by
    intro u v huv hsub'
    have hdf : ∀ z ∈ Set.Icc u v, DifferentiableAt ℝ f z := fun z hz => (hS z (hsub' hz)).1
    have hdg : ∀ z ∈ Set.Icc u v, DifferentiableAt ℝ g z := fun z hz => (hS z (hsub' hz)).2.1
    have hcf : ContinuousOn f (Set.Icc u v) := fun z hz => (hdf z hz).continuousAt.continuousWithinAt
    have hcg : ContinuousOn g (Set.Icc u v) := fun z hz => (hdg z hz).continuousAt.continuousWithinAt
    obtain ⟨c1, hc1, hc1e⟩ := exists_hasDerivAt_eq_slope g (deriv g) huv hcg
      (fun z hz => (hdg z (Set.Ioo_subset_Icc_self hz)).hasDerivAt)
    have hguv : g v ≠ g u := by
      intro h
      have := (hS c1 (hsub' (Set.Ioo_subset_Icc_self hc1))).2.2.1
      rw [hc1e, h, sub_self, zero_div] at this
      exact this rfl
    refine ⟨hguv, ?_⟩
    obtain ⟨c, hc, hce⟩ := exists_ratio_hasDerivAt_eq_ratio_slope f (deriv f) huv hcf
      (fun z hz => (hdf z (Set.Ioo_subset_Icc_self hz)).hasDerivAt) g (deriv g) hcg
      (fun z hz => (hdg z (Set.Ioo_subset_Icc_self hz)).hasDerivAt)
    have hcS := hS c (hsub' (Set.Ioo_subset_Icc_self hc))
    refine ⟨c, hsub' (Set.Ioo_subset_Icc_self hc), ?_⟩
    rw [div_eq_div_iff (sub_ne_zero.2 hguv) hcS.2.2.1]
    linarith [hce]
  have hq : g x ≠ g y ∧ M < (f x - f y) / (g x - g y) := by
    rcases lt_or_gt_of_ne hne with h | h
    · obtain ⟨h1, c, hc, hce⟩ := key x y h (by rw [Set.uIcc_of_le h.le] at hsub; exact hsub)
      refine ⟨h1.symm, ?_⟩
      rw [show (f x - f y) / (g x - g y) = (f y - f x) / (g y - g x) by
        rw [← neg_sub (f y), ← neg_sub (g y), neg_div_neg_eq], hce]
      exact (hS c hc).2.2.2
    · obtain ⟨h1, c, hc, hce⟩ := key y x h (by rw [Set.uIcc_of_ge h.le] at hsub; exact hsub)
      refine ⟨h1, ?_⟩
      rw [hce]
      exact (hS c hc).2.2.2
  obtain ⟨hxy', hqM⟩ := hq
  have hid : f x / g x = (f x - f y) / (g x - g y) * (1 - g y * (g x)⁻¹) + f y * (g x)⁻¹ := by
    have h2 : g x - g y ≠ 0 := sub_ne_zero.2 hxy'
    field_simp
    ring
  rw [hid]
  have := mul_lt_mul_of_pos_right hqM hx1
  linarith

/-- The four one-sided destinations (from the right of a, from the left of a, plus infinity,
minus infinity) all have the segment property used by the core step. -/
theorem lhopital_segment_property (a : ℝ) (F : Filter ℝ)
    (hF : F = 𝓝[>] a ∨ F = 𝓝[<] a ∨ F = atTop ∨ F = atBot) (P : ℝ → Prop)
    (hP : ∀ᶠ x in F, P x) : ∃ y, ∀ᶠ x in F, x ≠ y ∧ Set.uIcc x y ⊆ {x | P x} := by
  rcases hF with rfl | rfl | rfl | rfl
  · obtain ⟨u, hu, hPu⟩ := (nhdsGT_basis a).eventually_iff.1 hP
    refine ⟨(a + u) / 2, ?_⟩
    filter_upwards [Ioo_mem_nhdsGT (show a < (a + u) / 2 by linarith)] with x hx
    refine ⟨hx.2.ne, ?_⟩
    rw [Set.uIcc_of_le hx.2.le]
    intro z hz
    exact hPu ⟨lt_of_lt_of_le hx.1 hz.1, by linarith [hz.2]⟩
  · obtain ⟨u, hu, hPu⟩ := (nhdsLT_basis a).eventually_iff.1 hP
    refine ⟨(a + u) / 2, ?_⟩
    filter_upwards [Ioo_mem_nhdsLT (show (a + u) / 2 < a by linarith)] with x hx
    refine ⟨hx.1.ne', ?_⟩
    rw [Set.uIcc_of_ge hx.1.le]
    intro z hz
    exact hPu ⟨by linarith [hz.1], lt_of_le_of_lt hz.2 hx.2⟩
  · obtain ⟨b, hb⟩ := eventually_atTop.1 hP
    refine ⟨b, ?_⟩
    filter_upwards [eventually_gt_atTop b] with x hx
    refine ⟨hx.ne', ?_⟩
    rw [Set.uIcc_of_ge hx.le]
    intro z hz
    exact hb z hz.1
  · obtain ⟨b, hb⟩ := eventually_atBot.1 hP
    refine ⟨b, ?_⟩
    filter_upwards [eventually_lt_atBot b] with x hx
    refine ⟨hx.ne, ?_⟩
    rw [Set.uIcc_of_le hx.le]
    intro z hz
    exact hb z hz.2

/-- Lower bound in each one-sided direction. -/
theorem lhopital_lower_onesided (f g : ℝ → ℝ) (a : ℝ) (F : Filter ℝ)
    (hF : F = 𝓝[>] a ∨ F = 𝓝[<] a ∨ F = atTop ∨ F = atBot)
    (hf : ∀ᶠ x in F, DifferentiableAt ℝ f x)
    (hg : ∀ᶠ x in F, DifferentiableAt ℝ g x)
    (hg' : ∀ᶠ x in F, deriv g x ≠ 0)
    (hginf : Tendsto (fun x => |g x|) F atTop) (M M' : ℝ) (hMM : M' < M)
    (hM : ∀ᶠ x in F, M < deriv f x / deriv g x) :
    ∀ᶠ x in F, M' < f x / g x := by
  obtain ⟨y, hy⟩ := lhopital_segment_property a F hF
    (fun x => ((DifferentiableAt ℝ f x ∧ DifferentiableAt ℝ g x) ∧ deriv g x ≠ 0) ∧
      M < deriv f x / deriv g x) (((hf.and hg).and hg').and hM)
  refine lhopital_core_lower f g F M M' hMM _ y ?_ hy hginf
  rintro x ⟨⟨⟨h1, h2⟩, h3⟩, h4⟩
  exact ⟨h1, h2, h3, h4⟩

/-- Lower bound for the three destinations of the card. -/
theorem lhopital_lower (f g : ℝ → ℝ) (a : ℝ) (F : Filter ℝ)
    (hF : F = 𝓝[≠] a ∨ F = atTop ∨ F = atBot)
    (hf : ∀ᶠ x in F, DifferentiableAt ℝ f x)
    (hg : ∀ᶠ x in F, DifferentiableAt ℝ g x)
    (hg' : ∀ᶠ x in F, deriv g x ≠ 0)
    (hginf : Tendsto (fun x => |g x|) F atTop) (M M' : ℝ) (hMM : M' < M)
    (hM : ∀ᶠ x in F, M < deriv f x / deriv g x) :
    ∀ᶠ x in F, M' < f x / g x := by
  rcases hF with rfl | rfl | rfl
  · rw [← nhdsLT_sup_nhdsGT] at *
    rw [eventually_sup] at *
    rw [tendsto_sup] at hginf
    exact ⟨lhopital_lower_onesided f g a _ (Or.inr (Or.inl rfl)) hf.1 hg.1 hg'.1 hginf.1
        M M' hMM hM.1,
      lhopital_lower_onesided f g a _ (Or.inl rfl) hf.2 hg.2 hg'.2 hginf.2 M M' hMM hM.2⟩
  · exact lhopital_lower_onesided f g a _ (Or.inr (Or.inr (Or.inl rfl))) hf hg hg' hginf
      M M' hMM hM
  · exact lhopital_lower_onesided f g a _ (Or.inr (Or.inr (Or.inr rfl))) hf hg hg' hginf
      M M' hMM hM

/-- Upper bound, from the lower bound applied to -f. -/
theorem lhopital_upper (f g : ℝ → ℝ) (a : ℝ) (F : Filter ℝ)
    (hF : F = 𝓝[≠] a ∨ F = atTop ∨ F = atBot)
    (hf : ∀ᶠ x in F, DifferentiableAt ℝ f x)
    (hg : ∀ᶠ x in F, DifferentiableAt ℝ g x)
    (hg' : ∀ᶠ x in F, deriv g x ≠ 0)
    (hginf : Tendsto (fun x => |g x|) F atTop) (M M' : ℝ) (hMM : M < M')
    (hM : ∀ᶠ x in F, deriv f x / deriv g x < M) :
    ∀ᶠ x in F, f x / g x < M' := by
  have h := lhopital_lower (fun x => -f x) g a F hF (hf.mono fun x hx => hx.neg) hg hg' hginf
    (-M) (-M') (by linarith) (hM.mono fun x hx => by
      simp only [deriv.fun_neg', neg_div]
      linarith)
  filter_upwards [h] with x hx
  rw [neg_div] at hx
  linarith

/-- L'Hopital's rule, 0 over 0. Let x head for a number a (from both sides, a itself aside), or
for plus infinity, or for minus infinity. Suppose the top f and the bottom g both head for 0,
both have rates (derivatives) at every x near that destination, and the bottom's rate is never 0
there. If the rate ratio f'(x)/g'(x) heads for a number L, or for plus infinity, or for minus
infinity, then the ratio f(x)/g(x) heads for the same limit. -/
theorem lhopital_zero_over_zero (f g : ℝ → ℝ) (a L : ℝ) (F l : Filter ℝ)
    (hF : F = 𝓝[≠] a ∨ F = atTop ∨ F = atBot)
    (hl : l = 𝓝 L ∨ l = atTop ∨ l = atBot)
    (hf : ∀ᶠ x in F, DifferentiableAt ℝ f x)
    (hg : ∀ᶠ x in F, DifferentiableAt ℝ g x)
    (hg' : ∀ᶠ x in F, deriv g x ≠ 0)
    (hf0 : Tendsto f F (𝓝 0)) (hg0 : Tendsto g F (𝓝 0))
    (hdiv : Tendsto (fun x => deriv f x / deriv g x) F l) :
    Tendsto (fun x => f x / g x) F l := by
  rcases hF with rfl | rfl | rfl
  · exact deriv.lhopital_zero_nhdsNE hf hg' hf0 hg0 hdiv
  · exact deriv.lhopital_zero_atTop hf hg' hf0 hg0 hdiv
  · exact deriv.lhopital_zero_atBot hf hg' hf0 hg0 hdiv

/-- L'Hopital's rule, infinity over infinity. Same destinations and conditions as the 0 over 0
case, except that nothing is asked of the top: it is enough that the bottom blows up (its size
|g(x)| grows past every bound). If the rate ratio f'(x)/g'(x) heads for a number L, or for plus
infinity, or for minus infinity, then the ratio f(x)/g(x) heads for the same limit. -/
theorem lhopital_infinity_over_infinity (f g : ℝ → ℝ) (a L : ℝ) (F l : Filter ℝ)
    (hF : F = 𝓝[≠] a ∨ F = atTop ∨ F = atBot)
    (hl : l = 𝓝 L ∨ l = atTop ∨ l = atBot)
    (hf : ∀ᶠ x in F, DifferentiableAt ℝ f x)
    (hg : ∀ᶠ x in F, DifferentiableAt ℝ g x)
    (hg' : ∀ᶠ x in F, deriv g x ≠ 0)
    (hginf : Tendsto (fun x => |g x|) F atTop)
    (hdiv : Tendsto (fun x => deriv f x / deriv g x) F l) :
    Tendsto (fun x => f x / g x) F l := by
  rcases hl with rfl | rfl | rfl
  · rw [tendsto_order] at hdiv ⊢
    refine ⟨fun b hb => ?_, fun b hb => ?_⟩
    · exact lhopital_lower f g a F hF hf hg hg' hginf ((b + L) / 2) b (by linarith)
        (hdiv.1 _ (by linarith))
    · exact lhopital_upper f g a F hF hf hg hg' hginf ((b + L) / 2) b (by linarith)
        (hdiv.2 _ (by linarith))
  · rw [tendsto_atTop] at hdiv ⊢
    intro b
    exact (lhopital_lower f g a F hF hf hg hg' hginf (b + 1 / 2) b (by linarith)
      ((hdiv (b + 1)).mono fun x hx => by linarith)).mono fun x hx => hx.le
  · rw [tendsto_atBot] at hdiv ⊢
    intro b
    exact (lhopital_upper f g a F hF hf hg hg' hginf (b - 1 / 2) b (by linarith)
      ((hdiv (b - 1)).mono fun x hx => by linarith)).mono fun x hx => hx.le

/-- The card's two worked examples. The sine of x over x (x in radians) heads for 1 as x heads
for 0, and x times e^(-x) heads for 0 as x grows: the exponential outruns the line. -/
theorem sin_div_self_tendsto_one_and_mul_exp_neg_tendsto_zero :
    Tendsto (fun x : ℝ => sin x / x) (𝓝[≠] 0) (𝓝 1) ∧
      Tendsto (fun x : ℝ => x * exp (-x)) atTop (𝓝 0) := by
  refine ⟨Real.tendsto_sin_div_nhdsNE_zero, ?_⟩
  simpa using Real.tendsto_pow_mul_exp_neg_atTop_nhds_zero 1

-- The form of sin x / x at 0: top sin 0 = 0 and bottom 0, so 0 over 0; the rate ratio
-- cos x / 1 heads for cos 0 = 1.
example : sin 0 = 0 ∧ cos 0 / 1 = 1 := by norm_num
-- Not 0 over 0: sin x / (x + 1) at 0 has bottom 0 + 1 = 1, while the rates give cos 0 / 1 = 1.
example : (0 : ℝ) + 1 = 1 ∧ cos 0 / 1 = 1 := by norm_num
-- Step 2's tolerance game: for tolerance 1/1000 the safe distance is d = sqrt(2/1000), and the
-- bound c^2/2 at c = d is exactly 1/1000.
example : Real.sqrt (2 / 1000) ^ 2 / 2 = 1 / 1000 := by
  rw [Real.sq_sqrt] <;> norm_num
-- Swinging rates, (x + sin x)/x: the rate ratio 1 + cos x is 2 at x = 20 pi and 0 at x = 21 pi,
-- while the ratio itself is exactly 1 at both points.
example : 1 + cos (20 * π) = 2 ∧ 1 + cos (21 * π) = 0 := by
  constructor
  · rw [show (20 : ℝ) * π = ((10 : ℕ) : ℝ) * (2 * π) by push_cast; ring, cos_nat_mul_two_pi]
    norm_num
  · rw [show (21 : ℝ) * π = π + ((10 : ℕ) : ℝ) * (2 * π) by push_cast; ring,
      cos_add_nat_mul_two_pi, cos_pi]
    norm_num
example : (20 * π + sin (20 * π)) / (20 * π) = 1 ∧ (21 * π + sin (21 * π)) / (21 * π) = 1 := by
  have h20 : sin (20 * π) = 0 := by exact_mod_cast sin_nat_mul_pi 20
  have h21 : sin (21 * π) = 0 := by exact_mod_cast sin_nat_mul_pi 21
  rw [h20, h21, add_zero, add_zero]
  constructor <;> exact div_self (by positivity)

#print axioms lhopital_core_lower
#print axioms lhopital_segment_property
#print axioms lhopital_lower_onesided
#print axioms lhopital_lower
#print axioms lhopital_upper
#print axioms lhopital_zero_over_zero
#print axioms lhopital_infinity_over_infinity
#print axioms sin_div_self_tendsto_one_and_mul_exp_neg_tendsto_zero
