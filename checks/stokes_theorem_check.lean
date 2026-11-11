-- Stokes' theorem: for a wind with continuous rates on a surface given by one twice-smooth grid over a rectangle, the circulation once round the rim equals the flux of the curl through the surface, and the card's drain wind shows why the wind must be smooth on the whole surface.
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.MeasureTheory.Integral.DivergenceTheorem
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.FDeriv.Symmetric

open Set MeasureTheory Matrix

/-- The curl read off a matrix of rates. `L` sends a step to the change it makes in the wind, so
`L (Pi.single j 1) i` is `∂F_i/∂x_j`, the rate of the wind's `i`-th speed along axis `j`
(axes 0, 1, 2 are east, north, up). The curl is
`(∂F₃/∂y − ∂F₂/∂z, ∂F₁/∂z − ∂F₃/∂x, ∂F₂/∂x − ∂F₁/∂y)`. -/
noncomputable def curlOfRates (L : (Fin 3 → ℝ) →L[ℝ] (Fin 3 → ℝ)) : Fin 3 → ℝ :=
  ![L (Pi.single 1 1) 2 - L (Pi.single 2 1) 1,
    L (Pi.single 2 1) 0 - L (Pi.single 0 1) 2,
    L (Pi.single 0 1) 1 - L (Pi.single 1 1) 0]

/-- The curl of the wind `F` at the point `p`: the curl of its matrix of rates there. -/
noncomputable def curl (F : (Fin 3 → ℝ) → (Fin 3 → ℝ)) (p : Fin 3 → ℝ) : Fin 3 → ℝ :=
  curlOfRates (fderiv ℝ F p)

/-- The grid's rate in `u` (with `v` held still) at the grid point `z = (u, v)`: `r_u`. -/
noncomputable def rateU (r : ℝ × ℝ → (Fin 3 → ℝ)) (z : ℝ × ℝ) : Fin 3 → ℝ :=
  fderiv ℝ r z (1, 0)

/-- The grid's rate in `v` (with `u` held still) at the grid point `z = (u, v)`: `r_v`. -/
noncomputable def rateV (r : ℝ × ℝ → (Fin 3 → ℝ)) (z : ℝ × ℝ) : Fin 3 → ℝ :=
  fderiv ℝ r z (0, 1)

/-- The circulation of `F` once round the rim of the surface `r` over the grid rectangle
`[a, b] × [c, d]`: the rectangle's edge walked anticlockwise (bottom in `u`, right side in `v`,
top back in `u`, left side back in `v`), carried onto the surface by `r`. Along each edge a step
`dr` is `r_u du` or `r_v dv`, so the push collected is `F · r_u du` or `F · r_v dv`. -/
noncomputable def rimCirculation (F : (Fin 3 → ℝ) → (Fin 3 → ℝ)) (r : ℝ × ℝ → (Fin 3 → ℝ))
    (a b c d : ℝ) : ℝ :=
  (∫ u in a..b, F (r (u, c)) ⬝ᵥ rateU r (u, c)) + (∫ v in c..d, F (r (b, v)) ⬝ᵥ rateV r (b, v))
    - (∫ u in a..b, F (r (u, d)) ⬝ᵥ rateU r (u, d)) - (∫ v in c..d, F (r (a, v)) ⬝ᵥ rateV r (a, v))

/-- The flux of the curl of `F` through the surface `r` over `[a, b] × [c, d]`, with the normal
matched to the walk: the curl dotted with the grid's area arrow `r_u × r_v`, added over the grid. -/
noncomputable def curlFlux (F : (Fin 3 → ℝ) → (Fin 3 → ℝ)) (r : ℝ × ℝ → (Fin 3 → ℝ))
    (a b c d : ℝ) : ℝ :=
  ∫ u in a..b, ∫ v in c..d, curl F (r (u, v)) ⬝ᵥ (rateU r (u, v) ⨯₃ rateV r (u, v))

/-- Helper: the algebra step `(J A) · B − (J B) · A = curl(J) · (A × B)`, proved here so the
main theorem above it can use it. -/
theorem rates_difference_eq_curl_dot_cross_aux (J : (Fin 3 → ℝ) →L[ℝ] (Fin 3 → ℝ))
    (A B : Fin 3 → ℝ) :
    J A ⬝ᵥ B - J B ⬝ᵥ A = curlOfRates J ⬝ᵥ (A ⨯₃ B) := by
  have key : ∀ v : Fin 3 → ℝ, J v = v 0 • J (Pi.single 0 1) + v 1 • J (Pi.single 1 1)
      + v 2 • J (Pi.single 2 1) := by
    intro v
    have hv : v = v 0 • (Pi.single 0 1 : Fin 3 → ℝ) + v 1 • Pi.single 1 1
        + v 2 • Pi.single 2 1 := by
      ext i; fin_cases i <;> simp
    conv_lhs => rw [hv]
    simp only [map_add, map_smul]
  rw [key A, key B]
  simp [curlOfRates, dotProduct, Fin.sum_univ_three, cross_apply]
  ring

#print axioms rates_difference_eq_curl_dot_cross_aux

/-- **Stokes' theorem, one smooth chart.** Let the surface be `r(u, v)` over the grid rectangle
`[a, b] × [c, d]`, with `r` having continuous second partial derivatives on an open set holding
the rectangle. Let the wind `F` have continuous partial derivatives on an open set `U` holding
every point of the surface. Orient the surface by `r_u × r_v` and walk the rim the matching way
round. Then the circulation of `F` once round the rim equals the flux of its curl through the
surface. -/
theorem circulation_round_rim_eq_curl_flux_through_surface
    {F : (Fin 3 → ℝ) → (Fin 3 → ℝ)} {r : ℝ × ℝ → (Fin 3 → ℝ)} {U : Set (Fin 3 → ℝ)}
    {V : Set (ℝ × ℝ)} {a b c d : ℝ}
    (hU : IsOpen U) (hF : ContDiffOn ℝ 1 F U)
    (hV : IsOpen V) (hr : ContDiffOn ℝ 2 r V)
    (hRV : uIcc a b ×ˢ uIcc c d ⊆ V)
    (hS : ∀ z ∈ uIcc a b ×ˢ uIcc c d, r z ∈ U) :
    rimCirculation F r a b c d = curlFlux F r a b c d := by
  set R := uIcc a b ×ˢ uIcc c d with hRdef
  set W := V ∩ r ⁻¹' U with hWdef
  have hW : IsOpen W := hr.continuousOn.isOpen_inter_preimage hV hU
  have hRW : R ⊆ W := fun z hz => ⟨hRV hz, hS z hz⟩
  have hrW : ContDiffOn ℝ 2 r W := hr.mono inter_subset_left
  have hDr : ContDiffOn ℝ 1 (fderiv ℝ r) W :=
    (hr.fderiv_of_isOpen hV (m := 1) (by norm_num)).mono inter_subset_left
  have hFr : ContDiffOn ℝ 1 (fun z => F (r z)) W :=
    hF.comp (hrW.of_le (by norm_num)) (fun z hz => hz.2)
  have dotCD : ∀ w : ℝ × ℝ, ContDiffOn ℝ 1 (fun z => F (r z) ⬝ᵥ fderiv ℝ r z w) W := by
    intro w
    have h1 := contDiffOn_pi.1 hFr
    have h2 := contDiffOn_pi.1 (hDr.clm_apply (g := fun _ => w) contDiffOn_const)
    simp only [dotProduct]
    exact ContDiffOn.sum fun i _ => (h1 i).mul (h2 i)
  have hderiv : ∀ z ∈ W, ∀ w v : ℝ × ℝ,
      fderiv ℝ (fun z => F (r z) ⬝ᵥ fderiv ℝ r z w) z v =
        fderiv ℝ F (r z) (fderiv ℝ r z v) ⬝ᵥ fderiv ℝ r z w
          + F (r z) ⬝ᵥ fderiv ℝ (fderiv ℝ r) z v w := by
    intro z hz w v
    have hrz : DifferentiableAt ℝ r z :=
      (hrW.contDiffAt (hW.mem_nhds hz)).differentiableAt (by norm_num)
    have hDrz : DifferentiableAt ℝ (fderiv ℝ r) z :=
      (hDr.contDiffAt (hW.mem_nhds hz)).differentiableAt one_ne_zero
    have hFz : DifferentiableAt ℝ F (r z) :=
      (hF.contDiffAt (hU.mem_nhds hz.2)).differentiableAt one_ne_zero
    have hA : HasFDerivAt (fun z => F (r z)) ((fderiv ℝ F (r z)).comp (fderiv ℝ r z)) z :=
      hFz.hasFDerivAt.comp z hrz.hasFDerivAt
    have hB := hDrz.hasFDerivAt.clm_apply (hasFDerivAt_const w z)
    have hSum := HasFDerivAt.fun_sum (u := Finset.univ)
      (fun i _ => (hasFDerivAt_pi'.1 hA i).fun_mul (hasFDerivAt_pi'.1 hB i))
    rw [show (fun z => F (r z) ⬝ᵥ fderiv ℝ r z w)
        = fun z => ∑ i, F (r z) i * fderiv ℝ r z w i from rfl, hSum.fderiv]
    simp [dotProduct, Fin.sum_univ_three]
    ring
  have hQc := dotCD (0, 1)
  have hPc := (dotCD (1, 0)).neg
  have hIoo : Ioo (min a b) (max a b) ×ˢ Ioo (min c d) (max c d) ⊆ R :=
    fun z hz => ⟨Ioo_subset_Icc_self hz.1, Ioo_subset_Icc_self hz.2⟩
  have key := integral2_divergence_prod_of_hasFDerivAt
    (fun z => F (r z) ⬝ᵥ fderiv ℝ r z (0, 1)) (fun z => -(F (r z) ⬝ᵥ fderiv ℝ r z (1, 0)))
    (fderiv ℝ (fun z => F (r z) ⬝ᵥ fderiv ℝ r z (0, 1)))
    (fderiv ℝ (fun z => -(F (r z) ⬝ᵥ fderiv ℝ r z (1, 0)))) a c b d
    (hQc.continuousOn.mono hRW) (hPc.continuousOn.mono hRW)
    (fun z hz => ((hQc.differentiableOn one_ne_zero z (hRW (hIoo hz))).differentiableAt
      (hW.mem_nhds (hRW (hIoo hz)))).hasFDerivAt)
    (fun z hz => ((hPc.differentiableOn one_ne_zero z (hRW (hIoo hz))).differentiableAt
      (hW.mem_nhds (hRW (hIoo hz)))).hasFDerivAt)
    (ContinuousOn.integrableOn_compact (isCompact_uIcc.prod isCompact_uIcc)
      ((((hQc.continuousOn_fderiv_of_isOpen hW le_rfl).clm_apply continuousOn_const).add
        ((hPc.continuousOn_fderiv_of_isOpen hW le_rfl).clm_apply continuousOn_const)).mono hRW))
  have lhs : curlFlux F r a b c d = ∫ x in a..b, ∫ y in c..d,
      fderiv ℝ (fun z => F (r z) ⬝ᵥ fderiv ℝ r z (0, 1)) (x, y) (1, 0)
        + fderiv ℝ (fun z => -(F (r z) ⬝ᵥ fderiv ℝ r z (1, 0))) (x, y) (0, 1) := by
    unfold curlFlux
    refine intervalIntegral.integral_congr fun u hu => intervalIntegral.integral_congr
      fun v hv => ?_
    have hz : (u, v) ∈ W := hRW ⟨hu, hv⟩
    have hsymm := (hrW.contDiffAt (hW.mem_nhds hz)).isSymmSndFDerivAt (by simp)
    rw [fderiv_fun_neg, neg_apply, hderiv _ hz, hderiv _ hz, hsymm (1, 0) (0, 1),
      curl, ← rates_difference_eq_curl_dot_cross_aux, rateU, rateV]
    ring
  rw [lhs, key]
  unfold rimCirculation rateU rateV
  simp only [intervalIntegral.integral_neg]
  ring

/-- **The step that makes curl appear.** For any matrix of rates `J` and any two arrows `A`, `B`
(in the proof, `A = r_u` and `B = r_v`), `(J A) · B − (J B) · A` is the curl read off `J`, dotted
with `A × B`. This is why Green's theorem on the grid gives the curl's flux. -/
theorem rates_difference_eq_curl_dot_cross (J : (Fin 3 → ℝ) →L[ℝ] (Fin 3 → ℝ))
    (A B : Fin 3 → ℝ) :
    J A ⬝ᵥ B - J B ⬝ᵥ A = curlOfRates J ⬝ᵥ (A ⨯₃ B) := by
  exact rates_difference_eq_curl_dot_cross_aux J A B

/-- The drain wind `(−2y/(x² + y²), 2x/(x² + y²), 0)`, spinning round the vertical axis, where
it is undefined (Lean's division by zero gives it the value 0 there). -/
noncomputable def drain (p : Fin 3 → ℝ) : Fin 3 → ℝ :=
  ![-2 * p 1 / (p 0 ^ 2 + p 1 ^ 2), 2 * p 0 / (p 0 ^ 2 + p 1 ^ 2), 0]

/-- The bowl's rim: the level circle of radius 2 m at height 0, walked anticlockwise from above. -/
noncomputable def rimCircle (t : ℝ) : Fin 3 → ℝ :=
  ![2 * Real.cos t, 2 * Real.sin t, 0]

/-- **The drain breaks it.** The drain wind has zero curl at every point off the vertical axis,
yet its circulation once round the bowl's rim is 4π m²/s, not 0. -/
theorem drain_curl_zero_off_axis_but_circulation_four_pi :
    (∀ p : Fin 3 → ℝ, p 0 ^ 2 + p 1 ^ 2 ≠ 0 → curl drain p = 0) ∧
      (∫ t in (0:ℝ)..2 * Real.pi, drain (rimCircle t) ⬝ᵥ deriv rimCircle t) = 4 * Real.pi := by
  refine ⟨fun p hp => ?_, ?_⟩
  · have hd := ((hasFDerivAt_apply (𝕜 := ℝ) 0 p).pow 2).add
      ((hasFDerivAt_apply (𝕜 := ℝ) 1 p).pow 2)
    have hi := (hasDerivAt_inv hp).comp_hasFDerivAt p hd
    have h0 := ((hasFDerivAt_apply (𝕜 := ℝ) 1 p).const_mul (-2)).fun_mul hi
    have h1 := ((hasFDerivAt_apply (𝕜 := ℝ) 0 p).const_mul 2).fun_mul hi
    have h2 := hasFDerivAt_const (𝕜 := ℝ) (0 : ℝ) p
    simp only [Function.comp_def, Pi.add_apply] at h0 h1
    have e0 : (fun q => drain q 0) = fun q => -2 * q 1 * (q 0 ^ 2 + q 1 ^ 2)⁻¹ := by
      funext q; simp [drain, div_eq_mul_inv]
    have e1 : (fun q => drain q 1) = fun q => 2 * q 0 * (q 0 ^ 2 + q 1 ^ 2)⁻¹ := by
      funext q; simp [drain, div_eq_mul_inv]
    have e2 : (fun q => drain q 2) = fun _ => 0 := by
      funext q; simp [drain]
    have hdi : ∀ i, DifferentiableAt ℝ (fun q => drain q i) p := by
      intro i
      fin_cases i
      · simp only [Fin.zero_eta]; rw [e0]; exact h0.differentiableAt
      · simp only [Fin.mk_one]; rw [e1]; exact h1.differentiableAt
      · show DifferentiableAt ℝ (fun q => drain q 2) p
        rw [e2]; exact h2.differentiableAt
    have hdiff : DifferentiableAt ℝ drain p := differentiableAt_pi.2 hdi
    have comp : ∀ i v, fderiv ℝ drain p v i = fderiv ℝ (fun q => drain q i) p v := by
      intro i v
      rw [(hasFDerivAt_pi'.1 hdiff.hasFDerivAt i).fderiv]
      rfl
    rw [curl]
    simp only [curlOfRates, comp, e0, e1, e2, h0.fderiv, h1.fderiv, h2.fderiv]
    ext i
    fin_cases i <;> simp
    field_simp
    ring
  · have hder : ∀ t, deriv rimCircle t = ![-(2 * Real.sin t), 2 * Real.cos t, 0] := by
      intro t
      apply HasDerivAt.deriv
      refine hasDerivAt_pi.2 ?_
      intro i
      fin_cases i
      · simpa [rimCircle] using (Real.hasDerivAt_cos t).const_mul 2
      · simpa [rimCircle] using (Real.hasDerivAt_sin t).const_mul 2
      · simpa [rimCircle] using hasDerivAt_const t (0 : ℝ)
    have hint : ∀ t, drain (rimCircle t) ⬝ᵥ deriv rimCircle t = 2 := by
      intro t
      rw [hder]
      have h4 : (2 * Real.cos t) ^ 2 + (2 * Real.sin t) ^ 2 = 4 := by
        nlinarith [Real.sin_sq_add_cos_sq t]
      simp [drain, rimCircle, dotProduct, Fin.sum_univ_three, h4]
      nlinarith [Real.sin_sq_add_cos_sq t]
    simp only [hint, intervalIntegral.integral_const]
    simp; ring

/-! ### The card's worked numbers (lengths, areas and fluxes counted in multiples of π) -/

-- Wind speed at the rim: 0.5 per second × 2 m = 1 m/s.
example : (1 / 2 : ℚ) * 2 = 1 := by norm_num

-- Rim length 2π × 2 m = 4π m; circulation 1 m/s × 4π m = 4π.
example : (2 : ℚ) * 2 = 4 ∧ (1 : ℚ) * 4 = 4 := by norm_num

-- Curl of the swirl: w − (−w) = 1 per second with w = 0.5, that is 2 × 0.5.
example : (1 / 2 : ℚ) - (-(1 / 2)) = 1 ∧ (2 : ℚ) * (1 / 2) = 1 := by norm_num

-- The lid: curl 1 × π × 2² = 4π.
example : (1 : ℚ) * 2 ^ 2 = 4 := by norm_num

-- Each metre of depth carries 2πR = 4π m² of bowl; the swirl's average 0.5 × 2 m × 4π = 4π.
example : (2 : ℚ) * 2 = 4 ∧ (1 / 2 : ℚ) * 2 * 4 = 4 := by norm_num

-- By hand, 2πwR² = 2π × 0.5 × 2² = 4π.
example : (2 : ℚ) * (1 / 2) * 2 ^ 2 = 4 := by norm_num

-- The fading wind: π × (4 + 4 − 4) = 4π.
example : (4 + 4 - 4 : ℤ) = 4 := by norm_num

-- Break 2: curl size 1 times the bowl's area 2πR² = 8π, double the true 4π.
example : (1 : ℚ) * (2 * 2 ^ 2) = 8 ∧ (8 : ℚ) = 2 * 4 := by norm_num

#print axioms circulation_round_rim_eq_curl_flux_through_surface
#print axioms rates_difference_eq_curl_dot_cross
#print axioms drain_curl_zero_off_axis_but_circulation_four_pi
