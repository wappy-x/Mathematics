-- Policy gradients: for a softmax table rule on a finite discounted decision process, the slope of the expected discounted money is the visit-weighted average of value times score direction, a baseline leaves that average unchanged, and each score's slope is visits times chance times advantage.
import Mathlib.Analysis.Complex.Exponential
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.ToLinearEquiv
import Mathlib.Topology.Instances.Matrix
import Mathlib.Analysis.Calculus.Deriv.Slope
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Algebra.BigOperators.Field

open Matrix

namespace PolicyGradient

variable {S A : Type*} [Fintype S] [DecidableEq S] [Fintype A] [DecidableEq A]

/-- The softmax rule: the chance of action `a` at state `s` is `e^{θ(s,a)} / Σ_b e^{θ(s,b)}`. -/
noncomputable def softmaxPolicy (θ : S → A → ℝ) (s : S) (a : A) : ℝ :=
  Real.exp (θ s a) / ∑ b, Real.exp (θ s b)

/-- The score direction `∇ log π_θ(a | s)` of the softmax table: `e_a − π_θ(· | s)` in row `s`,
and zero in every other row. -/
noncomputable def scoreDir (θ : S → A → ℝ) (s : S) (a : A) : S → A → ℝ :=
  fun s' b => if s' = s then (if b = a then 1 else 0) - softmaxPolicy θ s b else 0

/-- The rule's state-to-state chances `P_π(s, s') = Σ_a π_θ(a | s) p(s' | s, a)`. -/
noncomputable def ruleTransition (p : S → A → S → ℝ) (θ : S → A → ℝ) : Matrix S S ℝ :=
  fun s s' => ∑ a, softmaxPolicy θ s a * p s a s'

/-- The rule's expected reward at each state, `Σ_a π_θ(a | s) r(s, a)`. -/
noncomputable def ruleReward (r : S → A → ℝ) (θ : S → A → ℝ) : S → ℝ :=
  fun s => ∑ a, softmaxPolicy θ s a * r s a

/-- The value `V^π = (I − γ P_π)⁻¹ r_π`, the solution of the Bellman equations of the rule. -/
noncomputable def value (γ : ℝ) (p : S → A → S → ℝ) (r : S → A → ℝ) (θ : S → A → ℝ) : S → ℝ :=
  (1 - γ • ruleTransition p θ)⁻¹ *ᵥ ruleReward r θ

/-- The action value `Q^π(s, a) = r(s, a) + γ Σ_{s'} p(s' | s, a) V^π(s')`. -/
noncomputable def qValue (γ : ℝ) (p : S → A → S → ℝ) (r : S → A → ℝ) (θ : S → A → ℝ)
    (s : S) (a : A) : ℝ :=
  r s a + γ * ∑ s', p s a s' * value γ p r θ s'

/-- The discounted visits `η(s)` from the start `s₀`: row `s₀` of `(I − γ P_π)⁻¹`,
which is `Σ_t γ^t P_π^t(s₀, s)`. -/
noncomputable def discVisits (γ : ℝ) (p : S → A → S → ℝ) (θ : S → A → ℝ) (s₀ s : S) : ℝ :=
  (1 - γ • ruleTransition p θ)⁻¹ s₀ s

/-- The objective `J(θ) = V^{π_θ}(s₀)`. -/
noncomputable def objective (γ : ℝ) (p : S → A → S → ℝ) (r : S → A → ℝ) (s₀ : S)
    (θ : S → A → ℝ) : ℝ :=
  value γ p r θ s₀

/-- The policy-gradient direction `Σ_s η(s) Σ_a π_θ(a | s) Q^π(s, a) ∇ log π_θ(a | s)`. -/
noncomputable def pgDirection (γ : ℝ) (p : S → A → S → ℝ) (r : S → A → ℝ) (s₀ : S)
    (θ : S → A → ℝ) : S → A → ℝ :=
  ∑ s, ∑ a, (discVisits γ p θ s₀ s * softmaxPolicy θ s a * qValue γ p r θ s a) • scoreDir θ s a

omit [Fintype S] [DecidableEq S] [DecidableEq A] in
lemma softmaxPolicy_nonneg (θ : S → A → ℝ) (s : S) (a : A) : 0 ≤ softmaxPolicy θ s a := by
  unfold softmaxPolicy
  exact div_nonneg (Real.exp_pos _).le (Finset.sum_nonneg fun b _ => (Real.exp_pos _).le)

omit [Fintype S] [DecidableEq S] [DecidableEq A] in
lemma softmaxPolicy_sum_le_one (θ : S → A → ℝ) (s : S) : ∑ a, softmaxPolicy θ s a ≤ 1 := by
  unfold softmaxPolicy
  rw [← Finset.sum_div]
  exact div_self_le_one _

omit [Fintype S] [DecidableEq S] [DecidableEq A] in
lemma softmaxPolicy_sum_eq_one (θ : S → A → ℝ) (s : S) (a₀ : A) : ∑ a, softmaxPolicy θ s a = 1 := by
  unfold softmaxPolicy
  rw [← Finset.sum_div]
  exact div_self (Finset.sum_pos (fun b _ => Real.exp_pos _) ⟨a₀, Finset.mem_univ _⟩).ne'

omit [DecidableEq A] in
lemma isUnit_det_one_sub (γ : ℝ) (hγ0 : 0 ≤ γ) (hγ1 : γ < 1)
    (p : S → A → S → ℝ) (hp0 : ∀ s a s', 0 ≤ p s a s') (hp1 : ∀ s a, ∑ s', p s a s' = 1)
    (θ : S → A → ℝ) : IsUnit (1 - γ • ruleTransition p θ).det := by
  rw [isUnit_iff_ne_zero]
  intro hdet
  obtain ⟨v, hv0, hv⟩ := (Matrix.exists_mulVec_eq_zero_iff).2 hdet
  have hPnn : ∀ i j, 0 ≤ ruleTransition p θ i j := fun i j =>
    Finset.sum_nonneg fun a _ => mul_nonneg (softmaxPolicy_nonneg θ i a) (hp0 i a j)
  have hProw : ∀ i, ∑ j, ruleTransition p θ i j ≤ 1 := by
    intro i
    unfold ruleTransition
    rw [Finset.sum_comm]
    simp_rw [← Finset.mul_sum, hp1, mul_one]
    exact softmaxPolicy_sum_le_one θ i
  have key : ∀ i, v i = γ * ∑ j, ruleTransition p θ i j * v j := by
    intro i
    rw [Matrix.sub_mulVec, Matrix.one_mulVec, Matrix.smul_mulVec] at hv
    have := congrFun hv i
    simp only [Pi.sub_apply, Pi.smul_apply, smul_eq_mul, Pi.zero_apply] at this
    simp only [Matrix.mulVec, dotProduct] at this
    linarith
  obtain ⟨i₀, hi₀⟩ : ∃ i, v i ≠ 0 := by
    by_contra hcon
    push Not at hcon
    exact hv0 (funext hcon)
  have : Nonempty S := ⟨i₀⟩
  obtain ⟨i, hi⟩ := Finite.exists_max (fun i => |v i|)
  have hm : |v i| ≤ γ * |v i| := by
    calc |v i| = γ * |∑ j, ruleTransition p θ i j * v j| := by
          rw [key i, abs_mul, abs_of_nonneg hγ0]
      _ ≤ γ * |v i| := by
          apply mul_le_mul_of_nonneg_left _ hγ0
          calc |∑ j, ruleTransition p θ i j * v j|
              ≤ ∑ j, |ruleTransition p θ i j * v j| := Finset.abs_sum_le_sum_abs _ _
            _ ≤ ∑ j, ruleTransition p θ i j * |v i| := by
                gcongr with j
                rw [abs_mul, abs_of_nonneg (hPnn i j)]
                exact mul_le_mul_of_nonneg_left (hi j) (hPnn i j)
            _ = (∑ j, ruleTransition p θ i j) * |v i| := by rw [Finset.sum_mul]
            _ ≤ |v i| := mul_le_of_le_one_left (abs_nonneg _) (hProw i)
  have h0 : |v i| = 0 := by
    have := abs_nonneg (v i)
    nlinarith
  apply hi₀
  have := hi i₀
  rw [h0] at this
  exact abs_nonpos_iff.1 this

omit [Fintype S] [DecidableEq S] [DecidableEq A] in
lemma hasDerivAt_softmaxPolicy (θ h : S → A → ℝ) (s : S) (a : A) :
    HasDerivAt (fun t : ℝ => softmaxPolicy (θ + t • h) s a)
      (softmaxPolicy θ s a * (h s a - ∑ b, softmaxPolicy θ s b * h s b)) 0 := by
  have hn : ∀ b, HasDerivAt (fun t : ℝ => Real.exp (θ s b + t * h s b))
      (Real.exp (θ s b) * h s b) 0 := by
    intro b
    have := (((hasDerivAt_id (0 : ℝ)).mul_const (h s b)).const_add (θ s b)).exp
    simpa using this
  have hZ : (∑ b, Real.exp (θ s b)) ≠ 0 :=
    (Finset.sum_pos (fun b _ => Real.exp_pos _) ⟨a, Finset.mem_univ _⟩).ne'
  have hZ' : (fun t : ℝ => ∑ b, Real.exp (θ s b + t * h s b)) 0 ≠ 0 := by simpa using hZ
  have hd := (hn a).fun_div (HasDerivAt.fun_sum fun b _ => hn b) hZ'
  have hfun : (fun t : ℝ => softmaxPolicy (θ + t • h) s a)
      = fun t : ℝ => Real.exp (θ s a + t * h s a) / ∑ b, Real.exp (θ s b + t * h s b) := by
    funext t
    simp [softmaxPolicy, Pi.add_apply, Pi.smul_apply, smul_eq_mul]
  rw [hfun]
  convert hd using 1
  simp only [zero_mul, add_zero, softmaxPolicy]
  simp_rw [div_mul_eq_mul_div, ← Finset.sum_div]
  field_simp

open Filter Topology in
lemma hasDerivAt_mul_of_zero {c g : ℝ → ℝ} {g' : ℝ} (hc : ContinuousAt c 0) (hg0 : g 0 = 0)
    (hg : HasDerivAt g g' 0) : HasDerivAt (fun t => c t * g t) (c 0 * g') 0 := by
  rw [hasDerivAt_iff_tendsto_slope_zero] at hg ⊢
  have hc' : Tendsto c (𝓝[≠] 0) (𝓝 (c 0)) := by
    have := hc.tendsto
    exact this.mono_left nhdsWithin_le_nhds
  have := hc'.mul hg
  refine this.congr' (Eventually.of_forall fun t => ?_)
  simp [hg0, smul_eq_mul]
  ring

omit [DecidableEq A] in
lemma value_eq_sum_qValue (γ : ℝ) (p : S → A → S → ℝ) (r : S → A → ℝ) (θ : S → A → ℝ)
    (hunit : IsUnit (1 - γ • ruleTransition p θ).det) (s : S) :
    value γ p r θ s = ∑ a, softmaxPolicy θ s a * qValue γ p r θ s a := by
  have hM : (1 - γ • ruleTransition p θ) *ᵥ value γ p r θ = ruleReward r θ := by
    unfold value
    rw [Matrix.mulVec_mulVec, Matrix.mul_nonsing_inv _ hunit, Matrix.one_mulVec]
  rw [Matrix.sub_mulVec, Matrix.one_mulVec, Matrix.smul_mulVec] at hM
  have h1 := congrFun hM s
  simp only [Pi.sub_apply, Pi.smul_apply, smul_eq_mul] at h1
  have hPV : (ruleTransition p θ *ᵥ value γ p r θ) s
      = ∑ a, softmaxPolicy θ s a * ∑ s', p s a s' * value γ p r θ s' := by
    simp only [Matrix.mulVec, dotProduct, ruleTransition, Finset.sum_mul, Finset.mul_sum]
    rw [Finset.sum_comm]
    exact Finset.sum_congr rfl fun _ _ => Finset.sum_congr rfl fun _ _ => by ring
  have h2 : ∑ a, softmaxPolicy θ s a * qValue γ p r θ s a
      = ruleReward r θ s + γ * ∑ a, softmaxPolicy θ s a * ∑ s', p s a s' * value γ p r θ s' := by
    simp only [qValue, mul_add, Finset.sum_add_distrib, ruleReward, Finset.mul_sum]
    congr 1
    exact Finset.sum_congr rfl fun _ _ => Finset.sum_congr rfl fun _ _ => by ring
  rw [h2, ← hPV]
  linarith

lemma pgDirection_apply (γ : ℝ) (p : S → A → S → ℝ) (r : S → A → ℝ) (s₀ : S) (θ : S → A → ℝ)
    (s : S) (a : A) :
    pgDirection γ p r s₀ θ s a = ∑ a', discVisits γ p θ s₀ s * softmaxPolicy θ s a' *
      qValue γ p r θ s a' * ((if a = a' then 1 else 0) - softmaxPolicy θ s a) := by
  simp [pgDirection, scoreDir, Finset.sum_apply, smul_eq_mul, mul_ite, mul_zero]

lemma sum_pgDirection_mul (γ : ℝ) (p : S → A → S → ℝ) (r : S → A → ℝ) (s₀ : S)
    (θ h : S → A → ℝ) :
    ∑ s, ∑ a, pgDirection γ p r s₀ θ s a * h s a
      = ∑ s, ∑ a, discVisits γ p θ s₀ s *
          (softmaxPolicy θ s a * (h s a - ∑ b, softmaxPolicy θ s b * h s b)) * qValue γ p r θ s a := by
  refine Finset.sum_congr rfl fun s _ => ?_
  simp_rw [pgDirection_apply, Finset.sum_mul]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun a' _ => ?_
  simp_rw [mul_sub, sub_mul, Finset.sum_sub_distrib, mul_ite, mul_one, mul_zero, ite_mul, zero_mul,
    Finset.sum_ite_eq', Finset.mem_univ, ite_true]
  rw [Finset.mul_sum, Finset.mul_sum, Finset.sum_mul]
  congr 1
  · ring
  · exact Finset.sum_congr rfl fun _ _ => by ring

/-- **Policy gradient theorem.** On a finite decision process with discount `0 ≤ γ < 1` and
transition chances `p`, under the softmax table rule, the gradient of the expected discounted
money from `s₀` is `∇J(θ) = Σ_s η(s) Σ_a π_θ(a | s) Q^π(s, a) ∇ log π_θ(a | s)`: moving the scores
along any direction `h`, `J` changes at the rate `Σ_{s,a} (∇J)(s, a) h(s, a)`. -/
theorem policy_gradient_theorem (γ : ℝ) (hγ0 : 0 ≤ γ) (hγ1 : γ < 1)
    (p : S → A → S → ℝ) (hp0 : ∀ s a s', 0 ≤ p s a s') (hp1 : ∀ s a, ∑ s', p s a s' = 1)
    (r : S → A → ℝ) (s₀ : S) (θ h : S → A → ℝ) :
    HasDerivAt (fun t : ℝ => objective γ p r s₀ (θ + t • h))
      (∑ s, ∑ a, pgDirection γ p r s₀ θ s a * h s a) 0 := by
  have hπ := fun s a => hasDerivAt_softmaxPolicy θ h s a
  have hunit : ∀ t : ℝ, IsUnit (1 - γ • ruleTransition p (θ + t • h)).det := fun t =>
    isUnit_det_one_sub γ hγ0 hγ1 p hp0 hp1 _
  have hunit0 : IsUnit (1 - γ • ruleTransition p θ).det := isUnit_det_one_sub γ hγ0 hγ1 p hp0 hp1 θ
  -- the leftover of the Bellman equations at the old value, along the line
  have hg : ∀ j, HasDerivAt (fun t : ℝ => ∑ a, softmaxPolicy (θ + t • h) j a * r j a -
        ∑ k, ((1 : Matrix S S ℝ) j k - γ * ∑ a, softmaxPolicy (θ + t • h) j a * p j a k) *
          value γ p r θ k)
      (∑ a, softmaxPolicy θ j a * (h j a - ∑ b, softmaxPolicy θ j b * h j b) * r j a -
        ∑ k, (0 - γ * ∑ a, softmaxPolicy θ j a * (h j a - ∑ b, softmaxPolicy θ j b * h j b) *
          p j a k) * value γ p r θ k) 0 := fun j =>
    (HasDerivAt.fun_sum fun a _ => (hπ j a).mul_const (r j a)).sub
      (HasDerivAt.fun_sum fun k _ => ((hasDerivAt_const (0 : ℝ) ((1 : Matrix S S ℝ) j k)).sub
        ((HasDerivAt.fun_sum fun a _ => (hπ j a).mul_const (p j a k)).const_mul γ)).mul_const
          (value γ p r θ k))
  have hg0 : ∀ j, (∑ a, softmaxPolicy (θ + (0 : ℝ) • h) j a * r j a -
        ∑ k, ((1 : Matrix S S ℝ) j k - γ * ∑ a, softmaxPolicy (θ + (0 : ℝ) • h) j a * p j a k) *
          value γ p r θ k) = 0 := by
    intro j
    have hM : (1 - γ • ruleTransition p θ) *ᵥ value γ p r θ = ruleReward r θ := by
      unfold value
      rw [Matrix.mulVec_mulVec, Matrix.mul_nonsing_inv _ hunit0, Matrix.one_mulVec]
    have h1 := congrFun hM j
    simp only [Matrix.mulVec, dotProduct, Matrix.sub_apply, Matrix.smul_apply, smul_eq_mul,
      ruleTransition, ruleReward] at h1
    simp only [zero_smul, add_zero]
    linarith
  have hPc : ContinuousAt (fun t : ℝ => 1 - γ • ruleTransition p (θ + t • h)) 0 := by
    refine continuousAt_const.sub (ContinuousAt.const_smul ?_ γ)
    refine continuousAt_pi.2 fun i => continuousAt_pi.2 fun k => ?_
    exact (HasDerivAt.fun_sum fun a _ => (hπ i a).mul_const (p i a k)).continuousAt
  have hinv : ContinuousAt Inv.inv (1 - γ • ruleTransition p θ) := by
    apply continuousAt_matrix_inv
    rw [Ring.inverse_eq_inv']
    exact continuousAt_inv₀ hunit0.ne_zero
  have hc : ∀ j, ContinuousAt (fun t : ℝ => (1 - γ • ruleTransition p (θ + t • h))⁻¹ s₀ j) 0 := by
    intro j
    have h1 := ContinuousAt.comp_of_eq hinv hPc (by simp)
    exact (continuous_apply j).continuousAt.comp ((continuous_apply s₀).continuousAt.comp h1)
  have heq : ∀ t : ℝ, objective γ p r s₀ (θ + t • h) = objective γ p r s₀ θ +
      ∑ j, (1 - γ • ruleTransition p (θ + t • h))⁻¹ s₀ j *
        (∑ a, softmaxPolicy (θ + t • h) j a * r j a -
          ∑ k, ((1 : Matrix S S ℝ) j k - γ * ∑ a, softmaxPolicy (θ + t • h) j a * p j a k) *
            value γ p r θ k) := by
    intro t
    have h1 : (1 - γ • ruleTransition p (θ + t • h))⁻¹ *ᵥ (ruleReward r (θ + t • h) -
        (1 - γ • ruleTransition p (θ + t • h)) *ᵥ value γ p r θ)
        = value γ p r (θ + t • h) - value γ p r θ := by
      rw [Matrix.mulVec_sub, Matrix.mulVec_mulVec, Matrix.nonsing_inv_mul _ (hunit t),
        Matrix.one_mulVec]
      rfl
    have h2 := congrFun h1 s₀
    simp only [Pi.sub_apply, Matrix.mulVec, dotProduct, Matrix.sub_apply, Matrix.smul_apply,
      smul_eq_mul, ruleTransition, ruleReward] at h2
    simp only [objective]
    linarith
  have hsum := (HasDerivAt.fun_sum (u := Finset.univ) fun j _ =>
    hasDerivAt_mul_of_zero (hc j) (hg0 j) (hg j)).const_add (objective γ p r s₀ θ)
  rw [show (fun t : ℝ => objective γ p r s₀ (θ + t • h)) = _ from funext heq]
  convert hsum using 1
  rw [sum_pgDirection_mul]
  refine Finset.sum_congr rfl fun j _ => ?_
  simp only [zero_smul, add_zero, qValue]
  have e1 : ∑ k, (0 - γ * ∑ a, softmaxPolicy θ j a * (h j a - ∑ b, softmaxPolicy θ j b * h j b) *
      p j a k) * value γ p r θ k
      = -∑ a, γ * (softmaxPolicy θ j a * (h j a - ∑ b, softmaxPolicy θ j b * h j b)) *
          ∑ k, p j a k * value γ p r θ k := by
    simp only [zero_sub, neg_mul, Finset.mul_sum, Finset.sum_mul, Finset.sum_neg_distrib, neg_inj]
    rw [Finset.sum_comm]
    exact Finset.sum_congr rfl fun _ _ => Finset.sum_congr rfl fun _ _ => by ring
  rw [e1, sub_neg_eq_add, ← Finset.sum_add_distrib, Finset.mul_sum]
  exact Finset.sum_congr rfl fun _ _ => by simp only [discVisits]; ring

/-- **A baseline keeps the mean.** At any state, for any payments `f` and any number `b` that
does not depend on the action, `Σ_a π_θ(a | s) (f(a) − b) ∇ log π_θ(a | s)` equals
`Σ_a π_θ(a | s) f(a) ∇ log π_θ(a | s)`, because the chances' score directions average to zero. -/
theorem baseline_keeps_mean (θ : S → A → ℝ) (s : S) (f : A → ℝ) (b : ℝ) :
    ∑ a, (softmaxPolicy θ s a * (f a - b)) • scoreDir θ s a
      = ∑ a, (softmaxPolicy θ s a * f a) • scoreDir θ s a := by
  funext s' b'
  simp only [Finset.sum_apply, Pi.smul_apply, smul_eq_mul, scoreDir]
  split_ifs with hs
  · have h1 := softmaxPolicy_sum_eq_one θ s b'
    have key : ∑ a, softmaxPolicy θ s a * ((if b' = a then 1 else 0) - softmaxPolicy θ s b') = 0 := by
      simp_rw [mul_sub, Finset.sum_sub_distrib, mul_ite, mul_one, mul_zero, Finset.sum_ite_eq,
        Finset.mem_univ, ite_true, ← Finset.sum_mul, h1, one_mul, sub_self]
    have : ∑ a, softmaxPolicy θ s a * (f a - b) * ((if b' = a then 1 else 0) - softmaxPolicy θ s b')
        = ∑ a, softmaxPolicy θ s a * f a * ((if b' = a then 1 else 0) - softmaxPolicy θ s b')
          - b * ∑ a, softmaxPolicy θ s a * ((if b' = a then 1 else 0) - softmaxPolicy θ s b') := by
      rw [Finset.mul_sum, ← Finset.sum_sub_distrib]
      exact Finset.sum_congr rfl fun _ _ => by ring
    rw [this, key, mul_zero, sub_zero]
  · simp

/-- **Softmax form.** Under the same hypotheses, the slope of `J` in the single score
`θ(s, a)` is `η(s) π_θ(a | s) (Q^π(s, a) − V^π(s))`. -/
theorem softmax_policy_gradient_entry (γ : ℝ) (hγ0 : 0 ≤ γ) (hγ1 : γ < 1)
    (p : S → A → S → ℝ) (hp0 : ∀ s a s', 0 ≤ p s a s') (hp1 : ∀ s a, ∑ s', p s a s' = 1)
    (r : S → A → ℝ) (s₀ : S) (θ : S → A → ℝ) (s : S) (a : A) :
    HasDerivAt (fun t : ℝ => objective γ p r s₀ (θ + t • fun s' b => if s' = s ∧ b = a then 1 else 0))
      (discVisits γ p θ s₀ s * softmaxPolicy θ s a *
        (qValue γ p r θ s a - value γ p r θ s)) 0 := by
  have H := policy_gradient_theorem γ hγ0 hγ1 p hp0 hp1 r s₀ θ
    (fun s' b => if s' = s ∧ b = a then 1 else 0)
  convert H using 1
  rw [Finset.sum_eq_single s (fun s' _ hs' => by simp [hs']) (by simp),
    Finset.sum_eq_single a (fun b _ hb => by simp [hb]) (by simp)]
  simp only [and_self, ite_true, mul_one]
  rw [pgDirection_apply, value_eq_sum_qValue γ p r θ (isUnit_det_one_sub γ hγ0 hγ1 p hp0 hp1 θ)]
  simp only [mul_sub, Finset.sum_sub_distrib, mul_ite, mul_one, mul_zero, Finset.sum_ite_eq,
    Finset.mem_univ, ite_true]
  rw [Finset.mul_sum]
  congr 1
  exact Finset.sum_congr rfl fun _ _ => by ring

end PolicyGradient

open PolicyGradient

/- The card's two-action case: one state, scores (0, 0), action 1 (index 0) pays 1,
action 2 (index 1) pays 0. -/

-- each chance is 1/2
example : softmaxPolicy (fun (_ : Unit) (_ : Fin 2) => (0 : ℝ)) () 0 = 1 / 2 := by
  simp [softmaxPolicy]

-- score directions (1/2, −1/2) for action 1 and (−1/2, 1/2) for action 2, and the gradient
-- 1/2 × 1 × (1/2) + 1/2 × 0 × (−1/2) = 1/4 (the second entry is −1/4)
example : (1 : ℚ) - 1 / 2 = 1 / 2 ∧ (0 : ℚ) - 1 / 2 = -1 / 2 := by norm_num
example : (1 / 2 : ℚ) * 1 * (1 / 2) + 1 / 2 * 0 * (-1 / 2) = 1 / 4 ∧
    (1 / 2 : ℚ) * 1 * (-1 / 2) + 1 / 2 * 0 * (1 / 2) = -1 / 4 := by norm_num

-- baseline 1/2: both actions report the exact gradient entry 1/4
example : (1 - 1 / 2 : ℚ) * (1 / 2) = 1 / 4 ∧ (0 - 1 / 2 : ℚ) * (-1 / 2) = 1 / 4 := by norm_num

-- no baseline: one play reports 1/2 or 0, variance 0.0625 = 1/16
example : (1 / 2 : ℚ) * (1 / 2 - 1 / 4) ^ 2 + 1 / 2 * (0 - 1 / 4) ^ 2 = 1 / 16 := by norm_num

-- payments 11 and 10, no baseline: one play reports 5.5 or −5, variance 27.5625 = 441/16
example : (11 : ℚ) * (1 / 2) = 11 / 2 ∧ (10 : ℚ) * (-1 / 2) = -5 ∧
    (1 / 2 : ℚ) * (11 / 2 - 1 / 4) ^ 2 + 1 / 2 * (-5 - 1 / 4) ^ 2 = 441 / 16 := by norm_num

-- the deadly-triad example: each update multiplies w by 1 + 0.1 (2 × 0.95 − 1) = 1.09,
-- and 50 updates from w = 1 give 74.36 to two decimals
example : (1 : ℚ) + 1 / 10 * (2 * (95 / 100) - 1) = 109 / 100 := by norm_num
example : (74355 / 1000 : ℚ) ≤ (109 / 100) ^ 50 ∧ (109 / 100 : ℚ) ^ 50 < 74365 / 1000 := by
  norm_num

#print axioms policy_gradient_theorem
#print axioms baseline_keeps_mean
#print axioms softmax_policy_gradient_entry
#print axioms softmaxPolicy_nonneg
#print axioms softmaxPolicy_sum_le_one
#print axioms softmaxPolicy_sum_eq_one
#print axioms isUnit_det_one_sub
#print axioms hasDerivAt_softmaxPolicy
#print axioms hasDerivAt_mul_of_zero
#print axioms value_eq_sum_qValue
#print axioms pgDirection_apply
#print axioms sum_pgDirection_mul
