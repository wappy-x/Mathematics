-- Adjoint differentiation: one backward sweep over a tape of differentiable steps returns the derivative of the answer with respect to every input.
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Probability.Distributions.Gaussian.Real

open ProbabilityTheory

/-- A tape with `n` inputs and `N` lines. Lines `0, …, n-1` hold the inputs. Every later
line `k` is one step `op k`, a function of the values on lines before it: changing a
value on line `k` or later never changes `op k`. -/
structure Tape (n N : ℕ) where
  op : Fin N → (Fin N → ℝ) → ℝ
  uses_earlier : ∀ (k : Fin N) (v w : Fin N → ℝ), (∀ j, j < k → v j = w j) → op k v = op k w

namespace Tape

variable {n N : ℕ}

/-- The starting record: the inputs on their lines, zero on every other line. -/
def start (x : Fin n → ℝ) : Fin N → ℝ :=
  fun j => if h : j.val < n then x ⟨j.val, h⟩ else 0

/-- The forward pass after lines `0, …, j-1`: each step line writes its value on its own line. -/
def run (t : Tape n N) (x : Fin n → ℝ) : ℕ → (Fin N → ℝ)
  | 0 => start x
  | j + 1 =>
    if h : n ≤ j ∧ j < N then
      Function.update (t.run x j) ⟨j, h.2⟩ (t.op ⟨j, h.2⟩ (t.run x j))
    else t.run x j

/-- The whole forward pass: every line's value. -/
def forward (t : Tape n N) (x : Fin n → ℝ) : Fin N → ℝ := t.run x N

/-- The local slope of step `k` with respect to line `j`, at the forward values. -/
noncomputable def slope (t : Tape n N) (x : Fin n → ℝ) (k j : Fin N) : ℝ :=
  fderiv ℝ (t.op k) (t.forward x) (Pi.single j 1)

/-- The backward sweep after `c` step lines, taken from the last line down. It starts with
adjoint 1 on the answer (the last line) and 0 elsewhere; processing step line `k` adds
`adjoint k × slope k j` into the adjoint of every earlier line `j`. Input lines are not
processed. -/
noncomputable def back (t : Tape n (m + 1)) (x : Fin n → ℝ) : ℕ → (Fin (m + 1) → ℝ)
  | 0 => Pi.single (Fin.last m) 1
  | c + 1 =>
    if h : c ≤ m ∧ n ≤ m - c then
      fun j =>
        if j < ⟨m - c, by omega⟩ then
          t.back x c j + t.back x c ⟨m - c, by omega⟩ * t.slope x ⟨m - c, by omega⟩ j
        else t.back x c j
    else t.back x c

/-- The adjoints after the full sweep over all `m + 1` lines. -/
noncomputable def adjoint (t : Tape n (m + 1)) (x : Fin n → ℝ) : Fin (m + 1) → ℝ :=
  t.back x (m + 1)

end Tape

namespace TapeHelp

open Tape

variable {n N : ℕ}

lemma run_add (t : Tape n N) (y : Fin n → ℝ) (s : ℕ) (j : Fin N) (hj : j.val < s) :
    ∀ d, t.run y (s + d) j = t.run y s j
  | 0 => rfl
  | d + 1 => by
    rw [show s + (d + 1) = (s + d) + 1 by omega, Tape.run]
    split_ifs with h
    · rw [Function.update_of_ne (Fin.ne_of_val_ne (by simp; omega))]
      exact run_add t y s j hj d
    · exact run_add t y s j hj d

lemma run_eq_forward (t : Tape n N) (y : Fin n → ℝ) (s : ℕ) (hs : s ≤ N) (j : Fin N)
    (hj : j.val < s) : t.run y s j = t.forward y j := by
  unfold Tape.forward
  obtain ⟨d, rfl⟩ := Nat.exists_eq_add_of_le hs
  rw [run_add t y s j hj d]

lemma run_input (t : Tape n N) (y : Fin n → ℝ) (s : ℕ) (j : Fin N) (hj : j.val < n) :
    t.run y s j = y ⟨j.val, hj⟩ := by
  induction s with
  | zero => simp [Tape.run, Tape.start, hj]
  | succ s ih =>
    rw [Tape.run]
    split_ifs with h
    · rw [Function.update_of_ne (Fin.ne_of_val_ne (by simp; omega))]
      exact ih
    · exact ih

lemma forward_input (t : Tape n N) (y : Fin n → ℝ) (j : Fin N) (hj : j.val < n) :
    t.forward y j = y ⟨j.val, hj⟩ := run_input t y N j hj

lemma forward_step (t : Tape n N) (y : Fin n → ℝ) (k : Fin N) (hk : n ≤ k.val) :
    t.forward y k = t.op k (t.forward y) := by
  rw [← run_eq_forward t y (k.val + 1) (by omega) k (by omega), Tape.run, dif_pos ⟨hk, k.2⟩]
  rw [Function.update_self]
  apply t.uses_earlier
  intro j hj
  exact run_eq_forward t y k.val (by omega) j hj

lemma linear_expand (L : (Fin N → ℝ) →L[ℝ] ℝ) (w : Fin N → ℝ) :
    L w = ∑ j, w j * L (Pi.single j 1) := by
  have := LinearMap.pi_apply_eq_sum_univ L.toLinearMap w
  simp only [ContinuousLinearMap.coe_coe, smul_eq_mul] at this
  rw [this]
  refine Finset.sum_congr rfl (fun j _ => ?_)
  congr 2
  funext i
  simp [Pi.single_apply, eq_comm]

lemma fderiv_input (t : Tape n N) (x w : Fin n → ℝ) (j : Fin N) (hj : j.val < n) :
    fderiv ℝ (fun y => t.forward y j) x w = w ⟨j.val, hj⟩ := by
  have hf : (fun y => t.forward y j) = fun y : Fin n → ℝ => y ⟨j.val, hj⟩ :=
    funext fun y => forward_input t y j hj
  rw [hf, (hasFDerivAt_apply (𝕜 := ℝ) (⟨j.val, hj⟩ : Fin n) x).fderiv]
  rfl

lemma deriv_step (t : Tape n N) (x : Fin n → ℝ)
    (hdiff : ∀ k : Fin N, n ≤ k.val → DifferentiableAt ℝ (t.op k) (t.forward x)) :
    ∀ s, ∀ k : Fin N, k.val = s → DifferentiableAt ℝ (fun y => t.forward y k) x ∧
      (n ≤ k.val → ∀ v, fderiv ℝ (fun y => t.forward y k) x v =
        ∑ j, (if j < k then t.slope x k j * fderiv ℝ (fun y => t.forward y j) x v else 0)) := by
  intro s
  induction s using Nat.strong_induction_on with
  | _ s ih =>
  intro k hks
  by_cases hk : k.val < n
  · refine ⟨?_, fun h => absurd h (by omega)⟩
    have hf : (fun y => t.forward y k) = fun y : Fin n → ℝ => y ⟨k.val, hk⟩ :=
      funext fun y => forward_input t y k hk
    rw [hf]
    exact (hasFDerivAt_apply (𝕜 := ℝ) (⟨k.val, hk⟩ : Fin n) x).differentiableAt
  · have hk : n ≤ k.val := by omega
    let G : (Fin n → ℝ) → (Fin N → ℝ) := fun y j => if j < k then t.forward y j else t.forward x j
    have hGj : ∀ j : Fin N, j < k → DifferentiableAt ℝ (fun y => t.forward y j) x :=
      fun j hj => (ih j.val (by rw [← hks]; exact hj) j rfl).1
    have hG : DifferentiableAt ℝ G x := by
      rw [differentiableAt_pi]
      intro j
      by_cases hj : j < k
      · simp only [G, hj, if_true]
        exact hGj j hj
      · simp only [G, hj, if_false]
        exact differentiableAt_const _
    have hF : (fun y => t.forward y k) = fun y => t.op k (G y) := by
      funext y
      rw [forward_step t y k hk]
      apply t.uses_earlier
      intro j hj
      simp [G, hj]
    have hGx : G x = t.forward x := by
      funext j
      by_cases hj : j < k <;> simp [G, hj]
    have hd : DifferentiableAt ℝ (t.op k) (G x) := by rw [hGx]; exact hdiff k hk
    refine ⟨?_, fun _ v => ?_⟩
    · rw [hF]; exact hd.comp x hG
    · rw [hF]
      show fderiv ℝ (t.op k ∘ G) x v = _
      rw [fderiv_comp x hd hG, ContinuousLinearMap.comp_apply, hGx, linear_expand]
      refine Finset.sum_congr rfl (fun j _ => ?_)
      have hcomp : fderiv ℝ G x v j = fderiv ℝ (fun y => G y j) x v := by
        rw [fderiv_apply hG j]; rfl
      rw [hcomp]
      unfold Tape.slope
      by_cases hj : j < k
      · simp only [G, hj, if_true]
        ring
      · simp only [G, hj, if_false, fderiv_const_apply]
        simp

#print axioms run_add
#print axioms run_eq_forward
#print axioms run_input
#print axioms forward_input
#print axioms forward_step
#print axioms linear_expand
#print axioms fderiv_input
#print axioms deriv_step

end TapeHelp

namespace TapeHelp

open Tape

lemma back_inv {n m : ℕ} (t : Tape n (m + 1)) (x : Fin n → ℝ)
    (hD : ∀ k : Fin (m + 1), n ≤ k.val → ∀ v, fderiv ℝ (fun y => t.forward y k) x v =
      ∑ j, (if j < k then t.slope x k j * fderiv ℝ (fun y => t.forward y j) x v else 0))
    (v : Fin n → ℝ) :
    ∀ c, c + n ≤ m + 1 → fderiv ℝ (fun y => t.forward y (Fin.last m)) x v =
      ∑ j : Fin (m + 1), (if j.val + c ≤ m then
        t.back x c j * fderiv ℝ (fun y => t.forward y j) x v else 0) := by
  intro c
  induction c with
  | zero =>
    intro _
    have hj : ∀ j : Fin (m + 1), j.val + 0 ≤ m := fun j => by have := j.2; omega
    simp only [hj, if_true, Tape.back]
    simp [Pi.single_apply]
  | succ c ih =>
    intro hc
    rw [ih (by omega)]
    have hcond : c ≤ m ∧ n ≤ m - c := ⟨by omega, by omega⟩
    set k : Fin (m + 1) := ⟨m - c, by omega⟩ with hkdef
    have hback : t.back x (c + 1) = fun j =>
        if j < k then t.back x c j + t.back x c k * t.slope x k j else t.back x c j := by
      rw [Tape.back, dif_pos hcond]
    have e1 : ∀ j : Fin (m + 1), (if j.val + c ≤ m then
        t.back x c j * fderiv ℝ (fun y => t.forward y j) x v else 0) =
        (if j < k then t.back x c j * fderiv ℝ (fun y => t.forward y j) x v else 0) +
        (if j = k then t.back x c j * fderiv ℝ (fun y => t.forward y j) x v else 0) := by
      intro j
      have hkv : k.val = m - c := rfl
      by_cases h1 : j < k
      · have h2 : j ≠ k := ne_of_lt h1
        have h3 : j.val + c ≤ m := by rw [Fin.lt_def] at h1; omega
        rw [if_pos h1, if_neg h2, if_pos h3, add_zero]
      · by_cases h2 : j = k
        · have h3 : j.val + c ≤ m := by rw [h2]; omega
          rw [if_neg h1, if_pos h2, if_pos h3, zero_add]
        · have h2' : j.val ≠ m - c := fun h => h2 (Fin.ext (by rw [h, hkv]))
          have h3 : ¬ j.val + c ≤ m := by rw [Fin.lt_def] at h1; omega
          rw [if_neg h1, if_neg h2, if_neg h3, add_zero]
    rw [Finset.sum_congr rfl (fun j _ => e1 j), Finset.sum_add_distrib]
    simp only [Finset.sum_ite_eq', Finset.mem_univ, if_true]
    rw [hD k (by simp [k]; omega) v, Finset.mul_sum, ← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl (fun j _ => ?_)
    rw [hback]
    by_cases h1 : j < k
    · have h3 : j.val + (c + 1) ≤ m := by rw [Fin.lt_def] at h1; simp [k] at h1; omega
      simp only [h1, h3, if_true]
      ring
    · have h3 : ¬ j.val + (c + 1) ≤ m := by rw [Fin.lt_def] at h1; simp [k] at h1; omega
      simp [h1, h3]

lemma back_stable {n m : ℕ} (t : Tape n (m + 1)) (x : Fin n → ℝ) (hn1 : 1 ≤ n) (hn : n ≤ m + 1) :
    ∀ d, t.back x (m + 1 - n + d) = t.back x (m + 1 - n)
  | 0 => rfl
  | d + 1 => by
    rw [← add_assoc, Tape.back, dif_neg (by omega)]
    exact back_stable t x hn1 hn d

#print axioms back_inv
#print axioms back_stable

end TapeHelp

/-- The card's main claim. Record the steps that produce the answer (the last line), then
sweep the tape backwards once, multiplying by each step's local slope and adding the
contributions wherever a value was used more than once. If every step has a slope at the
point (it is differentiable there), the adjoint left on each input line is exactly the
derivative of the answer with respect to that input. -/
theorem reverse_sweep_gives_every_derivative {n m : ℕ} (hn : n ≤ m + 1)
    (t : Tape n (m + 1)) (x : Fin n → ℝ)
    (hdiff : ∀ k : Fin (m + 1), n ≤ k.val → DifferentiableAt ℝ (t.op k) (t.forward x))
    (i : Fin n) :
    t.adjoint x (Fin.castLE hn i) =
      fderiv ℝ (fun y => t.forward y (Fin.last m)) x (Pi.single i 1) := by
  have hn1 : 1 ≤ n := by have := i.2; omega
  have hD : ∀ k : Fin (m + 1), n ≤ k.val → ∀ v, fderiv ℝ (fun y => t.forward y k) x v =
      ∑ j, (if j < k then t.slope x k j * fderiv ℝ (fun y => t.forward y j) x v else 0) :=
    fun k hk => (TapeHelp.deriv_step t x hdiff k.val k rfl).2 hk
  rw [TapeHelp.back_inv t x hD (Pi.single i 1) (m + 1 - n) (by omega)]
  unfold Tape.adjoint
  have hb : t.back x (m + 1) = t.back x (m + 1 - n) := by
    have := TapeHelp.back_stable t x hn1 hn n
    rwa [show m + 1 - n + n = m + 1 by omega] at this
  rw [hb]
  rw [Finset.sum_eq_single (Fin.castLE hn i)]
  · have hc : (Fin.castLE hn i).val + (m + 1 - n) ≤ m := by simp; omega
    rw [if_pos hc, TapeHelp.fderiv_input t x _ _ (by simp)]
    simp
  · intro b _ hb
    split_ifs with hc
    · have hbn : b.val < n := by omega
      rw [TapeHelp.fderiv_input t x _ _ hbn]
      have : (⟨b.val, hbn⟩ : Fin n) ≠ i := by
        intro h; apply hb; ext; simp [← h]
      simp [Pi.single_apply, this]
    · rfl
  · intro h; exact absurd (Finset.mem_univ _) h

/-- The cost claim. If no step has more than two inputs, the arrows into the step lines
(one multiply-and-add each in the sweep) number at most twice the step lines, so a
sweep costs at most about two forward passes however many inputs there are. -/
theorem sweep_arrows_at_most_twice_steps (m : ℕ) (arity : Fin m → ℕ)
    (h : ∀ k, arity k ≤ 2) : ∑ k, arity k ≤ 2 * m := by
  calc ∑ k, arity k ≤ ∑ _k : Fin m, 2 := Finset.sum_le_sum (fun k _ => h k)
    _ = 2 * m := by simp [mul_comm]

/-- The zero hiding in the Black–Scholes tape. With `d₁` and `d₂ = d₁ - σ√T` as in the
call formula and `φ` the standard bell-curve height, the adjoint reaching `d₁`,
`S e^{-qT} φ(d₁) - K e^{-rT} φ(d₂)`, is exactly zero. -/
theorem black_scholes_adjoint_of_d1_is_zero (S K r q σ T d₁ d₂ : ℝ)
    (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hd₁ : d₁ = (Real.log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * Real.sqrt T))
    (hd₂ : d₂ = d₁ - σ * Real.sqrt T) :
    S * Real.exp (-q * T) * gaussianPDFReal 0 1 d₁
      - K * Real.exp (-r * T) * gaussianPDFReal 0 1 d₂ = 0 := by
  have hsT : 0 < Real.sqrt T := Real.sqrt_pos.mpr hT
  have hsT2 : Real.sqrt T ^ 2 = T := Real.sq_sqrt hT.le
  have hσs : σ * Real.sqrt T ≠ 0 := by positivity
  have key : d₁ * (σ * Real.sqrt T) = Real.log (S / K) + (r - q + σ ^ 2 / 2) * T := by
    rw [hd₁]; field_simp
  have hexp : -(d₂ - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ)) =
      -(d₁ - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ)) + Real.log (S / K) + (r - q) * T := by
    rw [hd₂]
    have : (d₁ - σ * Real.sqrt T) ^ 2 = d₁ ^ 2 - 2 * (d₁ * (σ * Real.sqrt T)) + σ ^ 2 * Real.sqrt T ^ 2 := by ring
    simp only [sub_zero, NNReal.coe_one, mul_one]
    rw [this, key, hsT2]
    ring
  have hSK : 0 < S / K := div_pos hS hK
  simp only [gaussianPDFReal]
  rw [hexp, Real.exp_add, Real.exp_add, Real.exp_log hSK]
  have e1 : Real.exp (-q * T) = Real.exp (-r * T) * Real.exp ((r - q) * T) := by
    rw [← Real.exp_add]; ring_nf
  rw [e1]
  field_simp
  ring

-- The toy forward-price tape: steps r - q, (r - q)·T, e^(that), S·(that).
-- 4 step lines, 7 arrows.
example : [2, 2, 1, 2].length = 4 ∧ [2, 2, 1, 2].sum = 7 := by decide

-- The Black–Scholes tape: the number of inputs of each of its step lines, in tape order.
-- 26 step lines, 42 arrows, within the bound of 2 × 26 = 52.
example :
    [1, 2, 2, 1, 2, 2, 1, 2, 2, 2, 2, 2, 1, 1, 2, 1, 1, 2, 1, 1, 2, 2, 2, 2, 1, 2].length = 26 ∧
    [1, 2, 2, 1, 2, 2, 1, 2, 2, 2, 2, 2, 1, 1, 2, 1, 1, 2, 1, 1, 2, 2, 2, 2, 1, 2].sum = 42 ∧
    42 ≤ 2 * 26 := by decide

-- Nudging each way costs 2 pricings per slope plus the price: 13 pricings for six slopes.
example : 1 + 2 * 6 = 13 := by norm_num

#print axioms reverse_sweep_gives_every_derivative
#print axioms sweep_arrows_at_most_twice_steps
#print axioms black_scholes_adjoint_of_d1_is_zero
