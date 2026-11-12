-- Search without derivatives: no method that reads finitely many values can certify a global minimum, Nelder-Mead's best value never rises, and the rotated ripple surface is never below 0 and is 0 only at the origin.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.Topology.Order.MonotoneConvergence

open Filter Topology

/-- A method that reads values only: at step `k` it picks its next point from the `k` values
it has seen so far. -/
def ValueMethod (E : Type*) := (k : ℕ) → (Fin k → ℝ) → E

/-- The point a value-only method evaluates at step `k` when run on `f`. -/
noncomputable def ValueMethod.trace {E : Type*} (q : ValueMethod E) (f : E → ℝ) (k : ℕ) : E :=
  q k (fun i : Fin k => f (q.trace f i.1))
termination_by k
decreasing_by exact i.2

/-- No method that sees finitely many values can certify a global minimum. For any method that
reads only values, any number `K` of evaluations and any cost `f` on `n` settings (`n ≥ 1`),
there is a ball holding none of the evaluated points and a new cost `g`, equal to `f` outside
that ball and differing from it by a continuous pit, on which the method makes exactly the same
`K` choices, sees the same values, and yet `g` dips at least one unit below every value seen. -/
theorem no_finite_list_of_values_certifies_global_minimum (n : ℕ) (hn : 0 < n)
    (q : ValueMethod (EuclideanSpace ℝ (Fin n))) (f : EuclideanSpace ℝ (Fin n) → ℝ) (K : ℕ) :
    ∃ (c : EuclideanSpace ℝ (Fin n)) (r : ℝ), 0 < r ∧ (∀ k < K, q.trace f k ∉ Metric.ball c r) ∧
      ∃ g : EuclideanSpace ℝ (Fin n) → ℝ,
        (∀ x ∉ Metric.ball c r, g x = f x) ∧ Continuous (g - f) ∧
        (∀ k < K, q.trace g k = q.trace f k ∧ g (q.trace g k) = f (q.trace f k)) ∧
        ∃ z, ∀ k < K, g z ≤ f (q.trace f k) - 1 := by
  classical
  set M : ℝ := (∑ k ∈ Finset.range K, ‖q.trace f k‖) + 2 with hM
  set e : EuclideanSpace ℝ (Fin n) := EuclideanSpace.single (⟨0, hn⟩ : Fin n) (1 : ℝ) with he
  have he1 : ‖e‖ = 1 := (EuclideanSpace.orthonormal_single (𝕜 := ℝ) (ι := Fin n)).1 _
  set c : EuclideanSpace ℝ (Fin n) := M • e with hc
  have hMnn : 0 ≤ ∑ k ∈ Finset.range K, ‖q.trace f k‖ :=
    Finset.sum_nonneg (fun _ _ => norm_nonneg _)
  have hcn : ‖c‖ = M := by
    rw [hc, norm_smul, he1, mul_one, Real.norm_eq_abs, abs_of_nonneg (by linarith)]
  have hout : ∀ k < K, q.trace f k ∉ Metric.ball c 1 := by
    intro k hk hmem
    rw [Metric.mem_ball, dist_eq_norm] at hmem
    have h1 : ‖q.trace f k‖ ≤ ∑ k ∈ Finset.range K, ‖q.trace f k‖ :=
      Finset.single_le_sum (f := fun k => ‖q.trace f k‖) (fun _ _ => norm_nonneg _)
        (Finset.mem_range.2 hk)
    have h2 : ‖c‖ ≤ ‖q.trace f k‖ + ‖q.trace f k - c‖ := by
      have := norm_sub_le (q.trace f k) (q.trace f k - c)
      simpa using this
    linarith
  set D : ℝ := |f c| + (∑ k ∈ Finset.range K, |f (q.trace f k)|) + 1 with hD
  set h : EuclideanSpace ℝ (Fin n) → ℝ := fun x => -D * max 0 (1 - dist x c) with hh
  have hcont : Continuous h :=
    continuous_const.mul (continuous_const.max (continuous_const.sub
      (continuous_id.dist continuous_const)))
  have hzero : ∀ x ∉ Metric.ball c 1, h x = 0 := by
    intro x hx
    rw [Metric.mem_ball, not_lt] at hx
    simp only [hh]
    rw [max_eq_left (by linarith)]
    ring
  refine ⟨c, 1, one_pos, hout, fun x => f x + h x, ?_, ?_, ?_, c, ?_⟩
  · intro x hx
    simp [hzero x hx]
  · have : ((fun x => f x + h x) - f) = h := by
      funext x; simp
    rw [this]; exact hcont
  · have key : ∀ k, k < K → q.trace (fun x => f x + h x) k = q.trace f k := by
      intro k
      induction k using Nat.strong_induction_on with
      | _ k ih =>
        intro hk
        rw [ValueMethod.trace, ValueMethod.trace]
        congr 1
        funext i
        rw [ih i.1 i.2 (lt_trans i.2 hk), hzero _ (hout _ (lt_trans i.2 hk)), add_zero]
    intro k hk
    refine ⟨key k hk, ?_⟩
    rw [key k hk]
    show f (q.trace f k) + h (q.trace f k) = f (q.trace f k)
    rw [hzero _ (hout _ hk), add_zero]
  · intro k hk
    have hhc : h c = -D := by simp [hh]
    have h1 : |f (q.trace f k)| ≤ ∑ k ∈ Finset.range K, |f (q.trace f k)| :=
      Finset.single_le_sum (f := fun k => |f (q.trace f k)|) (fun _ _ => abs_nonneg _)
        (Finset.mem_range.2 hk)
    have h2 := neg_abs_le (f (q.trace f k))
    have h3 := le_abs_self (f c)
    show f c + h c ≤ _
    rw [hhc, hD]
    linarith

/-- One Nelder-Mead step on a simplex of `n + 2` corners in `n + 1` settings, sorted best first.
Every trial point is `c + t (worst - c)`, with `c` the centre of all corners but the worst:
reflect (`t = -1`), expand (`t = -2`), contract outside (`t = -1/2`) or inside (`t = 1/2`),
and otherwise shrink every corner halfway toward the best. -/
noncomputable def nelderMeadStep (n : ℕ) (f : EuclideanSpace ℝ (Fin (n + 1)) → ℝ)
    (P : Fin (n + 2) → EuclideanSpace ℝ (Fin (n + 1))) : Fin (n + 2) → EuclideanSpace ℝ (Fin (n + 1)) :=
  let w : Fin (n + 2) := Fin.last (n + 1)
  let c : EuclideanSpace ℝ (Fin (n + 1)) := (1 / ((n : ℝ) + 1)) • ∑ i : Fin (n + 1), P i.castSucc
  let pt : ℝ → EuclideanSpace ℝ (Fin (n + 1)) := fun t => c + t • (P w - c)
  let xr := pt (-1)
  if f xr < f (P 0) then
    Function.update P w (if f (pt (-2)) < f xr then pt (-2) else xr)
  else if f xr < f (P (Fin.last n).castSucc) then
    Function.update P w xr
  else
    let xc := pt (if f xr < f (P w) then -1 / 2 else 1 / 2)
    if f xc < min (f xr) (f (P w)) then Function.update P w xc
    else fun i => P 0 + (1 / 2 : ℝ) • (P i - P 0)

/-- Nelder-Mead's best value never rises: if every simplex is sorted best first and each one is a
re-sorting of one Nelder-Mead step from the one before, the best corner's value never goes up,
and when the cost has a floor these best values settle to some number. -/
theorem nelder_mead_best_value_never_rises (n : ℕ) (f : EuclideanSpace ℝ (Fin (n + 1)) → ℝ)
    (S : ℕ → Fin (n + 2) → EuclideanSpace ℝ (Fin (n + 1)))
    (hsorted : ∀ k, Monotone (fun i => f (S k i)))
    (hstep : ∀ k, ∃ σ : Equiv.Perm (Fin (n + 2)), S (k + 1) = nelderMeadStep n f (S k) ∘ σ) :
    Antitone (fun k => f (S k 0)) ∧
      ((∃ m, ∀ x, m ≤ f x) → ∃ L, Tendsto (fun k => f (S k 0)) atTop (𝓝 L)) := by
  have h0 : ∀ P : Fin (n + 2) → EuclideanSpace ℝ (Fin (n + 1)), nelderMeadStep n f P 0 = P 0 := by
    intro P
    have hne : (0 : Fin (n + 2)) ≠ Fin.last (n + 1) := (Fin.last_pos).ne
    unfold nelderMeadStep
    simp only
    split_ifs <;> simp [hne]
  have hanti : Antitone (fun k => f (S k 0)) := by
    apply antitone_nat_of_succ_le
    intro k
    obtain ⟨σ, hσ⟩ := hstep k
    have h1 : f (S (k + 1) 0) ≤ f (S (k + 1) (σ.symm 0)) := hsorted (k + 1) (Fin.zero_le _)
    rw [hσ] at h1 ⊢
    simpa [Function.comp, h0] using h1
  refine ⟨hanti, ?_⟩
  rintro ⟨m, hm⟩
  exact ⟨_, tendsto_atTop_ciInf hanti ⟨m, by rintro _ ⟨k, rfl⟩; exact hm _⟩⟩

/-- One ripple: a parabola with a cosine dent, `g(y) = y² - 10 cos(2πy) + 10`. -/
noncomputable def ripple (y : ℝ) : ℝ := y ^ 2 - 10 * Real.cos (2 * Real.pi * y) + 10

/-- The rotated ripple surface: `f(x) = Σ g(y_i)` with hidden coordinates `y = Qx`. -/
noncomputable def roughSurface {n : ℕ} (Q : Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ) : ℝ :=
  ∑ i, ripple ((Q.mulVec x) i)

/-- The floor: for any rotation `Q`, the rotated ripple surface is never negative, and it is `0`
only at the origin. -/
theorem rough_surface_floor_zero_only_at_origin (n : ℕ) (Q : Matrix (Fin n) (Fin n) ℝ)
    (hQ : Q ∈ Matrix.orthogonalGroup (Fin n) ℝ) (x : Fin n → ℝ) :
    0 ≤ roughSurface Q x ∧ (roughSurface Q x = 0 ↔ x = 0) := by
  have hr : ∀ y, y ^ 2 ≤ ripple y := by
    intro y
    unfold ripple
    have := Real.cos_le_one (2 * Real.pi * y)
    nlinarith
  have hnn : ∀ i ∈ (Finset.univ : Finset (Fin n)), 0 ≤ ripple ((Q.mulVec x) i) :=
    fun i _ => le_trans (sq_nonneg _) (hr _)
  refine ⟨Finset.sum_nonneg hnn, ?_⟩
  unfold roughSurface
  rw [Finset.sum_eq_zero_iff_of_nonneg hnn]
  constructor
  · intro h
    have hy : Q.mulVec x = 0 := by
      funext i
      have := h i (Finset.mem_univ _)
      have := hr ((Q.mulVec x) i)
      have := sq_nonneg ((Q.mulVec x) i)
      simpa using (show ((Q.mulVec x) i) ^ 2 = 0 by linarith)
    have hQ' := (Matrix.mem_orthogonalGroup_iff' (Fin n) ℝ).1 hQ
    calc x = (Q.transpose * Q).mulVec x := by rw [hQ', Matrix.one_mulVec]
      _ = Q.transpose.mulVec (Q.mulVec x) := by rw [Matrix.mulVec_mulVec]
      _ = 0 := by rw [hy, Matrix.mulVec_zero]
  · rintro rfl i _
    simp [ripple]

/-- McKinnon's function: `360u² + v + v²` for `u ≤ 0` and `6u² + v + v²` for `u > 0`. -/
noncomputable def mckinnon (u v : ℝ) : ℝ := (if u ≤ 0 then 360 else 6) * u ^ 2 + v + v ^ 2

-- The worst corner of the worked step: f(1, 1) = 6 + 1 + 1 = 8.
example : mckinnon 1 1 = 8 := by norm_num [mckinnon]
-- The best corner of the worked step: f(0, 0) = 0.
example : mckinnon 0 0 = 0 := by norm_num [mckinnon]
-- Valley floors of one ripple: g(0) = 0, g(1) = 1, g(2) = 4, g(3) = 9.
example : ripple 0 = 0 ∧ ripple 1 = 1 ∧ ripple 2 = 4 ∧ ripple 3 = 9 := by
  have h : ∀ m : ℕ, Real.cos (2 * Real.pi * m) = 1 := by
    intro m; rw [mul_comm]; exact Real.cos_nat_mul_two_pi m
  have h1 := h 1
  have h2 := h 2
  have h3 := h 3
  push_cast at h1 h2 h3
  simp only [mul_one] at h1
  refine ⟨?_, ?_, ?_, ?_⟩ <;> simp [ripple, h1, h2, h3] <;> norm_num

#print axioms no_finite_list_of_values_certifies_global_minimum
#print axioms nelder_mead_best_value_never_rises
#print axioms rough_surface_floor_zero_only_at_origin
