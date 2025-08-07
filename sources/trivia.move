module dhanesh_addr::TriviaGameRewards {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    struct TriviaGame has store, key {
        total_pool: u64,           
        reward_per_question: u64,  
    }
    struct PlayerStats has store, key {
        correct_answers: u64,      
        total_earned: u64,         
    }
    public fun create_trivia_game(admin: &signer, initial_pool: u64, reward_per_question: u64) {
        let game = TriviaGame {
            total_pool: initial_pool,
            reward_per_question,
        };
        move_to(admin, game);
    }
    public fun submit_correct_answers(
        player: &signer, 
        game_admin: address, 
        questions_answered: u64
    ) acquires TriviaGame, PlayerStats {
        let player_addr = signer::address_of(player);
        let game = borrow_global_mut<TriviaGame>(game_admin);
        let reward_amount = game.reward_per_question * questions_answered;
        assert!(game.total_pool >= reward_amount, 1);
        let reward = coin::withdraw<AptosCoin>(&signer::create_signer_with_capability(&coin::get_signer_capability(&game_admin)), reward_amount);
        coin::deposit<AptosCoin>(player_addr, reward);
        game.total_pool = game.total_pool - reward_amount;
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
