-- When prices jump: the jump-diffusion pricing equation in price and calendar time is the same equation as the log-price PIDE with its integral term, and the compensator is k = exp(μ_J + δ²/2) − 1.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.Calculus.Deriv.Shift

open Real MeasureTheory ProbabilityTheory

theorem deriv_comp_log_of_differentiable (f : ℝ → ℝ) (hf : Differentiable ℝ f) {S : ℝ}
    (hS : 0 < S) : deriv (fun P => f (log P)) S = deriv f (log S) / S := by
  have h : HasDerivAt (fun P => f (log P)) (deriv f (log S) * S⁻¹) S :=
    (hf (log S)).hasDerivAt.comp S (hasDerivAt_log hS.ne')
  rw [h.deriv, div_eq_mul_inv]

theorem deriv_deriv_comp_log_of_differentiable (f : ℝ → ℝ) (hf : Differentiable ℝ f)
    (hf' : Differentiable ℝ (deriv f)) {S : ℝ} (hS : 0 < S) :
    deriv (fun P => deriv (fun P' => f (log P')) P) S
      = (deriv (deriv f) (log S) - deriv f (log S)) / S ^ 2 := by
  have heq : (fun P => deriv (fun P' => f (log P')) P) =ᶠ[nhds S]
      (fun P => deriv f (log P) / P) := by
    filter_upwards [Ioi_mem_nhds hS] with P hP
    exact deriv_comp_log_of_differentiable f hf hP
  rw [heq.deriv_eq]
  have h1 : HasDerivAt (fun P => deriv f (log P)) (deriv (deriv f) (log S) * S⁻¹) S :=
    (hf' (log S)).hasDerivAt.comp S (hasDerivAt_log hS.ne')
  have h2 : HasDerivAt (fun P => deriv f (log P) / P)
      ((deriv (deriv f) (log S) * S⁻¹ * S - deriv f (log S) * 1) / S ^ 2) S :=
    h1.div (hasDerivAt_id' S) hS.ne'
  rw [h2.deriv]
  field_simp

#print axioms deriv_comp_log_of_differentiable
#print axioms deriv_deriv_comp_log_of_differentiable

/-- The PIDE in log price. A value `U x s` (log price `x`, time to expiry `s`) is a classical
solution for `s > 0` when, for every `x` and every `s > 0`,
`U_s = ½σ² U_xx + (r − q − λk − ½σ²) U_x − (r + λ) U + λ ∫ U(x + z, s) g(z) dz`,
where `g` is the bell-curve density of the log jump size, with mean `μJ` and spread `δ`,
and `k = exp(μJ + δ²/2) − 1` is the average jump. -/
def LogPIDE (r q σ lam μJ δ : ℝ) (U : ℝ → ℝ → ℝ) : Prop :=
  ∀ x : ℝ, ∀ s : ℝ, 0 < s →
    deriv (fun τ => U x τ) s =
      (1 / 2) * σ ^ 2 * deriv (fun y => deriv (fun w => U w s) y) x
      + (r - q - lam * (exp (μJ + δ ^ 2 / 2) - 1) - (1 / 2) * σ ^ 2) * deriv (fun y => U y s) x
      - (r + lam) * U x s
      + lam * ∫ z, U (x + z) s * gaussianPDFReal μJ (δ ^ 2).toNNReal z

/-- **Jumps add one integral term to the pricing equation.** Let `U` be twice differentiable
in log price for every time to expiry `s > 0` (a classical solution), and write the value in
share price `S` and calendar time `t` as `V(S, t) = U(ln S, T − t)`. Then `V` solves the
price-form jump-diffusion pricing equation, for every `S > 0` and `t < T`,
`V_t + (r − q − λk) S V_S + ½σ² S² V_SS − rV + λ (E[V(SY, t)] − V(S, t)) = 0`,
where a jump multiplies the price by `Y = e^z` with `z` drawn from the bell curve `g`,
exactly when `U` solves the log-price PIDE. -/
theorem jump_pricing_equation_iff_log_pide
    (r q σ lam μJ δ T : ℝ) (U : ℝ → ℝ → ℝ)
    (hU1 : ∀ s : ℝ, 0 < s → Differentiable ℝ (fun x => U x s))
    (hU2 : ∀ s : ℝ, 0 < s → Differentiable ℝ (fun x => deriv (fun y => U y s) x)) :
    (∀ S : ℝ, 0 < S → ∀ t : ℝ, t < T →
      deriv (fun τ => U (log S) (T - τ)) t
      + (r - q - lam * (exp (μJ + δ ^ 2 / 2) - 1)) * S
          * deriv (fun P => U (log P) (T - t)) S
      + (1 / 2) * σ ^ 2 * S ^ 2
          * deriv (fun P => deriv (fun P' => U (log P') (T - t)) P) S
      - r * U (log S) (T - t)
      + lam * ((∫ z, U (log (S * exp z)) (T - t) * gaussianPDFReal μJ (δ ^ 2).toNNReal z)
                - U (log S) (T - t)) = 0)
    ↔ LogPIDE r q σ lam μJ δ U := by
  -- pointwise rewriting of the price-form expression into log-price quantities
  have key : ∀ S : ℝ, 0 < S → ∀ s : ℝ, 0 < s →
      deriv (fun τ => U (log S) (T - τ)) (T - s)
      + (r - q - lam * (exp (μJ + δ ^ 2 / 2) - 1)) * S
          * deriv (fun P => U (log P) s) S
      + (1 / 2) * σ ^ 2 * S ^ 2
          * deriv (fun P => deriv (fun P' => U (log P') s) P) S
      - r * U (log S) s
      + lam * ((∫ z, U (log (S * exp z)) s * gaussianPDFReal μJ (δ ^ 2).toNNReal z)
                - U (log S) s)
      = -(deriv (fun τ => U (log S) τ) s -
          ((1 / 2) * σ ^ 2 * deriv (fun y => deriv (fun w => U w s) y) (log S)
          + (r - q - lam * (exp (μJ + δ ^ 2 / 2) - 1) - (1 / 2) * σ ^ 2)
              * deriv (fun y => U y s) (log S)
          - (r + lam) * U (log S) s
          + lam * ∫ z, U (log S + z) s * gaussianPDFReal μJ (δ ^ 2).toNNReal z)) := by
    intro S hS s hs
    have ht : deriv (fun τ => U (log S) (T - τ)) (T - s) = -deriv (fun τ => U (log S) τ) s := by
      rw [deriv_comp_const_sub (f := fun τ => U (log S) τ)]
      simp
    have h1 := deriv_comp_log_of_differentiable (fun w => U w s) (hU1 s hs) hS
    have h2 := deriv_deriv_comp_log_of_differentiable (fun w => U w s) (hU1 s hs) (hU2 s hs) hS
    have hint : (∫ z, U (log (S * exp z)) s * gaussianPDFReal μJ (δ ^ 2).toNNReal z)
        = ∫ z, U (log S + z) s * gaussianPDFReal μJ (δ ^ 2).toNNReal z := by
      congr 1
      funext z
      rw [log_mul hS.ne' (exp_pos z).ne', log_exp]
    rw [ht, h1, h2, hint]
    have hS2 : S ^ 2 ≠ 0 := pow_ne_zero 2 hS.ne'
    field_simp
    ring
  constructor
  · intro h x s hs
    have hh := h (exp x) (exp_pos x) (T - s) (by linarith)
    rw [sub_sub_cancel, key (exp x) (exp_pos x) s hs, log_exp] at hh
    linarith
  · intro h S hS t ht
    have hk := key S hS (T - t) (by linarith)
    rw [sub_sub_cancel] at hk
    rw [hk, h (log S) (T - t) (by linarith)]
    ring

/-- **The compensator.** If the log jump size is a bell curve with mean `μJ` and spread `δ`,
the average jump factor is `E[Y] = E[e^z] = exp(μJ + δ²/2)`, so the average jump as a
fraction of the price is `k = E[Y] − 1 = exp(μJ + δ²/2) − 1`. -/
theorem average_jump_eq_compensator (μJ δ : ℝ) :
    (∫ z, exp z ∂(gaussianReal μJ (δ ^ 2).toNNReal)) - 1 = exp (μJ + δ ^ 2 / 2) - 1 := by
  have h := congrFun (mgf_id_gaussianReal (μ := μJ) (v := (δ ^ 2).toNNReal)) 1
  simp only [mgf, id, one_mul, one_pow, mul_one] at h
  rw [h, Real.coe_toNNReal _ (sq_nonneg δ)]

#print axioms jump_pricing_equation_iff_log_pide
#print axioms average_jump_eq_compensator
