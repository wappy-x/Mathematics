-- The energy inequality, and the gap it leaves in three dimensions: a smooth incompressible flow in a repeating box loses kinetic energy only to friction, a spin that grows at most like its cube stays below y₀/√(1 − t/T*), and that curve has a finite total but an unbounded total square.
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.MeasureTheory.Constructions.Pi
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Integral.DivergenceTheorem
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.ContDiff.Operations
import Mathlib.Analysis.Calculus.FDeriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Tactic.LinearCombination

open Real Set MeasureTheory

theorem insertNth_L_eq (L : ℝ) (i : Fin 3) (x : Fin 2 → ℝ) :
    Fin.insertNth i L x = Fin.insertNth i (0 : ℝ) x + L • Pi.single i 1 := by
  funext j
  refine Fin.succAboveCases i ?_ ?_ j
  · simp
  · intro k
    simp [Fin.insertNth_apply_succAbove, Fin.succAbove_ne]

theorem periodic_box_div_integral_zero (L : ℝ) (hL : 0 < L)
    (f : Fin 3 → (Fin 3 → ℝ) → ℝ) (hf : ∀ i, ContDiff ℝ 1 (f i))
    (hper : ∀ i x, f i (x + L • Pi.single i 1) = f i x) :
    ∫ x in Icc (0 : Fin 3 → ℝ) (fun _ => L), ∑ i, fderiv ℝ (f i) x (Pi.single i 1) = 0 := by
  rw [integral_divergence_of_hasFDerivAt_off_countable' (n := 2) (0 : Fin 3 → ℝ) (fun _ => L)
    (fun i => le_of_lt hL) f (fun i x => fderiv ℝ (f i) x) ∅ countable_empty
    (fun i => (hf i).continuous.continuousOn)
    (fun x _ i => ((hf i).differentiable one_ne_zero x).hasFDerivAt)]
  · apply Finset.sum_eq_zero
    intro i _
    rw [sub_eq_zero]
    apply integral_congr_ae
    filter_upwards with x
    simp only [Pi.zero_apply]
    rw [insertNth_L_eq, hper]
  · apply Continuous.integrableOn_Icc
    apply continuous_finsetSum
    intro i _
    exact ((hf i).continuous_fderiv one_ne_zero).clm_apply continuous_const

theorem periodic_flow_energy_rate (ν L : ℝ) (hL : 0 < L)
    (v : (Fin 3 → ℝ) → (Fin 3 → ℝ)) (P : (Fin 3 → ℝ) → ℝ) (w : (Fin 3 → ℝ) → Fin 3 → ℝ)
    (hv : ContDiff ℝ 2 v) (hP : ContDiff ℝ 1 P)
    (hv_per : ∀ x : Fin 3 → ℝ, ∀ j : Fin 3, v (x + L • Pi.single j 1) = v x)
    (hP_per : ∀ x : Fin 3 → ℝ, ∀ j : Fin 3, P (x + L • Pi.single j 1) = P x)
    (h_div : ∀ x : Fin 3 → ℝ, ∑ i : Fin 3, fderiv ℝ (fun z => v z i) x (Pi.single i 1) = 0)
    (h_ns : ∀ x : Fin 3 → ℝ, ∀ i : Fin 3,
      w x i + ∑ j : Fin 3, v x j * fderiv ℝ (fun z => v z i) x (Pi.single j 1)
        = -fderiv ℝ P x (Pi.single i 1)
          + ν * ∑ j : Fin 3,
              fderiv ℝ (fun w => fderiv ℝ (fun z => v z i) w (Pi.single j 1)) x
                (Pi.single j 1)) :
    ∫ x in Icc (0 : Fin 3 → ℝ) (fun _ => L), ∑ i : Fin 3, v x i * w x i
      = -ν * ∫ x in Icc (0 : Fin 3 → ℝ) (fun _ => L),
          ∑ i : Fin 3, ∑ j : Fin 3, (fderiv ℝ (fun z => v z i) x (Pi.single j 1)) ^ 2 := by
  have hvi : ∀ i, ContDiff ℝ 2 (fun z => v z i) := fun i => contDiff_pi.1 hv i
  have hvi1 : ∀ i, ContDiff ℝ 1 (fun z => v z i) := fun i => (hvi i).of_le (by norm_num)
  have hg : ∀ i j, ContDiff ℝ 1 (fun w => fderiv ℝ (fun z => v z i) w (Pi.single j 1)) := by
    intro i j
    exact ((hvi i).fderiv_right (m := 1) (by norm_num)).clm_apply contDiff_const
  set F : Fin 3 → (Fin 3 → ℝ) → ℝ := fun j z =>
    (1 / 2) * (v z j * ∑ i : Fin 3, v z i * v z i) + P z * v z j
      - ν * ∑ i : Fin 3, v z i * fderiv ℝ (fun z => v z i) z (Pi.single j 1) with hF
  have hFc : ∀ j, ContDiff ℝ 1 (F j) := by
    intro j
    simp only [hF]
    apply ContDiff.sub
    · apply ContDiff.add
      · apply contDiff_const.mul
        apply (hvi1 j).mul
        exact ContDiff.sum fun i _ => (hvi1 i).mul (hvi1 i)
      · exact hP.mul (hvi1 j)
    · apply contDiff_const.mul
      exact ContDiff.sum fun i _ => (hvi1 i).mul (hg i j)
  have hFper : ∀ j x, F j (x + L • Pi.single j 1) = F j x := by
    intro j x
    have hgper : ∀ i k, fderiv ℝ (fun z => v z i) (x + L • Pi.single j 1) (Pi.single k 1)
        = fderiv ℝ (fun z => v z i) x (Pi.single k 1) := by
      intro i k
      rw [← fderiv_comp_add_right]
      congr 2
      funext z
      rw [hv_per]
    simp only [hF, hv_per, hP_per, hgper]
  have hdivF := periodic_box_div_integral_zero L hL F hFc hFper
  -- pointwise identity
  have hpt : ∀ x, ∑ i : Fin 3, v x i * w x i
      = -(∑ j, fderiv ℝ (F j) x (Pi.single j 1))
        - ν * ∑ i : Fin 3, ∑ j : Fin 3, (fderiv ℝ (fun z => v z i) x (Pi.single j 1)) ^ 2 := by
    intro x
    have dv : ∀ i, HasFDerivAt (fun z => v z i) (fderiv ℝ (fun z => v z i) x) x :=
      fun i => ((hvi1 i).differentiable one_ne_zero x).hasFDerivAt
    have dg : ∀ i j, HasFDerivAt (fun w => fderiv ℝ (fun z => v z i) w (Pi.single j 1))
        (fderiv ℝ (fun w => fderiv ℝ (fun z => v z i) w (Pi.single j 1)) x) x :=
      fun i j => ((hg i j).differentiable one_ne_zero x).hasFDerivAt
    have dP : HasFDerivAt P (fderiv ℝ P x) x := (hP.differentiable one_ne_zero x).hasFDerivAt
    have dF : ∀ j, HasFDerivAt (F j) ((1 / 2 : ℝ) • (v x j • (∑ i : Fin 3, (v x i • fderiv ℝ (fun z => v z i) x
        + v x i • fderiv ℝ (fun z => v z i) x)) + (∑ i : Fin 3, v x i * v x i) • fderiv ℝ (fun z => v z j) x)
        + (P x • fderiv ℝ (fun z => v z j) x + v x j • fderiv ℝ P x)
        - ν • ∑ i : Fin 3, (v x i • fderiv ℝ (fun w => fderiv ℝ (fun z => v z i) w (Pi.single j 1)) x
          + fderiv ℝ (fun z => v z i) x (Pi.single j 1) • fderiv ℝ (fun z => v z i) x)) x := by
      intro j
      simp only [hF]
      exact (((dv j).mul (HasFDerivAt.sum (u := Finset.univ) fun i _ => (dv i).mul (dv i))).const_mul (1 / 2)
        |>.add (dP.mul (dv j))).sub
        ((HasFDerivAt.sum (u := Finset.univ) fun i _ => (dv i).mul (dg i j)).const_mul ν)
    simp only [fun j => (dF j).fderiv]
    simp only [ContinuousLinearMap.add_apply, ContinuousLinearMap.sub_apply,
      ContinuousLinearMap.smul_apply,
      smul_eq_mul, Fin.sum_univ_three] 
    have h0 := h_ns x 0
    have h1 := h_ns x 1
    have h2 := h_ns x 2
    have hd := h_div x
    simp only [Fin.sum_univ_three] at h0 h1 h2 hd
    linear_combination (v x 0 * h0 + v x 1 * h1 + v x 2 * h2
      + ((1 / 2) * (v x 0 * v x 0 + v x 1 * v x 1 + v x 2 * v x 2) + P x) * hd)
  have hint1 : IntegrableOn (fun x => ∑ j, fderiv ℝ (F j) x (Pi.single j 1))
      (Icc (0 : Fin 3 → ℝ) (fun _ => L)) := by
    apply Continuous.integrableOn_Icc
    exact continuous_finsetSum _ fun j _ =>
      ((hFc j).continuous_fderiv one_ne_zero).clm_apply continuous_const
  have hint2 : IntegrableOn (fun x => ∑ i : Fin 3, ∑ j : Fin 3,
      (fderiv ℝ (fun z => v z i) x (Pi.single j 1)) ^ 2) (Icc (0 : Fin 3 → ℝ) (fun _ => L)) := by
    apply Continuous.integrableOn_Icc
    exact continuous_finsetSum _ fun i _ => continuous_finsetSum _ fun j _ =>
      ((hg i j).continuous).pow 2
  simp_rw [hpt]
  rw [integral_sub, integral_neg, hdivF, integral_const_mul]
  · ring
  · exact hint1.neg
  · exact hint2.const_mul ν

theorem blowup_curve_hasDerivAt (K ν y₀ Tstar : ℝ) (hK : 0 < K) (hν : 0 < ν)
    (hy₀ : 0 < y₀) (hT : Tstar = ν ^ 3 / (2 * K * y₀ ^ 2)) (t : ℝ) (ht : t < Tstar) :
    HasDerivAt (fun s => y₀ / √(1 - s / Tstar)) (K / ν ^ 3 * (y₀ / √(1 - t / Tstar)) ^ 3) t := by
  have hTp : 0 < Tstar := by rw [hT]; positivity
  have hw : 0 < 1 - t / Tstar := by
    have : t / Tstar < 1 := by rw [div_lt_one hTp]; exact ht
    linarith
  have h2 : HasDerivAt (fun s : ℝ => 1 - s / Tstar) (-(1 / Tstar)) t := by
    simpa using ((hasDerivAt_id t).div_const Tstar).const_sub 1
  have h3 := (h2.sqrt hw.ne')
  have hr : 0 < √(1 - t / Tstar) := Real.sqrt_pos.2 hw
  have h4 := (hasDerivAt_const t y₀).div h3 hr.ne'
  convert h4 using 1
  have hsq : √(1 - t / Tstar) ^ 2 = 1 - t / Tstar := Real.sq_sqrt hw.le
  rw [hT]
  rw [hT] at hsq hr
  set r := √(1 - t / (ν ^ 3 / (2 * K * y₀ ^ 2)))
  have : r ^ 3 = r * (1 - t / (ν ^ 3 / (2 * K * y₀ ^ 2))) := by rw [← hsq]; ring
  field_simp
  ring

/-- The energy inequality for a smooth flow, which holds with equality (Step 1 and its
detailed proof). Let `u t x i` be the `i`-th component of the velocity at time `t` and point
`x = (x₀, x₁, x₂)`, and `p t x` the pressure divided by the density, over the times
`0 ≤ t ≤ T`, with kinematic viscosity `ν > 0`. Suppose:
* the flow is smooth: `u` is twice and `p` once continuously differentiable;
* the box repeats: `u` and `p` take the same values at `x` and at `x + L eⱼ` for each
  direction `j`, where `L > 0` is the side of the cube `[0, L]³` (so the edges add nothing);
* the water is incompressible: `∑ᵢ ∂ᵢ uᵢ = 0`;
* there is no outside force: `∂ₜ uᵢ + ∑ⱼ uⱼ ∂ⱼ uᵢ = −∂ᵢ p + ν ∑ⱼ ∂ⱼ∂ⱼ uᵢ` inside the time span.
Then the energy `E(t) = ½ ∫ |u|²` over the cube, plus `ν` times the time integral of the
enstrophy `y(s) = ∫ |∇u|²`, equals the starting energy: `E(t) + ν ∫₀ᵗ y = E(0)`. In
particular `E(t) + ν ∫₀ᵗ y ≤ E(0)`. -/
theorem smooth_periodic_flow_energy_equality (ν L T : ℝ) (hν : 0 < ν) (hL : 0 < L)
    (u : ℝ → (Fin 3 → ℝ) → (Fin 3 → ℝ)) (p : ℝ → (Fin 3 → ℝ) → ℝ)
    (hu : ContDiffOn ℝ 2 (fun q : ℝ × (Fin 3 → ℝ) => u q.1 q.2) (Icc 0 T ×ˢ univ))
    (hp : ContDiffOn ℝ 1 (fun q : ℝ × (Fin 3 → ℝ) => p q.1 q.2) (Icc 0 T ×ˢ univ))
    (hu_per : ∀ t ∈ Icc 0 T, ∀ x : Fin 3 → ℝ, ∀ j : Fin 3,
      u t (x + L • Pi.single j 1) = u t x)
    (hp_per : ∀ t ∈ Icc 0 T, ∀ x : Fin 3 → ℝ, ∀ j : Fin 3,
      p t (x + L • Pi.single j 1) = p t x)
    (h_div : ∀ t ∈ Icc 0 T, ∀ x : Fin 3 → ℝ,
      ∑ i : Fin 3, fderiv ℝ (fun z => u t z i) x (Pi.single i 1) = 0)
    (h_ns : ∀ t ∈ Ioo 0 T, ∀ x : Fin 3 → ℝ, ∀ i : Fin 3,
      deriv (fun s => u s x i) t
          + ∑ j : Fin 3, u t x j * fderiv ℝ (fun z => u t z i) x (Pi.single j 1)
        = -fderiv ℝ (p t) x (Pi.single i 1)
          + ν * ∑ j : Fin 3,
              fderiv ℝ (fun w => fderiv ℝ (fun z => u t z i) w (Pi.single j 1)) x
                (Pi.single j 1)) :
    ∀ t ∈ Icc 0 T,
      (1 / 2) * (∫ x in Icc (0 : Fin 3 → ℝ) (fun _ => L), ∑ i : Fin 3, u t x i ^ 2)
        + ν * ∫ s in (0 : ℝ)..t, ∫ x in Icc (0 : Fin 3 → ℝ) (fun _ => L),
            ∑ i : Fin 3, ∑ j : Fin 3, (fderiv ℝ (fun z => u s z i) x (Pi.single j 1)) ^ 2
      = (1 / 2) * ∫ x in Icc (0 : Fin 3 → ℝ) (fun _ => L), ∑ i : Fin 3, u 0 x i ^ 2 := by
  intro t ht
  rcases eq_or_lt_of_le (ht.1.trans ht.2) with hT0 | hTpos
  · have h0 : t = 0 := le_antisymm (hT0 ▸ ht.2) ht.1
    subst h0
    simp
  set S := Icc 0 T ×ˢ (univ : Set (Fin 3 → ℝ)) with hSdef
  set U : ℝ × (Fin 3 → ℝ) → (Fin 3 → ℝ) := fun q => u q.1 q.2 with hUdef
  have hS : UniqueDiffOn ℝ S := (uniqueDiffOn_Icc hTpos).prod uniqueDiffOn_univ
  set D := fderivWithin ℝ U S with hDdef
  have hUc : ContinuousOn U S := hu.continuousOn
  have hDc : ContinuousOn D S := hu.continuousOn_fderivWithin hS (by norm_num)
  have hslice : ∀ s ∈ Icc 0 T, ContDiff ℝ 2 (u s) := by
    intro s hs
    have := hu.comp (s := univ) (contDiff_prodMk_right s).contDiffOn (fun x _ => ⟨hs, mem_univ x⟩)
    exact contDiffOn_univ.1 this
  have hpslice : ∀ s ∈ Icc 0 T, ContDiff ℝ 1 (p s) := by
    intro s hs
    have := hp.comp (s := univ) (contDiff_prodMk_right s).contDiffOn (fun x _ => ⟨hs, mem_univ x⟩)
    exact contDiffOn_univ.1 this
  have hderiv : ∀ s ∈ Ioo 0 T, ∀ x : Fin 3 → ℝ, ∀ i : Fin 3,
      HasDerivAt (fun s => u s x i) (D (s, x) (1, 0) i) s := by
    intro s hs x i
    have hmem : S ∈ nhds (s, x) := by
      apply Filter.mem_of_superset (prod_mem_nhds (Ioo_mem_nhds hs.1 hs.2) Filter.univ_mem)
      exact prod_mono Ioo_subset_Icc_self subset_rfl
    have hdiff : DifferentiableAt ℝ U (s, x) :=
      ((hu.differentiableOn (by norm_num)) (s, x) (mem_of_mem_nhds hmem)).differentiableAt hmem
    have h1 : HasFDerivAt U (D (s, x)) (s, x) := by
      rw [hDdef, fderivWithin_of_mem_nhds hmem]; exact hdiff.hasFDerivAt
    have h2 : HasDerivAt (fun s : ℝ => (s, x)) ((1 : ℝ), (0 : Fin 3 → ℝ)) s :=
      (hasDerivAt_id s).prodMk (hasDerivAt_const s x)
    have h3 := h1.comp_hasDerivAt s h2
    exact hasDerivAt_pi.1 h3 i
  set Q := Icc (0 : Fin 3 → ℝ) (fun _ => L) with hQdef
  set φ : ℝ × (Fin 3 → ℝ) → ℝ := fun q => ∑ i : Fin 3, U q i * D q (1, 0) i with hφdef
  have hφc : ContinuousOn φ S := by
    apply continuousOn_finsetSum
    intro i _
    apply ContinuousOn.mul
    · exact (continuous_apply i).comp_continuousOn hUc
    · exact (continuous_apply i).comp_continuousOn
        ((ContinuousLinearMap.apply ℝ (Fin 3 → ℝ) ((1 : ℝ), (0 : Fin 3 → ℝ))).continuous.comp_continuousOn hDc)
  have hrate : ∀ s ∈ Ioo 0 T, ∫ x in Q, φ (s, x) = -ν * ∫ x in Q,
      ∑ i : Fin 3, ∑ j : Fin 3, (fderiv ℝ (fun z => u s z i) x (Pi.single j 1)) ^ 2 := by
    intro s hs
    have hs' := Ioo_subset_Icc_self hs
    exact periodic_flow_energy_rate ν L hL (u s) (p s) (fun x i => D (s, x) (1, 0) i)
      (hslice s hs') (hpslice s hs') (hu_per s hs') (hp_per s hs') (h_div s hs')
      (fun x i => by rw [← (hderiv s hs x i).deriv]; exact h_ns s hs x i)
  have ht0 := ht.1
  have hsubS : ∀ s ∈ Icc 0 t, ∀ x, (s, x) ∈ S :=
    fun s hs x => ⟨⟨hs.1, hs.2.trans ht.2⟩, mem_univ x⟩
  have hftc : ∀ x, (1 / 2) * ∑ i : Fin 3, u t x i ^ 2 - (1 / 2) * ∑ i : Fin 3, u 0 x i ^ 2
      = ∫ s in (0 : ℝ)..t, φ (s, x) := by
    intro x
    symm
    have hcx : ContinuousOn (fun s => U (s, x)) (Icc 0 t) :=
      hUc.comp (continuous_id.prodMk continuous_const).continuousOn (fun s hs => hsubS s hs x)
    apply intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le ht0
      (f := fun s => (1 / 2) * ∑ i : Fin 3, u s x i ^ 2)
    · exact continuousOn_const.mul (continuousOn_finsetSum _ fun i _ =>
        ((continuous_apply i).comp_continuousOn hcx).pow 2)
    · intro s hs
      have hs' : s ∈ Ioo 0 T := ⟨hs.1, hs.2.trans_le ht.2⟩
      have := (HasDerivAt.sum (u := Finset.univ) fun i _ => (hderiv s hs' x i).pow 2).const_mul
        (1 / 2 : ℝ)
      convert this using 1
      · funext s; simp
      · rw [Finset.mul_sum]
        apply Finset.sum_congr rfl
        intro i _
        simp only [U]
        push_cast
        ring
    · apply ContinuousOn.intervalIntegrable
      rw [uIcc_of_le ht0]
      exact hφc.comp (continuous_id.prodMk continuous_const).continuousOn (fun s hs => hsubS s hs x)
  have hint : Integrable (Function.uncurry fun (s : ℝ) (x : Fin 3 → ℝ) => φ (s, x))
      ((volume.restrict (Ioc 0 t)).prod (volume.restrict Q)) := by
    rw [Measure.prod_restrict, ← Measure.volume_eq_prod]
    have : IntegrableOn φ (Icc 0 t ×ˢ Q) :=
      (hφc.mono (fun q (hq : q ∈ Icc 0 t ×ˢ Q) => hsubS q.1 hq.1 q.2)).integrableOn_compact
        (isCompact_Icc.prod isCompact_Icc)
    exact this.mono_set (prod_mono Ioc_subset_Icc_self subset_rfl)
  have hsq : ∀ s ∈ Icc 0 T, IntegrableOn (fun x => ∑ i : Fin 3, u s x i ^ 2) Q := by
    intro s hs
    apply Continuous.integrableOn_Icc
    exact continuous_finsetSum _ fun i _ =>
      ((continuous_apply i).comp (hslice s hs).continuous).pow 2
  have hE : (1 / 2) * (∫ x in Q, ∑ i : Fin 3, u t x i ^ 2)
      - (1 / 2) * ∫ x in Q, ∑ i : Fin 3, u 0 x i ^ 2 = ∫ x in Q, ∫ s in (0 : ℝ)..t, φ (s, x) := by
    rw [← integral_const_mul, ← integral_const_mul, ← integral_sub]
    · exact integral_congr_ae (Filter.Eventually.of_forall hftc)
    · exact (hsq t ht).const_mul _
    · exact (hsq 0 ⟨le_rfl, hTpos.le⟩).const_mul _
  have hswap : ∫ x in Q, ∫ s in (0 : ℝ)..t, φ (s, x) = ∫ s in (0 : ℝ)..t, ∫ x in Q, φ (s, x) := by
    simp only [intervalIntegral.integral_of_le ht0]
    exact (integral_integral_swap hint).symm
  have hy : ∫ s in (0 : ℝ)..t, ∫ x in Q, φ (s, x) = -ν * ∫ s in (0 : ℝ)..t, ∫ x in Q,
      ∑ i : Fin 3, ∑ j : Fin 3, (fderiv ℝ (fun z => u s z i) x (Pi.single j 1)) ^ 2 := by
    rw [← intervalIntegral.integral_const_mul]
    simp only [intervalIntegral.integral_of_le ht0]
    rw [integral_Ioc_eq_integral_Ioo, integral_Ioc_eq_integral_Ioo]
    apply setIntegral_congr_fun measurableSet_Ioo
    intro s hs
    exact hrate s ⟨hs.1, hs.2.trans_le ht.2⟩
  linarith

/-- The three-dimensional spin bound (The formula and Step 4). If the enstrophy `y` starts at
`y₀ > 0` and grows at most like its cube, `dy/dt ≤ (K / ν³) y³`, with `K > 0` and viscosity
`ν > 0`, then up to the time `T* = ν³ / (2 K y₀²)` it stays below the solution of the equality
case: `y(t) ≤ y₀ / √(1 − t/T*)` for `0 ≤ t < T*`. -/
theorem enstrophy_le_of_cubic_growth (K ν y₀ Tstar : ℝ) (hK : 0 < K) (hν : 0 < ν)
    (hy₀ : 0 < y₀) (hT : Tstar = ν ^ 3 / (2 * K * y₀ ^ 2))
    (y y' : ℝ → ℝ) (h_start : y 0 = y₀)
    (h_deriv : ∀ t ∈ Ico 0 Tstar, HasDerivAt y (y' t) t)
    (h_rate : ∀ t ∈ Ico 0 Tstar, y' t ≤ K / ν ^ 3 * y t ^ 3) :
    ∀ t ∈ Ico 0 Tstar, y t ≤ y₀ / √(1 - t / Tstar) := by
  intro t₁ ht₁
  set z : ℝ → ℝ := fun s => y₀ / √(1 - s / Tstar) with hz
  have hTp : 0 < Tstar := by rw [hT]; positivity
  have hzd : ∀ s, s < Tstar → HasDerivAt z (K / ν ^ 3 * z s ^ 3) s :=
    fun s hs => blowup_curve_hasDerivAt K ν y₀ Tstar hK hν hy₀ hT s hs
  have hw : ∀ s, s < Tstar → 0 < 1 - s / Tstar := by
    intro s hs
    have : s / Tstar < 1 := by rw [div_lt_one hTp]; exact hs
    linarith
  have hzpos : ∀ s, s < Tstar → 0 < z s := fun s hs => div_pos hy₀ (Real.sqrt_pos.2 (hw s hs))
  have hzmono : ∀ s ∈ Icc 0 t₁, z s ≤ z t₁ := by
    intro s hs
    apply div_le_div_of_nonneg_left hy₀.le (Real.sqrt_pos.2 (hw t₁ ht₁.2))
    apply Real.sqrt_le_sqrt
    have : s / Tstar ≤ t₁ / Tstar := div_le_div_of_nonneg_right hs.2 hTp.le
    linarith
  set M := z t₁
  set a := K / ν ^ 3 with ha
  have hapos : 0 < a := by positivity
  set P := 3 * M ^ 2 + 3 * M + 1
  set C := a * P + 1
  have key : ∀ δ, 0 < δ → δ * exp (C * t₁) ≤ 1 → y t₁ ≤ z t₁ + δ * exp (C * t₁) := by
    intro δ hδ hδ1
    have hsub : ∀ s ∈ Icc 0 t₁, s ∈ Ico 0 Tstar := fun s hs => ⟨hs.1, lt_of_le_of_lt hs.2 ht₁.2⟩
    have hsub' : ∀ s ∈ Ico 0 t₁, s ∈ Ico 0 Tstar := fun s hs => hsub s (Ico_subset_Icc_self hs)
    have hB : ∀ s ∈ Icc 0 t₁, HasDerivAt (fun s => z s + δ * exp (C * s))
        (a * z s ^ 3 + δ * (exp (C * s) * C)) s := by
      intro s hs
      have h1 := hzd s (hsub s hs).2
      have h2 : HasDerivAt (fun s => δ * exp (C * s)) (δ * (exp (C * s) * C)) s := by
        have := ((hasDerivAt_id s).const_mul C).exp
        simpa using this.const_mul δ
      exact h1.add h2
    refine image_le_of_deriv_right_lt_deriv_boundary' (f := y) (f' := y') (a := 0) (b := t₁)
      (B := fun s => z s + δ * exp (C * s)) (B' := fun s => a * z s ^ 3 + δ * (exp (C * s) * C))
      ?_ ?_ ?_ ?_ ?_ ?_ (right_mem_Icc.2 ht₁.1)
    · intro s hs; exact (h_deriv s (hsub s hs)).continuousAt.continuousWithinAt
    · intro s hs; exact (h_deriv s (hsub' s hs)).hasDerivWithinAt
    · rw [h_start]
      have : z 0 = y₀ := by simp [hz]
      rw [this]; simp; positivity
    · intro s hs; exact (hB s hs).continuousAt.continuousWithinAt
    · intro s hs; exact (hB s (Ico_subset_Icc_self hs)).hasDerivWithinAt
    · intro s hs heq
      have hr := h_rate s (hsub' s hs)
      rw [heq] at hr
      set η := δ * exp (C * s)
      have hη0 : 0 < η := by positivity
      have hη1 : η ≤ 1 := by
        refine le_trans ?_ hδ1
        apply mul_le_mul_of_nonneg_left _ hδ.le
        apply exp_le_exp.2
        have : 0 ≤ C := by positivity
        nlinarith [hs.2]
      have hz0 := hzpos s (hsub' s hs).2
      have hzM := hzmono s (Ico_subset_Icc_self hs)
      have hcube : (z s + η) ^ 3 - z s ^ 3 ≤ η * P := by
        have : (z s + η) ^ 3 - z s ^ 3 = η * (3 * z s ^ 2 + 3 * z s * η + η ^ 2) := by ring
        rw [this]
        apply mul_le_mul_of_nonneg_left _ hη0.le
        have h1 : z s ^ 2 ≤ M ^ 2 := by nlinarith
        have h2 : z s * η ≤ M := by nlinarith
        have h3 : η ^ 2 ≤ 1 := by nlinarith
        simp only [P]; nlinarith
      have : a * (z s + η) ^ 3 ≤ a * z s ^ 3 + a * (η * P) := by nlinarith
      have e : δ * (exp (C * s) * C) = a * (η * P) + η := by simp only [η, C]; ring
      rw [e]
      linarith
  apply le_of_forall_pos_le_add
  intro ε hε
  set η₁ := min ε 1
  have hη₁ : 0 < η₁ := lt_min hε one_pos
  have h := key (η₁ * exp (-(C * t₁))) (by positivity) (by
    rw [mul_assoc, ← exp_add]; simp [η₁])
  rw [mul_assoc, ← exp_add, neg_add_cancel, exp_zero, mul_one] at h
  have : η₁ ≤ ε := min_le_left _ _
  show y t₁ ≤ z t₁ + ε
  linarith

/-- Why energy cannot close the gap (Step 5). On the bound's own curve `z(s) = 1/√(1 − s)`
(spin as a multiple of `y₀`, time `s` as a fraction of `T*`), stopped `ε` short of the end,
the total `∫ z` is `2 − 2√ε`, which never reaches 2, while the total square `∫ z²` is
`−log ε`, which grows without limit as `ε` shrinks. -/
theorem blowup_curve_finite_total_unbounded_square (ε : ℝ) (hε₀ : 0 < ε) (hε₁ : ε < 1) :
    (∫ s in (0 : ℝ)..(1 - ε), 1 / √(1 - s)) = 2 - 2 * √ε ∧
      (∫ s in (0 : ℝ)..(1 - ε), (1 / √(1 - s)) ^ 2) = -log ε := by
  have hpos : ∀ s ∈ uIcc (0:ℝ) (1 - ε), 0 < 1 - s := by
    intro s hs
    rw [uIcc_of_le (by linarith)] at hs
    linarith [hs.2]
  constructor
  · have hd : ∀ s ∈ uIcc (0:ℝ) (1 - ε), HasDerivAt (fun s => -2 * √(1 - s)) (1 / √(1 - s)) s := by
      intro s hs
      have h1 := hpos s hs
      have h2 : HasDerivAt (fun s : ℝ => 1 - s) (-1) s := by
        simpa using (hasDerivAt_id s).const_sub 1
      have h3 := (h2.sqrt h1.ne').const_mul (-2)
      convert h3 using 1
      have : 0 < √(1 - s) := Real.sqrt_pos.2 h1
      field_simp
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd]
    · simp
      ring
    · apply ContinuousOn.intervalIntegrable
      intro s hs
      have h1 := hpos s hs
      apply ContinuousAt.continuousWithinAt
      apply ContinuousAt.div continuousAt_const
      · exact (continuous_const.sub continuous_id).sqrt.continuousAt
      · exact (Real.sqrt_pos.2 h1).ne'
  · have hd : ∀ s ∈ uIcc (0:ℝ) (1 - ε), HasDerivAt (fun s => -log (1 - s)) ((1 / √(1 - s)) ^ 2) s := by
      intro s hs
      have h1 := hpos s hs
      have h2 : HasDerivAt (fun s : ℝ => 1 - s) (-1) s := by
        simpa using (hasDerivAt_id s).const_sub 1
      have h3 := (h2.log h1.ne').neg
      convert h3 using 1
      rw [div_pow, Real.sq_sqrt h1.le]
      ring
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd]
    · simp
    · apply ContinuousOn.intervalIntegrable
      intro s hs
      have h1 := hpos s hs
      apply ContinuousAt.continuousWithinAt
      apply ContinuousAt.pow
      apply ContinuousAt.div continuousAt_const
      · exact (continuous_const.sub continuous_id).sqrt.continuousAt
      · exact (Real.sqrt_pos.2 h1).ne'

-- Worked numbers, by hand (exact rationals, SI units).
-- Reynolds number: 1 m/s × 0.05 m / 1.0e-6 m²/s = 50,000.
example : (1 : ℚ) * (5 / 100) / (1 / 10 ^ 6) = 50000 := by norm_num
-- Energy per unit density: ½ × (½ + ½ + 1) m²/s² × (0.05 m)³ = 1.25e-4 m⁵/s².
example : (1 / 2 : ℚ) * (1 / 2 + 1 / 2 + 1) * (5 / 100) ^ 3 = 125 / 10 ^ 6 := by norm_num
-- In joules, times 1000 kg/m³: 0.125 J.
example : (125 / 10 ^ 6 : ℚ) * 1000 = 1 / 8 := by norm_num
-- Energy budget for spin: 1.25e-4 / 1.0e-6 = 125 m³/s.
example : (125 / 10 ^ 6 : ℚ) / (1 / 10 ^ 6) = 125 := by norm_num
-- Enstrophy weights: amplitude² × |k|² over the three waves, 1·1 + 1·2 + 2·3 = 9.
example : 1 * 1 + 1 * 2 + 2 * 3 = 9 := by decide
-- Re³ = 50,000³ = 1.25e14.
example : (50000 : ℕ) ^ 3 = 125000000000000 := by norm_num
-- Zoom energy ratio λ^(2−d) in 3D: 0.1 at λ = 10, 0.01 at λ = 100; 1 in 2D.
example : (10 : ℚ) ^ ((2 : ℤ) - 3) = 1 / 10 ∧ (100 : ℚ) ^ ((2 : ℤ) - 3) = 1 / 100 ∧
    (100 : ℚ) ^ ((2 : ℤ) - 2) = 1 := by norm_num
-- The constant from Young's step: K = 2 × 27 C⁴ / 256 = 27 C⁴ / 128.
example (C : ℚ) : 2 * (27 * C ^ 4 / 256) = 27 * C ^ 4 / 128 := by ring
-- The bound's curve at s = 3/4 of T*: z = 1/√(1 − 3/4) = 2.
example : 1 / √(1 - 3 / 4 : ℝ) = 2 := by
  rw [show (1 - 3 / 4 : ℝ) = (1 / 2) ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]; norm_num
-- Stopped 1e-6 short: ∫ z = 2 − 2√(1e-6) = 1.998.
example : (2 : ℝ) - 2 * √(1 / 10 ^ 6) = 1998 / 1000 := by
  rw [show (1 / 10 ^ 6 : ℝ) = (1 / 1000) ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]; norm_num

#print axioms insertNth_L_eq
#print axioms periodic_box_div_integral_zero
#print axioms periodic_flow_energy_rate
#print axioms blowup_curve_hasDerivAt
#print axioms smooth_periodic_flow_energy_equality
#print axioms enstrophy_le_of_cubic_growth
#print axioms blowup_curve_finite_total_unbounded_square
