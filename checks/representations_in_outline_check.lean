-- Representation: a finite group's kept subspace always has a kept complement, and the snowflake's twelve moves shuffle its six arm lengths as a representation that splits into four unsplittable kept pieces of sizes 1, 1, 2 and 2.
import Mathlib.GroupTheory.SpecificGroups.Dihedral
import Mathlib.RepresentationTheory.Basic
import Mathlib.Algebra.DirectSum.Module
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.LinearAlgebra.Span.Defs
import Mathlib.Algebra.Module.Equiv.Basic
import Mathlib.Data.ZMod.Defs
import Mathlib.Basic.Real.Basic
import Mathlib.LinearAlgebra.DirectSum.Finite
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas

open DihedralGroup

namespace RepresentationsInOutline

/-- Where the snowflake move `g` sends arm `i`. The arms are numbered 0 to 5 anticlockwise,
as `ZMod 6`. `r k` is the turn by `60° · k`, so `r 1` is R60; `sr k` is a flip, so `sr 0` is
F30 (the flip through arm 0) and `sr 1` is F0 (the flip between arms 0 and 5). -/
def armMove : DihedralGroup 6 → ZMod 6 → ZMod 6
  | r k, i => i + k
  | sr k, i => -k - i

/-- The arm shuffle `ρ(g)`: the number written on an arm travels with the arm, so the new
list has at arm `j` the number the old list had at the arm that `g` sends to `j`. -/
def rho (g : DihedralGroup 6) : (ZMod 6 → ℝ) →ₗ[ℝ] (ZMod 6 → ℝ) :=
  LinearMap.funLeft ℝ ℝ (armMove g⁻¹)

/-- A subspace of the arm space is kept when every move's matrix maps it into itself. -/
def Kept (W : Submodule ℝ (ZMod 6 → ℝ)) : Prop :=
  ∀ g : DihedralGroup 6, ∀ w ∈ W, rho g w ∈ W

/-- A kept piece is unsplittable (irreducible) when it is not zero and its only kept
subspaces are zero and itself. -/
def Unsplittable (W : Submodule ℝ (ZMod 6 → ℝ)) : Prop :=
  W ≠ ⊥ ∧ ∀ U : Submodule ℝ (ZMod 6 → ℝ), U ≤ W → Kept U → U = ⊥ ∨ U = W

/-- A list of six arm lengths, given arm by arm. -/
def armList (a b c d e f : ℝ) : ZMod 6 → ℝ :=
  fun i => ![a, b, c, d, e, f] (i : Fin 6)

/-- The all-equal line: lists like 1, 1, 1, 1, 1, 1. -/
def Weq : Submodule ℝ (ZMod 6 → ℝ) := Submodule.span ℝ {armList 1 1 1 1 1 1}

/-- The alternating line: lists like +1, −1, +1, −1, +1, −1. -/
def Walt : Submodule ℝ (ZMod 6 → ℝ) := Submodule.span ℝ {armList 1 (-1) 1 (-1) 1 (-1)}

/-- The tilt plane, the waves once round. With arm `i` at angle `θ_i = 30° + 60° · i`,
`sin θ_i = ½ · (1, 2, 1, −1, −2, −1)` and `cos θ_i = (√3/2) · (1, 0, −1, −1, 0, 1)`, so these
two whole-number lists span the same plane as `cos θ_i` and `sin θ_i`. -/
def Wtilt : Submodule ℝ (ZMod 6 → ℝ) :=
  Submodule.span ℝ {armList 1 2 1 (-1) (-2) (-1), armList 1 0 (-1) (-1) 0 1}

/-- The three-wave plane, the waves twice round:
`cos 2θ_i = ½ · (1, −2, 1, 1, −2, 1)` and `sin 2θ_i = (√3/2) · (1, 0, −1, 1, 0, −1)`. -/
def W3 : Submodule ℝ (ZMod 6 → ℝ) :=
  Submodule.span ℝ {armList 1 (-2) 1 1 (-2) 1, armList 1 0 (-1) 1 0 (-1)}

/-! ### Helper lemmas -/

lemma rho_r1 (a b c d e f : ℝ) :
    rho (r 1) (armList a b c d e f) = armList f a b c d e := by
  funext j; fin_cases j <;> rfl

lemma rho_sr0 (a b c d e f : ℝ) :
    rho (sr 0) (armList a b c d e f) = armList a f e d c b := by
  funext j; fin_cases j <;> rfl

lemma armList_add (a b c d e f a' b' c' d' e' f' : ℝ) :
    armList a b c d e f + armList a' b' c' d' e' f' =
      armList (a + a') (b + b') (c + c') (d + d') (e + e') (f + f') := by
  funext j; fin_cases j <;> rfl

lemma armList_smul (t a b c d e f : ℝ) :
    t • armList a b c d e f = armList (t * a) (t * b) (t * c) (t * d) (t * e) (t * f) := by
  funext j; fin_cases j <;> rfl

lemma armList_eq_iff {a b c d e f a' b' c' d' e' f' : ℝ} :
    armList a b c d e f = armList a' b' c' d' e' f' ↔
      a = a' ∧ b = b' ∧ c = c' ∧ d = d' ∧ e = e' ∧ f = f' := by
  constructor
  · intro h
    exact ⟨congrFun h 0, congrFun h 1, congrFun h 2, congrFun h 3, congrFun h 4, congrFun h 5⟩
  · rintro ⟨rfl, rfl, rfl, rfl, rfl, rfl⟩; rfl

lemma eq_armList (x : ZMod 6 → ℝ) : x = armList (x 0) (x 1) (x 2) (x 3) (x 4) (x 5) := by
  funext j; fin_cases j <;> rfl

lemma zero_eq_armList : (0 : ZMod 6 → ℝ) = armList 0 0 0 0 0 0 := by
  funext j; fin_cases j <;> rfl

lemma armMove_inv_one : ∀ i : ZMod 6, armMove (1 : DihedralGroup 6)⁻¹ i = i := by decide

lemma armMove_inv_mul : ∀ g h : DihedralGroup 6, ∀ i : ZMod 6,
    armMove (g * h)⁻¹ i = armMove h⁻¹ (armMove g⁻¹ i) := by decide

lemma armMove_inv_cancel : ∀ g : DihedralGroup 6, ∀ i : ZMod 6,
    armMove g⁻¹ (armMove g i) = i := by decide

lemma rho_one : rho 1 = LinearMap.id := by
  apply LinearMap.ext; intro x; funext i
  show x (armMove 1⁻¹ i) = x i
  rw [armMove_inv_one]

lemma rho_mul (g h : DihedralGroup 6) : rho (g * h) = rho g ∘ₗ rho h := by
  apply LinearMap.ext; intro x; funext i
  show x (armMove (g * h)⁻¹ i) = x (armMove h⁻¹ (armMove g⁻¹ i))
  rw [armMove_inv_mul]

lemma kept_of_gen (W : Submodule ℝ (ZMod 6 → ℝ))
    (h1 : ∀ w ∈ W, rho (r 1) w ∈ W) (h2 : ∀ w ∈ W, rho (sr 0) w ∈ W) : Kept W := by
  have hpow : ∀ n : ℕ, ∀ w ∈ W, rho ((r 1) ^ n) w ∈ W := by
    intro n
    induction n with
    | zero => intro w hw; simpa [rho_one] using hw
    | succ n ih =>
      intro w hw
      rw [pow_succ, rho_mul, LinearMap.comp_apply]
      exact ih _ (h1 w hw)
  have hr : ∀ k : ZMod 6, ∀ w ∈ W, rho (r k) w ∈ W := by
    intro k w hw
    rw [← ZMod.natCast_zmod_val k, ← r_one_pow]
    exact hpow _ w hw
  intro g w hw
  cases g with
  | r k => exact hr k w hw
  | sr k =>
    have : (sr k : DihedralGroup 6) = sr 0 * r k := by rw [sr_mul_r, zero_add]
    rw [this, rho_mul, LinearMap.comp_apply]
    exact h2 _ (hr k w hw)

lemma kept_span (s : Set (ZMod 6 → ℝ))
    (h1 : ∀ v ∈ s, rho (r 1) v ∈ Submodule.span ℝ s)
    (h2 : ∀ v ∈ s, rho (sr 0) v ∈ Submodule.span ℝ s) : Kept (Submodule.span ℝ s) := by
  apply kept_of_gen
  · intro w hw
    have : Submodule.span ℝ s ≤ (Submodule.span ℝ s).comap (rho (r 1)) :=
      Submodule.span_le.mpr h1
    exact this hw
  · intro w hw
    have : Submodule.span ℝ s ≤ (Submodule.span ℝ s).comap (rho (sr 0)) :=
      Submodule.span_le.mpr h2
    exact this hw

lemma unsplittable_line (W : Submodule ℝ (ZMod 6 → ℝ)) (hdim : Module.finrank ℝ W = 1) :
    Unsplittable W := by
  refine ⟨?_, ?_⟩
  · intro h; rw [h, finrank_bot] at hdim; exact absurd hdim (by norm_num)
  · intro U hUW _
    by_cases hbot : U = ⊥
    · exact Or.inl hbot
    right
    apply Submodule.eq_of_le_of_finrank_eq hUW
    have h1 := Submodule.finrank_mono hUW
    have h0 : Module.finrank ℝ U ≠ 0 := fun h => hbot (Submodule.finrank_eq_zero.mp h)
    omega

lemma unsplittable_plane (W : Submodule ℝ (ZMod 6 → ℝ)) (hdim : Module.finrank ℝ W = 2)
    (s : ℝ) (hs : ∀ c : ℝ, c * c + s * c + 1 ≠ 0)
    (hT : ∀ w ∈ W, rho (r 1) (rho (r 1) w) + s • rho (r 1) w + w = 0) :
    Unsplittable W := by
  refine ⟨?_, ?_⟩
  · intro h; rw [h, finrank_bot] at hdim; exact absurd hdim (by norm_num)
  · intro U hUW hU
    by_cases hbot : U = ⊥
    · exact Or.inl hbot
    right
    by_contra hne
    have hlt : U < W := lt_of_le_of_ne hUW hne
    have h1 := Submodule.finrank_lt_finrank_of_lt hlt
    have h0 : Module.finrank ℝ U ≠ 0 := fun h => hbot (Submodule.finrank_eq_zero.mp h)
    have hU1 : Module.finrank ℝ U = 1 := by omega
    obtain ⟨v, hv0, hv⟩ := finrank_eq_one_iff'.mp hU1
    obtain ⟨c, hc⟩ := hv ⟨rho (r 1) v, hU (r 1) v v.2⟩
    have hc' : c • (v : ZMod 6 → ℝ) = rho (r 1) v := congrArg Subtype.val hc
    have key := hT v (hUW v.2)
    rw [← hc', map_smul, ← hc'] at key
    have hz : (c * c + s * c + 1) • (v : ZMod 6 → ℝ) = 0 := by
      rw [add_smul, add_smul, mul_smul, mul_smul, one_smul]; exact key
    rcases smul_eq_zero.mp hz with h | h
    · exact hs c h
    · exact hv0 (Subtype.ext h)

lemma finrank_pair (v w : ZMod 6 → ℝ)
    (h : ∀ s t : ℝ, s • v + t • w = 0 → s = 0 ∧ t = 0) :
    Module.finrank ℝ (Submodule.span ℝ {v, w}) = 2 := by
  rw [← Matrix.range_cons_cons_empty v w ![], finrank_span_eq_card]
  · simp
  · exact LinearIndependent.pair_iff.mpr h

lemma finrank_Weq : Module.finrank ℝ Weq = 1 := by
  apply finrank_span_singleton
  intro h
  have := congrFun h 0
  exact one_ne_zero this

lemma finrank_Walt : Module.finrank ℝ Walt = 1 := by
  apply finrank_span_singleton
  intro h
  have := congrFun h 0
  exact one_ne_zero this

lemma finrank_Wtilt : Module.finrank ℝ Wtilt = 2 := by
  apply finrank_pair
  intro s t h
  rw [armList_smul, armList_smul, armList_add, zero_eq_armList, armList_eq_iff] at h
  obtain ⟨h0, h1, -, -, -, -⟩ := h
  constructor <;> linarith

lemma finrank_W3 : Module.finrank ℝ W3 = 2 := by
  apply finrank_pair
  intro s t h
  rw [armList_smul, armList_smul, armList_add, zero_eq_armList, armList_eq_iff] at h
  obtain ⟨h0, h1, -, -, -, -⟩ := h
  constructor <;> linarith

lemma kept_Weq : Kept Weq := by
  apply kept_span
  · intro v hv; rw [Set.mem_singleton_iff] at hv; subst hv
    rw [rho_r1]; exact Submodule.subset_span rfl
  · intro v hv; rw [Set.mem_singleton_iff] at hv; subst hv
    rw [rho_sr0]; exact Submodule.subset_span rfl

lemma kept_Walt : Kept Walt := by
  apply kept_span
  · intro v hv; rw [Set.mem_singleton_iff] at hv; subst hv
    rw [rho_r1]
    refine Submodule.mem_span_singleton.mpr ⟨-1, ?_⟩
    rw [armList_smul, armList_eq_iff]; norm_num
  · intro v hv; rw [Set.mem_singleton_iff] at hv; subst hv
    rw [rho_sr0]; exact Submodule.subset_span rfl

lemma kept_Wtilt : Kept Wtilt := by
  apply kept_span
  · intro v hv
    rcases hv with rfl | hv
    · rw [rho_r1]
      refine Submodule.mem_span_pair.mpr ⟨1/2, -3/2, ?_⟩
      rw [armList_smul, armList_smul, armList_add, armList_eq_iff]; norm_num
    · rw [Set.mem_singleton_iff] at hv; subst hv
      rw [rho_r1]
      refine Submodule.mem_span_pair.mpr ⟨1/2, 1/2, ?_⟩
      rw [armList_smul, armList_smul, armList_add, armList_eq_iff]; norm_num
  · intro v hv
    rcases hv with rfl | hv
    · rw [rho_sr0]
      refine Submodule.mem_span_pair.mpr ⟨-1/2, 3/2, ?_⟩
      rw [armList_smul, armList_smul, armList_add, armList_eq_iff]; norm_num
    · rw [Set.mem_singleton_iff] at hv; subst hv
      rw [rho_sr0]
      refine Submodule.mem_span_pair.mpr ⟨1/2, 1/2, ?_⟩
      rw [armList_smul, armList_smul, armList_add, armList_eq_iff]; norm_num

lemma kept_W3 : Kept W3 := by
  apply kept_span
  · intro v hv
    rcases hv with rfl | hv
    · rw [rho_r1]
      refine Submodule.mem_span_pair.mpr ⟨-1/2, 3/2, ?_⟩
      rw [armList_smul, armList_smul, armList_add, armList_eq_iff]; norm_num
    · rw [Set.mem_singleton_iff] at hv; subst hv
      rw [rho_r1]
      refine Submodule.mem_span_pair.mpr ⟨-1/2, -1/2, ?_⟩
      rw [armList_smul, armList_smul, armList_add, armList_eq_iff]; norm_num
  · intro v hv
    rcases hv with rfl | hv
    · rw [rho_sr0]
      refine Submodule.mem_span_pair.mpr ⟨-1/2, 3/2, ?_⟩
      rw [armList_smul, armList_smul, armList_add, armList_eq_iff]; norm_num
    · rw [Set.mem_singleton_iff] at hv; subst hv
      rw [rho_sr0]
      refine Submodule.mem_span_pair.mpr ⟨1/2, 1/2, ?_⟩
      rw [armList_smul, armList_smul, armList_add, armList_eq_iff]; norm_num

lemma rot_Wtilt : ∀ w ∈ Wtilt, rho (r 1) (rho (r 1) w) + (-1 : ℝ) • rho (r 1) w + w = 0 := by
  intro w hw
  obtain ⟨a, b, rfl⟩ := Submodule.mem_span_pair.mp hw
  rw [armList_smul, armList_smul, armList_add, rho_r1, rho_r1, armList_smul, armList_add,
    armList_add, zero_eq_armList, armList_eq_iff]
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> ring

lemma rot_W3 : ∀ w ∈ W3, rho (r 1) (rho (r 1) w) + (1 : ℝ) • rho (r 1) w + w = 0 := by
  intro w hw
  obtain ⟨a, b, rfl⟩ := Submodule.mem_span_pair.mp hw
  rw [armList_smul, armList_smul, armList_add, rho_r1, rho_r1, armList_smul, armList_add,
    armList_add, zero_eq_armList, armList_eq_iff]
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> ring

lemma isInternal_four : DirectSum.IsInternal ![Weq, Walt, Wtilt, W3] := by
  classical
  set A := ![Weq, Walt, Wtilt, W3] with hA
  have hsurj : Function.Surjective (DirectSum.coeLinearMap A) := by
    intro x
    set α : ℝ := (x 0 + x 1 + x 2 + x 3 + x 4 + x 5) / 6
    set β : ℝ := (x 0 - x 1 + x 2 - x 3 + x 4 - x 5) / 6
    set a : ℝ := (x 0 + 2 * x 1 + x 2 - x 3 - 2 * x 4 - x 5) / 12
    set b : ℝ := (x 0 - x 2 - x 3 + x 5) / 4
    set c : ℝ := (x 0 - 2 * x 1 + x 2 + x 3 - 2 * x 4 + x 5) / 12
    set d : ℝ := (x 0 - x 2 + x 3 - x 5) / 4
    have m0 : α • armList 1 1 1 1 1 1 ∈ A 0 :=
      Submodule.smul_mem _ _ (Submodule.subset_span rfl)
    have m1 : β • armList 1 (-1) 1 (-1) 1 (-1) ∈ A 1 :=
      Submodule.smul_mem _ _ (Submodule.subset_span rfl)
    have m2 : a • armList 1 2 1 (-1) (-2) (-1) + b • armList 1 0 (-1) (-1) 0 1 ∈ A 2 :=
      Submodule.mem_span_pair.mpr ⟨a, b, rfl⟩
    have m3 : c • armList 1 (-2) 1 1 (-2) 1 + d • armList 1 0 (-1) 1 0 (-1) ∈ A 3 :=
      Submodule.mem_span_pair.mpr ⟨c, d, rfl⟩
    refine ⟨DirectSum.of (fun i => A i) 0 ⟨_, m0⟩ + DirectSum.of (fun i => A i) 1 ⟨_, m1⟩ +
      DirectSum.of (fun i => A i) 2 ⟨_, m2⟩ + DirectSum.of (fun i => A i) 3 ⟨_, m3⟩, ?_⟩
    simp only [map_add, DirectSum.coeLinearMap_of]
    rw [armList_smul, armList_smul, armList_smul, armList_smul, armList_smul, armList_smul,
      armList_add, armList_add, armList_add, armList_add, armList_add]
    conv_rhs => rw [eq_armList x]
    rw [armList_eq_iff]
    simp only [α, β, a, b, c, d]
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> ring
  have hdim : Module.finrank ℝ (DirectSum _ fun i => ↥(A i)) =
      Module.finrank ℝ (ZMod 6 → ℝ) := by
    rw [Module.finrank_directSum, Fin.sum_univ_four, Module.finrank_fintype_fun_eq_card,
      ZMod.card]
    show Module.finrank ℝ Weq + Module.finrank ℝ Walt + Module.finrank ℝ Wtilt +
      Module.finrank ℝ W3 = 6
    rw [finrank_Weq, finrank_Walt, finrank_Wtilt, finrank_W3]
  have hinj : Function.Injective (DirectSum.coeLinearMap A) := by
    exact (LinearMap.injective_iff_surjective_of_finrank_eq_finrank (K := ℝ)
      (V := DirectSum _ fun i => ↥(A i)) (V₂ := ZMod 6 → ℝ) hdim).mpr hsurj
  exact ⟨hinj, hsurj⟩


/-- Splitting is guaranteed for a finite group: for a representation `ρ : G → GL(V)` of a
finite group on a real vector space, every subspace that all the matrices `ρ(g)` map into
itself has a complement that all the `ρ(g)` also map into itself, so the symmetry never
mixes the kept piece with the rest. -/
theorem kept_subspace_has_kept_complement {G V : Type*} [Group G] [Finite G]
    [AddCommGroup V] [Module ℝ V] (ρ : Representation ℝ G V) (W : Submodule ℝ V)
    (hW : ∀ g : G, ∀ w ∈ W, ρ g w ∈ W) :
    ∃ W' : Submodule ℝ V, IsCompl W W' ∧ ∀ g : G, ∀ w ∈ W', ρ g w ∈ W' := by
  classical
  have := Fintype.ofFinite G
  obtain ⟨q, hq⟩ := Submodule.exists_isCompl W
  set π : V →ₗ[ℝ] W := Submodule.projectionOnto W q hq with hπ
  set P : V →ₗ[ℝ] V := (Fintype.card G : ℝ)⁻¹ • ∑ g : G, ρ g⁻¹ ∘ₗ W.subtype ∘ₗ π ∘ₗ ρ g
    with hP
  have hPapp : ∀ v, P v = (Fintype.card G : ℝ)⁻¹ • ∑ g : G, ρ g⁻¹ (π (ρ g v) : V) := by
    intro v
    simp [hP, LinearMap.sum_apply]
  have hinv : ∀ (g : G) (x : V), ρ g⁻¹ (ρ g x) = x := by
    intro g x
    rw [← Module.End.mul_apply, ← map_mul, inv_mul_cancel, map_one, Module.End.one_apply]
  have hPW : ∀ v, P v ∈ W := by
    intro v
    rw [hPapp]
    exact W.smul_mem _ (W.sum_mem fun g _ => hW g⁻¹ _ (π (ρ g v)).2)
  have hPid : ∀ w ∈ W, P w = w := by
    intro w hw
    have hterm : ∀ g : G, ρ g⁻¹ (π (ρ g w) : V) = w := by
      intro g
      have h1 : π (ρ g w) = ⟨ρ g w, hW g w hw⟩ :=
        Submodule.projectionOnto_apply_left hq ⟨ρ g w, hW g w hw⟩
      rw [h1]
      exact hinv g w
    rw [hPapp]
    simp only [hterm, Finset.sum_const, Finset.card_univ]
    rw [← Nat.cast_smul_eq_nsmul ℝ, smul_smul, inv_mul_cancel₀, one_smul]
    exact Nat.cast_ne_zero.mpr Fintype.card_ne_zero
  have hequiv : ∀ h v, P (ρ h v) = ρ h (P v) := by
    intro h v
    rw [hPapp, hPapp, map_smul, map_sum]
    congr 1
    refine Fintype.sum_equiv (Equiv.mulRight h) _ _ ?_
    intro g
    simp only [Equiv.coe_mulRight]
    rw [mul_inv_rev, map_mul ρ h⁻¹ g⁻¹, map_mul ρ g h, Module.End.mul_apply,
      Module.End.mul_apply, ← Module.End.mul_apply (ρ h), ← map_mul, mul_inv_cancel, map_one,
      Module.End.one_apply]
  set f : V →ₗ[ℝ] W := P.codRestrict W hPW with hf
  have hfx : ∀ x : W, f x = x := fun x => Subtype.ext (hPid x x.2)
  refine ⟨LinearMap.ker f, LinearMap.isCompl_of_proj hfx, ?_⟩
  intro g w hw
  rw [LinearMap.mem_ker] at hw ⊢
  have hw' : P w = 0 := congrArg Subtype.val hw
  apply Subtype.ext
  show P (ρ g w) = 0
  rw [hequiv, hw', map_zero]

/-- The arm shuffles are a representation of the snowflake's group of twelve moves on the
space of six-number lists: they respect combining, `ρ(gh) = ρ(g) ρ(h)` for all moves `g` and
`h`, and the number on arm `i` travels to arm `g(i)`, `(ρ(g) x)_{g(i)} = x_i`. -/
theorem arm_shuffle_is_representation :
    (∃ ρ : Representation ℝ (DihedralGroup 6) (ZMod 6 → ℝ), ∀ g, ρ g = rho g) ∧
    (∀ g h : DihedralGroup 6, rho (g * h) = rho g ∘ₗ rho h) ∧
    (∀ (g : DihedralGroup 6) (x : ZMod 6 → ℝ) (i : ZMod 6), rho g x (armMove g i) = x i) := by
  refine ⟨⟨{ toFun := rho, map_one' := rho_one, map_mul' := rho_mul }, fun g => rfl⟩,
    rho_mul, ?_⟩
  intro g x i
  simp [rho, LinearMap.funLeft_apply, armMove_inv_cancel]

/-- The arm space splits into four pieces that no move mixes: the all-equal line, the
alternating line, the tilt plane and the three-wave plane are each kept by every move and
cannot be split further, every list is in exactly one way a sum of one list from each, and
their dimensions are `6 = 1 + 1 + 2 + 2`. -/
theorem arm_space_splits_into_four_kept_pieces :
    (Kept Weq ∧ Kept Walt ∧ Kept Wtilt ∧ Kept W3) ∧
    (Unsplittable Weq ∧ Unsplittable Walt ∧ Unsplittable Wtilt ∧ Unsplittable W3) ∧
    DirectSum.IsInternal ![Weq, Walt, Wtilt, W3] ∧
    (Module.finrank ℝ Weq = 1 ∧ Module.finrank ℝ Walt = 1 ∧
      Module.finrank ℝ Wtilt = 2 ∧ Module.finrank ℝ W3 = 2) := by
  refine ⟨⟨kept_Weq, kept_Walt, kept_Wtilt, kept_W3⟩,
    ⟨unsplittable_line _ finrank_Weq, unsplittable_line _ finrank_Walt,
      unsplittable_plane _ finrank_Wtilt (-1) ?_ rot_Wtilt,
      unsplittable_plane _ finrank_W3 1 ?_ rot_W3⟩, ?_,
    ⟨finrank_Weq, finrank_Walt, finrank_Wtilt, finrank_W3⟩⟩
  · intro c h; nlinarith [sq_nonneg (c - 1/2)]
  · intro c h; nlinarith [sq_nonneg (c + 1/2)]
  · exact isInternal_four

-- Step 1's table: where R60, F30 and F0 send arms 0, 1, 2, 3, 4, 5.
example : [0, 1, 2, 3, 4, 5].map (armMove (r 1)) = [1, 2, 3, 4, 5, 0] := by decide
example : [0, 1, 2, 3, 4, 5].map (armMove (sr 0)) = [0, 5, 4, 3, 2, 1] := by decide
example : [0, 1, 2, 3, 4, 5].map (armMove (sr 1)) = [5, 4, 3, 2, 1, 0] := by decide

-- Moving arms respects combining on all 144 pairs of moves.
example : ∀ g h : DihedralGroup 6, ∀ i : ZMod 6, armMove (g * h) i = armMove g (armMove h i) := by
  decide

-- Mistake 1: reading the shuffle backwards composes in reverse order and fails for 72 of 144 pairs.
example : (Finset.univ.filter (fun p : DihedralGroup 6 × DihedralGroup 6 =>
    ∃ i : ZMod 6, armMove (p.1 * p.2) i ≠ armMove p.2 (armMove p.1 i))).card = 72 := by
  decide

-- Step 5: arms left in place, summed over the 12 moves, is 12 (average 1),
-- and their squares sum to 48 (average 4).
example : ∑ g : DihedralGroup 6, (Finset.univ.filter (fun i : ZMod 6 => armMove g i = i)).card
    = 12 := by decide
example : ∑ g : DihedralGroup 6, (Finset.univ.filter (fun i : ZMod 6 => armMove g i = i)).card ^ 2
    = 48 := by decide

-- Worked numbers in hundredths of a millimetre: total 600, alternating sum 48, alternating part 8.
example : (112 + 96 + 108 + 92 + 104 + 88 : ℤ) = 600 := by norm_num
example : (112 - 96 + 108 - 92 + 104 - 88 : ℤ) = 48 ∧ (48 : ℤ) / 6 = 8 := by norm_num

-- The deviation 12, −4, 8, −8, 4, −12 is 8 · alternating + 2 · tilt + 2 · three-wave.
example : (![12, -4, 8, -8, 4, -12] : Fin 6 → ℤ)
    = 8 • ![1, -1, 1, -1, 1, -1] + 2 • ![1, 2, 1, -1, -2, -1] + 2 • ![1, 0, -1, 1, 0, -1] := by
  decide

-- Pythagoras on the sizes, in units of 0.0001 mm²: 384 + 48 + 16 = 448, the squared deviation.
example : (6 * 8 ^ 2 : ℤ) = 384 ∧ (2 ^ 2 + 4 ^ 2 + 2 ^ 2 + 2 ^ 2 + 4 ^ 2 + 2 ^ 2 : ℤ) = 48 ∧
    (4 * 2 ^ 2 : ℤ) = 16 ∧ (384 + 48 + 16 : ℤ) = 448 ∧
    (12 ^ 2 + 4 ^ 2 + 8 ^ 2 + 8 ^ 2 + 4 ^ 2 + 12 ^ 2 : ℤ) = 448 := by norm_num

-- R60 on the tilt plane (trace 1, det 1) and on the three-wave plane (trace −1, det 1):
-- tr² − 4 det = −3 both times, so no real kept line.
example : ((1 : ℤ) ^ 2 - 4 * 1 = -3) ∧ ((-1 : ℤ) ^ 2 - 4 * 1 = -3) := by norm_num

#print axioms rho_r1
#print axioms rho_sr0
#print axioms armList_add
#print axioms armList_smul
#print axioms armList_eq_iff
#print axioms eq_armList
#print axioms zero_eq_armList
#print axioms armMove_inv_one
#print axioms armMove_inv_mul
#print axioms armMove_inv_cancel
#print axioms rho_one
#print axioms rho_mul
#print axioms kept_of_gen
#print axioms kept_span
#print axioms unsplittable_line
#print axioms unsplittable_plane
#print axioms finrank_pair
#print axioms finrank_Weq
#print axioms finrank_Walt
#print axioms finrank_Wtilt
#print axioms finrank_W3
#print axioms kept_Weq
#print axioms kept_Walt
#print axioms kept_Wtilt
#print axioms kept_W3
#print axioms rot_Wtilt
#print axioms rot_W3
#print axioms isInternal_four
#print axioms kept_subspace_has_kept_complement
#print axioms arm_shuffle_is_representation
#print axioms arm_space_splits_into_four_kept_pieces

end RepresentationsInOutline
