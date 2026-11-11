-- The maximum modulus principle: a non-constant holomorphic function on a bounded region, continuous up to the edge, takes its largest modulus only on the edge (and its smallest too when it has no zeros), and a local peak of the modulus inside a region makes the function constant there.
import Mathlib.Analysis.Complex.AbsMax
import Mathlib.Analysis.Complex.Basic
import Mathlib.Tactic.NormNum

open Set Complex

/-- **The maximum modulus principle.** Let D be a bounded region: an open set in the plane, in
one piece, that fits inside some disc. Let f be holomorphic (complex-differentiable) at every
point of D, continuous on D together with its edge (the closure of D), and not constant on D.
Then the modulus |f| takes a largest value on the closure of D, and every point of the closure
where it does so lies on the boundary (the frontier) of D: |f| has no interior peak. -/
theorem max_modulus_only_on_boundary {D : Set ℂ} {f : ℂ → ℂ}
    (hD : IsOpen D) (hconn : IsPreconnected D) (hbdd : Bornology.IsBounded D)
    (hf : DifferentiableOn ℂ f D) (hcont : ContinuousOn f (closure D))
    (hnc : ∃ z ∈ D, ∃ w ∈ D, f z ≠ f w) :
    (∃ z ∈ closure D, IsMaxOn (fun w => ‖f w‖) (closure D) z) ∧
      ∀ z ∈ closure D, IsMaxOn (fun w => ‖f w‖) (closure D) z → z ∈ frontier D := by
  have hnc' := hnc
  obtain ⟨a, haD, -⟩ := hnc
  have hK : IsCompact (closure D) := hbdd.isCompact_closure
  refine ⟨hK.exists_isMaxOn ⟨a, subset_closure haD⟩ (continuous_norm.comp_continuousOn hcont), ?_⟩
  intro z hz hmax
  by_contra hfr
  have hzD : z ∈ D := by
    rw [hD.frontier_eq] at hfr
    by_contra h
    exact hfr ⟨hz, h⟩
  have hm : IsMaxOn (norm ∘ f) D z := fun w hw => hmax (subset_closure hw)
  have hEq := Complex.eqOn_of_isPreconnected_of_isMaxOn_norm hconn hD hf hzD hm
  obtain ⟨x, hx, y, hy, hxy⟩ := hnc'
  exact hxy ((hEq hx).trans (hEq hy).symm)

/-- **The minimum version.** With the same bounded region D and the same non-constant f,
holomorphic on D and continuous up to the edge, suppose also that f has no zeros on the closure
of D. Then |f| takes a smallest value on the closure of D, and every point of the closure where
it does so lies on the boundary of D. -/
theorem min_modulus_only_on_boundary_of_no_zeros {D : Set ℂ} {f : ℂ → ℂ}
    (hD : IsOpen D) (hconn : IsPreconnected D) (hbdd : Bornology.IsBounded D)
    (hf : DifferentiableOn ℂ f D) (hcont : ContinuousOn f (closure D))
    (hnc : ∃ z ∈ D, ∃ w ∈ D, f z ≠ f w) (hzero : ∀ z ∈ closure D, f z ≠ 0) :
    (∃ z ∈ closure D, IsMinOn (fun w => ‖f w‖) (closure D) z) ∧
      ∀ z ∈ closure D, IsMinOn (fun w => ‖f w‖) (closure D) z → z ∈ frontier D := by
  have hg : DifferentiableOn ℂ (fun w => (f w)⁻¹) D := fun w hw =>
    (hf w hw).inv (hzero w (subset_closure hw))
  have hgc : ContinuousOn (fun w => (f w)⁻¹) (closure D) := hcont.inv₀ hzero
  have hgnc : ∃ z ∈ D, ∃ w ∈ D, (f z)⁻¹ ≠ (f w)⁻¹ := by
    obtain ⟨x, hx, y, hy, hxy⟩ := hnc
    exact ⟨x, hx, y, hy, fun h => hxy (inv_injective h)⟩
  have key : ∀ z ∈ closure D, IsMinOn (fun w => ‖f w‖) (closure D) z ↔
      IsMaxOn (fun w => ‖(f w)⁻¹‖) (closure D) z := by
    intro z hz
    constructor
    · intro h w hw
      have h1 : ‖f z‖ ≤ ‖f w‖ := h hw
      have hz0 : 0 < ‖f z‖ := norm_pos_iff.mpr (hzero z hz)
      show ‖(f w)⁻¹‖ ≤ ‖(f z)⁻¹‖
      rw [norm_inv, norm_inv]
      exact inv_anti₀ hz0 h1
    · intro h w hw
      have h1 : ‖(f w)⁻¹‖ ≤ ‖(f z)⁻¹‖ := h hw
      have hw0 : 0 < ‖f w‖ := norm_pos_iff.mpr (hzero w hw)
      show ‖f z‖ ≤ ‖f w‖
      rw [norm_inv, norm_inv] at h1
      exact (inv_le_inv₀ hw0 (norm_pos_iff.mpr (hzero z hz))).mp h1
  obtain ⟨⟨z, hz, hzmax⟩, hfr⟩ := max_modulus_only_on_boundary hD hconn hbdd hg hgc hgnc
  exact ⟨⟨z, hz, (key z hz).mpr hzmax⟩, fun w hw hmin => hfr w hw ((key w hw).mp hmin)⟩

/-- **The local form.** If f is holomorphic on a region D (open, in one piece) and its modulus
|f| has a local maximum at a point c inside D (|f(z)| ≤ |f(c)| for all z near c, a flat top
allowed), then f is constant on D: f(z) = f(c) for every z in D. -/
theorem eq_const_of_isLocalMax_norm {D : Set ℂ} {f : ℂ → ℂ} {c : ℂ}
    (hD : IsOpen D) (hconn : IsPreconnected D) (hf : DifferentiableOn ℂ f D) (hc : c ∈ D)
    (hmax : IsLocalMax (fun w => ‖f w‖) c) :
    ∀ z ∈ D, f z = f c := by
  have hev : ∀ᶠ z in nhds c, f z = f c :=
    Complex.eventually_eq_of_isLocalMax_norm
      (Filter.eventually_of_mem (hD.mem_nhds hc) fun z hz => hf.differentiableAt (hD.mem_nhds hz))
      hmax
  have han : AnalyticOnNhd ℂ f D := hf.analyticOnNhd hD
  have := han.eqOn_of_preconnected_of_eventuallyEq analyticOnNhd_const hconn hc hev
  exact fun z hz => this hz

-- The card's whole-number examples.
-- z^2 + 1 reaches modulus 2 at the rim points 1 and −1 of the unit disc.
example : ‖(1 : ℂ) ^ 2 + 1‖ = 2 := by norm_num
example : ‖(-1 : ℂ) ^ 2 + 1‖ = 2 := by norm_num
-- Zeros allowed: z^2 + 1 is 0 at i, inside the disc of radius 2 ...
example : I ^ 2 + 1 = 0 := by norm_num
-- ... while on its edge, at 2i, the modulus is 3 (the edge minimum).
example : ‖(2 * I) ^ 2 + 1‖ = 3 := by norm_num [mul_pow]

#print axioms max_modulus_only_on_boundary
#print axioms min_modulus_only_on_boundary_of_no_zeros
#print axioms eq_const_of_isLocalMax_norm
