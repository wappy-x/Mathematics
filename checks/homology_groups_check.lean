-- Homology groups: for a finite simplicial complex with rational coefficients, the k-th Betti number is (simplices - rank of the k-th boundary) - rank of the next boundary, the zeroth counts pieces, and the alternating sum is the Euler characteristic.
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.LinearAlgebra.Quotient.Basic
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Connected
import Mathlib.Tactic.NormNum

namespace HomologyGroups

open Finset

variable {V : Type*} [LinearOrder V]

/-- The k-simplices of a family of simplices: those with k + 1 corners. -/
def simplices (K : Finset (Finset V)) (k : ℕ) : Finset (Finset V) :=
  K.filter (fun s => s.card = k + 1)

/-- A finite simplicial complex: every face of every simplex is in the complex. -/
def IsComplex (K : Finset (Finset V)) : Prop :=
  ∀ s ∈ K, ∀ t ⊆ s, t.Nonempty → t ∈ K

/-- The signed coefficient of the face `t` in the boundary of the simplex `s`, corners listed in
increasing order: dropping the corner `v` gets sign `(-1)^i`, where `i` is the number of corners
of `s` below `v`. -/
def bdCoeff (s t : Finset V) : ℤ :=
  ∑ v ∈ s, if s.erase v = t then (-1) ^ (s.filter (· < v)).card else 0

/-- The k-chains with rational coefficients: one entry per k-simplex. -/
abbrev Chains (K : Finset (Finset V)) (k : ℕ) := (simplices K k) → ℚ

/-- The boundary matrix of `∂_{k+1}`: rows are the k-simplices, columns the (k+1)-simplices. -/
def bdMatrix (K : Finset (Finset V)) (k : ℕ) :
    Matrix (simplices K k) (simplices K (k + 1)) ℚ :=
  fun t s => (bdCoeff s.1 t.1 : ℚ)

/-- The boundary map `∂_{k+1} : C_{k+1} → C_k`. -/
def bd (K : Finset (Finset V)) (k : ℕ) : Chains K (k + 1) →ₗ[ℚ] Chains K k :=
  (bdMatrix K k).mulVecLin

/-- The k-cycles `Z_k = ker ∂_k`; every 0-chain is a cycle, since `∂_0 = 0`. -/
def cycles (K : Finset (Finset V)) : (k : ℕ) → Submodule ℚ (Chains K k)
  | 0 => ⊤
  | k + 1 => LinearMap.ker (bd K k)

/-- The k-boundaries `B_k = im ∂_{k+1}`. -/
def boundaries (K : Finset (Finset V)) (k : ℕ) : Submodule ℚ (Chains K k) :=
  LinearMap.range (bd K k)

/-- The k-th homology group `H_k = Z_k / B_k` over the rationals. -/
abbrev Homology (K : Finset (Finset V)) (k : ℕ) :=
  ↥(cycles K k) ⧸ (boundaries K k).comap (cycles K k).subtype

/-- The k-th Betti number over the rationals: the dimension of `H_k`. -/
noncomputable def betti (K : Finset (Finset V)) (k : ℕ) : ℕ :=
  Module.finrank ℚ (Homology K k)

/-- The rank of `∂_k`, with `∂_0 = 0`. -/
noncomputable def bdRank (K : Finset (Finset V)) : ℕ → ℕ
  | 0 => 0
  | k + 1 => (bdMatrix K k).rank

/-- The corners and edges of the complex as a graph: two corners are joined when they span an edge. -/
def skeleton (K : Finset (Finset V)) : SimpleGraph {v : V // ({v} : Finset V) ∈ K} :=
  SimpleGraph.fromRel (fun u v => ({u.1, v.1} : Finset V) ∈ K)

/-- Removing two corners in either order gives opposite signs. -/
theorem sign_swap (u : Finset V) {v w : V} (hw : w ∈ u) (hwv : w < v) :
    (-1 : ℤ) ^ (u.filter (· < v)).card * (-1) ^ ((u.erase v).filter (· < w)).card
      = -((-1 : ℤ) ^ (u.filter (· < w)).card * (-1) ^ ((u.erase w).filter (· < v)).card) := by
  have h1 : (u.erase v).filter (· < w) = u.filter (· < w) := by
    rw [Finset.filter_erase]
    apply Finset.erase_eq_of_notMem
    simp only [Finset.mem_filter, not_and, not_lt]
    exact fun _ => hwv.le
  have hmem : w ∈ u.filter (· < v) := Finset.mem_filter.2 ⟨hw, hwv⟩
  have h2 : ((u.erase w).filter (· < v)).card = (u.filter (· < v)).card - 1 := by
    rw [Finset.filter_erase, Finset.card_erase_of_mem hmem]
  have hpos : 0 < (u.filter (· < v)).card := Finset.card_pos.2 ⟨w, hmem⟩
  rw [h1, h2]
  obtain ⟨n, hn⟩ : ∃ n, (u.filter (· < v)).card = n + 1 := ⟨_, (Nat.succ_pred_eq_of_pos hpos).symm⟩
  rw [hn, Nat.add_sub_cancel, pow_succ]
  ring

/-- Expanding the boundary of `u` against a family `F` holding all its facets. -/
theorem sum_bdCoeff_mul {R : Type*} [CommRing R] (u : Finset V) (F : Finset (Finset V))
    (hF : ∀ v ∈ u, u.erase v ∈ F) (f : Finset V → R) :
    ∑ s ∈ F, (bdCoeff u s : R) * f s
      = ∑ v ∈ u, (-1 : R) ^ (u.filter (· < v)).card * f (u.erase v) := by
  simp only [bdCoeff, Int.cast_sum, Finset.sum_mul]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun v hv => ?_
  simp only [apply_ite (fun x : ℤ => (x : R)), Int.cast_pow, Int.cast_neg, Int.cast_one,
    Int.cast_zero, ite_mul, zero_mul]
  rw [Finset.sum_ite_eq]; simp [hF v hv]

/-- The boundary of a boundary is zero, one face at a time. -/
theorem sum_sign_bdCoeff_erase (u t : Finset V) :
    ∑ v ∈ u, (-1 : ℤ) ^ (u.filter (· < v)).card * bdCoeff (u.erase v) t = 0 := by
  set g : V → V → ℤ := fun v w => if w = v then 0 else
    (-1 : ℤ) ^ (u.filter (· < v)).card *
      (if (u.erase v).erase w = t then (-1) ^ ((u.erase v).filter (· < w)).card else 0) with hg
  have hrow : ∀ v ∈ u, (-1 : ℤ) ^ (u.filter (· < v)).card * bdCoeff (u.erase v) t
      = ∑ w ∈ u, g v w := by
    intro v hv
    rw [bdCoeff, Finset.mul_sum, ← Finset.sum_erase u (f := g v) (a := v) (by simp [hg])]
    refine Finset.sum_congr rfl fun w hw => ?_
    simp [hg, (Finset.mem_erase.1 hw).1]
  have hanti : ∀ v ∈ u, ∀ w ∈ u, g w v = -g v w := by
    intro v hv w hw
    by_cases hvw : w = v
    · subst hvw; simp [hg]
    have hvw' : v ≠ w := Ne.symm hvw
    simp only [hg, hvw, hvw', ↓reduceIte, Finset.erase_right_comm (s := u) (a := w) (b := v)]
    by_cases ht : (u.erase v).erase w = t
    · simp only [ht, ↓reduceIte]
      rcases lt_or_gt_of_ne hvw with h | h
      · rw [sign_swap u hw h]; ring
      · rw [sign_swap u hv h]
    · simp [ht]
  have hS : ∑ v ∈ u, (-1 : ℤ) ^ (u.filter (· < v)).card * bdCoeff (u.erase v) t
      = ∑ v ∈ u, ∑ w ∈ u, g v w := Finset.sum_congr rfl hrow
  have hneg : ∑ v ∈ u, ∑ w ∈ u, g v w = -∑ v ∈ u, ∑ w ∈ u, g v w := by
    conv_lhs => rw [Finset.sum_comm]
    rw [← Finset.sum_neg_distrib]
    refine Finset.sum_congr rfl fun v hv => ?_
    rw [← Finset.sum_neg_distrib]
    exact Finset.sum_congr rfl fun w hw => hanti v hv w hw
  rw [hS]
  linarith

/-- `∂_{k+1} ∘ ∂_{k+2} = 0` as matrices. -/
theorem bdMatrix_mul_bdMatrix (K : Finset (Finset V)) (hK : IsComplex K) (k : ℕ) :
    bdMatrix K k * bdMatrix K (k + 1) = 0 := by
  ext t u
  simp only [Matrix.mul_apply, bdMatrix, Matrix.zero_apply]
  have hu := Finset.mem_filter.1 u.2
  have hF : ∀ v ∈ u.1, u.1.erase v ∈ simplices K (k + 1) := by
    intro v hv
    have hc : (u.1.erase v).card = k + 1 + 1 := by
      rw [Finset.card_erase_of_mem hv, hu.2]; omega
    refine Finset.mem_filter.2 ⟨hK _ hu.1 _ (Finset.erase_subset _ _) ?_, hc⟩
    exact Finset.card_pos.1 (by omega)
  have := sum_bdCoeff_mul (R := ℚ) u.1 (simplices K (k + 1)) hF (fun s => (bdCoeff s t.1 : ℚ))
  rw [Finset.sum_coe_sort (simplices K (k + 1))
    (fun s => (bdCoeff s t.1 : ℚ) * (bdCoeff u.1 s : ℚ))]
  simp_rw [mul_comm (bdCoeff _ t.1 : ℚ)]
  rw [this]
  exact_mod_cast sum_sign_bdCoeff_erase u.1 t.1

/-- Every boundary is a cycle. -/
theorem boundaries_le_cycles (K : Finset (Finset V)) (hK : IsComplex K) (k : ℕ) :
    boundaries K k ≤ cycles K k := by
  cases k with
  | zero => exact le_top
  | succ k =>
    show LinearMap.range (bd K (k + 1)) ≤ LinearMap.ker (bd K k)
    rw [LinearMap.range_le_ker_iff, bd, bd, ← Matrix.mulVecLin_mul,
      bdMatrix_mul_bdMatrix K hK k]
    ext; simp

/-- The rank count in natural numbers: `β_k + rank ∂_{k+1} + rank ∂_k = n_k`. -/
theorem betti_add_bdRank_add_bdRank (K : Finset (Finset V)) (hK : IsComplex K) (k : ℕ) :
    betti K k + bdRank K (k + 1) + bdRank K k = (simplices K k).card := by
  have h1 : betti K k + Module.finrank ℚ (boundaries K k) = Module.finrank ℚ (cycles K k) := by
    unfold betti
    rw [← Submodule.finrank_quotient_add_finrank
      ((boundaries K k).comap (cycles K k).subtype)]
    congr 1
    exact (Submodule.comapSubtypeEquivOfLe (boundaries_le_cycles K hK k)).finrank_eq.symm
  have h2 : Module.finrank ℚ (boundaries K k) = bdRank K (k + 1) := rfl
  have h3 : Module.finrank ℚ (cycles K k) + bdRank K k = (simplices K k).card := by
    cases k with
    | zero =>
      show Module.finrank ℚ (⊤ : Submodule ℚ (Chains K 0)) + 0 = _
      rw [finrank_top, Module.finrank_fintype_fun_eq_card, Fintype.card_coe, add_zero]
    | succ k =>
      show Module.finrank ℚ (LinearMap.ker (bd K k)) + Module.finrank ℚ (LinearMap.range (bd K k)) = _
      rw [add_comm, LinearMap.finrank_range_add_finrank_ker, Module.finrank_fintype_fun_eq_card,
        Fintype.card_coe]
  omega

/-- The boundary of an edge `{a, b}` with `a < b`, applied through the transpose, is `f b - f a`. -/
theorem transpose_mulVec_edge (K : Finset (Finset V)) (f : Chains K 0)
    (e : simplices K 1) (a b : V) (hab : a < b) (he : e.1 = {a, b})
    (ha : ({a} : Finset V) ∈ simplices K 0) (hb : ({b} : Finset V) ∈ simplices K 0) :
    ((Matrix.transpose (bdMatrix K 0)).mulVecLin f) e = f ⟨{b}, hb⟩ - f ⟨{a}, ha⟩ := by
  set ext : Finset V → ℚ := fun s => if h : s ∈ simplices K 0 then f ⟨s, h⟩ else 0 with hext
  have hsum : ((Matrix.transpose (bdMatrix K 0)).mulVecLin f) e
      = ∑ s ∈ simplices K 0, (bdCoeff e.1 s : ℚ) * ext s := by
    simp only [Matrix.mulVecLin_apply, Matrix.mulVec, dotProduct, Matrix.transpose_apply,
      bdMatrix]
    rw [← Finset.sum_coe_sort (simplices K 0)]
    refine Finset.sum_congr rfl fun t _ => ?_
    simp [hext, t.2]
  have hne : a ≠ b := hab.ne
  have hF : ∀ v ∈ e.1, e.1.erase v ∈ simplices K 0 := by
    intro v hv
    rw [he] at hv ⊢
    rcases Finset.mem_insert.1 hv with rfl | hv
    · rw [Finset.erase_insert (by simpa using hne)]; exact hb
    · rw [Finset.mem_singleton.1 hv, Finset.pair_comm, Finset.erase_insert (by simpa using hne.symm)]
      exact ha
  rw [hsum, sum_bdCoeff_mul e.1 _ hF ext, he, Finset.sum_pair hne,
    Finset.erase_insert (by simpa using hne), Finset.pair_comm,
    Finset.erase_insert (by simpa using hne.symm), Finset.pair_comm]
  have hfa : Finset.filter (· < a) ({a, b} : Finset V) = ∅ := by
    ext x; simp only [Finset.mem_filter, Finset.mem_insert, Finset.mem_singleton,
      Finset.notMem_empty, iff_false, not_and]
    rintro (rfl | rfl) <;> simp [hab.le]
  have hfb : Finset.filter (· < b) ({a, b} : Finset V) = {a} := by
    ext x; simp only [Finset.mem_filter, Finset.mem_insert, Finset.mem_singleton]
    constructor
    · rintro ⟨rfl | rfl, h⟩
      · rfl
      · exact absurd h (lt_irrefl _)
    · rintro rfl; exact ⟨Or.inl rfl, hab⟩
  rw [hfa, hfb]
  simp [hext, ha, hb]
  ring

/-- The rank formula: for a finite simplicial complex with alternating boundary signs and
rational coefficients, the number of independent k-dimensional holes is the number of
independent k-cycles minus the number of independent k-boundaries,
`β_k = (n_k - rank ∂_k) - rank ∂_{k+1}`. -/
theorem betti_eq_card_sub_rank_sub_rank (K : Finset (Finset V)) (hK : IsComplex K) (k : ℕ) :
    betti K k = ((simplices K k).card - bdRank K k) - bdRank K (k + 1) := by
  have := betti_add_bdRank_add_bdRank K hK k
  omega

/-- The zeroth Betti number counts pieces: `β_0` is the number of connected components of the
graph of corners and edges. -/
theorem betti_zero_eq_pieces (K : Finset (Finset V)) (hK : IsComplex K) :
    betti K 0 = Nat.card (skeleton K).ConnectedComponent := by
  classical
  set G := skeleton K
  let W := {v : V // ({v} : Finset V) ∈ K}
  have hmem : ∀ v : W, ({v.1} : Finset V) ∈ simplices K 0 :=
    fun v => Finset.mem_filter.2 ⟨v.2, Finset.card_singleton _⟩
  let σ : W → simplices K 0 := fun v => ⟨{v.1}, hmem v⟩
  have hex : ∀ t : simplices K 0, ∃ a, t.1 = {a} :=
    fun t => Finset.card_eq_one.1 (Finset.mem_filter.1 t.2).2
  let vert : simplices K 0 → W := fun t => ⟨(hex t).choose, by
    rw [← (hex t).choose_spec]; exact (Finset.mem_filter.1 t.2).1⟩
  have hσvert : ∀ t, σ (vert t) = t := fun t => Subtype.ext (hex t).choose_spec.symm
  have hσinj : Function.Injective σ := by
    intro v w h
    exact Subtype.ext (Finset.singleton_inj.1 (congrArg Subtype.val h))
  have hvertσ : ∀ v, vert (σ v) = v := fun v => hσinj (hσvert _)
  have hsurj : Function.Surjective (fun t => G.connectedComponentMk (vert t)) := by
    intro c
    refine c.ind fun v => ⟨σ v, ?_⟩
    simp only [hvertσ]
  let Φ := LinearMap.funLeft ℚ ℚ (fun t => G.connectedComponentMk (vert t))
  have hΦinj : Function.Injective Φ := LinearMap.funLeft_injective_of_surjective _ _ _ hsurj
  set A := (Matrix.transpose (bdMatrix K 0))
  have hrange : LinearMap.range Φ = LinearMap.ker A.mulVecLin := by
    apply le_antisymm
    · rintro f ⟨g, rfl⟩
      rw [LinearMap.mem_ker]
      funext e
      obtain ⟨x, y, hxy, hexy⟩ := Finset.card_eq_two.1 (Finset.mem_filter.1 e.2).2
      have heK := (Finset.mem_filter.1 e.2).1
      wlog hlt : x < y generalizing x y
      · exact this y x hxy.symm (by rw [hexy, Finset.pair_comm])
          (lt_of_le_of_ne (not_lt.1 hlt) hxy.symm)
      rw [hexy] at heK
      have hxK : ({x} : Finset V) ∈ K := hK _ heK _ (by simp) (by simp)
      have hyK : ({y} : Finset V) ∈ K := hK _ heK _ (by simp) (by simp)
      have hx := transpose_mulVec_edge K (Φ g) e x y hlt hexy (hmem ⟨x, hxK⟩) (hmem ⟨y, hyK⟩)
      rw [hx]
      have hadj : G.Adj ⟨x, hxK⟩ ⟨y, hyK⟩ := by
        change (SimpleGraph.fromRel _).Adj _ _
        rw [SimpleGraph.fromRel_adj]
        exact ⟨fun h => hxy (congrArg Subtype.val h), Or.inl heK⟩
      have hσ : ∀ v : W, Φ g (σ v) = g (G.connectedComponentMk v) := by
        intro v; simp [Φ, LinearMap.funLeft_apply, hvertσ]
      have h1 := hσ ⟨x, hxK⟩
      have h2 := hσ ⟨y, hyK⟩
      simp only [σ] at h1 h2
      rw [h1, h2, SimpleGraph.ConnectedComponent.eq.2 hadj.reachable]
      simp
    · intro f hf
      rw [LinearMap.mem_ker] at hf
      have hadj : ∀ v w : W, G.Adj v w → f (σ v) = f (σ w) := by
        intro v w h
        change (SimpleGraph.fromRel _).Adj _ _ at h
        rw [SimpleGraph.fromRel_adj] at h
        obtain ⟨hne, hvwK⟩ := h
        have hne' : v.1 ≠ w.1 := fun h => hne (Subtype.ext h)
        have hK' : ({v.1, w.1} : Finset V) ∈ K := by
          rcases hvwK with h | h
          · exact h
          · rw [Finset.pair_comm]; exact h
        have he : ({v.1, w.1} : Finset V) ∈ simplices K 1 :=
          Finset.mem_filter.2 ⟨hK', Finset.card_pair hne'⟩
        rcases lt_or_gt_of_ne hne' with hlt | hlt
        · have := transpose_mulVec_edge K f ⟨_, he⟩ v.1 w.1 hlt rfl (hmem v) (hmem w)
          rw [hf] at this
          exact (sub_eq_zero.1 this.symm).symm
        · have := transpose_mulVec_edge K f ⟨_, he⟩ w.1 v.1 hlt (Finset.pair_comm _ _)
            (hmem w) (hmem v)
          rw [hf] at this
          exact sub_eq_zero.1 this.symm
      have hwalk : ∀ v w : W, ∀ p : G.Walk v w, f (σ v) = f (σ w) := by
        intro v w p
        induction p with
        | nil => rfl
        | cons h _ ih => exact (hadj _ _ h).trans ih
      refine ⟨SimpleGraph.ConnectedComponent.lift (fun v => f (σ v))
        (fun v w p _ => hwalk v w p), ?_⟩
      funext t
      simp [Φ, LinearMap.funLeft_apply, hσvert]
  have hfin : Finite W := Finite.of_injective (fun v : W => (⟨{v.1}, v.2⟩ : K))
    (fun v w h => Subtype.ext (Finset.singleton_inj.1 (congrArg Subtype.val h)))
  have : Fintype G.ConnectedComponent := Fintype.ofFinite _
  have hker : Module.finrank ℚ (LinearMap.ker A.mulVecLin) = Nat.card G.ConnectedComponent := by
    rw [← hrange, LinearMap.finrank_range_of_inj hΦinj, Module.finrank_fintype_fun_eq_card,
      Nat.card_eq_fintype_card]
  have hrn := LinearMap.finrank_range_add_finrank_ker A.mulVecLin
  rw [Module.finrank_fintype_fun_eq_card, Fintype.card_coe, hker] at hrn
  have hrank : A.rank = bdRank K 1 := Matrix.rank_transpose _
  have hrA : Module.finrank ℚ (LinearMap.range A.mulVecLin) = A.rank := rfl
  have key : betti K 0 + bdRank K 1 + bdRank K 0 = _ := betti_add_bdRank_add_bdRank K hK 0
  have hr0 : bdRank K 0 = 0 := rfl
  omega

/-- For a complex of corners, edges and triangles, the alternating sum of the Betti numbers is
the Euler characteristic: `n_0 - n_1 + n_2 = β_0 - β_1 + β_2`. -/
theorem euler_characteristic_eq_alternating_betti_sum (K : Finset (Finset V)) (hK : IsComplex K)
    (hdim : ∀ s ∈ K, s.card ≤ 3) :
    ((simplices K 0).card : ℤ) - (simplices K 1).card + (simplices K 2).card
      = (betti K 0 : ℤ) - betti K 1 + betti K 2 := by
  have h0 : betti K 0 + bdRank K 1 + bdRank K 0 = _ := betti_add_bdRank_add_bdRank K hK 0
  have h1 : betti K 1 + bdRank K 2 + bdRank K 1 = _ := betti_add_bdRank_add_bdRank K hK 1
  have h2 : betti K 2 + bdRank K 3 + bdRank K 2 = _ := betti_add_bdRank_add_bdRank K hK 2
  have hr0 : bdRank K 0 = 0 := rfl
  have hr3 : bdRank K 3 = 0 := by
    have hempty : simplices K 3 = ∅ := by
      apply Finset.filter_eq_empty_iff.2
      intro s hs
      have := hdim s hs
      omega
    have := Matrix.rank_le_card_width (bdMatrix K 2)
    show (bdMatrix K 2).rank = 0
    simp only [Fintype.card_coe, hempty, Finset.card_empty] at this
    omega
  omega

/-! ### The card's worked examples -/

/-- Every nonempty face of the given simplices. -/
def closure (T : Finset (Finset V)) : Finset (Finset V) :=
  T.biUnion (fun s => s.powerset.filter (·.Nonempty))

/-- The annulus: six panels on six corners, inner triangle 0, 1, 2 and outer triangle 3, 4, 5. -/
def annulus : Finset (Finset (Fin 6)) :=
  closure {{0, 1, 3}, {1, 2, 4}, {0, 2, 5}, {1, 3, 4}, {2, 4, 5}, {0, 3, 5}}

/-- The inner rim `z = [0,1] + [1,2] - [0,2]`. -/
def rimZ (e : Finset (Fin 6)) : ℤ :=
  if e = {0, 1} then 1 else if e = {1, 2} then 1 else if e = {0, 2} then -1 else 0

/-- The outer rim `w = [3,4] + [4,5] - [3,5]`. -/
def rimW (e : Finset (Fin 6)) : ℤ :=
  if e = {3, 4} then 1 else if e = {4, 5} then 1 else if e = {3, 5} then -1 else 0

-- the annulus has 6 corners, 12 edges and 6 panels
example : (simplices annulus 0).card = 6 ∧ (simplices annulus 1).card = 12 ∧
    (simplices annulus 2).card = 6 := by decide

-- the boundary of the filled triangle: ∂[0,1,2] = [1,2] - [0,2] + [0,1], printed [1, -1, 1] on 01, 02, 12
example : bdCoeff ({0, 1, 2} : Finset (Fin 3)) {0, 1} = 1 ∧
    bdCoeff ({0, 1, 2} : Finset (Fin 3)) {0, 2} = -1 ∧
    bdCoeff ({0, 1, 2} : Finset (Fin 3)) {1, 2} = 1 := by decide

-- both rims are cycles: their boundaries are zero on every corner
example : ∀ c ∈ simplices annulus 0,
    (∑ e ∈ simplices annulus 1, rimZ e * bdCoeff e c) = 0 ∧
    (∑ e ∈ simplices annulus 1, rimW e * bdCoeff e c) = 0 := by decide

-- w - z = ∂(-[0,1,3] + [0,2,5] - [0,3,5] - [1,2,4] + [1,3,4] + [2,4,5])
example : ∀ e ∈ simplices annulus 1,
    -bdCoeff {0, 1, 3} e + bdCoeff {0, 2, 5} e - bdCoeff {0, 3, 5} e - bdCoeff {1, 2, 4} e
      + bdCoeff {1, 3, 4} e + bdCoeff {2, 4, 5} e = rimW e - rimZ e := by decide

-- the annulus by the rank formula: β_1 = (12 - 5) - 6 = 1, β_0 = 6 - 5 = 1, β_2 = 6 - 6 = 0
example : (12 - 5) - 6 = 1 ∧ 6 - 5 = 1 ∧ 6 - 6 = 0 := by norm_num

-- Euler characteristic two ways: annulus 6 - 12 + 6 = 1 - 1 + 0; dome with three panels out
-- 42 - 120 + 77 = 1 - 2 + 0; the whole dome 42 - 120 + 80 = 1 - 0 + 1
example : (6 : ℤ) - 12 + 6 = 1 - 1 + 0 ∧ (42 : ℤ) - 120 + 77 = 1 - 2 + 0 ∧
    (42 : ℤ) - 120 + 80 = 1 - 0 + 1 := by norm_num

-- the dome table: dim Z_1 = 120 - 41 = 79, and β_1 = 79 - rank ∂_2 for 80, 79, 78, 77 panels
example : 120 - 41 = 79 ∧ 79 - 79 = 0 ∧ 79 - 78 = 1 ∧ 79 - 77 = 2 ∧
    80 - 79 = 1 ∧ 79 - 79 = 0 := by norm_num

#print axioms sign_swap
#print axioms sum_bdCoeff_mul
#print axioms sum_sign_bdCoeff_erase
#print axioms bdMatrix_mul_bdMatrix
#print axioms boundaries_le_cycles
#print axioms betti_add_bdRank_add_bdRank
#print axioms transpose_mulVec_edge
#print axioms betti_eq_card_sub_rank_sub_rank
#print axioms betti_zero_eq_pieces
#print axioms euler_characteristic_eq_alternating_betti_sum

end HomologyGroups
