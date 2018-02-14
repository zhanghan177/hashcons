-- |
-- Module:      Data.HashCons.SeqSubterms
-- Description: The @SeqSubterms@ class
-- Copyright:   © 2018 Andy Morris
-- Licence:     LGPL-3
-- Maintainer:  hello@andy-morris.xyz
-- Stability:   experimental
-- Portability: portable

module Data.HashCons.SeqSubterms (SeqSubterms (..)) where

-- | A class for evaluating immediate recursive subterms (as far as WHNF, like
-- 'seq'). __Make sure you write instances of this class correctly.__ If you
-- don't, you will get 'Control.Exception.BlockedIndefinitelyOnMVar' being
-- raised from pure code!
--
-- A \"fully-polymorphic\" newtype like @'Data.Ord.Down' a@, whose field is
-- simply of type @a@, must /delegate/ to the instance of 'SeqSubterms' for @a@.
-- (This is related to the fact that newtypes' runtime representation is simply
-- that of their field.)
--
-- Otherwise, if all of your values are always /finite/ and /fully-defined/
-- (i.e., never contain \(\bot\)), then it is safe, though possibly slightly
-- inefficient, to simply apply 'seq' to all immediate subterms. You can avoid
-- redundant applications of 'seq' by following these rules:
--
-- - If a type is /monomorphic/ and /non-recursive/, then 'seq' is a suitable
--   implementation of 'seqSubterms'.
-- - If any constructors have /recursive/ (or mutually-recursive) fields, then
--   those fields must be evaluated.
-- - If a type is /polymorphic/, then fields whose types contain a variable must
--   be evaluated, since they might become recursive.
-- - If /all recursive\/polymorphic fields are strict/, then 'seq' is again
--   suitable, since the problematic fields are already evaluated.
--
-- === __Examples__
--
-- @
-- data NonRec = NR 'Int' 'Int'
--
-- -- Non-recursive, so 'seq' is ok
-- instance 'SeqSubterms' NonRec where
--   'seqSubterms' = 'seq'
-- @
--
-- @
-- data IntList = INil | ICons 'Int' IntList
--
-- -- Must evaluate the recursive field.
-- -- The non-recursive one can be ignored.
-- instance 'SeqSubterms' IntList where
--   'seqSubterms' INil         b = b
--   'seqSubterms' (ICons _ xs) b = xs ``seq`` b
-- @
--
-- @
-- data First  = End | More 'Bool' Second
-- data Second = Sec 'Int' First
--
-- -- The same applies for mutual recursion
-- instance 'SeqSubterms' First where
--   'seqSubterms' End        b = b
--   'seqSubterms' (More _ s) b = s ``seq`` b
-- instance 'SeqSubterms' Second where
--   'seqSubterms' (Sec _ f) b = f ``seq`` b
-- @
--
-- @
-- data Pair a = Pair a a
--
-- -- Polymorphic fields need to be evaluated
-- instance 'SeqSubterms' (Pair a) where
--   'seqSubterms' (Pair x y) b = x ``seq`` y ``seq`` b
-- @
--
-- @
-- data StrictPair a = SP !a !a
--
-- -- It's ok to use 'seq' if all the fields of
-- -- interest are strict, though
-- instance 'SeqSubterms' (StrictPair a) where
--   'seqSubterms' = 'seq'
-- @
--
-- @
-- newtype Wrap a = Wrap a
--
-- -- Fully-polymorphic newtype needs to delegate
-- -- its implementation
-- instance 'SeqSubterms' a => 'SeqSubterms' (Wrap a) where
--   'seqSubterms' (Wrap x) = 'seqSubterms' x
-- @
class SeqSubterms a where
  -- | Evaluate the first argument according to the above rules, and return the
  -- second one.
  seqSubterms :: a -> b -> b
