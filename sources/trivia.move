module dhanesh_addr::TriviaGameRewards {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    /// Struct representing the trivia game state
    struct TriviaGame has store, key {
        total_pool: u64,           // Total reward pool available
        reward_per_question: u64,  // Reward amount per correct answer
    }

    /// Struct to track individual player performance
    struct PlayerStats has store, key {
        correct_answers: u64,      // Total correct answers by player
        total_earned: u64,         // Total tokens earned by player
    }

    /// Function to initialize the trivia game with reward pool
    public fun create_trivia_game(admin: &signer, initial_pool: u64, reward_per_question: u64) {
        let game = TriviaGame {
            total_pool: initial_pool,
            reward_per_question,
        };
        move_to(admin, game);
    }

    /// Function for players to submit correct answers and earn rewards
    public fun submit_correct_answers(
        player: &signer, 
        game_admin: address, 
        questions_answered: u64
    ) acquires TriviaGame, PlayerStats {
        let player_addr = signer::address_of(player);
        let game = borrow_global_mut<TriviaGame>(game_admin);
        
        // Calculate total reward for correct answers
        let reward_amount = game.reward_per_question * questions_answered;
        
        // Ensure sufficient funds in reward pool
        assert!(game.total_pool >= reward_amount, 1);
        
        // Transfer tokens from game admin to player
        let reward = coin::withdraw<AptosCoin>(&signer::create_signer_with_capability(&coin::get_signer_capability(&game_admin)), reward_amount);
        coin::deposit<AptosCoin>(player_addr, reward);
        
        // Update game pool
        game.total_pool = game.total_pool - reward_amount;
        
        // Update player statistics
        if (exists<PlayerStats>(player_addr)) {
            let stats = borrow_global_mut<PlayerStats>(player_addr);
            stats.correct_answers = stats.correct_answers + questions_answered;
            stats.total_earned = stats.total_earned + reward_amount;
        } else {
            let new_stats = PlayerStats {
                correct_answers: questions_answered,
                total_earned: reward_amount,
            };
            move_to(player, new_stats);
        };
    }
}