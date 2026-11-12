-- Reverse mode: for a program made of steps that each have a derivative where they run, the backward sweep that multiplies a seed row by each step's local Jacobian, last step first, returns the seed row times the whole program's Jacobian, and a checkpointed sweep done segment by segment gives the same answer.
import Mathlib.Analysis.Calculus.FDeriv.Comp
import Mathlib.Analysis.Calculus.FDeriv.Pi
import Mathlib.Analysis.Calculus.FDeriv.Add
import Mathlib.Analysis.Calculus.FDeriv.Mul
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.Tactic.NormNum

open Matrix

/-- The program's run. Step `i` reads the `d i` numbers the program holds before it and hands
`d (i + 1)` numbers to the next step. `runState φ x i` is what the program holds after its first
`i` steps, started from the inputs `x`. Loops and branches have already been unrolled into the
straight-line list of steps that this run executed. -/
def runState {d : ℕ → ℕ} (φ : ∀ i, (Fin (d i) → ℝ) → (Fin (d (i + 1)) → ℝ))
    (x : Fin (d 0) → ℝ) : (i : ℕ) → Fin (d i) → ℝ
  | 0 => x
  | i + 1 => φ i (runState φ x i)

/-- The Jacobian of a map at a point: entry (r, c) is the slope of output r against input c. -/
noncomputable def jac {m n : ℕ} (f : (Fin n → ℝ) → (Fin m → ℝ)) (a : Fin n → ℝ) :
    Matrix (Fin m) (Fin n) ℝ :=
  LinearMap.toMatrix' (fderiv ℝ f a : (Fin n → ℝ) →ₗ[ℝ] (Fin m → ℝ))

/-- The backward sweep over the first `L` steps. Start from the seed row `ybar` on the last
step's outputs; multiply it by the last step's local Jacobian, read where that step ran; then by
the step before's; and so on back to the inputs. -/
noncomputable def sweep {d : ℕ → ℕ} (φ : ∀ i, (Fin (d i) → ℝ) → (Fin (d (i + 1)) → ℝ))
    (x : Fin (d 0) → ℝ) : (L : ℕ) → (Fin (d L) → ℝ) → (Fin (d 0) → ℝ)
  | 0, ybar => ybar
  | L + 1, ybar => sweep φ x L (vecMul ybar (jac (φ L) (runState φ x L)))

theorem runState_differentiableAt {d : ℕ → ℕ}
    (φ : ∀ i, (Fin (d i) → ℝ) → (Fin (d (i + 1)) → ℝ)) (x : Fin (d 0) → ℝ) (L : ℕ)
    (hφ : ∀ i < L, DifferentiableAt ℝ (φ i) (runState φ x i)) :
    DifferentiableAt ℝ (fun z => runState φ z L) x := by
  induction L with
  | zero => exact differentiableAt_id
  | succ L ih =>
    have h1 := ih (fun i hi => hφ i (Nat.lt_succ_of_lt hi))
    have h2 := hφ L (Nat.lt_succ_self L)
    exact h2.comp x h1

theorem runState_shift {d : ℕ → ℕ}
    (φ : ∀ i, (Fin (d i) → ℝ) → (Fin (d (i + 1)) → ℝ)) (x : Fin (d 0) → ℝ) (s t : ℕ) :
    runState (d := fun i => d (s + i)) (fun i => φ (s + i)) (runState φ x s) t
      = runState φ x (s + t) := by
  induction t with
  | zero => rfl
  | succ t ih =>
    show φ (s + t) (runState (d := fun i => d (s + i)) (fun i => φ (s + i)) (runState φ x s) t) = _
    rw [ih]; rfl

/-- **Reverse mode returns the vector-Jacobian product.** Write a program as `L` steps
φ₀, …, φ_{L-1}. If every step has a derivative (a slope) at the point where it actually runs,
then the backward sweep, which multiplies the seed row ȳ by each step's local Jacobian from the
last step to the first, returns ȳᵀ J, where J is the Jacobian of the whole program at the inputs:
x̄ᵀ = ((ȳᵀ J_L) J_{L-1}) ⋯ J_1 = ȳᵀ J. -/
theorem reverse_sweep_eq_vector_jacobian_product {d : ℕ → ℕ}
    (φ : ∀ i, (Fin (d i) → ℝ) → (Fin (d (i + 1)) → ℝ)) (x : Fin (d 0) → ℝ) (L : ℕ)
    (ybar : Fin (d L) → ℝ)
    (hφ : ∀ i < L, DifferentiableAt ℝ (φ i) (runState φ x i)) :
    sweep φ x L ybar = vecMul ybar (jac (fun z => runState φ z L) x) := by
  induction L with
  | zero =>
    show ybar = vecMul ybar (jac (fun z => z) x)
    simp [jac]
  | succ L ih =>
    have h1 := runState_differentiableAt φ x L (fun i hi => hφ i (Nat.lt_succ_of_lt hi))
    have h2 := hφ L (Nat.lt_succ_self L)
    have hc : fderiv ℝ (fun z => runState φ z (L + 1)) x
        = (fderiv ℝ (φ L) (runState φ x L)).comp (fderiv ℝ (fun z => runState φ z L) x) :=
      fderiv_comp (g := φ L) (f := fun z => runState φ z L) x h2 h1
    show sweep φ x L (vecMul ybar (jac (φ L) (runState φ x L))) = _
    rw [ih _ (fun i hi => hφ i (Nat.lt_succ_of_lt hi)), vecMul_vecMul]
    congr 1
    simp only [jac, hc]
    rw [← LinearMap.toMatrix'_comp]
    rfl

/-- **The sweep returns the gradient of the weighted output.** Under the same condition, the
adjoint the sweep leaves on input k is the partial derivative, with respect to input k, of the
weighted output Φ = Σ_b ȳ_b y_b. Seeding the four bond prices with the holdings therefore gives
the book value's slope against every curve node in one sweep. -/
theorem reverse_sweep_eq_partial_of_weighted_output {d : ℕ → ℕ}
    (φ : ∀ i, (Fin (d i) → ℝ) → (Fin (d (i + 1)) → ℝ)) (x : Fin (d 0) → ℝ) (L : ℕ)
    (ybar : Fin (d L) → ℝ)
    (hφ : ∀ i < L, DifferentiableAt ℝ (φ i) (runState φ x i)) (k : Fin (d 0)) :
    sweep φ x L ybar k =
      fderiv ℝ (fun z => ∑ b, ybar b * runState φ z L b) x (Pi.single k 1) := by
  rw [reverse_sweep_eq_vector_jacobian_product φ x L ybar hφ]
  have hd := (runState_differentiableAt φ x L hφ).hasFDerivAt
  have hb : ∀ b, HasFDerivAt (fun z => ybar b * runState φ z L b)
      (ybar b • (ContinuousLinearMap.proj b).comp (fderiv ℝ (fun z => runState φ z L) x)) x :=
    fun b => (hasFDerivAt_pi'.1 hd b).const_mul (ybar b)
  have hs := HasFDerivAt.fun_sum (u := Finset.univ) (fun b _ => hb b)
  rw [hs.fderiv]
  simp [vecMul, dotProduct, jac, LinearMap.toMatrix'_apply]

/-- **Checkpointing gives the same adjoints.** Split the run after `s` steps. Store only the state
the program holds there, restart the last `t` steps from it and sweep that segment alone, seeded
with ȳ; then hand the adjoints of its starting state to a sweep of the first `s` steps. The result
is exactly the sweep of the full `s + t`-step tape. -/
theorem checkpointed_sweep_eq_full_sweep {d : ℕ → ℕ}
    (φ : ∀ i, (Fin (d i) → ℝ) → (Fin (d (i + 1)) → ℝ)) (x : Fin (d 0) → ℝ) (s t : ℕ)
    (ybar : Fin (d (s + t)) → ℝ) :
    sweep φ x (s + t) ybar =
      sweep φ x s (sweep (d := fun i => d (s + i)) (fun i => φ (s + i)) (runState φ x s) t ybar) := by
  induction t with
  | zero => rfl
  | succ t ih =>
    show sweep φ x (s + t) (vecMul ybar (jac (φ (s + t)) (runState φ x (s + t)))) =
      sweep φ x s (sweep (d := fun i => d (s + i)) (fun i => φ (s + i)) (runState φ x s) t
        (vecMul ybar (jac (φ (s + t))
          (runState (d := fun i => d (s + i)) (fun i => φ (s + i)) (runState φ x s) t))))
    rw [runState_shift, ih]

-- The tape: 50 nodes, one starting discount factor and four starting prices are the 55 inputs;
-- with 618 operations the tape holds 673 entries.
example : (50 + 1 + 4) + 618 = 673 := by norm_num

-- No step has more than two inputs, so 867 edges are at most twice the 618 operations.
example : 867 ≤ 2 * 618 := by norm_num

-- Central bumps on 50 nodes need 2 × 50 + 1 = 101 pricings.
example : 2 * 50 + 1 = 101 := by norm_num

-- Period 60's midpoint, 29.75 years, sits between node 49 (29.4 years) and node 50 (30 years)
-- with weight 7/12 on node 50 and 5/12 on node 49.
example : ((60 - 1 / 2 : ℚ) / 2 - 49 * (3 / 5)) / (3 / 5) = 7 / 12 := by norm_num
example : (5 / 12 : ℚ) + 7 / 12 = 1 := by norm_num

-- The seed on D₆₀ by hand: the 30-year bond pays 102 per $100 in period 60, held 500,000 times.
example : 102 * 500000 = 51000000 := by norm_num

-- Stored states for a 60-period loop checkpointed every 60, 15, 8, 4 and 1 periods.
example : [60, 15, 8, 4, 1].map (fun s => (60 + s - 1) / s) = [1, 4, 8, 15, 60] := by decide

#print axioms runState_differentiableAt
#print axioms runState_shift
#print axioms reverse_sweep_eq_vector_jacobian_product
#print axioms reverse_sweep_eq_partial_of_weighted_output
#print axioms checkpointed_sweep_eq_full_sweep
