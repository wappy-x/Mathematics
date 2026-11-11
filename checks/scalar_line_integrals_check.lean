-- Line integrals of a function: the piece totals of density times piece length along a wire close in on the integral of density times speed, that integral is the same for every clock that runs the wire once in either direction, and the card's wire y = x^2/2 with density 3x weighs exactly 5√5 − 2√2 kg.
import Mathlib.Topology.EMetricSpace.BoundedVariation
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.IntervalIntegral.IntegrationByParts
import Mathlib.Analysis.Calculus.Deriv.Slope
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Normed.Group.Bounded
import Mathlib.Topology.UniformSpace.HeineCantor
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FieldSimp

open Set Real

lemma sli_hasDerivAt_of_mem_Ioo {f : ℝ → ℝ} {a b t : ℝ} (hf : ContDiffOn ℝ 1 f (Icc a b))
    (ht : t ∈ Ioo a b) : HasDerivAt f (derivWithin f (Icc a b) t) t := by
  have hn : Icc a b ∈ nhds t := Icc_mem_nhds ht.1 ht.2
  rw [derivWithin_of_mem_nhds hn]
  exact (((hf.differentiableOn one_ne_zero) t (Ioo_subset_Icc_self ht)).differentiableAt
    hn).hasDerivAt

#print axioms sli_hasDerivAt_of_mem_Ioo

lemma sli_integral_congr_Ioo {f g : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b) (h : EqOn f g (Ioo a b)) :
    ∫ t in a..b, f t = ∫ t in a..b, g t := by
  rw [intervalIntegral.integral_of_le hab, intervalIntegral.integral_of_le hab,
    MeasureTheory.integral_Ioc_eq_integral_Ioo, MeasureTheory.integral_Ioc_eq_integral_Ioo]
  exact MeasureTheory.setIntegral_congr_fun measurableSet_Ioo h

#print axioms sli_integral_congr_Ioo

lemma sli_mono {t : ℕ → ℝ} {n : ℕ} (h : ∀ i < n, t i < t (i + 1)) :
    ∀ i j, i ≤ j → j ≤ n → t i ≤ t j := by
  intro i j hij hjn
  induction j with
  | zero => obtain rfl : i = 0 := by omega
            exact le_rfl
  | succ j ih =>
    rcases Nat.eq_or_lt_of_le hij with h' | h'
    · rw [h']
    · exact (ih (by omega) (by omega)).trans (h j (by omega)).le

#print axioms sli_mono

lemma sli_piece {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] {γ γ' : ℝ → E}
    {p q η : ℝ} (hpq : p ≤ q)
    (hγ : ∀ s ∈ Icc p q, HasDerivWithinAt γ (γ' s) (Icc p q) s)
    (hη : ∀ s ∈ Icc p q, ‖γ' s - γ' p‖ ≤ η) :
    |(eVariationOn γ (Icc p q)).toReal - (q - p) * ‖γ' p‖| ≤ η * (q - p) := by
  have hp : p ∈ Icc p q := left_mem_Icc.2 hpq
  have hq : q ∈ Icc p q := right_mem_Icc.2 hpq
  have hη0 : 0 ≤ η := by simpa using hη p hp
  set K : NNReal := ⟨‖γ' p‖ + η, by positivity⟩ with hK
  have hlip : LipschitzOnWith K γ (Icc p q) := LipschitzOnWith.of_dist_le_mul fun s hs r hr => by
    rw [dist_eq_norm, dist_eq_norm]
    refine Convex.norm_image_sub_le_of_norm_hasDerivWithin_le hγ (fun u hu => ?_) (convex_Icc p q) hr hs
    have := norm_sub_norm_le (γ' u) (γ' p)
    have := hη u hu
    show ‖γ' u‖ ≤ ‖γ' p‖ + η
    linarith
  have hup : eVariationOn γ (Icc p q) ≤ K * ENNReal.ofReal (q - p) := by
    have := hlip.comp_eVariationOn_le (g := id) (s := Icc p q) (mapsTo_id _)
    simpa using this
  have hfin : eVariationOn γ (Icc p q) ≠ ⊤ :=
    ne_top_of_le_ne_top (ENNReal.mul_ne_top ENNReal.coe_ne_top ENNReal.ofReal_ne_top) hup
  have hup' : (eVariationOn γ (Icc p q)).toReal ≤ (‖γ' p‖ + η) * (q - p) := by
    have := ENNReal.toReal_mono (ENNReal.mul_ne_top ENNReal.coe_ne_top ENNReal.ofReal_ne_top) hup
    rwa [ENNReal.toReal_mul, ENNReal.coe_toReal, ENNReal.toReal_ofReal (sub_nonneg.2 hpq)] at this
  have hlow : dist (γ p) (γ q) ≤ (eVariationOn γ (Icc p q)).toReal := by
    have h := eVariationOn.edist_le γ hp hq
    rw [edist_dist] at h
    have := ENNReal.toReal_mono hfin h
    rwa [ENNReal.toReal_ofReal dist_nonneg] at this
  have hmvt : ‖(γ q - q • γ' p) - (γ p - p • γ' p)‖ ≤ η * ‖q - p‖ :=
    Convex.norm_image_sub_le_of_norm_hasDerivWithin_le (f := fun s => γ s - s • γ' p)
      (f' := fun s => γ' s - γ' p)
      (fun s hs => by
        have h := (hγ s hs).sub ((hasDerivWithinAt_id s _).smul_const (γ' p))
        simp only [one_smul] at h
        exact h)
      (fun s hs => hη s hs) (convex_Icc p q) hp hq
  have heq : (γ q - q • γ' p) - (γ p - p • γ' p) = (γ q - γ p) - (q - p) • γ' p := by
    rw [sub_smul]; abel
  rw [heq, Real.norm_eq_abs, abs_of_nonneg (sub_nonneg.2 hpq)] at hmvt
  have h3 : (q - p) * ‖γ' p‖ - ‖γ q - γ p‖ ≤ ‖(γ q - γ p) - (q - p) • γ' p‖ := by
    have := norm_sub_norm_le ((q - p) • γ' p) (γ q - γ p)
    rw [norm_sub_rev ((q - p) • γ' p)] at this
    rwa [norm_smul, Real.norm_eq_abs, abs_of_nonneg (sub_nonneg.2 hpq)] at this
  rw [dist_eq_norm, norm_sub_rev] at hlow
  rw [abs_le]; constructor <;> nlinarith

#print axioms sli_piece

lemma sli_sqrt_scale (A B p : ℝ) : √((A * p) ^ 2 + (B * p) ^ 2) = √(A ^ 2 + B ^ 2) * |p| := by
  rw [show (A * p) ^ 2 + (B * p) ^ 2 = (A ^ 2 + B ^ 2) * p ^ 2 by ring,
    Real.sqrt_mul (by positivity), Real.sqrt_sq_eq_abs]

#print axioms sli_sqrt_scale

/-- **The mass of a wire is the integral of density times speed.** A clock runs a wire once:
at clock time t, from a to b, it has reached the point (x(t), y(t)). The wire has no jumps and
the clock's rates x'(t), y'(t) change without jumps (x and y are continuously differentiable on
[a, b]); the clock runs the wire once (no point is reached twice); and the density ρ changes
without jumps along the wire. Cut the clock at a = t₀ < t₁ < … < tₙ = b, pick a clock time τᵢ
in each step [tᵢ, tᵢ₊₁], and add density at the point reached at τᵢ times the length of that
piece of wire. A piece's length is its true length along the wire: the least upper bound of
its chord totals (Mathlib's `eVariationOn`). As the pieces shrink, these totals close in on
∫ from a to b of ρ(x(t), y(t)) · √(x'(t)^2 + y'(t)^2) dt, whichever points are picked: for every
ε > 0 there is a δ > 0 such that every cut with all steps shorter than δ gives a total within
ε of that integral. The density may take either sign. -/
theorem wire_mass_eq_integral_density_mul_speed {x y : ℝ → ℝ} {ρ : ℝ × ℝ → ℝ} {a b : ℝ}
    (hab : a ≤ b)
    (hx : ContDiffOn ℝ 1 x (Icc a b)) (hy : ContDiffOn ℝ 1 y (Icc a b))
    (honce : InjOn (fun t => (x t, y t)) (Icc a b))
    (hρ : ContinuousOn ρ ((fun t => (x t, y t)) '' Icc a b)) :
    ∀ ε > 0, ∃ δ > 0, ∀ (n : ℕ) (t τ : ℕ → ℝ),
      t 0 = a → t n = b → (∀ i < n, t i < t (i + 1) ∧ t (i + 1) - t i < δ) →
      (∀ i < n, τ i ∈ Icc (t i) (t (i + 1))) →
      |∑ i ∈ Finset.range n,
          ρ (x (τ i), y (τ i)) *
            (eVariationOn (fun s => !₂[x s, y s]) (Icc (t i) (t (i + 1)))).toReal -
        ∫ s in a..b, ρ (x s, y s) * √(deriv x s ^ 2 + deriv y s ^ 2)| < ε := by
  intro ε hε
  rcases hab.eq_or_lt with hab' | hab'
  · refine ⟨1, one_pos, fun n t τ h0 hn hstep _ => ?_⟩
    have hmono := sli_mono (fun i hi => (hstep i hi).1)
    obtain rfl : n = 0 := by
      by_contra hne
      have h1 := (hstep 0 (Nat.pos_of_ne_zero hne)).1
      have h2 := hmono 1 n (by omega) le_rfl
      linarith
    simpa [hab'] using hε
  have hXc : ContinuousOn (derivWithin x (Icc a b)) (Icc a b) :=
    hx.continuousOn_derivWithin (uniqueDiffOn_Icc hab') le_rfl
  have hYc : ContinuousOn (derivWithin y (Icc a b)) (Icc a b) :=
    hy.continuousOn_derivWithin (uniqueDiffOn_Icc hab') le_rfl
  set X := derivWithin x (Icc a b) with hXdef
  set Y := derivWithin y (Icc a b) with hYdef
  set e0 : EuclideanSpace ℝ (Fin 2) := EuclideanSpace.single 0 1 with he0
  set e1 : EuclideanSpace ℝ (Fin 2) := EuclideanSpace.single 1 1 with he1
  have hγeq : (fun s => !₂[x s, y s]) = fun s => x s • e0 + y s • e1 := by
    funext s; ext i; fin_cases i <;> simp [e0, e1]
  set γ' : ℝ → EuclideanSpace ℝ (Fin 2) := fun s => X s • e0 + Y s • e1 with hγ'def
  have hγ'norm : ∀ s, ‖γ' s‖ = √(X s ^ 2 + Y s ^ 2) := by
    intro s; simp [γ', e0, e1, EuclideanSpace.norm_eq, Fin.sum_univ_two]
  have hγd : ∀ s ∈ Icc a b,
      HasDerivWithinAt (fun s => !₂[x s, y s]) (γ' s) (Icc a b) s := by
    intro s hs; rw [hγeq]
    exact (((hx.differentiableOn one_ne_zero) s hs).hasDerivWithinAt.smul_const e0).add
      (((hy.differentiableOn one_ne_zero) s hs).hasDerivWithinAt.smul_const e1)
  have hγ'c : ContinuousOn γ' (Icc a b) :=
    (hXc.smul continuousOn_const).add (hYc.smul continuousOn_const)
  set R : ℝ → ℝ := fun s => ρ (x s, y s) with hRdef
  have hRc : ContinuousOn R (Icc a b) :=
    hρ.comp (hx.continuousOn.prodMk hy.continuousOn) (mapsTo_image _ _)
  set S : ℝ → ℝ := fun s => √(X s ^ 2 + Y s ^ 2) with hSdef
  have hSc : ContinuousOn S (Icc a b) := ((hXc.pow 2).add (hYc.pow 2)).sqrt
  set F : ℝ → ℝ := fun s => R s * S s with hFdef
  have hFc : ContinuousOn F (Icc a b) := hRc.mul hSc
  have hint : ∫ s in a..b, ρ (x s, y s) * √(deriv x s ^ 2 + deriv y s ^ 2) =
      ∫ s in a..b, F s := by
    refine sli_integral_congr_Ioo hab fun s hs => ?_
    rw [(sli_hasDerivAt_of_mem_Ioo hx hs).deriv, (sli_hasDerivAt_of_mem_Ioo hy hs).deriv]
  obtain ⟨M, hM⟩ := isCompact_Icc.exists_bound_of_continuousOn hRc
  set M1 := |M| + 1 with hM1def
  have hM1 : 0 < M1 := by positivity
  have hRb : ∀ s ∈ Icc a b, |R s| ≤ M1 := fun s hs => by
    have := hM s hs
    rw [Real.norm_eq_abs] at this
    linarith [le_abs_self M]
  have hba : 0 < b - a := sub_pos.2 hab'
  set η := ε / (4 * M1 * (b - a)) with hηdef
  set η' := ε / (4 * (b - a)) with hη'def
  have hη : 0 < η := by positivity
  have hη' : 0 < η' := by positivity
  obtain ⟨δ1, hδ1, h1⟩ := Metric.uniformContinuousOn_iff.1
    (isCompact_Icc.uniformContinuousOn_of_continuous hγ'c) η hη
  have hHc : ContinuousOn (fun z : ℝ × ℝ => R z.1 * S z.2) (Icc a b ×ˢ Icc a b) :=
    (hRc.comp continuousOn_fst (fun (z : ℝ × ℝ) (hz : z ∈ Icc a b ×ˢ Icc a b) => hz.1)).mul
      (hSc.comp continuousOn_snd (fun (z : ℝ × ℝ) (hz : z ∈ Icc a b ×ˢ Icc a b) => hz.2))
  obtain ⟨δ2, hδ2, h2⟩ := Metric.uniformContinuousOn_iff.1
    ((isCompact_Icc.prod isCompact_Icc).uniformContinuousOn_of_continuous hHc) η' hη'
  refine ⟨min δ1 δ2, lt_min hδ1 hδ2, fun n t τ h0 hn hstep hτ => ?_⟩
  have hmono := sli_mono (fun i hi => (hstep i hi).1)
  have hmem : ∀ i ≤ n, t i ∈ Icc a b := fun i hi =>
    ⟨h0 ▸ hmono 0 i (Nat.zero_le _) hi, hn ▸ hmono i n hi le_rfl⟩
  have hpiece : ∀ i < n, |R (τ i) *
      (eVariationOn (fun s => !₂[x s, y s]) (Icc (t i) (t (i + 1)))).toReal -
        ∫ s in t i..t (i + 1), F s| ≤ (M1 * η + η') * (t (i + 1) - t i) := by
    intro i hi
    have hp := hmem i hi.le
    have hq := hmem (i + 1) hi
    have hpq : t i < t (i + 1) := (hstep i hi).1
    have hqp : t (i + 1) - t i < min δ1 δ2 := (hstep i hi).2
    have hsub : Icc (t i) (t (i + 1)) ⊆ Icc a b := Icc_subset_Icc hp.1 hq.2
    have hτi := hτ i hi
    set p := t i
    set q := t (i + 1)
    set L := (eVariationOn (fun s => !₂[x s, y s]) (Icc p q)).toReal
    have hA : |L - (q - p) * ‖γ' p‖| ≤ η * (q - p) :=
      sli_piece hpq.le (fun s hs => (hγd s (hsub hs)).mono hsub) (fun s hs => by
        have := h1 s (hsub hs) p hp (by
          rw [Real.dist_eq, abs_of_nonneg (by linarith [hs.1])]
          linarith [hs.2, min_le_left δ1 δ2])
        rw [dist_eq_norm] at this; exact this.le)
    rw [hγ'norm] at hA
    have hB : |∫ s in p..q, (R (τ i) * S p - F s)| ≤ η' * (q - p) := by
      have := intervalIntegral.norm_integral_le_of_norm_le_const (a := p) (b := q) (C := η')
        (f := fun s => R (τ i) * S p - F s) (fun s hs => ?_)
      · rwa [Real.norm_eq_abs, abs_of_pos (sub_pos.2 hpq)] at this
      · rw [uIoc_of_le hpq.le] at hs
        have hsI : s ∈ Icc a b := hsub ⟨hs.1.le, hs.2⟩
        have := h2 (τ i, p) ⟨hsub hτi, hp⟩ (s, s) ⟨hsI, hsI⟩ ?_
        · rw [Real.dist_eq] at this; exact this.le
        · rw [Prod.dist_eq, Real.dist_eq, Real.dist_eq, max_lt_iff]
          constructor <;> rw [abs_lt] <;> constructor <;>
            linarith [hτi.1, hτi.2, hs.1, hs.2, min_le_right δ1 δ2]
    have hFi : IntervalIntegrable F MeasureTheory.volume p q :=
      (hFc.mono (by rw [uIcc_of_le hpq.le]; exact hsub)).intervalIntegrable
    have hsplit : ∫ s in p..q, (R (τ i) * S p - F s) =
        (q - p) * (R (τ i) * S p) - ∫ s in p..q, F s := by
      rw [intervalIntegral.integral_sub intervalIntegrable_const hFi,
        intervalIntegral.integral_const, smul_eq_mul]
    rw [hsplit] at hB
    have hRt : |R (τ i)| ≤ M1 := hRb _ (hsub hτi)
    have key : R (τ i) * L - ∫ s in p..q, F s = R (τ i) * (L - (q - p) * S p) +
        ((q - p) * (R (τ i) * S p) - ∫ s in p..q, F s) := by ring
    rw [key]
    calc _ ≤ |R (τ i) * (L - (q - p) * S p)| +
          |(q - p) * (R (τ i) * S p) - ∫ s in p..q, F s| := abs_add_le _ _
      _ ≤ M1 * (η * (q - p)) + η' * (q - p) := by
          gcongr
          rw [abs_mul]; exact mul_le_mul hRt hA (abs_nonneg _) hM1.le
      _ = _ := by ring
  have hsumint : ∑ i ∈ Finset.range n, ∫ s in t i..t (i + 1), F s = ∫ s in a..b, F s := by
    rw [intervalIntegral.sum_integral_adjacent_intervals, h0, hn]
    intro k hk
    exact (hFc.mono (by
      rw [uIcc_of_le (hstep k hk).1.le]
      exact Icc_subset_Icc (hmem k hk.le).1 (hmem (k + 1) hk).2)).intervalIntegrable
  rw [hint, ← hsumint, ← Finset.sum_sub_distrib]
  refine (Finset.abs_sum_le_sum_abs _ _).trans_lt ?_
  calc _ ≤ ∑ i ∈ Finset.range n, (M1 * η + η') * (t (i + 1) - t i) :=
        Finset.sum_le_sum fun i hi => hpiece i (Finset.mem_range.1 hi)
    _ = (M1 * η + η') * (b - a) := by
        rw [← Finset.mul_sum, Finset.sum_range_sub (fun i => t i), h0, hn]
    _ < ε := by
        have e1 : M1 * η * (b - a) = ε / 4 := by
          rw [hηdef]; field_simp
        have e2 : η' * (b - a) = ε / 4 := by
          rw [hη'def]; field_simp
        nlinarith

/-- **Any clock that runs the wire once, in either direction, gives the same mass.** Keep the
wire, clock and density of the main theorem. A new clock u runs from c to d, and the old clock
reads φ(u) when the new one reads u, so the new clock reaches the point (x(φ(u)), y(φ(u))).
Its rate φ' changes without jumps (φ is continuously differentiable on [c, d]), and it runs the
wire once: either φ rises strictly from a to b (same direction), or it falls strictly from b to
a (the far end first). Then density times the new clock's speed, integrated over the new clock,
equals density times the old clock's speed, integrated over the old clock. -/
theorem integral_density_mul_speed_indep_of_clock {x y φ : ℝ → ℝ} {ρ : ℝ × ℝ → ℝ}
    {a b c d : ℝ} (hab : a ≤ b) (hcd : c ≤ d)
    (hx : ContDiffOn ℝ 1 x (Icc a b)) (hy : ContDiffOn ℝ 1 y (Icc a b))
    (honce : InjOn (fun t => (x t, y t)) (Icc a b))
    (hρ : ContinuousOn ρ ((fun t => (x t, y t)) '' Icc a b))
    (hφ : ContDiffOn ℝ 1 φ (Icc c d))
    (hrun : (StrictMonoOn φ (Icc c d) ∧ φ c = a ∧ φ d = b) ∨
      (StrictAntiOn φ (Icc c d) ∧ φ c = b ∧ φ d = a)) :
    ∫ u in c..d, ρ (x (φ u), y (φ u)) * √(deriv (x ∘ φ) u ^ 2 + deriv (y ∘ φ) u ^ 2) =
      ∫ t in a..b, ρ (x t, y t) * √(deriv x t ^ 2 + deriv y t ^ 2) := by
  set X := derivWithin x (Icc a b)
  set Y := derivWithin y (Icc a b)
  set P := derivWithin φ (Icc c d)
  set G : ℝ → ℝ := fun t => ρ (x t, y t) * √(X t ^ 2 + Y t ^ 2) with hGdef
  have hR : ∫ t in a..b, ρ (x t, y t) * √(deriv x t ^ 2 + deriv y t ^ 2) = ∫ t in a..b, G t := by
    refine sli_integral_congr_Ioo hab fun t ht => ?_
    rw [(sli_hasDerivAt_of_mem_Ioo hx ht).deriv, (sli_hasDerivAt_of_mem_Ioo hy ht).deriv]
  rw [hR]
  have hP : ∀ u ∈ Ioo (min c d) (max c d), HasDerivAt φ (P u) u := by
    rw [min_eq_left hcd, max_eq_right hcd]
    exact fun u hu => sli_hasDerivAt_of_mem_Ioo hφ hu
  have hφc : ContinuousOn φ (uIcc c d) := by
    rw [uIcc_of_le hcd]; exact hφ.continuousOn
  have hin : (∀ u ∈ Ioo c d, φ u ∈ Ioo a b) := by
    intro u hu
    have huI : u ∈ Icc c d := Ioo_subset_Icc_self hu
    rcases hrun with ⟨hm, h1, h2⟩ | ⟨hm, h1, h2⟩
    · exact ⟨h1 ▸ hm (left_mem_Icc.2 hcd) huI hu.1, h2 ▸ hm huI (right_mem_Icc.2 hcd) hu.2⟩
    · exact ⟨h2 ▸ hm huI (right_mem_Icc.2 hcd) hu.2, h1 ▸ hm (left_mem_Icc.2 hcd) huI hu.1⟩
  have hL : ∀ u ∈ Ioo c d, ρ (x (φ u), y (φ u)) * √(deriv (x ∘ φ) u ^ 2 + deriv (y ∘ φ) u ^ 2)
      = G (φ u) * |P u| := by
    intro u hu
    have hPu := sli_hasDerivAt_of_mem_Ioo hφ hu
    rw [((sli_hasDerivAt_of_mem_Ioo hx (hin u hu)).comp u hPu).deriv,
      ((sli_hasDerivAt_of_mem_Ioo hy (hin u hu)).comp u hPu).deriv, sli_sqrt_scale]
    simp only [G]; ring
  rcases hrun with ⟨hm, h1, h2⟩ | ⟨hm, h1, h2⟩
  · have hnn : ∀ u, 0 ≤ P u := fun u => hm.monotoneOn.derivWithin_nonneg
    rw [sli_integral_congr_Ioo hcd (g := fun u => (G ∘ φ) u * P u) (fun u hu => by
      rw [hL u hu, abs_of_nonneg (hnn u)]; rfl)]
    rw [intervalIntegral.integral_comp_mul_deriv_of_deriv_nonneg hφc hP (fun u _ => hnn u), h1, h2]
  · have hnp : ∀ u, P u ≤ 0 := fun u => hm.antitoneOn.derivWithin_nonpos
    rw [sli_integral_congr_Ioo hcd (g := fun u => -((G ∘ φ) u * P u)) (fun u hu => by
      rw [hL u hu, abs_of_nonpos (hnp u)]; simp only [Function.comp]; ring)]
    rw [intervalIntegral.integral_neg,
      intervalIntegral.integral_comp_mul_deriv_of_deriv_nonpos hφc hP (fun u _ => hnp u), h1, h2,
      intervalIntegral.integral_symm, neg_neg]

/-- **The card's wire.** The wire follows y = x^2/2 from x = 1 to x = 2 m, run by the clock
x = t, y = t^2/2 for t from 1 to 2. Its density at the point (x, y) is 3x kg/m. Density times
speed, integrated over the clock, is exactly 5^(3/2) − 2^(3/2) = 5√5 − 2√2 kg, about
8.351913 kg. -/
theorem card_wire_mass :
    ∫ t in (1 : ℝ)..2, (fun p : ℝ × ℝ => 3 * p.1) (t, t ^ 2 / 2) *
        √(deriv (fun s : ℝ => s) t ^ 2 + deriv (fun s : ℝ => s ^ 2 / 2) t ^ 2) =
      5 * √5 - 2 * √2 := by
  have hd : ∀ t : ℝ, deriv (fun s : ℝ => s ^ 2 / 2) t = t := by
    intro t
    have : HasDerivAt (fun s : ℝ => s ^ 2 / 2) ((2 * t ^ 1) / 2) t :=
      (hasDerivAt_pow 2 t).div_const 2
    rw [this.deriv]; ring
  simp only [deriv_id'', hd, one_pow]
  have hF : ∀ t : ℝ, HasDerivAt (fun s : ℝ => (1 + s ^ 2) * √(1 + s ^ 2))
      (3 * t * √(1 + t ^ 2)) t := by
    intro t
    have h1 : HasDerivAt (fun s : ℝ => 1 + s ^ 2) (2 * t) t := by
      simpa using ((hasDerivAt_pow 2 t).const_add 1)
    have hpos : (0 : ℝ) < 1 + t ^ 2 := by positivity
    have h2 := h1.mul (h1.sqrt hpos.ne')
    convert h2 using 1
    have hs : 0 < √(1 + t ^ 2) := Real.sqrt_pos.2 hpos
    field_simp
    rw [Real.sq_sqrt hpos.le]; ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun t _ => hF t)
    (by apply Continuous.intervalIntegrable; fun_prop)]
  norm_num

-- Density 3x at the two ends of the wire: 3 kg/m at x = 1, 6 kg/m at x = 2.
example : (3 : ℚ) * 1 = 3 ∧ (3 : ℚ) * 2 = 6 := by norm_num
-- The ends of the wire: y = 1^2/2 = 1/2 m at x = 1 and y = 2^2/2 = 2 m at x = 2.
example : (1 : ℚ) ^ 2 / 2 = 1 / 2 ∧ (2 : ℚ) ^ 2 / 2 = 2 := by norm_num
-- The antiderivative (1 + t^2)^(3/2) at the ends: 1 + 2^2 = 5 and 1 + 1^2 = 2, so the mass
-- is 5^(3/2) − 2^(3/2), and 5^3 = 125, 2^3 = 8 are the squares of 5√5 and 2√2.
example : (1 : ℚ) + 2 ^ 2 = 5 ∧ (1 : ℚ) + 1 ^ 2 = 2 ∧ (5 : ℚ) ^ 2 * 5 = 5 ^ 3 ∧ (2 : ℚ) ^ 2 * 2 = 2 ^ 3 := by
  norm_num
-- The chain rule check on the antiderivative: (3/2) · 2t = 3t.
example : ∀ t : ℚ, 3 / 2 * (2 * t) = 3 * t := by intro t; ring
-- Mistake, drop the speed: ∫ from 1 to 2 of 3x dx = 3 · (2^2 − 1^2)/2 = 4.5 kg.
example : (3 : ℚ) * (2 ^ 2 - 1 ^ 2) / 2 = 9 / 2 := by norm_num
-- The average of the end densities, (3 + 6)/2 = 4.5 kg/m.
example : ((3 : ℚ) + 6) / 2 = 9 / 2 := by norm_num
-- The clock x = √u runs u from 1 to 4: √1 = 1 and √4 = 2, the two ends of the wire.
example : (1 : ℚ) ^ 2 = 1 ∧ (2 : ℚ) ^ 2 = 4 := by norm_num
-- On that clock y = u/2, so the rates are 1/(2√u) and 1/2, and the speed squared is
-- 1/(4u) + 1/4 = (1 + u)/(4u).
example : ∀ u : ℚ, u ≠ 0 → 1 / (4 * u) + 1 / 4 = (1 + u) / (4 * u) := by
  intro u hu; field_simp
-- The reversed clock x = 3 − s, s from 1 to 2, starts at the far end x = 2 and ends at x = 1;
-- its rate is −1, and (−1)^2 = 1, so its speed is the same as before.
example : (3 : ℚ) - 1 = 2 ∧ (3 : ℚ) - 2 = 1 ∧ (-1 : ℚ) ^ 2 = 1 := by norm_num

#print axioms wire_mass_eq_integral_density_mul_speed
#print axioms integral_density_mul_speed_indep_of_clock
#print axioms card_wire_mass
