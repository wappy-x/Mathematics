-- Finite elements: for a cantilever cut into any number of equal beam elements with a load at the tip, the assembled and supported stiffness system K u = F has exactly one solution, and it is the true drop and slope at every node; each element matrix is the energy integral of its cubic shape functions, and without supports K has no inverse.
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic

noncomputable section

namespace FEBeam

open Matrix

/-- The element stiffness matrix `k` of one beam element of length `ℓ` and bending stiffness
`EI`, with end movements ordered `(v₁, θ₁, v₂, θ₂)`. -/
def kElem (EI ℓ : ℝ) : Matrix (Fin 4) (Fin 4) ℝ :=
  (EI / ℓ ^ 3) • !![12, 6 * ℓ, -12, 6 * ℓ;
                    6 * ℓ, 4 * ℓ ^ 2, -6 * ℓ, 2 * ℓ ^ 2;
                    -12, -6 * ℓ, 12, -6 * ℓ;
                    6 * ℓ, 2 * ℓ ^ 2, -6 * ℓ, 4 * ℓ ^ 2]

/-- Node `i` (at distance `i ℓ` from the wall) has movement number `2 i` (its drop) and
`2 i + 1` (its slope). Element `e` joins nodes `e` and `e + 1`, so its four end movements are
numbers `2e, 2e+1, 2e+2, 2e+3`. This is the entry element `e` adds at position `(a, b)`. -/
def elemEntry (EI ℓ : ℝ) (e a b : ℕ) : ℝ :=
  if h : 2 * e ≤ a ∧ a < 2 * e + 4 ∧ 2 * e ≤ b ∧ b < 2 * e + 4 then
    kElem EI ℓ ⟨a - 2 * e, by omega⟩ ⟨b - 2 * e, by omega⟩
  else 0

/-- The assembled stiffness matrix of `n` elements, every node free (nothing fixed):
each element's `k` is added into the rows and columns of its two nodes. -/
def Kfull (n : ℕ) (EI ℓ : ℝ) : Matrix (Fin (2 * (n + 1))) (Fin (2 * (n + 1))) ℝ :=
  fun a b => ∑ e ∈ Finset.range n, elemEntry EI ℓ e a b

/-- The same matrix with the wall fixed: node 0's drop and slope are removed, so free
movement number `a` is overall movement number `a + 2`. -/
def Kfree (n : ℕ) (EI ℓ : ℝ) : Matrix (Fin (2 * n)) (Fin (2 * n)) ℝ :=
  fun a b => ∑ e ∈ Finset.range n, elemEntry EI ℓ e (a + 2) (b + 2)

/-- The load list `F`: a force `P` on the drop of the tip node `n`, zero everywhere else. -/
def tipLoad (n : ℕ) (P : ℝ) : Fin (2 * n) → ℝ :=
  fun a => if (a : ℕ) = 2 * n - 2 then P else 0

/-- The free node `a / 2 + 1` that free movement number `a` belongs to sits at this distance
from the wall. -/
def nodeX (ℓ : ℝ) (a : ℕ) : ℝ := ((a / 2 + 1 : ℕ) : ℝ) * ℓ

/-- The four cubic shape functions of one element of length `ℓ`, written in `x`
(with `s = x / ℓ`): `N₁ = 1 - 3s² + 2s³`, `N₂ = ℓ(s - 2s² + s³)`, `N₃ = 3s² - 2s³`,
`N₄ = ℓ(s³ - s²)`. -/
def shapeFn (ℓ : ℝ) : Fin 4 → ℝ → ℝ
  | 0 => fun x => 1 - 3 * (x / ℓ) ^ 2 + 2 * (x / ℓ) ^ 3
  | 1 => fun x => ℓ * ((x / ℓ) - 2 * (x / ℓ) ^ 2 + (x / ℓ) ^ 3)
  | 2 => fun x => 3 * (x / ℓ) ^ 2 - 2 * (x / ℓ) ^ 3
  | 3 => fun x => ℓ * ((x / ℓ) ^ 3 - (x / ℓ) ^ 2)

lemma sum_loc (N e : ℕ) (g : ℕ → ℝ) (hN : 2 * e + 4 ≤ N)
    (hg : ∀ b, b < 2 * e ∨ 2 * e + 4 ≤ b → g b = 0) :
    ∑ b ∈ Finset.range N, g b = g (2 * e) + g (2 * e + 1) + g (2 * e + 2) + g (2 * e + 3) := by
  obtain ⟨m, rfl⟩ := Nat.exists_eq_add_of_le hN
  rw [show 2 * e + 4 + m = 2 * e + (4 + m) by ring, Finset.sum_range_add, Finset.sum_range_add]
  have h1 : ∑ x ∈ Finset.range (2 * e), g x = 0 :=
    Finset.sum_eq_zero fun x hx => hg x (Or.inl (Finset.mem_range.1 hx))
  have h2 : ∑ x ∈ Finset.range m, g (2 * e + (4 + x)) = 0 :=
    Finset.sum_eq_zero fun x _ => hg _ (Or.inr (by omega))
  rw [h1, h2]
  simp [Finset.sum_range_succ]

#print axioms sum_loc

lemma elemEntry_out (EI ℓ : ℝ) (e a b : ℕ) (h : ¬ (2 * e ≤ a ∧ a < 2 * e + 4)) :
    elemEntry EI ℓ e a b = 0 := by
  unfold elemEntry; rw [dite_eq_right]; tauto

#print axioms elemEntry_out

lemma elemEntry_out' (EI ℓ : ℝ) (e a b : ℕ) (h : b < 2 * e ∨ 2 * e + 4 ≤ b) :
    elemEntry EI ℓ e a b = 0 := by
  unfold elemEntry; rw [dite_eq_right]; omega

#print axioms elemEntry_out'

lemma elemEntry_loc (EI ℓ : ℝ) (e i j : ℕ) (hi : i < 4) (hj : j < 4) :
    elemEntry EI ℓ e (2 * e + i) (2 * e + j) = kElem EI ℓ ⟨i, hi⟩ ⟨j, hj⟩ := by
  unfold elemEntry; rw [dif_pos (show 2 * e ≤ 2 * e + i ∧ 2 * e + i < 2 * e + 4 ∧ 2 * e ≤ 2 * e + j ∧ 2 * e + j < 2 * e + 4 by omega)]
  congr 1 <;> ext <;> simp

#print axioms elemEntry_loc

/-- Row `a` of the assembled matrix acting on a vector, element by element. -/
lemma Kfull_mulVec (n : ℕ) (EI ℓ : ℝ) (W : ℕ → ℝ) (a : Fin (2 * (n + 1))) :
    (Kfull n EI ℓ *ᵥ fun b => W b) a = ∑ e ∈ Finset.range n,
      (elemEntry EI ℓ e a (2 * e) * W (2 * e) + elemEntry EI ℓ e a (2 * e + 1) * W (2 * e + 1) +
       elemEntry EI ℓ e a (2 * e + 2) * W (2 * e + 2) +
       elemEntry EI ℓ e a (2 * e + 3) * W (2 * e + 3)) := by
  simp only [mulVec, dotProduct, Kfull, Finset.sum_mul]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun e he => ?_
  rw [Fin.sum_univ_eq_sum_range (fun b => elemEntry EI ℓ e a b * W b)]
  apply sum_loc
  · have := Finset.mem_range.1 he; omega
  · intro b hb; rw [elemEntry_out' _ _ _ _ _ hb, zero_mul]

#print axioms Kfull_mulVec

lemma Kfree_mulVec (n : ℕ) (EI ℓ : ℝ) (W : ℕ → ℝ) (h0 : W 0 = 0) (h1 : W 1 = 0)
    (a : Fin (2 * n)) :
    (Kfree n EI ℓ *ᵥ fun b => W (b + 2)) a = ∑ e ∈ Finset.range n,
      (elemEntry EI ℓ e (a + 2) (2 * e) * W (2 * e) +
       elemEntry EI ℓ e (a + 2) (2 * e + 1) * W (2 * e + 1) +
       elemEntry EI ℓ e (a + 2) (2 * e + 2) * W (2 * e + 2) +
       elemEntry EI ℓ e (a + 2) (2 * e + 3) * W (2 * e + 3)) := by
  simp only [mulVec, dotProduct, Kfree, Finset.sum_mul]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun e he => ?_
  rw [Fin.sum_univ_eq_sum_range (fun b => elemEntry EI ℓ e (a + 2) (b + 2) * W (b + 2))]
  have : ∑ b ∈ Finset.range (2 * n), elemEntry EI ℓ e (a + 2) (b + 2) * W (b + 2) =
      ∑ b ∈ Finset.range (2 * n + 2), elemEntry EI ℓ e (a + 2) b * W b := by
    rw [Finset.sum_range_succ', Finset.sum_range_succ']
    simp [h0, h1]
  rw [this]
  apply sum_loc
  · have := Finset.mem_range.1 he; omega
  · intro b hb; rw [elemEntry_out' _ _ _ _ _ hb, zero_mul]

#print axioms Kfree_mulVec

lemma summand_loc (EI ℓ : ℝ) (W : ℕ → ℝ) (e r i : ℕ) (hi : i < 4) (hr : r = 2 * e + i) :
    elemEntry EI ℓ e r (2 * e) * W (2 * e) + elemEntry EI ℓ e r (2 * e + 1) * W (2 * e + 1) +
      elemEntry EI ℓ e r (2 * e + 2) * W (2 * e + 2) +
      elemEntry EI ℓ e r (2 * e + 3) * W (2 * e + 3) =
    kElem EI ℓ ⟨i, hi⟩ 0 * W (2 * e) + kElem EI ℓ ⟨i, hi⟩ 1 * W (2 * e + 1) +
      kElem EI ℓ ⟨i, hi⟩ 2 * W (2 * e + 2) + kElem EI ℓ ⟨i, hi⟩ 3 * W (2 * e + 3) := by
  subst hr
  have q0 := elemEntry_loc EI ℓ e i 0 hi (by norm_num)
  rw [add_zero] at q0
  rw [q0, elemEntry_loc EI ℓ e i 1 hi (by norm_num),
    elemEntry_loc EI ℓ e i 2 hi (by norm_num), elemEntry_loc EI ℓ e i 3 hi (by norm_num)]
  rfl

#print axioms summand_loc

lemma summand_out (EI ℓ : ℝ) (W : ℕ → ℝ) (e r : ℕ) (h : ¬ (2 * e ≤ r ∧ r < 2 * e + 4)) :
    elemEntry EI ℓ e r (2 * e) * W (2 * e) + elemEntry EI ℓ e r (2 * e + 1) * W (2 * e + 1) +
      elemEntry EI ℓ e r (2 * e + 2) * W (2 * e + 2) +
      elemEntry EI ℓ e r (2 * e + 3) * W (2 * e + 3) = 0 := by
  simp [elemEntry_out _ _ _ _ _ h]

#print axioms summand_out

lemma Kfree_row (n : ℕ) (EI ℓ : ℝ) (W : ℕ → ℝ) (h0 : W 0 = 0) (h1 : W 1 = 0)
    (k : ℕ) (hk : k < n) :
    (Kfree n EI ℓ *ᵥ fun b => W (b + 2)) ⟨2 * k, by omega⟩ =
      EI / ℓ ^ 3 * (-12 * W (2 * k) - 6 * ℓ * W (2 * k + 1) + 12 * W (2 * k + 2)
        - 6 * ℓ * W (2 * k + 3)) +
      (if k + 1 < n then EI / ℓ ^ 3 * (12 * W (2 * k + 2) + 6 * ℓ * W (2 * k + 3)
        - 12 * W (2 * k + 4) + 6 * ℓ * W (2 * k + 5)) else 0) ∧
    (Kfree n EI ℓ *ᵥ fun b => W (b + 2)) ⟨2 * k + 1, by omega⟩ =
      EI / ℓ ^ 3 * (6 * ℓ * W (2 * k) + 2 * ℓ ^ 2 * W (2 * k + 1) - 6 * ℓ * W (2 * k + 2)
        + 4 * ℓ ^ 2 * W (2 * k + 3)) +
      (if k + 1 < n then EI / ℓ ^ 3 * (6 * ℓ * W (2 * k + 2) + 4 * ℓ ^ 2 * W (2 * k + 3)
        - 6 * ℓ * W (2 * k + 4) + 2 * ℓ ^ 2 * W (2 * k + 5)) else 0) := by
  rw [Kfree_mulVec _ _ _ _ h0 h1, Kfree_mulVec _ _ _ _ h0 h1]
  simp only []
  have e1 : 2 * (k + 1) = 2 * k + 2 := by ring
  have e2 : 2 * k + 2 + 1 = 2 * k + 3 := by ring
  have e3 : 2 * k + 2 + 2 = 2 * k + 4 := by ring
  have e4 : 2 * k + 2 + 3 = 2 * k + 5 := by ring
  by_cases hk1 : k + 1 < n
  · rw [Finset.sum_eq_add_of_mem k (k + 1) (Finset.mem_range.2 hk) (Finset.mem_range.2 hk1)
      (by omega), Finset.sum_eq_add_of_mem k (k + 1) (Finset.mem_range.2 hk)
      (Finset.mem_range.2 hk1) (by omega)]
    · rw [summand_loc EI ℓ W k _ 2 (by norm_num) (by ring),
        summand_loc EI ℓ W (k + 1) _ 0 (by norm_num) (by ring),
        summand_loc EI ℓ W k _ 3 (by norm_num) (by ring),
        summand_loc EI ℓ W (k + 1) _ 1 (by norm_num) (by ring)]
      simp only [e1, e2, e3, e4, if_pos hk1]
      constructor <;> simp [kElem] <;> ring
    · intro c _ hc
      exact summand_out EI ℓ W c _ (by omega)
    · intro c _ hc
      exact summand_out EI ℓ W c _ (by omega)
  · rw [Finset.sum_eq_single k, Finset.sum_eq_single k]
    · rw [summand_loc EI ℓ W k _ 2 (by norm_num) (by ring),
        summand_loc EI ℓ W k _ 3 (by norm_num) (by ring)]
      simp only [if_neg hk1]
      constructor <;> simp [kElem] <;> ring
    · intro c hc hck
      have := Finset.mem_range.1 hc
      exact summand_out EI ℓ W c _ (by omega)
    · intro h; exact absurd (Finset.mem_range.2 hk) h
    · intro c hc hck
      have := Finset.mem_range.1 hc
      exact summand_out EI ℓ W c _ (by omega)
    · intro h; exact absurd (Finset.mem_range.2 hk) h

#print axioms Kfree_row

lemma cubic_dd (c0 c1 c2 c3 : ℝ) :
    deriv (deriv (fun x : ℝ => c0 + c1 * x + c2 * x ^ 2 + c3 * x ^ 3)) =
      fun x => 2 * c2 + 6 * c3 * x := by
  have h1 : ∀ x : ℝ, HasDerivAt (fun x : ℝ => c0 + c1 * x + c2 * x ^ 2 + c3 * x ^ 3)
      (c1 + 2 * c2 * x + 3 * c3 * x ^ 2) x := by
    intro x
    have := ((((hasDerivAt_const x c0).add ((hasDerivAt_id x).const_mul c1)).add
      ((hasDerivAt_pow 2 x).const_mul c2)).add ((hasDerivAt_pow 3 x).const_mul c3))
    convert this using 1
    · funext y; simp
    · simp; ring
  have h2 : deriv (fun x : ℝ => c0 + c1 * x + c2 * x ^ 2 + c3 * x ^ 3) =
      fun x => c1 + 2 * c2 * x + 3 * c3 * x ^ 2 := funext fun x => (h1 x).deriv
  rw [h2]
  funext x
  have := ((((hasDerivAt_const x c1).add ((hasDerivAt_id x).const_mul (2 * c2))).add
      ((hasDerivAt_pow 2 x).const_mul (3 * c3))))
  rw [show (fun x : ℝ => c1 + 2 * c2 * x + 3 * c3 * x ^ 2) =
    (fun x => c1 + 2 * c2 * id x + 3 * c3 * x ^ 2) from rfl]
  convert this.deriv using 1
  simp; ring

#print axioms cubic_dd

lemma lin_integral (EI ℓ a b c d : ℝ) :
    ∫ x in (0 : ℝ)..ℓ, EI * (a + b * x) * (c + d * x) =
      EI * (a * c * ℓ + (a * d + b * c) * ℓ ^ 2 / 2 + b * d * ℓ ^ 3 / 3) := by
  have hF : ∀ x ∈ Set.uIcc (0:ℝ) ℓ, HasDerivAt
      (fun x : ℝ => EI * (a * c * x + (a * d + b * c) * x ^ 2 / 2 + b * d * x ^ 3 / 3))
      (EI * (a + b * x) * (c + d * x)) x := by
    intro x _
    have := (((((hasDerivAt_id x).const_mul (a * c)).add
      (((hasDerivAt_pow 2 x).const_mul (a * d + b * c)).div_const 2)).add
      (((hasDerivAt_pow 3 x).const_mul (b * d)).div_const 3)).const_mul EI)
    convert this using 1
    · funext y; simp
    · simp; ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hF]
  · simp
  · apply Continuous.intervalIntegrable; fun_prop

#print axioms lin_integral

/-- The card's main claim (Steps 1 to 5 of Why it works). A cantilever of length `L = n ℓ`,
built into a wall at `x = 0`, is cut into `n ≥ 1` elements of length `ℓ > 0`, with bending
stiffness `EI > 0` and a load `P` at the tip. Its true drop `v` (down positive) obeys the
bending equation `EI v'' = P (L - x)`, with `v = 0` and slope `v' = 0` at the wall. Then
`K u = F`, with the wall fixed, has exactly one solution `u`, and it is the true drop and
slope at every node: the method is exact at the nodes for any number of elements. -/
theorem cantilever_tip_load_fem_exact_at_nodes
    (n : ℕ) (hn : 0 < n) (EI ℓ P : ℝ) (hEI : 0 < EI) (hℓ : 0 < ℓ)
    (v v' : ℝ → ℝ)
    (hv : ∀ x, HasDerivAt v (v' x) x)
    (hv' : ∀ x, HasDerivAt v' (P * (n * ℓ - x) / EI) x)
    (hv0 : v 0 = 0) (hv'0 : v' 0 = 0) :
    ∀ u : Fin (2 * n) → ℝ, Kfree n EI ℓ *ᵥ u = tipLoad n P ↔
      u = fun a : Fin (2 * n) => if (a : ℕ) % 2 = 0 then v (nodeX ℓ a) else v' (nodeX ℓ a) := by
  have hl : ℓ ≠ 0 := hℓ.ne'
  have hE : EI ≠ 0 := hEI.ne'
  have hc : EI / ℓ ^ 3 ≠ 0 := by positivity
  -- the true slope and drop, in closed form
  have hv'f : ∀ x, v' x = P * (n * ℓ * x - x ^ 2 / 2) / EI := by
    have hd : ∀ x, HasDerivAt (fun x => v' x - P * (n * ℓ * x - x ^ 2 / 2) / EI) 0 x := by
      intro x
      have h2 := ((((hasDerivAt_id x).const_mul ((n : ℝ) * ℓ)).sub
        ((hasDerivAt_pow 2 x).div_const 2)).const_mul P).div_const EI
      convert (hv' x).sub h2 using 1
      · funext y; simp only [Pi.sub_apply, id]
      · simp
    intro x
    have := is_const_of_deriv_eq_zero (fun x => (hd x).differentiableAt) (fun x => (hd x).deriv) x 0
    simp only [hv'0] at this
    norm_num at this
    linarith
  have hvf : ∀ x, v x = P * (n * ℓ * x ^ 2 / 2 - x ^ 3 / 6) / EI := by
    have hd : ∀ x, HasDerivAt (fun x => v x - P * (n * ℓ * x ^ 2 / 2 - x ^ 3 / 6) / EI) 0 x := by
      intro x
      have h2 := (((((hasDerivAt_pow 2 x).const_mul ((n : ℝ) * ℓ)).div_const 2).sub
        ((hasDerivAt_pow 3 x).div_const 6)).const_mul P).div_const EI
      convert (hv x).sub h2 using 1
      rw [hv'f]; simp; ring
    intro x
    have := is_const_of_deriv_eq_zero (fun x => (hd x).differentiableAt) (fun x => (hd x).deriv) x 0
    simp only [hv0] at this
    norm_num at this
    linarith
  intro u
  set U : ℕ → ℝ := fun k => if h : 2 ≤ k ∧ k < 2 * n + 2 then u ⟨k - 2, by omega⟩ else 0 with hU
  have hu : u = fun b : Fin (2 * n) => U (b + 2) := by
    funext b
    simp only [hU]
    rw [dif_pos (by omega)]
    congr 1
  have U0 : U 0 = 0 := by simp [hU]
  have U1 : U 1 = 0 := by simp [hU]
  have hrow := Kfree_row n EI ℓ U U0 U1
  rw [hu]
  -- the equations, row by row
  have hB : (Kfree n EI ℓ *ᵥ fun b => U (b + 2)) = tipLoad n P ↔ ∀ k (hk : k < n),
      (Kfree n EI ℓ *ᵥ fun b => U (b + 2)) ⟨2 * k, by omega⟩ = (if k + 1 = n then P else 0) ∧
      (Kfree n EI ℓ *ᵥ fun b => U (b + 2)) ⟨2 * k + 1, by omega⟩ = 0 := by
    constructor
    · intro h k hk
      rw [h]
      simp only [tipLoad]
      constructor
      · by_cases hk1 : k + 1 = n
        · rw [if_pos hk1, if_pos (by omega)]
        · rw [if_neg hk1, if_neg (by omega)]
      · rw [if_neg (by omega)]
    · intro h
      funext a
      obtain ⟨k, hk | hk⟩ := Nat.even_or_odd' (a : ℕ)
      · have hkn : k < n := by omega
        have := (h k hkn).1
        have ha : a = ⟨2 * k, by omega⟩ := Fin.ext hk
        rw [ha, this]
        simp only [tipLoad]
        by_cases hk1 : k + 1 = n
        · rw [if_pos hk1, if_pos (by omega)]
        · rw [if_neg hk1, if_neg (by omega)]
      · have hkn : k < n := by omega
        have := (h k hkn).2
        have ha : a = ⟨2 * k + 1, by omega⟩ := Fin.ext hk
        rw [ha, this]
        simp only [tipLoad]
        rw [if_neg (by omega)]
  -- the answer, node by node
  have hC : ((fun b : Fin (2 * n) => U (b + 2)) =
      fun a : Fin (2 * n) => if (a : ℕ) % 2 = 0 then v (nodeX ℓ a) else v' (nodeX ℓ a)) ↔
      ∀ m ≤ n, U (2 * m) = v ((m : ℝ) * ℓ) ∧ U (2 * m + 1) = v' ((m : ℝ) * ℓ) := by
    constructor
    · intro h m hm
      rcases m with _ | m
      · simp [U0, U1, hv0, hv'0]
      · have hx : nodeX ℓ (2 * m) = ((m + 1 : ℕ) : ℝ) * ℓ := by
          unfold nodeX; congr 2; omega
        have hx' : nodeX ℓ (2 * m + 1) = ((m + 1 : ℕ) : ℝ) * ℓ := by
          unfold nodeX; congr 2; omega
        have h1 := congrFun h ⟨2 * m, by omega⟩
        have h2 := congrFun h ⟨2 * m + 1, by omega⟩
        dsimp only at h1 h2
        rw [if_pos (by omega), hx] at h1
        rw [if_neg (by omega), hx'] at h2
        rw [show 2 * (m + 1) = 2 * m + 2 by ring, show 2 * m + 2 + 1 = 2 * m + 1 + 2 by ring]
        exact ⟨h1, h2⟩
    · intro h
      funext a
      obtain ⟨k, hk | hk⟩ := Nat.even_or_odd' (a : ℕ)
      · have hkn : k < n := by omega
        obtain ⟨h1, _⟩ := h (k + 1) (by omega)
        have hx : nodeX ℓ a = ((k + 1 : ℕ) : ℝ) * ℓ := by
          unfold nodeX; congr 2; omega
        rw [if_pos (by omega), hx, hk, ← h1]
        congr 1
      · have hkn : k < n := by omega
        obtain ⟨_, h2⟩ := h (k + 1) (by omega)
        have hx : nodeX ℓ a = ((k + 1 : ℕ) : ℝ) * ℓ := by
          unfold nodeX; congr 2; omega
        rw [if_neg (by omega), hx, hk, ← h2]
        congr 1
  rw [hB, hC]
  constructor
  · intro h
    -- the end forces of every element, from the tip back to the wall
    have hF : ∀ m e, e + m + 1 = n →
        EI / ℓ ^ 3 * (-12 * U (2 * e) - 6 * ℓ * U (2 * e + 1) + 12 * U (2 * e + 2)
          - 6 * ℓ * U (2 * e + 3)) = P ∧
        EI / ℓ ^ 3 * (6 * ℓ * U (2 * e) + 2 * ℓ ^ 2 * U (2 * e + 1) - 6 * ℓ * U (2 * e + 2)
          + 4 * ℓ ^ 2 * U (2 * e + 3)) = m * ℓ * P := by
      intro m
      induction m with
      | zero =>
        intro e he
        have h1 := (h e (by omega)).1
        have h2 := (h e (by omega)).2
        rw [(hrow e (by omega)).1, if_neg (by omega), if_pos (by omega)] at h1
        rw [(hrow e (by omega)).2, if_neg (by omega)] at h2
        constructor
        · linear_combination h1
        · push_cast; linear_combination h2
      | succ m ih =>
        intro e he
        obtain ⟨i1, i2⟩ := ih (e + 1) (by omega)
        simp only [show 2 * (e + 1) = 2 * e + 2 by ring, show 2 * e + 2 + 1 = 2 * e + 3 by ring,
          show 2 * e + 2 + 2 = 2 * e + 4 by ring, show 2 * e + 2 + 3 = 2 * e + 5 by ring] at i1 i2
        have h1 := (h e (by omega)).1
        have h2 := (h e (by omega)).2
        rw [(hrow e (by omega)).1, if_pos (by omega), if_neg (by omega)] at h1
        rw [(hrow e (by omega)).2, if_pos (by omega)] at h2
        constructor
        · linear_combination h1 + i1
        · push_cast; linear_combination h2 + ℓ * i1 + i2
    -- the node movements, from the wall out to the tip
    intro m
    induction m with
    | zero => intro _; simp [U0, U1, hv0, hv'0]
    | succ e ih =>
      intro he
      obtain ⟨j0, j1⟩ := ih (by omega)
      obtain ⟨m, hm⟩ : ∃ m, e + m + 1 = n := ⟨n - e - 1, by omega⟩
      obtain ⟨f1, f2⟩ := hF m e hm
      have hnR : (n : ℝ) = e + m + 1 := by rw [← hm]; push_cast; ring
      rw [j0, j1] at f1 f2
      have x1 : EI / ℓ ^ 3 * (-12 * v (e * ℓ) - 6 * ℓ * v' (e * ℓ) + 12 * v (((e + 1 : ℕ) : ℝ) * ℓ)
          - 6 * ℓ * v' (((e + 1 : ℕ) : ℝ) * ℓ)) = P := by
        simp only [hvf, hv'f]; push_cast; rw [hnR]; field_simp; ring
      have x2 : EI / ℓ ^ 3 * (6 * ℓ * v (e * ℓ) + 2 * ℓ ^ 2 * v' (e * ℓ)
          - 6 * ℓ * v (((e + 1 : ℕ) : ℝ) * ℓ) + 4 * ℓ ^ 2 * v' (((e + 1 : ℕ) : ℝ) * ℓ)) =
          m * ℓ * P := by
        simp only [hvf, hv'f]; push_cast; rw [hnR]; field_simp; ring
      have d1 : EI / ℓ ^ 3 * (12 * (U (2 * e + 2) - v (((e + 1 : ℕ) : ℝ) * ℓ))
          - 6 * ℓ * (U (2 * e + 3) - v' (((e + 1 : ℕ) : ℝ) * ℓ))) = 0 := by
        linear_combination f1 - x1
      have d2 : EI / ℓ ^ 3 * (-6 * ℓ * (U (2 * e + 2) - v (((e + 1 : ℕ) : ℝ) * ℓ))
          + 4 * ℓ ^ 2 * (U (2 * e + 3) - v' (((e + 1 : ℕ) : ℝ) * ℓ))) = 0 := by
        linear_combination f2 - x2
      have d1' := (mul_eq_zero.1 d1).resolve_left hc
      have d2' := (mul_eq_zero.1 d2).resolve_left hc
      have hq2 : ℓ ^ 2 * (U (2 * e + 3) - v' (((e + 1 : ℕ) : ℝ) * ℓ)) = 0 := by
        linear_combination (ℓ / 2) * d1' + d2'
      have hq := (mul_eq_zero.1 hq2).resolve_left (pow_ne_zero 2 hl)
      have hp : U (2 * e + 2) - v (((e + 1 : ℕ) : ℝ) * ℓ) = 0 := by
        linear_combination d1' / 12 + ℓ / 2 * hq
      rw [show 2 * (e + 1) = 2 * e + 2 by ring, show 2 * e + 2 + 1 = 2 * e + 3 by ring]
      constructor
      · linear_combination hp
      · linear_combination hq
  · intro h k hk
    obtain ⟨a0, a1⟩ := h k hk.le
    obtain ⟨b0, b1⟩ := h (k + 1) hk
    simp only [show 2 * (k + 1) = 2 * k + 2 by ring, show 2 * k + 2 + 1 = 2 * k + 3 by ring] at b0 b1
    rw [(hrow k hk).1, (hrow k hk).2]
    by_cases hk1 : k + 1 < n
    · obtain ⟨c0, c1⟩ := h (k + 2) hk1
      simp only [show 2 * (k + 2) = 2 * k + 4 by ring, show 2 * k + 4 + 1 = 2 * k + 5 by ring]
        at c0 c1
      rw [if_pos hk1, if_pos hk1, if_neg (by omega), a0, a1, b0, b1, c0, c1]
      simp only [hvf, hv'f]
      push_cast
      constructor <;> field_simp <;> ring
    · have hnk : n = k + 1 := by omega
      rw [if_neg hk1, if_neg hk1, if_pos (by omega), a0, a1, b0, b1]
      have hnR : (n : ℝ) = k + 1 := by rw [hnk]; push_cast; ring
      simp only [hvf, hv'f]
      push_cast
      rw [hnR]
      constructor <;> field_simp <;> ring

/-- Step 2: the element stiffness matrix comes from the stored energy. Entry `(i, j)` of `k`
is `∫₀^ℓ EI Nᵢ'' Nⱼ'' dx`, for every element length `ℓ > 0`. -/
theorem element_stiffness_eq_energy_integral (EI ℓ : ℝ) (hℓ : 0 < ℓ) (i j : Fin 4) :
    ∫ x in (0 : ℝ)..ℓ, EI * deriv (deriv (shapeFn ℓ i)) x * deriv (deriv (shapeFn ℓ j)) x =
      kElem EI ℓ i j := by
  have hl : ℓ ≠ 0 := hℓ.ne'
  have h0 : deriv (deriv (shapeFn ℓ 0)) = fun x => -6 / ℓ ^ 2 + 12 / ℓ ^ 3 * x := by
    have : shapeFn ℓ 0 = fun x : ℝ => 1 + 0 * x + (-3 / ℓ ^ 2) * x ^ 2 + (2 / ℓ ^ 3) * x ^ 3 := by
      funext x; simp only [shapeFn]; field_simp; ring
    rw [this, cubic_dd]; funext x; ring
  have h1 : deriv (deriv (shapeFn ℓ 1)) = fun x => -4 / ℓ + 6 / ℓ ^ 2 * x := by
    have : shapeFn ℓ 1 = fun x : ℝ => 0 + 1 * x + (-2 / ℓ) * x ^ 2 + (1 / ℓ ^ 2) * x ^ 3 := by
      funext x; simp only [shapeFn]; field_simp; ring
    rw [this, cubic_dd]; funext x; ring
  have h2 : deriv (deriv (shapeFn ℓ 2)) = fun x => 6 / ℓ ^ 2 + -12 / ℓ ^ 3 * x := by
    have : shapeFn ℓ 2 = fun x : ℝ => 0 + 0 * x + (3 / ℓ ^ 2) * x ^ 2 + (-2 / ℓ ^ 3) * x ^ 3 := by
      funext x; simp only [shapeFn]; field_simp; ring
    rw [this, cubic_dd]; funext x; ring
  have h3 : deriv (deriv (shapeFn ℓ 3)) = fun x => -2 / ℓ + 6 / ℓ ^ 2 * x := by
    have : shapeFn ℓ 3 = fun x : ℝ => 0 + 0 * x + (-1 / ℓ) * x ^ 2 + (1 / ℓ ^ 2) * x ^ 3 := by
      funext x; simp only [shapeFn]; field_simp; ring
    rw [this, cubic_dd]; funext x; ring
  have hs : ∀ i, deriv (deriv (shapeFn ℓ i)) = fun x =>
      ![-6 / ℓ ^ 2, -4 / ℓ, 6 / ℓ ^ 2, -2 / ℓ] i + ![12 / ℓ ^ 3, 6 / ℓ ^ 2, -12 / ℓ ^ 3, 6 / ℓ ^ 2] i * x := by
    intro i
    fin_cases i
    · exact h0
    · exact h1
    · exact h2
    · exact h3
  rw [hs i, hs j]
  rw [show (fun x => EI * (![-6 / ℓ ^ 2, -4 / ℓ, 6 / ℓ ^ 2, -2 / ℓ] i + ![12 / ℓ ^ 3, 6 / ℓ ^ 2, -12 / ℓ ^ 3, 6 / ℓ ^ 2] i * x) * (![-6 / ℓ ^ 2, -4 / ℓ, 6 / ℓ ^ 2, -2 / ℓ] j + ![12 / ℓ ^ 3, 6 / ℓ ^ 2, -12 / ℓ ^ 3, 6 / ℓ ^ 2] j * x)) = _ from rfl]
  rw [lin_integral]
  fin_cases i <;> fin_cases j <;> simp [kElem] <;> field_simp <;> ring

/-- Step 4: without supports, `K` times a rigid lift (every node drops 1, no node turns) is
zero, and `K` times a rigid turn (node `i` drops `i ℓ`, every node turns 1) is zero, so no
force resists either movement and `K` has no inverse: its determinant is 0. -/
theorem unsupported_stiffness_singular (n : ℕ) (EI ℓ : ℝ) :
    Kfull n EI ℓ *ᵥ (fun a => if (a : ℕ) % 2 = 0 then 1 else 0) = 0 ∧
    Kfull n EI ℓ *ᵥ (fun a => if (a : ℕ) % 2 = 0 then ((a : ℕ) / 2 : ℕ) * ℓ else 1) = 0 ∧
    (Kfull n EI ℓ).det = 0 := by
  have key : ∀ W : ℕ → ℝ, (∀ e (i : Fin 4),
      kElem EI ℓ i 0 * W (2 * e) + kElem EI ℓ i 1 * W (2 * e + 1) +
      kElem EI ℓ i 2 * W (2 * e + 2) + kElem EI ℓ i 3 * W (2 * e + 3) = 0) →
      Kfull n EI ℓ *ᵥ (fun b => W b) = 0 := by
    intro W hW
    funext a
    rw [Kfull_mulVec]
    simp only [Pi.zero_apply]
    refine Finset.sum_eq_zero fun e _ => ?_
    by_cases h : 2 * e ≤ (a : ℕ) ∧ (a : ℕ) < 2 * e + 4
    · obtain ⟨i, hi⟩ : ∃ i, (a : ℕ) = 2 * e + i := ⟨a - 2 * e, by omega⟩
      have hi4 : i < 4 := by omega
      have q0 := elemEntry_loc EI ℓ e i 0 hi4 (by norm_num)
      rw [add_zero] at q0
      rw [hi, q0, elemEntry_loc EI ℓ e i 1 hi4 (by norm_num),
        elemEntry_loc EI ℓ e i 2 hi4 (by norm_num), elemEntry_loc EI ℓ e i 3 hi4 (by norm_num)]
      exact hW e ⟨i, hi4⟩
    · simp [elemEntry_out _ _ _ _ _ h]
  have hlift := key (fun b => if b % 2 = 0 then 1 else 0) (by
    intro e i
    have a1 : (2 * e + 1) % 2 = 1 := by omega
    have a2 : (2 * e + 2) % 2 = 0 := by omega
    have a3 : (2 * e + 3) % 2 = 1 := by omega
    simp only [a1, a2, a3, Nat.mul_mod_right]
    fin_cases i <;> simp [kElem] <;> ring)
  have hturn := key (fun b => if b % 2 = 0 then ((b / 2 : ℕ) : ℝ) * ℓ else 1) (by
    intro e i
    have a1 : (2 * e + 1) % 2 = 1 := by omega
    have a2 : (2 * e + 2) % 2 = 0 := by omega
    have a3 : (2 * e + 3) % 2 = 1 := by omega
    have b0 : 2 * e / 2 = e := by omega
    have b2 : (2 * e + 2) / 2 = e + 1 := by omega
    simp only [a1, a2, a3, Nat.mul_mod_right, b0, b2]
    fin_cases i <;> simp [kElem] <;> push_cast <;> ring)
  refine ⟨hlift, hturn, ?_⟩
  rw [← Matrix.exists_mulVec_eq_zero_iff]
  refine ⟨_, ?_, hlift⟩
  intro h
  have := congrFun h ⟨0, by omega⟩
  simp at this

end FEBeam

open FEBeam Matrix

/-- One entry by hand: `k₁₁ = (EI/ℓ³) ∫₀¹ (12s - 6)² ds = 12 EI/ℓ³`. -/
example : ∫ s in (0 : ℝ)..1, (12 * s - 6) ^ 2 = 12 := by
  have : (fun s : ℝ => (12 * s - 6) ^ 2) = fun s => 144 * s ^ 2 - 144 * s + 36 := by
    funext s; ring
  rw [this, intervalIntegral.integral_add, intervalIntegral.integral_sub,
    intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul]
  · norm_num [integral_pow]
  all_goals first
    | exact (continuous_const.mul (continuous_pow 2)).intervalIntegrable _ _
    | exact (continuous_const.mul continuous_id).intervalIntegrable _ _
    | exact ((continuous_const.mul (continuous_pow 2)).sub
        (continuous_const.mul continuous_id)).intervalIntegrable _ _
    | exact intervalIntegrable_const

/-- Node 1 is shared by elements 1 and 2: drop entry `12 + 12`, turn entry `4 + 4`,
coupling `-6 + 6`. -/
example : (12 + 12 : ℤ) = 24 ∧ (4 + 4 : ℤ) = 8 ∧ (-6 + 6 : ℤ) = 0 := by norm_num

/-- The six free rows of `K` for three 1 m elements, in units of `EI/ℓ³`. -/
example : Kfree 3 1 1 = !![24, 0, -12, 6, 0, 0;
                           0, 8, -6, 2, 0, 0;
                           -12, -6, 24, 0, -12, 6;
                           6, 2, 0, 8, -6, 2;
                           0, 0, -12, -6, 12, -6;
                           0, 0, 6, 2, -6, 4] := by
  ext i j
  fin_cases i <;> fin_cases j <;> simp [Kfree, elemEntry, kElem, Finset.sum_range_succ] <;> norm_num

/-- The solve, in units of `P ℓ³ / EI`: `u = (4/3, 5/2, 14/3, 4, 9, 9/2)` gives `K u = F`;
the tip drops 9 units, which is `P L³ / 3EI` with `L = 3ℓ`. -/
example : Kfree 3 1 1 *ᵥ ![4/3, 5/2, 14/3, 4, 9, 9/2] = tipLoad 3 1 := by
  ext i
  fin_cases i <;>
    simp [Kfree, elemEntry, kElem, Finset.sum_range_succ, tipLoad, mulVec, dotProduct,
      Fin.sum_univ_succ] <;> norm_num

/-- Check rows 1 and 5 by hand: `32 - 56 + 24 = 0` and `-56 - 24 + 108 - 27 = 1`. -/
example : (24 * (4/3) - 12 * (14/3) + 6 * 4 : ℚ) = 0 ∧
    (-12 * (14/3) - 6 * 4 + 12 * 9 - 6 * (9/2) : ℚ) = 1 ∧ (3 : ℚ) ^ 3 / 3 = 9 := by
  norm_num

#print axioms cantilever_tip_load_fem_exact_at_nodes
#print axioms element_stiffness_eq_energy_integral
#print axioms unsupported_stiffness_singular
