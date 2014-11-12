require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

BLACKJACK_VALUE = 21
DEALER_MIN_HIT = 17

helpers do 
  def total_value(hand)
    total = 0

    hand.each do |card|
      if card[:face_value] == "ace"
        total += 11

      else 
        # card[:face_value] == 0 if "jack" or "queen" or "king"
        total += card[:face_value].to_i == 0 ? 10 : card[:face_value].to_i
      end
    end

    number_of_ace = hand.select { |card| card[:face_value] == "ace" }.count
    while total > BLACKJACK_VALUE && number_of_ace > 0
      total -= 10
      number_of_ace -= 1
    end

    return total
  end

  def is_busted?(hand)
    total_value(hand) > BLACKJACK_VALUE
  end

  def hit_blackjack?(hand)
    total_value(hand) == BLACKJACK_VALUE
  end

  def judge
    @dealer_turn = false
    @game_over = true

    if total_value(session[:player_hand]) > total_value(session[:dealer_hand])
      winner!("#{session[:player_name]} stayed at #{total_value(session[:player_hand])}, 
               and dealer stayed at #{total_value(session[:dealer_hand])}.")

      win_bet!

    elsif total_value(session[:player_hand]) < total_value(session[:dealer_hand])
      loser!("#{session[:player_name]} stayed at #{total_value(session[:player_hand])}, 
              and dealer stayed at #{total_value(session[:dealer_hand])}.")
      lose_bet!

    else
      tie!("#{session[:player_name]} stayed at #{total_value(session[:player_hand])}, 
            and dealer stayed at #{total_value(session[:dealer_hand])}.")
    end
  end

  def img_tag(card)
    if card == "cover"
      "<img src='/images/cards/cover.jpg' class='card_image'>"

    elsif card.instance_of? Hash 
      "<img src='/images/cards/#{card[:suit]}_#{card[:face_value]}.jpg' class='card_image'>"
    end
  end

  def winner!(msg)
    @show_hit_and_stay = false
    @game_over = true

    @success = msg + " #{session[:player_name]} won!"
  end

  def loser!(msg)
    @show_hit_and_stay = false
    @game_over = true

    @failure = msg + " Dealer won!"
  end

  def tie!(msg)
    @show_hit_and_stay = false
    @game_over = true

    @info = msg
  end

  def win_bet!
    session[:money] = session[:money].to_i + session[:bet].to_i
  end

  def lose_bet!
    session[:money] = session[:money].to_i - session[:bet].to_i
  end
end

before do 
  @show_hit_and_stay = true
  @dealer_turn = false
  @game_over = false
end

get '/' do 
  if session[:player_name].nil?
    erb :new_game 

  else 
    redirect '/bet'
  end
end

get '/new_game' do 
  erb :new_game
end

post '/new_game' do 
  if params[:player_name] == ''
    @error = "You must enter a name."
    erb :new_game

  elsif params[:player_name] =~ /\d/
    @error = "Sorry. Please enter a name doesn't contain any digit."
    erb :new_game

  else 
    session[:player_name] = params[:player_name].capitalize
    session[:money] = 500 if session[:money].nil? || session[:money].to_i == 0
    redirect '/bet'
  end
end

get '/bet' do 
  erb :bet
end

post '/bet' do 
  if params[:bet].to_i > session[:money].to_i || params[:bet].to_i <= 0
    @error = "You must enter a number between 1 and #{session[:money]}."  
    erb :bet

  else 
    session[:bet] = params[:bet]

    redirect '/game'    
  end
end

get '/game' do 
  suits = ["clubs", "diamonds", "hearts", "spades"]
  face_values = (2..10).to_a.map! { |value| value.to_s }
  face_values << "ace" << "jack" << "queen" << "king"

  session[:cards] = []
  suits.each do |suit|
    face_values.each do |value|
      session[:cards] << { suit: suit, face_value: value }
    end
  end

  session[:cards].shuffle!

  session[:dealer_hand] = []
  session[:player_hand] = []

  2.times do 
    session[:dealer_hand] << session[:cards].pop
    session[:player_hand] << session[:cards].pop
  end

  # it's possible that player hit blackjack in the beginning
  if hit_blackjack?(session[:player_hand])
    winner!("#{session[:player_name]} hit blackjack!")
    win_bet!
  end

  erb :game 
end

post '/game/player/hit' do 
  session[:player_hand] << session[:cards].pop

  if is_busted?(session[:player_hand])
    loser!("#{session[:player_name]} busted!")
    lose_bet!

  elsif hit_blackjack?(session[:player_hand])
    winner!("#{session[:player_name]} hit blackjack!")
    win_bet!
  end
  
  erb :game
end

post '/game/player/stay' do 
  @show_hit_and_stay = false

  if total_value(session[:dealer_hand]) < DEALER_MIN_HIT
    @info = "Dealer's turn"
    @dealer_turn = true
  else
    # it's possible that the dealer hit blackjack in the beginning of his turn
    if hit_blackjack?(session[:dealer_hand])
      loser!("Dealer hit blackjack!")
      lose_bet!

    else # dealer doesn't hit blackjack and stays, total_value = 17, 18, 19, 20
      judge
    end
  end

  erb :game
end

post '/game/dealer/hit' do 
  session[:dealer_hand] << session[:cards].pop

  @show_hit_and_stay = false

  if is_busted?(session[:dealer_hand])
    winner!("Dealer busted.")
    win_bet!

  elsif hit_blackjack?(session[:dealer_hand])
    loser!("Dealer hit blackjack!")
    lose_bet!

  # dealer doesn't hit blackjack nor bust
  # stays, total_value = 17, 18, 19, 20
  elsif total_value(session[:dealer_hand]) >= DEALER_MIN_HIT # dealer stays
    judge

  else # continue hit
    @dealer_turn = true
  end    

  erb :game
end

get '/exit' do 
  erb :exit
end