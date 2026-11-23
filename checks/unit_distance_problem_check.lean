-- The unit-distance problem: Erdős's square grid puts n points in the plane with at least 2^(t-1) n pairs exactly one apart when its squared step is a product of t different primes leaving remainder 1 on division by 4, that step can be drawn in exactly 4 × 2^t ways, and two points in the plane never share more than two unit-distance neighbours.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Data.Int.Interval
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Data.Nat.Sqrt
import Mathlib.Data.Set.Card
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.NumberTheory.SumTwoSquares
import Mathlib.NumberTheory.Zsqrtd.GaussianInt
import Mathlib.Geometry.Euclidean.Basic

/-! A set of points in the plane is a finite set of distinct points of
`EuclideanSpace ℝ (Fin 2)`, and distance is the straight-line distance `dist`. -/

/-- The unit distances of a finite plane set: the pairs of its points exactly 1 apart.
Each pair is counted once from each end in `offDiag`, so the count is halved. -/
noncomputable def unitPairs (S : Finset (EuclideanSpace ℝ (Fin 2))) : ℕ :=
  (S.offDiag.filter (fun pq => dist pq.1 pq.2 = 1)).card / 2

/-- r₂(m): the whole-number steps (a, b) with a² + b² = m, signs and order counted.
Every such step has |a|, |b| ≤ √m, so the search box loses none. -/
def r2 (m : ℕ) : ℕ :=
  ((Finset.Icc (-(Nat.sqrt m : ℤ)) (Nat.sqrt m) ×ˢ Finset.Icc (-(Nat.sqrt m : ℤ)) (Nat.sqrt m)).filter
    (fun ab => ab.1 ^ 2 + ab.2 ^ 2 = (m : ℤ))).card

/-- The k by k grid of whole-number points (x, y), 0 ≤ x, y < k. -/
def gridPts (k : ℕ) : Finset (ℤ × ℤ) :=
  (Finset.range k ×ˢ Finset.range k).image (fun p => ((p.1 : ℤ), (p.2 : ℤ)))

/-- Pairs of grid points at squared distance m, each pair counted once. -/
def gridPairs (k m : ℕ) : ℕ :=
  ((gridPts k).offDiag.filter
    (fun pq => (pq.1.1 - pq.2.1) ^ 2 + (pq.1.2 - pq.2.2) ^ 2 = (m : ℤ))).card / 2

lemma r2_box_mem (m : ℕ) (ab : ℤ × ℤ) :
    ab ∈ (Finset.Icc (-(Nat.sqrt m : ℤ)) (Nat.sqrt m) ×ˢ Finset.Icc (-(Nat.sqrt m : ℤ)) (Nat.sqrt m)).filter
      (fun ab => ab.1 ^ 2 + ab.2 ^ 2 = (m : ℤ)) ↔ ab.1 ^ 2 + ab.2 ^ 2 = (m : ℤ) := by
  obtain ⟨a, b⟩ := ab
  simp only [Finset.mem_filter, Finset.mem_product, Finset.mem_Icc]
  constructor
  · exact fun h => h.2
  · intro h
    refine ⟨⟨?_, ?_⟩, h⟩
    · have ha : a.natAbs ^ 2 ≤ m := by
        have : ((a.natAbs ^ 2 : ℕ) : ℤ) ≤ m := by
          push_cast; rw [sq_abs]; nlinarith [sq_nonneg b]
        exact_mod_cast this
      have := Nat.le_sqrt'.mpr ha
      omega
    · have hb : b.natAbs ^ 2 ≤ m := by
        have : ((b.natAbs ^ 2 : ℕ) : ℤ) ≤ m := by
          push_cast; rw [sq_abs]; nlinarith [sq_nonneg a]
        exact_mod_cast this
      have := Nat.le_sqrt'.mpr hb
      omega

lemma r2_eq_card_gauss (m : ℕ) :
    r2 m = (((Finset.Icc (-(Nat.sqrt m : ℤ)) (Nat.sqrt m) ×ˢ Finset.Icc (-(Nat.sqrt m : ℤ)) (Nat.sqrt m)).filter
      (fun ab => ab.1 ^ 2 + ab.2 ^ 2 = (m : ℤ))).image (fun ab => (⟨ab.1, ab.2⟩ : GaussianInt))).card := by
  rw [Finset.card_image_of_injective]
  · rfl
  · intro x y h
    simp only [Zsqrtd.mk.injEq] at h
    exact Prod.ext h.1 h.2

lemma gauss_mem_iff (m : ℕ) (z : GaussianInt) :
    z ∈ ((Finset.Icc (-(Nat.sqrt m : ℤ)) (Nat.sqrt m) ×ˢ Finset.Icc (-(Nat.sqrt m : ℤ)) (Nat.sqrt m)).filter
      (fun ab => ab.1 ^ 2 + ab.2 ^ 2 = (m : ℤ))).image (fun ab => (⟨ab.1, ab.2⟩ : GaussianInt)) ↔
      z.norm = m := by
  rw [Finset.mem_image]
  constructor
  · rintro ⟨ab, hab, rfl⟩
    rw [r2_box_mem] at hab
    rw [Zsqrtd.norm_def, ← hab]; ring
  · intro h
    refine ⟨(z.re, z.im), ?_, rfl⟩
    rw [r2_box_mem, ← h, Zsqrtd.norm_def]; ring

lemma gauss_prime_of_norm_prime (z : GaussianInt) (p : ℕ) (hp : p.Prime) (hz : z.norm = p) :
    Prime z := by
  have hirr : Irreducible z := by
    refine ⟨fun hu => ?_, fun x y hxy => ?_⟩
    · have := (Zsqrtd.norm_eq_one_iff' (by norm_num) z).mpr hu
      rw [hz] at this
      exact hp.one_lt.ne' (by exact_mod_cast this)
    · have h1 : (x.norm.natAbs) * (y.norm.natAbs) = p := by
        rw [← Int.natAbs_mul, ← Zsqrtd.norm_mul, ← hxy, hz]; rfl
      rw [← h1] at hp
      rcases Nat.prime_mul_iff.mp hp with ⟨_, h⟩ | ⟨_, h⟩
      · exact Or.inr (Zsqrtd.norm_eq_one_iff.mp h)
      · exact Or.inl (Zsqrtd.norm_eq_one_iff.mp h)
  exact hirr.prime

lemma gauss_norm_dvd {x y : GaussianInt} (h : x ∣ y) : x.norm ∣ y.norm := by
  obtain ⟨c, rfl⟩ := h
  exact ⟨c.norm, Zsqrtd.norm_mul x c⟩

lemma gauss_card_split (m p : ℕ) (hp : p.Prime) (hp4 : p % 4 = 1) (hpm : ¬ p ∣ m)
    (A B : Finset GaussianInt) (hA : ∀ z, z ∈ A ↔ z.norm = ((p * m : ℕ) : ℤ))
    (hB : ∀ z, z ∈ B ↔ z.norm = (m : ℤ)) : A.card = 2 * B.card := by
  have := Fact.mk hp
  obtain ⟨a, b, hab⟩ := Nat.Prime.sq_add_sq (p := p) (by omega)
  set π : GaussianInt := ⟨a, b⟩ with hπdef
  set π' : GaussianInt := star π with hπ'def
  have hnπ : π.norm = p := by
    rw [Zsqrtd.norm_def, ← hab]; push_cast; ring
  have hnπ' : π'.norm = p := by rw [hπ'def, Zsqrtd.norm_conj, hnπ]
  have hpπ : Prime π := gauss_prime_of_norm_prime π p hp hnπ
  have hpπ' : Prime π' := gauss_prime_of_norm_prime π' p hp hnπ'
  have hp0 : (p : ℤ) ≠ 0 := by exact_mod_cast hp.ne_zero
  have hpZ : Prime (p : ℤ) := Nat.prime_iff_prime_int.mp hp
  -- star π does not divide π
  have hndvd : ¬ π' ∣ π := by
    intro h
    have h1 : π' ∣ (⟨2 * a, 0⟩ : GaussianInt) := by
      have : (⟨2 * a, 0⟩ : GaussianInt) = π + π' := by
        rw [hπ'def, hπdef, Zsqrtd.star_mk]; ext <;> simp; ring
      rw [this]; exact dvd_add h dvd_rfl
    have h2 : π' ∣ (⟨0, 2 * b⟩ : GaussianInt) := by
      have : (⟨0, 2 * b⟩ : GaussianInt) = π - π' := by
        rw [hπ'def, hπdef, Zsqrtd.star_mk]; ext <;> simp; ring
      rw [this]; exact dvd_sub h dvd_rfl
    have n1 := gauss_norm_dvd h1
    have n2 := gauss_norm_dvd h2
    rw [hnπ', Zsqrtd.norm_def] at n1 n2
    simp only at n1 n2
    have hp2 : ¬ (p : ℤ) ∣ 2 := by
      intro h2
      have : p ∣ 2 := by exact_mod_cast h2
      have := Nat.le_of_dvd (by norm_num) this
      have := hp.two_le
      omega
    have ha : (p : ℤ) ∣ a := by
      have : (p : ℤ) ∣ 2 * (2 * ((a : ℤ) * a)) := by
        have e : (2 * (a : ℤ) * (2 * a) - -1 * 0 * 0) = 2 * (2 * ((a : ℤ) * a)) := by ring
        rw [← e]; exact n1
      rcases hpZ.dvd_or_dvd this with h | h
      · exact absurd h hp2
      rcases hpZ.dvd_or_dvd h with h | h
      · exact absurd h hp2
      rcases hpZ.dvd_or_dvd h with h | h <;> exact h
    have hb : (p : ℤ) ∣ b := by
      have : (p : ℤ) ∣ 2 * (2 * ((b : ℤ) * b)) := by
        have e : ((0:ℤ) * 0 - -1 * (2 * b) * (2 * b)) = 2 * (2 * ((b : ℤ) * b)) := by ring
        rw [← e]; exact n2
      rcases hpZ.dvd_or_dvd this with h | h
      · exact absurd h hp2
      rcases hpZ.dvd_or_dvd h with h | h
      · exact absurd h hp2
      rcases hpZ.dvd_or_dvd h with h | h <;> exact h
    have : (p : ℤ) * p ∣ p * 1 := by
      have e : ((p : ℤ) * 1) = (a : ℤ) * a + b * b := by rw [← hab]; push_cast; ring
      rw [e]; exact dvd_add (mul_dvd_mul ha ha) (mul_dvd_mul hb hb)
    have h1 := (mul_dvd_mul_iff_left hp0).mp this
    have : p ∣ 1 := by exact_mod_cast h1
    exact hp.one_lt.ne' (Nat.dvd_one.mp this)
  have hnotdvd : ∀ w : GaussianInt, w.norm = m → ¬ π' ∣ w := by
    intro w hw h
    have := gauss_norm_dvd h
    rw [hnπ', hw] at this
    exact hpm (by exact_mod_cast this)
  have hsplit : A = (B).image (π * ·) ∪ (B).image (π' * ·) := by
    ext z
    rw [Finset.mem_union, Finset.mem_image, Finset.mem_image, hA]
    constructor
    · intro hz
      have hdvd : π ∣ z * star z := by
        rw [← Zsqrtd.norm_eq_mul_conj, hz]
        refine ⟨π' * (m : GaussianInt), ?_⟩
        rw [← mul_assoc, hπ'def, ← Zsqrtd.norm_eq_mul_conj, hnπ]; push_cast; ring
      rcases hpπ.dvd_or_dvd hdvd with ⟨w, hw⟩ | ⟨w, hw⟩
      · left
        refine ⟨w, ?_, hw.symm⟩
        rw [hB]
        rw [hw, Zsqrtd.norm_mul, hnπ] at hz
        push_cast at hz
        exact mul_left_cancel₀ hp0 hz
      · right
        have hz' : z = π' * star w := by
          rw [← star_star z, hw, star_mul, mul_comm]
        refine ⟨star w, ?_, hz'.symm⟩
        rw [hB]
        rw [hz', Zsqrtd.norm_mul, hnπ'] at hz
        push_cast at hz
        exact mul_left_cancel₀ hp0 hz
    · rintro (⟨w, hw, rfl⟩ | ⟨w, hw, rfl⟩) <;> rw [hB] at hw <;>
        rw [Zsqrtd.norm_mul, hw] <;> [rw [hnπ]; rw [hnπ']] <;> push_cast <;> ring
  have hπ0 : π ≠ 0 := hpπ.ne_zero
  have hπ'0 : π' ≠ 0 := hpπ'.ne_zero
  have hdisj : Disjoint ((B).image (π * ·)) ((B).image (π' * ·)) := by
    rw [Finset.disjoint_left]
    rintro z hz1 hz2
    rw [Finset.mem_image] at hz1 hz2
    obtain ⟨w, hw, rfl⟩ := hz1
    obtain ⟨w', hw', he⟩ := hz2
    rw [hB] at hw hw'
    have : π' ∣ π * w := ⟨w', he.symm⟩
    rcases hpπ'.dvd_or_dvd this with h | h
    · exact hndvd h
    · exact hnotdvd w hw h
  rw [hsplit, Finset.card_union_of_disjoint hdisj,
    Finset.card_image_of_injective _ (mul_right_injective₀ hπ0),
    Finset.card_image_of_injective _ (mul_right_injective₀ hπ'0)]
  ring

lemma r2_mul_prime (m p : ℕ) (hp : p.Prime) (hp4 : p % 4 = 1) (hpm : ¬ p ∣ m) :
    r2 (p * m) = 2 * r2 m := by
  rw [r2_eq_card_gauss, r2_eq_card_gauss]
  exact gauss_card_split m p hp hp4 hpm _ _ (gauss_mem_iff _) (gauss_mem_iff _)

lemma r2_prod_primes_helper (P : Finset ℕ)
    (hprime : ∀ p ∈ P, p.Prime) (hmod : ∀ p ∈ P, p % 4 = 1) :
    r2 (∏ p ∈ P, p) = 4 * 2 ^ P.card := by
  induction P using Finset.induction_on with
  | empty => simp only [Finset.prod_empty, Finset.card_empty]; decide
  | insert p P hpP ih =>
    have hp := hprime p (Finset.mem_insert_self p P)
    rw [Finset.prod_insert hpP, Finset.card_insert_of_notMem hpP,
      r2_mul_prime _ _ hp (hmod p (Finset.mem_insert_self p P)),
      ih (fun q hq => hprime q (Finset.mem_insert_of_mem hq))
        (fun q hq => hmod q (Finset.mem_insert_of_mem hq))]
    · ring
    · intro hdvd
      obtain ⟨q, hq, hpq⟩ := (Prime.dvd_finsetProd_iff hp.prime _).mp hdvd
      have hqp := hprime q (Finset.mem_insert_of_mem hq)
      have : p = q := (Nat.prime_dvd_prime_iff_eq hp hqp).mp hpq
      exact hpP (this ▸ hq)

lemma gridPts_mem (k : ℕ) (x y : ℤ) :
    (x, y) ∈ gridPts k ↔ 0 ≤ x ∧ x < k ∧ 0 ≤ y ∧ y < k := by
  simp only [gridPts, Finset.mem_image, Finset.mem_product, Finset.mem_range, Prod.mk.injEq,
    Prod.exists]
  constructor
  · rintro ⟨a, b, ⟨ha, hb⟩, rfl, rfl⟩
    omega
  · rintro ⟨h1, h2, h3, h4⟩
    exact ⟨x.toNat, y.toNat, ⟨by omega, by omega⟩, by omega, by omega⟩

lemma gridPts_card (k : ℕ) : (gridPts k).card = k ^ 2 := by
  rw [gridPts, Finset.card_image_of_injective, Finset.card_product, Finset.card_range, sq]
  intro p q h
  simp only [Prod.mk.injEq, Nat.cast_inj] at h
  exact Prod.ext h.1 h.2

lemma grid_ordered_ge (m : ℕ) (hm : 0 < m) :
    r2 m * ((Nat.sqrt m + 1) * (Nat.sqrt m + 1)) ≤
      ((gridPts (2 * (Nat.sqrt m + 1))).offDiag.filter
        (fun pq => (pq.1.1 - pq.2.1) ^ 2 + (pq.1.2 - pq.2.2) ^ 2 = (m : ℤ))).card := by
  unfold r2
  rw [show (Nat.sqrt m + 1) * (Nat.sqrt m + 1) =
      (Finset.range (Nat.sqrt m + 1) ×ˢ Finset.range (Nat.sqrt m + 1)).card by simp,
    ← Finset.card_product]
  refine Finset.card_le_card_of_injOn
    (fun x : (ℤ × ℤ) × (ℕ × ℕ) =>
      (((x.2.1 : ℤ) + max x.1.1 0, (x.2.2 : ℤ) + max x.1.2 0),
       ((x.2.1 : ℤ) + max (-x.1.1) 0, (x.2.2 : ℤ) + max (-x.1.2) 0))) ?_ ?_
  · rintro ⟨⟨a, b⟩, ⟨i, j⟩⟩ hx
    simp only [Finset.coe_product, Finset.coe_filter, Set.mem_prod, Set.mem_ofPred_eq,
      Finset.mem_product, Finset.mem_Icc, Finset.coe_range, Set.mem_Iio] at hx
    obtain ⟨⟨⟨⟨ha1, ha2⟩, hb1, hb2⟩, hab⟩, hi, hj⟩ := hx
    simp only [Finset.coe_filter, Finset.mem_offDiag, Set.mem_ofPred_eq, gridPts_mem]
    have e1 : (i : ℤ) + max a 0 - ((i : ℤ) + max (-a) 0) = a := by omega
    have e2 : (j : ℤ) + max b 0 - ((j : ℤ) + max (-b) 0) = b := by omega
    rw [e1, e2]
    refine ⟨⟨⟨by omega, by push_cast; omega, by omega, by push_cast; omega⟩,
      ⟨by omega, by push_cast; omega, by omega, by push_cast; omega⟩, ?_⟩, hab⟩
    intro h
    simp only [Prod.mk.injEq] at h
    have ha : a = 0 := by omega
    have hb : b = 0 := by omega
    subst ha hb
    simp at hab
    omega
  · rintro ⟨⟨a, b⟩, ⟨i, j⟩⟩ _ ⟨⟨a', b'⟩, ⟨i', j'⟩⟩ _ h
    simp only [Prod.mk.injEq] at h
    obtain ⟨⟨h1, h2⟩, h3, h4⟩ := h
    have ha : a = a' := by omega
    have hb : b = b' := by omega
    subst ha hb
    have hi : i = i' := by omega
    have hj : j = j' := by omega
    subst hi hj
    rfl

/-- Two grid points shrunk by √m are exactly 1 apart when their squared step is m. -/
lemma dist_scaled (m : ℕ) (hm : 0 < m) (p q : ℤ × ℤ) :
    dist (!₂[(p.1 : ℝ) / √m, (p.2 : ℝ) / √m]) (!₂[(q.1 : ℝ) / √m, (q.2 : ℝ) / √m]) = 1 ↔
      (p.1 - q.1) ^ 2 + (p.2 - q.2) ^ 2 = (m : ℤ) := by
  have hm' : (0 : ℝ) < m := by exact_mod_cast hm
  have hs : (√(m : ℝ)) ^ 2 = m := Real.sq_sqrt hm'.le
  have hs0 : √(m : ℝ) ≠ 0 := (Real.sqrt_pos.mpr hm').ne'
  rw [EuclideanSpace.dist_eq, Real.sqrt_eq_one, Fin.sum_univ_two]
  simp only [Matrix.cons_val_zero, Matrix.cons_val_one, Real.dist_eq, sq_abs]
  have e : ((p.1 : ℝ) / √m - q.1 / √m) ^ 2 + ((p.2 : ℝ) / √m - q.2 / √m) ^ 2 =
      ((((p.1 - q.1) ^ 2 + (p.2 - q.2) ^ 2 : ℤ) : ℝ)) / m := by
    rw [div_sub_div_same, div_sub_div_same, div_pow, div_pow, hs, ← add_div]; push_cast; ring
  rw [e, div_eq_one_iff_eq hm'.ne']
  exact_mod_cast Iff.rfl

lemma scaled_injective (m : ℕ) (hm : 0 < m) :
    Function.Injective (fun p : ℤ × ℤ => (!₂[(p.1 : ℝ) / √m, (p.2 : ℝ) / √m] :
      EuclideanSpace ℝ (Fin 2))) := by
  have hm' : (0 : ℝ) < m := by exact_mod_cast hm
  have hs0 : √(m : ℝ) ≠ 0 := (Real.sqrt_pos.mpr hm').ne'
  intro p q h
  have h0 := congrArg (fun v : EuclideanSpace ℝ (Fin 2) => v 0) h
  have h1 := congrArg (fun v : EuclideanSpace ℝ (Fin 2) => v 1) h
  simp only [Matrix.cons_val_zero, Matrix.cons_val_one] at h0 h1
  rw [div_left_inj' hs0] at h0 h1
  exact Prod.ext (by exact_mod_cast h0) (by exact_mod_cast h1)

lemma unitPairs_scaled (k m : ℕ) (hm : 0 < m) :
    unitPairs ((gridPts k).image (fun p : ℤ × ℤ => (!₂[(p.1 : ℝ) / √m, (p.2 : ℝ) / √m] :
      EuclideanSpace ℝ (Fin 2)))) = gridPairs k m := by
  unfold unitPairs gridPairs
  congr 1
  set F := (fun p : ℤ × ℤ => (!₂[(p.1 : ℝ) / √m, (p.2 : ℝ) / √m] :
      EuclideanSpace ℝ (Fin 2))) with hF
  have hinj : Function.Injective F := scaled_injective m hm
  symm
  refine Finset.card_bij (fun pq _ => (F pq.1, F pq.2)) ?_ ?_ ?_
  · rintro ⟨p, q⟩ h
    simp only [Finset.mem_filter, Finset.mem_offDiag] at h ⊢
    refine ⟨⟨Finset.mem_image_of_mem F h.1.1, Finset.mem_image_of_mem F h.1.2.1,
      fun e => h.1.2.2 (hinj e)⟩, ?_⟩
    exact (dist_scaled m hm p q).mpr h.2
  · rintro ⟨p, q⟩ _ ⟨p', q'⟩ _ h
    simp only [Prod.mk.injEq] at h
    rw [hinj h.1, hinj h.2]
  · rintro ⟨x, y⟩ h
    simp only [Finset.mem_filter, Finset.mem_offDiag, Finset.mem_image] at h
    obtain ⟨⟨⟨p, hp, rfl⟩, ⟨q, hq, rfl⟩, hne⟩, hd⟩ := h
    refine ⟨(p, q), ?_, rfl⟩
    simp only [Finset.mem_filter, Finset.mem_offDiag]
    exact ⟨⟨hp, hq, fun e => hne (by rw [e])⟩, (dist_scaled m hm p q).mp hd⟩

/-- Erdős's grid (Step 3). Let m be the product of t different primes, each leaving
remainder 1 on division by 4, let s be the whole number just above √m, and take the
square grid of side k = 2s, so n = k² points. Shrunk so that its step of length √m
becomes 1, it is a set of n distinct points in the plane with at least 2^(t-1) n pairs
exactly one apart: u(n) ≥ 2^(t-1) n. -/
theorem erdos_grid_unit_distance_lower_bound (P : Finset ℕ)
    (hprime : ∀ p ∈ P, p.Prime) (hmod : ∀ p ∈ P, p % 4 = 1) :
    ∃ S : Finset (EuclideanSpace ℝ (Fin 2)),
      S.card = (2 * (Nat.sqrt (∏ p ∈ P, p) + 1)) ^ 2 ∧
      2 ^ (P.card - 1) * S.card ≤ unitPairs S := by
  have hm0 : 0 < ∏ p ∈ P, p := Finset.prod_pos (fun p hp => (hprime p hp).pos)
  refine ⟨(gridPts (2 * (Nat.sqrt (∏ p ∈ P, p) + 1))).image
    (fun p : ℤ × ℤ => (!₂[(p.1 : ℝ) / √(∏ p ∈ P, p : ℕ), (p.2 : ℝ) / √(∏ p ∈ P, p : ℕ)] :
      EuclideanSpace ℝ (Fin 2))), ?_, ?_⟩
  · rw [Finset.card_image_of_injective _ (scaled_injective _ hm0), gridPts_card]
  · rw [Finset.card_image_of_injective _ (scaled_injective _ hm0), gridPts_card,
      unitPairs_scaled _ _ hm0]
    rcases Nat.eq_zero_or_pos P.card with h0 | hpos
    · rw [Finset.card_eq_zero] at h0
      subst h0
      simp only [Finset.prod_empty, Finset.card_empty]
      decide +kernel
    · have hge := grid_ordered_ge _ hm0
      rw [r2_prod_primes_helper P hprime hmod] at hge
      unfold gridPairs
      rw [Nat.le_div_iff_mul_le (by norm_num)]
      obtain ⟨t, ht⟩ : ∃ t, P.card = t + 1 := ⟨P.card - 1, by omega⟩
      rw [ht] at hge
      rw [ht, Nat.add_sub_cancel]
      calc 2 ^ t * (2 * (Nat.sqrt (∏ p ∈ P, p) + 1)) ^ 2 * 2
          = 4 * 2 ^ (t + 1) * ((Nat.sqrt (∏ p ∈ P, p) + 1) * (Nat.sqrt (∏ p ∈ P, p) + 1)) := by
            ring
        _ ≤ _ := hge

/-- Each new prime doubles the steps (Step 2). If m is the product of t different primes,
each leaving remainder 1 on division by 4, then m is a sum of two whole squares in exactly
4 × 2^t ways, signs and order counted. -/
theorem r2_prod_primes_one_mod_four (P : Finset ℕ)
    (hprime : ∀ p ∈ P, p.Prime) (hmod : ∀ p ∈ P, p % 4 = 1) :
    r2 (∏ p ∈ P, p) = 4 * 2 ^ P.card := by
  exact r2_prod_primes_helper P hprime hmod

/-- The two-circles rule (Step 4). Two different points of the plane have at most two
points at distance exactly 1 from both, because two different unit circles meet in at
most two points. -/
theorem at_most_two_shared_unit_neighbours (p q : EuclideanSpace ℝ (Fin 2)) (hpq : p ≠ q) :
    {x : EuclideanSpace ℝ (Fin 2) | dist x p = 1 ∧ dist x q = 1}.encard ≤ 2 := by
  set A := {x : EuclideanSpace ℝ (Fin 2) | dist x p = 1 ∧ dist x q = 1}
  by_cases h : ∃ a ∈ A, ∃ b ∈ A, a ≠ b
  · obtain ⟨a, ha, b, hb, hab⟩ := h
    have hsub : A ⊆ {a, b} := by
      intro x hx
      have := EuclideanGeometry.eq_of_dist_eq_of_dist_eq_of_finrank_eq_two
        (by simp) hpq hab ha.1 hb.1 hx.1 ha.2 hb.2 hx.2
      simpa using this
    calc A.encard ≤ ({a, b} : Set _).encard := Set.encard_le_encard hsub
      _ ≤ 2 := by
        rw [Set.encard_pair hab]
  · push Not at h
    have : A.encard ≤ 1 := Set.encard_le_one_iff.mpr (fun a b ha hb => h a ha b hb)
    exact this.trans (by norm_num)

-- The 3 by 3 grid: 12 pairs at distance 1 (6 across, 6 up).
example : gridPairs 3 1 = 12 := by decide
-- The 5 by 5 board: 40 pairs at distance 1, 32 at squared distance 2,
-- 48 knight's moves at squared distance 5, 8 at squared distance 25.
example : gridPairs 5 1 = 40 := by decide
example : gridPairs 5 2 = 32 := by decide
example : gridPairs 5 5 = 48 := by decide
example : gridPairs 5 25 = 8 := by decide
-- The knight's move by hand: 8 steps, each fitting (5 - 1)(5 - 2) = 12 times, 96 ordered, 48 pairs.
example : r2 5 = 8 ∧ (5 - 1) * (5 - 2) = 12 ∧ 8 * 12 = 96 ∧ 96 / 2 = 48 := by decide +kernel
-- r₂(m) for the card's list: 5, 15, 25, 45, 65, 325, 1105.
example : r2 5 = 8 := by decide +kernel
example : r2 15 = 0 := by decide +kernel
example : r2 25 = 12 := by decide +kernel
example : r2 45 = 8 := by decide +kernel
example : r2 65 = 16 := by decide +kernel
example : r2 325 = 24 := by decide +kernel
example : r2 1105 = 32 := by decide +kernel
-- Erdős's grid for t = 1: m = 5, s = 3, side 6, n = 36, and 80 pairs ≥ 2^0 × 36.
example : Nat.sqrt 5 + 1 = 3 ∧ gridPairs 6 5 = 80 ∧ 2 ^ 0 * 36 ≤ 80 := by decide +kernel
-- The first six primes leaving remainder 1 multiply to the card's m values.
example : 5 * 13 = 65 ∧ 65 * 17 = 1105 ∧ 1105 * 29 = 32045 ∧ 32045 * 37 = 1185665 ∧
    1185665 * 41 = 48612265 := by norm_num
-- t = 6: s = 6973, side 13,946, and the guarantee 2^5 × 13946² = 6,223,709,312.
example : Nat.sqrt 48612265 + 1 = 6973 ∧ 2 ^ 5 * 13946 ^ 2 = 6223709312 := by decide +kernel

#print axioms erdos_grid_unit_distance_lower_bound
#print axioms r2_prod_primes_one_mod_four
#print axioms at_most_two_shared_unit_neighbours
#print axioms r2_box_mem
#print axioms r2_eq_card_gauss
#print axioms gauss_mem_iff
#print axioms gauss_prime_of_norm_prime
#print axioms gauss_norm_dvd
#print axioms gauss_card_split
#print axioms r2_mul_prime
#print axioms r2_prod_primes_helper
#print axioms gridPts_mem
#print axioms gridPts_card
#print axioms grid_ordered_ge
#print axioms dist_scaled
#print axioms scaled_injective
#print axioms unitPairs_scaled
