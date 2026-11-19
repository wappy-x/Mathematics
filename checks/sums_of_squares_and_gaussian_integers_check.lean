-- Two squares: a prime is a sum of two whole squares exactly when it is 2 or leaves remainder 1 on division by 4, it is then a Gaussian integer times its mirror image, and every positive n is a sum of two squares in exactly 4 (d₁(n) − d₃(n)) ordered ways.
import Mathlib.NumberTheory.Zsqrtd.GaussianInt
import Mathlib.NumberTheory.SumTwoSquares
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.SetTheory.Cardinal.Finite
import Mathlib.NumberTheory.Zsqrtd.QuadraticReciprocity
import Mathlib.Data.Int.Interval

lemma gi_norm_eq (z : GaussianInt) : z.norm = z.re ^ 2 + z.im ^ 2 := by
  rw [Zsqrtd.norm_def]; ring

lemma gi_norm_set_finite (k : ℤ) : {z : GaussianInt | z.norm = k}.Finite := by
  have hinj : Function.Injective (fun z : GaussianInt => (z.re, z.im)) := by
    intro z w h
    simp only [Prod.mk.injEq] at h
    exact Zsqrtd.ext h.1 h.2
  apply Set.Finite.of_finite_image (f := fun z : GaussianInt => (z.re, z.im)) _ hinj.injOn
  apply ((Set.finite_Icc (-k) k).prod (Set.finite_Icc (-k) k)).subset
  rintro _ ⟨z, hz, rfl⟩
  simp only [Set.mem_ofPred_eq] at hz
  rw [gi_norm_eq] at hz
  have h1 := Int.le_self_sq z.re
  have h2 := Int.le_self_sq (-z.re)
  have h3 := Int.le_self_sq z.im
  have h4 := Int.le_self_sq (-z.im)
  rw [neg_sq] at h2 h4
  have h5 := sq_nonneg z.re
  have h6 := sq_nonneg z.im
  simp only [Set.mem_prod, Set.mem_Icc]
  refine ⟨⟨?_, ?_⟩, ?_, ?_⟩ <;> linarith

lemma gi_card_norm_one : Set.ncard {z : GaussianInt | z.norm = 1} = 4 := by
  have : {z : GaussianInt | z.norm = 1} =
      ↑({⟨1, 0⟩, ⟨-1, 0⟩, ⟨0, 1⟩, ⟨0, -1⟩} : Finset GaussianInt) := by
    ext ⟨x, y⟩
    simp only [Set.mem_ofPred_eq, Finset.coe_insert, Finset.coe_singleton, Set.mem_insert_iff,
      Set.mem_singleton_iff, Zsqrtd.ext_iff, gi_norm_eq]
    constructor
    · intro h
      have hx1 : -1 ≤ x := by nlinarith [sq_nonneg y]
      have hx2 : x ≤ 1 := by nlinarith [sq_nonneg y]
      have hy1 : -1 ≤ y := by nlinarith [sq_nonneg x]
      have hy2 : y ≤ 1 := by nlinarith [sq_nonneg x]
      interval_cases x <;> interval_cases y <;> simp_all
    · rintro (⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩) <;> norm_num
  rw [this, Set.ncard_coe_finset]
  decide

lemma gi_prime_of_norm_prime (π : GaussianInt) (h : π.norm.natAbs.Prime) : Prime π := by
  apply irreducible_iff_prime.1
  refine ⟨fun hu => h.ne_one (Zsqrtd.norm_eq_one_iff.2 hu), ?_⟩
  intro a b hab
  rw [hab, Zsqrtd.norm_mul, Int.natAbs_mul] at h
  rcases Nat.prime_mul_iff.1 h with ⟨_, hb⟩ | ⟨_, ha⟩
  · exact Or.inr (Zsqrtd.norm_eq_one_iff.1 hb)
  · exact Or.inl (Zsqrtd.norm_eq_one_iff.1 ha)

lemma gi_ncard_C (p n : ℕ) (hp : 0 < p) :
    Set.ncard {z : GaussianInt | (p : ℤ) * z.norm = (n : ℤ)} =
      if p ∣ n then Set.ncard {z : GaussianInt | z.norm = ((n / p : ℕ) : ℤ)} else 0 := by
  split_ifs with h
  · obtain ⟨k, rfl⟩ := h
    congr 1
    ext z
    simp only [Set.mem_ofPred_eq]
    rw [Nat.mul_div_cancel_left k hp]
    push_cast
    constructor
    · intro h; exact mul_left_cancel₀ (by exact_mod_cast hp.ne') h
    · intro h; rw [h]
  · have he : {z : GaussianInt | (p : ℤ) * z.norm = (n : ℤ)} = ∅ := by
      ext z
      simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false]
      intro hz
      apply h
      have : (p : ℤ) ∣ (n : ℤ) := ⟨_, hz.symm⟩
      exact_mod_cast this
    rw [he, Set.ncard_empty]

lemma gi_case_two (n : ℕ) :
    Set.ncard {z : GaussianInt | z.norm = ((2 * n : ℕ) : ℤ)} =
      Set.ncard {z : GaussianInt | z.norm = (n : ℤ)} := by
  have hπ : (⟨1, 1⟩ : GaussianInt) ≠ 0 := by
    intro h; have := congrArg Zsqrtd.re h; simp at this
  have hnπ : (⟨1, 1⟩ : GaussianInt).norm = 2 := by rw [gi_norm_eq]; norm_num
  have : {z : GaussianInt | z.norm = ((2 * n : ℕ) : ℤ)} =
      (fun w => (⟨1, 1⟩ : GaussianInt) * w) '' {z : GaussianInt | z.norm = (n : ℤ)} := by
    ext z
    simp only [Set.mem_ofPred_eq, Set.mem_image]
    constructor
    · intro hz
      rw [gi_norm_eq] at hz
      push_cast at hz
      have hev : Even ((z.re + z.im) ^ 2) := ⟨n + z.re * z.im, by linear_combination hz⟩
      obtain ⟨k, hk⟩ := (Int.even_pow.1 hev).1
      have hw : (⟨1, 1⟩ : GaussianInt) * ⟨k, k - z.re⟩ = z := by
        ext <;> simp [Zsqrtd.re_mul, Zsqrtd.im_mul]; linarith
      refine ⟨⟨k, k - z.re⟩, ?_, hw⟩
      have h2 := congrArg Zsqrtd.norm hw
      rw [Zsqrtd.norm_mul, hnπ, gi_norm_eq z, hz] at h2
      linarith
    · rintro ⟨w, hw, rfl⟩
      rw [Zsqrtd.norm_mul, hnπ, hw]; push_cast; ring
  rw [this, Set.ncard_image_of_injective _ (mul_right_injective₀ hπ)]

lemma gi_case_three (p n : ℕ) (hp : p.Prime) (h3 : p % 4 = 3) :
    Set.ncard {z : GaussianInt | z.norm = ((p * n : ℕ) : ℤ)} =
      Set.ncard {z : GaussianInt | (p : ℤ) * z.norm = (n : ℤ)} := by
  have := Fact.mk hp
  have hprime : Prime (p : GaussianInt) := GaussianInt.prime_of_nat_prime_of_mod_four_eq_three p h3
  have hp0 : (p : GaussianInt) ≠ 0 := hprime.ne_zero
  have hp0' : (p : ℤ) ≠ 0 := by exact_mod_cast hp.ne_zero
  have : {z : GaussianInt | z.norm = ((p * n : ℕ) : ℤ)} =
      (fun w => (p : GaussianInt) * w) '' {z : GaussianInt | (p : ℤ) * z.norm = (n : ℤ)} := by
    ext z
    simp only [Set.mem_ofPred_eq, Set.mem_image]
    constructor
    · intro hz
      have hdvd : (p : GaussianInt) ∣ z * star z := by
        rw [← Zsqrtd.norm_eq_mul_conj, hz]; push_cast; exact dvd_mul_right _ _
      rcases hprime.dvd_or_dvd hdvd with ⟨c, hc⟩ | ⟨c, hc⟩
      · refine ⟨c, ?_, hc.symm⟩
        have h2 := congrArg Zsqrtd.norm hc
        rw [hz, Zsqrtd.norm_mul, Zsqrtd.norm_natCast] at h2
        push_cast at h2
        apply mul_left_cancel₀ hp0'
        linarith
      · refine ⟨star c, ?_, ?_⟩
        · have h2 := congrArg Zsqrtd.norm hc
          rw [Zsqrtd.norm_conj, hz, Zsqrtd.norm_mul, Zsqrtd.norm_natCast] at h2
          push_cast at h2
          rw [Zsqrtd.norm_conj]
          apply mul_left_cancel₀ hp0'
          linarith
        · have h2 := congrArg star hc
          rw [star_star, star_mul', star_natCast] at h2
          exact h2.symm
    · rintro ⟨w, hw, rfl⟩
      rw [Zsqrtd.norm_mul, Zsqrtd.norm_natCast]
      push_cast
      rw [← hw]; ring
  rw [this, Set.ncard_image_of_injective _ (mul_right_injective₀ hp0)]

lemma gi_case_one (p n : ℕ) (hp : p.Prime) (h1 : p % 4 = 1) :
    (Set.ncard {z : GaussianInt | z.norm = ((p * n : ℕ) : ℤ)} : ℤ) =
      2 * (Set.ncard {z : GaussianInt | z.norm = (n : ℤ)} : ℤ) -
        (Set.ncard {z : GaussianInt | (p : ℤ) * z.norm = (n : ℤ)} : ℤ) := by
  have := Fact.mk hp
  obtain ⟨a, b, hab⟩ := Nat.Prime.sq_add_sq (p := p) (by omega)
  set π : GaussianInt := ⟨a, b⟩ with hπdef
  have hp0 : (p : ℤ) ≠ 0 := by exact_mod_cast hp.ne_zero
  have hnπ : π.norm = p := by
    rw [gi_norm_eq]; simp only [π]; exact_mod_cast hab
  have hnπ' : (star π).norm = p := by rw [Zsqrtd.norm_conj, hnπ]
  have hπ0 : π ≠ 0 := by
    intro h; rw [h, Zsqrtd.norm_zero] at hnπ; exact hp0 hnπ.symm
  have hπ0' : star π ≠ 0 := by
    intro h; rw [h, Zsqrtd.norm_zero] at hnπ'; exact hp0 hnπ'.symm
  have hprime : Prime π := gi_prime_of_norm_prime π (by rw [hnπ]; simpa using hp)
  have hprime' : Prime (star π) := gi_prime_of_norm_prime _ (by rw [hnπ']; simpa using hp)
  have hpmul : (p : GaussianInt) = π * star π := by
    rw [← Zsqrtd.norm_eq_mul_conj, hnπ]; simp
  -- the conjugate does not divide π
  have hndvd : ¬ star π ∣ π := by
    rintro ⟨c, hc⟩
    have hn := congrArg Zsqrtd.norm hc
    rw [Zsqrtd.norm_mul, hnπ, hnπ'] at hn
    have hc1 : c.norm = 1 := by
      apply mul_left_cancel₀ hp0; linarith
    rw [gi_norm_eq] at hc1
    have hre := congrArg Zsqrtd.re hc
    have him := congrArg Zsqrtd.im hc
    simp only [π, Zsqrtd.re_mul, Zsqrtd.im_mul, Zsqrtd.star_mk] at hre him
    obtain ⟨u, v⟩ := c
    simp only at hc1 hre him
    have hu1 : -1 ≤ u := by nlinarith [sq_nonneg v]
    have hu2 : u ≤ 1 := by nlinarith [sq_nonneg v]
    have hv1 : -1 ≤ v := by nlinarith [sq_nonneg u]
    have hv2 : v ≤ 1 := by nlinarith [sq_nonneg u]
    have hsq : ∀ m : ℕ, m * m = p → False := by
      intro m hm
      rw [← hm] at hp
      rcases Nat.prime_mul_iff.1 hp with ⟨h, rfl⟩ | ⟨h, rfl⟩ <;> exact Nat.not_prime_one h
    interval_cases u <;> interval_cases v <;> norm_num at hc1
    · -- u = -1, v = 0 : a = 0
      have ha : a = 0 := by omega
      subst ha
      exact hsq b (by rw [← hab]; ring)
    · -- u = 0, v = -1 : a = -b
      have ha : a = 0 := by omega
      have hb : b = 0 := by omega
      subst ha hb
      exact hp.ne_zero (by rw [← hab]; ring)
    · -- u = 0, v = 1 : a = b
      have ha : a = b := by omega
      subst ha
      have h2 : p = 2 * (a * a) := by rw [← hab]; ring
      generalize a * a = t at h2
      omega
    · -- u = 1, v = 0 : b = 0
      have hb : b = 0 := by omega
      subst hb
      exact hsq a (by rw [← hab]; ring)
  have hnorm_mul : ∀ (w : GaussianInt), (π * w).norm = p * w.norm ∧
      (star π * w).norm = p * w.norm := by
    intro w; rw [Zsqrtd.norm_mul, Zsqrtd.norm_mul, hnπ, hnπ']; exact ⟨rfl, rfl⟩
  set S := {z : GaussianInt | z.norm = (n : ℤ)} with hSdef
  set A := (fun w => π * w) '' S with hAdef
  set B := (fun w => star π * w) '' S with hBdef
  have hunion : {z : GaussianInt | z.norm = ((p * n : ℕ) : ℤ)} = A ∪ B := by
    ext z
    simp only [Set.mem_ofPred_eq, Set.mem_union, hAdef, hBdef, Set.mem_image, hSdef]
    constructor
    · intro hz
      have hdvd : π ∣ z * star z := by
        rw [← Zsqrtd.norm_eq_mul_conj, hz]; push_cast; rw [hpmul, mul_assoc]
        exact dvd_mul_right _ _
      rcases hprime.dvd_or_dvd hdvd with ⟨c, hc⟩ | ⟨c, hc⟩
      · left
        refine ⟨c, ?_, hc.symm⟩
        have h2 := congrArg Zsqrtd.norm hc
        rw [hz, (hnorm_mul c).1] at h2
        push_cast at h2
        apply mul_left_cancel₀ hp0
        linarith
      · right
        refine ⟨star c, ?_, ?_⟩
        · have h2 := congrArg Zsqrtd.norm hc
          rw [Zsqrtd.norm_conj, hz, (hnorm_mul c).1] at h2
          push_cast at h2
          rw [Zsqrtd.norm_conj]
          apply mul_left_cancel₀ hp0
          linarith
        · have h2 := congrArg star hc
          rw [star_star, star_mul'] at h2
          exact h2.symm
    · rintro (⟨w, hw, rfl⟩ | ⟨w, hw, rfl⟩)
      · rw [(hnorm_mul w).1, hw]; push_cast; ring
      · rw [(hnorm_mul w).2, hw]; push_cast; ring
  have hinter : A ∩ B =
      (fun w => (p : GaussianInt) * w) '' {z : GaussianInt | (p : ℤ) * z.norm = (n : ℤ)} := by
    ext z
    simp only [Set.mem_inter_iff, hAdef, hBdef, Set.mem_image, hSdef, Set.mem_ofPred_eq]
    constructor
    · rintro ⟨⟨c, hc, rfl⟩, ⟨c', _, hc'⟩⟩
      have hd : star π ∣ π * c := ⟨c', hc'.symm⟩
      rcases hprime'.dvd_or_dvd hd with h | ⟨e, he⟩
      · exact absurd h hndvd
      · refine ⟨e, ?_, ?_⟩
        · rw [he, (hnorm_mul e).2] at hc; exact hc
        · rw [he, hpmul]; ring
    · rintro ⟨e, he, rfl⟩
      refine ⟨⟨star π * e, ?_, ?_⟩, ⟨π * e, ?_, ?_⟩⟩
      · rw [(hnorm_mul e).2, he]
      · rw [hpmul]; ring
      · rw [(hnorm_mul e).1, he]
      · rw [hpmul]; ring
  have hfinS : S.Finite := gi_norm_set_finite _
  have key := Set.ncard_union_add_ncard_inter A B (hfinS.image _) (hfinS.image _)
  rw [← hunion, hinter, Set.ncard_image_of_injective _ (mul_right_injective₀ hπ0),
    Set.ncard_image_of_injective _ (mul_right_injective₀ hπ0'),
    Set.ncard_image_of_injective _ (mul_right_injective₀ (by exact_mod_cast hp.ne_zero))] at key
  have key' : ((Set.ncard {z : GaussianInt | z.norm = ((p * n : ℕ) : ℤ)} : ℕ) : ℤ) +
      ((Set.ncard {z : GaussianInt | (p : ℤ) * z.norm = (n : ℤ)} : ℕ) : ℤ) =
      (S.ncard : ℤ) + (S.ncard : ℤ) := by exact_mod_cast key
  linarith

lemma gi_hecke (p n : ℕ) (hp : p.Prime) :
    (Set.ncard {z : GaussianInt | z.norm = ((p * n : ℕ) : ℤ)} : ℤ) =
      (1 + (if p % 4 = 1 then 1 else if p % 4 = 3 then -1 else 0 : ℤ)) *
          (Set.ncard {z : GaussianInt | z.norm = (n : ℤ)} : ℤ) -
        (if p % 4 = 1 then 1 else if p % 4 = 3 then -1 else 0 : ℤ) *
          (if p ∣ n then (Set.ncard {z : GaussianInt | z.norm = ((n / p : ℕ) : ℤ)} : ℤ) else 0) := by
  have hC := gi_ncard_C p n hp.pos
  rcases hp.eq_two_or_odd with h2 | hodd
  · subst h2
    rw [gi_case_two]
    norm_num
  · have h4 : p % 4 = 1 ∨ p % 4 = 3 := by omega
    rcases h4 with h1 | h3
    · rw [gi_case_one p n hp h1, hC]
      split_ifs <;> omega
    · rw [gi_case_three p n hp h3, hC]
      split_ifs <;> omega

lemma chi_four_mul (a b : ℕ) :
    (if a * b % 4 = 1 then 1 else if a * b % 4 = 3 then -1 else 0 : ℤ) =
      (if a % 4 = 1 then 1 else if a % 4 = 3 then -1 else 0 : ℤ) *
        (if b % 4 = 1 then 1 else if b % 4 = 3 then -1 else 0 : ℤ) := by
  rw [Nat.mul_mod]
  have ha : a % 4 < 4 := Nat.mod_lt _ (by norm_num)
  have hb : b % 4 < 4 := Nat.mod_lt _ (by norm_num)
  generalize a % 4 = x at ha ⊢
  generalize b % 4 = y at hb ⊢
  interval_cases x <;> interval_cases y <;> norm_num

lemma divisor_sum_hecke (f : ℕ → ℤ) (hf : ∀ a b, f (a * b) = f a * f b) (p n : ℕ)
    (hp : p.Prime) (hn : 0 < n) :
    ∑ d ∈ Nat.divisors (p * n), f d =
      (1 + f p) * ∑ d ∈ Nat.divisors n, f d -
        f p * (if p ∣ n then ∑ d ∈ Nat.divisors (n / p), f d else 0) := by
  have hpn : p * n ≠ 0 := Nat.mul_ne_zero hp.ne_zero hn.ne'
  have hinj : Function.Injective (fun e => p * e) := fun a b h =>
    Nat.eq_of_mul_eq_mul_left hp.pos h
  have hunion : Nat.divisors (p * n) =
      Nat.divisors n ∪ (Nat.divisors n).image (fun e => p * e) := by
    ext d
    simp only [Finset.mem_union, Finset.mem_image, Nat.mem_divisors]
    constructor
    · rintro ⟨hd, -⟩
      by_cases hpd : p ∣ d
      · obtain ⟨e, rfl⟩ := hpd
        right
        exact ⟨e, ⟨Nat.dvd_of_mul_dvd_mul_left hp.pos hd, hn.ne'⟩, rfl⟩
      · left
        have hcop : Nat.Coprime d p :=
          Nat.coprime_comm.mp ((Nat.Prime.coprime_iff_not_dvd hp).2 hpd)
        exact ⟨hcop.dvd_of_dvd_mul_left hd, hn.ne'⟩
    · rintro (⟨hd, -⟩ | ⟨e, ⟨he, -⟩, rfl⟩)
      · exact ⟨Dvd.dvd.mul_left hd p, hpn⟩
      · exact ⟨mul_dvd_mul_left p he, hpn⟩
  have hinter : Nat.divisors n ∩ (Nat.divisors n).image (fun e => p * e) =
      if p ∣ n then (Nat.divisors (n / p)).image (fun e => p * e) else ∅ := by
    split_ifs with h
    · ext d
      simp only [Finset.mem_inter, Finset.mem_image, Nat.mem_divisors]
      have hnp : n / p ≠ 0 := (Nat.div_pos (Nat.le_of_dvd hn h) hp.pos).ne'
      constructor
      · rintro ⟨⟨hd, -⟩, e, -, rfl⟩
        exact ⟨e, ⟨Nat.dvd_div_of_mul_dvd hd, hnp⟩, rfl⟩
      · rintro ⟨e, ⟨he, -⟩, rfl⟩
        have hpe : p * e ∣ n := Nat.mul_dvd_of_dvd_div h he
        exact ⟨⟨hpe, hn.ne'⟩, e, ⟨Dvd.dvd.trans (Dvd.intro_left p rfl) hpe, hn.ne'⟩, rfl⟩
    · ext d
      simp only [Finset.mem_inter, Finset.mem_image, Nat.mem_divisors, Finset.notMem_empty,
        iff_false]
      rintro ⟨⟨hd, -⟩, e, -, rfl⟩
      exact h (Dvd.dvd.trans (Dvd.intro e rfl) hd)
  have key := Finset.sum_union_inter (s₁ := Nat.divisors n)
    (s₂ := (Nat.divisors n).image (fun e => p * e)) (f := f)
  rw [← hunion, hinter, Finset.sum_image hinj.injOn] at key
  simp only [hf, ← Finset.mul_sum] at key
  split_ifs at key ⊢ with h
  · rw [Finset.sum_image hinj.injOn] at key
    simp only [hf, ← Finset.mul_sum] at key
    linarith
  · simp only [Finset.sum_empty] at key
    linarith

lemma sum_chi_four (s : Finset ℕ) :
    ∑ d ∈ s, (if d % 4 = 1 then 1 else if d % 4 = 3 then -1 else 0 : ℤ) =
      ((s.filter (fun d => d % 4 = 1)).card : ℤ) - ((s.filter (fun d => d % 4 = 3)).card : ℤ) := by
  induction s using Finset.induction_on with
  | empty => simp
  | insert a s ha ih =>
    rw [Finset.sum_insert ha, ih, Finset.filter_insert, Finset.filter_insert]
    by_cases h1 : a % 4 = 1
    · simp only [h1, ↓reduceIte, Finset.card_insert_of_notMem
        (fun hm => ha (Finset.mem_filter.1 hm).1)]
      push_cast; ring
    · by_cases h3 : a % 4 = 3
      · simp only [h3, ↓reduceIte, Finset.card_insert_of_notMem
          (fun hm => ha (Finset.mem_filter.1 hm).1)]
        push_cast; ring
      · simp only [h1, h3, ↓reduceIte]
        ring

lemma r2_gauss_main (n : ℕ) (hn : 0 < n) :
    (Set.ncard {z : GaussianInt | z.norm = (n : ℤ)} : ℤ) =
      4 * ∑ d ∈ Nat.divisors n, (if d % 4 = 1 then 1 else if d % 4 = 3 then -1 else 0 : ℤ) := by
  induction n using Nat.strong_induction_on with
  | _ n ih =>
  rcases Nat.lt_or_ge 1 n with h | h
  · have hp : n.minFac.Prime := Nat.minFac_prime (by omega)
    obtain ⟨m, hm⟩ := Nat.minFac_dvd n
    generalize n.minFac = p at hp hm
    have hm0 : 0 < m := by
      rcases Nat.eq_zero_or_pos m with h0 | h0
      · subst h0; omega
      · exact h0
    have hmn : m < n := by
      have := hp.two_le; rw [hm]; nlinarith
    rw [hm, gi_hecke p m hp,
      divisor_sum_hecke (fun d => (if d % 4 = 1 then 1 else if d % 4 = 3 then -1 else 0 : ℤ))
        chi_four_mul p m hp hm0, ih m hmn hm0]
    generalize (if p % 4 = 1 then (1 : ℤ) else if p % 4 = 3 then -1 else 0) = c
    by_cases hpm : p ∣ m
    · simp only [hpm, ↓reduceIte]
      have hdiv : 0 < m / p := Nat.div_pos (Nat.le_of_dvd hm0 hpm) hp.pos
      rw [ih (m / p) (lt_of_le_of_lt (Nat.div_le_self m p) hmn) hdiv]
      ring
    · simp only [hpm, ↓reduceIte]
      ring
  · have : n = 1 := by omega
    subst this
    rw [Nat.cast_one, gi_card_norm_one]
    simp

#print axioms gi_norm_eq
#print axioms gi_norm_set_finite
#print axioms gi_card_norm_one
#print axioms gi_prime_of_norm_prime
#print axioms gi_ncard_C
#print axioms gi_case_two
#print axioms gi_case_three
#print axioms gi_case_one
#print axioms gi_hecke
#print axioms chi_four_mul
#print axioms divisor_sum_hecke
#print axioms sum_chi_four
#print axioms r2_gauss_main

/-- Fermat's two-square theorem: a prime p is a sum of two whole squares, a² + b² with a and b
whole numbers of either sign, exactly when p is 2 or leaves remainder 1 on division by 4. -/
theorem prime_sum_two_squares_iff (p : ℕ) (hp : p.Prime) :
    (∃ a b : ℤ, a ^ 2 + b ^ 2 = (p : ℤ)) ↔ p = 2 ∨ p % 4 = 1 := by
  constructor
  · rintro ⟨a, b, hab⟩
    rcases hp.eq_two_or_odd with h | h
    · exact Or.inl h
    · right
      have h4 : p % 4 = 1 ∨ p % 4 = 3 := by omega
      rcases h4 with h4 | h4
      · exact h4
      · exfalso
        have hz : ∀ a b : ZMod 4, a ^ 2 + b ^ 2 ≠ (p : ZMod 4) := by
          rw [← ZMod.natCast_mod p 4, h4]; decide
        apply hz a b
        have := congrArg (Int.cast : ℤ → ZMod 4) hab
        push_cast at this
        exact this
  · intro h
    have := Fact.mk hp
    obtain ⟨a, b, hab⟩ := Nat.Prime.sq_add_sq (p := p) (by omega)
    exact ⟨a, b, by exact_mod_cast hab⟩

/-- A sum of two squares is a factorisation: a prime p splits in the Gaussian integers as
α times its conjugate (mirror image) ᾱ exactly when p is 2 or leaves remainder 1 on division by 4. -/
theorem prime_eq_mul_conj_iff (p : ℕ) (hp : p.Prime) :
    (∃ α : GaussianInt, (p : GaussianInt) = α * star α) ↔ p = 2 ∨ p % 4 = 1 := by
  rw [← prime_sum_two_squares_iff p hp]
  constructor
  · rintro ⟨α, hα⟩
    refine ⟨α.re, α.im, ?_⟩
    rw [← Zsqrtd.norm_eq_mul_conj] at hα
    have h2 : ((p : ℤ) : GaussianInt) = ((α.norm : ℤ) : GaussianInt) := by
      rw [Int.cast_natCast]; exact hα
    have h3 : (p : ℤ) = α.norm := Int.cast_injective h2
    rw [h3, gi_norm_eq]
  · rintro ⟨a, b, hab⟩
    refine ⟨⟨a, b⟩, ?_⟩
    rw [← Zsqrtd.norm_eq_mul_conj, gi_norm_eq]
    simp only
    rw [hab]
    simp

/-- The count of representations: for every positive whole number n, the number r₂(n) of ordered
pairs of whole numbers (a, b), signs and order counted, with a² + b² = n equals four times the number
of divisors of n leaving remainder 1 on division by 4, minus the number leaving remainder 3. -/
theorem r2_eq_four_mul_d1_sub_d3 (n : ℕ) (hn : 0 < n) :
    (Nat.card {q : ℤ × ℤ // q.1 ^ 2 + q.2 ^ 2 = (n : ℤ)} : ℤ) =
      4 * ((((Nat.divisors n).filter (fun d => d % 4 = 1)).card : ℤ) -
        (((Nat.divisors n).filter (fun d => d % 4 = 3)).card : ℤ)) := by
  have hcard : Nat.card {q : ℤ × ℤ // q.1 ^ 2 + q.2 ^ 2 = (n : ℤ)} =
      Set.ncard {z : GaussianInt | z.norm = (n : ℤ)} := by
    rw [← Nat.card_coe_set_eq]
    apply Nat.card_congr
    exact
      { toFun := fun q => ⟨⟨q.1.1, q.1.2⟩, by
          show Zsqrtd.norm _ = _
          rw [gi_norm_eq]; exact q.2⟩
        invFun := fun z => ⟨(z.1.re, z.1.im), by
          have h := z.2
          simp only [Set.mem_ofPred_eq, gi_norm_eq] at h
          exact h⟩
        left_inv := fun q => rfl
        right_inv := fun z => rfl }
  rw [hcard, r2_gauss_main n hn, sum_chi_four]

-- 101 leaves remainder 1 and is 10² + 1²; 103 leaves remainder 3.
example : 101 % 4 = 1 ∧ 103 % 4 = 3 := by decide
example : (10 : ℤ) ^ 2 + 1 ^ 2 = 101 := by norm_num
-- 103 minus each square from 0 to 100 is never a square.
example : ∀ a b : Fin 11, (a : ℕ) ^ 2 + (b : ℕ) ^ 2 ≠ 103 := by decide
-- A square root of −1 mod 101 two ways: 2^25 mod 101 = 10, and Wilson's 50! mod 101 = 91.
example : 2 ^ 25 % 101 = 10 ∧ (10 ^ 2 + 1) % 101 = 0 := by norm_num
example : Nat.factorial 50 % 101 = 91 ∧ 91 ^ 2 + 1 = 101 * 82 := by
  norm_num [Nat.factorial]
-- 101 = (10 + i)(10 − i) in the Gaussian integers, and (10 + i)² = 99 + 20i gives 99² + 20² = 101².
example : ((101 : ℕ) : GaussianInt) = (⟨10, 1⟩ : GaussianInt) * star ⟨10, 1⟩ := by
  ext <;> simp
example : (99 : ℤ) ^ 2 + 20 ^ 2 = 101 ^ 2 := by norm_num
-- The largest remainder-1 prime below 10,000: 9973 = 82² + 57².
example : (82 : ℤ) ^ 2 + 57 ^ 2 = 9973 := by norm_num
-- The divisor counts d₁ and d₃ for 101, 103, 21, 45, 65 and 1105, giving r₂ = 8, 0, 0, 8, 16, 32.
example : ((Nat.divisors 101).filter (fun d => d % 4 = 1)).card = 2 ∧
    ((Nat.divisors 101).filter (fun d => d % 4 = 3)).card = 0 := by decide
example : ((Nat.divisors 103).filter (fun d => d % 4 = 1)).card = 1 ∧
    ((Nat.divisors 103).filter (fun d => d % 4 = 3)).card = 1 := by decide
example : ((Nat.divisors 21).filter (fun d => d % 4 = 1)).card = 2 ∧
    ((Nat.divisors 21).filter (fun d => d % 4 = 3)).card = 2 := by decide
example : ((Nat.divisors 45).filter (fun d => d % 4 = 1)).card = 4 ∧
    ((Nat.divisors 45).filter (fun d => d % 4 = 3)).card = 2 := by decide
example : ((Nat.divisors 65).filter (fun d => d % 4 = 1)).card = 4 ∧
    ((Nat.divisors 65).filter (fun d => d % 4 = 3)).card = 0 := by decide
example : ((Nat.divisors 1105).filter (fun d => d % 4 = 1)).card = 8 ∧
    ((Nat.divisors 1105).filter (fun d => d % 4 = 3)).card = 0 := by decide +kernel

#print axioms prime_sum_two_squares_iff
#print axioms prime_eq_mul_conj_iff
#print axioms r2_eq_four_mul_d1_sub_d3
