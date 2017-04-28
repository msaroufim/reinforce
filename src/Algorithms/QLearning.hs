{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeSynonymInstances #-}
module Algorithms.QLearning where

import Agents
import Agents.Prelude
import Control.MonadEnv (MonadEnv, Initial(..), Obs(..))
import qualified Control.MonadEnv as Env


class Monad m => QLearning m s a r | m -> s a r where
  choose  :: s -> m a
  actions :: s -> m [a]
  update  :: s -> a -> r -> s -> m ()


-- ============================================================================= --
-- | Q-Learning
-- ============================================================================= --
-- An off-Policy algorithm for TD-learning. Q-Learning learns the optimal policy
-- even when actions are selected according to a more exploratory or even random
-- policy.
--
--   Initialize Q(s, a) arbitrarily
--   For each episode:
--     Observe the initial s
--     Repeat for each step of the episode:
--       Choose a from s using policy derived from Q
--       Take action a, observe r, s'
--       Q(s, a) <- Q(s, a) + lambda * [ r + gamma * max[Q(s', a)] - Q(s, a)]
--                                                   -------------
--               estimate of optimal future value ------'
--
--       s <- s'
--     until s terminal
-- ========================================================================= --
rolloutQLearning :: forall m o a r . (MonadEnv m o a r, QLearning m o a r)=> Maybe Integer -> m ()
rolloutQLearning maxSteps = do
  Initial s <- Env.reset
  clock maxSteps 0 (goM s)
  where
    goM :: o -> Integer -> m ()
    goM s st = do
      a <- choose s
      Env.step a >>= \case
        Terminated -> return ()
        Done _     -> return ()
        Next r s'  -> do
          update s a r s'
          clock maxSteps (st+1) (goM s')



