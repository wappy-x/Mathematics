-- Modules: a finitely generated module over a principal ideal domain is free copies of the ring plus cyclic pieces R/(d_i) with each d_i dividing the next, and the card's example is Z ⊕ Z/2 ⊕ Z/6.
import Mathlib.Algebra.Module.PID
import Mathlib.LinearAlgebra.FreeModule.PID
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.LinearAlgebra.Matrix.Notation

open DirectSum

universe u v

lemma mulQ_exists {R : Type u} [CommRing R] (I J : Ideal R) (c : R) (h : ∀ x ∈ I, c * x ∈ J) :
    ∃ f : (R ⧸ I) →ₗ[R] (R ⧸ J), ∀ x : R, f (Ideal.Quotient.mk I x) = Ideal.Quotient.mk J (c * x) :=
  ⟨Submodule.mapQ I J (c • LinearMap.id) (fun x hx => by simpa using h x hx), fun x => rfl⟩

lemma pair_equiv {R : Type u} [CommRing R] (g a' b' u v : R) (h1 : u * a' + v * b' = 1) :
    Nonempty (((R ⧸ Ideal.span {g * a'}) × (R ⧸ Ideal.span {g * b'})) ≃ₗ[R]
      ((R ⧸ Ideal.span {g}) × (R ⧸ Ideal.span {g * a' * b'}))) := by
  have mem : ∀ (x y : R), y ∣ x → x ∈ Ideal.span {y} := fun x y h => Ideal.mem_span_singleton.mpr h
  -- forward pieces
  obtain ⟨f11, hf11⟩ := mulQ_exists (Ideal.span {g * a'}) (Ideal.span {g}) u (fun x hx => by
    obtain ⟨t, rfl⟩ := Ideal.mem_span_singleton.mp hx
    exact mem _ _ ⟨u * a' * t, by ring⟩)
  obtain ⟨f12, hf12⟩ := mulQ_exists (Ideal.span {g * b'}) (Ideal.span {g}) v (fun x hx => by
    obtain ⟨t, rfl⟩ := Ideal.mem_span_singleton.mp hx
    exact mem _ _ ⟨v * b' * t, by ring⟩)
  obtain ⟨f21, hf21⟩ := mulQ_exists (Ideal.span {g * a'}) (Ideal.span {g * a' * b'}) (-b')
    (fun x hx => by
    obtain ⟨t, rfl⟩ := Ideal.mem_span_singleton.mp hx
    exact mem _ _ ⟨-t, by ring⟩)
  obtain ⟨f22, hf22⟩ := mulQ_exists (Ideal.span {g * b'}) (Ideal.span {g * a' * b'}) a'
    (fun x hx => by
    obtain ⟨t, rfl⟩ := Ideal.mem_span_singleton.mp hx
    exact mem _ _ ⟨t, by ring⟩)
  -- backward pieces
  obtain ⟨g11, hg11⟩ := mulQ_exists (Ideal.span {g}) (Ideal.span {g * a'}) a' (fun x hx => by
    obtain ⟨t, rfl⟩ := Ideal.mem_span_singleton.mp hx
    exact mem _ _ ⟨t, by ring⟩)
  obtain ⟨g12, hg12⟩ := mulQ_exists (Ideal.span {g * a' * b'}) (Ideal.span {g * a'}) (-v)
    (fun x hx => by
    obtain ⟨t, rfl⟩ := Ideal.mem_span_singleton.mp hx
    exact mem _ _ ⟨-v * b' * t, by ring⟩)
  obtain ⟨g21, hg21⟩ := mulQ_exists (Ideal.span {g}) (Ideal.span {g * b'}) b' (fun x hx => by
    obtain ⟨t, rfl⟩ := Ideal.mem_span_singleton.mp hx
    exact mem _ _ ⟨t, by ring⟩)
  obtain ⟨g22, hg22⟩ := mulQ_exists (Ideal.span {g * a' * b'}) (Ideal.span {g * b'}) u
    (fun x hx => by
    obtain ⟨t, rfl⟩ := Ideal.mem_span_singleton.mp hx
    exact mem _ _ ⟨u * a' * t, by ring⟩)
  let F := (f11 ∘ₗ LinearMap.fst R _ _ + f12 ∘ₗ LinearMap.snd R _ _).prod
    (f21 ∘ₗ LinearMap.fst R _ _ + f22 ∘ₗ LinearMap.snd R _ _)
  let G := (g11 ∘ₗ LinearMap.fst R _ _ + g12 ∘ₗ LinearMap.snd R _ _).prod
    (g21 ∘ₗ LinearMap.fst R _ _ + g22 ∘ₗ LinearMap.snd R _ _)
  have hF : ∀ x y : R, F (Ideal.Quotient.mk _ x, Ideal.Quotient.mk _ y) =
      (Ideal.Quotient.mk _ (u * x + v * y), Ideal.Quotient.mk _ (-b' * x + a' * y)) := by
    intro x y; simp [F, hf11, hf12, hf21, hf22]
  have hG : ∀ x y : R, G (Ideal.Quotient.mk _ x, Ideal.Quotient.mk _ y) =
      (Ideal.Quotient.mk _ (a' * x + -v * y), Ideal.Quotient.mk _ (b' * x + u * y)) := by
    intro x y; simp [G, hg11, hg12, hg21, hg22]
  refine ⟨LinearEquiv.ofLinearMap F G ?_ ?_⟩
  · refine LinearMap.ext fun ⟨p, q⟩ => ?_
    obtain ⟨x, rfl⟩ := Ideal.Quotient.mk_surjective p
    obtain ⟨y, rfl⟩ := Ideal.Quotient.mk_surjective q
    simp only [LinearMap.comp_apply, LinearMap.id_apply, hG, hF, Prod.mk.injEq]
    constructor <;> congr 1
    · linear_combination x * h1
    · linear_combination y * h1
  · refine LinearMap.ext fun ⟨p, q⟩ => ?_
    obtain ⟨x, rfl⟩ := Ideal.Quotient.mk_surjective p
    obtain ⟨y, rfl⟩ := Ideal.Quotient.mk_surjective q
    simp only [LinearMap.comp_apply, LinearMap.id_apply, hG, hF, Prod.mk.injEq]
    constructor <;> congr 1
    · linear_combination x * h1
    · linear_combination y * h1

lemma pair_equiv' {R : Type u} [CommRing R] (a b g a' b' u v : R) (ha : a = g * a')
    (hb : b = g * b') (h1 : u * a' + v * b' = 1) :
    Nonempty (((R ⧸ Ideal.span {a}) × (R ⧸ Ideal.span {b})) ≃ₗ[R]
      ((R ⧸ Ideal.span {g}) × (R ⧸ Ideal.span {g * a' * b'}))) := by
  subst ha hb; exact pair_equiv g a' b' u v h1

lemma bezout_split {R : Type u} [CommRing R] [IsDomain R] [IsPrincipalIdealRing R]
    (a b : R) (ha : a ≠ 0) :
    ∃ g a' b' u v : R, a = g * a' ∧ b = g * b' ∧ u * a' + v * b' = 1 ∧ g ≠ 0 := by
  obtain ⟨g, hg⟩ := (Submodule.IsPrincipal.principal (Ideal.span {a, b} : Ideal R))
  have hg' : Ideal.span {a, b} = Ideal.span {g} := hg
  have hga : g ∣ a := Ideal.mem_span_singleton.mp (hg' ▸ Ideal.subset_span (by simp))
  have hgb : g ∣ b := Ideal.mem_span_singleton.mp (hg' ▸ Ideal.subset_span (by simp))
  obtain ⟨a', rfl⟩ := hga
  obtain ⟨b', rfl⟩ := hgb
  have hmem : g ∈ Ideal.span {g * a', g * b'} := hg' ▸ Ideal.mem_span_singleton_self g
  obtain ⟨u, v, huv⟩ := Ideal.mem_span_pair.mp hmem
  have g0 : g ≠ 0 := left_ne_zero_of_mul ha
  refine ⟨g, a', b', u, v, rfl, rfl, ?_, g0⟩
  apply mul_left_cancel₀ g0
  linear_combination huv

lemma insert_chain {R : Type u} [CommRing R] [IsDomain R] [IsPrincipalIdealRing R] :
    ∀ (s : ℕ) (d : Fin s → R) (b : R), (∀ i, d i ≠ 0) → (∀ i j : Fin s, i ≤ j → d i ∣ d j) →
      b ≠ 0 →
      ∃ e : Fin (s + 1) → R, (∀ i, e i ≠ 0) ∧ (∀ i j : Fin (s + 1), i ≤ j → e i ∣ e j) ∧
        (∀ c, c ∣ b → (∀ i, c ∣ d i) → ∀ i, c ∣ e i) ∧
        Nonempty (((R ⧸ Ideal.span {b}) × Π i, R ⧸ Ideal.span {d i}) ≃ₗ[R]
          Π i, R ⧸ Ideal.span {e i}) := by
  intro s
  induction s with
  | zero =>
    intro d b _ _ hb
    refine ⟨fun _ => b, fun _ => hb, fun _ _ _ => dvd_rfl, fun c hc _ _ => hc, ?_⟩
    exact ⟨(LinearEquiv.prodCongr (LinearEquiv.refl R _)
      (LinearEquiv.piCongrRight (fun i => i.elim0))).trans
      (Fin.consLinearEquiv R (fun _ : Fin 1 => R ⧸ Ideal.span {b}))⟩
  | succ s ih =>
    intro d b hd hch hb
    obtain ⟨g, a', b', u, v, ha, hbb, h1, g0⟩ := bezout_split (d 0) b (hd 0)
    have a0 : a' ≠ 0 := by rintro rfl; exact hd 0 (by simp [ha])
    have b0 : b' ≠ 0 := by rintro rfl; exact hb (by simp [hbb])
    have l0 : g * a' * b' ≠ 0 := mul_ne_zero (mul_ne_zero g0 a0) b0
    obtain ⟨e', he0, hech, hinv, ⟨E⟩⟩ := ih (fun i => d i.succ) (g * a' * b') (fun i => hd _)
      (fun i j hij => hch _ _ (Fin.succ_le_succ_iff.mpr hij)) l0
    obtain ⟨P⟩ := pair_equiv' (d 0) b g a' b' u v ha hbb h1
    have g_d : ∀ i, g ∣ d i := fun i => (Dvd.intro a' ha.symm).trans (hch 0 i (Fin.zero_le _))
    have g_l : g ∣ g * a' * b' := ⟨a' * b', by ring⟩
    refine ⟨Fin.cons g e', ?_, ?_, ?_, ?_⟩
    · intro i
      refine Fin.cases ?_ (fun i => ?_) i
      · simpa using g0
      · simpa using he0 i
    · intro i j hij
      induction i using Fin.cases with
      | zero =>
        induction j using Fin.cases with
        | zero => exact dvd_rfl
        | succ j =>
          simp only [Fin.cons_zero, Fin.cons_succ]
          exact hinv g g_l (fun i => g_d _) j
      | succ i =>
        induction j using Fin.cases with
        | zero => exact absurd hij (by simp)
        | succ j =>
          simp only [Fin.cons_succ]
          exact hech i j (Fin.succ_le_succ_iff.mp hij)
    · intro c hcb hcd i
      induction i using Fin.cases with
      | zero =>
        simp only [Fin.cons_zero]
        have : g = u * d 0 + v * b := by rw [ha, hbb]; linear_combination (-g) * h1
        rw [this]
        exact dvd_add (dvd_mul_of_dvd_right (hcd 0) _) (dvd_mul_of_dvd_right hcb _)
      | succ i =>
        simp only [Fin.cons_succ]
        exact hinv c (hcb.trans ⟨a', by rw [hbb]; ring⟩) (fun i => hcd _) i
    · exact ⟨LinearEquiv.prodCongr (LinearEquiv.refl R _)
          (Fin.consLinearEquiv R (fun i => R ⧸ Ideal.span {d i})).symm ≪≫ₗ
        (LinearEquiv.prodAssoc R _ _ _).symm ≪≫ₗ
        LinearEquiv.prodCongr (LinearEquiv.prodComm R _ _) (LinearEquiv.refl R _) ≪≫ₗ
        LinearEquiv.prodCongr P (LinearEquiv.refl R _) ≪≫ₗ
        LinearEquiv.prodAssoc R _ _ _ ≪≫ₗ
        LinearEquiv.prodCongr (LinearEquiv.refl R _) E ≪≫ₗ
        Fin.consLinearEquiv R (fun i => R ⧸ Ideal.span {(Fin.cons g e' : Fin (s + 2) → R) i})⟩

lemma chain_of_family {R : Type u} [CommRing R] [IsDomain R] [IsPrincipalIdealRing R] :
    ∀ (k : ℕ) (q : Fin k → R), (∀ j, q j ≠ 0) →
      ∃ (s : ℕ) (d : Fin s → R), (∀ i, d i ≠ 0) ∧ (∀ i j : Fin s, i ≤ j → d i ∣ d j) ∧
        Nonempty ((Π j, R ⧸ Ideal.span {q j}) ≃ₗ[R] Π i, R ⧸ Ideal.span {d i}) := by
  intro k
  induction k with
  | zero =>
    intro q _
    exact ⟨0, fun i => i.elim0, fun i => i.elim0, fun i => i.elim0,
      ⟨LinearEquiv.piCongrRight (fun i => i.elim0)⟩⟩
  | succ k ih =>
    intro q hq
    obtain ⟨s, d, hd, hch, ⟨E⟩⟩ := ih (fun j => q j.succ) (fun j => hq _)
    obtain ⟨e, he, hech, -, ⟨F⟩⟩ := insert_chain s d (q 0) hd hch (hq 0)
    exact ⟨s + 1, e, he, hech, ⟨(Fin.consLinearEquiv R (fun j => R ⧸ Ideal.span {q j})).symm ≪≫ₗ
      LinearEquiv.prodCongr (LinearEquiv.refl R _) E ≪≫ₗ F⟩⟩

lemma drop_units {R : Type u} [CommRing R] [IsDomain R] [IsPrincipalIdealRing R] :
    ∀ (n : ℕ) (e : Fin n → R), (∀ i, e i ≠ 0) → (∀ i j : Fin n, i ≤ j → e i ∣ e j) →
      ∃ (m : ℕ) (d : Fin m → R), (∀ i, d i ≠ 0 ∧ ¬ IsUnit (d i)) ∧
        (∀ i j : Fin m, i ≤ j → d i ∣ d j) ∧
        Nonempty ((Π j, R ⧸ Ideal.span {e j}) ≃ₗ[R] Π i, R ⧸ Ideal.span {d i}) := by
  intro n
  induction n with
  | zero =>
    intro e _ _
    exact ⟨0, fun i => i.elim0, fun i => i.elim0, fun i => i.elim0,
      ⟨LinearEquiv.piCongrRight (fun i => i.elim0)⟩⟩
  | succ n ih =>
    intro e he hch
    by_cases hu : IsUnit (e 0)
    · obtain ⟨m, d, hd, hdch, ⟨E⟩⟩ := ih (fun i => e i.succ) (fun i => he _)
        (fun i j hij => hch _ _ (Fin.succ_le_succ_iff.mpr hij))
      have htop : Ideal.span {e 0} = ⊤ := Ideal.span_singleton_eq_top.mpr hu
      have : Subsingleton (R ⧸ Ideal.span {e 0}) := Ideal.Quotient.subsingleton_iff.mpr htop
      have : Unique (R ⧸ Ideal.span {e 0}) := uniqueOfSubsingleton 0
      exact ⟨m, d, hd, hdch, ⟨(Fin.consLinearEquiv R (fun j => R ⧸ Ideal.span {e j})).symm ≪≫ₗ
        LinearEquiv.uniqueProd ≪≫ₗ E⟩⟩
    · refine ⟨n + 1, e, fun i => ⟨he i, fun hi => hu ?_⟩, hch, ⟨LinearEquiv.refl R _⟩⟩
      exact isUnit_of_dvd_unit (hch 0 i (Fin.zero_le _)) hi

#print axioms mulQ_exists
#print axioms pair_equiv
#print axioms pair_equiv'
#print axioms bezout_split
#print axioms insert_chain
#print axioms chain_of_family
#print axioms drop_units

/-- **Structure theorem, invariant-factor form.** Over a principal ideal domain R, every
finitely generated module M is the same module as m free copies of R plus s cyclic pieces
R/(d_1), ..., R/(d_s), where each d_i is a nonzero scalar with no inverse and each d_i
divides the next. -/
theorem structure_theorem_pid
    (R : Type u) [CommRing R] [IsDomain R] [IsPrincipalIdealRing R]
    (M : Type v) [AddCommGroup M] [Module R M] [Module.Finite R M] :
    ∃ (m s : ℕ) (d : Fin s → R),
      (∀ i, d i ≠ 0 ∧ ¬ IsUnit (d i)) ∧
      (∀ i j : Fin s, i ≤ j → d i ∣ d j) ∧
      Nonempty (M ≃ₗ[R] (Fin m → R) × ⨁ i : Fin s, R ⧸ Ideal.span {d i}) := by
  obtain ⟨n, ι, fι, p, hp, e, ⟨φ⟩⟩ := Module.equiv_free_prod_directSum R M
  let σ := Fintype.equivFin ι
  obtain ⟨s0, d0, hd0, hch0, ⟨E1⟩⟩ := chain_of_family (Fintype.card ι)
    (fun j => p (σ.symm j) ^ e (σ.symm j)) (fun j => pow_ne_zero _ (hp _).ne_zero)
  obtain ⟨s, d, hd, hch, ⟨E2⟩⟩ := drop_units s0 d0 hd0 hch0
  exact ⟨n, s, d, hd, hch, ⟨φ ≪≫ₗ LinearEquiv.prodCongr
    (Finsupp.linearEquivFunOnFinite R R (Fin n))
    (DirectSum.linearEquivFunOnFintype R ι (fun i => R ⧸ R ∙ p i ^ e i) ≪≫ₗ
      LinearEquiv.piCongrLeft' R (fun i => R ⧸ R ∙ p i ^ e i) σ ≪≫ₗ E1 ≪≫ₗ E2 ≪≫ₗ
      (DirectSum.linearEquivFunOnFintype R (Fin s) (fun i => R ⧸ Ideal.span {d i})).symm)⟩⟩

/-- **Step 1.** Over a principal ideal domain, every submodule K of the free module R^n
is free, of rank at most n: it has a basis of k members for some k ≤ n. -/
theorem submodule_of_free_is_free_rank_le
    (R : Type u) [CommRing R] [IsDomain R] [IsPrincipalIdealRing R]
    (n : ℕ) (K : Submodule R (Fin n → R)) :
    ∃ k ≤ n, Nonempty (Module.Basis (Fin k) R K) := by
  obtain ⟨k, b⟩ := Submodule.basisOfPid (Pi.basisFun R (Fin n)) K
  refine ⟨k, ?_, ⟨b⟩⟩
  have h := Submodule.finrank_le K
  rwa [Module.finrank_eq_card_basis b, Module.finrank_fin_fun, Fintype.card_fin] at h

/-- **The card's example.** The whole-number triples modulo the relations
r₁ = (2, 2, 2) and r₂ = (4, -2, -2) form the ℤ-module ℤ ⊕ ℤ/2 ⊕ ℤ/6. -/
theorem triples_mod_relations_equiv :
    Nonempty (((Fin 3 → ℤ) ⧸ Submodule.span ℤ {![2, 2, 2], ![4, -2, -2]})
      ≃ₗ[ℤ] ℤ × ZMod 2 × ZMod 6) := by
  let f : (Fin 3 → ℤ) →ₗ[ℤ] ℤ × ZMod 2 × ZMod 6 :=
    { toFun := fun v => (v 2 - v 1, ((v 0 : ℤ) : ZMod 2), ((v 0 - v 1 : ℤ) : ZMod 6))
      map_add' := by
        intro x y
        simp only [Pi.add_apply, Int.cast_add, Int.cast_sub, Prod.mk_add_mk, Prod.mk.injEq]
        refine ⟨by ring, trivial, by ring⟩
      map_smul' := by
        intro c x
        simp only [Pi.smul_apply, smul_eq_mul, Int.cast_mul, Int.cast_sub, RingHom.id_apply,
          Prod.smul_mk, zsmul_eq_mul, Prod.mk.injEq]
        refine ⟨by ring, trivial, by ring⟩ }
  have hf : ∀ v : Fin 3 → ℤ,
      f v = (v 2 - v 1, ((v 0 : ℤ) : ZMod 2), ((v 0 - v 1 : ℤ) : ZMod 6)) := fun v => rfl
  have hsurj : Function.Surjective f := by
    rintro ⟨n, a, b⟩
    obtain ⟨a', rfl⟩ := ZMod.intCast_surjective a
    obtain ⟨b', rfl⟩ := ZMod.intCast_surjective b
    refine ⟨![3 * a', 3 * a' - b', n + 3 * a' - b'], ?_⟩
    rw [hf]
    simp only [Matrix.cons_val, Prod.mk.injEq]
    refine ⟨by ring, ?_, by congr 1; ring⟩
    rw [ZMod.intCast_eq_intCast_iff_dvd_sub]
    exact ⟨-a', by push_cast; ring⟩
  have hker : LinearMap.ker f = Submodule.span ℤ {![2, 2, 2], ![4, -2, -2]} := by
    apply le_antisymm
    · intro v hv
      rw [LinearMap.mem_ker, hf, Prod.mk_eq_zero, Prod.mk_eq_zero] at hv
      obtain ⟨h2, h0, h01⟩ := hv
      obtain ⟨m, hm⟩ := (ZMod.intCast_zmod_eq_zero_iff_dvd (v 0) 2).mp h0
      obtain ⟨t, ht⟩ := (ZMod.intCast_zmod_eq_zero_iff_dvd (v 0 - v 1) 6).mp h01
      rw [Submodule.mem_span_pair]
      refine ⟨m - 2 * t, t, ?_⟩
      funext i
      fin_cases i <;> simp <;> push_cast at hm ht <;> linarith
    · rw [Submodule.span_le, Set.insert_subset_iff, Set.singleton_subset_iff]
      refine ⟨?_, ?_⟩ <;> simp only [SetLike.mem_coe, LinearMap.mem_ker, hf] <;> decide
  exact ⟨Submodule.quotEquivOfEq _ _ hker.symm ≪≫ₗ f.quotKerEquivOfSurjective hsurj⟩

-- S A T = D: the recorded row and column moves diagonalise the relation matrix.
example : !![(1 : ℤ), 0, 0; 1, -1, 0; 0, -1, 1] * !![(2 : ℤ), 4; 2, -2; 2, -2]
    * !![(1 : ℤ), -2; 0, 1] = !![(2 : ℤ), 0; 0, 6; 0, 0] := by decide

-- The moves can be undone: det S = -1 and det T = 1.
example : Matrix.det !![(1 : ℤ), 0, 0; 1, -1, 0; 0, -1, 1] = -1 := by
  simp [Matrix.det_fin_three]
example : Matrix.det !![(1 : ℤ), -2; 0, 1] = 1 := by
  simp [Matrix.det_fin_two]

-- The map (x, y, z) ↦ (x mod 2, x - y mod 6, z - y) sends both relations to zero.
example : (2 : ℤ) % 2 = 0 ∧ (2 - 2 : ℤ) % 6 = 0 ∧ (2 - 2 : ℤ) = 0 := by decide
example : (4 : ℤ) % 2 = 0 ∧ (4 - (-2) : ℤ) % 6 = 0 ∧ (-2 - (-2) : ℤ) = 0 := by decide

-- Orders: 6 · (1, 0, 0), 2 · (3, 3, 3) and 6 · (0, 1, 1) are whole-number mixes of r₁, r₂.
example : ((6 : ℤ) • ![1, 0, 0] : Fin 3 → ℤ) = (1 : ℤ) • ![2, 2, 2] + (1 : ℤ) • ![4, -2, -2] := by
  decide
example : ((2 : ℤ) • ![3, 3, 3] : Fin 3 → ℤ) = (3 : ℤ) • ![2, 2, 2] + (0 : ℤ) • ![4, -2, -2] := by
  decide
example : ((6 : ℤ) • ![0, 1, 1] : Fin 3 → ℤ) = (2 : ℤ) • ![2, 2, 2] + (-1 : ℤ) • ![4, -2, -2] := by
  decide

-- The torsion part ℤ/2 ⊕ ℤ/6 has 12 members, and 6 kills every one: no member of order 12.
example : Fintype.card (ZMod 2 × ZMod 6) = 12 := by decide
example : ∀ v : ZMod 2 × ZMod 6, 6 • v = 0 := by decide

-- Gcds of minors: g₁ = 2 and g₂ = 12, so d₁ = 2 and d₂ = 12 / 2 = 6.
example : Int.gcd (Int.gcd (Int.gcd 2 4) (Int.gcd 2 (-2))) (Int.gcd 2 (-2)) = 2 := by decide
example : Int.gcd (Int.gcd (2 * (-2) - 4 * 2) (2 * (-2) - 4 * 2)) (2 * (-2) - (-2) * 2) = 12 := by
  decide

-- |M/qM| = q · gcd(q, 2) · gcd(q, 6) for q = 1, ..., 12, as the card's listing prints.
example : (List.range 12).map (fun i => (i + 1) * Nat.gcd (i + 1) 2 * Nat.gcd (i + 1) 6)
    = [1, 8, 9, 16, 5, 72, 7, 32, 27, 40, 11, 144] := by decide

-- Mistake 3: (4, 4, 4) is twice r₁, so the two relations are dependent.
example : (![4, 4, 4] : Fin 3 → ℤ) = (2 : ℤ) • ![2, 2, 2] := by decide

#print axioms structure_theorem_pid
#print axioms submodule_of_free_is_free_rank_le
#print axioms triples_mod_relations_equiv
