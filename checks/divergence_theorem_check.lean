-- Divergence theorem: the flux of a smooth field out through all six faces of a box equals its divergence added through the box, the height part of that holds on any solid between a floor graph and a ceiling graph, and the card's tank and ball numbers check out.
import Mathlib.MeasureTheory.Integral.DivergenceTheorem
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Data.Matrix.Mul
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Set MeasureTheory

/-! Points of space are `Fin 3 → ℝ`: coordinate `0` is x, `1` is y, `2` is z. A field
`F : (Fin 3 → ℝ) → (Fin 3 → ℝ)` gives the flow `(F₁, F₂, F₃)` at each point. `volume` on
`Fin 3 → ℝ` is ordinary volume, so `∫ x in Icc a b, …` is the triple integral over the box
`[a₀, b₀] × [a₁, b₁] × [a₂, b₂]`; on `Fin 2 → ℝ` it is ordinary area, the `dS` of a flat face. -/

/-- The divergence `∂F₁/∂x + ∂F₂/∂y + ∂F₃/∂z` of the field `F` at the point `x`: the rate of
change of the `i`-th component along the `i`-th direction, added over the three directions. -/
noncomputable def divergence (F : (Fin 3 → ℝ) → Fin 3 → ℝ) (x : Fin 3 → ℝ) : ℝ :=
  ∑ i : Fin 3, fderiv ℝ F x (Pi.single i 1) i

/-- The outward flux `∬_{∂V} F · n dS` of `F` through the whole skin of the box `[a, b]`.
The skin is six flat faces. For each direction `i` there is a far face `x_i = b_i`, whose outward
unit normal is `e_i = Pi.single i 1`, and a near face `x_i = a_i`, whose outward unit normal is
`-e_i`. A face is parametrised by its two free coordinates `y`, which run over the rectangle
`Icc (a ∘ i.succAbove) (b ∘ i.succAbove)`, and `Fin.insertNth i c y` is the point of space with
`i`-th coordinate `c` and the other two from `y`. Each face adds the area integral of `F · n`. -/
noncomputable def boxOutwardFlux (F : (Fin 3 → ℝ) → Fin 3 → ℝ) (a b : Fin 3 → ℝ) : ℝ :=
  ∑ i : Fin 3,
    ((∫ y in Icc (a ∘ i.succAbove) (b ∘ i.succAbove),
        F (Fin.insertNth i (b i) y) ⬝ᵥ Pi.single i 1) +
      ∫ y in Icc (a ∘ i.succAbove) (b ∘ i.succAbove),
        F (Fin.insertNth i (a i) y) ⬝ᵥ -Pi.single i 1)

/-- **Divergence theorem on a box.** Take a solid box `[a, b]` in space (each side `a_i ≤ b_i`),
its whole closed skin of six faces, and the outward normal on each face. Let the field `F` have
continuous first partial derivatives at every point of the box and just beyond: on some open set
`U` containing the box. Then the flux of `F` out through the whole skin equals the triple integral
of its divergence through the box: what leaves through the skin is what is made inside. -/
theorem flux_out_of_box_eq_divergence_summed_inside
    (F : (Fin 3 → ℝ) → Fin 3 → ℝ) (a b : Fin 3 → ℝ) (hab : a ≤ b)
    (hF : ∃ U : Set (Fin 3 → ℝ), IsOpen U ∧ Icc a b ⊆ U ∧ ContDiffOn ℝ 1 F U) :
    boxOutwardFlux F a b = ∫ x in Icc a b, divergence F x := by
  obtain ⟨U, hU, hsub, hFU⟩ := hF
  have hdiff : ∀ x ∈ U, HasFDerivAt F (fderiv ℝ F x) x := fun x hx =>
    ((hFU.differentiableOn one_ne_zero) x hx).differentiableAt (hU.mem_nhds hx) |>.hasFDerivAt
  have hcont' : ContinuousOn (fun x => ∑ i : Fin 3, fderiv ℝ F x (Pi.single i 1) i) U := by
    have := hFU.continuousOn_fderiv_of_isOpen hU le_rfl
    refine continuousOn_finsetSum _ fun i _ => ?_
    exact (continuous_apply i).comp_continuousOn
      ((this.clm_apply continuousOn_const))
  have key := integral_divergence_of_hasFDerivAt_off_countable a b hab F (fderiv ℝ F) ∅
    Set.countable_empty (hFU.continuousOn.mono hsub)
    (fun x hx => hdiff x (hsub (by
      rcases hx with ⟨hx, -⟩
      exact ⟨fun i => (hx i (mem_univ i)).1.le, fun i => (hx i (mem_univ i)).2.le⟩)))
    ((hcont'.mono hsub).integrableOn_compact isCompact_Icc)
  unfold boxOutwardFlux divergence
  rw [key]
  refine Finset.sum_congr rfl fun i _ => ?_
  simp only [dotProduct_neg, dotProduct_single, mul_one, integral_neg, sub_eq_add_neg]

/-- **The height part on a solid between two graphs.** The solid lies over a closed bounded flat
region `D`, between a floor `z = g(x, y)` and a ceiling `z = h(x, y)` with `g ≤ h` on `D`; floor
and ceiling have continuous partial derivatives (`g'`, `h'`). Take the height part `(0, 0, F₃)` of
a smooth field: `F₃` is continuous on the solid, and its height rate `∂F₃/∂z` (`dF₃`) exists and is
continuous there, floor and ceiling included. Parametrise the ceiling by
`(x, y)`: the cross product of its tangent arrows is the outward normal `(−h_x, −h_y, 1)`; the
floor's is `(g_x, g_y, −1)`. The flux through ceiling plus floor equals `∂F₃/∂z` added through the
solid. (The vertical side walls pass nothing, since their normals have no height part.) -/
theorem height_flux_between_two_graphs_eq_dz_summed_inside
    {F₃ dF₃ : ℝ × ℝ × ℝ → ℝ} {g h : ℝ × ℝ → ℝ} {g' h' : ℝ × ℝ → ℝ × ℝ →L[ℝ] ℝ}
    {D : Set (ℝ × ℝ)} (hD : IsCompact D)
    (hg : ∀ p ∈ D, HasFDerivAt g (g' p) p) (hh : ∀ p ∈ D, HasFDerivAt h (h' p) p)
    (hg' : ContinuousOn g' D) (hh' : ContinuousOn h' D)
    (hgh : ∀ p ∈ D, g p ≤ h p)
    (hF₃ : ContinuousOn F₃ {q | (q.1, q.2.1) ∈ D ∧ q.2.2 ∈ Icc (g (q.1, q.2.1)) (h (q.1, q.2.1))})
    (hF : ∀ p ∈ D, ∀ z ∈ Icc (g p) (h p),
      HasDerivWithinAt (fun t => F₃ (p.1, p.2, t)) (dF₃ (p.1, p.2, z)) (Icc (g p) (h p)) z)
    (hdF : ContinuousOn dF₃ {q | (q.1, q.2.1) ∈ D ∧ q.2.2 ∈ Icc (g (q.1, q.2.1)) (h (q.1, q.2.1))}) :
    (∫ p in D, ![0, 0, F₃ (p.1, p.2, h p)] ⬝ᵥ ![-(h' p (1, 0)), -(h' p (0, 1)), 1]) +
      (∫ p in D, ![0, 0, F₃ (p.1, p.2, g p)] ⬝ᵥ ![g' p (1, 0), g' p (0, 1), -1]) =
      ∫ p in D, ∫ z in g p..h p, dF₃ (p.1, p.2, z) := by
  have hDm : MeasurableSet D := hD.isClosed.measurableSet
  have hgc : ContinuousOn g D := fun p hp => (hg p hp).continuousAt.continuousWithinAt
  have hhc : ContinuousOn h D := fun p hp => (hh p hp).continuousAt.continuousWithinAt
  set S := {q : ℝ × ℝ × ℝ | (q.1, q.2.1) ∈ D ∧ q.2.2 ∈ Icc (g (q.1, q.2.1)) (h (q.1, q.2.1))}
  have hcomp : ∀ k : ℝ × ℝ → ℝ, ContinuousOn k D → (∀ p ∈ D, k p ∈ Icc (g p) (h p)) →
      ContinuousOn (fun p : ℝ × ℝ => F₃ (p.1, p.2, k p)) D := by
    intro k hk hkm
    refine hF₃.comp (continuousOn_fst.prodMk (continuousOn_snd.prodMk hk)) ?_
    intro p hp
    exact ⟨by simpa using hp, by simpa using hkm p hp⟩
  have hH := (hcomp h hhc fun p hp => ⟨hgh p hp, le_rfl⟩).integrableOn_compact (μ := volume) hD
  have hG := (hcomp g hgc fun p hp => ⟨le_rfl, hgh p hp⟩).integrableOn_compact (μ := volume) hD
  have hL1 : (fun p : ℝ × ℝ => ![0, 0, F₃ (p.1, p.2, h p)] ⬝ᵥ
      ![-(h' p (1, 0)), -(h' p (0, 1)), 1]) = fun p => F₃ (p.1, p.2, h p) := by
    funext p; simp [dotProduct, Fin.sum_univ_three]
  have hL2 : (fun p : ℝ × ℝ => ![0, 0, F₃ (p.1, p.2, g p)] ⬝ᵥ
      ![g' p (1, 0), g' p (0, 1), -1]) = fun p => -F₃ (p.1, p.2, g p) := by
    funext p; simp [dotProduct, Fin.sum_univ_three]
  rw [hL1, hL2, integral_neg, ← sub_eq_add_neg, ← integral_sub hH hG]
  refine setIntegral_congr_fun hDm fun p hp => ?_
  symm
  have hle := hgh p hp
  have hmaps : MapsTo (fun t : ℝ => ((p.1, p.2, t) : ℝ × ℝ × ℝ)) (Icc (g p) (h p)) S := by
    intro t ht
    exact ⟨by simpa using hp, by simpa using ht⟩
  have hpc : Continuous (fun t : ℝ => ((p.1, p.2, t) : ℝ × ℝ × ℝ)) := by fun_prop
  refine intervalIntegral.integral_eq_sub_of_hasDeriv_right_of_le hle
    (fun t ht => (hF p hp t ht).continuousWithinAt) ?_ ?_
  · intro t ht
    have h1 := hF p hp t (Ioo_subset_Icc_self ht)
    exact ((h1.hasDerivAt (Icc_mem_nhds ht.1 ht.2))).hasDerivWithinAt
  · exact ((hdF.comp hpc.continuousOn hmaps).intervalIntegrable_of_Icc hle)

/-! ### The card's worked numbers (speeds in m/s, k = 1/100 per second, 1 m³ = 1000 L) -/

-- Even supply: divergence 3 × 0.01 = 0.03 per second, which is 30 L/s per m³;
-- over the 2 m³ tank that is 60 L/s.
example : (3:ℚ) * (1 / 100) * 1000 = 30 ∧ (30:ℚ) * 2 = 60 := by norm_num

-- Right end face: 0.01 m/s through 1 m² is 10 L/s. Top face: 0.005 m/s through 2 m² is 10 L/s.
-- Six faces of 10 L/s each: 60 L/s, the same as the supply.
example : (1 / 100 : ℚ) * 1 * 1000 = 10 ∧ (1 / 200 : ℚ) * 2 * 1000 = 10 ∧ (6:ℚ) * 10 = 60 := by
  norm_num

-- Ends supply F₁ = k(x³ + x): divergence 0.01(3x² + 3) is 30 L/s per m³ at the middle (x = 0)
-- and 60 at an end (x = 1).
example : (1 / 100 : ℚ) * (3 * 0 ^ 2 + 3) * 1000 = 30 ∧
    (1 / 100 : ℚ) * (3 * 1 ^ 2 + 3) * 1000 = 60 := by norm_num

-- Ends supply: the end pair passes 2 × 0.02 m/s × 1 m² = 40 L/s; along the length 3x² adds to 2
-- and 1 adds to 2, so 0.01 × 4 = 0.04 m³/s, 40 L/s again; total 40 + 20 + 20 = 80 L/s, and
-- 8 × 0.01 m³/s = 80 L/s.
example : (2:ℚ) * (2 / 100) * 1 * 1000 = 40 ∧ (1 / 100 : ℚ) * (2 + 2) * 1000 = 40 ∧
    (40:ℚ) + 20 + 20 = 80 ∧ (8:ℚ) * (1 / 100) * 1000 = 80 := by norm_num

-- Spherical tank of radius 1 m: inside, 30 L/s per m³ times 4π/3 m³ = 40π L/s; skin, kR = 0.01 m/s
-- over 4π m² is 0.04π m³/s = 40π L/s. Radius 2 m: both sides are eight times that, 320π.
example : (30:ℝ) * (4 / 3 * Real.pi * 1 ^ 3) = 40 * Real.pi ∧
    (1 / 100 : ℝ) * 1 * (4 * Real.pi * 1 ^ 2) * 1000 = 40 * Real.pi ∧
    (30:ℝ) * (4 / 3 * Real.pi * 2 ^ 3) = 320 * Real.pi ∧
    (1 / 100 : ℝ) * 2 * (4 * Real.pi * 2 ^ 2) * 1000 = 320 * Real.pi := by
  refine ⟨by ring, by ring, by ring, by ring⟩

-- What breaks: inward normals read −60 L/s; with the lid left out five faces pass 50 L/s
-- against 60 inside.
example : -((6:ℚ) * 10) = -60 ∧ (5:ℚ) * 10 = 50 ∧ (50:ℚ) ≠ 60 := by norm_num

#print axioms flux_out_of_box_eq_divergence_summed_inside
#print axioms height_flux_between_two_graphs_eq_dz_summed_inside
