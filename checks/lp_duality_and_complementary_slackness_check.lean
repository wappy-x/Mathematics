-- LP duality: every fair price list bounds every plan's profit, when either the maximising program or its pricing partner has a best answer both do and their values are equal, and a feasible pair is best exactly when every spare resource has price zero and every product made breaks even.
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib

open Matrix

namespace LPDuality

/-- Inequalities derivable from a set by nonnegative combinations. -/
inductive Der {M : Type*} [AddCommMonoid M] [Module ℝ M] (S : Set M) : M → Prop
  | mem {x : M} : x ∈ S → Der S x
  | zero : Der S 0
  | add {x y : M} : Der S x → Der S y → Der S (x + y)
  | smul {c : ℝ} {x : M} : 0 ≤ c → Der S x → Der S (c • x)

theorem Der.trans {M : Type*} [AddCommMonoid M] [Module ℝ M] {S T : Set M}
    (hST : ∀ x ∈ S, Der T x) {w : M} (hw : Der S w) : Der T w := by
  induction hw with
  | mem h => exact hST _ h
  | zero => exact Der.zero
  | add _ _ ih1 ih2 => exact Der.add ih1 ih2
  | smul hc _ ih => exact Der.smul hc ih

theorem exists_between_finset {α : Type*} (S : Finset α) (lo hi : α → ℝ) (isLo isHi : α → Prop)
    (h : ∀ p ∈ S, ∀ q ∈ S, isHi p → isLo q → lo q ≤ hi p) :
    ∃ x : ℝ, (∀ q ∈ S, isLo q → lo q ≤ x) ∧ (∀ p ∈ S, isHi p → x ≤ hi p) := by
  classical
  by_cases hne : (S.filter isLo).Nonempty
  · refine ⟨((S.filter isLo).image lo).max' (hne.image _), fun q hq hlo => ?_, fun p hp hhi => ?_⟩
    · exact Finset.le_max' _ _ (Finset.mem_image_of_mem _ (Finset.mem_filter.2 ⟨hq, hlo⟩))
    · obtain ⟨q, hq, hqe⟩ := Finset.mem_image.1 (Finset.max'_mem ((S.filter isLo).image lo)
        (hne.image _))
      rw [← hqe]
      exact h p hp q (Finset.mem_filter.1 hq).1 hhi (Finset.mem_filter.1 hq).2
  · obtain ⟨x, hx⟩ := Finset.bddBelow ((S.filter isHi).image hi)
    refine ⟨x, fun q hq hlo => absurd ⟨q, Finset.mem_filter.2 ⟨hq, hlo⟩⟩ hne, fun p hp hhi => ?_⟩
    exact hx (Finset.mem_image_of_mem _ (Finset.mem_filter.2 ⟨hp, hhi⟩))

/-- Fourier–Motzkin form of Farkas' lemma. -/
theorem fourier_motzkin : ∀ (n : ℕ) (S : Finset ((Fin n → ℝ) × ℝ)),
    (¬∃ x : Fin n → ℝ, ∀ p ∈ S, p.1 ⬝ᵥ x ≤ p.2) →
      ∃ β : ℝ, β < 0 ∧ Der (S : Set ((Fin n → ℝ) × ℝ)) ((0 : Fin n → ℝ), β)
  | 0, S, h => by
    push Not at h
    obtain ⟨p, hp, hlt⟩ := h 0
    refine ⟨p.2, by simpa using hlt, ?_⟩
    have : p = ((0 : Fin 0 → ℝ), p.2) := Prod.ext (Subsingleton.elim _ _) rfl
    exact this ▸ Der.mem hp
  | n + 1, S, h => by
    classical
    let comb : ((Fin (n + 1) → ℝ) × ℝ) × ((Fin (n + 1) → ℝ) × ℝ) → (Fin (n + 1) → ℝ) × ℝ :=
      fun pq => (-pq.2.1 0) • pq.1 + pq.1.1 0 • pq.2
    let T : Finset ((Fin (n + 1) → ℝ) × ℝ) :=
      S.filter (fun p => p.1 0 = 0) ∪
        ((S ×ˢ S).filter (fun pq => 0 < pq.1.1 0 ∧ pq.2.1 0 < 0)).image comb
    let L : (Fin (n + 1) → ℝ) × ℝ → (Fin n → ℝ) × ℝ := fun p => (fun (i : Fin n) => p.1 i.succ, p.2)
    have hT0 : ∀ p ∈ T, p.1 0 = 0 := by
      intro p hp
      rcases Finset.mem_union.1 hp with hp | hp
      · exact (Finset.mem_filter.1 hp).2
      · obtain ⟨pq, -, rfl⟩ := Finset.mem_image.1 hp
        simp only [comb, Prod.fst_add, Prod.smul_fst, Pi.add_apply, Pi.smul_apply, smul_eq_mul]
        ring
    have hTS : ∀ p ∈ (T : Set ((Fin (n + 1) → ℝ) × ℝ)), Der (S : Set _) p := by
      intro p hp
      rcases Finset.mem_union.1 hp with hp | hp
      · exact Der.mem (Finset.mem_filter.1 hp).1
      · obtain ⟨pq, hpq, rfl⟩ := Finset.mem_image.1 hp
        obtain ⟨hmem, h1, h2⟩ := Finset.mem_filter.1 hpq
        obtain ⟨hp1, hp2⟩ := Finset.mem_product.1 hmem
        exact Der.add (Der.smul (neg_nonneg.2 h2.le) (Der.mem hp1)) (Der.smul h1.le (Der.mem hp2))
    have hT' : ¬∃ x' : Fin n → ℝ, ∀ p ∈ T.image L, p.1 ⬝ᵥ x' ≤ p.2 := by
      rintro ⟨x', hx'⟩
      apply h
      have hTx : ∀ p ∈ T, (fun (i : Fin n) => p.1 i.succ) ⬝ᵥ x' ≤ p.2 := fun p hp =>
        hx' (L p) (Finset.mem_image_of_mem L hp)
      let r : (Fin (n + 1) → ℝ) × ℝ → ℝ := fun p => p.2 - (fun (i : Fin n) => p.1 i.succ) ⬝ᵥ x'
      obtain ⟨x0, hlo, hhi⟩ := exists_between_finset S (fun q => r q / q.1 0)
        (fun p => r p / p.1 0) (fun q => q.1 0 < 0) (fun p => 0 < p.1 0) (by
          intro p hp q hq hp0 hq0
          have hc := hTx (comb (p, q)) (Finset.mem_union_right _ (Finset.mem_image_of_mem _
            (Finset.mem_filter.2 ⟨Finset.mem_product.2 ⟨hp, hq⟩, hp0, hq0⟩)))
          have he : (fun (i : Fin n) => (comb (p, q)).1 i.succ) =
              (-q.1 0) • (fun (i : Fin n) => p.1 i.succ) + p.1 0 • (fun (i : Fin n) => q.1 i.succ) := by
            funext i; simp [comb]
          rw [he, add_dotProduct, smul_dotProduct, smul_dotProduct] at hc
          simp only [comb, Prod.snd_add, Prod.smul_snd, smul_eq_mul] at hc
          set a := r q / q.1 0 with ha
          set b := r p / p.1 0 with hb
          have hra : r q = a * q.1 0 := by rw [ha]; field_simp [hq0.ne]
          have hrb : r p = b * p.1 0 := by rw [hb]; field_simp [hp0.ne']
          have H : 0 ≤ (p.1 0 * -q.1 0) * (b - a) := by
            have e1 : r q = q.2 - (fun (i : Fin n) => q.1 i.succ) ⬝ᵥ x' := rfl
            have e2 : r p = p.2 - (fun (i : Fin n) => p.1 i.succ) ⬝ᵥ x' := rfl
            nlinarith
          have hpos : 0 < p.1 0 * -q.1 0 := mul_pos hp0 (neg_pos.2 hq0)
          have := (mul_nonneg_iff_of_pos_left hpos).1 H
          linarith)
      refine ⟨Fin.cons x0 x', fun p hp => ?_⟩
      have hdot : p.1 ⬝ᵥ (Fin.cons x0 x' : Fin (n + 1) → ℝ) =
          p.1 0 * x0 + (fun (i : Fin n) => p.1 i.succ) ⬝ᵥ x' := by
        simp [dotProduct, Fin.sum_univ_succ]
      rw [hdot]
      rcases lt_trichotomy (p.1 0) 0 with hneg | hzero | hpos
      · have := hlo p hp hneg
        rw [div_le_iff_of_neg hneg] at this
        simp only [r] at this
        linarith
      · have := hTx p (Finset.mem_union_left _ (Finset.mem_filter.2 ⟨hp, hzero⟩))
        rw [hzero]; linarith
      · have := hhi p hp hpos
        rw [le_div_iff₀ hpos] at this
        simp only [r] at this
        linarith
    obtain ⟨β, hβ, hd⟩ := fourier_motzkin n (T.image L) hT'
    have key : ∀ w', Der ((T.image L : Finset _) : Set ((Fin n → ℝ) × ℝ)) w' →
        ∃ w, Der (T : Set ((Fin (n + 1) → ℝ) × ℝ)) w ∧ w.1 0 = 0 ∧ L w = w' := by
      intro w' hw'
      induction hw' with
      | mem hm =>
        obtain ⟨p, hp, rfl⟩ := Finset.mem_image.1 hm
        exact ⟨p, Der.mem hp, hT0 p hp, rfl⟩
      | zero => exact ⟨0, Der.zero, rfl, rfl⟩
      | add _ _ ih1 ih2 =>
        obtain ⟨w1, h1, z1, rfl⟩ := ih1
        obtain ⟨w2, h2, z2, rfl⟩ := ih2
        refine ⟨w1 + w2, Der.add h1 h2, by simp [z1, z2], rfl⟩
      | smul hc _ ih =>
        obtain ⟨w1, h1, z1, rfl⟩ := ih
        refine ⟨_ • w1, Der.smul hc h1, by simp [z1], rfl⟩
    obtain ⟨w, hw, hw0, hwL⟩ := key _ hd
    have hweq : w = ((0 : Fin (n + 1) → ℝ), β) := by
      refine Prod.ext ?_ (congrArg Prod.snd hwL : _)
      funext i
      refine Fin.cases ?_ (fun j => ?_) i
      · exact hw0
      · exact congrFun (congrArg Prod.fst hwL) j
    exact ⟨β, hβ, Der.trans hTS (hweq ▸ hw)⟩

#print axioms Der.trans
#print axioms exists_between_finset
#print axioms fourier_motzkin


/-! ## The setting

The primal: maximise `c ⬝ᵥ x` subject to `A *ᵥ x ≤ b` and `x ≥ 0`, with `m` resources (rows of
`A`) and `n` products (columns of `A`). The dual: minimise `b ⬝ᵥ y` subject to `Aᵀ *ᵥ y ≥ c`
and `y ≥ 0`. Inequalities between vectors hold entry by entry. Quantities and prices are real
numbers, so fractions are allowed. -/

variable {m n : ℕ}

/-- A plan `x` is feasible: no negative amounts, and no resource used beyond its stock. -/
def PrimalFeasible (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (x : Fin n → ℝ) : Prop :=
  0 ≤ x ∧ A *ᵥ x ≤ b

/-- A price list `y` is feasible (fair): no negative prices, and every product's inputs, valued
at the prices, are worth at least its profit. -/
def DualFeasible (A : Matrix (Fin m) (Fin n) ℝ) (c : Fin n → ℝ) (y : Fin m → ℝ) : Prop :=
  0 ≤ y ∧ c ≤ Aᵀ *ᵥ y

/-- `x` is a best plan: feasible, and no feasible plan earns more. -/
def PrimalOptimal (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (c : Fin n → ℝ)
    (x : Fin n → ℝ) : Prop :=
  PrimalFeasible A b x ∧ ∀ x', PrimalFeasible A b x' → c ⬝ᵥ x' ≤ c ⬝ᵥ x

/-- `y` is a best (cheapest) price list: fair, and no fair price list values the stock lower. -/
def DualOptimal (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (c : Fin n → ℝ)
    (y : Fin m → ℝ) : Prop :=
  DualFeasible A c y ∧ ∀ y', DualFeasible A c y' → b ⬝ᵥ y ≤ b ⬝ᵥ y'

/-- Farkas' lemma in the shape used for both directions of strong duality. -/
theorem farkas_aux {p k : ℕ} (M : Matrix (Fin p) (Fin k) ℝ) (d : Fin p → ℝ) (g : Fin k → ℝ)
    (e : ℝ) (h : ¬∃ z : Fin k → ℝ, 0 ≤ z ∧ M *ᵥ z ≤ d ∧ g ⬝ᵥ z ≤ e) :
    ∃ (u : Fin p → ℝ) (t : ℝ), 0 ≤ u ∧ 0 ≤ t ∧ 0 ≤ Mᵀ *ᵥ u + t • g ∧ u ⬝ᵥ d + t * e < 0 := by
  classical
  let S : Finset ((Fin k → ℝ) × ℝ) :=
    (Finset.univ.image fun j => (-Pi.single j (1 : ℝ), (0 : ℝ))) ∪
      (Finset.univ.image fun i => (M i, d i)) ∪ {(g, e)}
  have hS : ¬∃ x : Fin k → ℝ, ∀ q ∈ S, q.1 ⬝ᵥ x ≤ q.2 := by
    rintro ⟨x, hx⟩
    refine h ⟨x, fun j => ?_, fun i => ?_, ?_⟩
    · have := hx (-Pi.single j (1 : ℝ), (0 : ℝ)) (by simp [S])
      simpa using this
    · have := hx (M i, d i) (Finset.mem_union_left _ (Finset.mem_union_right _
        (Finset.mem_image_of_mem _ (Finset.mem_univ i))))
      simpa [mulVec, dotProduct] using this
    · exact hx (g, e) (by simp [S])
  obtain ⟨β, hβ, hd⟩ := fourier_motzkin k S hS
  have key : ∀ w, Der (S : Set ((Fin k → ℝ) × ℝ)) w → ∃ (s : Fin k → ℝ) (u : Fin p → ℝ) (t : ℝ),
      0 ≤ s ∧ 0 ≤ u ∧ 0 ≤ t ∧ w = (-s + Mᵀ *ᵥ u + t • g, u ⬝ᵥ d + t * e) := by
    intro w hw
    induction hw with
    | mem hm =>
      simp only [S, Finset.coe_union, Finset.coe_image, Finset.coe_univ, Set.image_univ,
        Finset.coe_singleton, Set.mem_union, Set.mem_range, Set.mem_singleton_iff] at hm
      rcases hm with (⟨j, rfl⟩ | ⟨i, rfl⟩) | rfl
      · exact ⟨Pi.single j 1, 0, 0, Pi.single_nonneg.2 zero_le_one, le_rfl, le_rfl, by simp⟩
      · refine ⟨0, Pi.single i 1, 0, le_rfl, Pi.single_nonneg.2 zero_le_one, le_rfl, ?_⟩
        simp
        rfl
      · exact ⟨0, 0, 1, le_rfl, le_rfl, zero_le_one, by simp⟩
    | zero => exact ⟨0, 0, 0, le_rfl, le_rfl, le_rfl, by ext <;> simp⟩
    | add _ _ ih1 ih2 =>
      obtain ⟨s1, u1, t1, hs1, hu1, ht1, rfl⟩ := ih1
      obtain ⟨s2, u2, t2, hs2, hu2, ht2, rfl⟩ := ih2
      refine ⟨s1 + s2, u1 + u2, t1 + t2, add_nonneg hs1 hs2, add_nonneg hu1 hu2,
        add_nonneg ht1 ht2, ?_⟩
      refine Prod.ext ?_ ?_
      · simp only [Prod.fst_add, mulVec_add, add_smul]; abel
      · simp only [Prod.snd_add, add_dotProduct]; ring
    | @smul c _ hc _ ih =>
      obtain ⟨s1, u1, t1, hs1, hu1, ht1, rfl⟩ := ih
      refine ⟨c • s1, c • u1, c * t1, smul_nonneg hc hs1, smul_nonneg hc hu1,
        mul_nonneg hc ht1, ?_⟩
      refine Prod.ext ?_ ?_
      · simp only [Prod.smul_fst, mulVec_smul, smul_add, smul_neg, mul_smul]
      · simp only [Prod.smul_snd, smul_dotProduct, smul_eq_mul]; ring
  obtain ⟨s, u, t, hs, hu, ht, hw⟩ := key _ hd
  refine ⟨u, t, hu, ht, fun j => ?_, ?_⟩
  · have := congrFun (congrArg Prod.fst hw) j
    simp only [Pi.zero_apply, Pi.add_apply, Pi.neg_apply] at this
    simp only [Pi.zero_apply, Pi.add_apply]
    have hsj := hs j
    simp only [Pi.zero_apply] at hsj
    linarith
  · have := congrArg Prod.snd hw
    simp only at this
    linarith

/-- Weak duality: a feasible plan earns at most a fair price list's stock value. -/
theorem weak_aux {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (c : Fin n → ℝ)
    (x : Fin n → ℝ) (y : Fin m → ℝ) (hx : PrimalFeasible A b x) (hy : DualFeasible A c y) :
    c ⬝ᵥ x ≤ b ⬝ᵥ y := by
  calc c ⬝ᵥ x ≤ (Aᵀ *ᵥ y) ⬝ᵥ x :=
        Finset.sum_le_sum fun j _ => mul_le_mul_of_nonneg_right (hy.2 j) (hx.1 j)
    _ = y ⬝ᵥ (A *ᵥ x) := by rw [mulVec_transpose, dotProduct_mulVec]
    _ ≤ y ⬝ᵥ b := Finset.sum_le_sum fun i _ => mul_le_mul_of_nonneg_left (hx.2 i) (hy.1 i)
    _ = b ⬝ᵥ y := dotProduct_comm _ _

#print axioms farkas_aux
#print axioms weak_aux

/-- **Strong duality.** For any linear program "maximise `c ⬝ᵥ x` subject to `A *ᵥ x ≤ b`,
`x ≥ 0`" and its dual "minimise `b ⬝ᵥ y` subject to `Aᵀ *ᵥ y ≥ c`, `y ≥ 0`": when either one
has a best answer, both do, and the best profit equals the cheapest stock value. -/
theorem lp_strong_duality (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (c : Fin n → ℝ)
    (h : (∃ x, PrimalOptimal A b c x) ∨ (∃ y, DualOptimal A b c y)) :
    ∃ x y, PrimalOptimal A b c x ∧ DualOptimal A b c y ∧ c ⬝ᵥ x = b ⬝ᵥ y := by
  rcases h with ⟨x, hxf, hxo⟩ | ⟨y, hyf, hyo⟩
  · -- a best plan exists: find a fair price list valued at most its profit
    have hex : ∃ y : Fin m → ℝ, 0 ≤ y ∧ (-Aᵀ) *ᵥ y ≤ -c ∧ b ⬝ᵥ y ≤ c ⬝ᵥ x := by
      by_contra hne
      obtain ⟨u, t, hu, ht, h1, h2⟩ := farkas_aux (-Aᵀ) (-c) b (c ⬝ᵥ x) hne
      simp only [transpose_neg, transpose_transpose, neg_mulVec, dotProduct_neg] at h1 h2
      rcases ht.lt_or_eq with htp | rfl
      · have hfeas : PrimalFeasible A b (t⁻¹ • u) := by
          refine ⟨smul_nonneg (inv_nonneg.2 ht) hu, fun i => ?_⟩
          have := h1 i
          simp only [Pi.zero_apply, Pi.add_apply, Pi.neg_apply, Pi.smul_apply,
            smul_eq_mul] at this
          rw [mulVec_smul, Pi.smul_apply, smul_eq_mul, inv_mul_le_iff₀ htp]
          linarith
        have := hxo _ hfeas
        rw [dotProduct_smul, smul_eq_mul, inv_mul_le_iff₀ htp, dotProduct_comm] at this
        linarith
      · have hfeas : PrimalFeasible A b (x + u) := by
          refine ⟨add_nonneg hxf.1 hu, fun i => ?_⟩
          have := h1 i
          simp only [Pi.zero_apply, Pi.add_apply, Pi.neg_apply, zero_smul,
            add_zero] at this
          rw [mulVec_add, Pi.add_apply]
          linarith [hxf.2 i]
        have := hxo _ hfeas
        rw [dotProduct_add, dotProduct_comm c u] at this
        linarith
    obtain ⟨y, hy0, hyc, hyb⟩ := hex
    have hyf : DualFeasible A c y := by
      refine ⟨hy0, fun j => ?_⟩
      have := hyc j
      simp only [neg_mulVec, Pi.neg_apply, neg_le_neg_iff] at this
      exact this
    have heq : c ⬝ᵥ x = b ⬝ᵥ y := le_antisymm (weak_aux A b c x y hxf hyf) hyb
    exact ⟨x, y, ⟨hxf, hxo⟩, ⟨hyf, fun y' hy' => heq ▸ weak_aux A b c x y' hxf hy'⟩, heq⟩
  · -- a best price list exists: find a plan earning at least its value
    have hex : ∃ x : Fin n → ℝ, 0 ≤ x ∧ A *ᵥ x ≤ b ∧ (-c) ⬝ᵥ x ≤ -(b ⬝ᵥ y) := by
      by_contra hne
      obtain ⟨u, t, hu, ht, h1, h2⟩ := farkas_aux A b (-c) (-(b ⬝ᵥ y)) hne
      rcases ht.lt_or_eq with htp | rfl
      · have hfeas : DualFeasible A c (t⁻¹ • u) := by
          refine ⟨smul_nonneg (inv_nonneg.2 ht) hu, fun j => ?_⟩
          have := h1 j
          simp only [Pi.zero_apply, Pi.add_apply, Pi.neg_apply, Pi.smul_apply,
            smul_eq_mul] at this
          rw [mulVec_smul, Pi.smul_apply, smul_eq_mul, le_inv_mul_iff₀ htp]
          linarith
        have := hyo _ hfeas
        rw [dotProduct_smul, smul_eq_mul, le_inv_mul_iff₀ htp, dotProduct_comm b u] at this
        linarith
      · have hfeas : DualFeasible A c (y + u) := by
          refine ⟨add_nonneg hyf.1 hu, fun j => ?_⟩
          have := h1 j
          simp only [Pi.zero_apply, Pi.add_apply, zero_smul, add_zero] at this
          rw [mulVec_add, Pi.add_apply]
          linarith [hyf.2 j]
        have := hyo _ hfeas
        rw [dotProduct_add, dotProduct_comm b u] at this
        linarith
    obtain ⟨x, hx0, hxb, hxc⟩ := hex
    have hxf : PrimalFeasible A b x := ⟨hx0, hxb⟩
    have hxc' : b ⬝ᵥ y ≤ c ⬝ᵥ x := by
      rw [neg_dotProduct] at hxc; linarith
    have heq : c ⬝ᵥ x = b ⬝ᵥ y := le_antisymm (weak_aux A b c x y hxf hyf) hxc'
    exact ⟨x, y, ⟨hxf, fun x' hx' => heq ▸ weak_aux A b c x' y hx' hyf⟩, ⟨hyf, hyo⟩, heq⟩

/-- **Weak duality and the gap identity.** For every plan `x` and every price list `y`, the gap
`b ⬝ᵥ y - c ⬝ᵥ x` equals the price of the spare stock, `y ⬝ᵥ s` with `s = b - A *ᵥ x`, plus the
over-valuation of the items made, `x ⬝ᵥ r` with `r = Aᵀ *ᵥ y - c`. When the plan is feasible
and the price list is fair, the gap is never negative: every plan's profit is at most every fair
price list's stock value. -/
theorem lp_weak_duality_and_gap (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (c : Fin n → ℝ) (x : Fin n → ℝ) (y : Fin m → ℝ) :
    b ⬝ᵥ y - c ⬝ᵥ x = y ⬝ᵥ (b - A *ᵥ x) + x ⬝ᵥ (Aᵀ *ᵥ y - c) ∧
      (PrimalFeasible A b x → DualFeasible A c y → c ⬝ᵥ x ≤ b ⬝ᵥ y) := by
  refine ⟨?_, weak_aux A b c x y⟩
  rw [dotProduct_sub, dotProduct_sub, dotProduct_comm x (Aᵀ *ᵥ y), mulVec_transpose,
    ← dotProduct_mulVec, dotProduct_comm y b, dotProduct_comm x c]
  ring

/-- **Complementary slackness.** A feasible plan `x` and a fair price list `y` are both best
exactly when every resource with stock left over has price zero (`y i * s i = 0`) and every
product that is made breaks even at the prices (`x j * r j = 0`). -/
theorem lp_complementary_slackness (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (c : Fin n → ℝ) (x : Fin n → ℝ) (y : Fin m → ℝ)
    (hx : PrimalFeasible A b x) (hy : DualFeasible A c y) :
    (PrimalOptimal A b c x ∧ DualOptimal A b c y) ↔
      ((∀ i, y i * (b - A *ᵥ x) i = 0) ∧ (∀ j, x j * (Aᵀ *ᵥ y - c) j = 0)) := by
  have hgap := (lp_weak_duality_and_gap A b c x y).1
  have hs : ∀ i, 0 ≤ y i * (b - A *ᵥ x) i := fun i =>
    mul_nonneg (hy.1 i) (sub_nonneg.2 (hx.2 i))
  have hr : ∀ j, 0 ≤ x j * (Aᵀ *ᵥ y - c) j := fun j =>
    mul_nonneg (hx.1 j) (sub_nonneg.2 (hy.2 j))
  have hs0 : 0 ≤ y ⬝ᵥ (b - A *ᵥ x) := Finset.sum_nonneg fun i _ => hs i
  have hr0 : 0 ≤ x ⬝ᵥ (Aᵀ *ᵥ y - c) := Finset.sum_nonneg fun j _ => hr j
  constructor
  · rintro ⟨hxo, hyo⟩
    obtain ⟨x', y', hx', hy', heq⟩ := lp_strong_duality A b c (Or.inl ⟨x, hxo⟩)
    have e1 : c ⬝ᵥ x' ≤ c ⬝ᵥ x := hxo.2 x' hx'.1
    have e2 : b ⬝ᵥ y ≤ b ⬝ᵥ y' := hyo.2 y' hy'.1
    have e3 : c ⬝ᵥ x ≤ b ⬝ᵥ y := weak_aux A b c x y hx hy
    have hS : y ⬝ᵥ (b - A *ᵥ x) = 0 := by linarith
    have hR : x ⬝ᵥ (Aᵀ *ᵥ y - c) = 0 := by linarith
    refine ⟨fun i => ?_, fun j => ?_⟩
    · exact (Finset.sum_eq_zero_iff_of_nonneg fun i _ => hs i).1 hS i (Finset.mem_univ _)
    · exact (Finset.sum_eq_zero_iff_of_nonneg fun j _ => hr j).1 hR j (Finset.mem_univ _)
  · rintro ⟨hS, hR⟩
    have h1 : y ⬝ᵥ (b - A *ᵥ x) = 0 := Finset.sum_eq_zero fun i _ => hS i
    have h2 : x ⬝ᵥ (Aᵀ *ᵥ y - c) = 0 := Finset.sum_eq_zero fun j _ => hR j
    have heq : c ⬝ᵥ x = b ⬝ᵥ y := by linarith
    exact ⟨⟨hx, fun x' hx' => heq ▸ weak_aux A b c x' y hx' hy⟩,
      ⟨hy, fun y' hy' => heq ▸ weak_aux A b c x y' hx hy'⟩⟩

/-! ## The workshop: tables and chairs

Usage table (rows timber, labour, finish; columns tables, chairs), stocks, and profits. -/

/-- The workshop's usage table: a table takes (4, 3, 1), a chair (2, 1, 2). -/
def Aw : Matrix (Fin 3) (Fin 2) ℝ := !![4, 2; 3, 1; 1, 2]
/-- Stocks: 160 m of timber, 120 h of labour, 64 litres of finish. -/
def bw : Fin 3 → ℝ := ![160, 120, 64]
/-- Profits: £19 a table, £20 a chair. -/
def cw : Fin 2 → ℝ := ![19, 20]

-- The plan (32, 16) is feasible: it uses 160 m, 112 h and 64 litres.
example : Aw *ᵥ ![32, 16] = ![160, 112, 64] := by
  ext i; fin_cases i <;> simp [Aw, mulVec, dotProduct, Fin.sum_univ_succ] <;> norm_num
example : PrimalFeasible Aw bw ![32, 16] := by
  refine ⟨?_, ?_⟩ <;> intro i <;> fin_cases i <;>
    simp [Aw, bw, mulVec, dotProduct, Fin.sum_univ_succ] <;> norm_num
-- It earns £928.
example : cw ⬝ᵥ ![32, 16] = 928 := by
  simp [cw, dotProduct, Fin.sum_univ_succ]; norm_num
-- The prices (3, 0, 7) are fair: a table's inputs are worth exactly £19, a chair's exactly £20.
example : Awᵀ *ᵥ ![3, 0, 7] = ![19, 20] := by
  ext j; fin_cases j <;> simp [Aw, mulVec, dotProduct, Fin.sum_univ_succ] <;> norm_num
example : DualFeasible Aw cw ![3, 0, 7] := by
  refine ⟨?_, ?_⟩ <;> intro i <;> fin_cases i <;>
    simp [Aw, cw, mulVec, dotProduct, Fin.sum_univ_succ] <;> norm_num
-- They value the stock at £928, so the gap is £0.
example : bw ⬝ᵥ ![3, 0, 7] = 928 := by
  simp [bw, dotProduct, Fin.sum_univ_succ]; norm_num
-- Slackness at the best pair: price times slack is 3 × 0, 0 × 8, 7 × 0; made times surplus is
-- 32 × 0, 16 × 0.
example : (3 : ℤ) * 0 = 0 ∧ (0 : ℤ) * 8 = 0 ∧ (7 : ℤ) * 0 = 0 ∧ (32 : ℤ) * 0 = 0 ∧
    (16 : ℤ) * 0 = 0 := by decide
-- Solving slackness from the plan: y2 = 0, 4y1 + y3 = 19, 2y1 + 2y3 = 20 gives (3, 0, 7).
example : 4 * 3 + 3 * 0 + 7 = 19 ∧ 2 * 3 + 0 + 2 * 7 = 20 := by decide
-- The fair but not best prices (3, 1, 7): inputs £22 and £21, stock £1,048, gap £120,
-- and by the identity 1 × 8 + 32 × 3 + 16 × 1 = 120.
example : Awᵀ *ᵥ ![3, 1, 7] = ![22, 21] := by
  ext j; fin_cases j <;> simp [Aw, mulVec, dotProduct, Fin.sum_univ_succ] <;> norm_num
example : bw ⬝ᵥ ![3, 1, 7] = 1048 := by
  simp [bw, dotProduct, Fin.sum_univ_succ]; norm_num
example : 1048 - 928 = 120 ∧ 1 * 8 + 32 * 3 + 16 * 1 = 120 := by decide
-- Broken: prices (2, 0, 7) value a table's inputs at £15 and a chair's at £18, so they are not
-- fair; their stock value is £768, below £928 by £160.
example : Awᵀ *ᵥ ![2, 0, 7] = ![15, 18] ∧ ¬ DualFeasible Aw cw ![2, 0, 7] := by
  refine ⟨?_, ?_⟩
  · ext j; fin_cases j <;> simp [Aw, mulVec, dotProduct, Fin.sum_univ_succ] <;> norm_num
  · rintro ⟨-, h⟩
    have := h 0
    simp [Aw, cw, mulVec, dotProduct, Fin.sum_univ_succ] at this
    norm_num at this
example : bw ⬝ᵥ ![2, 0, 7] = 768 ∧ (928 : ℝ) - 768 = 160 := by
  simp [bw, dotProduct, Fin.sum_univ_succ]; norm_num
-- Broken: prices (8, -6, 5) cover both products but price labour negative; the "ceiling" is
-- £880, £48 below the truth, which is -6 × 8 spare hours.
example : Awᵀ *ᵥ ![8, -6, 5] = ![19, 20] ∧ bw ⬝ᵥ ![8, -6, 5] = 880 := by
  refine ⟨?_, ?_⟩
  · ext j; fin_cases j <;> simp [Aw, mulVec, dotProduct, Fin.sum_univ_succ] <;> norm_num
  · simp [bw, dotProduct, Fin.sum_univ_succ]; norm_num
example : (928 : ℤ) - 880 = 48 ∧ (-6 : ℤ) * 8 = -48 := by decide
-- An order for 40 chairs: finish plus twice the order rule gives x1 ≤ 64 - 80 = -16.
example : (64 : ℤ) + 2 * (-40) = -16 := by decide
-- Along w = (0, 0, 1, 2) the dual value falls by £16 a step: 928 - 160 = 768, 928 - 1600 = -672.
example : (928 : ℤ) - 16 * 10 = 768 ∧ (928 : ℤ) - 16 * 100 = -672 := by decide

#print axioms lp_strong_duality
#print axioms lp_weak_duality_and_gap
#print axioms lp_complementary_slackness

end LPDuality
