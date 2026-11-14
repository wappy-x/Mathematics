-- The quantum oscillator: a spring's quantum energy levels are exactly (n + 1/2) ħω for n = 0, 1, 2, …, the ladder operators factor the energy operator with a half left over, and the bell curve e^(−ξ²/2) is the floor state with energy 1/2 in units of ħω.
import Mathlib.Analysis.Distribution.SchwartzSpace.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Distribution.SchwartzSpace.Deriv
import Mathlib.Analysis.Calculus.DerivativeTest
import Mathlib.Analysis.SpecialFunctions.Gaussian.PoissonSummation
import Mathlib.RingTheory.Polynomial.Hermite.Gaussian
import Mathlib.Analysis.Polynomial.Basic

open SchwartzMap

/-- The lowering operator a = (ξ + d/dξ)/√2, acting on a function of the scaled stretch ξ. -/
noncomputable def lower (f : ℝ → ℝ) : ℝ → ℝ := fun ξ => (ξ * f ξ + deriv f ξ) / Real.sqrt 2

/-- The raising operator a† = (ξ − d/dξ)/√2. -/
noncomputable def raise (f : ℝ → ℝ) : ℝ → ℝ := fun ξ => (ξ * f ξ - deriv f ξ) / Real.sqrt 2

/-- The energy operator in units of ħω, with the stretch measured in units of x₀:
H/ħω = −½ d²/dξ² + ½ ξ². -/
noncomputable def oscH (f : ℝ → ℝ) : ℝ → ℝ := fun ξ => -(1 / 2) * deriv (deriv f) ξ + 1 / 2 * ξ ^ 2 * f ξ

open Filter Topology in
/-- A polynomial times a Gaussian, times any power of |x|, is bounded. -/
lemma qho_poly_gauss_bounded (P : Polynomial ℤ) (k : ℕ) :
    ∃ C : ℝ, ∀ x : ℝ, |x| ^ k * |Polynomial.aeval x P| * Real.exp (-(x ^ 2 / 2)) ≤ C := by
  set P' : Polynomial ℝ := P.map (algebraMap ℤ ℝ) with hP'
  have hev : ∀ x : ℝ, Polynomial.aeval x P = P'.eval x := fun x => by
    rw [hP', Polynomial.eval_map_algebraMap]
  set d := P'.natDegree
  set q : ℝ → ℝ := fun x => |x| ^ k * |Polynomial.aeval x P| * Real.exp (-(x ^ 2 / 2)) with hq
  have h1 : (fun x => P'.eval x) =O[cocompact ℝ] (fun x => x ^ d) := by
    rw [← Metric.cobounded_eq_cocompact]
    exact Polynomial.isBigO_cobounded_pow_natDegree P'
  have h2 : (fun x : ℝ => x ^ k * P'.eval x * Real.exp (-(x ^ 2 / 2))) =O[cocompact ℝ]
      (fun x : ℝ => x ^ k * x ^ d * Real.exp (-(x ^ 2 / 2))) :=
    ((Asymptotics.isBigO_refl _ _).mul h1).mul (Asymptotics.isBigO_refl _ _)
  have h3 : q =O[cocompact ℝ]
      (fun x : ℝ => |x| ^ ((k + d : ℕ) : ℝ) * Real.exp (-(1 / 2) * x ^ 2)) := by
    have := h2.norm_left.norm_right
    refine this.congr (fun x => ?_) (fun x => ?_)
    · simp only [hq, Real.norm_eq_abs, abs_mul, abs_pow, hev, abs_of_pos (Real.exp_pos _)]
    · simp only [Real.norm_eq_abs, abs_mul, abs_pow, abs_of_pos (Real.exp_pos _),
        Real.rpow_natCast, pow_add]
      ring_nf
  have ht : Tendsto q (cocompact ℝ) (𝓝 0) :=
    h3.trans_tendsto (tendsto_rpow_abs_mul_exp_neg_mul_sq_cocompact (by norm_num) _)
  have hev1 : ∀ᶠ x in cocompact ℝ, q x ≤ 1 :=
    ht.eventually (ge_mem_nhds (by norm_num))
  have hqc : Continuous q := by
    have : Continuous fun x : ℝ => P'.eval x := P'.continuous
    simp only [hq, hev]
    fun_prop
  set r : ℝ → ℝ := fun x => max (q x) 1 with hr
  have hrc : Continuous r := hqc.max continuous_const
  obtain ⟨xm, hxm⟩ := hrc.exists_forall_ge' 0 (by
    filter_upwards [hev1] with x hx
    simp only [hr, max_eq_right hx]
    exact le_max_right _ _)
  exact ⟨r xm, fun x => (le_max_left _ _).trans (hxm x)⟩

/-- The bell curve e^(−y²/2) as a Schwartz function. -/
noncomputable def qhoGauss : 𝓢(ℝ, ℝ) where
  toFun := fun y => Real.exp (-(y ^ 2 / 2))
  smooth' := by fun_prop
  decay' := by
    intro k n
    obtain ⟨C, hC⟩ := qho_poly_gauss_bounded (Polynomial.hermite n) k
    refine ⟨C, fun x => ?_⟩
    rw [norm_iteratedFDeriv_eq_norm_iteratedDeriv, iteratedDeriv_eq_iterate,
      Polynomial.deriv_gaussian_eq_hermite_mul_gaussian]
    simp only [Real.norm_eq_abs, abs_mul, abs_pow, abs_neg, abs_one, one_pow, one_mul,
      abs_of_pos (Real.exp_pos _)]
    simpa [mul_assoc] using hC x

lemma qhoGauss_apply (y : ℝ) : qhoGauss y = Real.exp (-(y ^ 2 / 2)) := rfl


/-- The ladder step φ ↦ l x φ + s φ' on Schwartz functions (s = 1 lowers, s = −1 raises). -/
noncomputable def qhoLadder (l s : ℝ) (φ : 𝓢(ℝ, ℝ)) : 𝓢(ℝ, ℝ) :=
  smulLeftCLM ℝ (fun x : ℝ => l * x) φ + s • derivCLM ℝ ℝ φ

lemma qhoLadder_apply (l s : ℝ) (φ : 𝓢(ℝ, ℝ)) (x : ℝ) :
    qhoLadder l s φ x = l * x * φ x + s * deriv φ x := by
  have hg : (fun x : ℝ => l * x).HasTemperateGrowth := by fun_prop
  simp [qhoLadder, smulLeftCLM_apply_apply hg]

/-- The scaled eigen-equation φ'' = l² x² φ − Λ φ. -/
def QhoEig (l Λ : ℝ) (φ : 𝓢(ℝ, ℝ)) : Prop :=
  ∀ x, deriv (deriv φ) x = l ^ 2 * x ^ 2 * φ x - Λ * φ x

lemma qho_deriv_hasDerivAt (φ : 𝓢(ℝ, ℝ)) (x : ℝ) :
    HasDerivAt (deriv φ) (deriv (deriv φ) x) x := by
  have h := (derivCLM ℝ ℝ φ).hasDerivAt x
  have hc : ⇑(derivCLM ℝ ℝ φ) = deriv φ := funext fun y => derivCLM_apply ℝ φ y
  rwa [hc] at h

lemma qhoLadder_eig (l s Λ : ℝ) (hs : s ^ 2 = 1) (φ : 𝓢(ℝ, ℝ)) (h : QhoEig l Λ φ) :
    QhoEig l (Λ - 2 * s * l) (qhoLadder l s φ) := by
  have e2 : deriv (deriv φ) = fun x => l ^ 2 * x ^ 2 * φ x - Λ * φ x := funext h
  have hd1 : ∀ x, HasDerivAt φ (deriv φ x) x := fun x => φ.hasDerivAt x
  have hd2 : ∀ x, HasDerivAt (deriv φ) (l ^ 2 * x ^ 2 * φ x - Λ * φ x) x := fun x => by
    rw [← h x]; exact qho_deriv_hasDerivAt φ x
  have hd3 : ∀ x, HasDerivAt (fun x => l ^ 2 * x ^ 2 * φ x - Λ * φ x)
      (l ^ 2 * (2 * x) * φ x + l ^ 2 * x ^ 2 * deriv φ x - Λ * deriv φ x) x := fun x => by
    have := ((((hasDerivAt_pow 2 x).const_mul (l ^ 2)).mul (hd1 x)).sub
      ((hd1 x).const_mul Λ))
    convert this using 1; push_cast; ring
  have hc : ⇑(qhoLadder l s φ) = fun x => l * x * φ x + s * deriv φ x :=
    funext (qhoLadder_apply l s φ)
  have hL1 : ∀ x, HasDerivAt (fun x => l * x * φ x + s * deriv φ x)
      (l * φ x + l * x * deriv φ x + s * (l ^ 2 * x ^ 2 * φ x - Λ * φ x)) x := fun x => by
    have := (((hasDerivAt_id' x).const_mul l).mul (hd1 x)).add ((hd2 x).const_mul s)
    convert this using 1; ring
  have dL1 : deriv (fun x => l * x * φ x + s * deriv φ x) =
      fun x => l * φ x + l * x * deriv φ x + s * (l ^ 2 * x ^ 2 * φ x - Λ * φ x) :=
    funext fun x => (hL1 x).deriv
  intro x
  rw [hc, dL1]
  have hL2 : HasDerivAt
      (fun x => l * φ x + l * x * deriv φ x + s * (l ^ 2 * x ^ 2 * φ x - Λ * φ x))
      (l * deriv φ x + (l * 1 * deriv φ x + l * x * (l ^ 2 * x ^ 2 * φ x - Λ * φ x)) +
        s * (l ^ 2 * (2 * x) * φ x + l ^ 2 * x ^ 2 * deriv φ x - Λ * deriv φ x)) x :=
    ((((hd1 x).const_mul l).add (((hasDerivAt_id' x).const_mul l).mul (hd2 x))).add
      ((hd3 x).const_mul s))
  rw [hL2.deriv]
  linear_combination (-2 * l * deriv φ x) * hs

lemma qhoLadder_kill (l s Λ : ℝ) (hs : s ^ 2 = 1) (φ : 𝓢(ℝ, ℝ)) (h : QhoEig l Λ φ)
    (h0 : qhoLadder l s φ = 0) : ∀ x, (Λ - s * l) * φ x = 0 := by
  have hz : ∀ x, l * x * φ x + s * deriv φ x = 0 := fun x => by
    rw [← qhoLadder_apply, h0]; rfl
  have hd : deriv φ = fun x => -s * l * x * φ x := funext fun x => by
    linear_combination s * hz x - deriv φ x * hs
  have hd2 : ∀ x, HasDerivAt (fun x => -s * l * x * φ x)
      (-s * l * φ x + -s * l * x * deriv φ x) x := fun x => by
    have := ((hasDerivAt_id' x).const_mul (-s * l)).mul (φ.hasDerivAt x)
    convert this using 1; ring
  intro x
  have e := h x
  rw [hd, (hd2 x).deriv, hd] at e
  linear_combination e - l ^ 2 * x ^ 2 * φ x * hs

open Filter Topology in
/-- Maximum principle: a function vanishing at infinity with f'' = q f, q > 0, is never positive. -/
lemma qho_max_principle (f : ℝ → ℝ) (hc : Continuous f) (ht : Tendsto f (cocompact ℝ) (𝓝 0))
    (q : ℝ → ℝ) (hq : ∀ x, 0 < q x) (he : ∀ x, deriv (deriv f) x = q x * f x) :
    ∀ x, f x ≤ 0 := by
  by_contra hne
  push Not at hne
  obtain ⟨x1, hx1⟩ := hne
  obtain ⟨x0, hx0⟩ := hc.exists_forall_ge' x1 (ht.eventually (gt_mem_nhds hx1) |>.mono
    fun x hx => hx.le)
  have hpos : 0 < f x0 := hx1.trans_le (hx0 x1)
  have hmax : IsLocalMax f x0 := Filter.Eventually.of_forall hx0
  have hd : deriv f x0 = 0 := hmax.deriv_eq_zero
  have hdd : deriv (deriv f) x0 > 0 := by rw [he]; exact mul_pos (hq x0) hpos
  have hmin : IsLocalMin f x0 := isLocalMin_of_deriv_deriv_pos hdd hd hc.continuousAt
  have hloc : f =ᶠ[𝓝 x0] fun _ => f x0 := by
    filter_upwards [hmin, hmax] with y h1 h2 using le_antisymm h2 h1
  have := hloc.deriv.deriv_eq
  simp only [deriv_const'] at this
  have h00 : deriv (deriv f) x0 = 0 := by rw [this]
  linarith

lemma qho_no_negative (l Λ : ℝ) (hΛ : Λ < 0) (φ : 𝓢(ℝ, ℝ)) (h : QhoEig l Λ φ) : φ = 0 := by
  have hq : ∀ x, 0 < l ^ 2 * x ^ 2 - Λ := fun x => by nlinarith [sq_nonneg (l * x)]
  have A := qho_max_principle φ φ.continuous φ.tendsto_cocompact (fun x => l ^ 2 * x ^ 2 - Λ) hq
    (fun x => by rw [h x]; ring)
  have hnd : deriv (fun x => -φ x) = fun x => -deriv φ x := funext fun x => deriv.fun_neg
  have hnd2 : deriv (fun x => -deriv φ x) = fun x => -deriv (deriv φ) x :=
    funext fun x => deriv.fun_neg
  have B := qho_max_principle (fun x => -φ x) φ.continuous.neg (by
      simpa using φ.tendsto_cocompact.neg) (fun x => l ^ 2 * x ^ 2 - Λ) hq
    (fun x => by rw [hnd, hnd2]; simp only; rw [h x]; ring)
  ext x
  have := A x
  have := B x
  simp only [zero_apply]
  linarith


/-- The scaled ground state e^(−l x²/2) as a Schwartz function. -/
noncomputable def qhoGround (l : ℝ) (hl : 0 < l) : 𝓢(ℝ, ℝ) :=
  compCLMOfContinuousLinearEquiv ℝ
    (ContinuousLinearEquiv.unitsEquivAut ℝ (Units.mk0 (Real.sqrt l) (Real.sqrt_pos.2 hl).ne'))
    qhoGauss

lemma qhoGround_coe (l : ℝ) (hl : 0 < l) :
    ⇑(qhoGround l hl) = fun x => Real.exp (-(l * x ^ 2 / 2)) := by
  funext x
  simp only [qhoGround, compCLMOfContinuousLinearEquiv_apply, Function.comp_apply,
    ContinuousLinearEquiv.unitsEquivAut_apply, Units.val_mk0, qhoGauss_apply, mul_pow,
    Real.sq_sqrt hl.le]
  ring_nf

lemma qhoGround_eig (l : ℝ) (hl : 0 < l) : QhoEig l l (qhoGround l hl) := by
  have hg : ∀ x : ℝ, HasDerivAt (fun x => Real.exp (-(l * x ^ 2 / 2)))
      (-l * x * Real.exp (-(l * x ^ 2 / 2))) x := fun x => by
    have h0 : HasDerivAt (fun x : ℝ => -(l * x ^ 2 / 2)) (-l * x) x := by
      have := (((hasDerivAt_pow 2 x).const_mul l).div_const 2).neg
      convert this using 1; push_cast; ring
    convert h0.exp using 1; ring
  have dg : deriv (fun x => Real.exp (-(l * x ^ 2 / 2))) =
      fun x => -l * x * Real.exp (-(l * x ^ 2 / 2)) := funext fun x => (hg x).deriv
  intro x
  rw [qhoGround_coe, dg]
  have e : HasDerivAt (fun x => -l * x * Real.exp (-(l * x ^ 2 / 2)))
      (-l * 1 * Real.exp (-(l * x ^ 2 / 2)) + -l * x * (-l * x * Real.exp (-(l * x ^ 2 / 2)))) x :=
    ((hasDerivAt_id' x).const_mul (-l)).mul (hg x)
  rw [e.deriv]
  ring

lemma qhoGround_ne (l : ℝ) (hl : 0 < l) : qhoGround l hl ≠ 0 := by
  intro h
  have := congrArg (fun φ : 𝓢(ℝ, ℝ) => φ 0) h
  simp only [qhoGround_coe, zero_apply] at this
  norm_num at this

lemma qho_ne_zero_iff (φ : 𝓢(ℝ, ℝ)) : φ ≠ 0 ↔ ∃ x, φ x ≠ 0 := by
  constructor
  · intro h
    by_contra h'
    push Not at h'
    exact h (by ext x; simp [h' x])
  · rintro ⟨x, hx⟩ h
    exact hx (by simp [h])

/-- The scaled spectrum: φ'' = l² x² φ − Λ φ has a nonzero Schwartz solution iff
Λ = l (2n + 1). -/
lemma qho_scaled_spectrum (l Λ : ℝ) (hl : 0 < l) :
    (∃ φ : 𝓢(ℝ, ℝ), φ ≠ 0 ∧ QhoEig l Λ φ) ↔ ∃ n : ℕ, Λ = l * (2 * n + 1) := by
  constructor
  · rintro ⟨φ, hne, hφ⟩
    have hiter : ∀ j : ℕ, QhoEig l (Λ - 2 * l * j) ((qhoLadder l 1)^[j] φ) := by
      intro j
      induction j with
      | zero => simpa using hφ
      | succ j ih =>
        rw [Function.iterate_succ_apply']
        have := qhoLadder_eig l 1 _ (by norm_num) _ ih
        convert this using 1
        push_cast; ring
    have hex : ∃ j, (qhoLadder l 1)^[j] φ = 0 := by
      refine ⟨⌈Λ / (2 * l)⌉₊ + 1, qho_no_negative l _ ?_ _ (hiter _)⟩
      have h1 := Nat.le_ceil (Λ / (2 * l))
      have h2 : Λ ≤ 2 * l * (⌈Λ / (2 * l)⌉₊ : ℝ) := by
        rw [div_le_iff₀ (by positivity)] at h1; linarith
      push_cast
      nlinarith
    classical
    set j0 := Nat.find hex with hj0
    have hj0spec : (qhoLadder l 1)^[j0] φ = 0 := Nat.find_spec hex
    have hj0pos : j0 ≠ 0 := by
      intro h; rw [h] at hj0spec; exact hne hj0spec
    obtain ⟨j, hj⟩ := Nat.exists_eq_succ_of_ne_zero hj0pos
    have hjlt : j < Nat.find hex := by omega
    have hjne : (qhoLadder l 1)^[j] φ ≠ 0 := Nat.find_min hex hjlt
    rw [hj] at hj0spec
    rw [Function.iterate_succ_apply'] at hj0spec
    have hk := qhoLadder_kill l 1 _ (by norm_num) _ (hiter j) hj0spec
    obtain ⟨x, hx⟩ := (qho_ne_zero_iff _).1 hjne
    have := hk x
    rcases mul_eq_zero.1 this with h | h
    · exact ⟨j, by linarith⟩
    · exact absurd h hx
  · rintro ⟨n, rfl⟩
    have hiter : ∀ j : ℕ, (qhoLadder l (-1))^[j] (qhoGround l hl) ≠ 0 ∧
        QhoEig l (l * (2 * j + 1)) ((qhoLadder l (-1))^[j] (qhoGround l hl)) := by
      intro j
      induction j with
      | zero =>
        refine ⟨qhoGround_ne l hl, ?_⟩
        simpa using qhoGround_eig l hl
      | succ j ih =>
        rw [Function.iterate_succ_apply']
        have he := qhoLadder_eig l (-1) _ (by norm_num) _ ih.2
        refine ⟨fun h0 => ?_, ?_⟩
        · have hk := qhoLadder_kill l (-1) _ (by norm_num) _ ih.2 h0
          obtain ⟨x, hx⟩ := (qho_ne_zero_iff _).1 ih.1
          have := hk x
          rcases mul_eq_zero.1 this with h | h
          · have hj0 : (0 : ℝ) ≤ j := Nat.cast_nonneg j
            have : (0 : ℝ) < l * (2 * j + 1) - -1 * l := by nlinarith
            linarith
          · exact hx h
        · convert he using 1
          push_cast; ring
    exact ⟨_, (hiter n).1, (hiter n).2⟩

#print axioms qho_poly_gauss_bounded
#print axioms qhoGauss_apply
#print axioms qhoLadder_apply
#print axioms qho_deriv_hasDerivAt
#print axioms qhoLadder_eig
#print axioms qhoLadder_kill
#print axioms qho_max_principle
#print axioms qho_no_negative
#print axioms qhoGround_coe
#print axioms qhoGround_eig
#print axioms qhoGround_ne
#print axioms qho_ne_zero_iff
#print axioms qho_scaled_spectrum

/-- The card's main claim. A particle of (reduced) mass μ > 0 on a spring of stiffness k > 0
has energy operator Ĥ = −(ħ²/2μ) d²/dx² + ½ k x². Its allowed energies, for states that die
away far out (smooth functions that fall off faster than any power, Schwartz functions), are
exactly E = (n + ½) ħω with n = 0, 1, 2, … and ω = √(k/μ): every such energy has a nonzero
state, and no other energy does. So the levels are evenly spaced by ħω and the lowest sits half
a step above the bottom of the well. -/
theorem oscillator_energies_are_n_plus_half_hbar_omega (hbar μ k E : ℝ)
    (hhbar : 0 < hbar) (hμ : 0 < μ) (hk : 0 < k) :
    (∃ ψ : 𝓢(ℝ, ℝ), ψ ≠ 0 ∧
        ∀ x : ℝ, -(hbar ^ 2 / (2 * μ)) * deriv (deriv ψ) x + 1 / 2 * k * x ^ 2 * ψ x = E * ψ x) ↔
      ∃ n : ℕ, E = ((n : ℝ) + 1 / 2) * hbar * Real.sqrt (k / μ) := by
  set ω := Real.sqrt (k / μ) with hωdef
  have hω : 0 < ω := Real.sqrt_pos.2 (div_pos hk hμ)
  have hω2 : ω ^ 2 = k / μ := Real.sq_sqrt (div_pos hk hμ).le
  set l := μ * ω / hbar with hldef
  have hl : 0 < l := by positivity
  have hl2 : l ^ 2 = μ * k / hbar ^ 2 := by
    rw [hldef, div_pow, mul_pow, hω2]; field_simp
  have heq : ∀ ψ : 𝓢(ℝ, ℝ), (∀ x : ℝ, -(hbar ^ 2 / (2 * μ)) * deriv (deriv ψ) x +
      1 / 2 * k * x ^ 2 * ψ x = E * ψ x) ↔ QhoEig l (2 * μ * E / hbar ^ 2) ψ := by
    intro ψ
    unfold QhoEig
    refine forall_congr' fun x => ?_
    rw [hl2]
    constructor
    · intro h
      field_simp at h ⊢
      linarith
    · intro h
      field_simp at h ⊢
      linarith
  have hiff : (∃ ψ : 𝓢(ℝ, ℝ), ψ ≠ 0 ∧ ∀ x : ℝ, -(hbar ^ 2 / (2 * μ)) * deriv (deriv ψ) x +
      1 / 2 * k * x ^ 2 * ψ x = E * ψ x) ↔
      ∃ ψ : 𝓢(ℝ, ℝ), ψ ≠ 0 ∧ QhoEig l (2 * μ * E / hbar ^ 2) ψ :=
    exists_congr fun ψ => and_congr_right' (heq ψ)
  rw [hiff, qho_scaled_spectrum _ _ hl]
  refine exists_congr fun n => ?_
  rw [hldef]
  constructor
  · intro h
    have hE : E = (2 * μ * E / hbar ^ 2) * hbar ^ 2 / (2 * μ) := by field_simp
    rw [hE, h]
    field_simp
  · intro h
    rw [h]
    field_simp

/-- Step 2 of the card. For any twice-differentiable ψ, the ladder operators factor the energy
with a half left over: a†a ψ = (H/ħω − ½) ψ and a a† ψ = (H/ħω + ½) ψ, so a a† − a†a = 1. -/
theorem ladder_operators_factor_energy (f : ℝ → ℝ) (hf : ContDiff ℝ 2 f) :
    (∀ ξ, raise (lower f) ξ = oscH f ξ - 1 / 2 * f ξ) ∧
      (∀ ξ, lower (raise f) ξ = oscH f ξ + 1 / 2 * f ξ) ∧
      ∀ ξ, lower (raise f) ξ - raise (lower f) ξ = f ξ := by
  have h1 : Differentiable ℝ f := hf.differentiable (by norm_num)
  have h2 : Differentiable ℝ (deriv f) :=
    (contDiff_succ_iff_deriv.mp (show ContDiff ℝ (1 + 1) f from hf)).2.2.differentiable
      (by norm_num)
  have hs : Real.sqrt 2 * Real.sqrt 2 = 2 := Real.mul_self_sqrt (by norm_num)
  have hs0 : Real.sqrt 2 ≠ 0 := by positivity
  have dl : ∀ ξ, deriv (lower f) ξ = (f ξ + ξ * deriv f ξ + deriv (deriv f) ξ) / Real.sqrt 2 := by
    intro ξ
    have := (((hasDerivAt_id ξ).mul (h1 ξ).hasDerivAt).add (h2 ξ).hasDerivAt).div_const
      (Real.sqrt 2)
    simp only [id, one_mul] at this
    exact this.deriv
  have dr : ∀ ξ, deriv (raise f) ξ = (f ξ + ξ * deriv f ξ - deriv (deriv f) ξ) / Real.sqrt 2 := by
    intro ξ
    have := (((hasDerivAt_id ξ).mul (h1 ξ).hasDerivAt).sub (h2 ξ).hasDerivAt).div_const
      (Real.sqrt 2)
    simp only [id, one_mul] at this
    exact this.deriv
  have A : ∀ ξ, raise (lower f) ξ = oscH f ξ - 1 / 2 * f ξ := by
    intro ξ
    simp only [raise, dl, oscH]
    simp only [lower]
    field_simp
    rw [Real.sq_sqrt (by norm_num : (0:ℝ) ≤ 2)]
    ring
  have B : ∀ ξ, lower (raise f) ξ = oscH f ξ + 1 / 2 * f ξ := by
    intro ξ
    simp only [lower, dr, oscH]
    simp only [raise]
    field_simp
    rw [Real.sq_sqrt (by norm_num : (0:ℝ) ≤ 2)]
    ring
  refine ⟨A, B, fun ξ => ?_⟩
  rw [A, B]
  ring

/-- Step 4 of the card, the floor. A differentiable state is wiped out by the lowering operator,
(ξ + d/dξ) ψ = 0, exactly when it is a multiple of the bell curve e^(−ξ²/2); and the bell curve
has energy exactly ½ in units of ħω. -/
theorem ground_state_is_bell_curve_with_half_step :
    (∀ ψ : ℝ → ℝ, Differentiable ℝ ψ →
        ((∀ ξ, lower ψ ξ = 0) ↔ ∃ c : ℝ, ψ = fun ξ => c * Real.exp (-ξ ^ 2 / 2))) ∧
      ∀ ξ, oscH (fun ξ => Real.exp (-ξ ^ 2 / 2)) ξ = 1 / 2 * Real.exp (-ξ ^ 2 / 2) := by
  have hg : ∀ ξ : ℝ, HasDerivAt (fun ξ => Real.exp (-ξ ^ 2 / 2))
      (-ξ * Real.exp (-ξ ^ 2 / 2)) ξ := by
    intro ξ
    have h0 : HasDerivAt (fun ξ : ℝ => -ξ ^ 2 / 2) (-ξ) ξ := by
      have := ((hasDerivAt_pow 2 ξ).neg).div_const 2
      convert this using 1; push_cast; ring
    convert h0.exp using 1; ring
  have dg : deriv (fun ξ => Real.exp (-ξ ^ 2 / 2)) = fun ξ => -ξ * Real.exp (-ξ ^ 2 / 2) :=
    funext fun ξ => (hg ξ).deriv
  have hs0 : Real.sqrt 2 ≠ 0 := by positivity
  refine ⟨fun ψ hψ => ⟨fun h => ?_, fun ⟨c, hc⟩ => ?_⟩, fun ξ => ?_⟩
  · -- ψ * exp(ξ²/2) is constant
    have hd : ∀ ξ, deriv ψ ξ = -ξ * ψ ξ := by
      intro ξ
      have := h ξ
      simp only [lower, div_eq_zero_iff, hs0, or_false] at this
      linarith
    set u : ℝ → ℝ := fun ξ => ψ ξ * Real.exp (ξ ^ 2 / 2) with hu
    have hu' : ∀ ξ, HasDerivAt u 0 ξ := by
      intro ξ
      have h0 : HasDerivAt (fun ξ : ℝ => ξ ^ 2 / 2) ξ ξ := by
        have := (hasDerivAt_pow 2 ξ).div_const 2
        convert this using 1; push_cast; ring
      have := (hψ ξ).hasDerivAt.mul h0.exp
      convert this using 1
      rw [hd]; ring
    have hconst : ∀ ξ, u ξ = u 0 := fun ξ =>
      is_const_of_deriv_eq_zero (fun x => (hu' x).differentiableAt) (fun x => (hu' x).deriv) ξ 0
    refine ⟨ψ 0, funext fun ξ => ?_⟩
    have := hconst ξ
    simp only [hu] at this
    simp only [ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, zero_div,
      Real.exp_zero, mul_one] at this
    rw [← this, mul_assoc, ← Real.exp_add,
      show ξ ^ 2 / 2 + -ξ ^ 2 / 2 = 0 by ring, Real.exp_zero, mul_one]
  · intro ξ
    subst hc
    simp only [lower]
    rw [deriv_const_mul _ (hg ξ).differentiableAt, (hg ξ).deriv]
    ring
  · simp only [oscH, dg]
    have e : deriv (fun ξ => -ξ * Real.exp (-ξ ^ 2 / 2)) ξ =
        -1 * Real.exp (-ξ ^ 2 / 2) + -ξ * (-ξ * Real.exp (-ξ ^ 2 / 2)) :=
      ((hasDerivAt_id' ξ).neg.mul (hg ξ)).deriv
    rw [e]; ring

-- Step 5: at ε = 5/2 the rule a_{j+2} = (2j + 1 − 2ε)/((j+1)(j+2)) a_j, from a₀ = 1, gives a₂ = −2, a₄ = 0.
example : (2 * 0 + 1 - 2 * (5 / 2 : ℚ)) / ((0 + 1) * (0 + 2)) * 1 = -2 := by norm_num
example : (2 * 2 + 1 - 2 * (5 / 2 : ℚ)) / ((2 + 1) * (2 + 2)) * (-2) = 0 := by norm_num
-- So y = 1 − 2ξ² (y' = −4ξ, y'' = −4) solves Hermite's equation y'' − 2ξy' + (2ε − 1)y = 0 at ε = 5/2.
example (ξ : ℝ) : -4 - 2 * ξ * (-4 * ξ) + (2 * (5 / 2) - 1) * (1 - 2 * ξ ^ 2) = 0 := by ring
-- Counting from 1 puts the floor at 3/2 instead of 1/2 rungs: three times too high.
example : ((1 : ℚ) + 1 / 2) / (0 + 1 / 2) = 3 := by norm_num
-- A box's ladder (levels grow as n²) fitted to the first gap puts the 0→2 line at 8/3 gaps, not 2.
example : ((3 : ℚ) ^ 2 - 1 ^ 2) / (2 ^ 2 - 1 ^ 2) = 8 / 3 := by norm_num
example : ((2 : ℚ) + 1 / 2) - (0 + 1 / 2) = 2 := by norm_num

#print axioms oscillator_energies_are_n_plus_half_hbar_omega
#print axioms ladder_operators_factor_energy
#print axioms ground_state_is_bell_curve_with_half_step
