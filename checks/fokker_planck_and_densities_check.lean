-- Fokker-Planck: moving the generator onto the density on a half-line leaves a wall term, so a bouncing wall forces zero current and a stopping wall forces zero density, and a reflecting mode's slope is an absorbing mode one rate step slower.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.RingTheory.Polynomial.Hermite.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.BumpFunction.InnerProduct

open MeasureTheory Set Filter Topology
open scoped ContDiff

/-- Helper: the wall term with the integral bracketed on its own (the two hypotheses on the
integrands make each integral a genuine one, and the limits kill the far boundary term). -/
lemma adjoint_wall_term_bracketed (μ : ℝ → ℝ) (σ : ℝ) (f p : ℝ → ℝ)
    (hμ : ContDiff ℝ 1 μ) (hf : ContDiff ℝ 2 f) (hp : ContDiff ℝ 2 p)
    (hLf : IntegrableOn
      (fun y => (μ y * deriv f y + 1 / 2 * σ ^ 2 * deriv (deriv f) y) * p y) (Ioi 0))
    (hLp : IntegrableOn
      (fun y => f y * (-deriv (fun z => μ z * p z) y + 1 / 2 * σ ^ 2 * deriv (deriv p) y)) (Ioi 0))
    (hfJ : Tendsto (fun y => f y * (μ y * p y - 1 / 2 * σ ^ 2 * deriv p y)) atTop (𝓝 0))
    (hfp : Tendsto (fun y => deriv f y * p y) atTop (𝓝 0)) :
    ∫ y in Ioi 0, (μ y * deriv f y + 1 / 2 * σ ^ 2 * deriv (deriv f) y) * p y =
      (∫ y in Ioi 0, f y * (-deriv (fun z => μ z * p z) y + 1 / 2 * σ ^ 2 * deriv (deriv p) y))
        - f 0 * (μ 0 * p 0 - 1 / 2 * σ ^ 2 * deriv p 0) - 1 / 2 * σ ^ 2 * deriv f 0 * p 0 := by
  have d1 : Differentiable ℝ f := hf.differentiable (by norm_num)
  have d2 : Differentiable ℝ (deriv f) := (hf.deriv' (n := 1)).differentiable (by norm_num)
  have dp : Differentiable ℝ p := hp.differentiable (by norm_num)
  have dp2 : Differentiable ℝ (deriv p) := (hp.deriv' (n := 1)).differentiable (by norm_num)
  have dμ : Differentiable ℝ μ := hμ.differentiable (by norm_num)
  have hder : ∀ x ∈ Ici (0:ℝ), HasDerivAt
      (fun y => f y * (μ y * p y - 1 / 2 * σ ^ 2 * deriv p y) + 1 / 2 * σ ^ 2 * (deriv f y * p y))
      ((μ x * deriv f x + 1 / 2 * σ ^ 2 * deriv (deriv f) x) * p x
        - f x * (-deriv (fun z => μ z * p z) x + 1 / 2 * σ ^ 2 * deriv (deriv p) x)) x := by
    intro x _
    have hmp : HasDerivAt (fun z => μ z * p z) (deriv (fun z => μ z * p z) x) x :=
      ((dμ x).mul (dp x)).hasDerivAt
    have h := ((d1 x).hasDerivAt.mul (hmp.sub ((dp2 x).hasDerivAt.const_mul (1 / 2 * σ ^ 2)))).add
      (((d2 x).hasDerivAt.mul (dp x).hasDerivAt).const_mul (1 / 2 * σ ^ 2))
    convert h using 1
    simp only [Pi.sub_apply]
    ring
  have hlim : Tendsto
      (fun y => f y * (μ y * p y - 1 / 2 * σ ^ 2 * deriv p y) + 1 / 2 * σ ^ 2 * (deriv f y * p y))
      atTop (𝓝 0) := by
    simpa using hfJ.add (hfp.const_mul (1 / 2 * σ ^ 2))
  have key := integral_Ioi_of_hasDerivAt_of_tendsto' hder (hLf.sub hLp) hlim
  rw [integral_sub hLf hLp] at key
  linear_combination key

/-- Helper: the bracketed wall term for a smooth payoff with compact support. -/
lemma wall_identity_compact (μ : ℝ → ℝ) (σ : ℝ) (f p : ℝ → ℝ)
    (hμ : ContDiff ℝ 1 μ) (hp : ContDiff ℝ 2 p) (hf : ContDiff ℝ ∞ f) (hcs : HasCompactSupport f) :
    ∫ y in Ioi 0, (μ y * deriv f y + 1 / 2 * σ ^ 2 * deriv (deriv f) y) * p y =
      (∫ y in Ioi 0, f y * (-deriv (fun z => μ z * p z) y + 1 / 2 * σ ^ 2 * deriv (deriv p) y))
        - f 0 * (μ 0 * p 0 - 1 / 2 * σ ^ 2 * deriv p 0) - 1 / 2 * σ ^ 2 * deriv f 0 * p 0 := by
  have hf2 : ContDiff ℝ 2 f := hf.of_le (by norm_cast)
  have hf1 : ContDiff ℝ 1 (deriv f) := hf2.deriv' (n := 1)
  have hp1 : ContDiff ℝ 1 (deriv p) := hp.deriv' (n := 1)
  have cμ := hμ.continuous
  have cp := hp.continuous
  have cf := hf2.continuous
  have cf1 : Continuous (deriv f) := hf1.continuous
  have cf2 : Continuous (deriv (deriv f)) := hf1.continuous_deriv le_rfl
  have cp1 : Continuous (deriv p) := hp1.continuous
  have cp2 : Continuous (deriv (deriv p)) := hp1.continuous_deriv le_rfl
  have cmp : Continuous (deriv (fun z => μ z * p z)) :=
    (hμ.mul (hp.of_le (by norm_num))).continuous_deriv le_rfl
  have hc1 := hcs.deriv
  have hc2 := hc1.deriv
  apply adjoint_wall_term_bracketed μ σ f p hμ hf2 hp
  · exact ((by fun_prop : Continuous _).integrable_of_hasCompactSupport
      ((hc1.mul_left.add hc2.mul_left).mul_right)).integrableOn
  · exact ((by fun_prop : Continuous _).integrable_of_hasCompactSupport
      hcs.mul_right).integrableOn
  · exact (HasCompactSupport.is_zero_at_infty
      (hcs.mul_right (f' := fun y => μ y * p y - 1 / 2 * σ ^ 2 * deriv p y))).mono_left
      atTop_le_cocompact
  · exact (HasCompactSupport.is_zero_at_infty (hc1.mul_right (f' := p))).mono_left
      atTop_le_cocompact

#print axioms adjoint_wall_term_bracketed
#print axioms wall_identity_compact

/-- The wall term (Step 2). Let the drift `μ` be a smooth function of position and the noise size
`σ` a constant, with generator `L f = μ f' + (1/2) σ² f''`, adjoint `L* p = -(μ p)' + (1/2) σ² p''`
and probability current `J = μ p - (1/2) σ² p'`. For smooth `f` and `p` whose products die away far
out (`f J → 0` and `f' p → 0`, with both integrands integrable on `y > 0`), moving the derivatives
from the payoff onto the density over the half-line `y > 0` leaves exactly one term at the wall:
`∫₀^∞ (L f) p dy = ∫₀^∞ f (L* p) dy - f(0) J(0) - (1/2) σ² f'(0) p(0)`. -/
theorem adjoint_wall_term (μ : ℝ → ℝ) (σ : ℝ) (f p : ℝ → ℝ)
    (hμ : ContDiff ℝ 1 μ) (hf : ContDiff ℝ 2 f) (hp : ContDiff ℝ 2 p)
    (hLf : IntegrableOn
      (fun y => (μ y * deriv f y + 1 / 2 * σ ^ 2 * deriv (deriv f) y) * p y) (Ioi 0))
    (hLp : IntegrableOn
      (fun y => f y * (-deriv (fun z => μ z * p z) y + 1 / 2 * σ ^ 2 * deriv (deriv p) y)) (Ioi 0))
    (hfJ : Tendsto (fun y => f y * (μ y * p y - 1 / 2 * σ ^ 2 * deriv p y)) atTop (𝓝 0))
    (hfp : Tendsto (fun y => deriv f y * p y) atTop (𝓝 0)) :
    ∫ y in Ioi 0, (μ y * deriv f y + 1 / 2 * σ ^ 2 * deriv (deriv f) y) * p y =
      (∫ y in Ioi 0, f y * (-deriv (fun z => μ z * p z) y + 1 / 2 * σ ^ 2 * deriv (deriv p) y))
        - f 0 * (μ 0 * p 0 - 1 / 2 * σ ^ 2 * deriv p 0) - 1 / 2 * σ ^ 2 * deriv f 0 * p 0 := by
  exact adjoint_wall_term_bracketed μ σ f p hμ hf hp hLf hLp hfJ hfp

/-- The edge conditions (the card's main claim). Let the drift `μ` be smooth, the noise size `σ`
a nonzero constant, and the density `p` smooth on the line, with a wall at `0` and the region
`y > 0`. A reflecting wall is one where the backward equation's payoffs have zero slope at the wall,
`f'(0) = 0`, with `f(0)` free; an absorbing wall is one where they vanish there, `f(0) = 0`, with
`f'(0)` free. The forward equation matches the backward one, `∫₀^∞ (L f) p dy = ∫₀^∞ f (L* p) dy`,
for every such smooth payoff that is zero far out
* at a reflecting wall exactly when the current is zero there, `J(0) = μ(0) p(0) - (1/2) σ² p'(0) = 0`;
* at an absorbing wall exactly when the density is zero there, `p(0) = 0`. -/
theorem fokker_planck_wall_conditions (μ : ℝ → ℝ) (σ : ℝ) (p : ℝ → ℝ)
    (hμ : ContDiff ℝ 1 μ) (hσ : σ ≠ 0) (hp : ContDiff ℝ 2 p) :
    ((∀ f : ℝ → ℝ, ContDiff ℝ ∞ f → HasCompactSupport f → deriv f 0 = 0 →
        ∫ y in Ioi 0, (μ y * deriv f y + 1 / 2 * σ ^ 2 * deriv (deriv f) y) * p y =
          ∫ y in Ioi 0, f y * (-deriv (fun z => μ z * p z) y + 1 / 2 * σ ^ 2 * deriv (deriv p) y))
      ↔ μ 0 * p 0 - 1 / 2 * σ ^ 2 * deriv p 0 = 0) ∧
    ((∀ f : ℝ → ℝ, ContDiff ℝ ∞ f → HasCompactSupport f → f 0 = 0 →
        ∫ y in Ioi 0, (μ y * deriv f y + 1 / 2 * σ ^ 2 * deriv (deriv f) y) * p y =
          ∫ y in Ioi 0, f y * (-deriv (fun z => μ z * p z) y + 1 / 2 * σ ^ 2 * deriv (deriv p) y))
      ↔ p 0 = 0) := by
  set b : ContDiffBump (0 : ℝ) := default
  have hbs : ContDiff ℝ ∞ (fun x => b x) := b.contDiff
  have hbc : HasCompactSupport (fun x => b x) := b.hasCompactSupport
  have hb0 : b 0 = 1 := b.one_of_mem_closedBall (Metric.mem_closedBall_self b.rIn_pos.le)
  have hbd : deriv (fun x => b x) 0 = 0 := by
    have hev : (fun x => b x) =ᶠ[𝓝 0] fun _ => (1 : ℝ) :=
      Filter.eventually_of_mem (Metric.ball_mem_nhds 0 b.rIn_pos)
        (fun x hx => b.one_of_mem_closedBall (Metric.ball_subset_closedBall hx))
    rw [hev.deriv_eq, deriv_const]
  have hgs : ContDiff ℝ ∞ (fun x => x * b x) := contDiff_id.mul hbs
  have hgc : HasCompactSupport (fun x => x * b x) := hbc.mul_left
  have hg0 : (fun x : ℝ => x * b x) 0 = 0 := by simp
  have hgd : deriv (fun x => x * b x) 0 = 1 := by
    have : HasDerivAt (fun x => x * b x) (1 * b 0 + 0 * deriv (fun x => b x) 0) 0 :=
      (hasDerivAt_id' (0 : ℝ)).mul
        ((hbs.differentiable (by simp)) 0).hasDerivAt
    rw [this.deriv, hb0]; ring
  refine ⟨⟨fun h => ?_, fun hJ f hf hcs hd => ?_⟩, ⟨fun h => ?_, fun hp0 f hf hcs h0 => ?_⟩⟩
  · have e := wall_identity_compact μ σ _ p hμ hp hbs hbc
    rw [h _ hbs hbc hbd, hb0, hbd] at e
    linear_combination e
  · rw [wall_identity_compact μ σ f p hμ hp hf hcs, hJ, hd]; ring
  · have e := wall_identity_compact μ σ _ p hμ hp hgs hgc
    rw [h _ hgs hgc hg0, hgd] at e
    have : 1 / 2 * σ ^ 2 * p 0 = 0 := by linear_combination e
    simpa [hσ] using this
  · rw [wall_identity_compact μ σ f p hμ hp hf hcs, h0, hp0]; ring

/-- The two walls differ by `κ` (Step 5). In the scaled distance `z`, a mode `e^(-ν κ t) φ(z)` on
the region `z > z₀` beyond a wall at `z₀` solves `φ'' - z φ' + ν φ = 0`; a reflecting wall asks
`φ'(z₀) = 0` and an absorbing wall asks `φ(z₀) = 0`.
* The slope `ψ = φ'` of a reflecting mode with rate `ν` is an absorbing mode with rate `ν - 1`.
* Back again, for `ν ≠ 0`: from an absorbing mode `ψ` with rate `ν - 1`, the function
  `φ = (z ψ - ψ') / ν` is a reflecting mode with rate `ν`, and its slope is `ψ`.
So reflecting rates are absorbing rates plus one in units of `κ`: plus `κ` per year. -/
theorem reflecting_mode_iff_absorbing_mode (ν z₀ : ℝ) :
    (∀ φ : ℝ → ℝ, ContDiff ℝ 3 φ →
      (∀ z ∈ Ioi z₀, deriv (deriv φ) z - z * deriv φ z + ν * φ z = 0) → deriv φ z₀ = 0 →
      (∀ z ∈ Ioi z₀,
        deriv (deriv (deriv φ)) z - z * deriv (deriv φ) z + (ν - 1) * deriv φ z = 0) ∧
      deriv φ z₀ = 0) ∧
    (ν ≠ 0 → ∀ ψ : ℝ → ℝ, ContDiff ℝ 3 ψ →
      (∀ z ∈ Ioi z₀, deriv (deriv ψ) z - z * deriv ψ z + (ν - 1) * ψ z = 0) → ψ z₀ = 0 →
      (∀ z ∈ Ioi z₀,
        deriv (deriv (fun w => (w * ψ w - deriv ψ w) / ν)) z
          - z * deriv (fun w => (w * ψ w - deriv ψ w) / ν) z
          + ν * ((z * ψ z - deriv ψ z) / ν) = 0) ∧
      deriv (fun w => (w * ψ w - deriv ψ w) / ν) z₀ = 0 ∧
      (∀ z ∈ Ioi z₀, deriv (fun w => (w * ψ w - deriv ψ w) / ν) z = ψ z)) := by
  refine ⟨fun φ hφ hE h0 => ⟨fun z hz => ?_, h0⟩, fun hν ψ hψ hE h0 => ?_⟩
  · have d1 : Differentiable ℝ φ := hφ.differentiable (by norm_num)
    have h2 : ContDiff ℝ 2 (deriv φ) := hφ.deriv' (n := 2)
    have d2 : Differentiable ℝ (deriv φ) := h2.differentiable (by norm_num)
    have d3 : Differentiable ℝ (deriv (deriv φ)) := h2.differentiable_deriv_two
    have hG : HasDerivAt (fun w => deriv (deriv φ) w - w * deriv φ w + ν * φ w)
        (deriv (deriv (deriv φ)) z - (1 * deriv φ z + z * deriv (deriv φ) z) + ν * deriv φ z) z :=
      ((d3 z).hasDerivAt.sub ((hasDerivAt_id' z).mul (d2 z).hasDerivAt)).add
        ((d1 z).hasDerivAt.const_mul ν)
    have hev : (fun w => deriv (deriv φ) w - w * deriv φ w + ν * φ w) =ᶠ[𝓝 z] fun _ => 0 :=
      Filter.eventually_of_mem (isOpen_Ioi.mem_nhds hz) hE
    have := hG.deriv
    rw [hev.deriv_eq, deriv_const] at this
    linear_combination -this
  · have d1 : Differentiable ℝ ψ := hψ.differentiable (by norm_num)
    have h2 : ContDiff ℝ 2 (deriv ψ) := hψ.deriv' (n := 2)
    have d2 : Differentiable ℝ (deriv ψ) := h2.differentiable (by norm_num)
    have c3 : Continuous (deriv (deriv ψ)) := h2.continuous_deriv (by norm_num)
    have hD : ∀ w, HasDerivAt (fun w => (w * ψ w - deriv ψ w) / ν)
        ((1 * ψ w + w * deriv ψ w - deriv (deriv ψ) w) / ν) w := fun w =>
      (((hasDerivAt_id' w).mul (d1 w).hasDerivAt).sub (d2 w).hasDerivAt).div_const ν
    have hI : ∀ z ∈ Ioi z₀, deriv (fun w => (w * ψ w - deriv ψ w) / ν) z = ψ z := by
      intro z hz
      rw [(hD z).deriv]
      have := hE z hz
      field_simp
      linear_combination -this
    refine ⟨fun z hz => ?_, ?_, hI⟩
    · have hev : deriv (fun w => (w * ψ w - deriv ψ w) / ν) =ᶠ[𝓝 z] ψ :=
        Filter.eventually_of_mem (isOpen_Ioi.mem_nhds hz) hI
      rw [hev.deriv_eq, hI z hz]
      field_simp
      ring
    · have hcl : IsClosed {z | deriv (deriv ψ) z - z * deriv ψ z + (ν - 1) * ψ z = 0} :=
        isClosed_eq (by fun_prop) continuous_const
      have hsub : Ioi z₀ ⊆ {z | deriv (deriv ψ) z - z * deriv ψ z + (ν - 1) * ψ z = 0} := hE
      have hz₀ : z₀ ∈ closure (Ioi z₀) := by rw [closure_Ioi]; exact self_mem_Ici
      have := hcl.closure_subset_iff.mpr hsub hz₀
      simp only [mem_ofPred_eq, h0, mul_zero, add_zero] at this
      rw [(hD z₀).deriv, h0]
      field_simp
      linear_combination -this

/-! ### The card's whole-number facts -/

-- The Hermite polynomials 1, z, z² - 1: the no-wall mode shapes.
example : Polynomial.hermite 0 = 1 ∧ Polynomial.hermite 1 = Polynomial.X ∧
    Polynomial.hermite 2 = Polynomial.X ^ 2 - 1 := by
  refine ⟨by simp, Polynomial.hermite_one, ?_⟩
  rw [Polynomial.hermite_succ, Polynomial.hermite_one]
  simp; ring
-- He₂ = z² - 1 solves the mode equation φ'' - z φ' + ν φ = 0 with ν = 2: 2 - z (2 z) + 2 (z² - 1) = 0.
example (z : ℝ) : 2 - z * (2 * z) + 2 * (z ^ 2 - 1) = 0 := by ring
-- Long-run variance σ² / (2 κ) with κ = 1/2 per year and σ = 2: 4 points squared, standard deviation 2.
example : (2 : ℚ) ^ 2 / (2 * (1 / 2)) = 4 ∧ (2 : ℚ) ^ 2 = 4 := by norm_num
-- The start 6 points is z = (6 - 4) / 2 = 1; the wall at 0 points is z = (0 - 4) / 2 = -2.
example : ((6 : ℚ) - 4) / 2 = 1 ∧ ((0 : ℚ) - 4) / 2 = -2 := by norm_num
-- With zero slope at the floor the current there is μ(0) p = κ θ p = 2 p, not zero.
example : (1 / 2 : ℚ) * (4 - 0) = 2 := by norm_num

#print axioms adjoint_wall_term
#print axioms fokker_planck_wall_conditions
#print axioms reflecting_mode_iff_absorbing_mode
