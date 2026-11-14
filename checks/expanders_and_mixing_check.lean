-- Expanders: on every connected network where each station has the same number d of links, the cheapest cut per station cut off lies between half the spectral gap and the square root of 2d times the gap, the lazy walk is within a quarter of an even spread after (2d / gap) ln(2 sqrt n) steps, and the card's 10-station pilot has gap 2 and cheapest cut 1 per station.
import Mathlib.Combinatorics.SimpleGraph.LapMatrix
import Mathlib.Analysis.Matrix.Spectrum
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Algebra.Order.Chebyshev
import Mathlib.Analysis.Matrix.PosDef

namespace ExpandersAndMixing

open Matrix Finset

variable {V : Type*} [Fintype V] [DecidableEq V]

/-- `|∂S|`: the number of links with one end in `S` and the other outside `S`.
Each such link is counted once, as the ordered pair (end inside, end outside). -/
def edgeBoundary (G : SimpleGraph V) [DecidableRel G.Adj] (S : Finset V) : ℕ :=
  ((S ×ˢ Sᶜ).filter fun p : V × V => G.Adj p.1 p.2).card

/-- The lazy walk's table of chances, `P = ½ I + (1 / 2d) A`: stay put with chance `1/2`,
otherwise ride one of the `d` links, each with the same chance. -/
noncomputable def lazyWalk (G : SimpleGraph V) [DecidableRel G.Adj] (d : ℕ) : Matrix V V ℝ :=
  (1 / 2 : ℝ) • (1 : Matrix V V ℝ) + (1 / (2 * d : ℝ)) • G.adjMatrix ℝ

/-! ## Helper lemmas -/

theorem spec_U {M : Matrix V V ℝ} (hM : M.IsHermitian) :
    M = (hM.eigenvectorUnitary : Matrix V V ℝ) * diagonal hM.eigenvalues *
      (hM.eigenvectorUnitary : Matrix V V ℝ)ᵀ := by
  conv_lhs => rw [hM.spectral_theorem]
  rw [Unitary.conjStarAlgAut_apply]
  simp [Matrix.star_eq_conjTranspose, conjTranspose_eq_transpose_of_trivial]

theorem UtU {M : Matrix V V ℝ} (hM : M.IsHermitian) :
    (hM.eigenvectorUnitary : Matrix V V ℝ)ᵀ * (hM.eigenvectorUnitary : Matrix V V ℝ) = 1 := by
  have := Unitary.coe_star_mul_self hM.eigenvectorUnitary
  simpa [Matrix.star_eq_conjTranspose, conjTranspose_eq_transpose_of_trivial] using this

theorem UUt {M : Matrix V V ℝ} (hM : M.IsHermitian) :
    (hM.eigenvectorUnitary : Matrix V V ℝ) * (hM.eigenvectorUnitary : Matrix V V ℝ)ᵀ = 1 := by
  have := Unitary.coe_mul_star_self hM.eigenvectorUnitary
  simpa [Matrix.star_eq_conjTranspose, conjTranspose_eq_transpose_of_trivial] using this

theorem MU {M : Matrix V V ℝ} (hM : M.IsHermitian) :
    M * (hM.eigenvectorUnitary : Matrix V V ℝ) =
      (hM.eigenvectorUnitary : Matrix V V ℝ) * diagonal hM.eigenvalues := by
  have h := congrArg (· * (hM.eigenvectorUnitary : Matrix V V ℝ)) (spec_U hM)
  rw [h, Matrix.mul_assoc, UtU hM, Matrix.mul_one]

theorem col_eigen {M : Matrix V V ℝ} (hM : M.IsHermitian) (k : V) :
    M *ᵥ (fun v => (hM.eigenvectorUnitary : Matrix V V ℝ) v k) =
      fun v => hM.eigenvalues k * (hM.eigenvectorUnitary : Matrix V V ℝ) v k := by
  funext v
  have := congrFun (congrFun (MU hM) v) k
  rw [Matrix.mul_apply, Matrix.mul_diagonal] at this
  rw [Matrix.mulVec, dotProduct, this, mul_comm]

theorem col_orth {M : Matrix V V ℝ} (hM : M.IsHermitian) (k l : V) :
    ∑ v, (hM.eigenvectorUnitary : Matrix V V ℝ) v k * (hM.eigenvectorUnitary : Matrix V V ℝ) v l =
      if k = l then 1 else 0 := by
  have := congrFun (congrFun (UtU hM) k) l
  rw [Matrix.mul_apply, Matrix.one_apply] at this
  simpa [Matrix.transpose_apply] using this

theorem row_orth {M : Matrix V V ℝ} (hM : M.IsHermitian) (u v : V) :
    ∑ k, (hM.eigenvectorUnitary : Matrix V V ℝ) u k * (hM.eigenvectorUnitary : Matrix V V ℝ) v k =
      if u = v then 1 else 0 := by
  have := congrFun (congrFun (UUt hM) u) v
  rw [Matrix.mul_apply, Matrix.one_apply] at this
  simpa [Matrix.transpose_apply] using this

theorem dot_U {M : Matrix V V ℝ} (hM : M.IsHermitian) (x z : V → ℝ) :
    x ⬝ᵥ ((hM.eigenvectorUnitary : Matrix V V ℝ) *ᵥ z) =
      ((hM.eigenvectorUnitary : Matrix V V ℝ)ᵀ *ᵥ x) ⬝ᵥ z := by
  rw [dotProduct_mulVec, mulVec_transpose]

theorem quad_U {M : Matrix V V ℝ} (hM : M.IsHermitian) (x : V → ℝ) :
    x ⬝ᵥ (M *ᵥ x) = ∑ k, hM.eigenvalues k *
      ((hM.eigenvectorUnitary : Matrix V V ℝ)ᵀ *ᵥ x) k ^ 2 := by
  conv_lhs => rw [spec_U hM, ← mulVec_mulVec, ← mulVec_mulVec, dot_U hM]
  simp only [dotProduct, mulVec_diagonal]
  refine Finset.sum_congr rfl fun k _ => by ring

theorem norm_U {M : Matrix V V ℝ} (hM : M.IsHermitian) (x : V → ℝ) :
    x ⬝ᵥ x = ∑ k, ((hM.eigenvectorUnitary : Matrix V V ℝ)ᵀ *ᵥ x) k ^ 2 := by
  have h : ((hM.eigenvectorUnitary : Matrix V V ℝ) * (hM.eigenvectorUnitary : Matrix V V ℝ)ᵀ) *ᵥ x = x := by
    rw [UUt hM, one_mulVec]
  calc x ⬝ᵥ x = x ⬝ᵥ (((hM.eigenvectorUnitary : Matrix V V ℝ) *
        (hM.eigenvectorUnitary : Matrix V V ℝ)ᵀ) *ᵥ x) := by rw [h]
    _ = _ := by
      rw [← mulVec_mulVec, dot_U hM, dotProduct]
      exact Finset.sum_congr rfl fun k _ => by ring

theorem sorted_facts {M : Matrix V V ℝ} (hM : M.IsHermitian) (i : Fin (Fintype.card V))
    (hi : (i : ℕ) + 2 = Fintype.card V) :
    ∃ k₀ k₁ : V, k₁ ≠ k₀ ∧ hM.eigenvalues k₁ = hM.eigenvalues₀ i ∧
      hM.eigenvalues k₀ ≤ hM.eigenvalues₀ i ∧ ∀ k, k ≠ k₀ → hM.eigenvalues₀ i ≤ hM.eigenvalues k := by
  set e := (Fintype.equivOfCardEq (Fintype.card_fin (Fintype.card V)) : Fin (Fintype.card V) ≃ V)
  let j : Fin (Fintype.card V) := ⟨(i : ℕ) + 1, by omega⟩
  have hij : i ≤ j := by simp [Fin.le_def, j]
  refine ⟨e j, e i, ?_, ?_, ?_, ?_⟩
  · intro h
    have := e.injective h
    simp [Fin.ext_iff, j] at this
  · simp [Matrix.IsHermitian.eigenvalues, e]
  · simp only [Matrix.IsHermitian.eigenvalues, e, Equiv.symm_apply_apply]
    exact hM.eigenvalues₀_antitone hij
  · intro k hk
    simp only [Matrix.IsHermitian.eigenvalues]
    apply hM.eigenvalues₀_antitone
    have h1 : (Fintype.equivOfCardEq (Fintype.card_fin (Fintype.card V))).symm k ≠ j := by
      intro h; apply hk; rw [← h]; simp [e]
    have h2 := ((Fintype.equivOfCardEq (Fintype.card_fin (Fintype.card V))).symm k).isLt
    rw [Fin.le_def]
    rw [Ne, Fin.ext_iff] at h1
    simp only [j] at h1
    omega


section Lap
variable (G : SimpleGraph V) [DecidableRel G.Adj]

theorem lap_quad (x : V → ℝ) :
    x ⬝ᵥ (G.lapMatrix ℝ *ᵥ x) = (∑ i, ∑ j, if G.Adj i j then (x i - x j) ^ 2 else 0) / 2 := by
  rw [← Matrix.toLinearMap₂'_apply', SimpleGraph.lapMatrix_toLinearMap₂']

theorem lap_eig_nonneg (k : V) : 0 ≤ (G.isHermitian_lapMatrix ℝ).eigenvalues k :=
  Matrix.PosSemidef.eigenvalues_nonneg (SimpleGraph.posSemidef_lapMatrix ℝ G) k

theorem reg_sum_left {d : ℕ} (hreg : G.IsRegularOfDegree d) (x : V → ℝ) :
    (∑ i, ∑ j, if G.Adj i j then x i else 0) = d * ∑ i, x i := by
  rw [Finset.mul_sum]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [← Finset.sum_filter, Finset.sum_const, nsmul_eq_mul]
  have : (Finset.univ.filter (G.Adj i)).card = d := by
    rw [← hreg i, ← SimpleGraph.card_neighborFinset_eq_degree, SimpleGraph.neighborFinset_eq_filter]
  rw [this]

theorem reg_sum_right {d : ℕ} (hreg : G.IsRegularOfDegree d) (x : V → ℝ) :
    (∑ i, ∑ j, if G.Adj i j then x j else 0) = d * ∑ i, x i := by
  rw [Finset.sum_comm, ← reg_sum_left G hreg x]
  refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
  simp only [G.adj_comm]

theorem lap_quad_le {d : ℕ} (hreg : G.IsRegularOfDegree d) (x : V → ℝ) :
    (∑ i, ∑ j, if G.Adj i j then (x i - x j) ^ 2 else 0) ≤ 4 * d * ∑ i, x i ^ 2 := by
  have h1 := reg_sum_left G hreg (fun i => x i ^ 2)
  have h2 := reg_sum_right G hreg (fun i => x i ^ 2)
  have h3 : (∑ i, ∑ j, if G.Adj i j then (x i - x j) ^ 2 else 0) ≤
      ∑ i, ∑ j, ((2 * if G.Adj i j then x i ^ 2 else 0) + (2 * if G.Adj i j then x j ^ 2 else 0)) := by
    refine Finset.sum_le_sum fun i _ => Finset.sum_le_sum fun j _ => ?_
    split_ifs
    · nlinarith [sq_nonneg (x i + x j)]
    · simp
  simp only [Finset.sum_add_distrib, ← Finset.mul_sum] at h3
  linarith

variable {G}

theorem col_quad (k : V) :
    let U := ((G.isHermitian_lapMatrix ℝ).eigenvectorUnitary : Matrix V V ℝ)
    (fun v => U v k) ⬝ᵥ (G.lapMatrix ℝ *ᵥ fun v => U v k) =
      (G.isHermitian_lapMatrix ℝ).eigenvalues k := by
  intro U
  rw [col_eigen, dotProduct]
  have := col_orth (G.isHermitian_lapMatrix ℝ) k k
  simp only [↓reduceIte] at this
  calc ∑ v, U v k * ((G.isHermitian_lapMatrix ℝ).eigenvalues k * U v k)
      = (G.isHermitian_lapMatrix ℝ).eigenvalues k * ∑ v, U v k * U v k := by
        rw [Finset.mul_sum]; exact Finset.sum_congr rfl fun v _ => by ring
    _ = _ := by rw [this, mul_one]

theorem lap_eig_le {d : ℕ} (hreg : G.IsRegularOfDegree d) (k : V) :
    (G.isHermitian_lapMatrix ℝ).eigenvalues k ≤ 2 * d := by
  have h := col_quad (G := G) k
  simp only at h
  rw [← h, lap_quad]
  have h2 := lap_quad_le G hreg (fun v => ((G.isHermitian_lapMatrix ℝ).eigenvectorUnitary : Matrix V V ℝ) v k)
  have h3 := col_orth (G.isHermitian_lapMatrix ℝ) k k
  simp only [↓reduceIte] at h3
  simp only [sq] at h2 ⊢
  rw [h3] at h2
  linarith

theorem gap_pos (hconn : G.Connected)
    (i : Fin (Fintype.card V)) (hi : (i : ℕ) + 2 = Fintype.card V) :
    0 < (G.isHermitian_lapMatrix ℝ).eigenvalues₀ i := by
  obtain ⟨k₀, k₁, hne, h1, h0, -⟩ := sorted_facts (G.isHermitian_lapMatrix ℝ) i hi
  by_contra hneg
  push Not at hneg
  obtain ⟨U, hU⟩ : ∃ U, U = ((G.isHermitian_lapMatrix ℝ).eigenvectorUnitary : Matrix V V ℝ) :=
    ⟨_, rfl⟩
  have e0 : (G.isHermitian_lapMatrix ℝ).eigenvalues k₀ = 0 :=
    le_antisymm (h0.trans hneg) (lap_eig_nonneg G k₀)
  have e1 : (G.isHermitian_lapMatrix ℝ).eigenvalues k₁ = 0 :=
    le_antisymm (h1 ▸ hneg) (lap_eig_nonneg G k₁)
  have hconst : ∀ k, (G.isHermitian_lapMatrix ℝ).eigenvalues k = 0 → ∀ v w, U v k = U w k := by
    intro k hk v w
    have hz : G.lapMatrix ℝ *ᵥ (fun v => U v k) = 0 := by
      rw [hU, col_eigen, hk]; funext v; simp
    exact (SimpleGraph.lapMatrix_mulVec_eq_zero_iff_forall_reachable G).1 hz v w (hconn.preconnected v w)
  obtain ⟨w⟩ : Nonempty V := ⟨k₀⟩
  have c0 := hconst k₀ e0
  have c1 := hconst k₁ e1
  have o01 := col_orth (G.isHermitian_lapMatrix ℝ) k₀ k₁
  have o00 := col_orth (G.isHermitian_lapMatrix ℝ) k₀ k₀
  have o11 := col_orth (G.isHermitian_lapMatrix ℝ) k₁ k₁
  rw [← hU] at o01 o00 o11
  simp only [hne.symm, ↓reduceIte] at o01 o00 o11
  simp only [c0 _ w, c1 _ w, Finset.sum_const, Finset.card_univ, nsmul_eq_mul] at o01 o00 o11
  have : ((Fintype.card V : ℝ) * (U w k₀ * U w k₁)) ^ 2 =
      ((Fintype.card V : ℝ) * (U w k₀ * U w k₀)) * ((Fintype.card V : ℝ) * (U w k₁ * U w k₁)) := by ring
  rw [o01, o00, o11] at this
  norm_num at this

end Lap

#print axioms spec_U
#print axioms UtU
#print axioms UUt
#print axioms MU
#print axioms col_eigen
#print axioms col_orth
#print axioms row_orth
#print axioms dot_U
#print axioms quad_U
#print axioms norm_U
#print axioms sorted_facts
#print axioms lap_quad
#print axioms lap_eig_nonneg
#print axioms reg_sum_left
#print axioms reg_sum_right
#print axioms lap_quad_le
#print axioms col_quad
#print axioms lap_eig_le
#print axioms gap_pos

section Lap2
variable {G : SimpleGraph V} [DecidableRel G.Adj]

theorem ker_col (k₀ : V) (lam : ℝ) (hlam : 0 < lam)
    (hk : ∀ k, k ≠ k₀ → lam ≤ (G.isHermitian_lapMatrix ℝ).eigenvalues k) :
    (G.isHermitian_lapMatrix ℝ).eigenvalues k₀ = 0 ∧ ∃ c : ℝ,
      (∀ v, ((G.isHermitian_lapMatrix ℝ).eigenvectorUnitary : Matrix V V ℝ) v k₀ = c) ∧
        c ^ 2 * Fintype.card V = 1 := by
  have hq := quad_U (G.isHermitian_lapMatrix ℝ) 1
  have hn := norm_U (G.isHermitian_lapMatrix ℝ) 1
  have hUy : ((G.isHermitian_lapMatrix ℝ).eigenvectorUnitary : Matrix V V ℝ) *ᵥ
      (((G.isHermitian_lapMatrix ℝ).eigenvectorUnitary : Matrix V V ℝ)ᵀ *ᵥ 1) = 1 := by
    rw [mulVec_mulVec, UUt, one_mulVec]
  obtain ⟨U, hU⟩ : ∃ U, U = ((G.isHermitian_lapMatrix ℝ).eigenvectorUnitary : Matrix V V ℝ) :=
    ⟨_, rfl⟩
  obtain ⟨μ, hμ⟩ : ∃ μ, μ = (G.isHermitian_lapMatrix ℝ).eigenvalues := ⟨_, rfl⟩
  rw [← hU, ← hμ] at hq
  rw [← hU] at hn hUy
  rw [← hμ] at hk ⊢
  rw [← hU]
  obtain ⟨y, hy⟩ : ∃ y, y = Uᵀ *ᵥ (1 : V → ℝ) := ⟨_, rfl⟩
  rw [← hy] at hq hn hUy
  rw [SimpleGraph.lapMatrix_mulVec_one_eq_zero, dotProduct_zero] at hq
  have hnn : ∀ k ∈ Finset.univ, 0 ≤ μ k * y k ^ 2 := fun k _ => by
    rw [hμ]; exact mul_nonneg (lap_eig_nonneg G k) (sq_nonneg _)
  have hz := (Finset.sum_eq_zero_iff_of_nonneg hnn).1 hq.symm
  have hy0 : ∀ k, k ≠ k₀ → y k = 0 := by
    intro k hk'
    have := hz k (Finset.mem_univ _)
    have hpos : 0 < μ k := lt_of_lt_of_le hlam (hk k hk')
    rcases mul_eq_zero.1 this with h | h
    · linarith
    · exact pow_eq_zero_iff (n := 2) (by norm_num) |>.1 h
  have hsum : ∑ k, y k ^ 2 = y k₀ ^ 2 :=
    Finset.sum_eq_single k₀ (fun k _ hk' => by rw [hy0 k hk']; ring) (by simp)
  have hone : (1 : V → ℝ) ⬝ᵥ 1 = Fintype.card V := by simp [dotProduct]
  rw [hone, hsum] at hn
  have hv : ∀ v, U v k₀ * y k₀ = 1 := by
    intro v
    have := congrFun hUy v
    rw [Matrix.mulVec, dotProduct, Finset.sum_eq_single k₀ (fun k _ hk' => by rw [hy0 k hk']; ring)
      (by simp)] at this
    simpa using this
  have hyne : y k₀ ≠ 0 := by
    intro h; have := hv k₀; rw [h, mul_zero] at this; exact zero_ne_one this
  refine ⟨?_, 1 / y k₀, fun v => by field_simp; exact hv v, ?_⟩
  · have := hz k₀ (Finset.mem_univ _)
    rcases mul_eq_zero.1 this with h | h
    · exact h
    · exact absurd (pow_eq_zero_iff (n := 2) (by norm_num) |>.1 h) hyne
  · rw [hn]; field_simp

theorem rayleigh_lower (k₀ : V) (lam c : ℝ)
    (hk : ∀ k, k ≠ k₀ → lam ≤ (G.isHermitian_lapMatrix ℝ).eigenvalues k)
    (hc : ∀ v, ((G.isHermitian_lapMatrix ℝ).eigenvectorUnitary : Matrix V V ℝ) v k₀ = c)
    (x : V → ℝ) (hx : ∑ v, x v = 0) :
    lam * (x ⬝ᵥ x) ≤ x ⬝ᵥ (G.lapMatrix ℝ *ᵥ x) := by
  rw [quad_U (G.isHermitian_lapMatrix ℝ), norm_U (G.isHermitian_lapMatrix ℝ), Finset.mul_sum]
  refine Finset.sum_le_sum fun k _ => ?_
  by_cases hk' : k = k₀
  · subst hk'
    have : (((G.isHermitian_lapMatrix ℝ).eigenvectorUnitary : Matrix V V ℝ)ᵀ *ᵥ x) k = 0 := by
      simp only [Matrix.mulVec, dotProduct, Matrix.transpose_apply, hc, ← Finset.mul_sum, hx,
        mul_zero]
    rw [this]; simp
  · exact mul_le_mul_of_nonneg_right (hk k hk') (sq_nonneg _)

theorem boundary_sum (S : Finset V) :
    (∑ i, ∑ j, if G.Adj i j ∧ i ∈ S ∧ j ∉ S then (1 : ℝ) else 0) = edgeBoundary G S := by
  classical
  rw [edgeBoundary, Finset.card_filter, Nat.cast_sum, Finset.sum_product]
  rw [← Finset.sum_filter_add_sum_filter_not Finset.univ (· ∈ S)]
  have h1 : ∑ x ∈ Finset.univ.filter (· ∉ S), ∑ j, (if G.Adj x j ∧ x ∈ S ∧ j ∉ S then (1 : ℝ) else 0)
      = 0 := by
    refine Finset.sum_eq_zero fun i hi => Finset.sum_eq_zero fun j _ => ?_
    simp only [Finset.mem_filter] at hi
    simp [hi.2]
  rw [h1, add_zero, Finset.filter_mem_eq_inter, Finset.univ_inter]
  refine Finset.sum_congr rfl fun i hi => ?_
  rw [← Finset.sum_filter_add_sum_filter_not Finset.univ (· ∉ S)]
  have h2 : ∑ x ∈ Finset.univ.filter (fun j => ¬ j ∉ S), (if G.Adj i x ∧ i ∈ S ∧ x ∉ S then (1 : ℝ) else 0)
      = 0 := by
    refine Finset.sum_eq_zero fun j hj => ?_
    simp only [Finset.mem_filter] at hj
    simp [hj.2]
  rw [h2, add_zero]
  have : Finset.univ.filter (fun j => j ∉ S) = Sᶜ := by ext; simp
  rw [this]
  refine Finset.sum_congr rfl fun j hj => ?_
  rw [Finset.mem_compl] at hj
  simp [hi, hj]

theorem cut_sum (S : Finset V) (a b : ℝ) (φ : ℝ → ℝ) (h0 : φ 0 = 0) (hab : φ (b - a) = φ (a - b)) :
    (∑ i, ∑ j, if G.Adj i j then
        φ ((if i ∈ S then a else b) - (if j ∈ S then a else b)) else 0) =
      2 * φ (a - b) * edgeBoundary G S := by
  rw [← boundary_sum]
  have : ∀ i j, (if G.Adj i j then
        φ ((if i ∈ S then a else b) - (if j ∈ S then a else b)) else 0) =
      φ (a - b) * (if G.Adj i j ∧ i ∈ S ∧ j ∉ S then (1 : ℝ) else 0) +
      φ (a - b) * (if G.Adj j i ∧ j ∈ S ∧ i ∉ S then (1 : ℝ) else 0) := by
    intro i j
    by_cases hij : G.Adj i j <;> by_cases hi : i ∈ S <;> by_cases hj : j ∈ S <;>
      simp [hij, hi, hj, G.adj_comm, h0, hab]
  simp only [this, Finset.sum_add_distrib, ← Finset.mul_sum]
  rw [Finset.sum_comm (f := fun i j => if G.Adj j i ∧ j ∈ S ∧ i ∉ S then (1 : ℝ) else 0)]
  ring

end Lap2


theorem split_abs (p q m : ℝ) (hm : 0 < m) (hp : p = 0 ∨ m ≤ p) (hq : q = 0 ∨ m ≤ q) :
    |p - q| = m * |(if p ≠ 0 then (1 : ℝ) else 0) - (if q ≠ 0 then 1 else 0)| +
      |max (p - m) 0 - max (q - m) 0| := by
  rcases hp with rfl | hp <;> rcases hq with rfl | hq
  · simp
  · have hq0 : q ≠ 0 := by intro h; linarith
    rw [max_eq_right (by linarith : (0:ℝ) - m ≤ 0), max_eq_left (by linarith : 0 ≤ q - m)]
    simp only [hq0, ne_eq, not_true_eq_false, not_false_eq_true, ↓reduceIte]
    rw [abs_of_nonpos (by linarith), abs_of_nonpos (by linarith), abs_of_nonpos (by linarith)]
    ring
  · have hp0 : p ≠ 0 := by intro h; linarith
    rw [max_eq_right (by linarith : (0:ℝ) - m ≤ 0), max_eq_left (by linarith : 0 ≤ p - m)]
    simp only [hp0, ne_eq, not_true_eq_false, not_false_eq_true, ↓reduceIte]
    rw [abs_of_nonneg (by linarith), abs_of_nonneg (by linarith), abs_of_nonneg (by linarith)]
    ring
  · have hp0 : p ≠ 0 := by intro h; linarith
    have hq0 : q ≠ 0 := by intro h; linarith
    rw [max_eq_left (by linarith : 0 ≤ p - m), max_eq_left (by linarith : 0 ≤ q - m)]
    simp only [hp0, hq0, ne_eq, not_false_eq_true, ↓reduceIte, sub_self, abs_zero, mul_zero,
      zero_add]
    congr 1; ring

section Sweep
variable {G : SimpleGraph V} [DecidableRel G.Adj]

theorem sweep (c : ℝ) (_hc : 0 ≤ c) : ∀ (N : ℕ) (h : V → ℝ),
    (Finset.univ.filter (fun v => h v ≠ 0)).card ≤ N → (∀ v, 0 ≤ h v) → (∃ v, h v ≠ 0) →
    (∑ i, ∑ j, if G.Adj i j then |h i - h j| else 0) ≤ 2 * c * ∑ v, h v →
    ∃ S ⊆ Finset.univ.filter (fun v => h v ≠ 0), S.Nonempty ∧
      (edgeBoundary G S : ℝ) ≤ c * S.card := by
  classical
  intro N
  induction N with
  | zero =>
    intro h hcard _ hex _
    obtain ⟨v, hv⟩ := hex
    have : v ∈ Finset.univ.filter (fun v => h v ≠ 0) := by simp [hv]
    rw [Finset.card_eq_zero.1 (Nat.le_zero.1 hcard)] at this
    simp at this
  | succ N ih =>
    intro h hcard hnn hex hB
    set T := Finset.univ.filter (fun v => h v ≠ 0) with hTdef
    obtain ⟨v₀, hv₀⟩ := hex
    have hT : T.Nonempty := ⟨v₀, by simp [T, hv₀]⟩
    by_cases hgood : (edgeBoundary G T : ℝ) ≤ c * T.card
    · exact ⟨T, subset_refl _, hT, hgood⟩
    push Not at hgood
    obtain ⟨vmin, hvminT, hvmin⟩ := Finset.exists_mem_eq_inf' hT h
    set m := T.inf' hT h with hmdef
    have hmle : ∀ v ∈ T, m ≤ h v := fun v hv => Finset.inf'_le h hv
    have hvmin0 : h vmin ≠ 0 := by simpa [T] using hvminT
    have hmpos : 0 < m := by rw [hvmin]; exact lt_of_le_of_ne (hnn vmin) (Ne.symm hvmin0)
    have hcase : ∀ v, h v = 0 ∨ m ≤ h v := by
      intro v
      by_cases hv : h v = 0
      · exact Or.inl hv
      · exact Or.inr (hmle v (by simp [T, hv]))
    set h' : V → ℝ := fun v => max (h v - m) 0 with hh'
    have hmemT : ∀ v, (v ∈ T) = (h v ≠ 0) := fun v => by simp [T]
    -- boundary decomposition
    have hsplit : ∀ i j, (if G.Adj i j then |h i - h j| else 0) =
        m * (if G.Adj i j then |(if i ∈ T then (1:ℝ) else 0) - (if j ∈ T then 1 else 0)| else 0) +
        (if G.Adj i j then |h' i - h' j| else 0) := by
      intro i j
      by_cases hij : G.Adj i j
      · simp only [hij, ↓reduceIte]
        have ei : (if i ∈ T then (1:ℝ) else 0) = if h i ≠ 0 then 1 else 0 := by simp [T]
        have ej : (if j ∈ T then (1:ℝ) else 0) = if h j ≠ 0 then 1 else 0 := by simp [T]
        rw [ei, ej]; exact split_abs _ _ _ hmpos (hcase i) (hcase j)
      · simp [hij]
    have hcut := cut_sum (G := G) T 1 0 (fun t => |t|) (by simp) (by simp)
    have hBsplit : (∑ i, ∑ j, if G.Adj i j then |h i - h j| else 0) =
        m * (2 * edgeBoundary G T) + ∑ i, ∑ j, if G.Adj i j then |h' i - h' j| else 0 := by
      simp only [hsplit, Finset.sum_add_distrib, ← Finset.mul_sum, hcut]
      norm_num
    have hsumsplit : ∑ v, h v = m * T.card + ∑ v, h' v := by
      have : ∀ v, h v = m * (if v ∈ T then (1:ℝ) else 0) + h' v := by
        intro v
        have ev : (if v ∈ T then (1:ℝ) else 0) = if h v ≠ 0 then 1 else 0 := by simp [T]
        rw [ev]
        rcases hcase v with hv | hv
        · simp [hh', hv, hmpos.le]
        · have hv0 : h v ≠ 0 := by intro h0; linarith
          simp only [hv0, ne_eq, not_false_eq_true, ↓reduceIte, mul_one, hh']
          rw [max_eq_left (by linarith)]; ring
      rw [Finset.sum_congr rfl fun v _ => this v, Finset.sum_add_distrib, ← Finset.mul_sum,
        Finset.sum_boole]
      simp [T]
    have hB' : (∑ i, ∑ j, if G.Adj i j then |h' i - h' j| else 0) < 2 * c * ∑ v, h' v := by
      rw [hBsplit, hsumsplit] at hB
      nlinarith [mul_lt_mul_of_pos_left hgood hmpos]
    have hnn' : ∀ v, 0 ≤ h' v := fun v => le_max_right _ _
    have hex' : ∃ v, h' v ≠ 0 := by
      by_contra hall
      push Not at hall
      simp [hall] at hB'
    have hsub : Finset.univ.filter (fun v => h' v ≠ 0) ⊆ T.erase vmin := by
      intro v hv
      simp only [Finset.mem_filter, Finset.mem_univ, true_and, hh'] at hv
      have hpos : m < h v := by
        by_contra hle; push Not at hle; apply hv; rw [max_eq_right (by linarith)]
      refine Finset.mem_erase.2 ⟨?_, by simp [T]; intro h0; linarith⟩
      intro hveq; rw [hveq] at hpos; linarith
    have hcard' : (Finset.univ.filter (fun v => h' v ≠ 0)).card ≤ N := by
      have := Finset.card_le_card hsub
      rw [Finset.card_erase_of_mem hvminT] at this
      omega
    obtain ⟨S, hS, hSne, hSb⟩ := ih h' hcard' hnn' hex' hB'.le
    exact ⟨S, hS.trans (hsub.trans (Finset.erase_subset _ _)), hSne, hSb⟩

end Sweep


section Upper
variable {G : SimpleGraph V} [DecidableRel G.Adj]

theorem cs_step {d : ℕ} (hreg : G.IsRegularOfDegree d) (lam : ℝ) (hlam : 0 ≤ lam)
    (a : V → ℝ) (ha : ∀ v, 0 ≤ a v)
    (hQ : (∑ i, ∑ j, if G.Adj i j then (a i - a j) ^ 2 else 0) ≤ 2 * lam * ∑ v, a v ^ 2) :
    (∑ i, ∑ j, if G.Adj i j then |a i ^ 2 - a j ^ 2| else 0) ≤
      2 * Real.sqrt (2 * d * lam) * ∑ v, a v ^ 2 := by
  classical
  set A := ∑ v, a v ^ 2
  have hA : 0 ≤ A := Finset.sum_nonneg fun v _ => sq_nonneg _
  have hB0 : 0 ≤ ∑ i, ∑ j, (if G.Adj i j then |a i ^ 2 - a j ^ 2| else 0) :=
    Finset.sum_nonneg fun i _ => Finset.sum_nonneg fun j _ => by split_ifs <;> positivity
  have hBeq : (∑ i, ∑ j, if G.Adj i j then |a i ^ 2 - a j ^ 2| else 0) =
      ∑ p : V × V, (if G.Adj p.1 p.2 then |a p.1 - a p.2| else 0) *
        (if G.Adj p.1 p.2 then a p.1 + a p.2 else 0) := by
    simp only [Fintype.sum_prod_type]
    refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
    split_ifs
    · rw [show a i ^ 2 - a j ^ 2 = (a i - a j) * (a i + a j) by ring, abs_mul,
        abs_of_nonneg (add_nonneg (ha i) (ha j))]
    · simp
  have hF : ∑ p : V × V, (if G.Adj p.1 p.2 then |a p.1 - a p.2| else 0) ^ 2 =
      ∑ i, ∑ j, if G.Adj i j then (a i - a j) ^ 2 else 0 := by
    simp only [Fintype.sum_prod_type]
    refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
    split_ifs <;> simp [sq_abs]
  have hH : ∑ p : V × V, (if G.Adj p.1 p.2 then a p.1 + a p.2 else 0) ^ 2 ≤ 4 * d * A := by
    simp only [Fintype.sum_prod_type]
    have h1 := reg_sum_left G hreg (fun i => a i ^ 2)
    have h2 := reg_sum_right G hreg (fun i => a i ^ 2)
    have h3 : (∑ i, ∑ j, (if G.Adj i j then a i + a j else 0) ^ 2) ≤
        ∑ i, ∑ j, ((2 * if G.Adj i j then a i ^ 2 else 0) +
          (2 * if G.Adj i j then a j ^ 2 else 0)) := by
      refine Finset.sum_le_sum fun i _ => Finset.sum_le_sum fun j _ => ?_
      split_ifs
      · nlinarith [sq_nonneg (a i - a j)]
      · simp
    simp only [Finset.sum_add_distrib, ← Finset.mul_sum] at h3
    linarith
  have hcs := Finset.sum_mul_sq_le_sq_mul_sq Finset.univ
    (fun p : V × V => if G.Adj p.1 p.2 then |a p.1 - a p.2| else 0)
    (fun p : V × V => if G.Adj p.1 p.2 then a p.1 + a p.2 else 0)
  rw [← hBeq, hF] at hcs
  have hQ0 : 0 ≤ ∑ i, ∑ j, (if G.Adj i j then (a i - a j) ^ 2 else 0) :=
    Finset.sum_nonneg fun i _ => Finset.sum_nonneg fun j _ => by split_ifs <;> positivity
  have hsq : (2 * Real.sqrt (2 * d * lam) * A) ^ 2 = 8 * d * lam * A ^ 2 := by
    rw [mul_pow, mul_pow, Real.sq_sqrt (by positivity)]; ring
  have key : (∑ i, ∑ j, if G.Adj i j then |a i ^ 2 - a j ^ 2| else 0) ^ 2 ≤
      (2 * Real.sqrt (2 * d * lam) * A) ^ 2 := by
    rw [hsq]
    calc _ ≤ _ := hcs
      _ ≤ (2 * lam * A) * (4 * d * A) :=
          mul_le_mul hQ hH (Finset.sum_nonneg fun p _ => sq_nonneg _) (by positivity)
      _ = 8 * d * lam * A ^ 2 := by ring
  exact (pow_le_pow_iff_left₀ hB0 (by positivity) (by norm_num)).1 key

theorem exists_median [Nonempty V] (f : V → ℝ) : ∃ m : ℝ,
    2 * (Finset.univ.filter (fun v => m < f v)).card ≤ Fintype.card V ∧
      2 * (Finset.univ.filter (fun v => f v < m)).card ≤ Fintype.card V := by
  classical
  set M := (Finset.univ.image f).filter
    (fun x => 2 * (Finset.univ.filter (fun v => x < f v)).card ≤ Fintype.card V)
  have himg : (Finset.univ.image f).Nonempty := Finset.univ_nonempty.image f
  have hM : M.Nonempty := by
    refine ⟨(Finset.univ.image f).max' himg, ?_⟩
    simp only [M, Finset.mem_filter]
    refine ⟨Finset.max'_mem _ _, ?_⟩
    have : Finset.univ.filter (fun v => (Finset.univ.image f).max' himg < f v) = ∅ := by
      ext v
      simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.notMem_empty, iff_false,
        not_lt]
      exact Finset.le_max' _ _ (Finset.mem_image_of_mem f (Finset.mem_univ v))
    rw [this]; simp
  refine ⟨M.min' hM, (Finset.mem_filter.1 (M.min'_mem hM)).2, ?_⟩
  by_contra hbad
  push Not at hbad
  set m := M.min' hM
  set L := Finset.univ.filter (fun v => f v < m)
  have hL : L.Nonempty := by
    rw [← Finset.card_pos]; omega
  set m' := (L.image f).max' (hL.image f)
  obtain ⟨w, hwL, hw⟩ := Finset.mem_image.1 ((L.image f).max'_mem (hL.image f))
  have hw' : f w = m' := hw
  have hm'lt : m' < m := by
    rw [← hw']; simpa [L] using hwL
  have hm'M : m' ∈ M := by
    simp only [M, Finset.mem_filter]
    refine ⟨by rw [← hw']; exact Finset.mem_image_of_mem f (Finset.mem_univ w), ?_⟩
    have hsub : Finset.univ.filter (fun v => m' < f v) ⊆ Lᶜ := by
      intro v hv
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hv
      rw [Finset.mem_compl]
      intro hvL
      have := (L.image f).le_max' (f v) (Finset.mem_image_of_mem f hvL)
      linarith
    have := Finset.card_le_card hsub
    rw [Finset.card_compl] at this
    have hLle : L.card ≤ Fintype.card V := Finset.card_le_univ L
    omega
  have := M.min'_le m' hm'M
  linarith

end Upper


theorem pos_neg_sq_le (x y : ℝ) :
    (max x 0 - max y 0) ^ 2 + (max (-x) 0 - max (-y) 0) ^ 2 ≤ (x - y) ^ 2 := by
  rcases le_total 0 x with hx | hx <;> rcases le_total 0 y with hy | hy
  · rw [max_eq_left hx, max_eq_left hy, max_eq_right (by linarith), max_eq_right (by linarith)]
    nlinarith
  · rw [max_eq_left hx, max_eq_right hy, max_eq_right (by linarith), max_eq_left (by linarith)]
    nlinarith
  · rw [max_eq_right hx, max_eq_left hy, max_eq_left (by linarith), max_eq_right (by linarith)]
    nlinarith
  · rw [max_eq_right hx, max_eq_right hy, max_eq_left (by linarith), max_eq_left (by linarith)]
    nlinarith

theorem pos_neg_sq (x : ℝ) : x ^ 2 = max x 0 ^ 2 + max (-x) 0 ^ 2 := by
  rcases le_total 0 x with hx | hx
  · rw [max_eq_left hx, max_eq_right (by linarith)]; ring
  · rw [max_eq_right hx, max_eq_left (by linarith)]; ring

theorem pos_neg_eq (x : ℝ) : x = max x 0 - max (-x) 0 := by
  rcases le_total 0 x with hx | hx
  · rw [max_eq_left hx, max_eq_right (by linarith)]; ring
  · rw [max_eq_right hx, max_eq_left (by linarith)]; ring

section Upper2
variable {G : SimpleGraph V} [DecidableRel G.Adj]

theorem upper_from_vector {d : ℕ} (hreg : G.IsRegularOfDegree d) (lam : ℝ) (hlam : 0 ≤ lam)
    (f : V → ℝ) (hf0 : ∃ v, f v ≠ 0) (hfs : ∑ v, f v = 0)
    (hQ : (∑ i, ∑ j, if G.Adj i j then (f i - f j) ^ 2 else 0) ≤ 2 * lam * ∑ v, f v ^ 2) :
    ∃ S : Finset V, S.Nonempty ∧ 2 * S.card ≤ Fintype.card V ∧
      (edgeBoundary G S : ℝ) / (S.card : ℝ) ≤ Real.sqrt (2 * d * lam) := by
  classical
  have : Nonempty V := ⟨hf0.choose⟩
  let Q : (V → ℝ) → ℝ := fun x => ∑ i, ∑ j, if G.Adj i j then (x i - x j) ^ 2 else 0
  have hQnn : ∀ x, 0 ≤ Q x := fun x =>
    Finset.sum_nonneg fun i _ => Finset.sum_nonneg fun j _ => by split_ifs <;> positivity
  obtain ⟨m, hm1, hm2⟩ := exists_median f
  let g : V → ℝ := fun v => f v - m
  have hQg : Q g = Q f := by
    simp only [Q, g, sub_sub_sub_cancel_right]
  have hgsq : ∑ v, g v ^ 2 = ∑ v, f v ^ 2 + Fintype.card V * m ^ 2 := by
    have : ∀ v, g v ^ 2 = f v ^ 2 + (m ^ 2 - 2 * m * f v) := fun v => by simp only [g]; ring
    simp only [this, Finset.sum_add_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum, hfs,
      Finset.sum_const, Finset.card_univ, nsmul_eq_mul]
    ring
  have hQg' : Q g ≤ 2 * lam * ∑ v, g v ^ 2 := by
    rw [hQg, hgsq]
    have : 0 ≤ 2 * lam * (Fintype.card V * m ^ 2) := by positivity
    have hQ' : Q f ≤ 2 * lam * ∑ v, f v ^ 2 := hQ
    nlinarith
  let gp : V → ℝ := fun v => max (g v) 0
  let gm : V → ℝ := fun v => max (-g v) 0
  have hQsplit : Q gp + Q gm ≤ Q g := by
    simp only [Q, ← Finset.sum_add_distrib]
    refine Finset.sum_le_sum fun i _ => Finset.sum_le_sum fun j _ => ?_
    split_ifs
    · exact pos_neg_sq_le (g i) (g j)
    · simp
  have hsqsplit : ∑ v, g v ^ 2 = ∑ v, gp v ^ 2 + ∑ v, gm v ^ 2 := by
    rw [← Finset.sum_add_distrib]
    exact Finset.sum_congr rfl fun v _ => pos_neg_sq (g v)
  have hQzero : ∀ x : V → ℝ, (∀ v, x v = 0) → Q x = 0 ∧ ∑ v, x v ^ 2 = 0 := by
    intro x hx
    simp [Q, hx]
  obtain ⟨a, ha0, hane, hQa, hsupp⟩ : ∃ a : V → ℝ, (∀ v, 0 ≤ a v) ∧ (∃ v, a v ≠ 0) ∧
      Q a ≤ 2 * lam * ∑ v, a v ^ 2 ∧
        2 * (Finset.univ.filter (fun v => a v ≠ 0)).card ≤ Fintype.card V := by
    have hsp : 2 * (Finset.univ.filter (fun v => gp v ≠ 0)).card ≤ Fintype.card V := by
      refine le_trans (Nat.mul_le_mul_left 2 (Finset.card_le_card ?_)) hm1
      intro v hv
      simp only [Finset.mem_filter, Finset.mem_univ, true_and, gp, g] at hv ⊢
      by_contra hle; push Not at hle; exact hv (max_eq_right (by linarith))
    have hsm : 2 * (Finset.univ.filter (fun v => gm v ≠ 0)).card ≤ Fintype.card V := by
      refine le_trans (Nat.mul_le_mul_left 2 (Finset.card_le_card ?_)) hm2
      intro v hv
      simp only [Finset.mem_filter, Finset.mem_univ, true_and, gm, g] at hv ⊢
      by_contra hle; push Not at hle; exact hv (max_eq_right (by linarith))
    by_cases hp : (∃ v, gp v ≠ 0) ∧ Q gp ≤ 2 * lam * ∑ v, gp v ^ 2
    · exact ⟨gp, fun v => le_max_right _ _, hp.1, hp.2, hsp⟩
    refine ⟨gm, fun v => le_max_right _ _, ?_, ?_, hsm⟩
    · by_contra hall
      push Not at hall
      by_cases hpz : ∃ v, gp v ≠ 0
      · have h1 := hQzero gm hall
        have : Q gp > 2 * lam * ∑ v, gp v ^ 2 := by
          by_contra h; push Not at h; exact hp ⟨hpz, h⟩
        rw [hsqsplit, h1.2] at hQg'
        linarith [h1.1, h1.2]
      · push Not at hpz
        obtain ⟨v, hv⟩ := hf0
        have hall' : ∀ v, f v = m := by
          intro v
          have := pos_neg_eq (g v)
          have e1 : max (g v) 0 = 0 := hpz v
          have e2 : max (-g v) 0 = 0 := hall v
          rw [e1, e2] at this
          simp only [g] at this
          linarith
        have hm0 : m = 0 := by
          simp only [hall', Finset.sum_const, Finset.card_univ, nsmul_eq_mul] at hfs
          have hpos : (0 : ℝ) < Fintype.card V := by exact_mod_cast Fintype.card_pos
          rcases mul_eq_zero.1 hfs with h | h
          · linarith
          · exact h
        exact hv (by rw [hall' v, hm0])
    · by_cases hpz : ∃ v, gp v ≠ 0
      · have : Q gp > 2 * lam * ∑ v, gp v ^ 2 := by
          by_contra h; push Not at h; exact hp ⟨hpz, h⟩
        rw [hsqsplit] at hQg'
        linarith
      · push Not at hpz
        have h1 := hQzero gp hpz
        rw [hsqsplit, h1.2] at hQg'
        linarith [h1.1, h1.2]
  have hcs := cs_step hreg lam hlam a ha0 hQa
  set c := Real.sqrt (2 * d * lam)
  have hc : 0 ≤ c := Real.sqrt_nonneg _
  have hsuppeq : Finset.univ.filter (fun v => a v ^ 2 ≠ 0) =
      Finset.univ.filter (fun v => a v ≠ 0) := by
    ext v; simp
  obtain ⟨S, hS, hSne, hSb⟩ := sweep (G := G) c hc _ (fun v => a v ^ 2) le_rfl
    (fun v => sq_nonneg _) (by obtain ⟨v, hv⟩ := hane; exact ⟨v, pow_ne_zero 2 hv⟩) hcs
  refine ⟨S, hSne, ?_, ?_⟩
  · have := Finset.card_le_card hS
    rw [hsuppeq] at this
    omega
  · have hpos : (0 : ℝ) < S.card := by exact_mod_cast hSne.card_pos
    rw [div_le_iff₀ hpos]; exact hSb

end Upper2

#print axioms ker_col
#print axioms rayleigh_lower
#print axioms boundary_sum
#print axioms cut_sum
#print axioms split_abs
#print axioms sweep
#print axioms cs_step
#print axioms exists_median
#print axioms pos_neg_sq_le
#print axioms pos_neg_sq
#print axioms pos_neg_eq
#print axioms upper_from_vector

theorem conj_mul (U : Matrix V V ℝ) (hU : Uᵀ * U = 1) (a b : V → ℝ) :
    (U * diagonal a * Uᵀ) * (U * diagonal b * Uᵀ) = U * diagonal (fun k => a k * b k) * Uᵀ := by
  calc (U * diagonal a * Uᵀ) * (U * diagonal b * Uᵀ)
      = U * diagonal a * (Uᵀ * U) * diagonal b * Uᵀ := by simp only [Matrix.mul_assoc]
    _ = U * (diagonal a * diagonal b) * Uᵀ := by
        rw [hU, Matrix.mul_one, Matrix.mul_assoc U]
    _ = _ := by rw [diagonal_mul_diagonal]

theorem conj_pow (U : Matrix V V ℝ) (hU : Uᵀ * U = 1) (hU' : U * Uᵀ = 1) (a : V → ℝ) (t : ℕ) :
    (U * diagonal a * Uᵀ) ^ t = U * diagonal (fun k => a k ^ t) * Uᵀ := by
  induction t with
  | zero =>
    simp only [pow_zero]
    have : diagonal (fun _ : V => (1 : ℝ)) = 1 := diagonal_one
    rw [this, Matrix.mul_one, hU']
  | succ t ih =>
    rw [pow_succ, ih, conj_mul U hU]
    simp only [pow_succ]

theorem lazyWalk_eq (G : SimpleGraph V) [DecidableRel G.Adj] (d : ℕ) (hd : (d : ℝ) ≠ 0)
    (hreg : G.IsRegularOfDegree d) :
    lazyWalk G d = 1 - (1 / (2 * d : ℝ)) • G.lapMatrix ℝ := by
  have hA : G.adjMatrix ℝ = G.degMatrix ℝ - G.lapMatrix ℝ := by
    simp [SimpleGraph.lapMatrix]
  rw [lazyWalk, hA, SimpleGraph.IsRegularOfDegree.degMatrix_eq (G := G) ℝ hreg]
  ext u v
  simp only [Matrix.add_apply, Matrix.smul_apply, Matrix.sub_apply, Matrix.one_apply,
    Matrix.natCast_apply, smul_eq_mul]
  split_ifs
  · field_simp; ring
  · simp

#print axioms conj_mul
#print axioms conj_pow
#print axioms lazyWalk_eq

theorem lap_cast (G : SimpleGraph V) [DecidableRel G.Adj]
    (a b : V) : G.lapMatrix ℝ a b = (G.lapMatrix ℤ a b : ℝ) := by
  simp only [SimpleGraph.lapMatrix, SimpleGraph.degMatrix, Matrix.sub_apply, Matrix.diagonal_apply,
    SimpleGraph.adjMatrix_apply]
  split_ifs <;> simp

theorem fin_combo (N : ℕ) (hN : N = 10) (e : Fin N → ℝ) (hanti : Antitone e)
    (hval : ∀ j, e j = 0 ∨ e j = 2 ∨ e j = 5) (hs1 : ∑ j, e j = 30) (hs2 : ∑ j, e j ^ 2 = 120)
    (i : Fin N) (hi : (i : ℕ) + 2 = N) : e i = 2 := by
  subst hN
  have hi8 : i = 8 := Fin.ext (by simp; omega)
  subst hi8
  have hA : ∑ j, (e j - 2) * (e j - 5) = 10 := by
    have : ∀ j, (e j - 2) * (e j - 5) = e j ^ 2 - 7 * e j + 10 := fun j => by ring
    simp only [this, Finset.sum_add_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum,
      Finset.sum_const, Finset.card_univ, Fintype.card_fin, hs1, hs2]
    norm_num
  have hB : ∑ j, e j * (e j - 2) = 60 := by
    have : ∀ j, e j * (e j - 2) = e j ^ 2 - 2 * e j := fun j => by ring
    simp only [this, Finset.sum_sub_distrib, ← Finset.mul_sum, hs1, hs2]
    norm_num
  have hAnn : ∀ j, 0 ≤ (e j - 2) * (e j - 5) := by
    intro j; rcases hval j with h | h | h <;> rw [h] <;> norm_num
  have hBnn : ∀ j, 0 ≤ e j * (e j - 2) := by
    intro j; rcases hval j with h | h | h <;> rw [h] <;> norm_num
  rcases hval 8 with h8 | h8 | h8
  · exfalso
    have h9 : e 9 = 0 := by
      have := hanti (show (8 : Fin 10) ≤ 9 by decide)
      rcases hval 9 with h | h | h <;> rw [h] at this ⊢ <;> linarith
    have hsub := Finset.sum_le_sum_of_subset_of_nonneg (f := fun j => (e j - 2) * (e j - 5))
      (Finset.subset_univ ({8, 9} : Finset (Fin 10))) (fun j _ _ => hAnn j)
    rw [Finset.sum_pair (by decide), h8, h9, hA] at hsub
    norm_num at hsub
  · exact h8
  · exfalso
    have hle : ∑ j : Fin 10, (if j ≤ 8 then (15 : ℝ) else 0) ≤ ∑ j, e j * (e j - 2) := by
      refine Finset.sum_le_sum fun j _ => ?_
      split_ifs with hj
      · have h1 := hanti hj
        rw [h8] at h1
        have : e j = 5 := by rcases hval j with h | h | h <;> rw [h] at h1 ⊢ <;> linarith
        rw [this]; norm_num
      · exact hBnn j
    rw [hB, Finset.sum_ite, Finset.sum_const, Finset.sum_const_zero, add_zero,
      nsmul_eq_mul] at hle
    have : (Finset.univ.filter (fun j : Fin 10 => j ≤ 8)).card = 9 := by decide
    rw [this] at hle
    norm_num at hle

#print axioms lap_cast
#print axioms fin_combo


/-- Cheeger's inequality, the card's main claim. Let `G` be a connected network in which every
station has exactly `d` links, with `n` stations, and let `λ₂` be the second-smallest eigenvalue
of its Laplacian `L = D - A` (Mathlib's `eigenvalues₀` lists the eigenvalues largest first, so
`λ₂` is the entry at position `n - 2`). Then the edge expansion
`h = min over 1 ≤ |S| ≤ n/2 of |∂S| / |S|` satisfies `λ₂ / 2 ≤ h ≤ √(2 d λ₂)`. Written out:
every set `S` of at least one and at most half the stations has `|∂S| / |S| ≥ λ₂ / 2`, and some
such set has `|∂S| / |S| ≤ √(2 d λ₂)`. -/
theorem cheeger_inequality (G : SimpleGraph V) [DecidableRel G.Adj] (d : ℕ)
    (hreg : G.IsRegularOfDegree d) (hconn : G.Connected)
    (i : Fin (Fintype.card V)) (hi : (i : ℕ) + 2 = Fintype.card V) :
    (∀ S : Finset V, S.Nonempty → 2 * S.card ≤ Fintype.card V →
        (G.isHermitian_lapMatrix ℝ).eigenvalues₀ i / 2 ≤
          (edgeBoundary G S : ℝ) / (S.card : ℝ)) ∧
      ∃ S : Finset V, S.Nonempty ∧ 2 * S.card ≤ Fintype.card V ∧
        (edgeBoundary G S : ℝ) / (S.card : ℝ) ≤
          Real.sqrt (2 * d * (G.isHermitian_lapMatrix ℝ).eigenvalues₀ i) := by
  obtain ⟨k₀, k₁, hne, h1, h0, hk⟩ := sorted_facts (G.isHermitian_lapMatrix ℝ) i hi
  have hpos := gap_pos hconn i hi
  obtain ⟨hμ0, c, hc, hcn⟩ := ker_col k₀ _ hpos hk
  set lam := (G.isHermitian_lapMatrix ℝ).eigenvalues₀ i with hlam
  constructor
  · intro S hS h2
    set n : ℝ := (Fintype.card V : ℝ) with hn
    set s : ℝ := (S.card : ℝ) with hs
    have hsn : S.card ≤ Fintype.card V := Finset.card_le_univ S
    have hspos : 0 < s := by rw [hs]; exact_mod_cast hS.card_pos
    have hnpos : 0 < n := by rw [hn]; exact_mod_cast Fintype.card_pos_iff.2 ⟨hS.choose⟩
    have h2' : 2 * s ≤ n := by rw [hs, hn]; exact_mod_cast h2
    have hite : ∀ a b : ℝ, ∑ v, (if v ∈ S then a else b) = s * a + (n - s) * b := by
      intro a b
      rw [Finset.sum_ite, Finset.sum_const, Finset.sum_const, Finset.filter_mem_eq_inter,
        Finset.univ_inter, nsmul_eq_mul, nsmul_eq_mul]
      have : Finset.univ.filter (fun v => v ∉ S) = Sᶜ := by ext; simp
      rw [this, Finset.card_compl, Nat.cast_sub hsn]
    let x : V → ℝ := fun v => if v ∈ S then n - s else -s
    have hx : ∑ v, x v = 0 := by
      show ∑ v, (if v ∈ S then n - s else -s) = 0
      rw [hite]; ring
    have hray := rayleigh_lower k₀ lam c hk hc x hx
    have hxx : x ⬝ᵥ x = s * (n - s) ^ 2 + (n - s) * s ^ 2 := by
      rw [dotProduct]
      have : ∀ v, x v * x v = if v ∈ S then (n - s) ^ 2 else s ^ 2 := by
        intro v
        show (if v ∈ S then n - s else -s) * (if v ∈ S then n - s else -s) = _
        split_ifs <;> ring
      simp only [this]; rw [hite]
    have hxLx : x ⬝ᵥ (G.lapMatrix ℝ *ᵥ x) = n ^ 2 * edgeBoundary G S := by
      rw [lap_quad]
      have := cut_sum (G := G) S (n - s) (-s) (fun t => t ^ 2) (by simp) (by ring)
      show (∑ i, ∑ j, if G.Adj i j then
        ((if i ∈ S then n - s else -s) - (if j ∈ S then n - s else -s)) ^ 2 else 0) / 2 = _
      rw [this]; ring
    rw [hxx, hxLx] at hray
    have e1 : (lam * s * (n - s)) * n ≤ (n * edgeBoundary G S) * n := by
      have : lam * (s * (n - s) ^ 2 + (n - s) * s ^ 2) = (lam * s * (n - s)) * n := by ring
      have h' : n ^ 2 * (edgeBoundary G S : ℝ) = (n * edgeBoundary G S) * n := by ring
      linarith
    have e2 := le_of_mul_le_mul_right e1 hnpos
    have e3 : lam * s * (n / 2) ≤ lam * s * (n - s) :=
      mul_le_mul_of_nonneg_left (by linarith) (by positivity)
    rw [le_div_iff₀ hspos]
    nlinarith
  · obtain ⟨U, hU⟩ : ∃ U, U = ((G.isHermitian_lapMatrix ℝ).eigenvectorUnitary : Matrix V V ℝ) :=
      ⟨_, rfl⟩
    have o01 := col_orth (G.isHermitian_lapMatrix ℝ) k₀ k₁
    have o11 := col_orth (G.isHermitian_lapMatrix ℝ) k₁ k₁
    have hq := col_quad (G := G) k₁
    simp only at hq
    rw [← hU] at o01 o11 hc hq
    simp only [hne.symm, ↓reduceIte, hc] at o01 o11
    rw [← Finset.mul_sum] at o01
    have hc0 : c ≠ 0 := by intro h; rw [h] at hcn; simp at hcn
    have hfs : ∑ v, U v k₁ = 0 := by
      rcases mul_eq_zero.1 o01 with h | h
      · exact absurd h hc0
      · exact h
    have hf0 : ∃ v, U v k₁ ≠ 0 := by
      by_contra hall; push Not at hall
      simp [hall] at o11
    apply upper_from_vector hreg lam hpos.le (fun v => U v k₁) hf0 hfs
    rw [lap_quad] at hq
    simp only [sq] at hq ⊢
    rw [o11]
    rw [h1] at hq
    linarith

/-- The mixing guarantee. On a connected network where every station has exactly `d` links,
with `n` stations and spectral gap `λ₂`, the lazy walk started at any station `u` is within
total variation distance `1/4` of the even spread `1/n` after any number of steps
`t ≥ (2d / λ₂) ln(2 √n)`. The distance is `½ Σ_v |Pᵗ(u, v) - 1/n|`. -/
theorem lazy_walk_mixes_within_spectral_bound (G : SimpleGraph V) [DecidableRel G.Adj] (d : ℕ)
    (hreg : G.IsRegularOfDegree d) (hconn : G.Connected)
    (i : Fin (Fintype.card V)) (hi : (i : ℕ) + 2 = Fintype.card V)
    (u : V) (t : ℕ)
    (ht : 2 * (d : ℝ) / (G.isHermitian_lapMatrix ℝ).eigenvalues₀ i *
        Real.log (2 * Real.sqrt (Fintype.card V)) ≤ t) :
    (1 / 2 : ℝ) * ∑ v, |(lazyWalk G d ^ t) u v - 1 / (Fintype.card V : ℝ)| ≤ 1 / 4 := by
  obtain ⟨k₀, k₁, hne, h1, h0, hk⟩ := sorted_facts (G.isHermitian_lapMatrix ℝ) i hi
  have hpos := gap_pos hconn i hi
  obtain ⟨hμ0, c, hc, hcn⟩ := ker_col k₀ _ hpos hk
  have hle := lap_eig_le hreg k₁
  have hall_le := fun k => lap_eig_le hreg k (G := G)
  have hnn := fun k => lap_eig_nonneg G k
  have hspec := spec_U (G.isHermitian_lapMatrix ℝ)
  have hUtU := UtU (G.isHermitian_lapMatrix ℝ)
  have hUUt := UUt (G.isHermitian_lapMatrix ℝ)
  have hrow := row_orth (G.isHermitian_lapMatrix ℝ) u u
  generalize (G.isHermitian_lapMatrix ℝ).eigenvalues₀ i = lam at *
  generalize ((G.isHermitian_lapMatrix ℝ).eigenvectorUnitary : Matrix V V ℝ) = U at *
  generalize (G.isHermitian_lapMatrix ℝ).eigenvalues = μ at *
  rw [h1] at hle
  have hdpos : (0 : ℝ) < d := by linarith
  set n : ℝ := (Fintype.card V : ℝ) with hn
  have hnpos : 0 < n := by rw [hn]; exact_mod_cast Fintype.card_pos_iff.2 ⟨u⟩
  set ρ : ℝ := 1 - lam / (2 * d) with hρ
  have hρ0 : 0 ≤ ρ := by
    rw [hρ, sub_nonneg, div_le_one (by positivity)]; exact hle
  -- the walk in the eigenbasis
  set ν : V → ℝ := fun k => 1 - (1 / (2 * d : ℝ)) * μ k with hν
  have hP : lazyWalk G d = U * diagonal ν * Uᵀ := by
    rw [lazyWalk_eq G d hdpos.ne' hreg]
    have : diagonal ν = 1 - (1 / (2 * d : ℝ)) • diagonal μ := by
      ext a b
      simp only [ν, diagonal_apply, Matrix.sub_apply, Matrix.one_apply, Matrix.smul_apply,
        smul_eq_mul]
      split_ifs <;> ring
    rw [this, Matrix.mul_sub, Matrix.sub_mul, Matrix.mul_one, hUUt, Matrix.mul_smul,
      Matrix.smul_mul, ← hspec]
  set δ : V → ℝ := Pi.single k₀ 1 with hδ
  have hJ : (Matrix.of fun _ _ => 1 / n : Matrix V V ℝ) = U * diagonal δ * Uᵀ := by
    ext a b
    rw [Matrix.mul_apply, Finset.sum_eq_single k₀]
    · simp only [Matrix.mul_diagonal, Matrix.transpose_apply, δ, Pi.single_eq_same, mul_one,
        hc, Matrix.of_apply]
      field_simp
      linarith [hcn]
    · intro k _ hk'
      simp [Matrix.mul_diagonal, δ, Pi.single_eq_of_ne hk']
    · simp
  set ε : V → ℝ := fun k => ν k ^ t - δ k with hε
  have hM : lazyWalk G d ^ t - (Matrix.of fun _ _ => 1 / n : Matrix V V ℝ) = U * diagonal ε * Uᵀ := by
    rw [hP, conj_pow U hUtU hUUt, hJ, ← Matrix.sub_mul, ← Matrix.mul_sub, diagonal_sub]
  set Mx := lazyWalk G d ^ t - (Matrix.of fun _ _ => 1 / n : Matrix V V ℝ) with hMx
  have hentry : ∀ v, (lazyWalk G d ^ t) u v - 1 / n = Mx u v := fun v => by simp [Mx]
  have hsymm : ∀ a b, Mx a b = Mx b a := by
    intro a b
    rw [hM, Matrix.mul_apply, Matrix.mul_apply]
    simp only [Matrix.mul_diagonal, Matrix.transpose_apply]
    exact Finset.sum_congr rfl fun k _ => by ring
  have hsq : ∑ v, Mx u v ^ 2 = ∑ k, U u k * (ε k * ε k) * U u k := by
    have h2 : Mx * Mx = U * diagonal (fun k => ε k * ε k) * Uᵀ := by
      rw [hM, conj_mul U hUtU]
    have := congrFun (congrFun h2 u) u
    rw [Matrix.mul_apply, Matrix.mul_apply] at this
    simp only [Matrix.mul_diagonal, Matrix.transpose_apply] at this
    rw [← this]
    exact Finset.sum_congr rfl fun v _ => by rw [hsymm v u]; ring
  have hεle : ∀ k, ε k * ε k ≤ (ρ ^ t) ^ 2 := by
    intro k
    by_cases hk' : k = k₀
    · subst hk'
      have : ε k = 0 := by simp [ε, ν, δ, hμ0]
      rw [this, mul_zero]; positivity
    · have hδk : δ k = 0 := by simp [δ, Pi.single_eq_of_ne hk']
      have hν0 : 0 ≤ ν k := by
        simp only [ν]
        have := hall_le k
        rw [sub_nonneg, one_div, inv_mul_le_iff₀ (by positivity)]; linarith
      have hνρ : ν k ≤ ρ := by
        simp only [ν, hρ]
        have := hk k hk'
        have : lam / (2 * d) ≤ 1 / (2 * d) * μ k := by
          rw [div_eq_mul_one_div, mul_comm]
          exact mul_le_mul_of_nonneg_left this (by positivity)
        linarith
      simp only [ε, hδk, sub_zero]
      rw [← sq]
      exact pow_le_pow_left₀ (pow_nonneg hν0 t) (pow_le_pow_left₀ hν0 hνρ t) 2
  have hsum2 : ∑ v, Mx u v ^ 2 ≤ (ρ ^ t) ^ 2 := by
    rw [hsq]
    calc ∑ k, U u k * (ε k * ε k) * U u k ≤ ∑ k, (ρ ^ t) ^ 2 * (U u k * U u k) :=
          Finset.sum_le_sum fun k _ => by
            have := hεle k
            nlinarith [mul_self_nonneg (U u k)]
      _ = (ρ ^ t) ^ 2 := by rw [← Finset.mul_sum, hrow]; simp
  -- Cauchy-Schwarz
  have hcs : (∑ v, |Mx u v|) ^ 2 ≤ n * ∑ v, |Mx u v| ^ 2 := by
    have := sq_sum_le_card_mul_sum_sq (s := Finset.univ) (f := fun v => |Mx u v|)
    simpa [hn] using this
  simp only [sq_abs] at hcs
  have hsum1 : ∑ v, |Mx u v| ≤ Real.sqrt n * ρ ^ t := by
    have hnn' : 0 ≤ ∑ v, |Mx u v| := Finset.sum_nonneg fun v _ => abs_nonneg _
    rw [← pow_le_pow_iff_left₀ hnn' (by positivity) (by norm_num : (2:ℕ) ≠ 0), mul_pow,
      Real.sq_sqrt hnpos.le]
    calc _ ≤ n * ∑ v, Mx u v ^ 2 := hcs
      _ ≤ n * (ρ ^ t) ^ 2 := mul_le_mul_of_nonneg_left hsum2 hnpos.le
  -- the exponential bound
  have hsqrt : 0 < Real.sqrt n := Real.sqrt_pos.2 hnpos
  have hlog : Real.log (2 * Real.sqrt n) ≤ t * (lam / (2 * d)) := by
    have hx : 0 < lam / (2 * d) := by positivity
    have := mul_le_mul_of_nonneg_right ht hx.le
    have e : 2 * (d : ℝ) / lam * Real.log (2 * Real.sqrt n) * (lam / (2 * d)) =
        Real.log (2 * Real.sqrt n) := by field_simp
    rw [e] at this; exact this
  have hρexp : ρ ^ t ≤ 1 / (2 * Real.sqrt n) := by
    calc ρ ^ t ≤ Real.exp (-(lam / (2 * d))) ^ t := by
          apply pow_le_pow_left₀ hρ0
          have := Real.add_one_le_exp (-(lam / (2 * d)))
          rw [hρ]; linarith
      _ = Real.exp (-(t * (lam / (2 * d)))) := by
          rw [← Real.exp_nat_mul]; ring_nf
      _ ≤ Real.exp (-(Real.log (2 * Real.sqrt n))) := Real.exp_le_exp.2 (by linarith)
      _ = 1 / (2 * Real.sqrt n) := by
          rw [Real.exp_neg, Real.exp_log (by positivity), one_div]
  simp only [hentry]
  calc (1 / 2 : ℝ) * ∑ v, |Mx u v| ≤ 1 / 2 * (Real.sqrt n * (1 / (2 * Real.sqrt n))) := by
        apply mul_le_mul_of_nonneg_left _ (by norm_num)
        exact hsum1.trans (mul_le_mul_of_nonneg_left hρexp hsqrt.le)
    _ = 1 / 4 := by field_simp; ring

/-! ## The 10-station pilot (the Petersen graph)

Stations `0`–`4` are the outer ring, `5`–`9` the inner five-pointed star; station `i` on the ring
has a spoke to station `i + 5`. These are the card's lists:
outer `i` links to `i ± 1 (mod 5)` and `i + 5`; inner `5 + i` links to `5 + (i ± 2 mod 5)` and `i`. -/

/-- The pilot's links, as a yes/no table. -/
def pilotAdj (a b : Fin 10) : Bool :=
  if a.val < 5 then
    b.val = (a.val + 1) % 5 || b.val = (a.val + 4) % 5 || b.val = a.val + 5
  else
    b.val = 5 + (a.val + 2) % 5 || b.val = 5 + (a.val + 3) % 5 || b.val + 5 = a.val

/-- The pilot network. -/
def pilot : SimpleGraph (Fin 10) where
  Adj a b := pilotAdj a b = true
  symm := ⟨by decide⟩
  loopless := ⟨by decide⟩

instance : DecidableRel pilot.Adj := fun a b =>
  inferInstanceAs (Decidable (pilotAdj a b = true))

theorem pilot_lap_sq_int : ∀ a b : Fin 10,
    (pilot.lapMatrix ℤ * pilot.lapMatrix ℤ) a b =
      7 * pilot.lapMatrix ℤ a b - 10 * (if a = b then 1 else 0) + 1 := by
  decide +kernel

theorem pilot_trace_int : ∑ a, pilot.lapMatrix ℤ a a = 30 := by decide +kernel

#print axioms pilot_lap_sq_int
#print axioms pilot_trace_int

/-- Step 4 of the card: on the pilot every number is exact. Its spectral gap, the
second-smallest eigenvalue of `L = D - A`, is exactly `2`. -/
theorem pilot_spectral_gap_eq_two (i : Fin (Fintype.card (Fin 10)))
    (hi : (i : ℕ) + 2 = Fintype.card (Fin 10)) :
    (pilot.isHermitian_lapMatrix ℝ).eigenvalues₀ i = 2 := by
  have hL := pilot.isHermitian_lapMatrix ℝ
  have hLL : ∀ a b, (pilot.lapMatrix ℝ * pilot.lapMatrix ℝ) a b =
      7 * pilot.lapMatrix ℝ a b - 10 * (if a = b then 1 else 0) + 1 := by
    intro a b
    have := pilot_lap_sq_int a b
    rw [Matrix.mul_apply] at this ⊢
    simp only [lap_cast]
    exact_mod_cast this
  -- every eigenvalue is 0, 2 or 5
  have heig : ∀ k, (pilot.isHermitian_lapMatrix ℝ).eigenvalues k = 0 ∨
      (pilot.isHermitian_lapMatrix ℝ).eigenvalues k = 2 ∨
      (pilot.isHermitian_lapMatrix ℝ).eigenvalues k = 5 := by
    intro k
    have hb := col_eigen (pilot.isHermitian_lapMatrix ℝ) k
    have hnorm := col_orth (pilot.isHermitian_lapMatrix ℝ) k k
    simp only [↓reduceIte] at hnorm
    generalize ((pilot.isHermitian_lapMatrix ℝ).eigenvectorUnitary : Matrix (Fin 10) (Fin 10) ℝ)
      = U at hb hnorm
    generalize (pilot.isHermitian_lapMatrix ℝ).eigenvalues k = μ at hb ⊢
    set b : Fin 10 → ℝ := fun v => U v k with hbdef
    have hcol : ∀ w, ∑ v, pilot.lapMatrix ℝ v w = 0 := by
      intro w
      have := congrFun (SimpleGraph.lapMatrix_mulVec_one_eq_zero (G := pilot) ℝ) w
      simp only [Matrix.mulVec, dotProduct, Pi.one_apply, mul_one, Pi.zero_apply] at this
      rw [← this]
      exact Finset.sum_congr rfl fun v _ => (SimpleGraph.isSymm_lapMatrix ℝ pilot).apply w v
    have hsum : μ * ∑ v, b v = 0 := by
      have h1 : ∑ v, (pilot.lapMatrix ℝ *ᵥ b) v = 0 := by
        simp only [Matrix.mulVec, dotProduct]
        rw [Finset.sum_comm]
        simp only [← Finset.sum_mul, hcol, zero_mul, Finset.sum_const_zero]
      rw [hb] at h1
      rw [Finset.mul_sum]; exact h1
    have hquad : ∀ v, μ ^ 2 * b v = 7 * μ * b v - 10 * b v + ∑ w, b w := by
      intro v
      have e1 : ((pilot.lapMatrix ℝ * pilot.lapMatrix ℝ) *ᵥ b) v = μ ^ 2 * b v := by
        rw [← Matrix.mulVec_mulVec, hb]
        have : (pilot.lapMatrix ℝ *ᵥ fun v => μ * b v) = μ • (pilot.lapMatrix ℝ *ᵥ b) := by
          rw [← Matrix.mulVec_smul]; rfl
        rw [this, hb]; simp only [Pi.smul_apply, smul_eq_mul]; ring
      have e2 : ((pilot.lapMatrix ℝ * pilot.lapMatrix ℝ) *ᵥ b) v =
          7 * (pilot.lapMatrix ℝ *ᵥ b) v - 10 * b v + ∑ w, b w := by
        simp only [Matrix.mulVec, dotProduct, hLL, add_mul, sub_mul, Finset.sum_add_distrib,
          Finset.sum_sub_distrib, mul_assoc, ← Finset.mul_sum, one_mul, ite_mul, zero_mul,
          Finset.sum_ite_eq, Finset.mem_univ, ↓reduceIte, one_mul]
      rw [← e1, e2, hb]; simp only [hbdef]; ring
    by_cases hμ : μ = 0
    · exact Or.inl hμ
    · right
      have hs0 : ∑ v, b v = 0 := by
        rcases mul_eq_zero.1 hsum with h | h
        · exact absurd h hμ
        · exact h
      obtain ⟨v, hv⟩ : ∃ v, b v ≠ 0 := by
        by_contra hall; push Not at hall
        simp [b, hall] at hnorm
      have := hquad v
      rw [hs0, add_zero] at this
      have h2 : (μ - 2) * (μ - 5) * b v = 0 := by linarith
      rcases mul_eq_zero.1 h2 with h | h
      · rcases mul_eq_zero.1 h with h | h
        · left; linarith
        · right; linarith
      · exact absurd h hv
  -- trace facts
  have hs1 : ∑ k, (pilot.isHermitian_lapMatrix ℝ).eigenvalues k = 30 := by
    have := (pilot.isHermitian_lapMatrix ℝ).trace_eq_sum_eigenvalues
    simp only [RCLike.ofReal_real_eq_id, id] at this
    rw [← this, Matrix.trace]
    simp only [Matrix.diag_apply, lap_cast]
    exact_mod_cast pilot_trace_int
  have hs2 : ∑ k, (pilot.isHermitian_lapMatrix ℝ).eigenvalues k ^ 2 = 120 := by
    have hsq : pilot.lapMatrix ℝ * pilot.lapMatrix ℝ =
        ((pilot.isHermitian_lapMatrix ℝ).eigenvectorUnitary : Matrix (Fin 10) (Fin 10) ℝ) *
          diagonal (fun k => (pilot.isHermitian_lapMatrix ℝ).eigenvalues k *
            (pilot.isHermitian_lapMatrix ℝ).eigenvalues k) *
          ((pilot.isHermitian_lapMatrix ℝ).eigenvectorUnitary : Matrix (Fin 10) (Fin 10) ℝ)ᵀ := by
      conv_lhs => rw [spec_U (pilot.isHermitian_lapMatrix ℝ)]
      rw [conj_mul _ (UtU _)]
    have htr : Matrix.trace (pilot.lapMatrix ℝ * pilot.lapMatrix ℝ) = 120 := by
      rw [Matrix.trace]
      simp only [Matrix.diag_apply, hLL]
      have : ∑ a : Fin 10, pilot.lapMatrix ℝ a a = 30 := by
        simp only [lap_cast]; exact_mod_cast pilot_trace_int
      simp only [Finset.sum_add_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum, this,
        ↓reduceIte, Finset.sum_const, Finset.card_univ, Fintype.card_fin]
      norm_num
    rw [hsq, Matrix.trace_mul_comm, ← Matrix.mul_assoc, UtU, Matrix.one_mul,
      Matrix.trace_diagonal] at htr
    rw [← htr]
    exact Finset.sum_congr rfl fun k _ => sq _
  -- move to the sorted list
  set e := (Fintype.equivOfCardEq (Fintype.card_fin (Fintype.card (Fin 10))) :
    Fin (Fintype.card (Fin 10)) ≃ Fin 10)
  have hev : ∀ j, (pilot.isHermitian_lapMatrix ℝ).eigenvalues₀ j =
      (pilot.isHermitian_lapMatrix ℝ).eigenvalues (e j) := by
    intro j; simp [Matrix.IsHermitian.eigenvalues, e]
  apply fin_combo (Fintype.card (Fin 10)) (Fintype.card_fin 10)
    (pilot.isHermitian_lapMatrix ℝ).eigenvalues₀
    (pilot.isHermitian_lapMatrix ℝ).eigenvalues₀_antitone
  · intro j; rw [hev]; exact heig _
  · rw [← hs1]
    simp only [hev]
    exact Equiv.sum_comp e (fun k => (pilot.isHermitian_lapMatrix ℝ).eigenvalues k)
  · rw [← hs2]
    simp only [hev]
    exact Equiv.sum_comp e (fun k => (pilot.isHermitian_lapMatrix ℝ).eigenvalues k ^ 2)
  · exact hi

-- Every station has 3 lanes; 15 lanes in all.
example : pilot.IsRegularOfDegree 3 := by
  intro v; revert v; decide

-- Sets to check: 10 + 45 + 120 + 210 + 252 = 637 sets of 1 to 5 stations.
example : (Finset.univ.filter fun S : Finset (Fin 10) => 1 ≤ S.card ∧ S.card ≤ 5).card = 637 := by
  decide +kernel

-- One station alone: 3 lanes out.
example : edgeBoundary pilot {0} = 3 := by decide

-- The inner star alone: 5 spokes out of 5 stations.
example : edgeBoundary pilot {5, 6, 7, 8, 9} = 5 := by decide

-- The outer loop of five: also 5 lanes out.
example : edgeBoundary pilot {0, 1, 2, 3, 4} = 5 := by decide

-- Brute force: every set of 1 to 5 stations has at least one lane out per station (h ≥ 1) ...
example : ∀ S : Finset (Fin 10), 1 ≤ S.card → S.card ≤ 5 → S.card ≤ edgeBoundary pilot S := by
  decide +kernel

-- ... and exactly 12 of the 637 sets tie at one lane per station (so h = 1).
example : (Finset.univ.filter fun S : Finset (Fin 10) =>
    1 ≤ S.card ∧ S.card ≤ 5 ∧ edgeBoundary pilot S = S.card).card = 12 := by
  decide +kernel

-- Two-step routes: A² + A - 2I = J at every entry.
example : pilot.adjMatrix ℤ * pilot.adjMatrix ℤ + pilot.adjMatrix ℤ - 2 • (1 : Matrix (Fin 10) (Fin 10) ℤ) =
    Matrix.of fun _ _ => 1 := by
  decide +kernel

-- The eigenvalues off the flat pattern solve μ² + μ - 2 = 0: μ = 1 or μ = -2; gap 3 - 1 = 2.
example : (1 : ℤ) ^ 2 + 1 - 2 = 0 ∧ (-2 : ℤ) ^ 2 + (-2) - 2 = 0 ∧ (3 : ℤ) - 1 = 2 := by decide

-- Cheeger on the pilot: 2 / 2 = 1, and 2 × 3 × 2 = 12 under the square root.
example : (2 : ℚ) / 2 = 1 ∧ 2 * 3 * 2 = 12 := by norm_num

#print axioms cheeger_inequality
#print axioms lazy_walk_mixes_within_spectral_bound
#print axioms pilot_spectral_gap_eq_two

end ExpandersAndMixing
