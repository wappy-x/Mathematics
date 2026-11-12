-- Conjugate gradient: on a symmetric positive definite matrix, in exact arithmetic, the method's directions are mutually conjugate and it reaches the bottom of the bowl, where A x = b, within n steps.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.Tactic.NormNum

open Matrix

set_option linter.unusedSimpArgs false

namespace ConjugateGradient

variable {n : ℕ} {K : Type*} [Field K]

/-- The cost (the bowl) `f(x) = 1/2 xᵀ A x - bᵀ x`. -/
def cost (A : Matrix (Fin n) (Fin n) K) (b x : Fin n → K) : K :=
  (1 / 2 : K) * (x ⬝ᵥ (A *ᵥ x)) - b ⬝ᵥ x

/-- What the method holds after each step: the guess `x`, the residual `r`, the direction `d`. -/
structure State (n : ℕ) (K : Type*) where
  x : Fin n → K
  r : Fin n → K
  d : Fin n → K

/-- The start: `r₀ = d₀ = b - A x₀`. -/
def init (A : Matrix (Fin n) (Fin n) K) (b x₀ : Fin n → K) : State n K :=
  ⟨x₀, b - A *ᵥ x₀, b - A *ᵥ x₀⟩

/-- One step of the card's formula:
`α = rᵀr / dᵀAd`, `x' = x + α d`, `r' = r - α A d`, `β = r'ᵀr' / rᵀr`, `d' = r' + β d`.
(Once the residual is zero, Lean's `0 / 0 = 0` keeps the method standing still: it has stopped.) -/
def step (A : Matrix (Fin n) (Fin n) K) (s : State n K) : State n K :=
  let α := (s.r ⬝ᵥ s.r) / (s.d ⬝ᵥ (A *ᵥ s.d))
  let r' := s.r - α • (A *ᵥ s.d)
  let β := (r' ⬝ᵥ r') / (s.r ⬝ᵥ s.r)
  ⟨s.x + α • s.d, r', r' + β • s.d⟩

/-- The state after `k` steps of conjugate gradient from `x₀`. -/
def cg (A : Matrix (Fin n) (Fin n) K) (b x₀ : Fin n → K) (k : ℕ) : State n K :=
  (step A)^[k] (init A b x₀)

lemma dot_mulVec_symm {A : Matrix (Fin n) (Fin n) ℝ} (hA : A.IsHermitian) (u v : Fin n → ℝ) :
    u ⬝ᵥ (A *ᵥ v) = v ⬝ᵥ (A *ᵥ u) := by
  have hT : Aᵀ = A := by
    have := hA.eq
    rwa [conjTranspose_eq_transpose_of_trivial] at this
  rw [dotProduct_mulVec, ← mulVec_transpose, hT, dotProduct_comm]

lemma quad_pos {A : Matrix (Fin n) (Fin n) ℝ} (hA : A.PosDef) {v : Fin n → ℝ} (hv : v ≠ 0) :
    0 < v ⬝ᵥ (A *ᵥ v) := by
  simpa using hA.dotProduct_mulVec_pos hv

lemma self_dot_ne {v : Fin n → ℝ} (hv : v ≠ 0) : v ⬝ᵥ v ≠ 0 :=
  fun h => hv (dotProduct_self_eq_zero.mp h)

lemma cg_succ (A : Matrix (Fin n) (Fin n) K) (b x₀ : Fin n → K) (k : ℕ) :
    cg A b x₀ (k + 1) = step A (cg A b x₀ k) := by
  simp only [cg]; rw [Function.iterate_succ_apply']

/-- The core invariant of conjugate gradient, for any sequences obeying its update rules. -/
lemma cg_inv {A : Matrix (Fin n) (Fin n) ℝ} (hA : A.PosDef) (r d : ℕ → Fin n → ℝ)
    (hd0 : d 0 = r 0)
    (hr : ∀ k, r (k + 1) = r k - (r k ⬝ᵥ r k / (d k ⬝ᵥ (A *ᵥ d k))) • (A *ᵥ d k))
    (hd : ∀ k, d (k + 1) = r (k + 1) + (r (k + 1) ⬝ᵥ r (k + 1) / (r k ⬝ᵥ r k)) • d k)
    (k : ℕ) :
    ∀ j ≤ k, ∀ i < j, r j ⬝ᵥ d i = 0 ∧ r j ⬝ᵥ r i = 0 ∧ d j ⬝ᵥ (A *ᵥ d i) = 0 := by
  have hsym := dot_mulVec_symm hA.1
  have dz : ∀ m, r m = 0 → d m = 0 := by
    intro m h
    cases m with
    | zero => rw [hd0, h]
    | succ m => rw [hd m, h]; simp
  have key : ∀ m, (r m ⬝ᵥ r m / (d m ⬝ᵥ (A *ᵥ d m))) • (A *ᵥ d m) = r m - r (m + 1) := by
    intro m; rw [hr m]; abel
  induction k with
  | zero => intro j hj i hi; omega
  | succ k ih =>
    intro j hj i hij
    rcases Nat.lt_or_ge j (k + 1) with h | h
    · exact ih j (by omega) i hij
    obtain rfl : j = k + 1 := by omega
    have rd : r k ⬝ᵥ d k = r k ⬝ᵥ r k := by
      cases k with
      | zero => rw [hd0]
      | succ m =>
        rw [hd m, dotProduct_add, dotProduct_smul, (ih (m + 1) le_rfl m (by omega)).1,
          smul_zero, add_zero]
    have P1 : ∀ i < k + 1, r (k + 1) ⬝ᵥ d i = 0 := by
      intro i hi
      rw [hr k, sub_dotProduct, smul_dotProduct, smul_eq_mul]
      rcases Nat.lt_or_ge i k with hik | hik
      · rw [(ih k le_rfl i hik).1, dotProduct_comm (A *ᵥ d k), hsym (d i) (d k),
          (ih k le_rfl i hik).2.2]
        ring
      · obtain rfl : i = k := by omega
        by_cases h0 : d i = 0
        · simp [h0]
        · rw [rd, dotProduct_comm (A *ᵥ d i), div_mul_cancel₀ _ (quad_pos hA h0).ne', sub_self]
    have P2 : ∀ i < k + 1, r (k + 1) ⬝ᵥ r i = 0 := by
      intro i hi
      cases i with
      | zero => rw [← hd0]; exact P1 0 hi
      | succ m =>
        have e : r (m + 1) = d (m + 1) - (r (m + 1) ⬝ᵥ r (m + 1) / (r m ⬝ᵥ r m)) • d m := by
          rw [hd m]; abel
        rw [e, dotProduct_sub, dotProduct_smul, P1 (m + 1) hi, P1 m (by omega)]
        simp
    refine ⟨P1 i hij, P2 i hij, ?_⟩
    rw [hd k, add_dotProduct, smul_dotProduct, smul_eq_mul]
    by_cases h0 : d i = 0
    · simp [h0]
    have hrne : r i ≠ 0 := fun h => h0 (dz i h)
    have hq := (quad_pos hA h0).ne'
    have hrr := self_dot_ne hrne
    have hα : r i ⬝ᵥ r i / (d i ⬝ᵥ (A *ᵥ d i)) ≠ 0 := div_ne_zero hrr hq
    have hrA : r (k + 1) ⬝ᵥ (A *ᵥ d i) * (r i ⬝ᵥ r i / (d i ⬝ᵥ (A *ᵥ d i))) =
        r (k + 1) ⬝ᵥ r i - r (k + 1) ⬝ᵥ r (i + 1) := by
      rw [← dotProduct_sub, ← key i, dotProduct_smul, smul_eq_mul, mul_comm]
    rcases Nat.lt_or_ge i k with hik | hik
    · rw [(ih k le_rfl i hik).2.2, mul_zero, add_zero]
      have : r (k + 1) ⬝ᵥ (A *ᵥ d i) * (r i ⬝ᵥ r i / (d i ⬝ᵥ (A *ᵥ d i))) = 0 := by
        rw [hrA, P2 i hij, P2 (i + 1) (by omega)]; simp
      exact (mul_eq_zero.mp this).resolve_right hα
    · obtain rfl : i = k := by omega
      rw [P2 i hij, zero_sub] at hrA
      have e : r (i + 1) ⬝ᵥ (A *ᵥ d i) =
          (r (i + 1) ⬝ᵥ (A *ᵥ d i) * (r i ⬝ᵥ r i / (d i ⬝ᵥ (A *ᵥ d i)))) *
            ((d i ⬝ᵥ (A *ᵥ d i)) / (r i ⬝ᵥ r i)) := by
        field_simp
      rw [e, hrA]
      field_simp
      ring

/-- The residual stays `b - A x`. -/
lemma cg_r_eq (A : Matrix (Fin n) (Fin n) ℝ) (b x₀ : Fin n → ℝ) (k : ℕ) :
    (cg A b x₀ k).r = b - A *ᵥ (cg A b x₀ k).x := by
  induction k with
  | zero => rfl
  | succ k ih =>
    rw [cg_succ]
    simp only [step]
    rw [ih, mulVec_add, mulVec_smul]
    abel

/-- `cg_inv` applied to the actual iterates. -/
lemma cg_inv' {A : Matrix (Fin n) (Fin n) ℝ} (hA : A.PosDef) (b x₀ : Fin n → ℝ) (k : ℕ) :
    ∀ j ≤ k, ∀ i < j, (cg A b x₀ j).r ⬝ᵥ (cg A b x₀ i).d = 0 ∧
      (cg A b x₀ j).r ⬝ᵥ (cg A b x₀ i).r = 0 ∧
      (cg A b x₀ j).d ⬝ᵥ (A *ᵥ (cg A b x₀ i).d) = 0 :=
  cg_inv hA (fun m => (cg A b x₀ m).r) (fun m => (cg A b x₀ m).d) rfl
    (fun k => by rw [cg_succ]; rfl)
    (fun k => by rw [cg_succ]; rfl) k

/-- Once the residual is zero it stays zero. -/
lemma cg_r_zero_succ (A : Matrix (Fin n) (Fin n) ℝ) (b x₀ : Fin n → ℝ) (k : ℕ)
    (h : (cg A b x₀ k).r = 0) : (cg A b x₀ (k + 1)).r = 0 := by
  have hd : (cg A b x₀ k).d = 0 := by
    cases k with
    | zero => exact h
    | succ m =>
      have e : (cg A b x₀ (m + 1)).d = (cg A b x₀ (m + 1)).r +
          ((cg A b x₀ (m + 1)).r ⬝ᵥ (cg A b x₀ (m + 1)).r /
            ((cg A b x₀ m).r ⬝ᵥ (cg A b x₀ m).r)) • (cg A b x₀ m).d := by
        rw [cg_succ]; rfl
      rw [e, h]; simp
  rw [cg_succ]
  simp only [step]
  rw [h, hd]; simp

lemma cg_r_n_zero {A : Matrix (Fin n) (Fin n) ℝ} (hA : A.PosDef) (b x₀ : Fin n → ℝ) :
    (cg A b x₀ n).r = 0 := by
  by_contra hn
  have hne : ∀ i ≤ n, (cg A b x₀ i).r ≠ 0 := by
    intro i hi h
    apply hn
    have stay : ∀ m, (cg A b x₀ (i + m)).r = 0 := by
      intro m
      induction m with
      | zero => exact h
      | succ m ih => exact cg_r_zero_succ A b x₀ _ ih
    have := stay (n - i)
    rwa [Nat.add_sub_cancel' hi] at this
  let v : Fin (n + 1) → (Fin n → ℝ) := fun i => (cg A b x₀ i).r
  have orth : ∀ i j : Fin (n + 1), i ≠ j → v i ⬝ᵥ v j = 0 := by
    intro i j hij
    rcases lt_or_gt_of_ne hij with h | h
    · rw [dotProduct_comm]
      exact (cg_inv' hA b x₀ n j (by omega) i h).2.1
    · exact (cg_inv' hA b x₀ n i (by omega) j h).2.1
  have hli : LinearIndependent ℝ v := by
    rw [Fintype.linearIndependent_iff]
    intro g hg i
    have h1 : (∑ j, g j • v j) ⬝ᵥ v i = 0 := by rw [hg, zero_dotProduct]
    rw [sum_dotProduct, Finset.sum_eq_single i] at h1
    · rw [smul_dotProduct, smul_eq_mul] at h1
      exact (mul_eq_zero.mp h1).resolve_right (self_dot_ne (hne i (by omega)))
    · intro j _ hji
      rw [smul_dotProduct, orth j i hji, smul_zero]
    · intro hi; exact absurd (Finset.mem_univ i) hi
  have := hli.fintype_card_le_finrank
  simp at this

lemma cost_le_of_solves {A : Matrix (Fin n) (Fin n) ℝ} (hA : A.PosDef) (b x : Fin n → ℝ)
    (hx : A *ᵥ x = b) (y : Fin n → ℝ) : cost A b x ≤ cost A b y := by
  obtain ⟨z, rfl⟩ : ∃ z, y = x + z := ⟨y - x, by abel⟩
  have hz : 0 ≤ z ⬝ᵥ (A *ᵥ z) := by
    by_cases h : z = 0
    · simp [h]
    · exact (quad_pos hA h).le
  have hs := dot_mulVec_symm hA.1 x z
  subst hx
  simp only [cost, mulVec_add, dotProduct_add, add_dotProduct]
  rw [dotProduct_comm (A *ᵥ x) x, dotProduct_comm (A *ᵥ x) z, hs]
  nlinarith

#print axioms dot_mulVec_symm
#print axioms quad_pos
#print axioms self_dot_ne
#print axioms cg_succ
#print axioms cg_inv
#print axioms cg_r_eq
#print axioms cg_inv'
#print axioms cg_r_zero_succ
#print axioms cg_r_n_zero
#print axioms cost_le_of_solves

/-- Conjugate gradient finishes within n steps: for a symmetric positive definite matrix `A`
(`Matrix.PosDef` includes symmetry), in exact arithmetic, after `n` steps the guess solves
`A x = b`, and it is the lowest point of the bowl `f(x) = 1/2 xᵀAx - bᵀx`. -/
theorem cg_reaches_bottom_within_n_steps (A : Matrix (Fin n) (Fin n) ℝ) (hA : A.PosDef)
    (b x₀ : Fin n → ℝ) :
    A *ᵥ (cg A b x₀ n).x = b ∧ ∀ y : Fin n → ℝ, cost A b (cg A b x₀ n).x ≤ cost A b y := by
  have hr := cg_r_n_zero hA b x₀
  rw [cg_r_eq, sub_eq_zero] at hr
  exact ⟨hr.symm, cost_le_of_solves hA b _ hr.symm⟩

/-- Every direction is conjugate to every earlier one: `d_kᵀ A d_j = 0` for `j < k`. -/
theorem cg_directions_conjugate (A : Matrix (Fin n) (Fin n) ℝ) (hA : A.PosDef)
    (b x₀ : Fin n → ℝ) {j k : ℕ} (hjk : j < k) :
    (cg A b x₀ k).d ⬝ᵥ (A *ᵥ (cg A b x₀ j).d) = 0 := by
  exact (cg_inv' hA b x₀ k k le_rfl j hjk).2.2

/-- Every residual (downhill slope) is perpendicular to every earlier one: `r_kᵀ r_j = 0` for `j < k`. -/
theorem cg_residuals_orthogonal (A : Matrix (Fin n) (Fin n) ℝ) (hA : A.PosDef)
    (b x₀ : Fin n → ℝ) {j k : ℕ} (hjk : j < k) :
    (cg A b x₀ k).r ⬝ᵥ (cg A b x₀ j).r = 0 := by
  exact (cg_inv' hA b x₀ k k le_rfl j hjk).2.1

/-! The card's worked numbers: readings 18 and 15, weight 1, start (15, 15). -/

/-- The two-reading bowl, `A = [[2, -1], [-1, 2]]`. -/
def A₂ : Matrix (Fin 2) (Fin 2) ℝ := !![2, -1; -1, 2]

-- first move: alpha 1/2 to (16.5, 15); new residual (0, 1.5); beta 1/4, new direction (0.75, 1.5)
example : cg A₂ ![18, 15] ![15, 15] 1 = ⟨![33 / 2, 15], ![0, 3 / 2], ![3 / 4, 3 / 2]⟩ := by
  simp only [cg, Function.iterate_one, step, init, A₂, State.mk.injEq]
  refine ⟨?_, ?_, ?_⟩ <;> ext i <;> fin_cases i <;>
    simp [mulVec, dotProduct, Fin.sum_univ_two, vecHead, vecTail] <;> norm_num

-- second move: alpha 2/3 lands on the bottom (17, 16) exactly; residual and direction become 0
example : step A₂ ⟨![33 / 2, 15], ![0, 3 / 2], ![3 / 4, 3 / 2]⟩ = ⟨![17, 16], 0, 0⟩ := by
  simp only [step, A₂, State.mk.injEq]
  refine ⟨?_, ?_, ?_⟩ <;> ext i <;> fin_cases i <;>
    simp [mulVec, dotProduct, Fin.sum_univ_two, vecHead, vecTail] <;> norm_num

-- the two directions are conjugate: d₁ᵀ A d₀ = 0, with d₀ = (3, 0) and d₁ = (0.75, 1.5)
example : (cg A₂ ![18, 15] ![15, 15] 0).d = ![3, 0] ∧
    ![3 / 4, 3 / 2] ⬝ᵥ (A₂ *ᵥ ![3, 0]) = (0 : ℝ) := by
  refine ⟨?_, ?_⟩
  · ext i; fin_cases i <;>
      simp [cg, init, A₂, mulVec, dotProduct, Fin.sum_univ_two, vecHead, vecTail] <;> norm_num
  · simp [A₂, mulVec, dotProduct, Fin.sum_univ_two, vecHead, vecTail]; norm_num

-- the start sits 3 above the bottom's cost
example : cost A₂ ![18, 15] ![15, 15] - cost A₂ ![18, 15] ![17, 16] = 3 := by
  simp [cost, A₂, mulVec, dotProduct, Fin.sum_univ_two, vecHead, vecTail]; norm_num

/-! What breaks: the saddle `[[1, 2], [2, 1]]`, `b = (3, 0)`, start (0, 0). -/

/-- A symmetric matrix that is not positive definite. -/
def Asad : Matrix (Fin 2) (Fin 2) ℝ := !![1, 2; 2, 1]

-- first move: to (3, 0), residual (0, -6), next direction (12, -6)
example : cg Asad ![3, 0] 0 1 = ⟨![3, 0], ![0, -6], ![12, -6]⟩ := by
  simp only [cg, Function.iterate_one, step, init, Asad, State.mk.injEq]
  refine ⟨?_, ?_, ?_⟩ <;> ext i <;> fin_cases i <;>
    simp [mulVec, dotProduct, Fin.sum_univ_two, vecHead, vecTail] <;> norm_num

-- the second direction curves down: d₁ᵀ A d₁ = -108
example : ![12, -6] ⬝ᵥ (Asad *ᵥ ![12, -6]) = (-108 : ℝ) := by
  simp [Asad, mulVec, dotProduct, Fin.sum_univ_two, vecHead, vecTail]; norm_num

-- second move: it stops at (-1, 2) with residual 0, so A x = b is solved ...
example : step Asad ⟨![3, 0], ![0, -6], ![12, -6]⟩ = ⟨![-1, 2], 0, 0⟩ := by
  simp only [step, Asad, State.mk.injEq]
  refine ⟨?_, ?_, ?_⟩ <;> ext i <;> fin_cases i <;>
    simp [mulVec, dotProduct, Fin.sum_univ_two, vecHead, vecTail] <;> norm_num

-- ... but its cost is 3/2, above the start's 0, while the cost at (10, -10) is -130
example : cost Asad ![3, 0] ![-1, 2] = 3 / 2 ∧ cost Asad ![3, 0] 0 = 0 ∧
    cost Asad ![3, 0] ![10, -10] = -130 := by
  refine ⟨?_, ?_, ?_⟩ <;> simp [cost, Asad, mulVec, dotProduct, Fin.sum_univ_two, vecHead, vecTail] <;>
    norm_num

#print axioms cg_reaches_bottom_within_n_steps
#print axioms cg_directions_conjugate
#print axioms cg_residuals_orthogonal

end ConjugateGradient
