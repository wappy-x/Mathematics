-- Free energies: the Helmholtz Maxwell relation (∂S/∂V)_T = (∂p/∂T)_V holds wherever F is twice continuously differentiable, G cannot rise in a change at fixed surrounding temperature and pressure, and equal Gibbs energies along the boiling line give the Clapeyron slope dp/dT = Δs/Δv.
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.ContDiff.Comp

open Topology

/-- Maxwell relation from the Helmholtz free energy. Let `F(T, V)` be twice continuously
differentiable on an open region of temperature–volume states (the card's "smooth
potentials", one phase at a time). Define the entropy `S = -(∂F/∂T)_V` and the pressure
`p = -(∂F/∂V)_T`. Then at every state in the region, `(∂S/∂V)_T = (∂p/∂T)_V`:
the entropy change nobody can measure equals the pressure change anybody can. -/
theorem maxwell_relation_helmholtz (F S p : ℝ → ℝ → ℝ) (Ω : Set (ℝ × ℝ))
    (hΩ : IsOpen Ω) (hF : ContDiffOn ℝ 2 (fun x : ℝ × ℝ => F x.1 x.2) Ω)
    (hS : ∀ T V, S T V = -deriv (fun T' => F T' V) T)
    (hp : ∀ T V, p T V = -deriv (fun V' => F T V') V)
    {T V : ℝ} (hTV : (T, V) ∈ Ω) :
    deriv (fun V' => S T V') V = deriv (fun T' => p T' V) T := by
  set f : ℝ × ℝ → ℝ := fun x => F x.1 x.2 with hfdef
  -- partial derivatives as values of the full derivative
  have hpart : ∀ x : ℝ × ℝ, x ∈ Ω →
      deriv (fun T' => F T' x.2) x.1 = fderiv ℝ f x (1, 0) ∧
      deriv (fun V' => F x.1 V') x.2 = fderiv ℝ f x (0, 1) := by
    intro x hx
    have hd : DifferentiableAt ℝ f x :=
      ((hF.contDiffAt (hΩ.mem_nhds hx)).differentiableAt (by norm_num))
    have h1 : HasDerivAt (fun t : ℝ => (t, x.2)) ((1 : ℝ), (0 : ℝ)) x.1 :=
      (hasDerivAt_id x.1).prodMk (hasDerivAt_const x.1 x.2)
    have h2 : HasDerivAt (fun t : ℝ => (x.1, t)) ((0 : ℝ), (1 : ℝ)) x.2 :=
      (hasDerivAt_const x.2 x.1).prodMk (hasDerivAt_id x.2)
    have e1 := hd.hasFDerivAt.comp_hasDerivAt x.1 (by simpa using h1)
    have e2 := hd.hasFDerivAt.comp_hasDerivAt x.2 (by simpa using h2)
    exact ⟨e1.deriv, e2.deriv⟩
  have hc : ContDiffAt ℝ 2 f (T, V) := hF.contDiffAt (hΩ.mem_nhds hTV)
  have hsymm : IsSymmSndFDerivAt ℝ f (T, V) := hc.isSymmSndFDerivAt (by simp)
  have hD : DifferentiableAt ℝ (fderiv ℝ f) (T, V) :=
    (hc.fderiv_right (m := 1) (by norm_num)).differentiableAt (by norm_num)
  set D := fderiv ℝ (fderiv ℝ f) (T, V) with hDdef
  -- derivative of x ↦ fderiv f x w along a line
  have hline : ∀ (w : ℝ × ℝ) (g : ℝ → ℝ × ℝ) (g' : ℝ × ℝ) (t : ℝ),
      g t = (T, V) → HasDerivAt g g' t →
      HasDerivAt (fun s => fderiv ℝ f (g s) w) (D g' w) t := by
    intro w g g' t hgt hg
    have hA : HasFDerivAt (fun x => fderiv ℝ f x w)
        ((ContinuousLinearMap.apply ℝ ℝ w).comp D) (T, V) :=
      (ContinuousLinearMap.apply ℝ ℝ w).hasFDerivAt.comp (T, V) hD.hasFDerivAt
    rw [← hgt] at hA
    exact hA.comp_hasDerivAt t hg
  have hU : ∀ᶠ x in 𝓝 (T, V), x ∈ Ω := hΩ.mem_nhds hTV
  -- left side
  have hL : deriv (fun V' => S T V') V = -(D (0, 1) (1, 0)) := by
    have hev : (fun V' => S T V') =ᶠ[𝓝 V] fun V' => -(fderiv ℝ f (T, V') (1, 0)) := by
      have hcont : Continuous (fun V' : ℝ => (T, V')) := by fun_prop
      have := hcont.continuousAt.preimage_mem_nhds (x := V) hU
      filter_upwards [this] with V' hV'
      rw [hS, (hpart (T, V') hV').1]
    rw [hev.deriv_eq]
    have h2 : HasDerivAt (fun t : ℝ => (T, t)) ((0 : ℝ), (1 : ℝ)) V :=
      (hasDerivAt_const V T).prodMk (hasDerivAt_id V)
    exact (hline (1, 0) _ _ V rfl h2).neg.deriv
  have hR : deriv (fun T' => p T' V) T = -(D (1, 0) (0, 1)) := by
    have hev : (fun T' => p T' V) =ᶠ[𝓝 T] fun T' => -(fderiv ℝ f (T', V) (0, 1)) := by
      have hcont : Continuous (fun T' : ℝ => (T', V)) := by fun_prop
      have := hcont.continuousAt.preimage_mem_nhds (x := T) hU
      filter_upwards [this] with T' hT'
      rw [hp, (hpart (T', V) hT').2]
    rw [hev.deriv_eq]
    have h1 : HasDerivAt (fun t : ℝ => (t, V)) ((1 : ℝ), (0 : ℝ)) T :=
      (hasDerivAt_id T).prodMk (hasDerivAt_const T V)
    exact (hline (0, 1) _ _ T rfl h1).neg.deriv
  rw [hL, hR, hsymm]

/-- At fixed temperature and pressure, `G` only falls. A substance starts and ends at the
surroundings' temperature `T₀ > 0` and pressure `p₀`. The first law gives the heat taken in
as `Q = ΔU + p₀ ΔV`, and the second law says the entropy generated, `ΔS - Q/T₀`, is not
negative. Then the Gibbs energy `G = U - T₀ S + p₀ V` does not rise. -/
theorem gibbs_energy_only_falls (U₁ U₂ S₁ S₂ V₁ V₂ Q T₀ p₀ : ℝ) (hT₀ : 0 < T₀)
    (hfirst : Q = (U₂ - U₁) + p₀ * (V₂ - V₁))
    (hsecond : 0 ≤ (S₂ - S₁) - Q / T₀) :
    (U₂ - T₀ * S₂ + p₀ * V₂) - (U₁ - T₀ * S₁ + p₀ * V₁) ≤ 0 := by
  have h : Q / T₀ ≤ S₂ - S₁ := by linarith
  rw [div_le_iff₀ hT₀] at h
  nlinarith

/-- The Clapeyron slope. Let `gₗ(T, p)` and `g_g(T, p)` be the Gibbs energies per mole of
liquid and vapour, each differentiable at the point `(T, p_b(T))` of a differentiable
boiling curve `p_b`, and let the two phases have equal Gibbs energy all along the curve
near `T`. With entropies per mole `s = -(∂g/∂T)_p` and volumes per mole `v = (∂g/∂p)_T`,
and the vapour taking up a different volume from the liquid, the boiling pressure climbs
at `dp_b/dT = (s_g - sₗ)/(v_g - vₗ) = Δs/Δv`. -/
theorem clapeyron_slope (gl gg : ℝ → ℝ → ℝ) (pb : ℝ → ℝ) (T sl sg vl vg : ℝ)
    (hgl : DifferentiableAt ℝ (fun x : ℝ × ℝ => gl x.1 x.2) (T, pb T))
    (hgg : DifferentiableAt ℝ (fun x : ℝ × ℝ => gg x.1 x.2) (T, pb T))
    (hpb : DifferentiableAt ℝ pb T)
    (hline : ∀ᶠ t in 𝓝 T, gl t (pb t) = gg t (pb t))
    (hsl : sl = -deriv (fun t => gl t (pb T)) T)
    (hsg : sg = -deriv (fun t => gg t (pb T)) T)
    (hvl : vl = deriv (fun q => gl T q) (pb T))
    (hvg : vg = deriv (fun q => gg T q) (pb T))
    (hΔv : vg ≠ vl) :
    deriv pb T = (sg - sl) / (vg - vl) := by
  set fl : ℝ × ℝ → ℝ := fun x => gl x.1 x.2
  set fg : ℝ × ℝ → ℝ := fun x => gg x.1 x.2
  have hpath : HasDerivAt (fun t : ℝ => (t, pb t)) ((1 : ℝ), deriv pb T) T :=
    (hasDerivAt_id T).prodMk hpb.hasDerivAt
  have hT1 : HasDerivAt (fun t : ℝ => (t, pb T)) ((1 : ℝ), (0 : ℝ)) T :=
    (hasDerivAt_id T).prodMk (hasDerivAt_const T (pb T))
  have hP1 : HasDerivAt (fun q : ℝ => (T, q)) ((0 : ℝ), (1 : ℝ)) (pb T) :=
    (hasDerivAt_const (pb T) T).prodMk (hasDerivAt_id (pb T))
  have al := hgl.hasFDerivAt.comp_hasDerivAt T hpath
  have ag := hgg.hasFDerivAt.comp_hasDerivAt T hpath
  have bl := (hgl.hasFDerivAt.comp_hasDerivAt T hT1)
  have bg := (hgg.hasFDerivAt.comp_hasDerivAt T hT1)
  have cl := (hgl.hasFDerivAt.comp_hasDerivAt (pb T) hP1)
  have cg := (hgg.hasFDerivAt.comp_hasDerivAt (pb T) hP1)
  have esl : sl = -(fderiv ℝ fl (T, pb T) (1, 0)) := by rw [hsl]; exact congrArg _ bl.deriv
  have esg : sg = -(fderiv ℝ fg (T, pb T) (1, 0)) := by rw [hsg]; exact congrArg _ bg.deriv
  have evl : vl = fderiv ℝ fl (T, pb T) (0, 1) := by rw [hvl]; exact cl.deriv
  have evg : vg = fderiv ℝ fg (T, pb T) (0, 1) := by rw [hvg]; exact cg.deriv
  have hdiff := al.sub ag
  have hzero : deriv (fun t => gl t (pb t) - gg t (pb t)) T = 0 := by
    have hev : (fun t => gl t (pb t) - gg t (pb t)) =ᶠ[𝓝 T] fun _ => (0 : ℝ) := by
      filter_upwards [hline] with t ht
      rw [ht, sub_self]
    rw [hev.deriv_eq]; simp
  have key : fderiv ℝ fl (T, pb T) ((1 : ℝ), deriv pb T) -
      fderiv ℝ fg (T, pb T) ((1 : ℝ), deriv pb T) = 0 := by
    rw [← hzero]; exact hdiff.deriv.symm
  have split : ∀ (L : ℝ × ℝ →L[ℝ] ℝ), L ((1 : ℝ), deriv pb T) = L (1, 0) + deriv pb T * L (0, 1) := by
    intro L
    have : ((1 : ℝ), deriv pb T) = ((1 : ℝ), (0 : ℝ)) + deriv pb T • ((0 : ℝ), (1 : ℝ)) := by
      ext <;> simp
    rw [this, map_add, map_smul, smul_eq_mul]
  rw [split, split] at key
  have hne : vg - vl ≠ 0 := sub_ne_zero.mpr hΔv
  rw [eq_div_iff hne, esl, esg, evl, evg]
  linarith

#print axioms maxwell_relation_helmholtz
#print axioms gibbs_energy_only_falls
#print axioms clapeyron_slope
